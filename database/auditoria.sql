USE confeccoes;

-- Auditoria do historico de lancamentos (RN11 / RF06).
-- p_origem: 'MANUAL' para monitorar so as alteracoes de lancamentos digitados a mao,
-- 'IMPORTACAO' para os que vieram de planilha, ou NULL para todos.

-- Historico com os nomes da confeccao, categoria, cidade e usuario e a diferenca entre antes e depois.
-- LEFT JOIN porque o historico nao tem FK: a confeccao, a categoria ou o usuario podem nao existir mais.
CREATE OR REPLACE VIEW vw_historico_lancamento AS
SELECT h.id_historico,
       h.data_alteracao,
       h.acao,
       h.origem,
       h.id_lancamento,
       h.mes_referencia,
       h.id_confeccao,
       c.nome AS confeccao,
       ci.nome AS cidade,
       ci.uf,
       h.id_categoria,
       cat.nome AS categoria,
       h.quantidade_antiga,
       h.quantidade_nova,
       h.quantidade_nova - h.quantidade_antiga AS diferenca_quantidade,
       h.faturamento_antigo,
       h.faturamento_novo,
       h.faturamento_novo - h.faturamento_antigo AS diferenca_faturamento,
       h.status_antigo,
       h.status_novo,
       h.id_usuario,
       COALESCE(u.nome, 'Nao identificado') AS usuario
FROM historico_lancamento h
LEFT JOIN confeccao c   ON h.id_confeccao = c.id_confeccao
LEFT JOIN cidade ci     ON c.id_cidade = ci.id_cidade
LEFT JOIN categoria cat ON h.id_categoria = cat.id_categoria
LEFT JOIN usuario u     ON h.id_usuario = u.id_usuario;

DROP PROCEDURE IF EXISTS relatorio_historico_periodo;
DROP PROCEDURE IF EXISTS relatorio_alteracoes_por_usuario;
DROP PROCEDURE IF EXISTS relatorio_alteracoes_por_confeccao;

-- Todas as alteracoes do periodo, da mais recente para a mais antiga
DELIMITER $$
CREATE PROCEDURE relatorio_historico_periodo(
    IN p_inicio DATE,
    IN p_fim DATE,
    IN p_origem VARCHAR(10)
)
BEGIN
    SELECT data_alteracao, acao, origem, id_lancamento, mes_referencia,
           confeccao, categoria,
           quantidade_antiga, quantidade_nova,
           faturamento_antigo, faturamento_novo, diferenca_faturamento,
           status_antigo, status_novo, usuario
    FROM vw_historico_lancamento
    WHERE data_alteracao >= p_inicio
      AND data_alteracao < p_fim + INTERVAL 1 DAY
      AND (p_origem IS NULL OR origem = p_origem)
    ORDER BY data_alteracao DESC, id_historico DESC;
END $$
DELIMITER ;

-- Quantas correcoes, cancelamentos e exclusoes cada usuario fez no periodo
DELIMITER $$
CREATE PROCEDURE relatorio_alteracoes_por_usuario(
    IN p_inicio DATE,
    IN p_fim DATE,
    IN p_origem VARCHAR(10)
)
BEGIN
    SELECT usuario,
           COUNT(*) AS total_alteracoes,
           SUM(acao = 'UPDATE' AND status_novo = status_antigo) AS correcoes,
           SUM(acao = 'UPDATE' AND status_novo = 'CANCELADO' AND status_antigo = 'ATIVO') AS cancelamentos,
           SUM(acao = 'DELETE') AS exclusoes,
           -- impacto nos indicadores: exclusao e cancelamento tiram o faturamento antigo (RN04)
           SUM(CASE WHEN acao = 'DELETE' OR (status_antigo = 'ATIVO' AND status_novo = 'CANCELADO')
                    THEN -faturamento_antigo
                    ELSE diferenca_faturamento END) AS impacto_faturamento,
           MAX(data_alteracao) AS ultima_alteracao
    FROM vw_historico_lancamento
    WHERE data_alteracao >= p_inicio
      AND data_alteracao < p_fim + INTERVAL 1 DAY
      AND (p_origem IS NULL OR origem = p_origem)
    GROUP BY id_usuario, usuario
    ORDER BY total_alteracoes DESC;
END $$
DELIMITER ;

-- Quantas alteracoes cada confeccao teve no periodo e quanto o faturamento informado mudou
DELIMITER $$
CREATE PROCEDURE relatorio_alteracoes_por_confeccao(
    IN p_inicio DATE,
    IN p_fim DATE,
    IN p_origem VARCHAR(10)
)
BEGIN
    SELECT confeccao,
           cidade,
           uf,
           COUNT(*) AS total_alteracoes,
           COUNT(DISTINCT id_lancamento) AS lancamentos_alterados,
           SUM(acao = 'UPDATE' AND status_novo = status_antigo) AS correcoes,
           SUM(acao = 'UPDATE' AND status_novo = 'CANCELADO' AND status_antigo = 'ATIVO') AS cancelamentos,
           SUM(acao = 'DELETE') AS exclusoes,
           -- impacto nos indicadores: exclusao e cancelamento tiram o faturamento antigo (RN04)
           SUM(CASE WHEN acao = 'DELETE' OR (status_antigo = 'ATIVO' AND status_novo = 'CANCELADO')
                    THEN -faturamento_antigo
                    ELSE diferenca_faturamento END) AS impacto_faturamento
    FROM vw_historico_lancamento
    WHERE data_alteracao >= p_inicio
      AND data_alteracao < p_fim + INTERVAL 1 DAY
      AND (p_origem IS NULL OR origem = p_origem)
    GROUP BY id_confeccao, confeccao, cidade, uf
    ORDER BY total_alteracoes DESC;
END $$
DELIMITER ;

-- Teste: relatorios do dia de hoje, com o historico gravado pelos testes do triggers.sql
SELECT * FROM vw_historico_lancamento;
CALL relatorio_historico_periodo(CURDATE(), CURDATE(), NULL);
CALL relatorio_historico_periodo(CURDATE(), CURDATE(), 'MANUAL');
CALL relatorio_alteracoes_por_usuario(CURDATE(), CURDATE(), NULL);
CALL relatorio_alteracoes_por_confeccao(CURDATE(), CURDATE(), 'MANUAL');
