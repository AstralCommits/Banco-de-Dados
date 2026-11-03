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
    fonte_dado VARCHAR(20) NOT NULL,
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
    CONSTRAINT chk_lanc_fonte     CHECK (fonte_dado IN ('ENTREVISTA','QUESTIONARIO','FONTE_SECUNDARIA')),
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
       l.fonte_dado,
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