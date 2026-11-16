# Changelog

Todas as mudanças relevantes do projeto ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/) (`MAJOR.MINOR.PATCH`). Enquanto a versão for `0.x`, o banco ainda está em desenvolvimento e a estrutura das tabelas pode mudar entre versões MINOR.

Cada versão tem uma tag anotada no Git (`git tag -l -n9` lista todas).

## [Não lançado]

### Adicionado
- **DB-01 (#9):** `04_constraints_pedidos_lote.sql` com as tabelas `artesao`, `produto`, `empresa_cliente`, `pedido_corporativo` e `item_pedido_corporativo`. `CHECK (quantidade >= 5)` nos itens dos pedidos em lote, chaves estrangeiras `ON DELETE RESTRICT` entre empresas, pedidos, produtos e artesãos, validação de CNPJ (formato, unicidade e dígitos verificadores com a função `cnpj_valido`), bloqueio de itens em pedidos entregues ou cancelados, índices e a view `vw_pedido_corporativo`.
- **DB-03 (#11):** `05_seed_produtos_pe.sql` com 10 mestres artesãos de Caruaru, Olinda, Cabo de Santo Agostinho e Recife, 30 produtos com descrição, técnica, material e foto, e pedidos de demonstração.
- `teste_constraints_pedidos.sql` com 18 casos de teste das novas regras.
- Versão SQLite das novas tabelas e `extensao.db` regenerado; o workflow do Docker passa a conferir 16 tabelas, 8 rotinas, 6 triggers, os testes e a carga.

### Alterado
- **Incompatível (compatibilização com a API):** em `lancamento_mensal`, a coluna `fonte_dado` passa a se chamar `origem_dado` (VARCHAR(30)) e ganha a companheira `nome_fonte` (VARCHAR(200), padrão "Fonte não informada"), os mesmos nomes da entidade `LancamentoMensal` do Back-end. Sem isso o perfil `dev` da API (`ddl-auto: validate`) não sobe contra este banco. Procedure `inserir_lancamento`, view `vw_lancamentos`, versão SQLite e `extensao.db` acompanham a mudança.
- Migração `database/migracoes/V0_4_0__origem_dado_nome_fonte.sql` para bancos já criados na v0.3.x.

### Adicionado
- Índices para o RNF01 (resposta em até 3 segundos com 10.000 vendas): `idx_lancamento_mes_categoria` e `idx_lancamento_confeccao` em `lancamento_mensal`, mais índices em `historico_lancamento`, `cenario_concorrencia` e `relatorio`, no `schema.sql` e no `banco_completo.sql`.
- `teste_desempenho.sql`, que gera 10.000 vendas, mede as consultas do painel, mostra o `EXPLAIN` das agregações por período e desfaz os dados no final.
- `docker-compose.yml` com MySQL 8.0 que carrega o `banco_completo.sql` automaticamente na primeira subida, com healthcheck e credenciais de desenvolvimento (`trama`/`trama`).
- Instruções de uso com `docker compose up -d` no README.
- Workflow do GitHub Actions que sobe o `docker compose` e confere tabelas, dados, view, procedures e triggers a cada push e Pull Request.
- `schema_sqlite.sql`, versão SQLite3 do schema com as 11 tabelas, chaves, `CHECK`, triggers e view.
- `gerar_sqlite.py`, que gera o banco local `extensao.db` com os dados do `inserts.sql` e confere as chaves estrangeiras.
- Instruções no README para o back-end usar o banco SQLite local.
- Auditoria do histórico de lançamentos (#25): view `vw_historico_lancamento` e procedures `relatorio_historico_periodo`, `relatorio_alteracoes_por_usuario` e `relatorio_alteracoes_por_confeccao` em `auditoria.sql`, com filtro por origem (MANUAL ou IMPORTACAO).
- O histórico passa a guardar quem fez a alteração, a origem, o mês, a confecção, a categoria e os valores novos, além dos antigos.
- Seção "Backup e restauração" no README, com `mysqldump` (Docker e MySQL instalado), volta ao estado inicial e conferência de integridade.
- Pasta `backups/` para os arquivos de backup, ignorada pelo Git.

### Alterado
- **Incompatível:** a tabela `log_lancamento` passa a se chamar `historico_lancamento` (`id_log` → `id_historico`, `data_log` → `data_alteracao`), e os triggers passam a se chamar `trg_historico_lancamento_update` e `trg_historico_lancamento_delete`.
- **Incompatível:** `atualizar_lancamento`, `cancelar_lancamento` e `excluir_lancamento` recebem o id do usuário como último parâmetro.
- **Incompatível (alinhamento ao SRS):** a tabela `cidade` aceita só Toritama, Caruaru e Santa Cruz do Capibaribe, em PE (RF02); os dados de exemplo passam a usar essas cidades.
- **Incompatível (alinhamento ao SRS):** `lancamento_mensal` ganha a coluna obrigatória `fonte_dado` (ENTREVISTA, QUESTIONARIO ou FONTE_SECUNDARIA, RF04), e `inserir_lancamento` recebe a fonte do dado como último parâmetro.
- **Incompatível (alinhamento ao SRS):** `item_relatorio.uf` vira `id_cidade` (FK para `cidade`): o relatório REGIONAL compara as cidades do polo em vez de estados.
- Nome da categoria limitado a 50 caracteres (RF01).
- Tendência com limiar inclusivo de 5%: ALTA a partir de +5% e QUEDA a partir de −5% (RF06); dados de exemplo corrigidos para seguir a regra.
- **Incompatível (alinhamento ao SRS):** o perfil de usuário `CONFECCAO` passa a se chamar `EMPRESARIO` (RF09), no `schema.sql`, no `schema_sqlite.sql`, nos dados de exemplo e na documentação. O tipo de confecção (`CONFECCAO` ou `FACCAO`) não muda.
- `cenario_concorrencia.percentual_impacto` ganha o `CHECK chk_cenario_impacto`, que aceita só valores de 0 a 100 (RF07, RN06).

## [0.3.1] - 2026-10-27

### Alterado
- O projeto passa a se chamar **TRAMA** (antes RedeSulanca) no README e no minimundo.

### Adicionado
- Este `CHANGELOG.md`, com o histórico das versões.

## [0.3.0] - 2026-10-27

### Alterado
- Scripts SQL revisados e organizados em arquivos separados: estrutura, inserts, consultas, procedures e triggers.
- Ajustes nas transações e nos comandos de importação de dados.
- `banco_completo.sql` atualizado com todas as mudanças.

### Corrigido
- Quantidade de linhas informada na importação.

## [0.2.0] - 2026-10-16

### Adicionado
- Tabela de auditoria `log_lancamento` no schema.
- Dados de exemplo (`inserts.sql`) e consulta de todas as tabelas (`selects.sql`).
- Procedures para inserir, atualizar, cancelar e excluir lançamentos.
- Triggers que registram UPDATE e DELETE de lançamentos em `log_lancamento`.
- Transações de importação e de geração de relatório com `COMMIT`, `ROLLBACK` e `SAVEPOINT`.
- Consultas com `JOIN`, `GROUP BY`, `COUNT`, `AVG`, `MAX` e `MIN`.
- Minimundo (`docs/minimundo.md`) com contexto, usuários, regras de negócio e requisitos.
- Script único `banco_completo.sql`, que recria o banco do zero.

### Alterado
- Histórico de lançamento incluído nos modelos conceitual e lógico; regras do minimundo padronizadas no README.

## [0.1.0] - 2026-09-29

### Adicionado
- Schema inicial do banco (`schema.sql`) com as 10 tabelas.
- Modelos conceitual e lógico, relacionamentos, cardinalidades e chaves estrangeiras documentados no README.

[Não lançado]: https://github.com/AstralCommits/Banco-de-Dados/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/AstralCommits/Banco-de-Dados/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/AstralCommits/Banco-de-Dados/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/AstralCommits/Banco-de-Dados/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/AstralCommits/Banco-de-Dados/releases/tag/v0.1.0
