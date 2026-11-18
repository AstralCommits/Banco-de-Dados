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
VALUES ('vendas_marco_estiloagreste.csv', 1, 'CONCLUIDA', 3);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 270, 16200.00, 'IMPORTACAO', 'ATIVO', 2, 1, @id_importacao);

ROLLBACK;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', NULL, 'ERRO', 3);

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

DROP PROCEDURE IF EXISTS teste_trigger_audita_preco;

DELIMITER $$
CREATE PROCEDURE teste_trigger_audita_preco()
BEGIN
    DECLARE v_id INT;
    DECLARE v_erro VARCHAR(255);
    DECLARE v_qtd INT;
    DECLARE v_anterior DECIMAL(10,2);
    DECLARE v_novo DECIMAL(10,2);
    DECLARE v_data DATETIME;
    DECLARE v_autor INT;
    DECLARE v_preco DECIMAL(10,2);
    DECLARE v_just VARCHAR(255);

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_erro = MESSAGE_TEXT;
    END;

    DROP TEMPORARY TABLE IF EXISTS resultado_teste;
    CREATE TEMPORARY TABLE resultado_teste (
        teste INT,
        descricao VARCHAR(120),
        resultado VARCHAR(4)
    ) ENGINE = MEMORY;

    START TRANSACTION;

    INSERT INTO produto (nome, preco, id_confeccao)
    VALUES ('Produto de teste', 80.00, 3);
    SET v_id = LAST_INSERT_ID();
    SET @id_usuario_logado = 4;

    UPDATE produto SET preco = 95.00 WHERE id_produto = v_id;
    SELECT COUNT(*), MAX(preco_anterior), MAX(preco_novo), MAX(data_alteracao), MAX(alterado_por)
      INTO v_qtd, v_anterior, v_novo, v_data, v_autor
    FROM historico_preco_produto WHERE produto_id = v_id;
    INSERT INTO resultado_teste VALUES
    (1, 'R$ 80,00 para R$ 95,00 grava 1 linha com valores, autor e data',
     IF(v_qtd = 1 AND v_anterior = 80.00 AND v_novo = 95.00
        AND v_data IS NOT NULL AND v_autor = 4, 'OK', 'FALHA'));

    UPDATE produto SET nome = 'Produto de teste renomeado', preco = 95.00
    WHERE id_produto = v_id;
    SELECT COUNT(*) INTO v_qtd FROM historico_preco_produto WHERE produto_id = v_id;
    INSERT INTO resultado_teste VALUES
    (2, 'Atualizar sem mudar o preco nao grava historico',
     IF(v_qtd = 1, 'OK', 'FALHA'));

    SET v_erro = NULL;
    UPDATE produto SET preco = -10.00 WHERE id_produto = v_id;
    SELECT preco INTO v_preco FROM produto WHERE id_produto = v_id;
    SELECT COUNT(*) INTO v_qtd FROM historico_preco_produto WHERE produto_id = v_id;
    INSERT INTO resultado_teste VALUES
    (3, 'Preco negativo e bloqueado, preco e historico ficam intactos',
     IF(v_erro = 'Preco nao pode ser negativo.' AND v_preco = 95.00 AND v_qtd = 1,
        'OK', 'FALHA'));

    SET v_erro = NULL;
    UPDATE produto SET preco = 285.01 WHERE id_produto = v_id;
    SELECT preco INTO v_preco FROM produto WHERE id_produto = v_id;
    SELECT COUNT(*) INTO v_qtd FROM historico_preco_produto WHERE produto_id = v_id;
    SET @bloqueou_sem_justificativa =
        (v_erro = 'Acrescimo acima de 200% exige justificativa.' AND v_preco = 95.00 AND v_qtd = 1);

    SET v_erro = NULL;
    UPDATE produto SET preco = 285.00 WHERE id_produto = v_id;
    SELECT COUNT(*) INTO v_qtd FROM historico_preco_produto WHERE produto_id = v_id;
    SET @limite_exato_liberado = (v_erro IS NULL AND v_qtd = 2);

    UPDATE produto SET preco = 1000.00, justificativa_preco = 'Edicao limitada de colecao'
    WHERE id_produto = v_id;
    SELECT COUNT(*), MAX(justificativa) INTO v_qtd, v_just
    FROM historico_preco_produto WHERE produto_id = v_id;
    INSERT INTO resultado_teste VALUES
    (4, 'Acrescimo acima de 200%: bloqueia sem justificativa, aceita no limite e com justificativa',
     IF(@bloqueou_sem_justificativa AND @limite_exato_liberado
        AND v_qtd = 3 AND v_just = 'Edicao limitada de colecao', 'OK', 'FALHA'));

    ROLLBACK;
    SET @id_usuario_logado = NULL;

    SELECT teste, descricao, resultado FROM resultado_teste ORDER BY teste;
    DROP TEMPORARY TABLE resultado_teste;
END $$
DELIMITER ;

CALL teste_trigger_audita_preco();
DROP PROCEDURE teste_trigger_audita_preco;
