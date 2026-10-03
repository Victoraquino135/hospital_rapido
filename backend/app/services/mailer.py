"""Entrega SMTP com TLS; códigos e credenciais nunca são registrados."""

import logging
from datetime import datetime, timezone
import os
import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr
from email_validator import validate_email, EmailNotValidError

logger = logging.getLogger(__name__)


class MailUnavailable(Exception):
    def __init__(self, reason):
        self.reason = reason
        super().__init__("Serviço de e-mail temporariamente indisponível.")


def send_recovery(email, code):
    enabled = os.getenv("SMTP_ENABLED", "true").strip().lower() == "true"
    if not enabled:
        raise MailUnavailable("SMTP_DISABLED")
    user = os.getenv("SMTP_USER", "").strip()
    password = os.getenv("SMTP_PASSWORD") or os.getenv("SMTP_APP_PASSWORD", "")
    sender = os.getenv("SMTP_FROM", "").strip() or user
    host = os.getenv("SMTP_HOST", "").strip()
    try:
        placeholders = ("COLOQUE_", "_AQUI")
        if (
            not host
            or not user
            or not password
            or any(marker in value.upper() for value in (user, password, sender) for marker in placeholders)
        ):
            raise MailUnavailable("SMTP_CONFIG_MISSING")
        if os.getenv("SMTP_USE_TLS", "true").lower() != "true":
            raise MailUnavailable("SMTP_TLS_REQUIRED")
        port = int(os.getenv("SMTP_PORT", "587"))
        sender = validate_email(sender, check_deliverability=False).normalized
        if email is not None:
            email = validate_email(email, check_deliverability=False).normalized
        context = ssl.create_default_context()
        transport = smtplib.SMTP_SSL if port == 465 else smtplib.SMTP
        options = {"timeout": 10}
        if port == 465:
            options["context"] = context
        with transport(host, port, **options) as smtp:
            if port != 465:
                smtp.ehlo()
                smtp.starttls(context=context)
                smtp.ehlo()
            smtp.login(user, password)
            # Contas desconhecidas percorrem a mesma verificação de disponibilidade.
            if email is None:
                return
            message = EmailMessage()
            message["From"] = formataddr(
                (os.getenv("SMTP_FROM_NAME", "UBS Rápida"), sender)
            )
            message["To"] = email
            message["Subject"] = "Código para recuperação de senha - UBS Rápida"
            message.set_content(
                f"UBS Rápida\n\nSeu código de recuperação é {code}.\nVálido por 10 minutos e para um único uso.\nSe você não solicitou a recuperação, ignore esta mensagem. Nenhuma senha foi alterada."
            )
            if smtp.send_message(message):
                raise MailUnavailable("SMTP_RECIPIENT_REFUSED")
        logger.info(
            "recovery_delivery status=accepted code=SMTP_ACCEPTED timestamp=%s",
            datetime.now(timezone.utc).isoformat(),
        )
    except MailUnavailable:
        raise
    except smtplib.SMTPAuthenticationError:
        raise MailUnavailable("SMTP_AUTH_FAILED") from None
    except EmailNotValidError:
        raise MailUnavailable("SMTP_INVALID_ADDRESS") from None
    except (ValueError, OSError, smtplib.SMTPException):
        raise MailUnavailable("SMTP_UNAVAILABLE") from None
