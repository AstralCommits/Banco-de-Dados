PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS vw_historico_lancamento;
DROP VIEW IF EXISTS vw_lancamentos;
DROP TABLE IF EXISTS historico_lancamento;
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
    nome TEXT NOT NULL UNIQUE,
    uf TEXT NOT NULL,
    CONSTRAINT chk_cidade_agreste CHECK (
        uf = 'PE' AND nome IN ('Toritama', 'Caruaru', 'Santa Cruz do Capibaribe')
    )
);

CREATE TABLE confeccao (
    id_confeccao INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    cnpj TEXT NULL UNIQUE,
    porte TEXT NOT NULL,
    tipo TEXT NOT NULL,
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
    perfil TEXT NOT NULL,
    id_confeccao INTEGER NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    CONSTRAINT chk_usuario_perfil CHECK (perfil IN ('ADMIN','EMPRESARIO')),
    CONSTRAINT chk_usuario_perfil_confeccao CHECK (
        (perfil = 'ADMIN' AND id_confeccao IS NULL)
        OR (perfil = 'EMPRESARIO' AND id_confeccao IS NOT NULL)
    )
);

CREATE TABLE categoria (
    id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE CHECK (length(nome) <= 50)
);

CREATE TABLE importacao (
    id_importacao INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_arquivo TEXT NOT NULL,
    data_importacao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qtd_linhas INTEGER NULL,
    imp_status TEXT NOT NULL,
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    CONSTRAINT chk_imp_data   CHECK (data_importacao IS datetime(data_importacao)),
    CONSTRAINT chk_imp_status CHECK (imp_status IN ('CONCLUIDA','ERRO'))
);

CREATE TABLE lancamento_mensal (
    id_lancamento INTEGER PRIMARY KEY AUTOINCREMENT,
    mes_referencia TEXT NOT NULL,
    quantidade INTEGER NOT NULL,
    faturamento NUMERIC NOT NULL,
    origem TEXT NOT NULL,
    origem_dado TEXT NOT NULL,
    nome_fonte TEXT NOT NULL DEFAULT 'Fonte não informada',
    lanc_status TEXT NOT NULL DEFAULT 'ATIVO',
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
    CONSTRAINT chk_lanc_fonte     CHECK (origem_dado IN ('ENTREVISTA','QUESTIONARIO','FONTE_SECUNDARIA')),
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
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_cenario_impacto CHECK (percentual_impacto BETWEEN 0 AND 100)
);

CREATE TABLE relatorio (
    id_relatorio INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL,
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
    id_cidade INTEGER NULL,
    quantidade INTEGER NOT NULL,
    faturamento NUMERIC NOT NULL,
    variacao_percentual NUMERIC NULL,
    tendencia TEXT NULL,
    id_relatorio INTEGER NOT NULL,
    id_categoria INTEGER NULL,
    FOREIGN KEY (id_relatorio) REFERENCES relatorio (id_relatorio),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade),
    CONSTRAINT chk_item_tendencia CHECK (tendencia IS NULL OR tendencia IN ('ALTA','QUEDA','ESTAVEL'))
);

CREATE TABLE entrevista (
    id_entrevista INTEGER PRIMARY KEY AUTOINCREMENT,
    data TEXT NOT NULL,
    resumo TEXT NOT NULL,
    achou_algo_novo TEXT NOT NULL,
    id_confeccao INTEGER NOT NULL,
    id_categoria_percebida INTEGER NULL,
    FOREIGN KEY (id_confeccao) REFERENCES confeccao (id_confeccao),
    FOREIGN KEY (id_categoria_percebida) REFERENCES categoria (id_categoria),
    CONSTRAINT chk_entrevista_data CHECK (data IS date(data)),
    CONSTRAINT chk_entrevista_novo CHECK (achou_algo_novo IN ('SIM','NAO'))
);

CREATE TABLE historico_lancamento (
    id_historico INTEGER PRIMARY KEY AUTOINCREMENT,
    id_lancamento INTEGER NOT NULL,
    acao TEXT NOT NULL,
    origem TEXT NOT NULL,
    mes_referencia TEXT NOT NULL,
    id_confeccao INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    quantidade_antiga INTEGER NOT NULL,
    faturamento_antigo NUMERIC NOT NULL,
    status_antigo TEXT NOT NULL,
    quantidade_nova INTEGER NULL,
    faturamento_novo NUMERIC NULL,
    status_novo TEXT NULL,
    id_usuario INTEGER NULL,
    data_alteracao TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_hist_acao   CHECK (acao IN ('UPDATE','DELETE')),
    CONSTRAINT chk_hist_origem CHECK (origem IN ('MANUAL','IMPORTACAO'))
);

CREATE INDEX idx_historico_lancamento ON historico_lancamento (id_lancamento, data_alteracao);
CREATE INDEX idx_historico_data ON historico_lancamento (data_alteracao, origem);

CREATE TRIGGER trg_historico_lancamento_update
AFTER UPDATE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO historico_lancamento
    (id_lancamento, acao, origem, mes_referencia, id_confeccao, id_categoria,
     quantidade_antiga, faturamento_antigo, status_antigo,
     quantidade_nova, faturamento_novo, status_novo)
    VALUES
    (OLD.id_lancamento, 'UPDATE', OLD.origem, OLD.mes_referencia, OLD.id_confeccao, OLD.id_categoria,
     OLD.quantidade, OLD.faturamento, OLD.lanc_status,
     NEW.quantidade, NEW.faturamento, NEW.lanc_status);
END;

CREATE TRIGGER trg_historico_lancamento_delete
AFTER DELETE ON lancamento_mensal
FOR EACH ROW
BEGIN
    INSERT INTO historico_lancamento
    (id_lancamento, acao, origem, mes_referencia, id_confeccao, id_categoria,
     quantidade_antiga, faturamento_antigo, status_antigo)
    VALUES
    (OLD.id_lancamento, 'DELETE', OLD.origem, OLD.mes_referencia, OLD.id_confeccao, OLD.id_categoria,
     OLD.quantidade, OLD.faturamento, OLD.lanc_status);
END;

CREATE VIEW vw_lancamentos AS
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

CREATE VIEW vw_historico_lancamento AS
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


CREATE TABLE artesao (
    id_artesao INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_artistico TEXT NOT NULL UNIQUE CHECK (length(nome_artistico) <= 100),
    nome_civil TEXT NULL,
    municipio TEXT NOT NULL,
    uf TEXT NOT NULL DEFAULT 'PE' CHECK (uf = 'PE'),
    ano_nascimento INTEGER NULL,
    ano_falecimento INTEGER NULL,
    tecnica_principal TEXT NOT NULL,
    reconhecimento TEXT NULL,
    biografia TEXT NOT NULL,
    CHECK (ano_falecimento IS NULL OR ano_nascimento IS NULL OR ano_falecimento >= ano_nascimento)
);

CREATE TABLE produto (
    id_produto INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    descricao TEXT NOT NULL,
    tecnica TEXT NOT NULL,
    material TEXT NOT NULL,
    municipio_origem TEXT NOT NULL,
    preco_unitario NUMERIC NOT NULL CHECK (preco_unitario > 0),
    foto_url TEXT NOT NULL,
    prod_status TEXT NOT NULL DEFAULT 'ATIVO' CHECK (prod_status IN ('ATIVO','INATIVO')),
    id_artesao INTEGER NOT NULL REFERENCES artesao (id_artesao) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE (id_artesao, nome)
);

CREATE TABLE empresa_cliente (
    id_empresa INTEGER PRIMARY KEY AUTOINCREMENT,
    razao_social TEXT NOT NULL,
    nome_fantasia TEXT NULL,
    cnpj TEXT NOT NULL UNIQUE CHECK (length(cnpj) = 14 AND cnpj NOT GLOB '*[^0-9]*'),
    email TEXT NOT NULL CHECK (email LIKE '%_@_%._%'),
    telefone TEXT NULL,
    municipio TEXT NOT NULL,
    uf TEXT NOT NULL CHECK (length(uf) = 2),
    data_cadastro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pedido_corporativo (
    id_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
    data_pedido TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    prazo_entrega TEXT NULL,
    ped_status TEXT NOT NULL DEFAULT 'ORCAMENTO'
        CHECK (ped_status IN ('ORCAMENTO','CONFIRMADO','EM_PRODUCAO','ENTREGUE','CANCELADO')),
    observacao TEXT NULL,
    id_empresa INTEGER NOT NULL REFERENCES empresa_cliente (id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_usuario INTEGER NULL REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (prazo_entrega IS NULL OR prazo_entrega >= date(data_pedido))
);

CREATE TABLE item_pedido_corporativo (
    id_item_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
    quantidade INTEGER NOT NULL CHECK (quantidade >= 5),
    preco_unitario NUMERIC NOT NULL CHECK (preco_unitario > 0),
    id_pedido INTEGER NOT NULL REFERENCES pedido_corporativo (id_pedido) ON DELETE CASCADE ON UPDATE CASCADE,
    id_produto INTEGER NOT NULL REFERENCES produto (id_produto) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE (id_pedido, id_produto)
);

CREATE INDEX idx_produto_artesao ON produto (id_artesao, prod_status);
CREATE INDEX idx_produto_municipio_tecnica ON produto (municipio_origem, tecnica);
CREATE INDEX idx_pedido_empresa_status ON pedido_corporativo (id_empresa, ped_status, data_pedido);
CREATE INDEX idx_item_pedido_produto ON item_pedido_corporativo (id_produto);

CREATE TRIGGER trg_item_pedido_insert
BEFORE INSERT ON item_pedido_corporativo
FOR EACH ROW
WHEN (SELECT ped_status FROM pedido_corporativo WHERE id_pedido = NEW.id_pedido) IN ('ENTREGUE','CANCELADO')
  OR (SELECT prod_status FROM produto WHERE id_produto = NEW.id_produto) = 'INATIVO'
BEGIN
    SELECT RAISE(ABORT, 'Pedido entregue/cancelado ou produto inativo nao aceita novos itens.');
END;

CREATE TRIGGER trg_item_pedido_update
BEFORE UPDATE ON item_pedido_corporativo
FOR EACH ROW
WHEN (SELECT ped_status FROM pedido_corporativo WHERE id_pedido = NEW.id_pedido) IN ('ENTREGUE','CANCELADO')
BEGIN
    SELECT RAISE(ABORT, 'Pedido entregue ou cancelado nao pode ter itens alterados.');
END;

CREATE VIEW vw_pedido_corporativo AS
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
GROUP BY p.id_pedido;
