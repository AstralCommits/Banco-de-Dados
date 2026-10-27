
USE confeccoes;
 
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
(2, 'Ana Silva', 'ana@jeanstoritama.com', 'HASH_ANA_123', 'CONFECCAO', 1),
(3, 'Bruno Santos', 'bruno@estiloagreste.com', 'HASH_BRUNO_123', 'CONFECCAO', 2),
(4, 'Carla Oliveira', 'carla@costuranordeste.com', 'HASH_CARLA_123', 'CONFECCAO', 3),
(5, 'Daniel Lima', 'daniel@sulancasantacruz.com', 'HASH_DANIEL_123', 'CONFECCAO', 4),
(6, 'Eduarda Costa', 'eduarda@capibaribetextil.com', 'HASH_EDUARDA_123', 'CONFECCAO', 5);
 
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
 id_confeccao, id_categoria, id_importacao, fonte_dado) VALUES
 
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