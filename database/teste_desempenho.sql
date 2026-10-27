USE confeccoes;

-- Teste do RNF01: as consultas do painel devem responder em ate 3 segundos com 10.000 vendas.
-- Gera 10.000 lancamentos (100 confeccoes x 5 categorias x 20 meses) dentro de uma transacao
-- e desfaz tudo no final, entao o banco de exemplo continua igual.
-- O tempo de cada consulta aparece no Workbench (Action Output -> Duration) ou no cliente mysql.

SET SESSION cte_max_recursion_depth = 10000;

START TRANSACTION;

INSERT INTO confeccao (id_confeccao, nome, cnpj, porte, tipo, id_cidade)
WITH RECURSIVE n (i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 100)
SELECT 1000 + i, CONCAT('Confeccao Teste ', i), NULL, 'MICRO', 'CONFECCAO', 1 + i % 3
FROM n;

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, fonte_dado, lanc_status, id_confeccao, id_categoria)
WITH RECURSIVE n (i) AS (SELECT 0 UNION ALL SELECT i + 1 FROM n WHERE i < 9999)
SELECT DATE_ADD('2024-07-01', INTERVAL i DIV 500 MONTH),
       100 + (i * 37) % 900,
       (100 + (i * 37) % 900) * (40 + i % 60),
       'MANUAL',
       ELT(1 + i % 3, 'ENTREVISTA', 'QUESTIONARIO', 'FONTE_SECUNDARIA'),
       IF(i % 20 = 0, 'CANCELADO', 'ATIVO'),
       1001 + i % 100,
       1 + (i DIV 100) % 5
FROM n;

SELECT COUNT(*) AS total_lancamentos FROM lancamento_mensal;

-- RF05: faturamento por categoria, filtrado por periodo e cidade
SELECT categoria,
       SUM(faturamento) AS faturamento_total,
       SUM(quantidade)  AS quantidade_total
FROM vw_lancamentos
WHERE mes_referencia BETWEEN '2025-01-01' AND '2025-12-01'
  AND cidade = 'Caruaru'
GROUP BY categoria
ORDER BY faturamento_total DESC;

-- RF06: variacao de cada categoria entre dois meses; ALTA a partir de +5% e QUEDA a partir de -5% (inclusive)
SELECT categoria,
       anterior,
       atual,
       ROUND((atual - anterior) / anterior * 100, 2) AS variacao_percentual,
       CASE
           WHEN (atual - anterior) / anterior * 100 >=  5 THEN 'ALTA'
           WHEN (atual - anterior) / anterior * 100 <= -5 THEN 'QUEDA'
           ELSE 'ESTAVEL'
       END AS tendencia
FROM (
    SELECT categoria,
           SUM(CASE WHEN mes_referencia = '2025-12-01' THEN faturamento ELSE 0 END) AS anterior,
           SUM(CASE WHEN mes_referencia = '2026-01-01' THEN faturamento ELSE 0 END) AS atual
    FROM vw_lancamentos
    WHERE mes_referencia IN ('2025-12-01', '2026-01-01')
    GROUP BY categoria
) t;

-- Planos de execucao das agregacoes por periodo: na linha da tabela l, a coluna type nunca deve ser
-- ALL (full table scan) e a coluna key deve mostrar um indice. Com estatisticas atualizadas
-- (ANALYZE TABLE lancamento_mensal) o MySQL escolhe idx_lancamento_mes_categoria com type range;
-- logo depois de criar o banco ele pode preferir id_categoria com type ref, que tambem usa indice.
EXPLAIN
SELECT categoria, SUM(faturamento), SUM(quantidade)
FROM vw_lancamentos
WHERE mes_referencia BETWEEN '2025-01-01' AND '2025-12-01'
GROUP BY categoria;

EXPLAIN
SELECT categoria, SUM(faturamento)
FROM vw_lancamentos
WHERE mes_referencia IN ('2025-12-01', '2026-01-01')
GROUP BY categoria;

ROLLBACK;
