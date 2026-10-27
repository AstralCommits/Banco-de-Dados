-- Versao SQLite3 do schema.sql, para persistencia local (arquivo extensao.db).
-- Adaptacoes em relacao ao MySQL:
--   INT AUTO_INCREMENT   -> INTEGER PRIMARY KEY AUTOINCREMENT
--   VARCHAR / CHAR       -> TEXT (o SQLite nao limita tamanho; CHAR(2) virou CHECK de length)
--   DECIMAL(p,s)         -> NUMERIC
--   DATE / DATETIME      -> TEXT no formato ISO 8601 ('AAAA-MM-DD' e 'AAAA-MM-DD HH:MM:SS'), validado por CHECK
--   DAY(data) = 1        -> strftime('%d', data) = '01'
-- O SQLite nao tem procedures: inserir, atualizar, cancelar e excluir lancamentos ficam com o back-end.
-- As chaves estrangeiras so valem com PRAGMA foreign_keys = ON, que precisa ser ligado em cada conexao.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS vw_lancamentos;
DROP TABLE IF EXISTS log_lancamento;
DROP TABLE IF EXISTS entrevista;
DROP TABLE IF EXISTS item_relatorio;
DROP TABLE IF EXISTS relatorio;
DROP TABLE IF EXISTS cenario_concorrencia;
DROP TABLE IF EXISTS lancamento_mensal;
DROP TABLE IF EXISTS importacao;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS confeccao;
DROP TABLE IF EXISTS cidade;

CREATE TABLE cidade (
    id_cidade INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    uf TEXT NOT NULL CHECK (length(uf) = 2)
);

CREATE TABLE confeccao (
    id_confeccao INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    cnpj TEXT NULL UNIQUE,
    porte TEXT NOT NULL, -- MICRO, PEQUENA ou MEDIA
    tipo TEXT NOT NULL,  -- CONFECCAO ou FACCAO
    id_cidade INTEGER NOT NULL,
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade),
    CONSTRAINT chk_confeccao_porte CHECK (porte IN ('MICRO','PEQUENA','MEDIA')),
    CONSTRAINT chk_confeccao_tipo  CHECK (tipo IN ('CONFECCAO','FACCAO'))
);

CREATE TABLE usuario (
    id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    senha_hash TEXT NOT NULL,
    perfil TEXT NOT NULL, -- ADMIN ou CONFECCAO
    id_confeccao INTEGER NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    CONSTRAINT chk_usuario_perfil CHECK (perfil IN ('ADMIN','CONFECCAO')),
    CONSTRAINT chk_usuario_perfil_confeccao CHECK (
        (perfil = 'ADMIN' AND id_confeccao IS NULL)
        OR (perfil = 'CONFECCAO' AND id_confeccao IS NOT NULL)
    )
);

CREATE TABLE categoria (
    id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE
);

CREATE TABLE importacao (
    id_importacao INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_arquivo TEXT NOT NULL,
    data_importacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qtd_linhas INTEGER NULL,
    imp_status TEXT NOT NULL, -- CONCLUIDA ou ERRO
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    CONSTRAINT chk_imp_data   CHECK (data_importacao IS datetime(data_importacao)),
    CONSTRAINT chk_imp_status CHECK (imp_status IN ('CONCLUIDA','ERRO'))
);

CREATE TABLE lancamento_mensal (
    id_lancamento INTEGER PRIMARY KEY AUTOINCREMENT,
    mes_referencia TEXT NOT NULL, -- sempre o dia 1 do mes
    quantidade INTEGER NOT NULL,
    faturamento NUMERIC NOT NULL,
    origem TEXT NOT NULL, -- MANUAL ou IMPORTACAO
    lanc_status TEXT NOT NULL DEFAULT 'ATIVO', -- ATIVO ou CANCELADO
    id_confeccao INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    id_importacao INTEGER NULL,

    UNIQUE (id_confeccao, id_categoria, mes_referencia),
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_importacao) REFERENCES importacao (id_importacao),
    CONSTRAINT chk_lanc_data      CHECK (mes_referencia IS date(mes_referencia)),
    CONSTRAINT chk_lanc_dia1      CHECK (strftime('%d', mes_referencia) = '01'),
    CONSTRAINT chk_lanc_origem    CHECK (origem IN ('MANUAL','IMPORTACAO')),
    CONSTRAINT chk_lanc_status    CHECK (lanc_status IN ('ATIVO','CANCELADO')),
    CONSTRAINT chk_lanc_quant     CHECK (quantidade >= 0),
    CONSTRAINT chk_lanc_fatur     CHECK (faturamento >= 0)
);

CREATE TABLE cenario_concorrencia (
    id_cenario INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    percentual_impacto NUMERIC NOT NULL,
    descricao TEXT NULL,
    id_usuario INTEGER NOT NULL,
    id_categoria INTEGER NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
);

CREATE TABLE relatorio (
    id_relatorio INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL, -- REGIONAL, CATEGORIA_PERIODO, TENDENCIA ou CENARIO
    periodo_inicio TEXT NOT NULL,
    periodo_fim TEXT NOT NULL,
    limiar_tendencia NUMERIC NULL,
    data_geracao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_usuario INTEGER NOT NULL,
    id_cenario INTEGER NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_cenario) REFERENCES cenario_concorrencia (id_cenario),
    CONSTRAINT chk_relatorio_tipo CHECK (tipo IN ('REGIONAL','CATEGORIA_PERIODO','TENDENCIA','CENARIO')),
    CONSTRAINT chk_relatorio_datas CHECK (
        periodo_inicio IS date(periodo_inicio)
        AND periodo_fim IS date(periodo_fim)
        AND data_geracao IS datetime(data_geracao)
    ),
    CONSTRAINT chk_relatorio_periodo CHECK (periodo_fim >= periodo_inicio)
);

CREATE TABLE item_relatorio (
    id_item INTEGER PRIMARY KEY AUTOINCREMENT,
    uf TEXT NULL, -- PE, PB ou AL
    quantidade INTEGER NOT NULL,
    faturamento NUMERIC NOT NULL,
    variacao_percentual NUMERIC NULL,
    tendencia TEXT NULL, -- ALTA, QUEDA ou ESTAVEL
    id_relatorio INTEGER NOT NULL,
    id_categoria INTEGER NULL,
    FOREIGN KEY (id_relatorio) REFERENCES relatorio (id_relatorio),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_item_uf CHECK (uf IS NULL OR uf IN ('PE','PB','AL')),
    CONSTRAINT chk_item_tendencia CHECK (tendencia IS NULL OR tendencia IN ('ALTA','QUEDA','ESTAVEL'))
);

CREATE TABLE entrevista (
    id_entrevista INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT NOT NULL,
    resumo TEXT NOT NULL,
    achou_algo_novo TEXT NOT NULL, -- SIM ou NAO
    id_confeccao INTEGER NOT NULL,
    id_categoria_percebida INTEGER NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_entrevista_data CHECK (data IS date(data)),
    CONSTRAINT chk_entrevista_novo CHECK (achou_algo_novo IN ('SIM','NAO'))
);

CREATE TABLE log_lancamento (
    id_log INTEGER PRIMARY KEY AUTOINCREMENT,
    id_lancamento INTEGER NOT NULL,
    acao TEXT NOT NULL, -- UPDATE ou DELETE
    quantidade_antiga INTEGER NOT NULL,
    faturamento_antigo NUMERIC NOT NULL,
    status_antigo TEXT NOT NULL,
    data_log TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_log_acao CHECK (acao IN ('UPDATE','DELETE'))
);

-- Historico de lancamento (RN11): mesmos triggers do triggers.sql
CREATE TRIGGER trg_log_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.quantidade, OLD.faturamento, OLD.lanc_status);
END;

CREATE TRIGGER trg_log_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO log_lancamento
    (id_lancamento, acao, quantidade_antiga, faturamento_antigo, status_antigo)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.quantidade, OLD.faturamento, OLD.lanc_status);
END;

CREATE VIEW vw_lancamentos AS
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
