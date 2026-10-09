# Fluxo de atendimento presencial

```text
agendado
  -> Recepção: check-in
em_espera
  -> Enfermagem: queixa, sinais vitais e classificação manual de risco
em_triagem
  -> Médico atribuído: iniciar atendimento
em_atendimento
  -> Médico responsável: informar resumo simples e concluir
concluido
```

A fila considera, nesta ordem, classificação de risco, pessoa idosa (60+), PCD, gestante, lactante e horário de chegada. O indicador que justificou a prioridade é exibido.

O Médico recebe somente consultas atribuídas a ele após check-in e triagem completos. Um paciente não pode permanecer em atendimento simultâneo com dois Médicos. A conclusão exige que o mesmo Médico tenha iniciado o atendimento e informe um resumo simples. Trata-se de uma simulação acadêmica de fluxo, sem prontuário ou diagnóstico.
