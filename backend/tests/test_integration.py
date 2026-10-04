import os
import secrets
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
import pytest

TEST_DIR = tempfile.TemporaryDirectory()
os.environ["DATABASE_URL"] = "sqlite:///" + str(Path(TEST_DIR.name) / "test.db")
os.environ["JWT_SECRET_KEY"] = secrets.token_urlsafe(48)
os.environ["SEED_DEMO_DATA"] = "false"
from fastapi.testclient import TestClient
from sqlalchemy import select, func
from app.main import app, migrate_database
from app.core.database import Base, engine, SessionLocal
from app.models import (
    User,
    Guardian,
    PatientGuardian,
    PasswordRecovery,
    Appointment,
    ProfessionalSchedule,
    ProfessionalProfile,
    AuditLog,
    ScheduleGrid,
    Specialty,
)
from app.core.security import pwd, make_token
import atexit

atexit.register(engine.dispose)


@pytest.fixture()
def client():
    Base.metadata.drop_all(engine)
    with TestClient(app) as c:
        yield c


def data(**overrides):
    return dict(
        name="Maria-Silva Santos",
        cpf="52998224725",
        cns="123456789012345",
        birth_date="1990-03-15",
        email="maria@example.com",
        phone="11999998888",
        password="Paciente@123",
        **overrides,
    )


def register(client, **overrides):
    value = data()
    value.update(overrides)
    return client.post("/auth/register", json=value)


def login(client, document="52998224725", password="Paciente@123"):
    return client.post("/auth/login", json={"document": document, "password": password})


def header(client):
    return {"Authorization": "Bearer " + login(client).json()["access_token"]}


def future_weekday(hour=9, days=3):
    value = (datetime.now() + timedelta(days=days)).replace(
        hour=hour, minute=0, second=0, microsecond=0
    )
    while value.weekday() >= 5:
        value += timedelta(days=1)
    return value


def test_adult_login_and_persistence(client):
    assert register(client).status_code == 201
    for document in ["529.982.247-25", "52998224725", " 529.982.247-25 "]:
        r = login(client, document)
        assert r.status_code == 200
        assert (
            client.get(
                "/auth/me",
                headers={"Authorization": "Bearer " + r.json()["access_token"]},
            ).status_code
            == 200
        )
    assert login(client, password="Errada@123").status_code == 401
    assert login(client, document="maria@example.com").status_code == 401
    migrate_database()
    with SessionLocal() as db:
        user = db.scalar(select(User))
        assert user.senha_hash.startswith("$2b$")
        assert user.senha_hash != "Paciente@123"
    assert login(client).status_code == 200


@pytest.mark.parametrize(
    "field,value",
    [
        ("cpf", "11111111111"),
        ("email", "sem-email"),
        ("phone", "123"),
        ("name", "Maria 123"),
        ("birth_date", "1899-01-01"),
        ("password", "fraca"),
    ],
)
def test_invalid(client, field, value):
    assert register(client, **{field: value}).status_code == 422


@pytest.mark.parametrize("field", ["cpf", "email"])
def test_duplicates(client, field):
    assert register(client).status_code == 201
    other = {
        "cpf": "12345678909",
        "cns": "987654321098765",
        "email": "other@example.com",
    }
    other[field] = data()[field]
    assert register(client, **other).status_code == 409


def test_minors_share_guardian(client):
    guardian = dict(
        birth_date="2015-03-15",
        guardian_name="Ana Souza",
        guardian_cpf="11144477735",
        guardian_phone="11977776666",
        guardian_email="ana@example.com",
        guardian_relationship="Mãe",
    )
    assert register(client, birth_date="2015-03-15").status_code == 422
    assert register(client, **guardian).status_code == 201
    assert (
        register(
            client,
            cpf="12345678909",
            cns="987654321098765",
            email="child@example.com",
            **guardian,
        ).status_code
        == 201
    )
    with SessionLocal() as db:
        assert db.scalar(select(func.count(Guardian.id))) == 1
        assert db.scalar(select(func.count(PatientGuardian.paciente_id))) == 2


def recovery(client, monkeypatch):
    import app.routes.recovery as module

    sent = []
    monkeypatch.setattr(
        module,
        "send_recovery",
        lambda email, code: sent.append(code) if email else None,
    )
    assert register(client).status_code == 201
    r = client.post("/auth/forgot-password", json={"document": "52998224725"})
    assert r.status_code == 200 and len(sent) == 1
    unknown = client.post("/auth/forgot-password", json={"document": "12345678909"})
    assert unknown.json() == r.json()
    with SessionLocal() as db:
        row = db.scalar(select(PasswordRecovery))
        assert row.codigo_hash != sent[0] and len(row.codigo_hash) == 64
    return sent[0]


def test_recovery_complete_single_use_and_token_isolation(client, monkeypatch):
    code = recovery(client, monkeypatch)
    old = header(client)
    r = client.post(
        "/auth/verify-recovery-code", json={"document": "52998224725", "code": code}
    )
    assert r.status_code == 200
    token = r.json()["recovery_token"]
    assert (
        client.get("/auth/me", headers={"Authorization": "Bearer " + token}).status_code
        == 401
    )
    body = {
        "recovery_token": token,
        "password": "NovaSenha@123",
        "password_confirmation": "NovaSenha@123",
    }
    assert client.post("/auth/reset-password", json=body).status_code == 200
    assert client.post("/auth/reset-password", json=body).status_code == 401
    assert login(client).status_code == 401
    assert login(client, password="NovaSenha@123").status_code == 200
    assert client.get("/auth/me", headers=old).status_code == 401


def test_incorrect_expired_and_attempt_limit(client, monkeypatch):
    code = recovery(client, monkeypatch)
    wrong = "000000" if code != "000000" else "111111"
    for _ in range(5):
        assert (
            client.post(
                "/auth/verify-recovery-code",
                json={"document": "52998224725", "code": wrong},
            ).status_code
            == 400
        )
    assert (
        client.post(
            "/auth/verify-recovery-code", json={"document": "52998224725", "code": code}
        ).status_code
        == 400
    )
    with SessionLocal() as db:
        row = db.scalar(select(PasswordRecovery))
        row.tentativas = 0
        row.expira_em = datetime.utcnow() - timedelta(seconds=1)
        db.commit()
    assert (
        client.post(
            "/auth/verify-recovery-code", json={"document": "52998224725", "code": code}
        ).status_code
        == 400
    )


def test_login_throttling(client):
    for _ in range(10):
        assert login(client).status_code == 401
    assert login(client).status_code == 429


def test_appointments_permissions_and_cancellation(client):
    register(client)
    h = header(client)
    with SessionLocal() as db:
        doctor = User(
            nome="Médico Teste",
            cpf="11144477735",
            email="doctor@example.com",
            senha_hash=pwd.hash("Doctor@123"),
            perfil="medico",
        )
        db.add(doctor)
        db.flush()
        at = future_weekday()
        db.add(
            ProfessionalSchedule(
                medico_id=doctor.id, data_horario=at, especialidade="Clínica geral"
            )
        )
        db.commit()
        doctor_id = doctor.id
    body = {
        "doctor_id": doctor_id,
        "specialty": "Clínica geral",
        "scheduled_at": at.isoformat(),
    }
    assert client.post("/schedules", json=body, headers=h).status_code == 403
    assert client.get("/queue", headers=h).status_code == 403
    r = client.post("/appointments", json=body, headers=h)
    assert r.status_code == 201
    appointment_id = r.json()["id"]
    assert client.post("/appointments", json=body, headers=h).status_code == 409
    assert (
        client.put(
            f"/appointments/{appointment_id}/status",
            json={"status": "em_espera"},
            headers=h,
        ).status_code
        == 403
    )
    assert (
        client.put(f"/appointments/{appointment_id}/cancel", headers=h).status_code
        == 200
    )
    assert (
        client.put(f"/appointments/{appointment_id}/cancel", headers=h).status_code
        == 409
    )


def test_cors(client):
    r = client.options(
        "/auth/login",
        headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert r.headers["access-control-allow-origin"] == "http://localhost:8080"
    r = client.options(
        "/auth/login",
        headers={
            "Origin": "https://untrusted.example",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert "access-control-allow-origin" not in r.headers


def test_smtp_uses_tls_and_app_password(monkeypatch):
    from app.services import mailer

    calls = []

    class SMTP:
        def __init__(self, host, port, timeout):
            calls.append(("connect", host, port))

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def ehlo(self):
            pass

        def starttls(self, context):
            calls.append(("tls",))

        def login(self, user, password):
            calls.append(("auth", user, password))

        def send_message(self, message):
            calls.append(("send", message))

    monkeypatch.setenv("SMTP_HOST", "smtp.example.com")
    monkeypatch.setenv("SMTP_USER", "projeto@example.com")
    monkeypatch.setenv("SMTP_APP_PASSWORD", "test-only-app-password")
    monkeypatch.setattr(mailer.smtplib, "SMTP", SMTP)
    mailer.send_recovery("patient@example.com", "123456")
    assert calls[1] == ("tls",)
    assert calls[2][2] == "test-only-app-password"
    assert calls[3][1]["To"] == "patient@example.com"
    assert "123456" in calls[3][1].get_content()


def test_presential_flow_and_queue(client):
    register(client)
    with SessionLocal() as db:
        patient = db.scalar(select(User))
        roles = {}
        for index, role in enumerate(["recepcao", "enfermagem", "medico", "admin"]):
            u = User(
                nome="Equipe Teste",
                cpf=str(10000000000 + index),
                email=f"{role}@example.com",
                senha_hash=pwd.hash("Equipe@123"),
                perfil=role,
            )
            db.add(u)
            db.flush()
            roles[role] = u
        item = Appointment(
            paciente_id=patient.id,
            medico_id=roles["medico"].id,
            especialidade="Clínica geral",
            data_horario=datetime.now(),
            status="agendado",
        )
        db.add(item)
        db.commit()
        appointment_id = item.id
        headers = {
            role: {"Authorization": "Bearer " + make_token(u)}
            for role, u in roles.items()
        }
    path = f"/appointments/{appointment_id}/status"
    assert (
        client.put(
            path, headers=headers["medico"], json={"status": "em_atendimento"}
        ).status_code
        == 409
    )
    assert (
        client.put(
            path, headers=headers["recepcao"], json={"status": "em_espera"}
        ).status_code
        == 200
    )
    assert (
        client.put(
            path,
            headers=headers["recepcao"],
            json={
                "status": "em_triagem",
                "risk": "verde",
                "triage": "Avaliação presencial",
            },
        ).status_code
        == 403
    )
    assert (
        client.put(
            path,
            headers=headers["enfermagem"],
            json={
                "status": "em_triagem",
                "risk": "verde",
                "triage": "Avaliação presencial",
            },
        ).status_code
        == 200
    )
    assert (
        client.get("/queue", headers=headers["medico"]).json()[0]["id"]
        == appointment_id
    )
    assert (
        client.put(
            path, headers=headers["medico"], json={"status": "em_atendimento"}
        ).status_code
        == 200
    )
    assert (
        client.put(
            path, headers=headers["medico"], json={"status": "concluido"}
        ).status_code
        == 200
    )
    assert (
        client.put(
            f"/appointments/{appointment_id}/cancel", headers=header(client)
        ).status_code
        == 409
    )
    assert client.get("/queue", headers=headers["medico"]).json() == []


def test_migrate_existing_database_without_loss(client, tmp_path):
    # Only fictional records are used to verify legacy migration.
    import subprocess, sys, sqlite3

    assert register(client).status_code == 201
    with SessionLocal() as db:
        u = db.scalar(select(User))
        u.nome_responsavel = "Ana Souza"
        u.cpf_responsavel = "11144477735"
        u.email_responsavel = "ana@example.com"
        db.add(Guardian(nome="Ana Souza", cpf="11144477735"))
        db.commit()
    target = tmp_path / "old.db"
    with sqlite3.connect(engine.url.database) as source, sqlite3.connect(
        target
    ) as destination:
        source.backup(destination)
    with sqlite3.connect(target) as connection:
        connection.execute("ALTER TABLE responsaveis DROP COLUMN email")
        before = connection.execute("SELECT COUNT(*) FROM usuarios").fetchone()[0]
    env = dict(os.environ, DATABASE_URL="sqlite:///" + str(target))
    result = subprocess.run(
        [
            sys.executable,
            "-c",
            "from app.main import migrate_database; migrate_database(); migrate_database()",
        ],
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    with sqlite3.connect(target) as connection:
        assert (
            connection.execute("SELECT COUNT(*) FROM usuarios").fetchone()[0] == before
        )
        assert "ativo" in [
            x[1] for x in connection.execute("PRAGMA table_info(usuarios)")
        ]


@pytest.mark.parametrize("cns", [None, ""])
def test_optional_cns(client, cns):
    assert register(client, cns=cns).status_code == 201
    assert (
        register(
            client, cpf="12345678909", email="second@example.com", cns=cns
        ).status_code
        == 201
    )
    with SessionLocal() as db:
        assert all(u.cns is None for u in db.scalars(select(User)))
    assert login(client).status_code == 200


def test_missing_cns_and_cpf_constraints(client):
    from sqlalchemy.exc import IntegrityError

    value = data()
    value.pop("cns")
    assert client.post("/auth/register", json=value).status_code == 201
    value.pop("cpf")
    assert client.post("/auth/register", json=value).status_code == 422
    with SessionLocal() as db:
        u = db.scalar(select(User))
        u.cpf = None
        with pytest.raises(IntegrityError):
            db.commit()
        db.rollback()
    assert (
        register(
            client, cpf="529.982.247-25", email="another@example.com", cns=None
        ).status_code
        == 409
    )


@pytest.mark.parametrize(
    "document", ["123456789012345", "11111111111", "52998224724", "abc52998224725"]
)
def test_login_rejects_cns_and_invalid_cpf(client, document):
    assert register(client).status_code == 201
    assert login(client, document=document).status_code == 401


def test_recovery_rejects_cns_even_with_correct_code(client, monkeypatch):
    import app.routes.recovery as module

    sent = []
    monkeypatch.setattr(
        module,
        "send_recovery",
        lambda email, code: sent.append(code) if email else None,
    )
    assert register(client).status_code == 201
    assert (
        client.post(
            "/auth/forgot-password", json={"document": "123456789012345"}
        ).status_code
        == 200
    )
    assert sent == []
    assert (
        client.post(
            "/auth/forgot-password", json={"document": "529.982.247-25"}
        ).status_code
        == 200
    )
    assert len(sent) == 1
    assert (
        client.post(
            "/auth/verify-recovery-code",
            json={"document": "123456789012345", "code": sent[0]},
        ).status_code
        == 400
    )
    assert (
        client.post(
            "/auth/verify-recovery-code",
            json={"document": "529.982.247-25", "code": sent[0]},
        ).status_code
        == 200
    )


def test_change_password(client, monkeypatch):
    code = recovery(client, monkeypatch)
    h = header(client)
    body = {"current_password": "Errada@123", "password": "NovaSenha@123"}
    assert client.post("/auth/change-password", json=body).status_code in (401, 403)
    assert client.post("/auth/change-password", headers=h, json=body).status_code == 400
    body["current_password"] = "Paciente@123"
    assert (
        client.post(
            "/auth/change-password", headers=h, json={**body, "password": "fraca"}
        ).status_code
        == 422
    )
    assert (
        client.post(
            "/auth/change-password",
            headers=h,
            json={**body, "password": "Paciente@123"},
        ).status_code
        == 422
    )
    assert client.post("/auth/change-password", headers=h, json=body).status_code == 200
    assert client.get("/auth/me", headers=h).status_code == 401
    assert login(client).status_code == 401
    assert login(client, password="NovaSenha@123").status_code == 200
    assert (
        client.post(
            "/auth/verify-recovery-code", json={"document": "52998224725", "code": code}
        ).status_code
        == 400
    )


def test_patient_summary_availability_and_ownership(client):
    assert register(client).status_code == 201
    first = header(client)
    assert register(client, cpf="12345678909", email="outro@example.com").status_code == 201
    second = {"Authorization": "Bearer " + login(client, "12345678909").json()["access_token"]}
    with SessionLocal() as db:
        doctor = User(nome="Profissional Fictício", cpf="11144477735",
            email="profissional@example.com", senha_hash=pwd.hash("Doctor@123"), perfil="medico")
        db.add(doctor)
        db.flush()
        at = future_weekday()
        db.add(ProfessionalSchedule(medico_id=doctor.id, data_horario=at,
            especialidade="Clínica geral"))
        db.commit()
        doctor_id = doctor.id
        staff = {"Authorization": "Bearer " + make_token(doctor)}
    profile = client.get("/patients/me", headers=first)
    assert profile.status_code == 200
    assert profile.json()["name"] == "Maria-Silva Santos"
    assert profile.json()["masked_cpf"].endswith("-25")
    assert "senha_hash" not in profile.text and "52998224725" not in profile.text
    assert client.get("/patients/me/summary", headers=first).json().get("next_appointment") is None
    assert client.get("/patients/me", headers=second).json()["masked_cpf"].endswith("-09")
    assert client.get("/specialties", headers=first).status_code == 200
    assert any(x["id"] == doctor_id for x in client.get(
        "/professionals", params={"specialty": "Clínica geral"}, headers=first).json())
    params = {"specialty": "Clínica geral", "doctor_id": doctor_id}
    assert client.get("/availability/dates", params=params, headers=first).json() == [at.date().isoformat()]
    assert client.get("/appointments/available", params=params, headers=first).status_code == 200
    times = client.get("/availability/times", params={**params, "day": at.date().isoformat()}, headers=first)
    assert len(times.json()) == 1
    body = {**params, "scheduled_at": at.isoformat()}
    booked = client.post("/appointments", json=body, headers=first)
    assert booked.status_code == 201
    appointment_id = booked.json()["id"]
    assert client.get("/patients/me/summary", headers=first).json()["next_appointment"]["id"] == appointment_id
    assert len(client.get("/appointments/me", headers=first).json()) == 1
    assert client.get("/appointments/me", headers=second).json() == []
    assert client.get(f"/appointments/{appointment_id}", headers=second).status_code == 403
    assert client.post(f"/appointments/{appointment_id}/cancel", headers=second).status_code == 403
    assert client.post(f"/appointments/{appointment_id}/reschedule", headers=second,
        json={"doctor_id": doctor_id, "scheduled_at": at.isoformat()}).status_code == 403
    assert client.get("/availability/times", params={**params, "day": at.date().isoformat()}, headers=second).json() == []
    assert client.get("/patients/me", headers={}).status_code in (401, 403)
    assert client.get("/patients/me", headers={"Authorization": "Bearer invalid"}).status_code == 401
    assert client.get("/patients/me", headers=staff).status_code == 403
    assert client.get("/appointments/me", headers=staff).status_code == 403


def test_slot_conflict_reschedule_and_release(client):
    register(client)
    h = header(client)
    with SessionLocal() as db:
        doctor = User(nome="Profissional Fictício", cpf="11144477735",
            email="profissional@example.com", senha_hash=pwd.hash("Doctor@123"), perfil="medico")
        db.add(doctor); db.flush()
        first_time = future_weekday(hour=9)
        times = [first_time, first_time.replace(hour=10)]
        for at in times:
            db.add(ProfessionalSchedule(medico_id=doctor.id, data_horario=at,
                especialidade="Clínica geral"))
        db.commit(); doctor_id = doctor.id
    def body(at):
        return {"doctor_id": doctor_id, "specialty": "Clínica geral", "scheduled_at": at.isoformat()}
    first = client.post("/appointments", json=body(times[0]), headers=h)
    assert first.status_code == 201
    assert client.post("/appointments", json=body(times[0]), headers=h).status_code == 409
    item_id = first.json()["id"]
    moved = client.post(f"/appointments/{item_id}/reschedule", headers=h,
        json={"doctor_id": doctor_id, "scheduled_at": times[1].isoformat()})
    assert moved.status_code == 200
    assert moved.json()["scheduled_at"] == times[1].isoformat()
    assert client.get("/availability/dates", params={"specialty": "Clínica geral", "doctor_id": doctor_id}, headers=h).json() == [times[0].date().isoformat()]
    with SessionLocal() as db:
        assert db.get(Appointment, item_id).data_horario == times[1]
    cancelled = client.post(f"/appointments/{item_id}/cancel", headers=h)
    assert cancelled.status_code == 200 and cancelled.json()["message"]
    assert client.post(f"/appointments/{item_id}/cancel", headers=h).status_code == 409
    assert client.post("/appointments", json=body(times[1]), headers=h).status_code == 201


def test_exact_time_boundaries(client, monkeypatch):
    import importlib
    module = importlib.import_module("app.main")
    register(client)
    h = header(client)
    anchor = (datetime.now() + timedelta(days=1)).replace(
        hour=1, minute=0, second=0, microsecond=0
    )
    while anchor.weekday() != 0:
        anchor += timedelta(days=1)
    with SessionLocal() as db:
        patient = db.scalar(select(User).where(User.perfil == "paciente"))
        doctor = User(nome="Profissional Fictício", cpf="11144477735",
            email="profissional@example.com", senha_hash=pwd.hash("Doctor@123"), perfil="medico")
        db.add(doctor); db.flush()
        slots = [anchor + timedelta(hours=h) for h in (12, 15, 23, 24, 25, 60, 84, 11)]
        for at in slots:
            db.add(ProfessionalSchedule(medico_id=doctor.id, data_horario=at,
                especialidade="Clínica geral"))
        cancel_items = []
        for at in slots[2:5]:
            item = Appointment(paciente_id=patient.id, medico_id=doctor.id,
                especialidade="Clínica geral", data_horario=at, status="agendado")
            db.add(item); db.flush(); cancel_items.append(item.id)
        reschedule_items = []
        for at in slots[:2]:
            item = Appointment(paciente_id=patient.id, medico_id=doctor.id,
                especialidade="Clínica geral", data_horario=at, status="agendado")
            db.add(item); db.flush(); reschedule_items.append(item.id)
        too_soon = Appointment(paciente_id=patient.id, medico_id=doctor.id,
            especialidade="Clínica geral", data_horario=slots[7], status="agendado")
        db.add(too_soon); db.flush(); too_soon_id = too_soon.id
        db.commit(); doctor_id = doctor.id
    class FrozenDateTime(datetime):
        @classmethod
        def now(cls, tz=None):
            return anchor if tz is None else anchor.replace(tzinfo=tz)
    monkeypatch.setattr(module, "datetime", FrozenDateTime)
    assert client.post(f"/appointments/{cancel_items[0]}/cancel", headers=h).status_code == 409
    assert client.post(f"/appointments/{cancel_items[1]}/cancel", headers=h).status_code == 200
    assert client.post(f"/appointments/{cancel_items[2]}/cancel", headers=h).status_code == 200
    target = {"doctor_id": doctor_id, "scheduled_at": slots[5].isoformat()}
    assert client.post(f"/appointments/{reschedule_items[0]}/reschedule", headers=h,
        json=target).status_code == 200
    assert client.post(f"/appointments/{reschedule_items[1]}/reschedule", headers=h,
        json=target).status_code == 409
    assert client.post(f"/appointments/{reschedule_items[1]}/reschedule", headers=h,
        json={"doctor_id": doctor_id, "scheduled_at": slots[6].isoformat()}).status_code == 200
    assert client.post(f"/appointments/{too_soon_id}/reschedule", headers=h,
        json={"doctor_id": doctor_id, "scheduled_at": slots[7].isoformat()}).status_code == 409
    with SessionLocal() as db:
        assert db.get(Appointment, reschedule_items[1]).data_horario == slots[6]
        assert db.get(Appointment, too_soon_id).data_horario == slots[7]


def test_two_patients_cannot_reserve_same_slot_concurrently(client):
    from concurrent.futures import ThreadPoolExecutor
    register(client)
    first = header(client)
    register(client, cpf="12345678909", email="outro@example.com")
    second = {"Authorization": "Bearer " + login(client, "12345678909").json()["access_token"]}
    with SessionLocal() as db:
        doctor = User(nome="Profissional Fictício", cpf="11144477735",
            email="profissional@example.com", senha_hash=pwd.hash("Doctor@123"), perfil="medico")
        db.add(doctor); db.flush()
        at = future_weekday()
        db.add(ProfessionalSchedule(medico_id=doctor.id, data_horario=at,
            especialidade="Clínica geral"))
        db.commit(); doctor_id = doctor.id
    payload = {"doctor_id": doctor_id, "specialty": "Clínica geral", "scheduled_at": at.isoformat()}
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda h: client.post("/appointments", json=payload, headers=h).status_code,
            [first, second]))
    assert sorted(responses) == [201, 409]
    with SessionLocal() as db:
        assert db.scalar(select(func.count(Appointment.id))) == 1


def test_expired_access_token_is_rejected(client):
    from datetime import timezone
    from jose import jwt
    from app.core.config import SECRET, ALGORITHM
    register(client)
    with SessionLocal() as db:
        patient = db.scalar(select(User).where(User.perfil == "paciente"))
        token = jwt.encode({"sub": str(patient.id), "purpose": "access",
            "version": patient.token_version,
            "exp": datetime.now(timezone.utc) - timedelta(seconds=1)},
            SECRET, algorithm=ALGORITHM)
    assert client.get("/patients/me", headers={"Authorization": f"Bearer {token}"}).status_code == 401


def test_appointment_survives_api_restart(client):
    register(client)
    h = header(client)
    with SessionLocal() as db:
        doctor = User(nome="Profissional Fictício", cpf="11144477735",
            email="profissional@example.com", senha_hash=pwd.hash("Doctor@123"), perfil="medico")
        db.add(doctor); db.flush()
        at = future_weekday(days=4)
        db.add(ProfessionalSchedule(medico_id=doctor.id, data_horario=at,
            especialidade="Clínica geral"))
        db.commit(); doctor_id = doctor.id
    booked = client.post("/appointments", headers=h, json={"doctor_id": doctor_id,
        "specialty": "Clínica geral", "scheduled_at": at.isoformat()})
    assert booked.status_code == 201
    with TestClient(app) as restarted:
        assert restarted.get("/appointments/me", headers=h).json()[0]["id"] == booked.json()["id"]
        assert restarted.get("/patients/me/summary", headers=h).json()["next_appointment"]["id"] == booked.json()["id"]


def _admin_headers():
    with SessionLocal() as db:
        admin = User(nome="Administrador Fictício", cpf="11144477735",
            email="admin.ficticio@example.com", senha_hash=pwd.hash("Admin@123"), perfil="admin")
        db.add(admin); db.commit(); db.refresh(admin)
        return {"Authorization": "Bearer " + make_token(admin)}, admin.id


def test_public_registration_is_always_patient_and_has_no_sensitive_response(client):
    response = client.post("/auth/register", json=data(role="admin", senha_hash="proibido"))
    assert response.status_code == 201
    assert response.json()["role"] == "paciente"
    assert "password" not in response.text.lower()
    assert "hash" not in response.text.lower()


def test_admin_manages_internal_users_and_permissions(client):
    headers, _ = _admin_headers()
    with SessionLocal() as db:
        specialty = db.scalar(select(Specialty).where(
            func.lower(Specialty.nome) == "clínica geral"))
        specialty_id = specialty.id
    reception = {"name": "Rita Recepção", "cpf": "12345678909",
        "email": "rita@example.com", "role": "recepcao", "password": "Equipe@123",
        "password_confirmation": "Equipe@123", "active": True}
    assert client.post("/admin/users", headers=headers,
        json={**reception, "password_confirmation": "Outra@123"}).status_code == 422
    created = client.post("/admin/users", headers=headers, json=reception)
    assert created.status_code == 201
    assert created.json()["role"] == "recepcao"
    assert "senha" not in created.text.lower() and "hash" not in created.text.lower()
    professional = {"name": "Paula Profissional", "cpf": "16899535009",
        "email": "paula@example.com", "role": "profissional", "password": "Equipe@123",
        "password_confirmation": "Equipe@123", "active": True,
        "professional_registration": "COREN-FICT-123", "specialty_id": specialty_id,
        "can_triage": True}
    created_professional = client.post("/admin/users", headers=headers, json=professional)
    assert created_professional.status_code == 201
    assert created_professional.json()["can_triage"] is False
    nursing = {"name": "Helena Enfermagem", "cpf": "70000000744",
        "email": "helena@example.com", "role": "enfermagem", "password": "Equipe@123",
        "password_confirmation": "Equipe@123", "active": True,
        "professional_registration": "COREN-FICT-456", "specialty_id": specialty_id}
    created_nursing = client.post("/admin/users", headers=headers, json=nursing)
    assert created_nursing.status_code == 201
    assert created_nursing.json()["role"] == "enfermagem"
    assert created_nursing.json()["can_triage"] is True
    assert client.post("/admin/users", headers=headers,
        json={**reception, "email": "outra@example.com"}).status_code == 409
    with SessionLocal() as db:
        users = list(db.scalars(select(User).where(User.perfil.in_(["recepcao", "profissional"]))))
        assert all(u.senha_hash.startswith("$2b$") for u in users)
        assert db.scalar(select(func.count(AuditLog.id))) == 3
        reception_user = db.scalar(select(User).where(User.perfil == "recepcao"))
        professional_user = db.scalar(select(User).where(User.perfil == "profissional"))
        reception_headers = {"Authorization": "Bearer " + make_token(reception_user)}
        professional_headers = {"Authorization": "Bearer " + make_token(professional_user)}
    assert client.post("/admin/users", headers=reception_headers, json=reception).status_code == 403
    assert client.post("/admin/users", headers=professional_headers, json=reception).status_code == 403
    register(client, cpf="39053344705", email="paciente2@example.com")
    patient_headers = {"Authorization": "Bearer " + login(client, "39053344705").json()["access_token"]}
    assert client.get("/admin/users", headers=patient_headers).status_code == 403


def test_deactivation_reset_and_admin_safeguards(client):
    headers, admin_id = _admin_headers()
    second_admin = client.post("/admin/admins", headers=headers, json={
        "name": "Bruno Administrador", "cpf": "39053344705",
        "email": "bruno.admin@example.com", "password": "Admin@123",
        "password_confirmation": "Admin@123"})
    assert second_admin.status_code == 201
    second_admin_id = second_admin.json()["id"]
    assert client.post(f"/admin/users/{admin_id}/deactivate", headers=headers).json()["detail"] == "Você não pode desativar a própria conta"
    assert client.post(f"/admin/users/{second_admin_id}/deactivate", headers=headers).status_code == 200
    payload = {"name": "Rita Recepção", "cpf": "12345678909", "email": "rita@example.com",
        "role": "recepcao", "password": "Equipe@123", "password_confirmation": "Equipe@123",
        "active": True}
    user_id = client.post("/admin/users", headers=headers, json=payload).json()["id"]
    old_hash = None
    with SessionLocal() as db:
        old_hash = db.get(User, user_id).senha_hash
    reset = client.post(f"/admin/users/{user_id}/reset-access", headers=headers,
        json={"password": "NovaEquipe@123", "password_confirmation": "NovaEquipe@123"})
    assert reset.status_code == 204
    assert client.post("/auth/login", json={"document": "12345678909", "password": "Equipe@123"}).status_code == 401
    assert client.post("/auth/login", json={"document": "12345678909", "password": "NovaEquipe@123"}).status_code == 200
    with SessionLocal() as db:
        assert db.get(User, user_id).senha_hash != old_hash
    assert client.post(f"/admin/users/{admin_id}/deactivate", headers=headers).json()["detail"] == "O último administrador ativo não pode ser desativado"
    assert client.post(f"/admin/users/{user_id}/deactivate", headers=headers).status_code == 200
    assert client.post("/auth/login", json={"document": "12345678909", "password": "NovaEquipe@123"}).status_code == 401
    with SessionLocal() as db:
        assert db.get(User, user_id) is not None


def test_checkin_duplicate_cancelled_and_grid_overlap(client):
    headers, admin_id = _admin_headers()
    register(client)
    with SessionLocal() as db:
        specialty = db.scalar(select(Specialty).where(
            func.lower(Specialty.nome) == "clínica geral"))
        professional = User(nome="Paulo Profissional", cpf="16899535009", email="paulo@example.com",
            senha_hash=pwd.hash("Equipe@123"), perfil="profissional")
        db.add(professional); db.flush()
        db.add(ProfessionalProfile(usuario_id=professional.id, registro_profissional="CRM-FICT-1",
            especialidade_id=specialty.id, autorizado_triagem=False))
        patient = db.scalar(select(User).where(User.perfil == "paciente"))
        appointment = Appointment(paciente_id=patient.id, medico_id=professional.id,
            especialidade=specialty.nome, data_horario=datetime.now(), status="agendado")
        cancelled = Appointment(paciente_id=patient.id, medico_id=professional.id,
            especialidade=specialty.nome, data_horario=datetime.now() + timedelta(minutes=30), status="cancelado")
        db.add_all([appointment, cancelled]); db.commit()
        appointment_id, cancelled_id, professional_id, specialty_id = appointment.id, cancelled.id, professional.id, specialty.id
    assert client.post(f"/admin/appointments/{appointment_id}/check-in", headers=headers).status_code == 200
    assert client.put(f"/appointments/{appointment_id}/status", headers=headers,
        json={"status": "em_triagem", "risk": "verde", "triage": "Dados fictícios"}).status_code == 403
    assert client.post(f"/admin/appointments/{appointment_id}/check-in", headers=headers).status_code == 409
    assert client.post(f"/admin/appointments/{cancelled_id}/check-in", headers=headers).status_code == 409
    searched = client.get("/admin/appointments", headers=headers, params={
        "day": datetime.now().date().isoformat(),
        "patient": datetime.now().strftime("%H:%M"),
    })
    assert searched.status_code == 200
    assert any(item["id"] == appointment_id for item in searched.json())
    from app.routes.admin import is_holiday
    selected_day = (datetime.now() + timedelta(days=1)).date()
    while selected_day.weekday() >= 5 or is_holiday(selected_day):
        selected_day += timedelta(days=1)
    day = selected_day.isoformat()
    grid = {"professional_id": professional_id, "specialty_id": specialty_id, "day": day,
        "start_time": "08:00", "end_time": "12:00", "duration_minutes": 60,
        "capacity": 1, "break_start": "10:00", "break_end": "11:00"}
    assert client.post("/admin/grids", headers=headers, json=grid).status_code == 201
    assert client.post("/admin/grids", headers=headers, json=grid).status_code == 409
    with SessionLocal() as db:
        at_break = datetime.combine(datetime.fromisoformat(day).date(), datetime.strptime("10:00", "%H:%M").time())
        assert db.scalar(select(ProfessionalSchedule).where(
            ProfessionalSchedule.medico_id == professional_id,
            ProfessionalSchedule.data_horario == at_break)) is None
        assert db.scalar(select(func.count(ScheduleGrid.id))) == 1


def test_absence_details_specialties_and_schedule_rules(client):
    headers, admin_id = _admin_headers()
    register(client)
    with SessionLocal() as db:
        specialty = db.scalar(select(Specialty).where(
            func.lower(Specialty.nome) == "clínica geral"))
        professional = User(nome="Lia Profissional", cpf="16899535009",
            email="lia@example.com", senha_hash=pwd.hash("Equipe@123"), perfil="profissional")
        reception = User(nome="Rita Recepção", cpf="12345678909",
            email="rita@example.com", senha_hash=pwd.hash("Equipe@123"), perfil="recepcao")
        db.add_all([professional, reception]); db.flush()
        db.add(ProfessionalProfile(usuario_id=professional.id,
            registro_profissional="SEM-REGISTRO-TESTE", especialidade_id=specialty.id))
        patient = db.scalar(select(User).where(User.perfil == "paciente"))
        overdue = Appointment(paciente_id=patient.id, medico_id=professional.id,
            especialidade=specialty.nome, data_horario=datetime.now() - timedelta(minutes=16),
            status="agendado")
        manual = Appointment(paciente_id=patient.id, medico_id=professional.id,
            especialidade=specialty.nome, data_horario=datetime.now() + timedelta(hours=1),
            status="agendado")
        db.add_all([overdue, manual]); db.commit()
        overdue_id, manual_id = overdue.id, manual.id
        professional_id, specialty_id = professional.id, specialty.id
        reception_headers = {"Authorization": "Bearer " + make_token(reception)}

    # A leitura operacional aplica a regra automática de atraso superior a 15 minutos.
    agenda = client.get("/admin/appointments", headers=reception_headers)
    assert agenda.status_code == 200
    with SessionLocal() as db:
        assert db.get(Appointment, overdue_id).status == "falta"
        assert db.get(Appointment, manual_id).status == "agendado"

    assert client.post(f"/admin/appointments/{manual_id}/absence",
                       headers=reception_headers).status_code == 200
    assert client.get(f"/admin/appointments/{manual_id}",
                      headers=reception_headers).json()["patient_document"].startswith("***")
    assert client.get(f"/admin/appointments/{manual_id}", headers=header(client)).status_code == 403

    assert client.post("/admin/specialties", headers=headers,
                       json={"name": "Dermatologia Fictícia"}).status_code == 201
    listed = client.get("/admin/specialties", headers=headers).json()
    assert [item["name"] for item in listed] == ["Clínica geral", "Dermatologia Fictícia"]

    next_day = (datetime.now() + timedelta(days=1)).date()
    while next_day.weekday() >= 5:
        next_day += timedelta(days=1)
    invalid_grid = {"professional_id": professional_id, "specialty_id": specialty_id,
        "day": next_day.isoformat(), "start_time": "08:00", "end_time": "10:00",
        "duration_minutes": 30, "capacity": 1}
    assert client.post("/admin/grids", headers=headers, json=invalid_grid).status_code == 422


def test_professional_registration_is_optional(client):
    headers, _ = _admin_headers()
    with SessionLocal() as db:
        specialty = db.scalar(select(Specialty).where(
            func.lower(Specialty.nome) == "clínica geral"))
        specialty_id = specialty.id
    response = client.post("/admin/users", headers=headers, json={
        "name": "Flávia Profissional", "cpf": "16899535009",
        "email": "flavia@example.com", "role": "profissional",
        "password": "Equipe@123", "password_confirmation": "Equipe@123",
        "specialty_id": specialty_id, "can_triage": False,
    })
    assert response.status_code == 201
    assert response.json()["professional_registration"] is None


def test_initial_admin_is_single_and_secure(client):
    from criar_admin_inicial import create_initial_admin
    created = create_initial_admin("Ana Administradora", "111.444.777-35",
        "ana.admin@example.com", "Admin@123", "Admin@123")
    assert created.perfil == "admin"
    with SessionLocal() as db:
        stored = db.get(User, created.id)
        assert stored.senha_hash.startswith("$2b$") and stored.senha_hash != "Admin@123"
    with pytest.raises(ValueError, match="Já existe administrador"):
        create_initial_admin("Outra Administradora", "12345678909",
            "outra.admin@example.com", "Admin@123", "Admin@123")
    second = create_initial_admin("Outra Administradora", "12345678909",
        "outra.admin@example.com", "Admin@123", "Admin@123",
        allow_additional=True)
    assert second.perfil == "admin"
    with SessionLocal() as db:
        assert db.scalar(select(func.count(User.id)).where(User.perfil == "admin")) == 2
