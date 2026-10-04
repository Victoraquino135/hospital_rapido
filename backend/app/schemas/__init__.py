from datetime import date, datetime
from typing import Literal
from pydantic import BaseModel, EmailStr, Field, field_validator


class LoginRequest(BaseModel):
    document: str = Field(min_length=3)
    password: str = Field(min_length=6)


class UserResponse(BaseModel):
    id: int
    name: str
    role: str
    permissions: list[str] = []


class PatientProfile(BaseModel):
    name: str
    masked_cpf: str
    cns: str | None = None
    birth_date: date | None = None
    email: str
    phone: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
    permissions: list[str] = []


class InternalUserCreate(BaseModel):
    name: str = Field(min_length=3, max_length=80)
    cpf: str = Field(min_length=11, max_length=32)
    email: EmailStr
    role: Literal["recepcao", "enfermagem", "profissional"]
    password: str = Field(min_length=8, max_length=128)
    password_confirmation: str = Field(min_length=8, max_length=128)
    active: bool = True
    professional_registration: str | None = Field(default=None, max_length=40)
    specialty_id: int | None = None
    can_triage: bool = False


class InternalUserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=3, max_length=80)
    email: EmailStr | None = None
    role: Literal["recepcao", "enfermagem", "profissional"] | None = None
    professional_registration: str | None = Field(default=None, max_length=40)
    specialty_id: int | None = None
    can_triage: bool | None = None


class AccessReset(BaseModel):
    password: str = Field(min_length=8, max_length=128)
    password_confirmation: str = Field(min_length=8, max_length=128)


class InternalUserResponse(BaseModel):
    id: int
    name: str
    masked_cpf: str
    email: str
    role: str
    active: bool
    professional_registration: str | None = None
    specialty_id: int | None = None
    specialty: str | None = None
    can_triage: bool = False
    created_at: datetime | None = None
    updated_at: datetime | None = None


class PatientRegistration(BaseModel):
    name: str = Field(min_length=3, max_length=80)
    cpf: str = Field(min_length=11, max_length=32)
    birth_date: date
    email: EmailStr
    phone: str = Field(min_length=10, max_length=16)
    password: str = Field(min_length=8, max_length=128)
    priority: str | None = None
    guardian_name: str | None = Field(default=None, max_length=120)
    guardian_cpf: str | None = Field(default=None, max_length=32)
    guardian_birth_date: date | None = None
    guardian_relationship: str | None = Field(default=None, max_length=40)
    guardian_other_relationship: str | None = Field(default=None, max_length=80)
    guardian_phone: str | None = Field(default=None, max_length=16)
    guardian_email: EmailStr | None = None

    @field_validator("name", "guardian_name", mode="before")
    @classmethod
    def normalize_spaces(cls, value):
        return " ".join(value.split()) if isinstance(value, str) else value

    @field_validator("email", "guardian_email", mode="before")
    @classmethod
    def trim_email(cls, value):
        return value.strip().lower() if isinstance(value, str) else value


class RecoveryIdentity(BaseModel):
    document: str = Field(min_length=3, max_length=32)
    guardian_cpf: str | None = Field(default=None, max_length=32)
    guardian_email: str | None = Field(default=None, max_length=254)


class PasswordRecoveryVerify(RecoveryIdentity):
    document: str = Field(min_length=3)
    code: str = Field(pattern=r"^[0-9]{6}$")


class PasswordRecoveryRequest(RecoveryIdentity):
    document: str = Field(min_length=3, max_length=20)


class PasswordReset(BaseModel):
    recovery_token: str
    password_confirmation: str = Field(min_length=8, max_length=128)
    password: str = Field(min_length=8, max_length=128)


class EmailPasswordRecoveryRequest(BaseModel):
    email: EmailStr

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return value.strip().lower() if isinstance(value, str) else value


class EmailPasswordRecoveryVerify(EmailPasswordRecoveryRequest):
    code: str = Field(pattern=r"^[0-9]{6}$")


class EmailPasswordReset(BaseModel):
    recovery_token: str = Field(min_length=1)
    new_password: str = Field(min_length=8, max_length=128)
    confirm_new_password: str = Field(min_length=8, max_length=128)


class PasswordChange(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)
    password: str = Field(min_length=8, max_length=128)


class AppointmentResponse(BaseModel):
    id: int
    specialty: str
    professional: str
    doctor_id: int
    scheduled_at: datetime
    status: str
    risk_classification: str | None = None
    location: str | None = None
    message: str | None = None


class PatientSummary(BaseModel):
    patient: PatientProfile
    next_appointment: AppointmentResponse | None = None


class CatalogItem(BaseModel):
    id: int
    name: str


class AppointmentCreate(BaseModel):
    doctor_id: int
    specialty: str = Field(min_length=3, max_length=80)
    scheduled_at: datetime


class RescheduleRequest(BaseModel):
    doctor_id: int
    scheduled_at: datetime


class AvailableSlot(BaseModel):
    doctor_id: int
    doctor_name: str
    specialty: str
    scheduled_at: datetime


class CalendarSlot(AvailableSlot):
    availability: Literal["available", "unavailable", "already_scheduled"]
    label: Literal["Disponível", "Indisponível", "Já agendado"]
    selectable: bool
