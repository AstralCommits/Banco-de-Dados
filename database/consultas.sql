USE confeccoes;

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
