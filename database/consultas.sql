USE confeccoes;

SELECT uf,
       SUM(faturamento) AS faturamento_total,
       SUM(quantidade)  AS quantidade_total
FROM vw_lancamentos
GROUP BY uf
ORDER BY faturamento_total DESC;
 
SELECT categoria,
       SUM(faturamento) AS faturamento_total,
       SUM(quantidade)  AS quantidade_total
FROM vw_lancamentos
GROUP BY categoria
ORDER BY faturamento_total DESC;
 
SELECT mes_referencia,
       SUM(faturamento) AS faturamento_total
FROM vw_lancamentos
GROUP BY mes_referencia
ORDER BY mes_referencia;
 
SELECT confeccao,
       SUM(faturamento) AS faturamento_total,
       SUM(quantidade)  AS quantidade_total
FROM vw_lancamentos
GROUP BY id_confeccao, confeccao
HAVING SUM(faturamento) > 50000
ORDER BY faturamento_total DESC;
 
SELECT * FROM vw_lancamentos
ORDER BY uf, confeccao, mes_referencia;

SELECT c.nome AS confeccao, ci.nome AS cidade, ci.uf, u.nome AS usuario, u.email
FROM confeccao c
INNER JOIN cidade ci ON c.id_cidade = ci.id_cidade
LEFT JOIN usuario u  ON c.id_confeccao = u.id_confeccao;
 
SELECT cat.nome AS categoria, l.id_lancamento, l.faturamento
FROM categoria cat
LEFT JOIN lancamento_mensal l ON cat.id_categoria = l.id_categoria;
 
SELECT i.id_importacao, i.nome_arquivo, i.data_importacao, i.qtd_linhas,
       i.imp_status, u.nome AS usuario, c.nome AS confeccao
FROM importacao i
INNER JOIN usuario u   ON i.id_usuario = u.id_usuario
LEFT JOIN confeccao c  ON u.id_confeccao = c.id_confeccao;
 
SELECT r.id_relatorio, r.tipo, r.periodo_inicio, r.periodo_fim,
       u.nome AS usuario, cc.nome AS cenario
FROM relatorio r
INNER JOIN usuario u                ON r.id_usuario = u.id_usuario
LEFT JOIN cenario_concorrencia cc   ON r.id_cenario = cc.id_cenario;
 
SELECT e.id_entrevista, e.data, c.nome AS confeccao, ci.nome AS cidade, ci.uf,
       cat.nome AS categoria_percebida, e.achou_algo_novo, e.resumo
FROM entrevista e
INNER JOIN confeccao c   ON e.id_confeccao = c.id_confeccao
INNER JOIN cidade ci     ON c.id_cidade = ci.id_cidade
LEFT JOIN categoria cat  ON e.id_categoria_percebida = cat.id_categoria
ORDER BY e.data;
 
SELECT cc.nome AS cenario, cc.percentual_impacto,
       cat.nome AS categoria, u.nome AS usuario
FROM cenario_concorrencia cc
INNER JOIN usuario u    ON cc.id_usuario = u.id_usuario
LEFT JOIN categoria cat ON cc.id_categoria = cat.id_categoria
ORDER BY cc.percentual_impacto DESC;
 
SELECT cat.nome AS categoria, ir.uf, ir.variacao_percentual, ir.tendencia
FROM item_relatorio ir
INNER JOIN categoria cat ON ir.id_categoria = cat.id_categoria
ORDER BY ir.tendencia, ir.variacao_percentual DESC;