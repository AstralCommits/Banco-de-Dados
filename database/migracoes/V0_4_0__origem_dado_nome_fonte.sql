-- Migração v0.3.1 -> v0.4.0 para bancos MySQL já criados.
-- Compatibiliza lancamento_mensal com a API (entidade LancamentoMensal, RF04):
-- a coluna fonte_dado passa a se chamar origem_dado e surge nome_fonte.
-- Execute uma única vez: mysql -u root -p confeccoes < database/migracoes/V0_4_0__origem_dado_nome_fonte.sql
-- Bancos novos (docker compose ou banco_completo.sql) já nascem com a estrutura nova.

USE confeccoes;

ALTER TABLE lancamento_mensal DROP CHECK chk_lanc_fonte;

ALTER TABLE lancamento_mensal
    RENAME COLUMN fonte_dado TO origem_dado;

ALTER TABLE lancamento_mensal
    MODIFY COLUMN origem_dado VARCHAR(30) NOT NULL,
    ADD COLUMN nome_fonte VARCHAR(200) NOT NULL DEFAULT 'Fonte não informada' AFTER origem_dado,
    ADD CONSTRAINT chk_lanc_fonte CHECK (origem_dado IN ('ENTREVISTA','QUESTIONARIO','FONTE_SECUNDARIA'));

-- Recriar a procedure e a view que citavam fonte_dado:
-- rode novamente database/procedures.sql e o trecho de views de database/schema.sql.
