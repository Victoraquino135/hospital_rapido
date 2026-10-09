# Redesenho responsivo do frontend UBS Rápida

**Data:** 07/10/2026  
**Status:** design visual aprovado; aguardando revisão da especificação  
**Plataformas principais:** Windows desktop e celular

## Objetivo

Modernizar todas as telas Flutter do UBS Rápida para que pareçam mais naturais, acolhedoras e profissionais, mantendo integralmente a identidade existente, a paleta azul e verde, os fluxos funcionais e os recursos de acessibilidade.

O resultado deve adaptar hierarquia, navegação e densidade de conteúdo à largura disponível. Windows terá aproveitamento horizontal e navegação persistente quando apropriado. Celulares terão conteúdo em coluna, ações fáceis de alcançar e navegação compacta.

## Restrições aprovadas

- Manter a paleta atual; não introduzir uma nova identidade visual.
- Usar o `BrandMark` existente: símbolo circular azul com cruz e assinatura “UBS RÁPIDA”.
- Manter o botão “Preferências de acessibilidade” no canto superior direito no Windows.
- No celular, apresentar o mesmo recurso como controle compacto no topo, com área mínima de toque e descrição semântica.
- Preservar alto contraste, escala de fonte, suporte a leitores de tela, navegação por teclado e foco visível.
- Não alterar contratos da API, regras de negócio, permissões, perfis ou persistência.
- Não substituir os fluxos funcionais já cobertos por testes.

## Direção visual

A interface continuará usando azul, verde, branco e os fundos existentes. A melhoria virá de hierarquia, espaçamento, tipografia e composição, não de uma mudança de cores.

- Reduzir cartões e contornos usados apenas como decoração.
- Reservar cartões para informações ou ações semanticamente agrupadas.
- Dar maior destaque à próxima ação relevante de cada perfil.
- Usar textos curtos e naturais, evitando aparência de painel genérico.
- Padronizar raios, espaçamentos, alturas, estados e densidade.
- Manter sombras discretas e somente onde indiquem elevação real.
- Usar botões principais com pelo menos 48 px de altura; alvos interativos terão no mínimo 48 × 48 px sempre que aplicável.
- Exibir estados de carregamento, vazio, erro, confirmação e indisponibilidade de forma consistente.

## Arquitetura visual

A implementação será incremental, reaproveitando a aplicação existente. Não haverá reescrita completa.

### Fundamentos compartilhados

Criar ou consolidar componentes compartilhados para:

- tokens de espaçamento, tamanhos, raios e larguras máximas;
- botões primário, secundário e destrutivo;
- cabeçalhos de página e seções;
- cartões de informação e de ação;
- estados vazio, carregando e erro;
- campos e mensagens de formulário;
- shell responsivo de página;
- navegação adaptativa;
- diálogos e folhas inferiores responsivas.

Esses componentes devem consumir o tema e o estado global de acessibilidade existentes. Nenhum componente poderá fixar cores que prejudiquem o modo de alto contraste.

### Breakpoints e comportamento

Os breakpoints serão centralizados para evitar decisões diferentes em cada tela.

- **Celular:** conteúdo em uma coluna, margens compactas, ações largas e navegação inferior ou menus compactos quando necessário.
- **Intermediário:** conteúdo fluido, cartões reorganizados e formulários com largura limitada.
- **Windows amplo:** navegação lateral ou painéis lado a lado, conteúdo central com largura máxima e melhor uso horizontal.

O layout deve continuar funcional com fonte ampliada. Nenhuma decisão dependerá apenas da largura nominal da tela; overflow e escala de texto serão testados em conjunto.

## Marca e acessibilidade

O `BrandMark` existente será a fonte única da marca no aplicativo. Imagens alternativas não substituirão esse componente.

O `AccessibilityMenu` continuará global e visível:

- Windows: botão completo “Preferências de acessibilidade” alinhado no canto superior direito;
- celular: controle compacto no topo, com `Semantics`, tooltip e alvo mínimo de 48 × 48 px;
- menu aberto: controles de fonte, alto contraste e leitor de tela responsivos e navegáveis por teclado.

O modo de alto contraste continuará usando preto, branco e amarelo e terá precedência sobre detalhes decorativos do novo layout.

## Telas no escopo

### Acesso e conta

- login;
- cadastro de paciente e responsável;
- verificação e correção de e-mail;
- recuperação e redefinição de senha.

Os formulários terão largura controlada no Windows e ocuparão a largura útil no celular. Erros manterão foco automático, região semântica ativa e conteúdo digitado.

### Paciente

- painel inicial;
- perfil e resumo;
- consultas;
- agendamento;
- cancelamento e reagendamento;
- detalhes da consulta.

A próxima consulta e a ação de agendar serão priorizadas. No celular, informações secundárias serão empilhadas sem esconder status ou ações essenciais.

### Recepção

- resumo diário;
- filtros e busca;
- lista e detalhes de agendamentos;
- check-in e registro de ausência.

No Windows, filtros e resumo poderão usar a largura horizontal. No celular, filtros serão recolhíveis e ações críticas continuarão explícitas.

### Enfermagem e profissional de saúde

- fila;
- detalhes do paciente e atendimento;
- classificação de risco;
- chamada, início e conclusão do atendimento.

Risco, prioridade legal, horário e estado do atendimento terão hierarquia clara. As cores nunca serão o único meio de comunicar risco ou status.

### Administração

- resumo;
- usuários internos;
- profissionais;
- especialidades;
- agendas e grades;
- consultas;
- auditoria;
- criação, edição, ativação, desativação e redefinição de acesso.

No Windows, áreas densas poderão usar painéis e tabelas responsivas. No celular, registros serão apresentados como cartões ou listas legíveis, sem rolagem horizontal obrigatória para ações principais.

## Navegação

- Preservar o redirecionamento atual por perfil e todas as permissões.
- Usar navegação lateral no Windows quando o perfil tiver várias áreas.
- Usar navegação inferior ou menu compacto no celular somente para destinos principais.
- Manter rótulo textual junto a ícones importantes.
- Não esconder ações destrutivas em gestos invisíveis.
- Preservar histórico de navegação e botão voltar de forma previsível.

## Estados e mensagens

- Erros de API continuarão usando as mensagens seguras retornadas pelo backend.
- Falhas de rede apresentarão mensagem clara e possibilidade de tentar novamente.
- Ações assíncronas bloquearão somente o controle relacionado, evitando duplo envio.
- Estados vazios explicarão o que está ausente e oferecerão ação quando houver uma ação válida.
- Confirmações destrutivas mencionarão o objeto afetado.
- Snackbars e diálogos deverão ser legíveis com fonte ampliada e modo de alto contraste.

## Estratégia de implementação

1. Proteger o comportamento atual com testes adicionais de responsividade e acessibilidade.
2. Consolidar tokens e componentes compartilhados.
3. Atualizar o shell global, marca, acessibilidade e navegação adaptativa.
4. Redesenhar acesso e recuperação.
5. Redesenhar as telas do paciente e agendamento.
6. Redesenhar recepção, enfermagem e profissional.
7. Redesenhar administração.
8. Executar regressão completa, análise estática e builds de validação.

Cada etapa deve manter o aplicativo executável e os testes verdes. Refatorações serão limitadas ao código necessário para o redesign.

## Testes e critérios de aceitação

### Automatizados

- Todos os testes Flutter existentes continuam aprovados.
- `flutter analyze` não apresenta problemas.
- Novos testes verificam layouts em larguras de celular e Windows.
- Testes com escala máxima de fonte não apresentam overflow.
- Testes semânticos confirmam marca, acessibilidade, ações principais e estados.
- Testes confirmam alto contraste nos novos componentes compartilhados.
- A suíte backend permanece aprovada, embora o backend não esteja no escopo de alteração.

### Visuais e funcionais

- Nenhuma tela principal apresenta overflow em celular ou Windows.
- O `BrandMark` correto aparece de forma consistente.
- O botão de acessibilidade fica no canto superior direito no Windows.
- Todo botão principal possui altura mínima de 48 px.
- A paleta atual permanece reconhecível.
- Todos os perfis conseguem concluir seus fluxos existentes.
- A interface funciona por teclado no Windows e com leitor de tela/semântica no celular.
- Alto contraste e fonte ampliada permanecem utilizáveis em todas as telas.

## Fora do escopo

- mudanças no backend ou no banco de dados;
- novos perfis, permissões ou funcionalidades clínicas;
- troca de paleta ou criação de nova marca;
- inclusão de bibliotecas pesadas de design sem necessidade;
- reformulação de textos legais ou políticas;
- publicação nas lojas ou implantação em produção.

## Riscos e mitigação

- **Arquivos de tela grandes:** extrair somente componentes diretamente envolvidos na mudança, com testes antes da extração.
- **Regressão por perfil:** trabalhar por fluxo e executar seus testes após cada etapa.
- **Overflow com fonte ampliada:** testar breakpoint e escala em conjunto desde o início.
- **Inconsistência visual:** concentrar tokens e componentes antes de atualizar telas individuais.
- **Perda de acessibilidade:** fazer `AccessibilityMenu`, `Semantics`, foco e contraste parte dos critérios de aceite de cada etapa, não uma revisão final.

