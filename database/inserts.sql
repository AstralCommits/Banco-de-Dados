USE confeccoes;

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
(1, 'Administrador', 'admin@confeccoes.com', '$2a$10$RUHpWKL8l/MbvAtM6ieBSuaxvvBDVQqw6A2UiAlZUpOmWYKlzWkFi', 'ADMIN', NULL),
(2, 'Ana Silva', 'ana@modarecife.com', '$2a$10$dS3G2eqaYwRL8yZaR105iufic/MmQ.dmRObzykhRgvrt6xL2u6QiK', 'EMPRESARIO', 1),
(3, 'Bruno Santos', 'bruno@estiloagreste.com', '$2a$10$tzffyS3CASpBkKWhoiORAONZG8yIrXR0FJ5Ons2eX.K5OfC0F88o6', 'EMPRESARIO', 2),
(4, 'Carla Oliveira', 'carla@costuranordeste.com', '$2a$10$I2IHsshvvutHa9eUjSZ64.B2ml3o6nRt/fU2FjT4hCqIPpkZk3xL.', 'EMPRESARIO', 3),
(5, 'Daniel Lima', 'daniel@paraibafashion.com', '$2a$10$yXxDfFNef572wcUQHGhBPevG0EcHJ8Y5M/.6z.cZ0zvgu7z.BY60K', 'EMPRESARIO', 4),
(6, 'Eduarda Costa', 'eduarda@alagoastextil.com', '$2a$10$dDKa.urDOEn8LNfbPevWKuR.fxUtQysSCCAYjrzJRvhFsxpaSgeie', 'EMPRESARIO', 5);

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

INSERT INTO produto (id_produto, nome, preco, id_confeccao) VALUES
(1, 'Camiseta bordada a mao', 80.00, 3),
(2, 'Bolsa de palha trancada', 120.00, 9),
(3, 'Vestido de renda', 250.00, 8),
(4, 'Bermuda jeans lavada', 95.00, 6),
(5, 'Blusa de croche', 70.00, 7);

INSERT INTO pedido_item
(id_item_pedido, id_pedido, id_produto, quantidade, preco_unitario) VALUES
(1, 1, 1, 3, 80.00),
(2, 2, 1, 2, 80.00),
(3, 5, 4, 10, 95.00),
(4, 6, 5, 6, 70.00),
(5, 7, 3, 2, 250.00),
(6, 8, 2, 4, 120.00),
(7, 9, 4, 5, 95.00),
(8, 10, 5, 8, 70.00);
