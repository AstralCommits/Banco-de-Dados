USE confeccoes;

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
