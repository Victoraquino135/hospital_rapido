# UBS Saúde & Cuidado — Documentação de Acesso e Cadastro

## 1. Objetivo

Esta documentação descreve as telas de acesso criadas no aplicativo Flutter: login, cadastro público de paciente, identificação de responsável legal para menores de idade e recuperação de senha. O cadastro público é exclusivo para pacientes; os demais perfis são administrados internamente.

## 2. Perfis e responsabilidades de cadastro

| Perfil | Quem realiza o cadastro |
| --- | --- |
| Paciente maior de idade | O próprio paciente |
| Paciente menor de idade | O paciente, com os dados do responsável legal |
| Profissional de saúde | Administrador |
| Recepcionista | Administrador |
| Agente Comunitário de Saúde (ACS) | Administrador |
| Administrador | Responsável pelo sistema |

## 3. Telas do aplicativo

### 3.1 Login

Permite que o paciente informe CPF ou Cartão SUS e senha para acessar o aplicativo. Também oferece os atalhos **Criar conta**, **Esqueci minha senha** e **Recursos de acessibilidade**.

### 3.2 Opções de atendimento: vacinação e retirada de medicamentos

Após concluir uma consulta, o paciente poderá acessar as opções abaixo:

- **Vacinação:** acesso às informações e aos serviços relacionados à vacinação na UBS.
- **Retirada de medicamentos:** acesso às informações para solicitar ou acompanhar a retirada de medicamentos disponibilizados pela UBS.

Essas opções complementam o atendimento realizado na consulta e serão desenvolvidas nas próximas etapas do projeto.

### 3.3 Cadastro de paciente

Permite o cadastro público de pacientes de qualquer idade. O formulário possui nome completo, CPF, CNS opcional, data de nascimento, e-mail, telefone, senha e confirmação de senha.

Quando a idade calculada a partir da data de nascimento for menor que 18 anos, o sistema direciona para a tela de responsável legal. Para pacientes maiores de idade, o cadastro é enviado diretamente à API de demonstração.

### 3.4 Responsável legal

Solicitada apenas para paciente menor de 18 anos. Reúne nome completo, CPF, data de nascimento, parentesco, telefone e e-mail opcional. Se o parentesco escolhido for **Outro responsável legal**, o campo para descrevê-lo é apresentado.

### 3.5 Recuperação e redefinição de senha

A primeira tela solicita CPF ou CNS e data de nascimento. Após validação local, o usuário avança para a definição de uma nova senha e confirmação da senha.

### 3.6 Acessibilidade

A tela apresenta as opções de alto contraste e texto ampliado, além de informar os cuidados de legibilidade e áreas de toque usadas no formulário. A persistência dessas preferências ainda deve ser implementada.

## 4. Requisitos funcionais (RF)

| ID | Requisito |
| --- | --- |
| RF-01 | O sistema deve permitir login com CPF ou Cartão SUS e senha. |
| RF-02 | O sistema deve permitir que um paciente inicie seu próprio cadastro pelo botão **Criar conta**. |
| RF-03 | O cadastro de paciente deve exigir nome completo, CPF, data de nascimento, e-mail, telefone, senha e confirmação de senha. |
| RF-04 | O Cartão Nacional de Saúde (CNS) deve ser opcional. |
| RF-05 | O sistema deve calcular a idade com base na data de nascimento. |
| RF-06 | Quando o paciente tiver menos de 18 anos, o sistema deve solicitar os dados do responsável legal antes de concluir o cadastro. |
| RF-07 | O responsável legal deve informar nome completo, CPF, data de nascimento, parentesco e telefone; e-mail é opcional. |
| RF-08 | O sistema deve oferecer os parentescos Mãe, Pai, Avó/Avô, Tutor(a) legal e Outro responsável legal. |
| RF-09 | Ao escolher Outro responsável legal, o sistema deve solicitar a descrição do parentesco. |
| RF-10 | O sistema deve validar o CPF pelo algoritmo dos dígitos verificadores e rejeitar números repetidos. |
| RF-11 | O sistema deve aplicar máscara de CPF, CNS, telefone e data durante a digitação. |
| RF-12 | O sistema deve validar nome completo, e-mail, telefone, data e senha antes de avançar. |
| RF-13 | O sistema deve permitir iniciar a recuperação de senha com CPF/CNS e data de nascimento. |
| RF-14 | O sistema deve exigir confirmação idêntica da nova senha. |
| RF-15 | O cadastro de paciente maior de idade deve chamar a rota `POST /patients/register`. |

## 5. Requisitos não funcionais (RNF)

| ID | Requisito |
| --- | --- |
| RNF-01 | Os formulários devem ser responsivos e adaptar-se a celular e desktop. |
| RNF-02 | Em desktop, o cartão de formulário deve ter largura máxima de 560 px; em telas menores, deve ocupar o espaço disponível com margens. |
| RNF-03 | Campos devem possuir área de toque ampla, com altura aproximada de 52 px ou mais. |
| RNF-04 | Texto de campos e botões deve manter tamanho legível, preferencialmente 16 px ou superior. |
| RNF-05 | Os campos devem ter espaçamento vertical de 18 px para facilitar leitura e toque. |
| RNF-06 | A interface deve usar rótulos visíveis, ícones de apoio e mensagens de validação compreensíveis. |
| RNF-07 | A senha deve ser ocultada por padrão e poder ser mostrada ou ocultada pelo usuário. |
| RNF-08 | Dados de pacientes reais não devem ser usados nesta versão de demonstração. |
| RNF-09 | Para produção, o sistema deve atender à LGPD, com autenticação segura, criptografia, auditoria e controle de acesso por perfil. |

## 6. Regras de validação

| Campo | Regra |
| --- | --- |
| Nome completo | Obrigatório; de 3 a 80 caracteres; deve conter nome e sobrenome; aceita letras, acentos e espaços. |
| CPF | Obrigatório; 11 dígitos; máscara `000.000.000-00`; validação dos dígitos verificadores; não aceita todos os números iguais. |
| CNS | Opcional; quando informado, deve ter 15 dígitos e iniciar com 1, 2, 7, 8 ou 9. A validação integral do algoritmo CNS ainda é pendente. |
| Data de nascimento | Obrigatória; formato `DD/MM/AAAA`; não pode ser futura, anterior a 1900 ou indicar mais de 120 anos. |
| E-mail | Obrigatório no paciente e opcional no responsável; formato de e-mail válido; máximo de 100 caracteres. |
| Telefone | Obrigatório; celular brasileiro com DDD e 11 dígitos; máscara `(00) 00000-0000`. |
| Senha | Obrigatória; entre 8 e 32 caracteres, contendo letra maiúscula, minúscula, número e caractere especial. |
| Confirmação de senha | Obrigatória e idêntica à senha. |
| Parentesco | Obrigatório para responsável legal. |

## 7. Fluxo principal

```text
Login
 ├─ Criar conta
 │   └─ Cadastro de paciente
 │       └─ Data de nascimento
 │           ├─ 18 anos ou mais → validar e enviar cadastro
 │           └─ Menor de 18 anos → informar responsável legal → validar e concluir
 └─ Esqueci minha senha
     └─ Confirmar identidade → definir nova senha
```

## 8. Integração atual e pendências

O aplicativo possui a rota `POST /patients/register` na API FastAPI. Ela recebe e valida os dados básicos de um paciente maior de idade e devolve confirmação de sucesso.

Esta é uma implementação demonstrativa: os dados ainda não são persistidos em PostgreSQL. Para tornar o fluxo apto para produção, devem ser implementados armazenamento seguro de senhas com hash, banco de dados, unicidade de CPF/CNS, gravação do responsável legal, envio de código real para recuperação de senha, autenticação JWT, autorização por perfil, auditoria e adequação completa à LGPD.

## 9. Prompt organizado a partir do briefing

```text
Crie para o aplicativo UBS Saúde & Cuidado telas Flutter responsivas de login, cadastro de paciente, responsável legal para menor de idade e recuperação de senha, seguindo visual parecido com a referência: cartão centralizado, identidade azul, campos amplos, botões destacados e bom espaçamento.

Regras de perfis:
- Paciente maior de idade: faz o próprio cadastro.
- Paciente menor de idade: faz cadastro com dados do responsável legal.
- Profissional, recepcionista e ACS: cadastrados apenas pelo administrador.
- Administrador: criado/configurado pelo responsável pelo sistema.

Cadastro do paciente:
- CPF obrigatório e válido pelo algoritmo de CPF.
- CNS opcional, com 15 dígitos quando preenchido.
- Nome completo obrigatório, com nome e sobrenome, apenas letras e espaços, de 3 a 80 caracteres.
- Data de nascimento obrigatória, não futura e entre 1900 e hoje.
- E-mail obrigatório e válido.
- Telefone obrigatório no formato brasileiro com DDD.
- Senha obrigatória, entre 8 e 32 caracteres, com letra maiúscula, minúscula, número e caractere especial.
- Confirmação de senha deve ser igual à senha.

Regra de idade:
- Se o paciente tiver 18 anos ou mais, não deve informar responsável.
- Se tiver menos de 18 anos, abrir uma etapa de responsável legal.

Dados do responsável legal:
- Nome completo obrigatório.
- CPF obrigatório e válido.
- Data de nascimento obrigatória e não futura.
- Parentesco obrigatório: Mãe, Pai, Avó/Avô, Tutor(a) legal ou Outro responsável legal.
- Se escolher Outro responsável legal, mostrar campo para explicar o parentesco.
- Telefone obrigatório e e-mail opcional.

Recuperação de senha:
- Solicitar CPF ou CNS e data de nascimento.
- Depois permitir informar e confirmar a nova senha.

Requisitos visuais e de acessibilidade:
- Em celular, o formulário deve usar a largura disponível com margens.
- Em desktop, o formulário deve ter largura máxima de aproximadamente 560 px.
- Campos e botões devem ter ao menos 52 px de altura, fonte legível e espaçamento vertical confortável.
- Usar rótulos claros, ícones de apoio e mensagens de validação em português.
```
