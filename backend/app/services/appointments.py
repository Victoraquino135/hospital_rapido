"""Regras compartilhadas do fluxo presencial de consultas."""
from datetime import date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Appointment, AppointmentStatusHistory, AuditLog, User


RISK_ORDER = {"vermelho": 0, "laranja": 1, "amarelo": 2, "verde": 3, "azul": 4}
LEGAL_PRIORITIES = {"idoso_60+", "pcd", "gestante", "lactante"}


def is_legal_priority(patient: User, today: date | None = None) -> bool:
    if patient.e_prioridade in LEGAL_PRIORITIES:
        return True
    if not patient.data_nascimento:
        return False
    today = today or date.today()
    born = patient.data_nascimento.date()
    age = today.year - born.year - ((today.month, today.day) < (born.month, born.day))
    return age >= 60


def queue_sort_key(item: Appointment):
    return (
        RISK_ORDER.get(item.classificacao_risco, len(RISK_ORDER)),
        0 if is_legal_priority(item.paciente) else 1,
        item.chegada_em or datetime.max,
    )


def mark_overdue_absences(db: Session, actor: User, now: datetime | None = None) -> int:
    """Marca como falta consultas sem chegada 15 minutos após o horário.

    A alteração fica vinculada ao usuário interno que provocou a atualização,
    preservando a trilha de auditoria sem criar uma credencial de sistema.
    """
    now = now or datetime.now()
    limit = now - timedelta(minutes=15)
    rows = list(db.scalars(select(Appointment).where(
        Appointment.status == "agendado",
        Appointment.chegada_em.is_(None),
        Appointment.data_horario <= limit,
    )))
    for row in rows:
        row.status = "falta"
        db.add(AppointmentStatusHistory(
            consulta_id=row.id,
            status_anterior="agendado",
            status_novo="falta",
            alterado_por=actor.id,
        ))
        db.add(AuditLog(
            usuario_id=actor.id,
            acao="falta_automatica",
            tipo_registro="consulta",
            registro_id=row.id,
            detalhes='{"regra":"atraso_superior_15_minutos"}',
        ))
    if rows:
        db.commit()
    return len(rows)
