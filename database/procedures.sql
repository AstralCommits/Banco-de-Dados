
USE confeccoes;
 
DROP PROCEDURE IF EXISTS inserir_lancamento;
DROP PROCEDURE IF EXISTS atualizar_lancamento;
DROP PROCEDURE IF EXISTS cancelar_lancamento;
DROP PROCEDURE IF EXISTS excluir_lancamento;
 
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
    IN p_faturamento DECIMAL(12,2),
    IN p_id_usuario INT
)
BEGIN
    IF (SELECT lanc_status FROM lancamento_mensal
        WHERE id_lancamento = p_id_lancamento) = 'CANCELADO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento cancelado nao pode ser atualizado.';
    END IF;
 
    -- O trigger le @id_usuario para registrar quem alterou
    SET @id_usuario = p_id_usuario;
    UPDATE lancamento_mensal
    SET quantidade = p_quantidade,
        faturamento = p_faturamento
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;
 
DELIMITER $$
CREATE PROCEDURE cancelar_lancamento(
    IN p_id_lancamento INT,
    IN p_id_usuario INT
)
BEGIN
    SET @id_usuario = p_id_usuario;
    UPDATE lancamento_mensal
    SET lanc_status = 'CANCELADO'
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;
 
DELIMITER $$
CREATE PROCEDURE excluir_lancamento(
    IN p_id_lancamento INT,
    IN p_id_usuario INT
)
BEGIN
    SET @id_usuario = p_id_usuario;
    DELETE FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;