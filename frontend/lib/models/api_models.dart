class ApiException implements Exception {
  const ApiException(this.message, {this.field, this.statusCode});
  final String? field;
  final String message;
  final int? statusCode;
}

class PatientProfile {
  PatientProfile.fromJson(Map<String, dynamic> v)
      : name = v['name'] as String,
        maskedCpf = v['masked_cpf'] as String,
        cns = v['cns'] as String?,
        birthDate =
            v['birth_date'] == null ? null : DateTime.parse(v['birth_date']),
        email = v['email'] as String,
        phone = v['phone'] as String?;
  final String name, maskedCpf, email;
  final String? cns, phone;
  final DateTime? birthDate;
}

class PatientSummary {
  PatientSummary.fromJson(Map<String, dynamic> v)
      : patient = PatientProfile.fromJson(v['patient'] as Map<String, dynamic>),
        nextAppointment = v['next_appointment'] == null
            ? null
            : Appointment.fromJson(
                v['next_appointment'] as Map<String, dynamic>);
  final PatientProfile patient;
  final Appointment? nextAppointment;
}

class Session {
  const Session(this.token, this.name, this.role, this.permissions);
  final String token, name, role;
  final List<String> permissions;
  bool can(String permission) => permissions.contains(permission);
}

class AdminSummary {
  AdminSummary.fromJson(Map<String, dynamic> v)
      : scheduled = v['scheduled'] as int,
        checkedIn = v['checked_in'] as int,
        waiting = v['waiting'] as int,
        inCare = v['in_care'] as int,
        completed = v['completed'] as int,
        cancelled = v['cancelled'] as int,
        available = v['available'] as int? ?? 0,
        absent = v['absent'] as int? ?? 0;
  final int scheduled,
      checkedIn,
      waiting,
      inCare,
      completed,
      cancelled,
      available,
      absent;
}

class InternalUser {
  InternalUser.fromJson(Map<String, dynamic> v)
      : id = v['id'] as int,
        name = v['name'] as String,
        maskedCpf = v['masked_cpf'] as String,
        email = v['email'] as String,
        role = v['role'] as String,
        active = v['active'] as bool,
        professionalRegistration = v['professional_registration'] as String?,
        specialtyId = v['specialty_id'] as int?,
        specialty = v['specialty'] as String?,
        canTriage = v['can_triage'] as bool? ?? false;
  final int id;
  final String name, maskedCpf, email, role;
  final bool active, canTriage;
  final String? professionalRegistration, specialty;
  final int? specialtyId;
}

class AdminAppointment {
  AdminAppointment.fromJson(Map<String, dynamic> v)
      : id = v['id'] as int,
        scheduledAt = DateTime.parse(v['scheduled_at'] as String),
        patient = v['patient'] as String,
        patientDocument = v['patient_document'] as String? ?? '',
        specialty = v['specialty'] as String,
        professional = v['professional'] as String,
        professionalId = v['professional_id'] as int,
        status = v['status'] as String,
        legalPriority = v['legal_priority'] as String? ?? 'geral',
        risk = v['risk_classification'] as String?,
        arrivedAt = v['arrived_at'] == null
            ? null
            : DateTime.parse(v['arrived_at'] as String);
  final int id, professionalId;
  final DateTime scheduledAt;
  final DateTime? arrivedAt;
  final String patient,
      patientDocument,
      specialty,
      professional,
      status,
      legalPriority;
  final String? risk;
}

class Appointment {
  Appointment.fromJson(Map<String, dynamic> v)
      : id = v['id'],
        specialty = v['specialty'],
        professional = v['professional'],
        doctorId = v['doctor_id'],
        scheduledAt = DateTime.parse(v['scheduled_at']),
        status = v['status'],
        location = v['location'] as String?,
        message = v['message'] as String?;
  final int id, doctorId;
  final String specialty, professional, status;
  final String? location, message;
  final DateTime scheduledAt;
}

class Slot {
  Slot.fromJson(Map<String, dynamic> v)
      : doctorId = v['doctor_id'],
        doctorName = v['doctor_name'],
        specialty = v['specialty'],
        scheduledAt = DateTime.parse(v['scheduled_at']),
        availability = v['availability'] as String? ?? 'available',
        label = v['label'] as String? ?? 'Disponível',
        selectable = v['selectable'] as bool? ?? true;
  final int doctorId;
  final String doctorName, specialty;
  final String availability, label;
  final bool selectable;
  final DateTime scheduledAt;
}
