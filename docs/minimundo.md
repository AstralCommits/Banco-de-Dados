# Minimundo — TRAMA

## 1. Contexto

A TRAMA é um sistema para acompanhar as vendas das confecções e facções do Nordeste, com foco no polo de confecções de Pernambuco, Paraíba e Alagoas. Hoje cada empresa controla as próprias vendas em cadernos ou planilhas soltas, e ninguém tem uma visão da região como um todo.

O sistema reúne, todo mês, quanto cada confecção vendeu em cada categoria de produto. A partir desses dados, ele gera relatórios por estado, por categoria e por período, aponta tendências de alta ou queda e permite simular o efeito da concorrência nas vendas. Além dos números, a rede faz entrevistas com os empresários para comparar o que eles percebem do mercado com o que os dados mostram.

## 2. Usuários

O sistema tem dois perfis de usuário:

- **ADMIN:** administra a rede. Não pertence a nenhuma confecção. Gera relatórios de toda a região e cria cenários de concorrência.
- **CONFECCAO:** representa uma única confecção. Informa as vendas da sua empresa (à mão ou por planilha), cria cenários e gera relatórios.

Todo usuário tem nome, e-mail (único no sistema) e senha, que é guardada criptografada (hash).

## 3. O que o sistema guarda

### Cidades e confecções

Cada **confecção** fica em uma única **cidade**, e cada cidade pertence a um estado (UF). Uma cidade pode ter várias confecções.

De cada confecção o sistema guarda o nome, o CNPJ, o porte e o tipo:
- **CNPJ:** opcional, porque muitas empresas do polo são informais. Quando informado, não pode se repetir.
- **Porte:** MICRO, PEQUENA ou MEDIA.
- **Tipo:** CONFECCAO (produz e vende a peça) ou FACCAO (presta serviço de costura para outras empresas).

### Categorias

As vendas são classificadas em **categorias** de produto, como Moda Feminina, Moda Masculina, Moda Infantil, Fitness e Praia. O nome de cada categoria é único.

### Lançamentos mensais

O **lançamento mensal** é o registro central do sistema. Ele informa quantas peças uma confecção vendeu em uma categoria em determinado mês, e quanto faturou com isso.

- O mês é sempre guardado como o dia 1 daquele mês.
- Cada confecção só pode ter **um** lançamento por categoria em cada mês.
- O lançamento pode ser digitado à mão (origem **MANUAL**) ou vir de uma planilha (origem **IMPORTACAO**). Quando vem de planilha, fica ligado à importação que o gerou.
- Um lançamento errado pode ser **cancelado**. Ele continua guardado no banco, com status CANCELADO, mas deixa de contar nos indicadores e relatórios. Lançamentos válidos têm status ATIVO.
- Toda alteração ou exclusão de lançamento fica registrada num **histórico**, com os valores de antes e de depois da mudança, quem a fez, a data e a origem do lançamento (manual ou planilha). O administrador consulta esse histórico em relatórios por período, por usuário e por confecção.

### Importações de planilha

O usuário pode enviar uma **planilha** com vários lançamentos de uma vez. O sistema guarda o nome do arquivo, a data da importação, quantas linhas a planilha tinha, quem a enviou e o resultado (CONCLUIDA ou ERRO).

A importação é **tudo ou nada**: se qualquer linha da planilha estiver inválida, nenhum lançamento dela é gravado, e a tentativa fica registrada com status ERRO.

### Cenários de concorrência

O usuário pode criar **cenários de concorrência** para simular situações do mercado, como "Entrada de novo concorrente". Cada cenário tem um nome, uma descrição opcional e um percentual de impacto entre 0 e 100.

Um cenário pode valer para uma categoria específica ou, se nenhuma categoria for escolhida, para todas.

### Relatórios

O usuário gera **relatórios** sobre um período (data de início e de fim). Existem quatro tipos:

- **REGIONAL:** compara os estados (PE, PB e AL).
- **CATEGORIA_PERIODO:** mostra as vendas por categoria no período.
- **TENDENCIA:** aponta quais vendas estão em alta, em queda ou estáveis.
- **CENARIO:** aplica um cenário de concorrência às vendas. Só esse tipo usa cenário, e para ele o cenário é obrigatório.

Cada relatório guarda quem o gerou, quando foi gerado e o **limiar de tendência**: o percentual de variação a partir do qual uma venda é considerada em alta ou em queda.

O resultado do relatório fica em **itens de relatório**. Cada item traz a UF ou a categoria, a quantidade, o faturamento, a variação percentual e a tendência (ALTA, QUEDA ou ESTAVEL). Todo relatório tem pelo menos um item. Se não houver dados no período, o relatório não é gravado.

### Entrevistas

A rede faz **entrevistas** com as confecções. Cada entrevista guarda a data, um resumo da conversa, se o empresário percebeu alguma novidade no mercado (SIM ou NAO) e a categoria que ele **acha** que mais vende. O empresário pode não saber ou não responder essa última pergunta.

Comparar a categoria percebida com as vendas reais mostra se o empresário conhece bem o próprio negócio.

## 4. Regras de negócio

| # | Regra |
|---|---|
| RN01 | Cada confecção fica em uma única cidade; o CNPJ é opcional, mas não pode se repetir. |
| RN02 | O usuário ADMIN não pertence a nenhuma confecção; o usuário CONFECCAO pertence a exatamente uma. |
| RN03 | Cada confecção tem no máximo um lançamento por categoria em cada mês. |
| RN04 | Lançamento cancelado não é apagado, mas fica fora dos indicadores e relatórios. |
| RN05 | Se uma linha da planilha for inválida, nada da importação é gravado. |
| RN06 | O impacto de um cenário fica entre 0 e 100; cenário sem categoria vale para todas. |
| RN07 | Relatório do tipo CENARIO exige um cenário; relatórios regionais usam apenas PE, PB ou AL. |
| RN08 | A tendência (ALTA, QUEDA ou ESTAVEL) é definida comparando a variação percentual com o limiar do relatório. |
| RN09 | A entrevista registra a categoria que o empresário acha que mais vende, que pode ficar em branco. |
| RN10 | Todo relatório tem pelo menos um item. |
| RN11 | Toda alteração ou exclusão de lançamento fica registrada no histórico. |

## 5. Requisitos funcionais

| # | Requisito |
|---|---|
| RF01 | Cadastrar cidades, confecções e categorias. |
| RF02 | Cadastrar usuários com perfil ADMIN ou CONFECCAO. |
| RF03 | Registrar lançamentos mensais manualmente. |
| RF04 | Importar lançamentos a partir de uma planilha. |
| RF05 | Corrigir, cancelar e excluir lançamentos. |
| RF06 | Consultar o histórico de alterações dos lançamentos. |
| RF07 | Criar cenários de concorrência. |
| RF08 | Gerar relatórios dos tipos REGIONAL, CATEGORIA_PERIODO, TENDENCIA e CENARIO. |
| RF09 | Registrar entrevistas com as confecções. |
| RF10 | Consultar vendas por estado, por categoria e por período. |

## 6. Requisitos não funcionais

| # | Requisito |
|---|---|
| RNF01 | O banco de dados é MySQL 8.0, com codificação utf8mb4. |
| RNF02 | As senhas são guardadas apenas como hash, nunca em texto puro. |
| RNF03 | Importações e geração de relatórios usam transações, para nunca deixar dados pela metade. |
| RNF04 | O histórico de lançamentos é gravado automaticamente por triggers, sem depender do sistema. |
