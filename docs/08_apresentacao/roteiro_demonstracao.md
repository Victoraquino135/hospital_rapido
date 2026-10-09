# Roteiro de demonstração

Tempo sugerido: 10 a 15 minutos. Use somente contas e dados fictícios.

1. **Problema e solução (1 min):** filas presenciais para agendar e acompanhar consultas; o UBS Rápida organiza agendamento, chegada, fila e atendimento.
2. **Estrutura (1 min):** mostrar `frontend/`, `backend/`, banco local, `docs/` e testes. Destacar o único iniciador `INICIAR_TUDO.bat`.
3. **Inicialização (1 min):** executar o BAT, observar mensagens e abrir `http://127.0.0.1:8000/docs`.
4. **Paciente (3 min):** fazer login único, mostrar redirecionamento automático, escolher especialidade/profissional/data/horário, confirmar e acompanhar o status. Se houver tempo, mostrar reagendamento ou cancelamento.
5. **Recepção (2 min):** entrar com conta fictícia, localizar o paciente na agenda e confirmar check-in.
6. **Enfermagem (2 min):** abrir a fila, explicar que a classificação é manual e acadêmica, registrar um nível e encaminhar.
7. **Profissional (2 min):** chamar, iniciar e concluir o atendimento atribuído. Reforçar que não há prontuário eletrônico.
8. **Administrador (2 min):** mostrar resumo, usuários internos, especialidades, agenda, grades e auditoria sem alterar dados desnecessariamente.
9. **Evidências (1 min):** mostrar Swagger, a estrutura de 15 tabelas sem expor senhas/hashes e `docs/07_testes/testes_e_resultados.md`.
10. **Encerramento:** reforçar que é um MVP com dados fictícios, persistência SQLite, JWT/BCrypt e separação por perfis.

## Preparação antes da aula

- executar `INICIAR_TUDO.bat -Validar`;
- confirmar que as contas fictícias existem sem rodar seeds repetidos manualmente;
- deixar uma consulta futura disponível e outra no dia da demonstração para o fluxo presencial;
- testar internet/SMTP somente se a confirmação real de e-mail fizer parte da apresentação;
- manter o `.env` e o conteúdo sensível do banco fora da tela;
- não demonstrar com dados reais.
