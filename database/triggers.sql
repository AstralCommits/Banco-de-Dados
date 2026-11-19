USE confeccoes;

DROP TRIGGER IF EXISTS trg_log_lancamento_update;
DROP TRIGGER IF EXISTS trg_log_lancamento_delete;
DROP TRIGGER IF EXISTS trg_avaliacao_pedido_entregue;
DROP TRIGGER IF EXISTS trg_audita_preco_produto;
DROP TRIGGER IF EXISTS trg_pedido_item_artesao;

DELIMITER $$
CREATE TRIGGER trg_log_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo,
     quantidade_nova, faturamento_novo, status_novo, usuario_mysql)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     NEW.quantidade, NEW.faturamento, NEW.lanc_status, CURRENT_USER());
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_log_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo,
     usuario_mysql)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     CURRENT_USER());
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_avaliacao_pedido_entregue
BEFORE INSERT ON avaliacoes_artesao
FOR EACH ROW
BEGIN
    IF (SELECT ped_status FROM pedido WHERE id_pedido = NEW.pedido_id) <> 'ENTREGUE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Somente pedidos entregues podem ser avaliados.';
    END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_audita_preco_produto
BEFORE UPDATE ON produto
FOR EACH ROW
BEGIN
    IF OLD.preco <> NEW.preco THEN
        IF NEW.preco < 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Preco nao pode ser negativo.';
        END IF;

        IF OLD.preco > 0
           AND NEW.preco > OLD.preco * 3
           AND (NEW.justificativa_preco IS NULL OR TRIM(NEW.justificativa_preco) = '') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Acrescimo acima de 200% exige justificativa.';
        END IF;

        INSERT INTO historico_preco_produto
        (produto_id, preco_anterior, preco_novo, justificativa, alterado_por, usuario_mysql)
        VALUES
        (OLD.id_produto, OLD.preco, NEW.preco, NULLIF(TRIM(NEW.justificativa_preco), ''),
         @id_usuario_logado, CURRENT_USER());
    END IF;

    SET NEW.justificativa_preco = NULL;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_pedido_item_artesao
BEFORE INSERT ON pedido_item
FOR EACH ROW
BEGIN
    IF (SELECT id_confeccao FROM produto WHERE id_produto = NEW.id_produto)
       <> (SELECT id_confeccao FROM pedido WHERE id_pedido = NEW.id_pedido) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Produto nao pertence ao artesao do pedido.';
    END IF;
END $$
DELIMITER ;
