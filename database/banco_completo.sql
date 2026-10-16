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
    tipo VARCHAR(10) NOT NULL, -- CONFECCAO ou FACCAO
    id_cidade INT NOT NULL,
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade)
);

CREATE TABLE usuario (
    id_usuario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    perfil VARCHAR(10) NOT NULL, -- ADMIN ou CONFECCAO
    id_confeccao INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao)
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
    imp_status VARCHAR(100) NOT NULL, -- CONCLUIDA ou ERRO
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE lancamento_mensal (
    id_lancamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mes_referencia DATE NOT NULL, -- sempre o dia 1 do mês
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
    FOREIGN KEY (id_importacao) REFERENCES importacao (id_importacao)
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
    FOREIGN KEY (id_cenario) REFERENCES cenario_concorrencia (id_cenario)
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
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
);

CREATE TABLE entrevista (
    id_entrevista INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    data DATE NOT NULL,
    resumo TEXT NOT NULL,
    achou_algo_novo VARCHAR(3) NOT NULL, -- SIM ou NAO
    id_confeccao INT NOT NULL,
    id_categoria_percebida INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria)
);

-- Auditoria: preenchida pelos triggers de triggers.sql.
-- Sem FK em id_lancamento, porque o log precisa sobreviver à exclusão do lançamento.
CREATE TABLE log_lancamento (
    id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_lancamento INT NOT NULL,
    acao VARCHAR(10) NOT NULL, -- UPDATE ou DELETE
    quantidade_antiga INT NOT NULL,
    faturamento_antigo DECIMAL(12,2) NOT NULL,
    status_antigo VARCHAR(10) NOT NULL,
    data_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
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
(1, 'vendas_janeiro.csv', '2026-02-01 09:15:00', 120, 'CONCLUIDA', 2),
(2, 'vendas_fevereiro.csv', '2026-03-01 10:20:00', 135, 'CONCLUIDA', 3),
(3, 'vendas_marco.csv', '2026-04-01 14:30:00', 98, 'CONCLUIDA', 4),
(4, 'vendas_abril.csv', '2026-05-01 08:45:00', 150, 'CONCLUIDA', 5);

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
VALUES ('vendas_marco_estiloagreste.csv', 2, 'CONCLUIDA', 3);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 270, 16200.00, 'IMPORTACAO', 'ATIVO', 2, 1, @id_importacao);

ROLLBACK;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', 2, 'ERRO', 3);

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
    confeccao.nome AS confeccao,
    confeccao.porte,
    cidade.nome AS cidade,
    cidade.uf
FROM confeccao
INNER JOIN cidade
    ON confeccao.id_cidade = cidade.id_cidade;

SELECT
    lancamento_mensal.mes_referencia,
    confeccao.nome AS confeccao,
    categoria.nome AS categoria,
    lancamento_mensal.quantidade,
    lancamento_mensal.faturamento,
    lancamento_mensal.origem
FROM lancamento_mensal
INNER JOIN confeccao
    ON lancamento_mensal.id_confeccao = confeccao.id_confeccao
INNER JOIN categoria
    ON lancamento_mensal.id_categoria = categoria.id_categoria
WHERE lancamento_mensal.lanc_status = 'ATIVO'
ORDER BY lancamento_mensal.mes_referencia, confeccao.nome;

SELECT
    cidade.uf,
    COUNT(lancamento_mensal.id_lancamento) AS total_lancamentos
FROM lancamento_mensal
INNER JOIN confeccao
    ON lancamento_mensal.id_confeccao = confeccao.id_confeccao
INNER JOIN cidade
    ON confeccao.id_cidade = cidade.id_cidade
WHERE lancamento_mensal.lanc_status = 'ATIVO'
GROUP BY cidade.uf;

SELECT
    categoria.nome AS categoria,
    ROUND(AVG(lancamento_mensal.faturamento), 2) AS media_faturamento
FROM lancamento_mensal
INNER JOIN categoria
    ON lancamento_mensal.id_categoria = categoria.id_categoria
WHERE lancamento_mensal.lanc_status = 'ATIVO'
GROUP BY categoria.nome;

SELECT
    ROUND(AVG(faturamento), 2) AS media_faturamento,
    MAX(faturamento) AS maior_faturamento,
    MIN(faturamento) AS menor_faturamento
FROM lancamento_mensal
WHERE lanc_status = 'ATIVO';

SELECT
    cidade.nome AS cidade,
    cidade.uf,
    COUNT(confeccao.id_confeccao) AS total_confeccoes
FROM cidade
LEFT JOIN confeccao
    ON cidade.id_cidade = confeccao.id_cidade
GROUP BY cidade.nome, cidade.uf;

SELECT
    usuario.nome AS usuario,
    usuario.perfil,
    importacao.nome_arquivo,
    importacao.imp_status
FROM usuario
LEFT JOIN importacao
    ON usuario.id_usuario = importacao.id_usuario
ORDER BY usuario.nome;

SELECT
    entrevista.data,
    confeccao.nome AS confeccao,
    categoria.nome AS categoria_percebida,
    entrevista.achou_algo_novo
FROM entrevista
INNER JOIN confeccao
    ON entrevista.id_confeccao = confeccao.id_confeccao
LEFT JOIN categoria
    ON entrevista.id_categoria_percebida = categoria.id_categoria;

SELECT
    relatorio.id_relatorio,
    relatorio.tipo,
    usuario.nome AS gerado_por,
    cenario_concorrencia.nome AS cenario,
    COUNT(item_relatorio.id_item) AS total_itens
FROM relatorio
INNER JOIN usuario
    ON relatorio.id_usuario = usuario.id_usuario
LEFT JOIN cenario_concorrencia
    ON relatorio.id_cenario = cenario_concorrencia.id_cenario
LEFT JOIN item_relatorio
    ON relatorio.id_relatorio = item_relatorio.id_relatorio
GROUP BY relatorio.id_relatorio, relatorio.tipo, usuario.nome, cenario_concorrencia.nome;

SELECT
    log_lancamento.data_log,
    log_lancamento.acao,
    log_lancamento.id_lancamento,
    log_lancamento.quantidade_antiga,
    log_lancamento.faturamento_antigo,
    log_lancamento.status_antigo
FROM log_lancamento
ORDER BY log_lancamento.data_log;
