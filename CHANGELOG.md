# Changelog

Todas as mudanças relevantes do projeto ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/) (`MAJOR.MINOR.PATCH`). Enquanto a versão for `0.x`, o banco ainda está em desenvolvimento e a estrutura das tabelas pode mudar entre versões MINOR.

Cada versão tem uma tag anotada no Git (`git tag -l -n9` lista todas).

## [Não lançado]

### Adicionado
- Massa de dados fictícia do polo têxtil para o ProjetAÍ (`seed_demonstracao_projetaí.sql`), view `vw_serie_polo_regional` com a série mensal por município e `teste_demonstracao_projetai.sql` com 12 casos (DEMO-DB-01).
- Backup lógico agendado (`scripts/backup_database.sh`): dump compactado `.sql.gz` com timestamp, validação do arquivo gerado e expurgo de backups com mais de 7 dias (DB-07).
- Teste de restauração (`scripts/restore_test.sh`): restaura o backup em um banco temporário e valida tabelas, views, rotinas e triggers (DB-07).
- Modelo de configuração `scripts/backup.env.example`, pasta `backups/` e arquivos `.gitignore` e `.gitattributes` (DB-07).
- Procedimento de backup, teste de restore e recuperação no README (DB-07).

### Corrigido
- As senhas dos usuários de exemplo passam a ser BCrypt, o formato que a API confere; antes, o login respondia 401. Bancos já criados usam `database/migracoes/V0_4_1__senhas_bcrypt.sql`.

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
