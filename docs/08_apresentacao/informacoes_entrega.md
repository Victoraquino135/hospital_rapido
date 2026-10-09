# Informações da entrega

- **Projeto:** UBS Rápida;
- **Versão final revisada:** 09/10/2026;
- **Repositório:** https://github.com/Victoraquino135/hospital_rapido;
- **Protótipo:** nenhum link externo foi localizado; o Flutter executável é a referência visual;
- **Plataformas verificadas:** Windows e Web compiladas; a estrutura Android é mantida, mas o download do Gradle foi bloqueado pela cadeia de certificados Java deste ambiente;
- **Banco:** SQLite local preservado, com dados fictícios;
- **Iniciador oficial:** `INICIAR_TUDO.bat`.

## Contas fictícias

As credenciais exibidas pelo iniciador pertencem somente à demonstração acadêmica. Não são senhas reais e não devem ser reutilizadas. Há contas fictícias para paciente, recepção, enfermagem, profissional de saúde e administrador/gestão.

- Paciente — CPF `52998224725` — senha fictícia `Paciente@123`;
- Recepção — CPF `98765432100` — senha fictícia `Recepcao@123`;
- Enfermagem — CPF `45678912364` — senha fictícia `Enfermagem@123`;
- Médico — CPF `39053344705` — senha fictícia `Medico@123`;
- Administrador/Gestão — CPF `12345678909` — senha fictícia `Admin@123`.

## Resultados alcançados

- login único e redirecionamento automático por perfil;
- agendamento com controle de duplicidade e concorrência;
- cancelamento/reagendamento com liberação de vaga;
- fluxo presencial completo, com triagem manual e fila priorizada;
- separação de permissões no backend;
- acessibilidade, responsividade e atualização automática;
- documentação, Swagger, testes e build de apresentação.

## Limitações e melhorias futuras

- aplicação acadêmica local, sem integração SUS/e-SUS;
- SMTP depende de configuração local segura;
- SQLite é adequado ao MVP, não a implantação multiunidade em produção;
- depreciações técnicas de `datetime.utcnow()` e eventos FastAPI devem ser modernizadas em evolução futura;
- painel público/TV, senha pública e chamador de fila ficam explicitamente fora do MVP e podem ser avaliados futuramente;
- não há prontuário, diagnóstico, medicamentos, exames, vacinação, pagamentos ou IA clínica.
