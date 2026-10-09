import logging
import smtplib
import pytest
from sqlalchemy import select, func
from test_integration import client, register, login
from app.core.database import SessionLocal
from app.models import User, Guardian, PatientGuardian, PasswordRecovery
from app.services import mailer
from app.routes import recovery as routes

GUARDIAN = dict(
    birth_date="2015-03-15",
    guardian_name="Ana Souza",
    guardian_cpf="11144477735",
    guardian_phone="11977776666",
    guardian_email="ana@example.com",
    guardian_relationship="Mãe",
)


@pytest.mark.parametrize(
    "field,value,message",
    [
        (
            "guardian_cpf",
            "529.982.247-25",
            "O CPF do responsável deve ser diferente do CPF do paciente.",
        ),
        (
            "guardian_name",
            "  MÁRIA-SILVA   SANTOS  ",
            "O nome do responsável deve ser diferente do nome do paciente.",
        ),
        (
            "guardian_email",
            " MARIA@EXAMPLE.COM ",
            "O e-mail do responsável deve ser diferente do e-mail do paciente.",
        ),
        (
            "guardian_phone",
            "(11) 99999-8888",
            "O telefone do responsável deve ser diferente do telefone do paciente.",
        ),
        ("guardian_email", "", "Informe o e-mail válido do responsável legal."),
        ("guardian_email", "invalido", "Informe o e-mail válido do responsável legal."),
        ("guardian_cpf", "", "Informe o CPF válido do responsável legal."),
        ("guardian_cpf", "11111111111", "Informe o CPF válido do responsável legal."),
        (
            "guardian_birth_date",
            "2012-01-01",
            "O responsável legal deve ter pelo menos 18 anos.",
        ),
    ],
)
def test_guardian_specific_error(client, field, value, message):
    response = register(client, **{**GUARDIAN, field: value})
    assert response.status_code == 422
    assert response.json()["detail"] == {"field": field, "message": message}
    with SessionLocal() as db:
        assert db.scalar(select(func.count(User.id))) == 0


def test_cns_ignored_and_old_values_preserved(client):
    assert register(client).status_code == 201
    with SessionLocal() as db:
        u = db.scalar(select(User))
        assert u.cns is None
        u.cns = "123456789012345"
        db.commit()
    from app.main import migrate_database

    migrate_database()
    with SessionLocal() as db:
        assert db.scalar(select(User)).cns == "123456789012345"
    assert login(client, document="123456789012345").status_code == 401


def test_shared_guardian_email_must_match_recovery_destination(client):
    assert register(client, **GUARDIAN).status_code == 201
    second = dict(GUARDIAN, cpf="12345678909", email="second@example.com")
    mismatch = register(client, **dict(second, guardian_email="wrong@example.com"))
    assert mismatch.status_code == 422
    assert mismatch.json()["detail"]["field"] == "guardian_email"
    with SessionLocal() as db:
        assert db.scalar(select(func.count(User.id))) == 1
        assert db.scalar(select(func.count(Guardian.id))) == 1
    assert register(client, **second).status_code == 201
    with SessionLocal() as db:
        assert db.scalar(select(func.count(Guardian.id))) == 1
        assert db.scalar(select(func.count(PatientGuardian.paciente_id))) == 2


@pytest.fixture
def sent(monkeypatch):
    messages = []
    monkeypatch.setattr(
        routes,
        "send_recovery",
        lambda email, code: messages.append((email, code)) if email else None,
    )
    return messages


@pytest.mark.parametrize(
    "details",
    [
        {},
        {"guardian_cpf": "12345678909", "guardian_email": "ana@example.com"},
        {"guardian_cpf": "11144477735", "guardian_email": "other@example.com"},
        {"guardian_cpf": "39053344705", "guardian_email": "other@example.com"},
    ],
)
def test_minor_wrong_identity_is_generic(client, sent, details):
    assert register(client, **GUARDIAN).status_code == 201
    with SessionLocal() as db:
        db.add(
            Guardian(nome="Outro Adulto", cpf="39053344705", email="other@example.com")
        )
        db.commit()
    r = client.post(
        "/auth/forgot-password", json={"document": "52998224725", **details}
    )
    assert r.status_code == 200 and r.json() == {"message": routes.GENERIC}
    assert sent == []
    with SessionLocal() as db:
        assert db.scalar(select(func.count(PasswordRecovery.id))) == 0


def test_minor_multiple_dependents_correct_account(client, sent):
    assert register(client, **GUARDIAN).status_code == 201
    assert (
        register(
            client, **GUARDIAN, cpf="12345678909", email="second@example.com"
        ).status_code
        == 201
    )
    identity = {
        "document": "52998224725",
        "guardian_cpf": "111.444.777-35",
        "guardian_email": " ANA@EXAMPLE.COM ",
    }
    assert client.post("/auth/forgot-password", json=identity).status_code == 200
    assert len(sent) == 1 and sent[0][0] == "ana@example.com"
    code = sent[0][1]
    assert (
        client.post(
            "/auth/verify-recovery-code",
            json={**identity, "document": "12345678909", "code": code},
        ).status_code
        == 400
    )
    verified = client.post(
        "/auth/verify-recovery-code", json={**identity, "code": code}
    )
    assert verified.status_code == 200
    token = verified.json()["recovery_token"]
    body = {
        "recovery_token": token,
        "password": "NovaSenha@123",
        "password_confirmation": "Diferente@123",
    }
    assert client.post("/auth/reset-password", json=body).status_code == 422
    body["password_confirmation"] = body["password"]
    assert client.post("/auth/reset-password", json=body).status_code == 200
    assert login(client).status_code == 401
    assert login(client, password="NovaSenha@123").status_code == 200
    assert login(client, document="12345678909").status_code == 200
    with SessionLocal() as db:
        assert db.scalar(select(func.count(Guardian.id))) == 1
        assert db.scalar(select(func.count(PatientGuardian.paciente_id))) == 2


def test_new_code_invalidates_previous_and_rate_limit(client, sent):
    register(client)
    for _ in range(3):
        assert (
            client.post(
                "/auth/forgot-password", json={"document": "52998224725"}
            ).status_code
            == 200
        )
    assert (
        client.post(
            "/auth/forgot-password", json={"document": "52998224725"}
        ).status_code
        == 429
    )
    with SessionLocal() as db:
        rows = list(db.scalars(select(PasswordRecovery).order_by(PasswordRecovery.id)))
        assert [r.utilizado for r in rows] == [True, True, False]
        assert all(r.codigo_hash not in [x[1] for x in sent] for r in rows)


@pytest.mark.parametrize("document", ["11111111111", "12345678909"])
def test_unknown_invalid_cpf_generic(client, sent, document):
    assert client.post("/auth/forgot-password", json={"document": document}).json() == {
        "message": routes.GENERIC
    }
    assert sent == []


def test_service_failure_no_false_success_no_code(client, monkeypatch, caplog):
    register(client)

    def fail(*args):
        raise mailer.MailUnavailable("SMTP_AUTH_FAILED")

    monkeypatch.setattr(routes, "send_recovery", fail)
    with caplog.at_level(logging.INFO):
        a = client.post("/auth/forgot-password", json={"document": "52998224725"})
        b = client.post("/auth/forgot-password", json={"document": "12345678909"})
    assert a.status_code == b.status_code == 503 and a.json() == b.json()
    assert "SMTP_AUTH_FAILED" in caplog.text
    assert "52998224725" not in caplog.text
    with SessionLocal() as db:
        assert db.scalar(select(func.count(PasswordRecovery.id))) == 0


@pytest.fixture
def smtp(monkeypatch):
    for key, value in {
        "SMTP_HOST": "smtp.example.com",
        "SMTP_PORT": "587",
        "SMTP_USER": "sender@example.com",
        "SMTP_PASSWORD": "mock-only-value",
        "SMTP_FROM": "sender@example.com",
        "SMTP_USE_TLS": "true",
    }.items():
        monkeypatch.setenv(key, value)
    events = []

    class FakeSMTP:
        def __init__(self, *args, **kwargs):
            events.append(("connect", args, kwargs))

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def ehlo(self):
            events.append(("ehlo",))

        def starttls(self, **kwargs):
            events.append(("tls", kwargs))

        def login(self, *args):
            events.append(("login",))

        def send_message(self, message):
            events.append(("message", message))
            return {}

    monkeypatch.setattr(mailer.smtplib, "SMTP", FakeSMTP)
    monkeypatch.setattr(mailer.smtplib, "SMTP_SSL", FakeSMTP)
    return events, FakeSMTP


def test_mail_tls_message_and_no_secret_logging(smtp, monkeypatch, caplog, capsys):
    monkeypatch.setenv("DEV_SHOW_RECOVERY_CODE", "true")
    with caplog.at_level(logging.INFO):
        mailer.send_recovery("test@example.com", "123456")
    events, _ = smtp
    assert [e[0] for e in events] == [
        "connect",
        "ehlo",
        "tls",
        "ehlo",
        "login",
        "message",
    ]
    message = events[-1][1]
    assert "123456" in message.get_content() and "10 minutos" in message.get_content()
    assert message["Subject"] == "Código para recuperação de senha - UBS Rápida"
    assert "123456" not in caplog.text + capsys.readouterr().out
    assert "mock-only-value" not in caplog.text
    assert events[2][1]["context"].check_hostname
    assert events[0][2]["timeout"] == 10


def test_implicit_tls(smtp, monkeypatch):
    monkeypatch.setenv("SMTP_PORT", "465")
    mailer.send_recovery("test@example.com", "123456")
    events, _ = smtp
    assert events[0][2]["context"].check_hostname
    assert not any(e[0] == "tls" for e in events)


@pytest.mark.parametrize(
    "case,expected",
    [
        ("missing", "SMTP_CONFIG_MISSING"),
        ("auth", "SMTP_AUTH_FAILED"),
        ("offline", "SMTP_UNAVAILABLE"),
        ("email", "SMTP_INVALID_ADDRESS"),
        ("tls", "SMTP_TLS_REQUIRED"),
        ("port", "SMTP_PORT_INVALID"),
        ("disabled", "SMTP_DISABLED"),
    ],
)
def test_mail_failures(smtp, monkeypatch, case, expected):
    _, fake = smtp
    recipient = "test@example.com"
    if case == "missing":
        monkeypatch.delenv("SMTP_USER")
    if case == "tls":
        monkeypatch.setenv("SMTP_USE_TLS", "false")
    if case == "port":
        monkeypatch.setenv("SMTP_PORT", "25")
    if case == "disabled":
        monkeypatch.setenv("SMTP_ENABLED", "false")
    if case == "email":
        recipient = "invalid"

    def fail_auth(*a):
        raise smtplib.SMTPAuthenticationError(535, b"details secret")

    def offline(*a, **k):
        raise OSError("details secret")

    if case == "auth":
        monkeypatch.setattr(fake, "login", fail_auth)
    if case == "offline":
        monkeypatch.setattr(mailer.smtplib, "SMTP", offline)
    with pytest.raises(mailer.MailUnavailable) as error:
        mailer.send_recovery(recipient, "123456")
    assert error.value.reason == expected and "secret" not in str(error.value)


def test_placeholder_configuration_names_fields_without_leaking_values(
    smtp, monkeypatch, caplog
):
    monkeypatch.setenv("SMTP_USER", "COLOQUE_SEU_EMAIL_AQUI")
    monkeypatch.setenv("SMTP_PASSWORD", "COLOQUE_A_CREDENCIAL_AQUI")
    monkeypatch.setenv("SMTP_FROM", "COLOQUE_SEU_EMAIL_AQUI")

    with caplog.at_level(logging.ERROR), pytest.raises(mailer.MailUnavailable) as error:
        mailer.send_email_verification("patient@example.com", "123456")

    assert error.value.reason == "SMTP_CONFIG_MISSING"
    assert "SMTP_USER,SMTP_PASSWORD,SMTP_FROM" in caplog.text
    assert "COLOQUE_SEU_EMAIL_AQUI" not in caplog.text
    assert "COLOQUE_A_CREDENCIAL_AQUI" not in caplog.text


def test_authentication_failure_logs_only_safe_technical_cause(
    smtp, monkeypatch, caplog
):
    _, fake = smtp

    def fail_auth(*args):
        raise smtplib.SMTPAuthenticationError(535, b"sensitive provider response")

    monkeypatch.setattr(fake, "login", fail_auth)
    with caplog.at_level(logging.ERROR), pytest.raises(mailer.MailUnavailable) as error:
        mailer.send_email_verification("patient@example.com", "123456")

    assert error.value.reason == "SMTP_AUTH_FAILED"
    assert "exception_type=SMTPAuthenticationError" in caplog.text
    assert "sensitive provider response" not in caplog.text
    assert "123456" not in caplog.text
