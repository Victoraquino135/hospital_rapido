# Perfil Médico

O Médico entra pelo login único com CPF e senha e é direcionado ao `MedicalDashboard`.

Permissões:

- visualizar somente consultas atribuídas a ele, com check-in e triagem concluídos;
- consultar nome, idade, horário, especialidade, prioridade, risco, queixa, sinais vitais e observação da triagem;
- iniciar um atendimento elegível;
- concluir o próprio atendimento com resumo simples obrigatório.

O Médico não administra usuários, grades ou vagas, não registra check-in ou triagem e não acessa pacientes fora da própria fila. A fila é ordenada por risco, prioridade legal e chegada e atualizada a cada quatro segundos.

API: `GET /medico/fila`, `GET /medico/atendimentos/{id}`, `PATCH /medico/atendimentos/{id}/iniciar` e `PATCH /medico/atendimentos/{id}/concluir`.

Conta fictícia: Dr. Victor Almeida, CPF `39053344705`, senha `Medico@123`.
