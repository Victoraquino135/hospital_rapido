# 1 DEFINIÇÃO DO PROJETO

## 1.1 TEMA E CONTEXTO

O projeto aborda o desenvolvimento de um sistema digital voltado ao agendamento de consultas, triagem e gerenciamento do fluxo de atendimento em Unidades Básicas de Saúde (UBS). A proposta surge da necessidade observada em unidades de saúde de bairro onde, pela ausência de canais virtuais, os pacientes enfrentam longas filas e esperas excessivas em uma dupla jornada: precisam deslocar-se presencialmente à unidade apenas para marcar uma consulta para uma data futura e, posteriormente, retornar para o atendimento. A solução busca reduzir esse deslocamento desnecessário ao transferir parte do processo de agendamento para o meio digital, otimizando o tempo da comunidade e contribuindo para a redução da sobrecarga na recepção da unidade.

No contexto da Atenção Primária à Saúde, o sistema atua além da simples marcação de consultas, incorporando recursos de triagem e identificação de critérios de prioridade, como idosos, pessoas com deficiência (PCD) e gestantes, auxiliando a equipe da unidade na organização do fluxo de atendimento. A plataforma permitirá ao paciente realizar e acompanhar seus agendamentos, acessar a opção de vacinação e, após a conclusão da consulta, consultar a orientação para retirada de medicamentos na própria UBS. Enquanto isso, a equipe poderá utilizar uma interface desktop para gerenciar pacientes, consultas, agendas e atendimentos. Dessa forma, o sistema busca proporcionar maior organização, previsibilidade e eficiência no atendimento, contribuindo para um acesso mais adequado aos serviços oferecidos pela unidade.

## 1.2 PROBLEMA

Em diversas Unidades Básicas de Saúde (UBS), a marcação e o gerenciamento de consultas ainda dependem do atendimento presencial. Esse modelo exige que o cidadão se desloque até a unidade e, em determinados casos, aguarde em filas na recepção apenas para agendar um atendimento para uma data futura. Essa dinâmica pode representar uma dificuldade para diferentes públicos, especialmente pessoas com dificuldades de locomoção, gestantes e trabalhadores que possuem horários limitados, além de contribuir para a sobrecarga da recepção e da estrutura física da unidade.

Sob a perspectiva da gestão da unidade, a ausência de um canal digital integrado pode dificultar a organização das agendas, a identificação de critérios de prioridade e o acompanhamento dos atendimentos. A falta de mecanismos digitais de confirmação e acompanhamento dos horários também pode contribuir para o esquecimento de consultas e para o não comparecimento dos pacientes, ocasionando o desperdício de vagas disponíveis. Além disso, o paciente pode não receber de forma organizada as informações sobre vacinação e sobre a retirada de medicamentos após sua consulta. Consequentemente, a equipe da recepção permanece responsável por uma quantidade elevada de procedimentos administrativos que poderiam ser realizados de forma digital.

Diante desse cenário, define-se como problema central desta pesquisa: como um sistema digital integrado, com interface mobile para pacientes e desktop para a equipe da UBS, pode otimizar o agendamento, auxiliar na identificação de critérios de prioridade, no acompanhamento de consultas e na orientação pós-consulta sobre vacinação e retirada de medicamentos, contribuindo para reduzir a sobrecarga presencial na recepção de uma Unidade Básica de Saúde?

## 1.3 SOLUÇÃO PROPOSTA

A solução proposta consiste em uma plataforma digital integrada projetada para gerenciar e otimizar o fluxo operacional das Unidades Básicas de Saúde (UBS) nas etapas de pré-atendimento, atendimento presencial e pós-consulta. O sistema é composto por duas aplicações com acesso multiplataforma: uma interface voltada ao paciente, disponível por aplicativo mobile e navegador web, e um painel operacional e administrativo voltado às equipes de recepção, enfermagem, corpo médico, farmácia e gestão.

Na interface do paciente, o cidadão realiza a gestão do seu cadastro, consulta as especialidades disponíveis, agenda consultas e acompanha o estado de suas solicitações. Ao comparecer à UBS na data agendada, o atendimento presencial é registrado no painel administrativo por meio do check-in realizado pela recepção. Em seguida, a equipe de enfermagem realiza a triagem clínica no sistema, inserindo os dados vitais e atribuindo a classificação de risco. Essas informações alimentam a fila de espera do médico, organizada por prioridade clínica, grupos prioritários e horário de chegada, permitindo ao profissional iniciar, conduzir e registrar o encerramento do atendimento.

Ao finalizar a consulta, o médico sinaliza no sistema se houve orientação para retirada de itens disponíveis no dispensário da unidade. Essa sinalização ativa, de forma condicional, a funcionalidade **Retirar Medicamento** na interface do paciente, exibindo as orientações para a retirada presencial na UBS, conforme as regras da unidade. O módulo não realiza vendas, cobranças, reserva de estoque, entregas ou integração com farmácias privadas.

Adicionalmente, o sistema disponibiliza o módulo **Vacinação**, uma área informativa na qual o paciente consulta o calendário de imunização e os horários da sala de vacinas. As informações sobre a disponibilidade de doses serão divulgadas e atualizadas pela equipe responsável da UBS, de acordo com a organização da unidade.

Com essa arquitetura acessível por mobile e desktop, a solução reduz deslocamentos desnecessários para a marcação de consultas, estabelece um fluxo de triagem mais transparente para a gestão da UBS e dá mais previsibilidade ao paciente durante as etapas do atendimento, incluindo vacinação e a retirada de medicamentos após a consulta.

## 1.4 OBJETIVO

Desenvolver um sistema digital integrado, composto por um aplicativo para pacientes e uma interface para os profissionais da Unidade Básica de Saúde (UBS), com foco na otimização do fluxo de agendamento presencial. O sistema visa permitir a marcação remota de consultas presenciais de rotina e acompanhamento, realizar o pré-filtro dos pacientes por classificação de risco e grupos prioritários, como idosos, gestantes e pessoas com deficiência (PCDs), e reduzir as filas presenciais relacionadas ao processo de agendamento de consultas na unidade. Também visa disponibilizar ao paciente uma opção de vacinação e, após a consulta, uma opção para consultar e realizar a retirada presencial de medicamentos na UBS.

# 2 USUÁRIOS E STAKEHOLDERS

## 2.1 USUÁRIOS FINAIS

| Perfil de usuário | Necessidade principal | Ações no sistema |
| --- | --- | --- |
| Paciente | Agendar consultas presenciais de forma remota, evitando deslocamentos à UBS apenas para realizar a marcação. | Criar conta, realizar login, recuperar acesso, atualizar dados pessoais, consultar especialidades e profissionais, visualizar datas e horários disponíveis, realizar, cancelar e reagendar consultas, acompanhar o status do atendimento, acessar a opção de vacinação e, após a consulta concluída, consultar a opção de retirada presencial de medicamentos. |
| Recepcionista | Organizar o fluxo de chegada dos pacientes e validar os agendamentos para o atendimento na UBS. | Consultar os agendamentos do dia, confirmar a presença do paciente na chegada, registrar faltas, organizar a fila de atendimento e acompanhar o fluxo dos pacientes. |
| Enfermeiro | Realizar o acolhimento inicial e a triagem dos pacientes conforme critérios de prioridade. | Visualizar os pacientes agendados, realizar e registrar a triagem, classificar a prioridade do atendimento e identificar grupos prioritários, como idosos, pessoas com deficiência (PCDs) e gestantes. |
| Médico | Visualizar e gerenciar sua agenda diária de atendimentos presenciais. | Consultar pacientes agendados, visualizar informações da triagem, acompanhar a ordem de atendimento, atualizar o status da consulta para Em Atendimento, Concluído ou Falta e registrar a orientação para retirada de medicamento após a consulta, quando aplicável. |
| Administrador | Gerenciar as configurações da unidade, usuários, profissionais, especialidades e disponibilidade de horários. | Cadastrar e gerenciar profissionais e especialidades, gerenciar usuários, configurar horários de atendimento, disponibilizar vagas na agenda e acompanhar indicadores e informações gerais do sistema. |

## 2.2 STAKEHOLDERS





# 3 ESCOPO E MVP

## 3.1 ESCOPO INCLUÍDO

- Cadastro e autenticação de usuários.
- Gerenciamento dos dados pessoais do paciente.
- Consulta de especialidades e profissionais.
- Agendamento remoto de consultas presenciais.
- Consulta e gerenciamento de agendamentos.
- Gerenciamento da agenda pela recepção e administração.
- Registro de chegada e acompanhamento da fila.
- Triagem e classificação de prioridade.
- Acompanhamento do atendimento pelo médico.
- Opção de vacinação para o paciente.
- Liberação da opção de retirada presencial de medicamentos após a consulta concluída, quando houver orientação ou prescrição registrada pelo profissional.
- Gerenciamento administrativo.
- Geração de relatório da consulta.

## 3.2 FORA DO ESCOPO

### Integrações com sistemas externos

- **Integração com sistemas governamentais:** não será realizada integração com sistemas oficiais do SUS, e-SUS ou outras plataformas governamentais.
- **Integração com planos de saúde:** não serão implementadas consultas de cobertura, autorização de procedimentos, faturamento ou comunicação com operadoras de planos de saúde.
- **Integração com laboratórios e clínicas externas:** o sistema não realizará solicitação automática de exames nem receberá resultados diretamente de laboratórios ou clínicas terceirizadas.
- **Integração com farmácias externas:** não serão disponibilizados recursos para compra, reserva ou entrega de medicamentos por farmácias externas. A retirada prevista no sistema será presencial e realizada somente na UBS, após a consulta.

### Recursos médicos avançados

- **Telemedicina:** não será disponibilizado atendimento médico remoto por chamadas de áudio ou vídeo.
- **Diagnóstico por inteligência artificial:** o sistema não realizará diagnóstico, interpretação automática de sintomas ou recomendação de tratamentos por inteligência artificial.
- **Prescrição médica digital oficial:** não será implementada a emissão de receitas digitais com certificação ou validade oficial.
- **Prontuário eletrônico integrado:** não haverá integração com prontuários eletrônicos de outros sistemas de saúde ou instituições.

### Serviços financeiros e logísticos

- **Pagamentos online:** não será implementado sistema de pagamento, cobrança ou processamento financeiro dentro da plataforma.
- **Entrega de medicamentos:** o sistema não oferecerá serviço de entrega de medicamentos no endereço do paciente; a retirada será presencial na UBS e somente após a consulta.
- **Transporte de pacientes:** não será disponibilizado serviço de solicitação ou gerenciamento de transporte para pacientes.

### Comunicação externa

- **Mensagens por SMS:** não será implementado envio de mensagens por SMS para pacientes ou profissionais.
- **Notificações por WhatsApp:** não haverá integração com o WhatsApp para envio automático de confirmações, lembretes ou comunicados.
- **Chat entre usuários:** não será disponibilizado um sistema de mensagens instantâneas ou chat individual entre pacientes e profissionais.

### Integração com equipamentos

- **Dispositivos médicos:** não será realizada comunicação automática com aparelhos de pressão, glicômetros, oxímetros ou outros dispositivos médicos.
- **Internet das Coisas (IoT):** não serão desenvolvidos recursos para coleta automática de informações provenientes de sensores ou equipamentos conectados.

### Funcionalidades administrativas avançadas

- **Análises preditivas:** não serão implementados recursos de inteligência artificial para previsão de demanda, lotação da UBS ou comportamento dos atendimentos.
- **Integração com sistemas contábeis ou financeiros:** o sistema não realizará comunicação automática com softwares de contabilidade, folha de pagamento ou gestão financeira.
- **Expansão para outras instituições:** nesta versão, o sistema será desenvolvido considerando o funcionamento da UBS definida no projeto, não contemplando uma implantação automática em diferentes redes ou municípios.

## 3.3 REGRAS DE NEGÓCIO

- O paciente deve possuir cadastro e estar autenticado para realizar ou acompanhar agendamentos.
- Um agendamento só poderá ser realizado em horário disponível para a especialidade e o profissional selecionados.
- A recepção deverá registrar a chegada do paciente antes do início da triagem.
- A triagem será registrada pela equipe de enfermagem e deverá considerar dados vitais, classificação de risco e grupos prioritários, como idosos, gestantes e pessoas com deficiência.
- A fila médica será organizada pela classificação de prioridade e pelo horário de chegada do paciente.
- A consulta somente poderá ser marcada como concluída pelo médico responsável pelo atendimento.
- A opção **Retirar Medicamento** será exibida ao paciente somente após a consulta concluída e quando o médico registrar a orientação para retirada na UBS.
- A retirada de medicamentos ocorrerá presencialmente na UBS, conforme as regras da unidade; o sistema não realizará venda, reserva de estoque ou entrega.
- A opção **Vacinação** terá caráter informativo, apresentando o calendário de imunização e os horários da sala de vacinas divulgados pela UBS.

## 3.4 DEFINIÇÃO DO MVP

O Produto Mínimo Viável (MVP) reunirá as funcionalidades essenciais para testar o fluxo de atendimento da UBS e validar a utilidade do sistema com pacientes e profissionais. Nesta primeira versão, serão priorizados:

- Cadastro, login e recuperação de acesso do paciente.
- Consulta de especialidades, profissionais, datas e horários disponíveis.
- Agendamento, cancelamento, reagendamento e acompanhamento de consultas presenciais.
- Check-in do paciente pela recepção e visualização da fila de atendimento.
- Registro de triagem e classificação de prioridade pela enfermagem.
- Atualização do estado da consulta pelo médico.
- Exibição da opção de retirada presencial de medicamento após consulta concluída e orientação registrada.
- Área informativa de vacinação com calendário e horários divulgados pela UBS.
- Painel administrativo para gerenciamento básico de usuários, profissionais, especialidades e agendas.

# 4 REQUISITOS DO SISTEMA

## 4.1 REQUISITOS FUNCIONAIS

| ID | Requisito funcional |
| --- | --- |
| RF-01 | O sistema deve permitir que o paciente crie uma conta, faça login e recupere o acesso. |
| RF-02 | O sistema deve permitir que o paciente atualize seus dados pessoais. |
| RF-03 | O sistema deve apresentar especialidades, profissionais, datas e horários disponíveis para consulta. |
| RF-04 | O sistema deve permitir que o paciente agende, cancele, reagende e acompanhe consultas presenciais. |
| RF-05 | O sistema deve permitir que a recepção registre o check-in do paciente e acompanhe a fila de atendimento. |
| RF-06 | O sistema deve permitir que a enfermagem registre a triagem, os dados vitais e a classificação de prioridade do paciente. |
| RF-07 | O sistema deve organizar a fila médica conforme a prioridade definida na triagem e o horário de chegada. |
| RF-08 | O sistema deve permitir que o médico atualize o estado da consulta para Em Atendimento, Concluído ou Falta. |
| RF-09 | O sistema deve permitir que o médico registre a orientação para retirada de medicamento após a consulta. |
| RF-10 | O sistema deve exibir a opção Retirar Medicamento ao paciente somente quando a consulta estiver concluída e houver orientação registrada pelo médico. |
| RF-11 | O sistema deve informar que a retirada do medicamento é presencial na UBS e segue as regras da unidade. |
| RF-12 | O sistema deve disponibilizar uma área de vacinação com calendário de imunização e horários da sala de vacinas. |
| RF-13 | O sistema deve permitir que a administração gerencie usuários, profissionais, especialidades e horários de atendimento. |
