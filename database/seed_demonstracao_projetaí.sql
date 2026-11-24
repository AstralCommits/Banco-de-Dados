SET NAMES utf8mb4;

USE confeccoes;

DROP PROCEDURE IF EXISTS carregar_demonstracao_projetai;

DELIMITER $$
CREATE PROCEDURE carregar_demonstracao_projetai()
BEGIN
    DECLARE v_colunas VARCHAR(200) DEFAULT '';
    DECLARE v_valores VARCHAR(200) DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF (SELECT COUNT(*) FROM cidade
        WHERE uf = 'PE' AND nome IN ('Caruaru','Toritama','Santa Cruz do Capibaribe')) <> 3 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cadastre Caruaru, Toritama e Santa Cruz do Capibaribe antes da carga.';
    END IF;

    SELECT COALESCE(GROUP_CONCAT(', ', column_name ORDER BY column_name SEPARATOR ''), ''),
           COALESCE(GROUP_CONCAT(
               IF(column_name = 'nome_fonte',
                  ', ''Dados fictícios - demonstração ProjetAÍ''',
                  ', ELT(1 + d.id_confeccao % 3, ''ENTREVISTA'', ''QUESTIONARIO'', ''FONTE_SECUNDARIA'')')
               ORDER BY column_name SEPARATOR ''), '')
      INTO v_colunas, v_valores
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'lancamento_mensal'
      AND column_name IN ('fonte_dado','origem_dado','nome_fonte');

    DROP TEMPORARY TABLE IF EXISTS demo_confeccao;
    CREATE TEMPORARY TABLE demo_confeccao (
        id_confeccao INT NOT NULL PRIMARY KEY,
        nome VARCHAR(120) NOT NULL,
        porte VARCHAR(10) NOT NULL,
        tipo VARCHAR(10) NOT NULL,
        cidade VARCHAR(80) NOT NULL
    );
    INSERT INTO demo_confeccao VALUES
        (9001, 'Demo Alto do Agreste', 'MEDIA', 'CONFECCAO', 'Caruaru'),
        (9002, 'Demo Feira Moderna', 'PEQUENA', 'CONFECCAO', 'Caruaru'),
        (9003, 'Demo Pequeno Passo', 'PEQUENA', 'CONFECCAO', 'Caruaru'),
        (9004, 'Demo Linha Firme', 'MICRO', 'FACCAO', 'Caruaru'),
        (9005, 'Demo Azul Profundo', 'MEDIA', 'CONFECCAO', 'Toritama'),
        (9006, 'Demo Denim Nordeste', 'MEDIA', 'CONFECCAO', 'Toritama'),
        (9007, 'Demo Lavanderia Indigo', 'PEQUENA', 'FACCAO', 'Toritama'),
        (9008, 'Demo Costura Reta', 'MICRO', 'FACCAO', 'Toritama'),
        (9009, 'Demo Malha Viva', 'MEDIA', 'CONFECCAO', 'Santa Cruz do Capibaribe'),
        (9010, 'Demo Movimento Fit', 'PEQUENA', 'CONFECCAO', 'Santa Cruz do Capibaribe'),
        (9011, 'Demo Sol e Sal', 'PEQUENA', 'CONFECCAO', 'Santa Cruz do Capibaribe'),
        (9012, 'Demo Ponto Certo', 'MICRO', 'FACCAO', 'Santa Cruz do Capibaribe');

    DROP TEMPORARY TABLE IF EXISTS demo_producao;
    CREATE TEMPORARY TABLE demo_producao (
        id_confeccao INT NOT NULL,
        categoria VARCHAR(50) NOT NULL,
        pecas_base INT NOT NULL,
        preco DECIMAL(6,2) NOT NULL,
        crescimento_anual DECIMAL(4,3) NOT NULL,
        PRIMARY KEY (id_confeccao, categoria)
    );
    INSERT INTO demo_producao VALUES
        (9001, 'Moda Feminina', 4200, 48.00, 1.005),
        (9001, 'Moda Masculina', 1800, 52.00, 0.860),
        (9002, 'Moda Feminina', 2400, 45.00, 1.005),
        (9002, 'Moda Infantil', 1500, 32.00, 0.990),
        (9003, 'Moda Infantil', 2600, 30.00, 0.990),
        (9004, 'Moda Masculina', 900, 47.00, 0.860),
        (9005, 'Jeans', 5200, 72.00, 1.180),
        (9005, 'Moda Masculina', 2200, 58.00, 0.860),
        (9006, 'Jeans', 4600, 69.00, 1.180),
        (9007, 'Jeans', 2100, 64.00, 1.180),
        (9008, 'Moda Masculina', 1100, 50.00, 0.860),
        (9009, 'Moda Feminina', 3800, 38.00, 1.005),
        (9009, 'Moda Infantil', 2000, 28.00, 0.990),
        (9010, 'Fitness', 3100, 42.00, 1.120),
        (9011, 'Praia', 2300, 40.00, 0.880),
        (9011, 'Fitness', 1400, 44.00, 1.120),
        (9012, 'Moda Feminina', 1000, 35.00, 1.005);

    DROP TEMPORARY TABLE IF EXISTS demo_lancamento;
    CREATE TEMPORARY TABLE demo_lancamento AS
    WITH RECURSIVE meses (n) AS (
        SELECT 0 UNION ALL SELECT n + 1 FROM meses WHERE n < 23
    ),
    calendario AS (
        SELECT n, DATE('2024-11-01') + INTERVAL n MONTH AS mes_referencia
        FROM meses
    )
    SELECT c.mes_referencia,
           p.id_confeccao,
           p.categoria,
           p.preco,
           CAST(ROUND(
               p.pecas_base
               * IF(p.categoria = 'Praia',
                    ELT(MONTH(c.mes_referencia), 1.30, 1.15, 0.95, 0.80, 0.75, 0.80, 0.85, 0.85, 1.00, 1.15, 1.35, 1.50),
                    ELT(MONTH(c.mes_referencia), 0.78, 0.82, 0.92, 1.02, 1.28, 1.35, 0.88, 0.90, 0.95, 1.02, 1.25, 1.38))
               * POW(p.crescimento_anual, c.n DIV 12)
               * (1 + (CAST(CRC32(CONCAT(p.id_confeccao, p.categoria, MONTH(c.mes_referencia))) % 61 AS SIGNED) - 30) / 1000)
           ) AS SIGNED) AS quantidade
    FROM calendario c
    CROSS JOIN demo_producao p;

    START TRANSACTION;

    INSERT INTO categoria (nome)
    SELECT DISTINCT p.categoria
    FROM demo_producao p
    LEFT JOIN categoria cat ON cat.nome = p.categoria
    WHERE cat.id_categoria IS NULL;

    INSERT INTO confeccao (id_confeccao, nome, cnpj, porte, tipo, id_cidade)
    SELECT d.id_confeccao, d.nome, NULL, d.porte, d.tipo, ci.id_cidade
    FROM demo_confeccao d
    INNER JOIN cidade ci   ON ci.nome = d.cidade AND ci.uf = 'PE'
    LEFT JOIN confeccao co ON co.id_confeccao = d.id_confeccao
    WHERE co.id_confeccao IS NULL;

    IF EXISTS (SELECT 1 FROM demo_confeccao d
               INNER JOIN confeccao co ON co.id_confeccao = d.id_confeccao
               WHERE co.nome <> d.nome) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Os ids 9001 a 9012 de confeccao ja pertencem a outros cadastros.';
    END IF;

    SET @demo_sql = CONCAT(
        'INSERT INTO lancamento_mensal (mes_referencia, quantidade, faturamento, origem, lanc_status, id_confeccao, id_categoria, id_importacao',
        v_colunas,
        ') SELECT d.mes_referencia, d.quantidade, d.quantidade * d.preco, ''MANUAL'', ''ATIVO'', d.id_confeccao, cat.id_categoria, NULL',
        v_valores,
        ' FROM demo_lancamento d',
        ' INNER JOIN categoria cat ON cat.nome = d.categoria',
        ' LEFT JOIN lancamento_mensal l ON l.id_confeccao = d.id_confeccao',
        ' AND l.id_categoria = cat.id_categoria AND l.mes_referencia = d.mes_referencia',
        ' WHERE l.id_lancamento IS NULL');
    PREPARE demo_stmt FROM @demo_sql;
    EXECUTE demo_stmt;
    DEALLOCATE PREPARE demo_stmt;

    COMMIT;

    DROP TEMPORARY TABLE demo_confeccao;
    DROP TEMPORARY TABLE demo_producao;
    DROP TEMPORARY TABLE demo_lancamento;
END $$
DELIMITER ;

CALL carregar_demonstracao_projetai();
DROP PROCEDURE carregar_demonstracao_projetai;

CREATE OR REPLACE VIEW vw_serie_polo_regional AS
SELECT s.mes_referencia,
       s.municipio_id,
       s.municipio,
       s.uf,
       s.faturamento,
       s.volume_itens,
       ROUND((s.faturamento / NULLIF(LAG(s.faturamento) OVER w, 0) - 1) * 100, 2) AS variacao_mes_percentual
FROM (
    SELECT l.mes_referencia,
           ci.id_cidade AS municipio_id,
           ci.nome AS municipio,
           ci.uf,
           SUM(l.faturamento) AS faturamento,
           SUM(l.quantidade) AS volume_itens
    FROM lancamento_mensal l
    INNER JOIN confeccao c ON c.id_confeccao = l.id_confeccao
    INNER JOIN cidade ci   ON ci.id_cidade = c.id_cidade
    WHERE l.lanc_status = 'ATIVO'
    GROUP BY l.mes_referencia, ci.id_cidade, ci.nome, ci.uf
) s
WINDOW w AS (PARTITION BY s.municipio_id ORDER BY s.mes_referencia);

SELECT municipio, COUNT(*) AS meses, MIN(mes_referencia) AS inicio, MAX(mes_referencia) AS fim,
       SUM(faturamento) AS faturamento, SUM(volume_itens) AS itens
FROM vw_serie_polo_regional
WHERE municipio IN ('Caruaru','Toritama','Santa Cruz do Capibaribe')
GROUP BY municipio_id, municipio
ORDER BY faturamento DESC;
