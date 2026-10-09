# Relacionamentos

```text
usuarios (paciente) 1 --- N consultas N --- 1 usuarios (medico)
       |                         |
       |                         +--- N historico_status_consultas
       |                         +--- 0..1 classificacoes_risco
       |
       N --- N responsaveis (via pacientes_responsaveis)

usuarios (medico/enfermagem) 1 --- 0..1 perfis_profissionais --- 1 especialidades
          |
          +--- N agendas_profissionais
          +--- N grades_atendimento --- 1 especialidades
          +--- N bloqueios_agenda

usuarios 1 --- N recuperacao_senha
usuarios 1 --- N verificacoes_email
usuarios 1 --- N auditoria_administrativa
```

## Observações

- `consultas.paciente_id` e `consultas.medico_id` determinam propriedade e visibilidade;
- `agendas_profissionais` contém slots; `grades_atendimento` é a origem administrativa que pode gerar vários slots;
- histórico e auditoria preservam rastreabilidade sem armazenar prontuário;
- a associação de responsáveis permite que um mesmo responsável legal seja vinculado a mais de um dependente;
- exclusões físicas são evitadas quando poderiam romper vínculos; a aplicação prefere desativar/bloquear.
