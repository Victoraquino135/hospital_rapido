# Fluxo de cadastro

```text
Login -> Criar conta
  -> dados do paciente
  -> se menor: dados do responsável legal
  -> POST /patients/register
  -> conta paciente ativa
  -> login automático com CPF e senha
  -> painel do paciente
```

O cadastro atual não chama o SMTP e não depende de confirmação para o primeiro acesso. As rotas auxiliares de confirmação, reenvio e correção de endereço permanecem implementadas para compatibilidade, com código temporário, tentativas limitadas e uso único.
