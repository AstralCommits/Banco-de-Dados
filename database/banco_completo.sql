DROP DATABASE IF EXISTS confeccoes;

CREATE DATABASE IF NOT EXISTS confeccoes CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE confeccoes;

CREATE TABLE cidade (
    id_cidade INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    uf CHAR(2) NOT NULL,
    polo_destaque TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT chk_cidade_polo CHECK (polo_destaque IN (0,1))
);

CREATE TABLE confeccao (
    id_confeccao INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cnpj VARCHAR(14) NULL UNIQUE,
    porte VARCHAR(10) NOT NULL,
    tipo VARCHAR(10) NOT NULL,
    id_cidade INT NOT NULL,
    INDEX idx_confeccao_cidade (id_cidade),
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
    nome VARCHAR(60) NOT NULL UNIQUE
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
    lanc_status VARCHAR(10) NOT NULL DEFAULT 'ATIVO',
    id_confeccao INT NOT NULL,
    id_categoria INT NOT NULL,
    id_importacao INT NULL,
    UNIQUE (id_confeccao, id_categoria, mes_referencia),
    INDEX idx_lanc_status_mes (lanc_status, mes_referencia),
    INDEX idx_lanc_polo (lanc_status, id_confeccao, quantidade, faturamento),
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_importacao) REFERENCES importacao (id_importacao),
    CONSTRAINT chk_lanc_dia1      CHECK (DAY(mes_referencia) = 1),
    CONSTRAINT chk_lanc_origem    CHECK (origem IN ('MANUAL','IMPORTACAO')),
    CONSTRAINT chk_lanc_status    CHECK (lanc_status IN ('ATIVO','CANCELADO')),
    CONSTRAINT chk_lanc_quant     CHECK (quantidade >= 0),
    CONSTRAINT chk_lanc_fatur     CHECK (faturamento >= 0),
    CONSTRAINT chk_lanc_origem_importacao CHECK (
        (origem = 'IMPORTACAO' AND id_importacao IS NOT NULL)
        OR (origem = 'MANUAL' AND id_importacao IS NULL)
    )
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
    CONSTRAINT chk_cenario_impacto CHECK (percentual_impacto >= 0 AND percentual_impacto <= 100)
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
    CONSTRAINT chk_relatorio_periodo CHECK (periodo_fim >= periodo_inicio),
    CONSTRAINT chk_relatorio_cenario CHECK (
        (tipo = 'CENARIO' AND id_cenario IS NOT NULL)
        OR (tipo <> 'CENARIO' AND id_cenario IS NULL)
    )
);

CREATE TABLE item_relatorio (
    id_item INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uf CHAR(2) NULL,
    quantidade INT NOT NULL,
    faturamento DECIMAL(12,2) NOT NULL,
    variacao_percentual DECIMAL(7,2) NULL,
    tendencia VARCHAR(10) NULL,
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
    achou_algo_novo VARCHAR(3) NOT NULL,
    id_confeccao INT NOT NULL,
    id_categoria_percebida INT NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_entrevista_novo CHECK (achou_algo_novo IN ('SIM','NAO'))
);

CREATE TABLE log_lancamento (
    id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_lancamento INT NOT NULL,
    acao VARCHAR(10) NOT NULL,
    quantidade_antiga INT NOT NULL,
    faturamento_antigo DECIMAL(12,2) NOT NULL,
    status_antigo VARCHAR(10) NOT NULL,
    quantidade_nova INT NULL,
    faturamento_novo DECIMAL(12,2) NULL,
    status_novo VARCHAR(10) NULL,
    usuario_mysql VARCHAR(100) NULL,
    data_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_log_acao CHECK (acao IN ('UPDATE','DELETE'))
);

CREATE TABLE pedido (
    id_pedido INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ped_status VARCHAR(12) NOT NULL DEFAULT 'PENDENTE',
    data_entrega DATETIME NULL,
    id_usuario INT NOT NULL,
    id_confeccao INT NOT NULL,
    INDEX idx_pedido_data (data_pedido),
    INDEX idx_pedido_confeccao_status (id_confeccao, ped_status),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    UNIQUE (id_pedido, id_confeccao),
    CONSTRAINT chk_ped_status CHECK (ped_status IN ('PENDENTE','EM_TRANSITO','ENTREGUE','CANCELADO')),
    CONSTRAINT chk_ped_entrega CHECK (
        (ped_status = 'ENTREGUE' AND data_entrega IS NOT NULL)
        OR (ped_status <> 'ENTREGUE' AND data_entrega IS NULL)
    )
);

CREATE TABLE avaliacoes_artesao (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    artesao_id INT NOT NULL,
    nota TINYINT NOT NULL,
    comentario VARCHAR(500) NULL,
    data_avaliacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_avaliacao_pedido UNIQUE (pedido_id),
    CONSTRAINT chk_avaliacao_nota CHECK (nota BETWEEN 1 AND 5),
    CONSTRAINT fk_avaliacao_pedido_artesao
        FOREIGN KEY (pedido_id, artesao_id) REFERENCES pedido (id_pedido, id_confeccao)
        ON DELETE RESTRICT,
    INDEX idx_avaliacoes_artesao (artesao_id)
);

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

CREATE OR REPLACE VIEW vw_reputacao_artesao AS
SELECT c.id_confeccao AS artesao_id,
       c.nome AS artesao,
       ci.nome AS cidade,
       ci.uf,
       ROUND(AVG(a.nota), 2) AS nota_media,
       COUNT(a.id) AS total_avaliacoes
FROM confeccao c
INNER JOIN cidade ci ON c.id_cidade = ci.id_cidade
LEFT JOIN avaliacoes_artesao a ON a.artesao_id = c.id_confeccao
GROUP BY c.id_confeccao, c.nome, ci.nome, ci.uf;

CREATE OR REPLACE VIEW vw_vendas_polo_regional AS
SELECT ci.id_cidade AS municipio_id,
       ci.nome AS municipio,
       ci.uf,
       ci.polo_destaque,
       COALESCE(v.faturamento_total, 0) AS faturamento_total,
       COALESCE(v.volume_itens, 0) AS volume_itens,
       COALESCE(p.qtd_pedidos, 0) AS qtd_pedidos,
       ROUND(COALESCE(v.faturamento_total, 0) / NULLIF(v.volume_itens, 0), 2) AS ticket_medio_item
FROM cidade ci
LEFT JOIN (
    SELECT c.id_cidade,
           SUM(x.faturamento) AS faturamento_total,
           SUM(x.quantidade) AS volume_itens
    FROM (
        SELECT id_confeccao,
               SUM(faturamento) AS faturamento,
               SUM(quantidade) AS quantidade
        FROM lancamento_mensal
        WHERE lanc_status = 'ATIVO'
        GROUP BY id_confeccao
    ) x
    INNER JOIN confeccao c ON c.id_confeccao = x.id_confeccao
    GROUP BY c.id_cidade
) v ON v.id_cidade = ci.id_cidade
LEFT JOIN (
    SELECT c.id_cidade,
           COUNT(*) AS qtd_pedidos
    FROM pedido pe
    INNER JOIN confeccao c ON c.id_confeccao = pe.id_confeccao
    WHERE pe.ped_status <> 'CANCELADO'
    GROUP BY c.id_cidade
) p ON p.id_cidade = ci.id_cidade;

INSERT INTO cidade (id_cidade, nome, uf, polo_destaque) VALUES
(1, 'Recife', 'PE', 0),
(2, 'Caruaru', 'PE', 1),
(3, 'Joao Pessoa', 'PB', 0),
(4, 'Maceio', 'AL', 0),
(5, 'Toritama', 'PE', 1),
(6, 'Santa Cruz do Capibaribe', 'PE', 1),
(7, 'Olinda', 'PE', 1),
(8, 'Passira', 'PE', 1);

INSERT INTO confeccao
(id_confeccao, nome, cnpj, porte, tipo, id_cidade) VALUES
(1, 'Moda Recife', '12345678000101', 'MEDIA', 'CONFECCAO', 1),
(2, 'Estilo Agreste', '23456789000102', 'PEQUENA', 'CONFECCAO', 2),
(3, 'Costura Nordeste', '34567890000103', 'MICRO', 'FACCAO', 2),
(4, 'Paraiba Fashion', '45678901000104', 'PEQUENA', 'CONFECCAO', 3),
(5, 'Alagoas Textil', '56789012000105', 'MEDIA', 'CONFECCAO', 4),
(6, 'Jeans Toritama', '67890123000106', 'PEQUENA', 'CONFECCAO', 5),
(7, 'Moda Santa Cruz', '78901234000107', 'MEDIA', 'CONFECCAO', 6),
(8, 'Atelier Olinda', '89012345000108', 'MICRO', 'FACCAO', 7),
(9, 'Passira Artesanal', '90123456000109', 'MICRO', 'FACCAO', 8);

INSERT INTO usuario
(id_usuario, nome, email, senha_hash, perfil, id_confeccao) VALUES
(1, 'Administrador', 'admin@confeccoes.com', 'HASH_ADMIN_123', 'ADMIN', NULL),
(2, 'Ana Silva', 'ana@modarecife.com', 'HASH_ANA_123', 'EMPRESARIO', 1),
(3, 'Bruno Santos', 'bruno@estiloagreste.com', 'HASH_BRUNO_123', 'EMPRESARIO', 2),
(4, 'Carla Oliveira', 'carla@costuranordeste.com', 'HASH_CARLA_123', 'EMPRESARIO', 3),
(5, 'Daniel Lima', 'daniel@paraibafashion.com', 'HASH_DANIEL_123', 'EMPRESARIO', 4),
(6, 'Eduarda Costa', 'eduarda@alagoastextil.com', 'HASH_EDUARDA_123', 'EMPRESARIO', 5);

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
(12, '2026-02-01', 420, 29400.00, 'MANUAL', 'ATIVO', 5, 5, NULL),

(13, '2026-01-01', 520, 31200.00, 'MANUAL', 'ATIVO', 6, 2, NULL),
(14, '2026-02-01', 610, 36600.00, 'MANUAL', 'ATIVO', 6, 2, NULL),

(15, '2026-01-01', 480, 28800.00, 'MANUAL', 'ATIVO', 7, 1, NULL),
(16, '2026-02-01', 530, 31800.00, 'MANUAL', 'ATIVO', 7, 1, NULL),

(17, '2026-01-01', 90, 7200.00, 'MANUAL', 'ATIVO', 8, 3, NULL),
(18, '2026-02-01', 110, 8800.00, 'MANUAL', 'ATIVO', 8, 3, NULL),

(19, '2026-01-01', 60, 4800.00, 'MANUAL', 'ATIVO', 9, 3, NULL),
(20, '2026-02-01', 75, 6000.00, 'MANUAL', 'ATIVO', 9, 3, NULL);

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

INSERT INTO pedido
(id_pedido, data_pedido, ped_status, data_entrega, id_usuario, id_confeccao) VALUES
(1, '2026-02-02 10:00:00', 'ENTREGUE', '2026-02-09 15:30:00', 2, 3),
(2, '2026-02-10 11:20:00', 'ENTREGUE', '2026-02-17 09:00:00', 3, 3),
(3, '2026-03-01 08:40:00', 'PENDENTE', NULL, 5, 1),
(4, '2026-01-10 09:00:00', 'ENTREGUE', '2026-01-17 10:00:00', 2, 2),
(5, '2026-01-20 14:00:00', 'ENTREGUE', '2026-01-28 16:00:00', 3, 6),
(6, '2026-02-05 10:30:00', 'EM_TRANSITO', NULL, 2, 7),
(7, '2026-02-12 08:15:00', 'ENTREGUE', '2026-02-20 11:00:00', 5, 8),
(8, '2026-02-25 13:45:00', 'PENDENTE', NULL, 4, 9),
(9, '2026-03-03 09:20:00', 'CANCELADO', NULL, 6, 6),
(10, '2026-03-08 15:00:00', 'ENTREGUE', '2026-03-15 09:30:00', 2, 7),
(11, '2026-03-10 10:10:00', 'ENTREGUE', '2026-03-18 14:00:00', 3, 2);

INSERT INTO avaliacoes_artesao
(id, pedido_id, artesao_id, nota, comentario, data_avaliacao) VALUES
(1, 1, 3, 5, 'Pecas dentro do prazo e com acabamento excelente.', '2026-02-10 09:00:00'),
(2, 2, 3, 4, 'Boa qualidade, pequeno atraso na entrega.', '2026-02-18 14:10:00');

DROP PROCEDURE IF EXISTS inserir_lancamento;
DROP PROCEDURE IF EXISTS atualizar_lancamento;
DROP PROCEDURE IF EXISTS cancelar_lancamento;
DROP PROCEDURE IF EXISTS excluir_lancamento;
DROP PROCEDURE IF EXISTS gerar_relatorio_regional;

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
    DECLARE v_status VARCHAR(10);

    SELECT lanc_status INTO v_status
    FROM lancamento_mensal
    WHERE id_lancamento = p_id_lancamento;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lancamento nao encontrado.';
    ELSEIF v_status = 'CANCELADO' THEN
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

DELIMITER $$
CREATE PROCEDURE gerar_relatorio_regional(
    IN p_id_usuario INT,
    IN p_periodo_inicio DATE,
    IN p_periodo_fim DATE,
    IN p_limiar DECIMAL(5,2)
)
BEGIN
    DECLARE v_id_relatorio INT;
    DECLARE v_meses INT;
    DECLARE v_ant_inicio DATE;
    DECLARE v_ant_fim DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_meses = TIMESTAMPDIFF(MONTH, p_periodo_inicio, p_periodo_fim) + 1;
    SET v_ant_inicio = DATE_SUB(p_periodo_inicio, INTERVAL v_meses MONTH);
    SET v_ant_fim = DATE_SUB(p_periodo_inicio, INTERVAL 1 DAY);

    START TRANSACTION;

    INSERT INTO relatorio (tipo, periodo_inicio, periodo_fim, limiar_tendencia, id_usuario)
    VALUES ('REGIONAL', p_periodo_inicio, p_periodo_fim, p_limiar, p_id_usuario);
    SET v_id_relatorio = LAST_INSERT_ID();

    INSERT INTO item_relatorio
    (uf, quantidade, faturamento, variacao_percentual, tendencia, id_relatorio)
    SELECT a.uf, a.quantidade, a.faturamento, a.variacao,
           CASE WHEN a.variacao IS NULL THEN NULL
                WHEN a.variacao > p_limiar THEN 'ALTA'
                WHEN a.variacao < -p_limiar THEN 'QUEDA'
                ELSE 'ESTAVEL'
           END,
           v_id_relatorio
    FROM (
        SELECT atual.uf, atual.quantidade, atual.faturamento,
               CASE WHEN ant.faturamento IS NULL OR ant.faturamento = 0 THEN NULL
                    ELSE ROUND((atual.faturamento - ant.faturamento) / ant.faturamento * 100, 2)
               END AS variacao
        FROM (SELECT uf, SUM(quantidade) AS quantidade, SUM(faturamento) AS faturamento
              FROM vw_lancamentos
              WHERE mes_referencia BETWEEN p_periodo_inicio AND p_periodo_fim
              GROUP BY uf) atual
        LEFT JOIN (SELECT uf, SUM(faturamento) AS faturamento
                   FROM vw_lancamentos
                   WHERE mes_referencia BETWEEN v_ant_inicio AND v_ant_fim
                   GROUP BY uf) ant ON ant.uf = atual.uf
    ) a;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Periodo sem lancamentos ativos: relatorio nao gerado.';
    END IF;

    COMMIT;
    SELECT v_id_relatorio AS id_relatorio;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_log_lancamento_update;
DROP TRIGGER IF EXISTS trg_log_lancamento_delete;
DROP TRIGGER IF EXISTS trg_avaliacao_pedido_entregue;

DELIMITER $$
CREATE TRIGGER trg_log_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo,
     quantidade_nova, faturamento_novo, status_novo, usuario_mysql)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     NEW.quantidade, NEW.faturamento, NEW.lanc_status, CURRENT_USER());
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_log_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo,
     usuario_mysql)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     CURRENT_USER());
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_avaliacao_pedido_entregue
BEFORE INSERT ON avaliacoes_artesao
FOR EACH ROW
BEGIN
    IF (SELECT ped_status FROM pedido WHERE id_pedido = NEW.pedido_id) <> 'ENTREGUE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Somente pedidos entregues podem ser avaliados.';
    END IF;
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
SELECT * FROM pedido;
SELECT * FROM avaliacoes_artesao;

SELECT
    (SELECT COUNT(*) FROM cidade)            AS total_cidades,
    (SELECT COUNT(*) FROM confeccao)         AS total_confeccoes,
    (SELECT COUNT(*) FROM usuario)           AS total_usuarios,
    (SELECT COUNT(*) FROM categoria)         AS total_categorias,
    (SELECT COUNT(*) FROM lancamento_mensal) AS total_lancamentos,
    (SELECT COUNT(*) FROM entrevista)        AS total_entrevistas,
    (SELECT COUNT(*) FROM pedido)            AS total_pedidos,
    (SELECT COUNT(*) FROM avaliacoes_artesao) AS total_avaliacoes;

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
SELECT 'lancamento.status', lanc_status, COUNT(*) FROM lancamento_mensal GROUP BY lanc_status
UNION ALL
SELECT 'pedido.status', ped_status, COUNT(*) FROM pedido GROUP BY ped_status;

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
