USE confeccoes;
 
DROP TRIGGER IF EXISTS trg_log_lancamento_update;
DROP TRIGGER IF EXISTS trg_log_lancamento_delete;
 
DELIMITER $$
CREATE TRIGGER trg_log_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.quantidade, OLD.faturamento, OLD.lanc_status);
END $$
DELIMITER ;
 
DELIMITER $$
CREATE TRIGGER trg_log_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.quantidade, OLD.faturamento, OLD.lanc_status);
END $$
DELIMITER ;
 
-- Teste: chama as procedures e confere o log gerado pelos triggers
CALL inserir_lancamento('2026-03-15', 360, 25200.00, 4, 4);
SET @id_novo = LAST_INSERT_ID();
SELECT * FROM lancamento_mensal WHERE id_lancamento = @id_novo;
CALL atualizar_lancamento(10, 350, 24500.00);
CALL cancelar_lancamento(8);
CALL excluir_lancamento(@id_novo);
SELECT * FROM log_lancamento;