# Casos de uso principais

## UC01 — Autenticar usuário

Ator: qualquer usuário cadastrado. Informa CPF e senha; o backend valida credenciais e situação e devolve JWT/perfil; o Flutter abre automaticamente o painel correspondente.

## UC02 — Agendar consulta

Ator: paciente. Seleciona especialidade, profissional, data e horário. A API rejeita horário ocupado/bloqueado e segunda consulta ativa da mesma especialidade na mesma data.

## UC03 — Cancelar ou reagendar

Ator: paciente proprietário. Cancela com 24 horas ou reagenda com 12 horas de antecedência. A vaga antiga volta a ficar disponível; estados encerrados não aceitam repetição.

## UC04 — Registrar chegada ou ausência

Ator: recepção. Localiza consulta do dia, confirma check-in ou registra no-show. O backend bloqueia datas e estados incompatíveis.

## UC05 — Realizar triagem

Ator: enfermagem autorizada. Após check-in, registra queixa principal, sinais vitais e risco manual. O sistema grava autoria/data e ordena a fila sem automação clínica.

## UC06 — Realizar atendimento

Ator: profissional de saúde atribuído. Visualiza fila priorizada e sua justificativa, chama o paciente, inicia após triagem e conclui o atendimento.

## UC07 — Administrar equipe e agenda

Ator: administrador/gestão. Gerencia usuários internos, especialidades, grades, horários e bloqueios, com validações e auditoria.
