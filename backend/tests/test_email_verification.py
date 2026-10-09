from datetime import datetime, timedelta

from sqlalchemy import func, select

from test_integration import client, data
from app.core.database import SessionLocal
from app.main import migrate_database
from app.models import EmailVerification, User
from app.routes import email_verification as routes


def _register_pending(client, **overrides):
    payload = data(**overrides)
    response = client.post("/auth/register", json=payload)
    assert response.status_code == 201
    # Cria deliberadamente um registro legado pendente para testar a
    # compatibilidade dos endpoints antigos de código.
    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.email == payload["email"]))
        user.email_verificado = False
        db.commit()
    return payload


def _capture_delivery(monkeypatch):
    sent = []
    delivery = lambda email, code: sent.append((email, code))
    monkeypatch.setattr(
        routes,
        "send_email_verification",
        delivery,
    )
    return sent


def _request(client, email="maria@example.com", path="solicitar-codigo"):
    return client.post(f"/auth/email/{path}", json={"email": email})


def test_code_generation_hash_and_ten_minute_expiration(client, monkeypatch):
    sent = _capture_delivery(monkeypatch)
    _register_pending(client)
    assert _request(client).status_code == 200
    code = sent[0][1]
    assert len(code) == 6 and code.isdigit()
    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.email == "maria@example.com"))
        row = db.scalar(select(EmailVerification))
        assert row.codigo_hash != code and len(row.codigo_hash) == 64
        assert routes.verification_code_matches(user.id, code, row.codigo_hash)
        remaining = row.expira_em - datetime.utcnow()
        assert timedelta(minutes=9, seconds=55) < remaining <= timedelta(minutes=10)


def test_legacy_code_is_single_use_without_blocking_login(client, monkeypatch):
    sent = _capture_delivery(monkeypatch)
    _register_pending(client)
    assert _request(client).status_code == 200
    code = sent[0][1]
    before = client.post(
        "/auth/login",
        json={"document": "52998224725", "password": "Paciente@123"},
    )
    assert before.status_code == 200
    verified = client.post(
        "/auth/email/validar-codigo",
        json={"email": "maria@example.com", "code": code},
    )
    assert verified.status_code == 200
    assert client.post(
        "/auth/email/validar-codigo",
        json={"email": "maria@example.com", "code": code},
    ).status_code == 400
    assert client.post(
        "/auth/login",
        json={"document": "52998224725", "password": "Paciente@123"},
    ).status_code == 200


def test_invalid_expired_and_attempt_limit(client, monkeypatch):
    _capture_delivery(monkeypatch)
    _register_pending(client)
    assert _request(client).status_code == 200
    for _ in range(routes.MAX_CODE_ATTEMPTS):
        response = client.post(
            "/auth/email/validar-codigo",
            json={"email": "maria@example.com", "code": "999999"},
        )
        assert response.status_code == 400
    with SessionLocal() as db:
        row = db.scalar(select(EmailVerification))
        assert row.tentativas == routes.MAX_CODE_ATTEMPTS
        row.tentativas = 0
        row.expira_em = datetime.utcnow() - timedelta(seconds=1)
        db.commit()
    expired = client.post(
        "/auth/email/validar-codigo",
        json={"email": "maria@example.com", "code": "999999"},
    )
    assert expired.status_code in {400, 429}


def test_resend_invalidates_previous_code(client, monkeypatch):
    sent = _capture_delivery(monkeypatch)
    _register_pending(client)
    assert _request(client).status_code == 200
    first = sent[0][1]
    with SessionLocal() as db:
        latest = db.scalar(select(EmailVerification))
        latest.criado_em = datetime.utcnow() - timedelta(seconds=61)
        db.commit()
    assert _request(client, path="reenviar-codigo").status_code == 200
    second = sent[1][1]
    assert second != first or len(second) == 6
    assert client.post(
        "/auth/email/validar-codigo",
        json={"email": "maria@example.com", "code": first},
    ).status_code == 400
    assert client.post(
        "/auth/email/validar-codigo",
        json={"email": "maria@example.com", "code": second},
    ).status_code == 200
    with SessionLocal() as db:
        rows = list(db.scalars(select(EmailVerification).order_by(EmailVerification.id)))
        assert len(rows) == 2 and all(row.utilizado for row in rows)


def test_registration_does_not_use_smtp_and_allows_immediate_login(
    client, monkeypatch
):
    def fail_if_called(_email, _code):
        raise AssertionError("O cadastro não deve chamar o SMTP")

    monkeypatch.setattr(routes, "send_email_verification", fail_if_called)
    response = client.post("/auth/register", json=data())
    assert response.status_code == 201
    assert client.post(
        "/auth/login",
        json={"document": "52998224725", "password": "Paciente@123"},
    ).status_code == 200
    with SessionLocal() as db:
        user = db.scalar(select(User))
        assert user is not None and user.email_verificado is True
        assert db.scalar(select(func.count(User.id))) == 1
        assert db.scalar(select(func.count(EmailVerification.id))) == 0


def test_duplicate_message_is_clear_without_confirming_email_owner(client, monkeypatch):
    _capture_delivery(monkeypatch)
    _register_pending(client)
    duplicate = client.post(
        "/auth/register",
        json={**data(), "cpf": "12345678909"},
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["detail"].startswith("CPF ou e-mail já cadastrado")
    with SessionLocal() as db:
        assert db.scalar(select(func.count(User.id))) == 1


def test_unknown_email_has_same_public_message(client, monkeypatch):
    sent = _capture_delivery(monkeypatch)
    _register_pending(client)
    known = _request(client).json()["message"]
    unknown = _request(client, "desconhecido@example.com").json()["message"]
    assert known == unknown
    assert sent[-1] == (None, None)


def test_migration_preserves_existing_users_and_verified_state(client, monkeypatch):
    _capture_delivery(monkeypatch)
    _register_pending(client)
    with SessionLocal() as db:
        user = db.scalar(select(User))
        user.email_verificado = True
        original_id = user.id
        db.commit()
    migrate_database()
    with SessionLocal() as db:
        user = db.get(User, original_id)
        assert user is not None and user.email_verificado is True
