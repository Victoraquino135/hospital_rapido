# Telas de login e recuperação

## Login

- **Finalidade:** autenticar qualquer perfil sem permitir escolha manual de função.
- **Perfis:** todos.
- **Campos:** CPF e senha.
- **Ações:** entrar, abrir cadastro de paciente, recuperar senha, mostrar/ocultar senha e recursos de acessibilidade.
- **Validações:** CPF com 11 dígitos e dígitos verificadores; senha obrigatória; mensagens da API sem revelar qual credencial falhou.
- **Anterior:** abertura do aplicativo ou saída de uma sessão.
- **Próxima:** dashboard definido automaticamente por `homeForRole()`.
- **Frontend:** `frontend/lib/screens/auth_pages.dart` (`LoginPage`) e `frontend/lib/main.dart`.
- **API:** `POST /auth/login`; a sessão persistida usa também `GET /auth/me`.

## Recuperação de senha

- **Finalidade:** solicitar código por e-mail, validar o código e definir nova senha.
- **Campos:** e-mail, código de seis dígitos, nova senha e confirmação.
- **Ações:** solicitar, validar, redefinir e voltar.
- **Validações:** formato de e-mail, código temporário/uso único e política de senha forte.
- **Frontend:** `frontend/lib/screens/recovery_email_page.dart` (`RecoveryPage`).
- **API:** `POST /auth/esqueci-senha`, `/auth/validar-codigo-recuperacao` e `/auth/redefinir-senha`.
