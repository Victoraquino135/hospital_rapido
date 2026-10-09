# Fluxo de check-in

```text
Paciente chega à UBS
  -> recepção localiza consulta do dia
  -> confirmação de chegada
  -> PATCH /recepcao/agendamentos/{id}/check-in
  -> chegada registrada
  -> status em_espera
  -> paciente entra na fila da enfermagem
```

Se o paciente não comparecer, a recepção pode registrar `falta` no dia da consulta.
