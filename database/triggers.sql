USE confeccoes;
 
DROP TRIGGER IF EXISTS trg_historico_lancamento_update;
DROP TRIGGER IF EXISTS trg_historico_lancamento_delete;
 
DELIMITER $$
CREATE TRIGGER trg_historico_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO historico_lancamento
    (id_lancamento, acao, origem, mes_referencia, id_confeccao, id_categoria,
     quantidade_antiga, faturamento_antigo, status_antigo,
     quantidade_nova, faturamento_novo, status_novo, id_usuario)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.origem, OLD.mes_referencia, OLD.id_confeccao, OLD.id_categoria,
     OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     NEW.quantidade, NEW.faturamento, NEW.lanc_status, @id_usuario);
END $$
DELIMITER ;
 
DELIMITER $$
CREATE TRIGGER trg_historico_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO historico_lancamento
    (id_lancamento, acao, origem, mes_referencia, id_confeccao, id_categoria,
     quantidade_antiga, faturamento_antigo, status_antigo, id_usuario)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.origem, OLD.mes_referencia, OLD.id_confeccao, OLD.id_categoria,
     OLD.quantidade, OLD.faturamento, OLD.lanc_status, @id_usuario);
END $$
DELIMITER ;
 
-- Teste: chama as procedures e confere o log gerado pelos triggers
CALL inserir_lancamento('2026-03-15', 360, 25200.00, 4, 4);
SET @id_novo = LAST_INSERT_ID();
SELECT * FROM lancamento_mensal WHERE id_lancamento = @id_novo;
CALL atualizar_lancamento(10, 350, 24500.00, 5);
CALL cancelar_lancamento(8, 4);
CALL excluir_lancamento(@id_novo, 1);
SELECT * FROM historico_lancamento;