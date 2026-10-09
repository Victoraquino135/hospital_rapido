# Tela do administrador

- **Nome:** Painel Administrativo.
- **Finalidade:** visão operacional e manutenção controlada do cadastro interno e da agenda.
- **Perfil:** administrador.
- **Seções:** visão geral, agenda, fila, especialidades, profissionais, Médicos, usuários internos, grades/horários, histórico e configurações.
- **Agenda:** data, paciente, status, especialidade e profissional; ações de detalhes, check-in e falta.
- **Usuários:** pesquisa, perfil e situação; cadastrar, editar, ativar/desativar e redefinir acesso. Campos incluem nome, CPF, e-mail, perfil, senha provisória e, para profissionais, especialidade/registro e autorização de triagem.
- **Especialidades:** pesquisar, cadastrar, editar e ativar/desativar; especialidades inativas permanecem no histórico e deixam de aparecer em novos agendamentos.
- **Grades:** profissional, especialidade, data, início/fim, duração, vagas e intervalo; criar e remover/desativar disponibilidade.
- **Outras ações da API:** administradores, bloqueios e auditoria.
- **Validações:** confirmações antes de ações destrutivas; proteção contra retirada do próprio perfil e contra remoção de grade ocupada.
- **Anterior:** login.
- **Próxima:** permanece na seção atual ou volta ao login ao sair.
- **Frontend:** `frontend/lib/screens/admin_dashboard.dart` (`AdminDashboard` e componentes internos).
- **API:** `/admin/summary`, `/admin/appointments`, `/admin/users`, `/admin/specialties`, `/admin/grids`, `/admin/blocks`, `/admin/audit` e rotas relacionadas.
