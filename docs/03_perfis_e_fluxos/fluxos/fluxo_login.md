# Fluxo de login

```text
Login único
  -> CPF + senha
  -> POST /auth/login
  -> backend valida CPF, BCrypt e situação da conta
  -> JWT + perfil
  -> sessão local protegida
  -> homeForRole()
  -> dashboard do paciente, equipe ou administrador
```

Não existe escolha pública de perfil. CPF/senha inválidos retornam mensagem genérica. O cadastro atual já cria o paciente apto ao primeiro login.
