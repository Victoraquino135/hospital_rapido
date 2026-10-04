# Roteiro de demonstração — UBS Rápida

Este ambiente usa somente pessoas, documentos, e-mails e informações de saúde fictícios. A classificação de risco é uma simulação acadêmica manual, realizada pelo perfil de enfermagem, e não substitui avaliação clínica real.

## Preparação

1. Execute `INICIAR_TUDO.bat` na raiz do projeto.
2. Aguarde as mensagens de criação/verificação dos dados fictícios.
3. Confirme o backend em `http://127.0.0.1:8000/docs` e a abertura do Flutter.
4. O seed é idempotente: contas, consultas e horários já existentes não são duplicados.

## Contas fictícias

| Perfil | Nome | CPF | Senha | Uso na demonstração |
|---|---|---|---|---|
| Administrador | Ana Administração Fictícia | 12345678909 | Admin@123 | Gestão de usuários, especialidades e agendas |
| Recepção | Rita Recepção Fictícia | 98765432100 | Recepcao@123 | Check-in e ausência |
| Enfermagem | Enf. Helena Triagem Fictícia | 39053344705 | Enfermagem@123 | Triagem manual |
| Profissional — Clínica Geral | Dr. Paulo Clínica Fictício | 11144477735 | Profissional@123 | Chamada e atendimento |
| Profissional — Pediatria | Dra. Lívia Pediatria Fictícia | 16899535009 | Pediatria@123 | Chamada e atendimento pediátrico |
| Paciente | Paciente Demonstração | 52998224725 | Paciente@123 | Agendamento, cancelamento e reagendamento |

Pacientes adicionais do cenário usam a senha `PacienteFluxo@123`. Entre eles estão Carlos Agendado, Bianca Cancelada, Marina Reagendada, Lucas Check-in, Joana Triagem, Rafael Atendimento e Camila Concluída, todos fictícios.

## Ordem exata da demonstração

### 1. Login e redirecionamento automático

1. Entre com o CPF do paciente, sem escolher perfil.
2. Confirme que o painel do paciente abre automaticamente.
3. Repita brevemente com recepção, enfermagem, profissional e administrador.

Resultado esperado: cada CPF abre somente a tela correspondente ao perfil salvo no servidor.

**Evidência:** print da tela inicial de cada perfil, sem exibir token ou senha.

### 2. Agendamento pelo paciente

1. Entre como Paciente Demonstração.
2. Abra o agendamento.
3. Escolha Clínica Geral ou Pediatria, profissional, data e horário disponíveis.
4. Confirme.

Resultado esperado: consulta com status **Agendada** e horário removido da disponibilidade. O sistema impede duas reservas da mesma vaga e uma segunda consulta ativa da mesma especialidade no mesmo dia.

**Evidência:** print da vaga antes, confirmação da consulta e vaga indisponível depois.

### 3. Reagendamento

1. Em uma consulta agendada com mais de 12 horas de antecedência, selecione reagendar.
2. Escolha outro horário disponível e confirme.

Resultado esperado: o horário anterior volta a ficar disponível, o novo fica reservado e a consulta continua ativa como **Agendada**, com data e horário atualizados. O histórico registra o reagendamento.

**Evidência:** print antes e depois com os dois horários.

### 4. Cancelamento

1. Em uma consulta com mais de 24 horas de antecedência, selecione cancelar.
2. Confirme a operação.

Resultado esperado: status **Cancelada** e vaga novamente disponível. Fora do prazo, o servidor recusa a ação.

**Evidência:** print do status e da vaga liberada.

### 5. Fluxo presencial completo

1. Deixe uma consulta do dia em **Agendada**.
2. Entre como Recepção e faça o **Check-in**.
3. Entre como Enfermagem. Localize somente os pacientes com chegada registrada, abra **Classificar risco**, selecione um dos quatro níveis fictícios e salve.
4. Entre como o profissional vinculado. Clique em **Chamar paciente**.
5. Clique em **Iniciar atendimento**; confirme **Em atendimento**.
6. Clique em **Concluir atendimento**; confirme **Concluída**.
7. Entre novamente como paciente e confira o status atualizado.

Resultado esperado: **Agendada → Check-in realizado → Em triagem → Em atendimento → Concluída**, com horários e histórico gravados.

**Evidência:** um print por transição e vídeo contínuo do fluxo.

## Permissões verificáveis

- **Paciente:** vê apenas os próprios dados e consultas; agenda, cancela e reagenda dentro dos prazos.
- **Recepção:** vê a agenda administrativa, confirma chegada e registra ausência; não classifica risco.
- **Enfermagem:** vê somente pacientes com check-in aguardando/em triagem e registra classificação manual; não administra usuários nem inicia/conclui atendimento.
- **Profissional de saúde:** vê somente consultas atribuídas e encaminhadas pela triagem; chama, inicia e conclui; não classifica risco nem administra usuários.
- **Administrador:** gerencia equipe interna, especialidades, profissionais, grades, horários e vagas; acompanha dados gerais; não classifica risco.

## Limites acadêmicos

- Não há prontuário completo, prescrição, medicamentos, vacinação, pagamentos ou integração oficial com o SUS.
- Os níveis de risco são simples e fictícios: Muito alto, Alto, Médio e Baixo.
- Não há classificação automática. A ação é exclusiva da enfermagem autenticada.
- Registre somente observações curtas e fictícias; não use dados reais de saúde.

## Plano para vídeo de 6 a 10 minutos

1. **0:00–1:00:** objetivo, aviso acadêmico e Swagger.
2. **1:00–2:30:** login do paciente e agendamento.
3. **2:30–3:30:** reagendamento e cancelamento, mostrando liberação das vagas.
4. **3:30–4:30:** login da recepção e check-in.
5. **4:30–6:00:** login da enfermagem, aviso da simulação e classificação manual.
6. **6:00–7:30:** login do profissional, chamada, início e conclusão.
7. **7:30–8:30:** retorno ao paciente e status concluído.
8. **8:30–9:30:** painel administrativo com duas especialidades, profissionais e vagas.
9. **9:30–10:00:** mencionar testes aprovados e limites do projeto.

Evite gravar senhas sendo digitadas, tokens, o conteúdo do arquivo `.env` ou dados que não pertençam ao cenário fictício.

## Pontos sugeridos para prints

- `[PRINT 01]` Login por CPF sem seletor público de perfil.
- `[PRINT 02]` Duas especialidades e horários disponíveis.
- `[PRINT 03]` Consulta agendada.
- `[PRINT 04]` Reagendamento e vaga anterior liberada.
- `[PRINT 05]` Cancelamento e vaga liberada.
- `[PRINT 06]` Recepção após check-in.
- `[PRINT 07]` Enfermagem com aviso acadêmico e classificação.
- `[PRINT 08]` Profissional chamando o paciente.
- `[PRINT 09]` Atendimento concluído.
- `[PRINT 10]` Paciente vendo o status final.
