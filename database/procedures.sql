USE confeccoes;

DROP PROCEDURE IF EXISTS inserir_lancamento;
DROP PROCEDURE IF EXISTS atualizar_lancamento;
DROP PROCEDURE IF EXISTS cancelar_lancamento;
DROP PROCEDURE IF EXISTS excluir_lancamento;
DROP PROCEDURE IF EXISTS gerar_relatorio_regional;

DELIMITER $$
CREATE PROCEDURE inserir_lancamento(
    IN p_mes_referencia DATE,
    IN p_quantidade INT,
    IN p_faturamento DECIMAL(12,2),
    IN p_id_confeccao INT,
    IN p_id_categoria INT
)
BEGIN
    INSERT INTO lancamento_mensal
    (mes_referencia, quantidade, faturamento, origem, lanc_status,
     id_confeccao, id_categoria, id_importacao)
    VALUES
    (DATE_FORMAT(p_mes_referencia, '%Y-%m-01'), p_quantidade, p_faturamento,
     'MANUAL', 'ATIVO', p_id_confeccao, p_id_categoria, NULL);
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE atualizar_lancamento(
    IN p_id_lancamento INT,
    IN p_quantidade INT,
    IN p_faturamento DECIMAL(12,2)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    SELECT lanc_status INTO v_status
    FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento nao encontrado.';
    ELSEIF v_status = 'CANCELADO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento cancelado nao pode ser atualizado.';
    END IF;

    UPDATE lancamento_mensal
    SET quantidade = p_quantidade,
        faturamento = p_faturamento
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE cancelar_lancamento(
    IN p_id_lancamento INT
)
BEGIN
    UPDATE lancamento_mensal
    SET lanc_status = 'CANCELADO'
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE excluir_lancamento(
    IN p_id_lancamento INT
)
BEGIN
    DELETE FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE gerar_relatorio_regional(
    IN p_id_usuario INT,
    IN p_periodo_inicio DATE,
    IN p_periodo_fim DATE,
    IN p_limiar DECIMAL(5,2)
)
BEGIN
    DECLARE v_id_relatorio INT;
    DECLARE v_meses INT;
    DECLARE v_ant_inicio DATE;
    DECLARE v_ant_fim DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_meses = TIMESTAMPDIFF(MONTH, p_periodo_inicio, p_periodo_fim) + 1;
    SET v_ant_inicio = DATE_SUB(p_periodo_inicio, INTERVAL v_meses MONTH);
    SET v_ant_fim = DATE_SUB(p_periodo_inicio, INTERVAL 1 DAY);

    START TRANSACTION;

    INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
    VALUES ('REGIONAL', p_periodo_inicio, p_periodo_fim, p_limiar, p_id_usuario);
    SET v_id_relatorio = LAST_INSERT_ID();

    INSERT INTO item_relatorio
    (uf, quantidade, faturamento, variacao_percentual, tendencia, id_relatorio)
    SELECT a.uf, a.quantidade, a.faturamento, a.variacao,
           CASE WHEN a.variacao IS NULL THEN NULL
                WHEN a.variacao > p_limiar THEN 'ALTA'
                WHEN a.variacao < -p_limiar THEN 'QUEDA'
                ELSE 'ESTAVEL'
           END,
           v_id_relatorio
    FROM (
        SELECT atual.uf, atual.quantidade, atual.faturamento,
               CASE WHEN ant.faturamento IS NULL OR ant.faturamento = 0 THEN NULL
                    ELSE ROUND((atual.faturamento - ant.faturamento) / ant.faturamento * 100, 2)
               END AS variacao
        FROM (SELECT uf, SUM(quantidade) AS quantidade, SUM(faturamento) AS faturamento
              FROM vw_lancamentos
              WHERE mes_referencia BETWEEN p_periodo_inicio AND p_periodo_fim
              GROUP BY uf) atual
        LEFT JOIN (SELECT uf, SUM(faturamento) AS faturamento
                   FROM vw_lancamentos
                   WHERE mes_referencia BETWEEN v_ant_inicio AND v_ant_fim
                   GROUP BY uf) ant ON ant.uf = atual.uf
    ) a;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Periodo sem lancamentos ativos: relatorio nao gerado.';
    END IF;

    COMMIT;
    SELECT v_id_relatorio AS id_relatorio;
END $$
DELIMITER ;
