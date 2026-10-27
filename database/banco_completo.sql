DROP DATABASE IF EXISTS confeccoes;

CREATE DATABASE IF NOT EXISTS confeccoes CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE confeccoes;

CREATE TABLE cidade (
    id_cidade INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    uf CHAR(2) NOT NULL
);

CREATE TABLE confeccao (
    id_confeccao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cnpj VARCHAR(14) NULL UNIQUE,
    porte VARCHAR(10) NOT NULL, -- MICRO, PEQUENA ou MEDIA
    tipo VARCHAR(10) NOT NULL,  -- CONFECCAO ou FACCAO
    id_cidade INT NOT NULL,
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade),
    CONSTRAINT chk_confeccao_porte CHECK (porte IN ('MICRO','PEQUENA','MEDIA')),
    CONSTRAINT chk_confeccao_tipo  CHECK (tipo IN ('CONFECCAO','FACCAO'))
);

CREATE TABLE usuario (
    id_usuario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    perfil VARCHAR(10) NOT NULL, -- ADMIN ou CONFECCAO
    id_confeccao INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    CONSTRAINT chk_usuario_perfil CHECK (perfil IN ('ADMIN','CONFECCAO')),
    -- ADMIN nao pertence a confeccao; usuario CONFECCAO precisa pertencer a uma
    CONSTRAINT chk_usuario_perfil_confeccao CHECK (
        (perfil = 'ADMIN' AND id_confeccao IS NULL)
        OR (perfil = 'CONFECCAO' AND id_confeccao IS NOT NULL)
    )
);

CREATE TABLE categoria (
    id_categoria INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE importacao (
    id_importacao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_arquivo VARCHAR(150) NOT NULL,
    data_importacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qtd_linhas INT NULL,
    imp_status VARCHAR(10) NOT NULL, -- CONCLUIDA ou ERRO
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    CONSTRAINT chk_imp_status CHECK (imp_status IN ('CONCLUIDA','ERRO'))
);

CREATE TABLE lancamento_mensal (
    id_lancamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mes_referencia DATE NOT NULL, -- sempre o dia 1 do mes
    quantidade INT NOT NULL,
    faturamento DECIMAL(12,2) NOT NULL,
    origem VARCHAR(10) NOT NULL, -- MANUAL ou IMPORTACAO
    lanc_status VARCHAR(10) NOT NULL DEFAULT 'ATIVO', -- ATIVO ou CANCELADO
    id_confeccao INT NOT NULL,
    id_categoria INT NOT NULL,
    id_importacao INT NULL,
    
    UNIQUE (id_confeccao, id_categoria, mes_referencia),
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_importacao) REFERENCES importacao (id_importacao),
    CONSTRAINT chk_lanc_dia1      CHECK (DAY(mes_referencia) = 1),
    CONSTRAINT chk_lanc_origem    CHECK (origem IN ('MANUAL','IMPORTACAO')),
    CONSTRAINT chk_lanc_status    CHECK (lanc_status IN ('ATIVO','CANCELADO')),
    CONSTRAINT chk_lanc_quant     CHECK (quantidade >= 0),
    CONSTRAINT chk_lanc_fatur     CHECK (faturamento >= 0)
);

CREATE TABLE cenario_concorrencia (
    id_cenario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    percentual_impacto DECIMAL(5,2) NOT NULL,
    descricao VARCHAR(300) NULL,
    id_usuario INT NOT NULL,
    id_categoria INT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
);

CREATE TABLE relatorio (
    id_relatorio INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL, -- REGIONAL, CATEGORIA_PERIODO, TENDENCIA ou CENARIO
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    limiar_tendencia DECIMAL(5,2) NULL,
    data_geracao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_usuario INT NOT NULL,
    id_cenario INT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_cenario) REFERENCES cenario_concorrencia (id_cenario),
    CONSTRAINT chk_relatorio_tipo CHECK (tipo IN ('REGIONAL','CATEGORIA_PERIODO','TENDENCIA','CENARIO')),
    CONSTRAINT chk_relatorio_periodo CHECK (periodo_fim >= periodo_inicio)
);

CREATE TABLE item_relatorio (
    id_item INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uf CHAR(2) NULL, -- PE, PB ou AL
    quantidade INT NOT NULL,
    faturamento DECIMAL(12,2) NOT NULL,
    variacao_percentual DECIMAL(7,2) NULL,
    tendencia VARCHAR(10) NULL, -- ALTA, QUEDA ou ESTAVEL
    id_relatorio INT NOT NULL,
    id_categoria INT NULL,
    FOREIGN KEY (id_relatorio) REFERENCES relatorio (id_relatorio),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_item_uf CHECK (uf IS NULL OR uf IN ('PE','PB','AL')),
    CONSTRAINT chk_item_tendencia CHECK (tendencia IS NULL OR tendencia IN ('ALTA','QUEDA','ESTAVEL'))
);

CREATE TABLE entrevista (
    id_entrevista INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    data DATE NOT NULL,
    resumo TEXT NOT NULL,
    achou_algo_novo VARCHAR(3) NOT NULL, -- SIM ou NAO
    id_confeccao INT NOT NULL,
    id_categoria_percebida INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_entrevista_novo CHECK (achou_algo_novo IN ('SIM','NAO'))
);

CREATE TABLE log_lancamento (
    id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_lancamento INT NOT NULL,
    acao VARCHAR(10) NOT NULL, -- UPDATE ou DELETE
    quantidade_antiga INT NOT NULL,
    faturamento_antigo DECIMAL(12,2) NOT NULL,
    status_antigo VARCHAR(10) NOT NULL,
    data_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_log_acao CHECK (acao IN ('UPDATE','DELETE'))
);

INSERT INTO cidade (id_cidade, nome, uf) VALUES
(1, 'Recife', 'PE'),
(2, 'Caruaru', 'PE'),
(3, 'Joao Pessoa', 'PB'),
(4, 'Maceio', 'AL');

INSERT INTO confeccao
(id_confeccao, nome, cnpj, porte, tipo, id_cidade) VALUES
(1, 'Moda Recife', '12345678000101', 'MEDIA', 'CONFECCAO', 1),
(2, 'Estilo Agreste', '23456789000102', 'PEQUENA', 'CONFECCAO', 2),
(3, 'Costura Nordeste', '34567890000103', 'MICRO', 'FACCAO', 2),
(4, 'Paraiba Fashion', '45678901000104', 'PEQUENA', 'CONFECCAO', 3),
(5, 'Alagoas Textil', '56789012000105', 'MEDIA', 'CONFECCAO', 4);

INSERT INTO usuario
(id_usuario, nome, email, senha_hash, perfil, id_confeccao) VALUES
(1, 'Administrador', 'admin@confeccoes.com', 'HASH_ADMIN_123', 'ADMIN', NULL),
(2, 'Ana Silva', 'ana@modarecife.com', 'HASH_ANA_123', 'CONFECCAO', 1),
(3, 'Bruno Santos', 'bruno@estiloagreste.com', 'HASH_BRUNO_123', 'CONFECCAO', 2),
(4, 'Carla Oliveira', 'carla@costuranordeste.com', 'HASH_CARLA_123', 'CONFECCAO', 3),
(5, 'Daniel Lima', 'daniel@paraibafashion.com', 'HASH_DANIEL_123', 'CONFECCAO', 4),
(6, 'Eduarda Costa', 'eduarda@alagoastextil.com', 'HASH_EDUARDA_123', 'CONFECCAO', 5);

INSERT INTO categoria (id_categoria, nome) VALUES
(1, 'Moda Feminina'),
(2, 'Moda Masculina'),
(3, 'Moda Infantil'),
(4, 'Fitness'),
(5, 'Praia');

INSERT INTO importacao
(id_importacao, nome_arquivo, data_importacao, qtd_linhas, imp_status, id_usuario) VALUES
(1, 'vendas_jan_fev_modarecife.csv',       '2026-03-01 09:15:00', 2, 'CONCLUIDA', 2),
(2, 'vendas_jan_fev_estiloagreste.csv',    '2026-03-01 10:20:00', 2, 'CONCLUIDA', 3),
(3, 'vendas_janeiro_costuranordeste.csv',  '2026-02-01 14:30:00', 1, 'CONCLUIDA', 4),
(4, 'vendas_janeiro_paraibafashion.csv',   '2026-02-01 08:45:00', 1, 'CONCLUIDA', 5);

INSERT INTO lancamento_mensal
(id_lancamento, mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES

(1, '2026-01-01', 450, 31500.00, 'IMPORTACAO', 'ATIVO', 1, 1, 1),
(2, '2026-01-01', 280, 19600.00, 'MANUAL', 'ATIVO', 1, 2, NULL),
(3, '2026-02-01', 510, 35700.00, 'IMPORTACAO', 'ATIVO', 1, 1, 1),

(4, '2026-01-01', 220, 13200.00, 'IMPORTACAO', 'ATIVO', 2, 1, 2),
(5, '2026-01-01', 180, 10800.00, 'MANUAL', 'ATIVO', 2, 3, NULL),
(6, '2026-02-01', 250, 15000.00, 'IMPORTACAO', 'ATIVO', 2, 1, 2),

(7, '2026-01-01', 160, 9600.00, 'IMPORTACAO', 'ATIVO', 3, 2, 3),
(8, '2026-02-01', 190, 11400.00, 'MANUAL', 'ATIVO', 3, 2, NULL),

(9, '2026-01-01', 300, 21000.00, 'IMPORTACAO', 'ATIVO', 4, 4, 4),
(10, '2026-02-01', 340, 23800.00, 'MANUAL', 'ATIVO', 4, 4, NULL),

(11, '2026-01-01', 390, 27300.00, 'MANUAL', 'ATIVO', 5, 5, NULL),
(12, '2026-02-01', 420, 29400.00, 'MANUAL', 'ATIVO', 5, 5, NULL);

INSERT INTO cenario_concorrencia
(id_cenario, nome, percentual_impacto, descricao, id_usuario, id_categoria) VALUES

(1, 'Aumento da concorrencia', 10.00,
 'Simulacao de aumento da concorrencia no mercado.',
 2, 1),

(2, 'Entrada de novo concorrente', 15.00,
 'Simulacao da entrada de uma nova confeccao na regiao.',
 3, 2),

(3, 'Queda de demanda', 8.00,
 'Simulacao de reducao da demanda pela categoria.',
 5, 4),

(4, 'Expansao regional', 12.50,
 'Simulacao de crescimento da demanda em novos mercados.',
 1, NULL);

INSERT INTO relatorio
(id_relatorio, tipo, periodo_inicio, periodo_fim, limiar_tendencia,
 data_geracao, id_usuario, id_cenario) VALUES

(1, 'REGIONAL', '2026-01-01', '2026-03-31',
 5.00, '2026-04-05 09:00:00', 1, NULL),

(2, 'CATEGORIA_PERIODO', '2026-01-01', '2026-03-31',
 10.00, '2026-04-06 10:30:00', 1, NULL),

(3, 'TENDENCIA', '2026-01-01', '2026-03-31',
 5.00, '2026-04-07 14:00:00', 2, NULL),

(4, 'CENARIO', '2026-01-01', '2026-03-31',
 NULL, '2026-04-08 15:30:00', 3, 1);

INSERT INTO item_relatorio
(id_item, uf, quantidade, faturamento, variacao_percentual,
 tendencia, id_relatorio, id_categoria) VALUES

(1, 'PE', 960, 67200.00, 8.50, 'ALTA', 1, 1),
(2, 'PB', 300, 21000.00, 3.20, 'ESTAVEL', 1, 2),
(3, 'AL', 390, 27300.00, -4.50, 'QUEDA', 1, 5),

(4, 'PE', 730, 44700.00, 12.00, 'ALTA', 2, 1),
(5, 'PE', 180, 10800.00, -2.50, 'QUEDA', 2, 3),
(6, 'PB', 300, 21000.00, 6.80, 'ALTA', 2, 2),

(7, 'PE', 960, 67200.00, 8.50, 'ALTA', 3, 1),
(8, 'PB', 300, 21000.00, 3.20, 'ESTAVEL', 3, 2),

(9, 'PE', 1050, 74700.00, 10.50, 'ALTA', 4, 1),
(10, 'PB', 300, 21000.00, 5.00, 'ALTA', 4, 2);

INSERT INTO entrevista
(id_entrevista, data, resumo, achou_algo_novo,
 id_confeccao, id_categoria_percebida) VALUES

(1, '2026-01-15',
 'A empresa identificou aumento da procura por moda feminina.',
 'SIM', 1, 1),

(2, '2026-01-20',
 'A empresa relatou estabilidade nas vendas de moda masculina.',
 'NAO', 2, 2),

(3, '2026-02-10',
 'Foi identificada maior procura por produtos fitness.',
 'SIM', 4, 4),

(4, '2026-02-18',
 'A empresa percebeu crescimento nas vendas de moda praia.',
 'SIM', 5, 5),

(5, '2026-03-05',
 'Nao foram identificadas novas tendencias relevantes.',
 'NAO', 3, NULL);

CREATE OR REPLACE VIEW vw_lancamentos AS
SELECT l.id_lancamento,
       l.mes_referencia,
       l.quantidade,
       l.faturamento,
       l.origem,
       l.lanc_status,
       c.id_confeccao,
       c.nome AS confeccao,
       cat.id_categoria,
       cat.nome AS categoria,
       ci.nome AS cidade,
       ci.uf
FROM lancamento_mensal l
INNER JOIN confeccao c   ON l.id_confeccao = c.id_confeccao
INNER JOIN categoria cat ON l.id_categoria = cat.id_categoria
INNER JOIN cidade ci     ON c.id_cidade = ci.id_cidade
WHERE l.lanc_status = 'ATIVO';

DROP PROCEDURE IF EXISTS inserir_lancamento;
DROP PROCEDURE IF EXISTS atualizar_lancamento;
DROP PROCEDURE IF EXISTS cancelar_lancamento;
DROP PROCEDURE IF EXISTS excluir_lancamento;

DELIMITER $$
CREATE PROCEDURE inserir_lancamento(
    IN p_mes_referencia DATE,
    IN p_quantidade INT,
    IN p_faturamento DECIMAL(12,2),
    IN p_id_confeccao INT,
    IN p_id_categoria INT
)
BEGIN
    INSERT INTO lancamento_mensal
    (mes_referencia, quantidade, faturamento, origem, lanc_status,
     id_confeccao, id_categoria, id_importacao)
    VALUES
    (DATE_FORMAT(p_mes_referencia, '%Y-%m-01'), p_quantidade, p_faturamento,
     'MANUAL', 'ATIVO', p_id_confeccao, p_id_categoria, NULL);
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE atualizar_lancamento(
    IN p_id_lancamento INT,
    IN p_quantidade INT,
    IN p_faturamento DECIMAL(12,2)
)
BEGIN
    -- Nao permite alterar lancamentos ja cancelados
    IF (SELECT lanc_status FROM lancamento_mensal
        WHERE id_lancamento = p_id_lancamento) = 'CANCELADO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento cancelado nao pode ser atualizado.';
    END IF;

    UPDATE lancamento_mensal
    SET quantidade = p_quantidade,
        faturamento = p_faturamento
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE cancelar_lancamento(
    IN p_id_lancamento INT
)
BEGIN
    UPDATE lancamento_mensal
    SET lanc_status = 'CANCELADO'
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE excluir_lancamento(
    IN p_id_lancamento INT
)
BEGIN
    DELETE FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;
END $$
DELIMITER ;

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

CALL inserir_lancamento('2026-03-15', 360, 25200.00, 4, 4);
SET @id_novo = LAST_INSERT_ID();
SELECT * FROM lancamento_mensal WHERE id_lancamento = @id_novo;
CALL atualizar_lancamento(10, 350, 24500.00);
CALL cancelar_lancamento(8);
CALL excluir_lancamento(@id_novo);
SELECT * FROM log_lancamento;

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_modarecife.csv', 2, 'CONCLUIDA', 2);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 530, 37100.00, 'IMPORTACAO', 'ATIVO', 1, 1, @id_importacao),
('2026-03-01', 300, 21000.00, 'IMPORTACAO', 'ATIVO', 1, 2, @id_importacao);

COMMIT;

SELECT * FROM lancamento_mensal WHERE id_importacao = @id_importacao;

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', 1, 'CONCLUIDA', 3);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 270, 16200.00, 'IMPORTACAO', 'ATIVO', 2, 1, @id_importacao);

ROLLBACK;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', NULL, 'ERRO', 3);

SELECT * FROM importacao;
SELECT * FROM lancamento_mensal WHERE id_confeccao = 2 AND mes_referencia = '2026-03-01';

START TRANSACTION;

INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
VALUES ('REGIONAL', '2026-01-01', '2026-03-31', 5.00, 1);
SET @id_relatorio = LAST_INSERT_ID();

SAVEPOINT relatorio_criado;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('PE', 2880, 193500.00, @id_relatorio);

SAVEPOINT item_pe;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('PB', 650, 45500.00, @id_relatorio);

SAVEPOINT item_pb;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('AL', 810, 5670.00, @id_relatorio);

ROLLBACK TO SAVEPOINT item_pb;

INSERT INTO item_relatorio (uf, quantidade, faturamento, id_relatorio)
VALUES ('AL', 810, 56700.00, @id_relatorio);

COMMIT;

SELECT * FROM item_relatorio WHERE id_relatorio = @id_relatorio;

START TRANSACTION;

INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
VALUES ('TENDENCIA', '2025-01-01', '2025-03-31', 5.00, 2);

ROLLBACK;
SELECT * FROM relatorio;

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