USE confeccoes;

DROP TEMPORARY TABLE IF EXISTS resultado_demo;
CREATE TEMPORARY TABLE resultado_demo (
    caso VARCHAR(100) NOT NULL,
    esperado VARCHAR(60) NOT NULL,
    obtido VARCHAR(60) NULL
);

INSERT INTO resultado_demo
SELECT 'Confeccoes de demonstracao', '12', COUNT(*)
FROM confeccao WHERE id_confeccao BETWEEN 9001 AND 9012;

INSERT INTO resultado_demo
SELECT 'Lancamentos (17 series x 24 meses)', '408', COUNT(*)
FROM lancamento_mensal WHERE id_confeccao BETWEEN 9001 AND 9012;

INSERT INTO resultado_demo
SELECT 'Polos com 24 meses seguidos', '3', COUNT(*)
FROM (
    SELECT c.id_cidade
    FROM lancamento_mensal l
    INNER JOIN confeccao c ON c.id_confeccao = l.id_confeccao
    WHERE c.id_confeccao BETWEEN 9001 AND 9012
    GROUP BY c.id_cidade
    HAVING COUNT(DISTINCT l.mes_referencia) = 24
       AND TIMESTAMPDIFF(MONTH, MIN(l.mes_referencia), MAX(l.mes_referencia)) = 23
) p;

INSERT INTO resultado_demo
SELECT 'Serie mensal bate com vw_vendas_polo_regional', '0', COUNT(*)
FROM vw_vendas_polo_regional v
LEFT JOIN (
    SELECT municipio, SUM(faturamento) AS faturamento, SUM(volume_itens) AS itens
    FROM vw_serie_polo_regional
    GROUP BY municipio
) s ON s.municipio = v.municipio
WHERE v.municipio IN ('Caruaru','Toritama','Santa Cruz do Capibaribe')
  AND (s.municipio IS NULL OR s.faturamento <> v.faturamento_total OR s.itens <> v.volume_itens);

INSERT INTO resultado_demo
SELECT 'Nenhum valor zerado', '0', COUNT(*)
FROM lancamento_mensal
WHERE id_confeccao BETWEEN 9001 AND 9012 AND (quantidade = 0 OR faturamento = 0);

INSERT INTO resultado_demo
SELECT 'Maior salto de um mes para o outro abaixo de 60%', 'SIM', IF(MAX(ABS(variacao_mes_percentual)) < 60, 'SIM', 'NAO')
FROM vw_serie_polo_regional
WHERE municipio IN ('Caruaru','Toritama','Santa Cruz do Capibaribe')
  AND mes_referencia BETWEEN '2024-12-01' AND '2026-10-01';

INSERT INTO resultado_demo
SELECT CONCAT('Tendencia de ', t.categoria),
       CASE t.categoria
           WHEN 'Jeans' THEN 'ALTA' WHEN 'Fitness' THEN 'ALTA'
           WHEN 'Moda Masculina' THEN 'QUEDA' WHEN 'Praia' THEN 'QUEDA'
           ELSE 'ESTAVEL'
       END,
       CASE
           WHEN t.atual / t.anterior - 1 >= 0.05 THEN 'ALTA'
           WHEN t.atual / t.anterior - 1 <= -0.05 THEN 'QUEDA'
           ELSE 'ESTAVEL'
       END
FROM (
    SELECT cat.nome AS categoria,
           SUM(IF(l.mes_referencia >= '2025-11-01', l.faturamento, 0)) AS atual,
           SUM(IF(l.mes_referencia < '2025-11-01', l.faturamento, 0)) AS anterior
    FROM lancamento_mensal l
    INNER JOIN categoria cat ON cat.id_categoria = l.id_categoria
    INNER JOIN confeccao c   ON c.id_confeccao = l.id_confeccao
    INNER JOIN cidade ci     ON ci.id_cidade = c.id_cidade
    WHERE l.lanc_status = 'ATIVO'
      AND ci.nome IN ('Caruaru','Toritama','Santa Cruz do Capibaribe')
      AND l.mes_referencia BETWEEN '2024-11-01' AND '2026-10-01'
    GROUP BY cat.nome
) t;

SELECT caso, esperado, obtido, IF(esperado <=> obtido, 'OK', 'FALHOU') AS resultado FROM resultado_demo;
SELECT COUNT(*) AS total_casos, SUM(esperado <=> obtido) AS ok, SUM(NOT (esperado <=> obtido)) AS falhou FROM resultado_demo;
