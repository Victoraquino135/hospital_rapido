# Requisitos não funcionais

- Segurança: JWT, BCrypt, autorização por perfil, limitação de tentativas e códigos temporários armazenados como hash;
- Privacidade: dados fictícios; `.env` e SQLite local fora do Git; CPF mascarado nos painéis operacionais;
- Persistência: a inicialização não apaga nem recria o banco existente;
- Usabilidade: mensagens claras, layout responsivo, navegação por teclado e alvos de interação com tamanho mínimo;
- Acessibilidade: fonte ajustável, alto contraste e rótulos/atalhos semânticos;
- Consistência visual: azul `#005A9C`, verde `#1E824C`, fundo `#F8F9FA` e texto `#212529`;
- Manutenibilidade: separação entre telas, serviço HTTP, rotas, modelos, schemas e serviços;
- Observabilidade: Swagger em `/docs`, endpoint `/health` e registros de auditoria administrativa;
- Portabilidade: execução principal suportada no Windows.
