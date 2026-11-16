DROP DATABASE IF EXISTS confeccoes;

CREATE DATABASE IF NOT EXISTS confeccoes CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE confeccoes;

CREATE TABLE cidade (
    id_cidade INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE,
    uf CHAR(2) NOT NULL,
    CONSTRAINT chk_cidade_agreste CHECK (
        uf = 'PE' AND nome IN ('Toritama', 'Caruaru', 'Santa Cruz do Capibaribe')
    )
);

CREATE TABLE confeccao (
    id_confeccao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cnpj VARCHAR(14) NULL UNIQUE,
    porte VARCHAR(10) NOT NULL,
    tipo VARCHAR(10) NOT NULL,
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
    perfil VARCHAR(10) NOT NULL,
    id_confeccao INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    CONSTRAINT chk_usuario_perfil CHECK (perfil IN ('ADMIN','EMPRESARIO')),
    CONSTRAINT chk_usuario_perfil_confeccao CHECK (
        (perfil = 'ADMIN' AND id_confeccao IS NULL)
        OR (perfil = 'EMPRESARIO' AND id_confeccao IS NOT NULL)
    )
);

CREATE TABLE categoria (
    id_categoria INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE importacao (
    id_importacao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_arquivo VARCHAR(150) NOT NULL,
    data_importacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qtd_linhas INT NULL,
    imp_status VARCHAR(10) NOT NULL,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    CONSTRAINT chk_imp_status CHECK (imp_status IN ('CONCLUIDA','ERRO'))
);

CREATE TABLE lancamento_mensal (
    id_lancamento INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mes_referencia DATE NOT NULL,
    quantidade INT NOT NULL,
    faturamento DECIMAL(12,2) NOT NULL,
    origem VARCHAR(10) NOT NULL,
    origem_dado VARCHAR(30) NOT NULL,
    nome_fonte VARCHAR(200) NOT NULL DEFAULT 'Fonte não informada',
    lanc_status VARCHAR(10) NOT NULL DEFAULT 'ATIVO',
    id_confeccao INT NOT NULL,
    id_categoria INT NOT NULL,
    id_importacao INT NULL,
    
    UNIQUE (id_confeccao, id_categoria, mes_referencia),
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_importacao) REFERENCES importacao (id_importacao),
    CONSTRAINT chk_lanc_dia1      CHECK (DAY(mes_referencia) = 1),
    CONSTRAINT chk_lanc_origem    CHECK (origem IN ('MANUAL','IMPORTACAO')),
    CONSTRAINT chk_lanc_fonte     CHECK (origem_dado IN ('ENTREVISTA','QUESTIONARIO','FONTE_SECUNDARIA')),
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
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_cenario_impacto CHECK (percentual_impacto BETWEEN 0 AND 100)
);

CREATE TABLE relatorio (
    id_relatorio INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL,
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
    id_cidade INT NULL,
    quantidade INT NOT NULL,
    faturamento DECIMAL(12,2) NOT NULL,
    variacao_percentual DECIMAL(7,2) NULL,
    tendencia VARCHAR(10) NULL,
    id_relatorio INT NOT NULL,
    id_categoria INT NULL,
    FOREIGN KEY (id_relatorio) REFERENCES relatorio (id_relatorio),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade),
    CONSTRAINT chk_item_tendencia CHECK (tendencia IS NULL OR tendencia IN ('ALTA','QUEDA','ESTAVEL'))
);

CREATE TABLE entrevista (
    id_entrevista INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    data DATE NOT NULL,
    resumo TEXT NOT NULL,
    achou_algo_novo VARCHAR(3) NOT NULL,
    id_confeccao INT NOT NULL,
    id_categoria_percebida INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_entrevista_novo CHECK (achou_algo_novo IN ('SIM','NAO'))
);

CREATE TABLE historico_lancamento (
    id_historico INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_lancamento INT NOT NULL,
    acao VARCHAR(10) NOT NULL,
    origem VARCHAR(10) NOT NULL,
    mes_referencia DATE NOT NULL,
    id_confeccao INT NOT NULL,
    id_categoria INT NOT NULL,
    quantidade_antiga INT NOT NULL,
    faturamento_antigo DECIMAL(12,2) NOT NULL,
    status_antigo VARCHAR(10) NOT NULL,
    quantidade_nova INT NULL,
    faturamento_novo DECIMAL(12,2) NULL,
    status_novo VARCHAR(10) NULL,
    id_usuario INT NULL,
    data_alteracao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_hist_acao   CHECK (acao IN ('UPDATE','DELETE')),
    CONSTRAINT chk_hist_origem CHECK (origem IN ('MANUAL','IMPORTACAO'))
);

INSERT INTO cidade (id_cidade, nome, uf) VALUES
(1, 'Toritama', 'PE'),
(2, 'Caruaru', 'PE'),
(3, 'Santa Cruz do Capibaribe', 'PE');

INSERT INTO confeccao
(id_confeccao, nome, cnpj, porte, tipo, id_cidade) VALUES
(1, 'Jeans Toritama', '12345678000101', 'MEDIA', 'CONFECCAO', 1),
(2, 'Estilo Agreste', '23456789000102', 'PEQUENA', 'CONFECCAO', 2),
(3, 'Costura Nordeste', '34567890000103', 'MICRO', 'FACCAO', 2),
(4, 'Sulanca Santa Cruz', '45678901000104', 'PEQUENA', 'CONFECCAO', 3),
(5, 'Capibaribe Textil', '56789012000105', 'MEDIA', 'CONFECCAO', 3);

INSERT INTO usuario
(id_usuario, nome, email, senha_hash, perfil, id_confeccao) VALUES
(1, 'Administrador', 'admin@confeccoes.com', 'HASH_ADMIN_123', 'ADMIN', NULL),
(2, 'Ana Silva', 'ana@jeanstoritama.com', 'HASH_ANA_123', 'EMPRESARIO', 1),
(3, 'Bruno Santos', 'bruno@estiloagreste.com', 'HASH_BRUNO_123', 'EMPRESARIO', 2),
(4, 'Carla Oliveira', 'carla@costuranordeste.com', 'HASH_CARLA_123', 'EMPRESARIO', 3),
(5, 'Daniel Lima', 'daniel@sulancasantacruz.com', 'HASH_DANIEL_123', 'EMPRESARIO', 4),
(6, 'Eduarda Costa', 'eduarda@capibaribetextil.com', 'HASH_EDUARDA_123', 'EMPRESARIO', 5);

INSERT INTO categoria (id_categoria, nome) VALUES
(1, 'Moda Feminina'),
(2, 'Moda Masculina'),
(3, 'Moda Infantil'),
(4, 'Fitness'),
(5, 'Praia');

INSERT INTO importacao
(id_importacao, nome_arquivo, data_importacao, qtd_linhas, imp_status, id_usuario) VALUES
(1, 'vendas_jan_fev_jeanstoritama.csv',    '2026-03-01 09:15:00', 2, 'CONCLUIDA', 2),
(2, 'vendas_jan_fev_estiloagreste.csv',    '2026-03-01 10:20:00', 2, 'CONCLUIDA', 3),
(3, 'vendas_janeiro_costuranordeste.csv',  '2026-02-01 14:30:00', 1, 'CONCLUIDA', 4),
(4, 'vendas_janeiro_sulancasantacruz.csv', '2026-02-01 08:45:00', 1, 'CONCLUIDA', 5);

INSERT INTO lancamento_mensal
(id_lancamento, mes_referencia, quantidade, faturamento, origem, lanc_status,
 id_confeccao, id_categoria, id_importacao, origem_dado) VALUES

(1, '2026-01-01', 450, 31500.00, 'IMPORTACAO', 'ATIVO', 1, 1, 1, 'QUESTIONARIO'),
(2, '2026-01-01', 280, 19600.00, 'MANUAL', 'ATIVO', 1, 2, NULL, 'ENTREVISTA'),
(3, '2026-02-01', 510, 35700.00, 'IMPORTACAO', 'ATIVO', 1, 1, 1, 'QUESTIONARIO'),

(4, '2026-01-01', 220, 13200.00, 'IMPORTACAO', 'ATIVO', 2, 1, 2, 'QUESTIONARIO'),
(5, '2026-01-01', 180, 10800.00, 'MANUAL', 'ATIVO', 2, 3, NULL, 'FONTE_SECUNDARIA'),
(6, '2026-02-01', 250, 15000.00, 'IMPORTACAO', 'ATIVO', 2, 1, 2, 'QUESTIONARIO'),

(7, '2026-01-01', 160, 9600.00, 'IMPORTACAO', 'ATIVO', 3, 2, 3, 'QUESTIONARIO'),
(8, '2026-02-01', 190, 11400.00, 'MANUAL', 'ATIVO', 3, 2, NULL, 'ENTREVISTA'),

(9, '2026-01-01', 300, 21000.00, 'IMPORTACAO', 'ATIVO', 4, 4, 4, 'QUESTIONARIO'),
(10, '2026-02-01', 340, 23800.00, 'MANUAL', 'ATIVO', 4, 4, NULL, 'FONTE_SECUNDARIA'),

(11, '2026-01-01', 390, 27300.00, 'MANUAL', 'ATIVO', 5, 5, NULL, 'ENTREVISTA'),
(12, '2026-02-01', 420, 29400.00, 'MANUAL', 'ATIVO', 5, 5, NULL, 'ENTREVISTA');

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
 5.00, '2026-04-06 10:30:00', 1, NULL),

(3, 'TENDENCIA', '2026-01-01', '2026-03-31',
 5.00, '2026-04-07 14:00:00', 2, NULL),

(4, 'CENARIO', '2026-01-01', '2026-03-31',
 NULL, '2026-04-08 15:30:00', 3, 1);

INSERT INTO item_relatorio
(id_item, id_cidade, quantidade, faturamento, variacao_percentual,
 tendencia, id_relatorio, id_categoria) VALUES

(1, 2, 960, 67200.00, 8.50, 'ALTA', 1, 1),
(2, 3, 300, 21000.00, 3.20, 'ESTAVEL', 1, 2),
(3, 1, 390, 27300.00, -5.00, 'QUEDA', 1, 5),

(4, 2, 730, 44700.00, 12.00, 'ALTA', 2, 1),
(5, 2, 180, 10800.00, -2.50, 'ESTAVEL', 2, 3),
(6, 3, 300, 21000.00, 6.80, 'ALTA', 2, 2),

(7, 2, 960, 67200.00, 8.50, 'ALTA', 3, 1),
(8, 3, 300, 21000.00, 3.20, 'ESTAVEL', 3, 2),

(9, 2, 1050, 74700.00, 10.50, 'ALTA', 4, 1),
(10, 3, 300, 21000.00, 5.00, 'ALTA', 4, 2);

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

CREATE INDEX idx_lancamento_mes_categoria ON lancamento_mensal
    (mes_referencia, id_categoria, id_confeccao, lanc_status, quantidade, faturamento);
CREATE INDEX idx_lancamento_confeccao ON lancamento_mensal (id_confeccao);
CREATE INDEX idx_historico_lancamento ON historico_lancamento (id_lancamento, data_alteracao);
CREATE INDEX idx_historico_data ON historico_lancamento (data_alteracao, origem);
CREATE INDEX idx_cenario_usuario_nome ON cenario_concorrencia (id_usuario, nome);
CREATE INDEX idx_relatorio_usuario_data ON relatorio (id_usuario, data_geracao);

CREATE OR REPLACE VIEW vw_lancamentos AS
SELECT l.id_lancamento,
       l.mes_referencia,
       l.quantidade,
       l.faturamento,
       l.origem,
       l.origem_dado,
       l.nome_fonte,
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
    IN p_id_categoria INT,
    IN p_origem_dado VARCHAR(30)
)
BEGIN
    INSERT INTO lancamento_mensal
    (mes_referencia, quantidade, faturamento, origem, origem_dado, lanc_status,
     id_confeccao, id_categoria, id_importacao)
    VALUES
    (DATE_FORMAT(p_mes_referencia, '%Y-%m-01'), p_quantidade, p_faturamento,
     'MANUAL', p_origem_dado, 'ATIVO', p_id_confeccao, p_id_categoria, NULL);
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE atualizar_lancamento(
    IN p_id_lancamento INT,
    IN p_quantidade INT,
    IN p_faturamento DECIMAL(12,2),
    IN p_id_usuario INT
)
BEGIN
    IF (SELECT lanc_status FROM lancamento_mensal
        WHERE id_lancamento = p_id_lancamento) = 'CANCELADO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento cancelado nao pode ser atualizado.';
    END IF;

    SET @id_usuario = p_id_usuario;
    UPDATE lancamento_mensal
    SET quantidade = p_quantidade,
        faturamento = p_faturamento
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE cancelar_lancamento(
    IN p_id_lancamento INT,
    IN p_id_usuario INT
)
BEGIN
    SET @id_usuario = p_id_usuario;
    UPDATE lancamento_mensal
    SET lanc_status = 'CANCELADO'
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE excluir_lancamento(
    IN p_id_lancamento INT,
    IN p_id_usuario INT
)
BEGIN
    SET @id_usuario = p_id_usuario;
    DELETE FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;
    SET @id_usuario = NULL;
END $$
DELIMITER ;

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

CALL inserir_lancamento('2026-03-15', 360, 25200.00, 4, 4, 'ENTREVISTA');
SET @id_novo = LAST_INSERT_ID();
SELECT * FROM lancamento_mensal WHERE id_lancamento = @id_novo;
CALL atualizar_lancamento(10, 350, 24500.00, 5);
CALL cancelar_lancamento(8, 4);
CALL excluir_lancamento(@id_novo, 1);
SELECT * FROM historico_lancamento;

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

SELECT * FROM vw_historico_lancamento;
CALL relatorio_historico_periodo(CURDATE(), CURDATE(), NULL);
CALL relatorio_historico_periodo(CURDATE(), CURDATE(), 'MANUAL');
CALL relatorio_alteracoes_por_usuario(CURDATE(), CURDATE(), NULL);
CALL relatorio_alteracoes_por_confeccao(CURDATE(), CURDATE(), 'MANUAL');

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_jeanstoritama.csv', 2, 'CONCLUIDA', 2);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, origem_dado, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 530, 37100.00, 'IMPORTACAO', 'QUESTIONARIO', 'ATIVO', 1, 1, @id_importacao),
('2026-03-01', 300, 21000.00, 'IMPORTACAO', 'QUESTIONARIO', 'ATIVO', 1, 2, @id_importacao);

COMMIT;

SELECT * FROM lancamento_mensal WHERE id_importacao = @id_importacao;

START TRANSACTION;

INSERT INTO importacao (nome_arquivo, qtd_linhas, imp_status, id_usuario)
VALUES ('vendas_marco_estiloagreste.csv', 1, 'CONCLUIDA', 3);
SET @id_importacao = LAST_INSERT_ID();

INSERT INTO lancamento_mensal
(mes_referencia, quantidade, faturamento, origem, origem_dado, lanc_status,
 id_confeccao, id_categoria, id_importacao) VALUES
('2026-03-01', 270, 16200.00, 'IMPORTACAO', 'QUESTIONARIO', 'ATIVO', 2, 1, @id_importacao);

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

INSERT INTO item_relatorio (id_cidade, quantidade, faturamento, id_relatorio)
VALUES (2, 2880, 193500.00, @id_relatorio);

SAVEPOINT item_caruaru;

INSERT INTO item_relatorio (id_cidade, quantidade, faturamento, id_relatorio)
VALUES (3, 650, 45500.00, @id_relatorio);

SAVEPOINT item_santa_cruz;

INSERT INTO item_relatorio (id_cidade, quantidade, faturamento, id_relatorio)
VALUES (1, 810, 5670.00, @id_relatorio);

ROLLBACK TO SAVEPOINT item_santa_cruz;

INSERT INTO item_relatorio (id_cidade, quantidade, faturamento, id_relatorio)
VALUES (1, 810, 56700.00, @id_relatorio);

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

SELECT cidade,
       SUM(faturamento) AS faturamento_total,
       SUM(quantidade)  AS quantidade_total
FROM vw_lancamentos
GROUP BY cidade
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
ORDER BY cidade, confeccao, mes_referencia;

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

SELECT cat.nome AS categoria, ci.nome AS cidade, ir.variacao_percentual, ir.tendencia
FROM item_relatorio ir
INNER JOIN categoria cat ON ir.id_categoria = cat.id_categoria
LEFT JOIN cidade ci      ON ir.id_cidade = ci.id_cidade
ORDER BY ir.tendencia, ir.variacao_percentual DESC;

DROP VIEW IF EXISTS vw_pedido_corporativo;
DROP TABLE IF EXISTS item_pedido_corporativo;
DROP TABLE IF EXISTS pedido_corporativo;
DROP TABLE IF EXISTS empresa_cliente;
DROP TABLE IF EXISTS produto;
DROP TABLE IF EXISTS artesao;

CREATE TABLE artesao (
    id_artesao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_artistico VARCHAR(100) NOT NULL UNIQUE,
    nome_civil VARCHAR(120) NULL,
    municipio VARCHAR(60) NOT NULL,
    uf CHAR(2) NOT NULL DEFAULT 'PE',
    ano_nascimento SMALLINT NULL,
    ano_falecimento SMALLINT NULL,
    tecnica_principal VARCHAR(80) NOT NULL,
    reconhecimento VARCHAR(200) NULL,
    biografia VARCHAR(800) NOT NULL,
    CONSTRAINT chk_artesao_uf CHECK (uf = 'PE'),
    CONSTRAINT chk_artesao_anos CHECK (
        ano_falecimento IS NULL OR ano_nascimento IS NULL OR ano_falecimento >= ano_nascimento
    )
);

CREATE TABLE produto (
    id_produto INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    tecnica VARCHAR(80) NOT NULL,
    material VARCHAR(80) NOT NULL,
    municipio_origem VARCHAR(60) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    foto_url VARCHAR(255) NOT NULL,
    prod_status VARCHAR(10) NOT NULL DEFAULT 'ATIVO',
    id_artesao INT NOT NULL,
    UNIQUE (id_artesao, nome),
    FOREIGN KEY (id_artesao) REFERENCES artesao (id_artesao) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_produto_preco CHECK (preco_unitario > 0),
    CONSTRAINT chk_produto_status CHECK (prod_status IN ('ATIVO','INATIVO'))
);

CREATE TABLE empresa_cliente (
    id_empresa INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(150) NOT NULL,
    nome_fantasia VARCHAR(120) NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NULL,
    municipio VARCHAR(60) NOT NULL,
    uf CHAR(2) NOT NULL,
    data_cadastro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_empresa_cnpj_formato CHECK (cnpj REGEXP '^[0-9]{14}$'),
    CONSTRAINT chk_empresa_uf CHECK (uf REGEXP '^[A-Z]{2}$'),
    CONSTRAINT chk_empresa_email CHECK (email LIKE '%_@_%._%')
);

CREATE TABLE pedido_corporativo (
    id_pedido INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    prazo_entrega DATE NULL,
    ped_status VARCHAR(12) NOT NULL DEFAULT 'ORCAMENTO',
    observacao VARCHAR(300) NULL,
    id_empresa INT NOT NULL,
    id_usuario INT NULL,
    FOREIGN KEY (id_empresa) REFERENCES empresa_cliente (id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pedido_status CHECK (
        ped_status IN ('ORCAMENTO','CONFIRMADO','EM_PRODUCAO','ENTREGUE','CANCELADO')
    ),
    CONSTRAINT chk_pedido_prazo CHECK (prazo_entrega IS NULL OR prazo_entrega >= DATE(data_pedido))
);

CREATE TABLE item_pedido_corporativo (
    id_item_pedido INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    UNIQUE (id_pedido, id_produto),
    FOREIGN KEY (id_pedido) REFERENCES pedido_corporativo (id_pedido) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES produto (id_produto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_item_pedido_lote CHECK (quantidade >= 5),
    CONSTRAINT chk_item_pedido_preco CHECK (preco_unitario > 0)
);

CREATE INDEX idx_produto_artesao ON produto (id_artesao, prod_status);
CREATE INDEX idx_produto_municipio_tecnica ON produto (municipio_origem, tecnica);
CREATE INDEX idx_pedido_empresa_status ON pedido_corporativo (id_empresa, ped_status, data_pedido);
CREATE INDEX idx_item_pedido_produto ON item_pedido_corporativo (id_produto);

DROP FUNCTION IF EXISTS cnpj_valido;
DROP TRIGGER IF EXISTS trg_empresa_cnpj_insert;
DROP TRIGGER IF EXISTS trg_empresa_cnpj_update;
DROP TRIGGER IF EXISTS trg_item_pedido_insert;
DROP TRIGGER IF EXISTS trg_item_pedido_update;

DELIMITER $$
CREATE FUNCTION cnpj_valido(p_cnpj VARCHAR(14))
RETURNS TINYINT
DETERMINISTIC
NO SQL
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE soma INT DEFAULT 0;
    DECLARE dv1 INT;
    DECLARE dv2 INT;
    DECLARE pesos1 CHAR(12) DEFAULT '543298765432';
    DECLARE pesos2 CHAR(13) DEFAULT '6543298765432';

    IF p_cnpj IS NULL OR p_cnpj NOT REGEXP '^[0-9]{14}$' THEN
        RETURN 0;
    END IF;
    IF p_cnpj REGEXP '^(.)\\1{13}$' THEN
        RETURN 0;
    END IF;

    WHILE i <= 12 DO
        SET soma = soma + CAST(SUBSTRING(p_cnpj, i, 1) AS UNSIGNED) * CAST(SUBSTRING(pesos1, i, 1) AS UNSIGNED);
        SET i = i + 1;
    END WHILE;
    SET dv1 = IF(soma % 11 < 2, 0, 11 - soma % 11);

    SET i = 1;
    SET soma = 0;
    WHILE i <= 13 DO
        SET soma = soma + CAST(SUBSTRING(p_cnpj, i, 1) AS UNSIGNED) * CAST(SUBSTRING(pesos2, i, 1) AS UNSIGNED);
        SET i = i + 1;
    END WHILE;
    SET dv2 = IF(soma % 11 < 2, 0, 11 - soma % 11);

    RETURN IF(dv1 = CAST(SUBSTRING(p_cnpj, 13, 1) AS UNSIGNED)
          AND dv2 = CAST(SUBSTRING(p_cnpj, 14, 1) AS UNSIGNED), 1, 0);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_empresa_cnpj_insert
BEFORE INSERT ON empresa_cliente
FOR EACH ROW
BEGIN
    IF cnpj_valido(NEW.cnpj) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CNPJ invalido: digitos verificadores nao conferem.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_empresa_cnpj_update
BEFORE UPDATE ON empresa_cliente
FOR EACH ROW
BEGIN
    IF cnpj_valido(NEW.cnpj) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CNPJ invalido: digitos verificadores nao conferem.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_item_pedido_insert
BEFORE INSERT ON item_pedido_corporativo
FOR EACH ROW
BEGIN
    IF (SELECT ped_status FROM pedido_corporativo WHERE id_pedido = NEW.id_pedido) IN ('ENTREGUE','CANCELADO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido entregue ou cancelado nao aceita novos itens.';
    END IF;
    IF (SELECT prod_status FROM produto WHERE id_produto = NEW.id_produto) = 'INATIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto inativo nao pode entrar em pedido.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_item_pedido_update
BEFORE UPDATE ON item_pedido_corporativo
FOR EACH ROW
BEGIN
    IF (SELECT ped_status FROM pedido_corporativo WHERE id_pedido = NEW.id_pedido) IN ('ENTREGUE','CANCELADO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido entregue ou cancelado nao pode ter itens alterados.';
    END IF;
END$$
DELIMITER ;

CREATE OR REPLACE VIEW vw_pedido_corporativo AS
SELECT p.id_pedido,
       p.data_pedido,
       p.prazo_entrega,
       p.ped_status,
       e.id_empresa,
       e.razao_social,
       e.cnpj,
       COUNT(i.id_item_pedido) AS total_itens,
       COALESCE(SUM(i.quantidade), 0) AS total_pecas,
       COALESCE(SUM(i.quantidade * i.preco_unitario), 0) AS valor_total
FROM pedido_corporativo p
INNER JOIN empresa_cliente e ON p.id_empresa = e.id_empresa
LEFT JOIN item_pedido_corporativo i ON i.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.data_pedido, p.prazo_entrega, p.ped_status,
         e.id_empresa, e.razao_social, e.cnpj;

DELETE FROM item_pedido_corporativo;
DELETE FROM pedido_corporativo;
DELETE FROM empresa_cliente;
DELETE FROM produto;
DELETE FROM artesao;

INSERT INTO artesao
    (id_artesao, nome_artistico, nome_civil, municipio, uf, ano_nascimento, ano_falecimento, tecnica_principal, reconhecimento, biografia)
VALUES
    (1, 'Mestre Vitalino', 'Vitalino Pereira dos Santos', 'Caruaru', 'PE', 1909, 1963,
     'Cerâmica figurativa em barro',
     'Patrono da Arte do Barro de Pernambuco (Lei Estadual nº 16.998/2020)',
     'Ceramista popular e músico do Alto do Moura, em Caruaru. É a maior referência da arte figurativa em barro do Nordeste e formou a primeira geração de discípulos da comunidade.'),
    (2, 'Manuel Eudócio', 'Manuel Eudócio Rodrigues', 'Caruaru', 'PE', 1931, 2016,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco',
     'Discípulo direto de Mestre Vitalino no Alto do Moura. Os personagens mascarados são a marca do seu trabalho e, com Zé Caboclo, criou os olhos redondos pintados de branco que se tornaram característicos da escola vitaliniana.'),
    (3, 'Zé Caboclo', NULL, 'Caruaru', 'PE', 1921, 1973,
     'Cerâmica figurativa em barro',
     'Discípulo direto de Mestre Vitalino',
     'Um dos pioneiros da escola de cerâmica popular do Alto do Moura. Com a artesã Celestina Rodrigues formou uma família de ceramistas que mantém o ofício até hoje, entre eles a mestra Marliete Rodrigues.'),
    (4, 'Mestre Galdino', 'Manoel Galdino de Freitas', 'Caruaru', 'PE', NULL, 1996,
     'Cerâmica figurativa em barro',
     'Mestre do Alto do Moura',
     'Ceramista do Alto do Moura cuja estética de figuras fantásticas e quase surrealistas segue inspirando artesãos da comunidade.'),
    (5, 'Marliete Rodrigues', 'Marliete Rodrigues', 'Caruaru', 'PE', 1957, NULL,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco (2021) e de Caruaru (2022)',
     'Nascida no Alto do Moura, é filha do mestre Zé Caboclo e da artesã Celestina Rodrigues. É reconhecida como a principal expoente da geração seguinte aos discípulos de Vitalino e retrata cenas do cotidiano nordestino em barro.'),
    (6, 'Mestre Luiz Antônio', 'Luiz Antônio da Silva', 'Caruaru', 'PE', NULL, NULL,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco (2021) e de Caruaru',
     'Conheceu o trabalho de Mestre Vitalino aos 13 anos, no Alto do Moura. Representa em barro figuras do campo, como o matuto, as construções, as profissões e os animais da região.'),
    (7, 'Silvio Botelho', NULL, 'Olinda', 'PE', NULL, NULL,
     'Bonecos gigantes',
     'Principal mestre bonequeiro do carnaval de Olinda',
     'Artista plástico de Olinda, criou em 1974 o Menino da Tarde, seu primeiro boneco gigante. Fundou o Encontro dos Bonecos Gigantes de Olinda e já produziu mais de mil bonecos em cinco décadas de carreira.'),
    (8, 'Mestre Nado', NULL, 'Olinda', 'PE', NULL, NULL,
     'Cerâmica musical (ocarinas de barro)',
     'Patrimônio Vivo de Pernambuco (2019)',
     'Produz há mais de 20 anos ocarinas e outros instrumentos de sopro em barro. Mantém o Centro Cultural Som do Barro, com trabalho educativo para crianças na comunidade de Caixa d''Água, em Olinda.'),
    (9, 'Seu Celé', 'Celestino Mota', 'Cabo de Santo Agostinho', 'PE', NULL, NULL,
     'Cerâmica vermelha utilitária',
     'Membro mais antigo do Grupo de Ceramistas do Cabo de Santo Agostinho',
     'Mestre ceramista do Cabo de Santo Agostinho, referência da cerâmica utilitária local. Sua obra serviu de base para a linha de utilitários de mesa desenvolvida com o Laboratório O Imaginário da UFPE.'),
    (10, 'Francisco Brennand', NULL, 'Recife', 'PE', 1927, 2019,
     'Cerâmica artística',
     'Fundador da Oficina Cerâmica Francisco Brennand',
     'Ceramista, pintor e escultor recifense. Transformou uma antiga olaria da família, na Várzea, na Oficina Cerâmica Francisco Brennand, um dos principais destinos culturais do Recife.');

INSERT INTO produto
    (id_produto, nome, descricao, tecnica, material, municipio_origem, preco_unitario, foto_url, id_artesao)
VALUES
    (1, 'Casal de noivos a cavalo', 'Reprodução de ateliê da cena clássica do casamento matuto, modelada à mão e pintada.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 180.00, '/img/produtos/vitalino-noivos-cavalo.jpg', 1),
    (2, 'Banda de pífanos', 'Conjunto de quatro músicos da banda de pífanos, no estilo do mestre.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 260.00, '/img/produtos/vitalino-banda-pifanos.jpg', 1),
    (3, 'Retirantes', 'Família de retirantes a caminho, tema recorrente da obra vitaliniana.', 'Modelagem figurativa', 'Barro cozido', 'Caruaru', 210.00, '/img/produtos/vitalino-retirantes.jpg', 1),
    (4, 'Folguedo mascarado', 'Personagens de folguedo popular com as máscaras que marcam o estilo do mestre.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 190.00, '/img/produtos/eudocio-folguedo.jpg', 2),
    (5, 'Autorretrato do artesão', 'Figura do artesão trabalhando o barro, inspirada no autorretrato de Manuel Eudócio.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 230.00, '/img/produtos/eudocio-autorretrato.jpg', 2),
    (6, 'Casa de farinha', 'Cena da casa de farinha com forno e trabalhadores.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 320.00, '/img/produtos/eudocio-casa-farinha.jpg', 2),
    (7, 'Vaqueiro encourado', 'Vaqueiro com gibão e chapéu de couro, produzido pelo ateliê da família.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 150.00, '/img/produtos/zecaboclo-vaqueiro.jpg', 3),
    (8, 'Feira de Caruaru', 'Banca de feira com feirante e mercadorias em miniatura.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 280.00, '/img/produtos/zecaboclo-feira.jpg', 3),
    (9, 'Rendeira', 'Rendeira sentada com almofada de bilros.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 140.00, '/img/produtos/zecaboclo-rendeira.jpg', 3),
    (10, 'Figura fantástica', 'Escultura de figura fantástica na linha estética de Mestre Galdino.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 250.00, '/img/produtos/galdino-figura-fantastica.jpg', 4),
    (11, 'Lampião e Maria Bonita', 'Casal do cangaço em barro sem pintura, acabamento natural.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 220.00, '/img/produtos/galdino-cangaco.jpg', 4),
    (12, 'Cavaleiro sertanejo', 'Cavaleiro com montaria em proporções alongadas.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 200.00, '/img/produtos/galdino-cavaleiro.jpg', 4),
    (13, 'Cena de São João', 'Quadrilha junina com fogueira em pequeno formato.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 290.00, '/img/produtos/marliete-sao-joao.jpg', 5),
    (14, 'Cozinha nordestina', 'Cozinha com fogão a lenha, panelas e cozinheira.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 270.00, '/img/produtos/marliete-cozinha.jpg', 5),
    (15, 'Procissão', 'Procissão religiosa com andor e fiéis.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 340.00, '/img/produtos/marliete-procissao.jpg', 5),
    (16, 'Matuto com jumento', 'Matuto conduzindo jumento carregado de caçuás.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 160.00, '/img/produtos/luizantonio-matuto.jpg', 6),
    (17, 'Casa de taipa', 'Casa de taipa com moradores e animais no terreiro.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 240.00, '/img/produtos/luizantonio-casa-taipa.jpg', 6),
    (18, 'Profissões do Agreste', 'Trio com ferreiro, sapateiro e costureira.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 210.00, '/img/produtos/luizantonio-profissoes.jpg', 6),
    (19, 'Miniatura do Menino da Tarde', 'Miniatura de mesa do boneco gigante criado em 1974.', 'Bonecaria', 'Papel machê, tecido e madeira', 'Olinda', 350.00, '/img/produtos/botelho-menino-tarde.jpg', 7),
    (20, 'Boneco gigante sob encomenda', 'Boneco gigante personalizado para eventos e desfiles.', 'Bonecaria', 'Fibra de vidro, tecido e madeira', 'Olinda', 9500.00, '/img/produtos/botelho-boneco-gigante.jpg', 7),
    (21, 'Cabeça de boneco decorativa', 'Cabeça de boneco em tamanho reduzido para decoração.', 'Bonecaria', 'Papel machê pintado', 'Olinda', 420.00, '/img/produtos/botelho-cabeca.jpg', 7),
    (22, 'Ocarina de pássaro', 'Ocarina afinada em formato de pássaro.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 85.00, '/img/produtos/nado-ocarina-passaro.jpg', 8),
    (23, 'Ocarina de quatro furos', 'Ocarina didática para iniciação musical.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 60.00, '/img/produtos/nado-ocarina-didatica.jpg', 8),
    (24, 'Apito de barro', 'Apito em formato de animal da fauna local.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 35.00, '/img/produtos/nado-apito.jpg', 8),
    (25, 'Moringa tradicional', 'Moringa para água em cerâmica vermelha.', 'Torno e modelagem', 'Argila vermelha', 'Cabo de Santo Agostinho', 70.00, '/img/produtos/cele-moringa.jpg', 9),
    (26, 'Jogo de pratos de mesa', 'Jogo com seis pratos vitrificados com esmalte natural.', 'Torno e vitrificação', 'Argila vermelha esmaltada', 'Cabo de Santo Agostinho', 260.00, '/img/produtos/cele-pratos.jpg', 9),
    (27, 'Panela de barro', 'Panela utilitária para cozimento lento.', 'Torno e modelagem', 'Argila vermelha', 'Cabo de Santo Agostinho', 95.00, '/img/produtos/cele-panela.jpg', 9),
    (28, 'Azulejo decorativo', 'Azulejo em cerâmica esmaltada com motivo vegetal.', 'Cerâmica esmaltada', 'Cerâmica de alta temperatura', 'Recife', 120.00, '/img/produtos/brennand-azulejo.jpg', 10),
    (29, 'Vaso esmaltado', 'Vaso de cerâmica com esmalte de alta temperatura.', 'Cerâmica esmaltada', 'Cerâmica de alta temperatura', 'Recife', 480.00, '/img/produtos/brennand-vaso.jpg', 10),
    (30, 'Painel cerâmico pequeno', 'Painel de parede com placas cerâmicas em relevo.', 'Cerâmica em relevo', 'Cerâmica de alta temperatura', 'Recife', 1350.00, '/img/produtos/brennand-painel.jpg', 10);

INSERT INTO empresa_cliente
    (id_empresa, razao_social, nome_fantasia, cnpj, email, telefone, municipio, uf)
VALUES
    (1, 'Hotel Demonstração Boa Viagem Ltda', 'Hotel Demo BV', '11222333000181', 'compras@hoteldemo.com.br', '8130000001', 'Recife', 'PE'),
    (2, 'Loja Conceito Demonstração Ltda', 'Conceito Demo', '44555666000181', 'pedidos@conceitodemo.com.br', '8130000002', 'Olinda', 'PE'),
    (3, 'Eventos Demonstração Nordeste Ltda', 'Eventos Demo', '77888999000181', 'contato@eventosdemo.com.br', '8130000003', 'Caruaru', 'PE'),
    (4, 'Restaurante Demonstração Ltda', 'Restaurante Demo', '12345678000195', 'compras@restaurantedemo.com.br', '8130000004', 'Recife', 'PE');

INSERT INTO pedido_corporativo
    (id_pedido, data_pedido, prazo_entrega, ped_status, observacao, id_empresa, id_usuario)
VALUES
    (1, '2026-11-03 10:00:00', '2026-12-05', 'CONFIRMADO', 'Brindes de fim de ano para hóspedes.', 1, 1),
    (2, '2026-11-05 15:30:00', '2026-12-15', 'ORCAMENTO', 'Vitrine temática de Natal.', 2, 1),
    (3, '2026-11-08 09:00:00', '2027-01-20', 'EM_PRODUCAO', 'Louça para o novo salão.', 4, 1);

INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES
    (40, 85.00, 1, 22),
    (20, 140.00, 1, 9),
    (10, 150.00, 2, 7),
    (6, 290.00, 2, 13),
    (12, 260.00, 3, 26),
    (24, 95.00, 3, 27);
