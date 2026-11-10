USE confeccoes;

DROP TEMPORARY TABLE IF EXISTS resultado_teste;
CREATE TEMPORARY TABLE resultado_teste (
    caso VARCHAR(120) NOT NULL,
    esperado VARCHAR(10) NOT NULL,
    obtido VARCHAR(10) NOT NULL,
    resultado VARCHAR(6) NOT NULL
);

DROP PROCEDURE IF EXISTS tmp_testar;

DELIMITER $$
CREATE PROCEDURE tmp_testar(IN p_caso VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(10))
BEGIN
    DECLARE v_obtido VARCHAR(10) DEFAULT 'ACEITO';
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_obtido = 'REJEITADO';

    SET @tmp_sql = p_sql;
    START TRANSACTION;
    PREPARE stmt FROM @tmp_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    ROLLBACK;

    INSERT INTO resultado_teste VALUES
        (p_caso, p_esperado, v_obtido, IF(v_obtido = p_esperado, 'OK', 'FALHOU'));
END$$
DELIMITER ;

CALL tmp_testar('Item com 4 pecas (abaixo do lote minimo)',
    'INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (4, 100.00, 2, 1)', 'REJEITADO');
CALL tmp_testar('Item com 5 pecas (lote minimo)',
    'INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (5, 100.00, 2, 1)', 'ACEITO');
CALL tmp_testar('Item com preco zero',
    'INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (10, 0, 2, 2)', 'REJEITADO');
CALL tmp_testar('Mesmo produto duas vezes no pedido',
    'INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (10, 150.00, 2, 7)', 'REJEITADO');
CALL tmp_testar('Item para pedido inexistente',
    'INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (10, 100.00, 999, 1)', 'REJEITADO');
CALL tmp_testar('Excluir empresa que tem pedidos (ON DELETE RESTRICT)',
    'DELETE FROM empresa_cliente WHERE id_empresa = 1', 'REJEITADO');
CALL tmp_testar('Excluir empresa sem pedidos',
    'DELETE FROM empresa_cliente WHERE id_empresa = 3', 'ACEITO');
CALL tmp_testar('Excluir produto que esta em pedido (ON DELETE RESTRICT)',
    'DELETE FROM produto WHERE id_produto = 22', 'REJEITADO');
CALL tmp_testar('Excluir artesao com produtos (ON DELETE RESTRICT)',
    'DELETE FROM artesao WHERE id_artesao = 1', 'REJEITADO');
CALL tmp_testar('Pedido para empresa inexistente',
    'INSERT INTO pedido_corporativo (id_empresa, id_usuario) VALUES (999, 1)', 'REJEITADO');
CALL tmp_testar('Pedido com status invalido',
    'INSERT INTO pedido_corporativo (id_empresa, ped_status) VALUES (1, ''PAGO'')', 'REJEITADO');
CALL tmp_testar('Pedido com prazo antes da data do pedido',
    'INSERT INTO pedido_corporativo (data_pedido, prazo_entrega, id_empresa) VALUES (''2026-11-10'', ''2026-11-01'', 1)', 'REJEITADO');
CALL tmp_testar('Empresa com CNPJ de digitos verificadores errados',
    'INSERT INTO empresa_cliente (razao_social, cnpj, email, municipio, uf) VALUES (''Teste Ltda'', ''11222333000182'', ''a@b.com'', ''Recife'', ''PE'')', 'REJEITADO');
CALL tmp_testar('Empresa com CNPJ com letras',
    'INSERT INTO empresa_cliente (razao_social, cnpj, email, municipio, uf) VALUES (''Teste Ltda'', ''1122233300018A'', ''a@b.com'', ''Recife'', ''PE'')', 'REJEITADO');
CALL tmp_testar('Empresa com CNPJ repetido',
    'INSERT INTO empresa_cliente (razao_social, cnpj, email, municipio, uf) VALUES (''Teste Ltda'', ''11222333000181'', ''a@b.com'', ''Recife'', ''PE'')', 'REJEITADO');
CALL tmp_testar('Empresa com CNPJ valido',
    'INSERT INTO empresa_cliente (razao_social, cnpj, email, municipio, uf) VALUES (''Teste Ltda'', ''11444777000161'', ''a@b.com'', ''Recife'', ''PE'')', 'ACEITO');
CALL tmp_testar('Produto com preco negativo',
    'INSERT INTO produto (nome, descricao, tecnica, material, municipio_origem, preco_unitario, foto_url, id_artesao) VALUES (''X'', ''X'', ''X'', ''X'', ''Recife'', -1, ''/x.jpg'', 10)', 'REJEITADO');

DROP PROCEDURE IF EXISTS tmp_testar;

UPDATE pedido_corporativo SET ped_status = 'ENTREGUE' WHERE id_pedido = 1;
SET @bloqueou = 'NAO';
DROP PROCEDURE IF EXISTS tmp_testar_entregue;
DELIMITER $$
CREATE PROCEDURE tmp_testar_entregue()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET @bloqueou = 'SIM';
    INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES (10, 100.00, 1, 1);
END$$
DELIMITER ;
CALL tmp_testar_entregue();
DROP PROCEDURE IF EXISTS tmp_testar_entregue;
DELETE FROM item_pedido_corporativo WHERE id_pedido = 1 AND id_produto = 1;
UPDATE pedido_corporativo SET ped_status = 'CONFIRMADO' WHERE id_pedido = 1;

INSERT INTO resultado_teste VALUES
    ('Novo item em pedido ENTREGUE (trigger)', 'REJEITADO', IF(@bloqueou = 'SIM', 'REJEITADO', 'ACEITO'),
     IF(@bloqueou = 'SIM', 'OK', 'FALHOU'));

SELECT * FROM resultado_teste;
SELECT COUNT(*) AS total_casos, SUM(resultado = 'OK') AS ok, SUM(resultado = 'FALHOU') AS falhou FROM resultado_teste;
