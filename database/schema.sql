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
