USE confeccoes;

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_modarecife.csv', 2, 'CONCLUIDA', 2);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 530, 37100.00, 'IMPORTACAO', 'ATIVO', 1, 1, @id_importacao),
('2026-03-01', 300, 21000.00, 'IMPORTACAO', 'ATIVO', 1, 2, @id_importacao);

COMMIT;

SELECT * FROM lancamento_mensal WHERE id_importacao = @id_importacao;

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', 2, 'CONCLUIDA', 3);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 270, 16200.00, 'IMPORTACAO', 'ATIVO', 2, 1, @id_importacao);

ROLLBACK;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', 2, 'ERRO', 3);

SELECT * FROM importacao;
SELECT * FROM lancamento_mensal WHERE id_confeccao = 2 AND mes_referencia = '2026-03-01';

START TRANSACTION;

INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
VALUES ('REGIONAL', '2026-01-01', '2026-03-31', 5.00, 1);
SET @id_relatorio = LAST_INSERT_ID();

SAVEPOINT relatorio_criado;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('PE', 2880, 193500.00, @id_relatorio);

SAVEPOINT item_pe;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('PB', 650, 45500.00, @id_relatorio);

SAVEPOINT item_pb;
INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('AL', 810, 5670.00, @id_relatorio);

ROLLBACK TO SAVEPOINT item_pb;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('AL', 810, 56700.00, @id_relatorio);

COMMIT;

SELECT * FROM item_relatorio WHERE id_relatorio = @id_relatorio;
START TRANSACTION;
INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
VALUES ('TENDENCIA', '2025-01-01', '2025-03-31', 5.00, 2);

ROLLBACK;
SELECT * FROM relatorio;
