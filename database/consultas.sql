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

SELECT * FROM vw_reputacao_artesao
ORDER BY nota_media DESC;

SELECT * FROM vw_vendas_polo_regional
ORDER BY faturamento_total DESC;


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

SELECT p.id_pedido, p.ped_status, comprador.nome AS comprador,
       c.nome AS artesao, a.nota, a.comentario
FROM pedido p
INNER JOIN usuario comprador ON p.id_usuario = comprador.id_usuario
INNER JOIN confeccao c       ON p.id_confeccao = c.id_confeccao
LEFT JOIN avaliacoes_artesao a ON a.pedido_id = p.id_pedido
ORDER BY p.id_pedido;

SELECT u.nome AS usuario, COUNT(r.id_relatorio) AS relatorios_gerados
FROM usuario u
LEFT JOIN relatorio r ON r.id_usuario = u.id_usuario
GROUP BY u.id_usuario, u.nome
ORDER BY relatorios_gerados DESC;

SELECT l.id_log, l.id_lancamento, l.acao,
       l.quantidade_antiga, l.quantidade_nova,
       l.faturamento_antigo, l.faturamento_novo,
       l.status_antigo, l.status_novo, l.usuario_mysql, l.data_log
FROM log_lancamento l
LEFT JOIN lancamento_mensal lm ON lm.id_lancamento = l.id_lancamento
ORDER BY l.data_log, l.id_log;

SELECT h.id, p.nome AS produto, c.nome AS artesao,
       h.preco_anterior, h.preco_novo,
       ROUND((h.preco_novo - h.preco_anterior) / h.preco_anterior * 100, 2) AS variacao_percentual,
       h.justificativa, u.nome AS alterado_por, h.data_alteracao
FROM historico_preco_produto h
INNER JOIN produto p   ON p.id_produto = h.produto_id
INNER JOIN confeccao c ON c.id_confeccao = p.id_confeccao
LEFT JOIN usuario u    ON u.id_usuario = h.alterado_por
ORDER BY h.data_alteracao, h.id;

SELECT f.ano, f.mes, c.nome AS artesao, ci.nome AS cidade, ci.uf,
       f.qtd_pedidos, f.valor_bruto, f.taxa_percentual,
       f.valor_taxa, f.valor_liquido, f.fech_status, f.data_fechamento
FROM fechamento_comissao f
INNER JOIN confeccao c ON c.id_confeccao = f.id_confeccao
INNER JOIN cidade ci   ON ci.id_cidade = c.id_cidade
ORDER BY f.ano, f.mes, f.valor_liquido DESC;

SELECT ano, mes,
       SUM(qtd_pedidos)   AS pedidos,
       SUM(valor_bruto)   AS bruto_total,
       SUM(valor_taxa)    AS taxa_plataforma,
       SUM(valor_liquido) AS liquido_a_repassar
FROM fechamento_comissao
GROUP BY ano, mes
ORDER BY ano, mes;

SELECT pe.id_confeccao,
       SUM(pit.quantidade * pit.preco_unitario) AS bruto_pedidos
FROM pedido pe
INNER JOIN pedido_item pit ON pit.id_pedido = pe.id_pedido
WHERE pe.ped_status = 'ENTREGUE'
  AND pe.data_entrega >= '2026-02-01' AND pe.data_entrega < '2026-03-01'
GROUP BY pe.id_confeccao;

SELECT municipio, uf, faturamento_total, volume_itens, qtd_pedidos, ticket_medio_item
FROM vw_vendas_polo_regional
WHERE polo_destaque = 1
ORDER BY faturamento_total DESC;

SELECT SUM(faturamento_total) AS faturamento_polos,
       SUM(volume_itens)      AS itens_polos,
       SUM(qtd_pedidos)       AS pedidos_polos
FROM vw_vendas_polo_regional
WHERE polo_destaque = 1;

SELECT ci.nome AS municipio, COUNT(*) AS pedidos_no_periodo
FROM pedido p
INNER JOIN confeccao c ON c.id_confeccao = p.id_confeccao
INNER JOIN cidade ci   ON ci.id_cidade = c.id_cidade
WHERE p.data_pedido >= '2026-02-01' AND p.data_pedido < '2026-03-01'
  AND p.ped_status <> 'CANCELADO'
GROUP BY ci.id_cidade, ci.nome
ORDER BY pedidos_no_periodo DESC;

SHOW INDEX FROM pedido;
SHOW INDEX FROM confeccao;
SHOW INDEX FROM lancamento_mensal;
SHOW INDEX FROM pedido_item;
SHOW INDEX FROM fechamento_comissao;

EXPLAIN SELECT * FROM vw_vendas_polo_regional;

EXPLAIN ANALYZE SELECT * FROM vw_vendas_polo_regional;

EXPLAIN SELECT COUNT(*) FROM pedido
WHERE data_pedido >= '2026-02-01' AND data_pedido < '2026-03-01';

EXPLAIN ANALYZE
SELECT ci.nome AS municipio, COUNT(*) AS pedidos_no_periodo
FROM pedido p
INNER JOIN confeccao c ON c.id_confeccao = p.id_confeccao
INNER JOIN cidade ci   ON ci.id_cidade = c.id_cidade
WHERE p.data_pedido >= '2026-02-01' AND p.data_pedido < '2026-03-01'
  AND p.ped_status <> 'CANCELADO'
GROUP BY ci.id_cidade, ci.nome;
