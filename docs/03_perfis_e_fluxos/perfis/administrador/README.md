# Perfil: Administrador

Após o login único, o Flutter abre `AdminDashboard` (`frontend/lib/screens/admin_dashboard.dart`).

Funcionalidades implementadas:

- visão resumida e agenda diária com filtros;
- detalhes, check-in e registro de falta;
- cadastro, edição, ativação e desativação de usuários internos;
- redefinição de acesso e invalidação de sessões anteriores;
- criação protegida de outro administrador;
- cadastro, edição, ativação e desativação de especialidades;
- vínculo de profissionais a especialidades e permissão de triagem;
- criação de grades com horários, duração, capacidade e intervalo;
- desativação segura de grades e bloqueio de períodos;
- consulta do histórico de auditoria.

O cadastro público não cria administradores. As APIs administrativas ficam principalmente em `/admin/*`, além de `/schedules` e `/schedules/{id}/block`.
