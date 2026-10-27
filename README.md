SQL | TRAMA

# Banco de Dados

## Modelo conceitual

No modelo conceitual não aparecem chaves estrangeiras: elas surgem como colunas só no modelo lógico.

```mermaid
erDiagram
    CIDADE ||--o{ CONFECCAO : localiza
    CONFECCAO |o--o{ USUARIO : possui
    CONFECCAO ||--o{ LANCAMENTO_MENSAL : informa
    CATEGORIA ||--o{ LANCAMENTO_MENSAL : classifica
    IMPORTACAO |o--o{ LANCAMENTO_MENSAL : origina
    USUARIO ||--o{ IMPORTACAO : realiza
    USUARIO ||--o{ CENARIO_CONCORRENCIA : cria
    USUARIO ||--o{ RELATORIO : gera
    CATEGORIA |o--o{ CENARIO_CONCORRENCIA : simula
    CENARIO_CONCORRENCIA |o--o{ RELATORIO : fundamenta
    RELATORIO ||--|{ ITEM_RELATORIO : possui
    CATEGORIA |o--o{ ITEM_RELATORIO : agrupa
    CONFECCAO ||--o{ ENTREVISTA : responde
    CATEGORIA |o--o{ ENTREVISTA : "é percebida em"
    LANCAMENTO_MENSAL ||--o{ HISTORICO_LANCAMENTO : registra
    USUARIO |o--o{ HISTORICO_LANCAMENTO : altera
```

### Entidades e atributos

| Entidade | Identificador | Demais atributos |
|---|---|---|
| **Cidade** | id_cidade | nome, uf |
| **Confecção** | id_confeccao | nome, cnpj (opcional), porte (micro, pequena, média), tipo (confecção, facção) |
| **Usuário** | id_usuario | nome, email, senha_hash, perfil (ADMIN, CONFECCAO) |
| **Categoria** | id_categoria | nome |
| **Lançamento mensal** | id_lancamento | mes_referencia, quantidade, faturamento, origem (MANUAL, IMPORTACAO), status (ATIVO, CANCELADO) |
| **Importação** | id_importacao | nome_arquivo, data_importacao, qtd_linhas, status (CONCLUIDA, ERRO) |
| **Cenário de concorrência** | id_cenario | nome, percentual_impacto, descricao (opcional) |
| **Entrevista** | id_entrevista | data, resumo, achou_algo_novo (sim, não) |
| **Relatório** | id_relatorio | tipo (REGIONAL, CATEGORIA_PERIODO, TENDENCIA, CENARIO), periodo_inicio, periodo_fim, limiar_tendencia, data_geracao |
| **Item de relatório** | id_item | uf (opcional), quantidade, faturamento, variacao_percentual, tendencia (ALTA, QUEDA, ESTAVEL) |
| **Histórico de lançamento** | id_historico | acao (UPDATE, DELETE), origem (MANUAL, IMPORTACAO), mes_referencia, quantidade_antiga, faturamento_antigo, status_antigo, quantidade_nova, faturamento_novo, status_novo (os novos ficam vazios no DELETE), data_alteracao |

## Modelo lógico

```mermaid
erDiagram
    cidade               ||--o{ confeccao            : localiza
    confeccao            |o--o{ usuario              : possui
    confeccao            ||--o{ lancamento_mensal    : informa
    categoria            ||--o{ lancamento_mensal    : classifica
    importacao           |o--o{ lancamento_mensal    : origina
    usuario              ||--o{ importacao           : realiza
    usuario              ||--o{ cenario_concorrencia : cria
    usuario              ||--o{ relatorio            : gera
    categoria            |o--o{ cenario_concorrencia : simula
    cenario_concorrencia |o--o{ relatorio            : fundamenta
    relatorio            ||--|{ item_relatorio       : possui
    categoria            |o--o{ item_relatorio       : agrupa
    confeccao            ||--o{ entrevista           : responde
    categoria            |o--o{ entrevista           : "é percebida em"
    lancamento_mensal    ||..o{ historico_lancamento : registra
    usuario              |o..o{ historico_lancamento : altera

    cidade {
        int     id_cidade PK
        varchar nome
        char    uf
    }
    confeccao {
        int     id_confeccao PK
        varchar nome
        varchar cnpj UK "opcional"
        varchar porte "MICRO | PEQUENA | MEDIA"
        varchar tipo "CONFECCAO | FACCAO"
        int     id_cidade FK
    }
    usuario {
        int     id_usuario PK
        varchar nome
        varchar email UK
        varchar senha_hash
        varchar perfil "ADMIN | CONFECCAO"
        int     id_confeccao FK "NULL se ADMIN"
    }
    categoria {
        int     id_categoria PK
        varchar nome UK
    }
    importacao {
        int       id_importacao PK
        varchar   nome_arquivo
        datetime  data_importacao
        int       qtd_linhas
        varchar   imp_status "CONCLUIDA | ERRO"
        int       id_usuario FK
    }
    lancamento_mensal {
        int     id_lancamento PK
        date    mes_referencia "dia 1 do mês"
        int     quantidade
        decimal faturamento
        varchar origem "MANUAL | IMPORTACAO"
        varchar lanc_status "ATIVO | CANCELADO"
        int     id_confeccao FK
        int     id_categoria FK
        int     id_importacao FK "NULL se MANUAL"
    }
    cenario_concorrencia {
        int     id_cenario PK
        varchar nome
        decimal percentual_impacto "0 a 100"
        varchar descricao "opcional"
        int     id_usuario FK
        int     id_categoria FK "NULL = todas"
    }
    relatorio {
        int       id_relatorio PK
        varchar   tipo "REGIONAL | CATEGORIA_PERIODO | TENDENCIA | CENARIO"
        date      periodo_inicio
        date      periodo_fim
        decimal   limiar_tendencia
        datetime  data_geracao
        int       id_usuario FK
        int       id_cenario FK "obrigatório se CENARIO"
    }
    item_relatorio {
        int     id_item PK
        char    uf "PE | PB | AL, opcional"
        int     quantidade
        decimal faturamento
        decimal variacao_percentual
        varchar tendencia "ALTA | QUEDA | ESTAVEL"
        int     id_relatorio FK
        int     id_categoria FK "opcional"
    }
    entrevista {
        int     id_entrevista PK
        date    data
        text    resumo
        varchar achou_algo_novo "SIM | NAO"
        int     id_confeccao FK
        int     id_categoria_percebida FK "opcional"
    }
    historico_lancamento {
        int       id_historico PK
        int       id_lancamento "sem FK"
        varchar   acao "UPDATE | DELETE"
        varchar   origem "MANUAL | IMPORTACAO"
        date      mes_referencia
        int       id_confeccao "sem FK"
        int       id_categoria "sem FK"
        int       quantidade_antiga
        decimal   faturamento_antigo
        varchar   status_antigo
        int       quantidade_nova "NULL se DELETE"
        decimal   faturamento_novo "NULL se DELETE"
        varchar   status_novo "NULL se DELETE"
        int       id_usuario "sem FK, quem alterou"
        datetime  data_alteracao
    }
```

`historico_lancamento` implementa a entidade Histórico de lançamento e é preenchida pelos triggers. As linhas tracejadas indicam que `id_lancamento` e `id_usuario` **não são FK**: o registro do histórico precisa continuar existindo depois que o lançamento (ou o usuário) é excluído, e uma FK impediria isso. Pelo mesmo motivo a tabela guarda uma cópia de `origem`, `mes_referencia`, `id_confeccao` e `id_categoria`: depois de um DELETE, o lançamento não existe mais para consultar esses dados. Essa repetição é proposital — o histórico é um retrato do lançamento no momento da alteração, não um dado que deva acompanhar mudanças futuras.

**Legenda da cardinalidade:** `||` = exatamente 1 · `|o` = 0 ou 1 · `o{` = 0 ou N · `|{` = 1 ou N

## Relacionamentos e cardinalidades

| Entidade A | Relacionamento | Entidade B |
|---|---|---|
| Cidade (0,N) | localiza | Confecção (1,1) |
| Confecção (0,N) | possui | Usuário (0,1) |
| Confecção (0,N) | informa | Lançamento mensal (1,1) |
| Categoria (0,N) | classifica | Lançamento mensal (1,1) |
| Importação (0,N) | origina | Lançamento mensal (0,1) |
| Usuário (0,N) | realiza | Importação (1,1) |
| Usuário (0,N) | cria | Cenário de concorrência (1,1) |
| Usuário (0,N) | gera | Relatório (1,1) |
| Categoria (0,N) | simula | Cenário de concorrência (0,1) |
| Cenário de concorrência (0,N) | fundamenta | Relatório (0,1) |
| Relatório (1,N) | possui | Item de relatório (1,1) |
| Categoria (0,N) | agrupa | Item de relatório (0,1) |
| Confecção (0,N) | responde | Entrevista (1,1) |
| Categoria (0,N) | é percebida em | Entrevista (0,1) |
| Lançamento mensal (0,N) | registra | Histórico de lançamento (1,1) |
| Usuário (0,N) | altera | Histórico de lançamento (0,1) |

### Justificativa das cardinalidades opcionais

Cada participação (0,1) do modelo existe por causa de uma regra do [minimundo](docs/minimundo.md):

| Relacionamento | Por que é (0,1) | Regra | Garantia no banco |
|---|---|---|---|
| Confecção → Usuário | O ADMIN não pertence a nenhuma confecção | RN02 | `id_confeccao` aceita NULL; perfil validado pelo sistema |
| Importação → Lançamento mensal | O lançamento pode ser digitado à mão (origem MANUAL) | — | `id_importacao` aceita NULL; `origem` guarda MANUAL ou IMPORTACAO |
| Categoria → Cenário de concorrência | Um cenário sem categoria vale para todas | RN06 | FK aceita NULL |
| Cenário de concorrência → Relatório | Só o relatório do tipo CENARIO usa cenário | RN07 | `id_cenario` aceita NULL; tipo validado pelo sistema |
| Categoria → Item de relatório | O relatório REGIONAL agrupa por UF, não por categoria | RN07 | `id_categoria` aceita NULL; UF ou categoria validado pelo sistema |
| Categoria → Entrevista | O empresário pode não saber ou não responder qual categoria vende mais | RN09 | FK aceita NULL |

**Relatório (1,N) → Item de relatório (RN10):** a exigência de pelo menos um item não pode ser garantida por FK, porque o relatório é gravado antes dos itens. Quem garante é a transação de geração do relatório (`transacoes.sql`): se nenhum item for gerado, ela faz `ROLLBACK`.

## Chaves estrangeiras (modelo lógico)

Em um relacionamento 1:N, a FK fica no lado N. Se a cardinalidade desse lado é (1,1), a FK é `NOT NULL`; se é (0,1), ela aceita `NULL`.

| Tabela (lado N) | FK | Referencia | Obrigatória? |
|---|---|---|---|
| confeccao | id_cidade | cidade | Sim |
| usuario | id_confeccao | confeccao | Não (só para perfil CONFECCAO) |
| lancamento_mensal | id_confeccao | confeccao | Sim |
| lancamento_mensal | id_categoria | categoria | Sim |
| lancamento_mensal | id_importacao | importacao | Não (só para origem IMPORTACAO) |
| importacao | id_usuario | usuario | Sim |
| cenario_concorrencia | id_usuario | usuario | Sim |
| cenario_concorrencia | id_categoria | categoria | Não |
| relatorio | id_usuario | usuario | Sim |
| relatorio | id_cenario | cenario_concorrencia | Não (só para tipo CENARIO) |
| item_relatorio | id_relatorio | relatorio | Sim |
| item_relatorio | id_categoria | categoria | Não |
| entrevista | id_confeccao | confeccao | Sim |
| entrevista | id_categoria_percebida | categoria | Não |

## Regras do minimundo e onde são garantidas

A numeração segue o [minimundo](docs/minimundo.md).

| # | Regra | Implementação |
|---|---|---|
| RN01 | Cada confecção fica em uma única cidade; CNPJ opcional, mas sem repetição | `id_cidade NOT NULL`; `cnpj` aceita NULL e é `UNIQUE` |
| RN02 | ADMIN não tem confecção; CONFECCAO tem exatamente uma | `id_confeccao` opcional; combinação validada pelo sistema |
| RN03 | Um lançamento por confecção, categoria e mês | `UNIQUE (id_confeccao, id_categoria, mes_referencia)` |
| RN04 | Lançamento cancelado fica fora dos indicadores e relatórios | Procedure `cancelar_lancamento` muda o status sem apagar; as consultas filtram `lanc_status = 'ATIVO'` |
| RN05 | Linha inválida na planilha: nada da importação é gravado | Transação em `transacoes.sql` |
| RN06 | Impacto entre 0 e 100; cenário sem categoria vale para todas | `id_categoria` opcional; faixa 0–100 validada pelo sistema |
| RN07 | Relatório CENARIO exige cenário; regionais usam PE, PB ou AL | UF (PE, PB ou AL) e cenário obrigatório validados pelo sistema |
| RN08 | Tendência pela variação comparada ao limiar | Calculada ao gerar o relatório |
| RN09 | Entrevista registra a categoria que o empresário *acha* que mais vende | `id_categoria_percebida` aceita NULL |
| RN10 | Todo relatório tem pelo menos um item | Transação em `transacoes.sql` faz `ROLLBACK` se nenhum item for gerado |
| RN11 | Toda alteração ou exclusão de lançamento fica no histórico | Triggers `trg_historico_lancamento_update` e `trg_historico_lancamento_delete`; relatórios em `auditoria.sql` |

## Procedures

| Procedure | Parâmetros | O que faz |
|---|---|---|
| `inserir_lancamento` | mês, quantidade, faturamento, confecção, categoria | Grava um lançamento MANUAL e ATIVO; qualquer dia do mês vira dia 1 |
| `atualizar_lancamento` | id do lançamento, quantidade, faturamento, id do usuário | Corrige quantidade e faturamento |
| `cancelar_lancamento` | id do lançamento, id do usuário | Muda o status para CANCELADO, sem apagar (RN04) |
| `excluir_lancamento` | id do lançamento, id do usuário | Apaga o lançamento de vez |

O id do usuário é quem está fazendo a alteração. A procedure guarda esse id em `@id_usuario` antes de mexer no lançamento, o trigger copia para o histórico, e no fim a procedure limpa a variável. Alterações feitas direto com `UPDATE` ou `DELETE`, sem passar pelas procedures, ficam no histórico como "Nao identificado".

## Triggers

| Trigger | Quando dispara | O que grava em `historico_lancamento` |
|---|---|---|
| `trg_historico_lancamento_update` | Depois de um UPDATE em `lancamento_mensal` | Ação `UPDATE`, origem, mês, confecção, categoria, os valores de antes (`OLD`) e de depois (`NEW`) e o usuário de `@id_usuario` |
| `trg_historico_lancamento_delete` | Depois de um DELETE em `lancamento_mensal` | Ação `DELETE`, os dados e valores do lançamento apagado e o usuário |

Cancelar um lançamento também vai para o histórico, porque o cancelamento é um UPDATE no status.

## Auditoria do histórico

O `auditoria.sql` traz a view e as procedures para monitorar as alterações em lançamentos (RF06). Todas as procedures recebem o período e a origem: `'MANUAL'` para acompanhar só os lançamentos digitados à mão, `'IMPORTACAO'` para os que vieram de planilha, ou `NULL` para todos.

| Objeto | Parâmetros | O que mostra |
|---|---|---|
| `vw_historico_lancamento` (view) | — | Histórico com nomes de confecção, cidade, categoria e usuário, e a diferença de quantidade e faturamento entre antes e depois |
| `relatorio_historico_periodo` | início, fim, origem | Todas as alterações do período, da mais recente para a mais antiga |
| `relatorio_alteracoes_por_usuario` | início, fim, origem | Quantas correções, cancelamentos e exclusões cada usuário fez, e o impacto no faturamento |
| `relatorio_alteracoes_por_confeccao` | início, fim, origem | Quantas alterações cada confecção teve, quantos lançamentos foram mexidos e o impacto no faturamento |

O **impacto no faturamento** é quanto as alterações mudaram o faturamento que entra nos indicadores: numa correção, a diferença entre o valor novo e o antigo; num cancelamento ou exclusão, o valor antigo inteiro, negativo, porque o lançamento sai dos indicadores (RN04).

```sql
CALL relatorio_alteracoes_por_usuario('2026-10-01', '2026-10-31', 'MANUAL');
```

## Transações

| # | Situação | Resultado |
|---|---|---|
| 1 | Importação de planilha sem erros | `COMMIT`: a importação e as linhas são gravadas juntas |
| 2 | Importação com uma linha inválida | `ROLLBACK`: nada da importação é gravado (RN05); depois só a tentativa é registrada com status ERRO |
| 3 | Geração de relatório com um item digitado errado | `ROLLBACK TO SAVEPOINT`: desfaz só o item errado e mantém os anteriores, depois `COMMIT` |
| 4 | Relatório sem nenhum item | `ROLLBACK`: todo relatório precisa de pelo menos um item (RN10) |

## Consultas

O `consultas.sql` traz 10 consultas que juntam as tabelas com `INNER JOIN` e `LEFT JOIN` e usam `COUNT`, `AVG`, `MAX` e `MIN` com `GROUP BY`. Entre elas:

- confecções com cidade e UF;
- lançamentos ativos por UF e faturamento médio por categoria;
- usuários que nunca fizeram importação (`LEFT JOIN`);
- relatórios com o cenário usado e a quantidade de itens;
- histórico de alterações gravado pelos triggers.

## Índices (RNF01)

O RNF01 pede resposta em até 3 segundos com 10.000 vendas. Além das chaves primárias, dos `UNIQUE` e dos índices que o MySQL cria para cada FK, o `schema.sql` cria:

| Índice | Tabela | Colunas | Para quê |
|---|---|---|---|
| `idx_lancamento_mes_categoria` | lancamento_mensal | mes_referencia, id_categoria, id_confeccao, lanc_status, quantidade, faturamento | Agregação de faturamento por período e categoria (RF05/RF06) |
| `idx_lancamento_confeccao` | lancamento_mensal | id_confeccao | Filtro por confecção e, pela junção com `confeccao`, por cidade |
| `idx_historico_lancamento` | historico_lancamento | id_lancamento, data_alteracao | Histórico de um lançamento (RN11); `id_lancamento` não é FK, então não tinha índice |
| `idx_historico_data` | historico_lancamento | data_alteracao, origem | Relatórios de auditoria por período e origem (`auditoria.sql`) |
| `idx_cenario_usuario_nome` | cenario_concorrencia | id_usuario, nome | Cenários salvos do usuário, consultados por nome (RF08) |
| `idx_relatorio_usuario_data` | relatorio | id_usuario, data_geracao | Relatórios do usuário, do mais recente ao mais antigo |

`idx_lancamento_mes_categoria` começa por `(mes_referencia, id_categoria)` e termina com as colunas que a consulta filtra e soma. Assim ele **cobre** a consulta: o MySQL lê só o índice, sem voltar à tabela. Sem essas colunas, a agregação de um período longo (12 meses) caía em *full table scan* (`type = ALL` no `EXPLAIN`), porque buscar cada linha pelo índice saía mais caro que ler a tabela inteira.

O `teste_desempenho.sql` gera 10.000 lançamentos dentro de uma transação, roda as consultas de faturamento por categoria (RF05) e de tendência (RF06), mostra o `EXPLAIN` das agregações por período e desfaz tudo com `ROLLBACK`. Em um MySQL 8.0 local, com 10.000 vendas:

| Agregação por período | Sem os índices | Com os índices |
|---|---|---|
| 12 meses, por categoria | `ALL` (full table scan), 27 ms | `range` em `idx_lancamento_mes_categoria`, 24 ms |
| 2 meses, por categoria | `ALL` (full table scan), 9 ms | `range` em `idx_lancamento_mes_categoria`, 4 ms |

As agregações do `consultas.sql` (por UF, categoria e mês) também usam índice (`type = ref`), sem *full table scan*. Com esse volume tudo fica muito abaixo dos 3 segundos; os índices tiram o *full table scan* e mantêm a margem quando o número de vendas crescer.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| [docker-compose.yml](docker-compose.yml) | MySQL 8.0 em container que carrega o `banco_completo.sql` na primeira subida |
| [minimundo.md](docs/minimundo.md) | Minimundo: contexto, usuários, regras de negócio e requisitos |
| [banco_completo.sql](database/banco_completo.sql) | Todos os arquivos abaixo em um único script, na ordem certa; recria o banco do zero |
| [schema.sql](database/schema.sql) | Criação do banco, das 10 tabelas, da tabela de auditoria `historico_lancamento` e dos índices do RNF01 |
| [inserts.sql](database/inserts.sql) | Dados de exemplo para todas as tabelas |
| [procedures.sql](database/procedures.sql) | Procedures para inserir, atualizar, cancelar e excluir lançamentos |
| [triggers.sql](database/triggers.sql) | Triggers que gravam no histórico os UPDATE e DELETE de lançamentos, com testes |
| [auditoria.sql](database/auditoria.sql) | View e procedures de relatório do histórico de lançamentos |
| [transacoes.sql](database/transacoes.sql) | Transações de importação e de geração de relatório (`COMMIT`, `ROLLBACK`, `SAVEPOINT`) |
| [selects.sql](database/selects.sql) | Consulta de todos os registros de cada tabela |
| [consultas.sql](database/consultas.sql) | Consultas com `INNER JOIN`, `LEFT JOIN`, `GROUP BY`, `COUNT`, `AVG`, `MAX` e `MIN` |
| [teste_desempenho.sql](database/teste_desempenho.sql) | Teste do RNF01 com 10.000 vendas; não fica no `banco_completo.sql` e não altera os dados |
| [schema_sqlite.sql](database/schema_sqlite.sql) | Versão SQLite3 do `schema.sql`, com os triggers e a view |
| [gerar_sqlite.py](database/gerar_sqlite.py) | Gera o `extensao.db` a partir do `schema_sqlite.sql` e do `inserts.sql` |
| [extensao.db](database/extensao.db) | Banco SQLite pronto, com os dados de exemplo |

## Como executar

### Com Docker (recomendado para o back-end e o front-end)

Precisa só do [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e aberto. Na pasta do repositório:

```bash
docker compose up -d
```

Na primeira vez, o Docker baixa a imagem `mysql:8.0` e roda o `database/banco_completo.sql` automaticamente: cria as tabelas, procedures, triggers, índices e os dados de exemplo. Leva por volta de um minuto. Para saber se terminou:

```bash
docker compose ps
```

Quando a coluna `STATUS` mostrar `healthy`, o banco está pronto. O healthcheck só fica `healthy` depois que a carga inicial terminou e a tabela `lancamento_mensal` responde.

| Configuração | Valor |
|---|---|
| Host | `localhost` |
| Porta | `3307` |
| Banco | `confeccoes` |
| Usuário / senha | `trama` / `trama` |
| Usuário root / senha | `root` / `root` |
| URL JDBC (Spring Boot) | `jdbc:mysql://localhost:3307/confeccoes` |

A porta é `3307`, e não `3306`, para não dar conflito com um MySQL já instalado no computador. Para usar outra porta, defina `MYSQL_PORT` antes de subir (no Git Bash: `MYSQL_PORT=3306 docker compose up -d`). Essas credenciais são só para desenvolvimento.

Para conferir as tabelas e os dados pelo terminal:

```bash
docker compose exec mysql mysql -utrama -ptrama confeccoes -e "SHOW TABLES; SELECT COUNT(*) FROM lancamento_mensal;"
```

Pelo **MySQL Workbench** ou DBeaver, crie uma conexão com os dados da tabela acima.

| Comando | O que faz |
|---|---|
| `docker compose stop` | Para o banco e mantém os dados |
| `docker compose start` | Sobe de novo com os dados que já estavam lá |
| `docker compose logs -f mysql` | Mostra o log do MySQL (útil se o status não ficar `healthy`) |
| `docker compose down -v` | Apaga o container **e os dados**; o próximo `up -d` recarrega o `banco_completo.sql` do zero |

O `banco_completo.sql` só roda quando o volume de dados está vazio. Depois de mudar algum script SQL, use `docker compose down -v` e `docker compose up -d` para recarregar.

A cada push e Pull Request, o GitHub Actions ([`.github/workflows/docker.yml`](.github/workflows/docker.yml)) roda `docker compose up -d`, espera o banco ficar `healthy` e confere que as 11 tabelas existem com dados, além das 2 views, das 7 procedures e dos 2 triggers. O resultado aparece na aba **Actions** do repositório e como ✅ ou ❌ no commit e no Pull Request. Assim, uma mudança nos scripts que quebre a carga inicial é descoberta antes de chegar à `develop`.

### Com MySQL instalado

O jeito mais simples é rodar o script completo, que apaga e recria o banco `confeccoes` com tudo:

```bash
mysql -u root -p < database/banco_completo.sql
```

Se preferir rodar por partes, use os arquivos nesta ordem, porque cada um depende do anterior:

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/inserts.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/triggers.sql
mysql -u root -p < database/auditoria.sql
mysql -u root -p < database/transacoes.sql
mysql -u root -p < database/selects.sql
mysql -u root -p < database/consultas.sql
```

Para conferir o desempenho (RNF01), rode depois de criar o banco:

```bash
mysql -u root -p < database/teste_desempenho.sql
```

Para recomeçar do zero, apague o banco antes com `DROP DATABASE confeccoes;`.

Pelo **MySQL Workbench**: abra cada arquivo em *File → Open SQL Script* e execute (⚡), na mesma ordem.
## Banco local em SQLite (`extensao.db`)

Para quem precisa de um banco local sem instalar MySQL nem Docker, o repositório traz uma versão SQLite3 do mesmo modelo: as 11 tabelas, todas as chaves primárias e estrangeiras, os `UNIQUE`, os `CHECK`, os dois triggers do histórico de lançamento e as views `vw_lancamentos` e `vw_historico_lancamento`, com os mesmos dados de exemplo do `inserts.sql`.

O arquivo pronto é o [`database/extensao.db`](database/extensao.db). Para gerar de novo (depois de mudar o `schema_sqlite.sql` ou o `inserts.sql`), na raiz do repositório:

```bash
python database/gerar_sqlite.py
```

O script apaga o `extensao.db` antigo, roda o `schema_sqlite.sql`, carrega o `inserts.sql` (ignorando só a linha `USE confeccoes;`, que é do MySQL) e confere as chaves estrangeiras e a integridade do arquivo. Precisa só do Python 3, que já vem com o SQLite.

Se tiver o [`sqlite3`](https://sqlite.org/download.html) de linha de comando, o mesmo resultado sai com:

```bash
sqlite3 database/extensao.db < database/schema_sqlite.sql
```

```bash
sed '/^USE /d' database/inserts.sql | sqlite3 database/extensao.db
```

### Diferenças em relação ao MySQL

| MySQL (`schema.sql`) | SQLite (`schema_sqlite.sql`) |
|---|---|
| `INT AUTO_INCREMENT PRIMARY KEY` | `INTEGER PRIMARY KEY AUTOINCREMENT` |
| `VARCHAR(n)`, `CHAR(2)` | `TEXT` (o SQLite não limita tamanho; a UF tem `CHECK (length(uf) = 2)`) |
| `DECIMAL(12,2)` | `NUMERIC` |
| `DATE`, `DATETIME` | `TEXT` em ISO 8601 (`AAAA-MM-DD` e `AAAA-MM-DD HH:MM:SS`), validado por `CHECK` |
| `DAY(mes_referencia) = 1` | `strftime('%d', mes_referencia) = '01'` |
| Procedures (`procedures.sql`, `auditoria.sql`) | Não existem no SQLite: inserir, atualizar, cancelar e excluir lançamentos e os relatórios de auditoria ficam com o back-end (a view `vw_historico_lancamento` existe) |
| `@id_usuario` no histórico | O SQLite não tem variáveis de sessão: os triggers gravam `id_usuario` vazio e o back-end preenche logo depois da alteração, na mesma transação: `UPDATE historico_lancamento SET id_usuario = ? WHERE id_historico = (SELECT MAX(id_historico) FROM historico_lancamento WHERE id_lancamento = ?)` (`last_insert_rowid()` não serve, porque não enxerga os inserts feitos pelos triggers) |

`NUMERIC` guarda os valores como número de ponto flutuante quando têm casas decimais, então somas de faturamento podem ter diferenças de centavos em casas muito distantes. Para desenvolvimento local isso não atrapalha; o MySQL continua sendo o banco oficial.

### Usando no back-end

O SQLite **só aplica as chaves estrangeiras quando a conexão liga isso**, e precisa ser em toda conexão. Sem isso, o banco aceita lançamentos de confecções que não existem.

No Spring Boot, com o driver `org.xerial:sqlite-jdbc`:

```properties
spring.datasource.url=jdbc:sqlite:../Banco-de-Dados/database/extensao.db?foreign_keys=on
spring.datasource.driver-class-name=org.sqlite.JDBC
```

Ajuste o caminho para onde o `extensao.db` estiver no seu computador. Em qualquer outro cliente, rode `PRAGMA foreign_keys = ON;` logo depois de abrir a conexão. Para olhar as tabelas e os dados, o [DB Browser for SQLite](https://sqlitebrowser.org/) abre o arquivo direto.
