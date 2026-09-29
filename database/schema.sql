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