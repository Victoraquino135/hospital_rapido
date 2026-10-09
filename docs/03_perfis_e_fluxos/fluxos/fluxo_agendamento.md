# Fluxo de agendamento

```text
Paciente autenticado
  -> Agendar consulta
  -> especialidade
  -> profissional
  -> data disponível
  -> horário livre
  -> resumo e confirmação
  -> POST /appointments
  -> consulta com status agendado
  -> painel atualizado
```

A disponibilidade é confirmada novamente pela API para impedir reserva duplicada.
