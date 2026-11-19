USE confeccoes;

DROP PROCEDURE IF EXISTS inserir_lancamento;
DROP PROCEDURE IF EXISTS atualizar_lancamento;
DROP PROCEDURE IF EXISTS cancelar_lancamento;
DROP PROCEDURE IF EXISTS excluir_lancamento;
DROP PROCEDURE IF EXISTS gerar_relatorio_regional;
DROP PROCEDURE IF EXISTS sp_fechamento_mensal_artesao;

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

DELIMITER $$
CREATE PROCEDURE sp_fechamento_mensal_artesao(
    IN p_ano INT,
    IN p_mes INT
)
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_fim DATE;
    DECLARE v_taxa DECIMAL(5,2) DEFAULT 10.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_ano IS NULL OR p_mes IS NULL OR p_mes NOT BETWEEN 1 AND 12 OR p_ano < 2000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ano ou mes invalido.';
    END IF;

    SET v_inicio = STR_TO_DATE(CONCAT(p_ano, '-', p_mes, '-01'), '%Y-%m-%d');
    SET v_fim    = DATE_ADD(v_inicio, INTERVAL 1 MONTH);

    IF EXISTS (SELECT 1 FROM fechamento_comissao WHERE ano = p_ano AND mes = p_mes) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mes ja fechado: fechamento nao pode ser repetido.';
    END IF;

    START TRANSACTION;

    INSERT INTO fechamento_comissao
    (ano, mes, id_confeccao, qtd_pedidos, valor_bruto, taxa_percentual,
     valor_taxa, valor_liquido, fech_status)
    SELECT p_ano, p_mes, t.id_confeccao, t.qtd_pedidos, t.bruto, v_taxa,
           ROUND(t.bruto * v_taxa / 100, 2),
           t.bruto - ROUND(t.bruto * v_taxa / 100, 2),
           'A_PAGAR'
    FROM (
        SELECT pe.id_confeccao,
               COUNT(DISTINCT pe.id_pedido) AS qtd_pedidos,
               SUM(pit.quantidade * pit.preco_unitario) AS bruto
        FROM pedido pe
        INNER JOIN pedido_item pit ON pit.id_pedido = pe.id_pedido
        WHERE pe.ped_status = 'ENTREGUE'
          AND pe.data_entrega >= v_inicio
          AND pe.data_entrega <  v_fim
        GROUP BY pe.id_confeccao
    ) t;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sem pedidos entregues no mes: fechamento nao gerado.';
    END IF;

    COMMIT;

    SELECT c.nome AS artesao, f.qtd_pedidos, f.valor_bruto,
           f.valor_taxa, f.valor_liquido, f.fech_status
    FROM fechamento_comissao f
    INNER JOIN confeccao c ON c.id_confeccao = f.id_confeccao
    WHERE f.ano = p_ano AND f.mes = p_mes
    ORDER BY f.valor_liquido DESC;
END $$
DELIMITER ;
