USE confeccoes;
 
SELECT * FROM cidade;
SELECT * FROM confeccao;
SELECT * FROM usuario;
SELECT * FROM categoria;
SELECT * FROM importacao;
SELECT * FROM lancamento_mensal;
SELECT * FROM cenario_concorrencia;
SELECT * FROM relatorio;
SELECT * FROM item_relatorio;
SELECT * FROM entrevista;

SELECT
    (SELECT COUNT(*) FROM cidade)            AS total_cidades,
    (SELECT COUNT(*) FROM confeccao)         AS total_confeccoes,
    (SELECT COUNT(*) FROM usuario)           AS total_usuarios,
    (SELECT COUNT(*) FROM categoria)         AS total_categorias,
    (SELECT COUNT(*) FROM lancamento_mensal) AS total_lancamentos,
    (SELECT COUNT(*) FROM entrevista)        AS total_entrevistas;
 
SELECT
    SUM(faturamento) AS faturamento_total,
    SUM(CASE WHEN lanc_status = 'ATIVO' THEN faturamento END) AS faturamento_ativo,
    AVG(faturamento) AS faturamento_medio,
    MAX(faturamento) AS maior_faturamento,
    MIN(faturamento) AS menor_faturamento,
    SUM(quantidade)  AS quantidade_total,
    AVG(quantidade)  AS quantidade_media,
    MAX(quantidade)  AS maior_quantidade,
    MIN(quantidade)  AS menor_quantidade
FROM lancamento_mensal;
 
SELECT 'confeccao.porte' AS campo, porte AS valor, COUNT(*) AS qtd FROM confeccao GROUP BY porte
UNION ALL
SELECT 'confeccao.tipo', tipo, COUNT(*) FROM confeccao GROUP BY tipo
UNION ALL
SELECT 'importacao.status', imp_status, COUNT(*) FROM importacao GROUP BY imp_status
UNION ALL
SELECT 'lancamento.origem', origem, COUNT(*) FROM lancamento_mensal GROUP BY origem
UNION ALL
SELECT 'lancamento.status', lanc_status, COUNT(*) FROM lancamento_mensal GROUP BY lanc_status;

SELECT 'usuario sem confeccao' AS caso, COUNT(*) AS qtd FROM usuario WHERE id_confeccao IS NULL
UNION ALL
SELECT 'cenario sem categoria', COUNT(*) FROM cenario_concorrencia WHERE id_categoria IS NULL
UNION ALL
SELECT 'relatorio sem cenario', COUNT(*) FROM relatorio WHERE id_cenario IS NULL
UNION ALL
SELECT 'entrevista sem categoria', COUNT(*) FROM entrevista WHERE id_categoria_percebida IS NULL
UNION ALL
SELECT 'lancamento sem importacao', COUNT(*) FROM lancamento_mensal WHERE id_importacao IS NULL;
 
SELECT * FROM cenario_concorrencia
WHERE percentual_impacto > 10
ORDER BY percentual_impacto DESC;
 
SELECT * FROM confeccao WHERE nome LIKE 'Moda%';
 
SELECT * FROM confeccao
WHERE id_cidade IN (SELECT id_cidade FROM cidade WHERE uf = 'PE');
 
SELECT * FROM lancamento_mensal
WHERE mes_referencia BETWEEN '2026-01-01' AND '2026-02-01';
 
SELECT DISTINCT uf FROM cidade ORDER BY uf;