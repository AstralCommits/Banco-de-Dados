USE confeccoes;

DELETE FROM item_pedido_corporativo;
DELETE FROM pedido_corporativo;
DELETE FROM empresa_cliente;
DELETE FROM produto;
DELETE FROM artesao;

INSERT INTO artesao
    (id_artesao, nome_artistico, nome_civil, municipio, uf, ano_nascimento, ano_falecimento, tecnica_principal, reconhecimento, biografia)
VALUES
    (1, 'Mestre Vitalino', 'Vitalino Pereira dos Santos', 'Caruaru', 'PE', 1909, 1963,
     'Cerâmica figurativa em barro',
     'Patrono da Arte do Barro de Pernambuco (Lei Estadual nº 16.998/2020)',
     'Ceramista popular e músico do Alto do Moura, em Caruaru. É a maior referência da arte figurativa em barro do Nordeste e formou a primeira geração de discípulos da comunidade.'),
    (2, 'Manuel Eudócio', 'Manuel Eudócio Rodrigues', 'Caruaru', 'PE', 1931, 2016,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco',
     'Discípulo direto de Mestre Vitalino no Alto do Moura. Os personagens mascarados são a marca do seu trabalho e, com Zé Caboclo, criou os olhos redondos pintados de branco que se tornaram característicos da escola vitaliniana.'),
    (3, 'Zé Caboclo', NULL, 'Caruaru', 'PE', 1921, 1973,
     'Cerâmica figurativa em barro',
     'Discípulo direto de Mestre Vitalino',
     'Um dos pioneiros da escola de cerâmica popular do Alto do Moura. Com a artesã Celestina Rodrigues formou uma família de ceramistas que mantém o ofício até hoje, entre eles a mestra Marliete Rodrigues.'),
    (4, 'Mestre Galdino', 'Manoel Galdino de Freitas', 'Caruaru', 'PE', NULL, 1996,
     'Cerâmica figurativa em barro',
     'Mestre do Alto do Moura',
     'Ceramista do Alto do Moura cuja estética de figuras fantásticas e quase surrealistas segue inspirando artesãos da comunidade.'),
    (5, 'Marliete Rodrigues', 'Marliete Rodrigues', 'Caruaru', 'PE', 1957, NULL,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco (2021) e de Caruaru (2022)',
     'Nascida no Alto do Moura, é filha do mestre Zé Caboclo e da artesã Celestina Rodrigues. É reconhecida como a principal expoente da geração seguinte aos discípulos de Vitalino e retrata cenas do cotidiano nordestino em barro.'),
    (6, 'Mestre Luiz Antônio', 'Luiz Antônio da Silva', 'Caruaru', 'PE', NULL, NULL,
     'Cerâmica figurativa em barro',
     'Patrimônio Vivo de Pernambuco (2021) e de Caruaru',
     'Conheceu o trabalho de Mestre Vitalino aos 13 anos, no Alto do Moura. Representa em barro figuras do campo, como o matuto, as construções, as profissões e os animais da região.'),
    (7, 'Silvio Botelho', NULL, 'Olinda', 'PE', NULL, NULL,
     'Bonecos gigantes',
     'Principal mestre bonequeiro do carnaval de Olinda',
     'Artista plástico de Olinda, criou em 1974 o Menino da Tarde, seu primeiro boneco gigante. Fundou o Encontro dos Bonecos Gigantes de Olinda e já produziu mais de mil bonecos em cinco décadas de carreira.'),
    (8, 'Mestre Nado', NULL, 'Olinda', 'PE', NULL, NULL,
     'Cerâmica musical (ocarinas de barro)',
     'Patrimônio Vivo de Pernambuco (2019)',
     'Produz há mais de 20 anos ocarinas e outros instrumentos de sopro em barro. Mantém o Centro Cultural Som do Barro, com trabalho educativo para crianças na comunidade de Caixa d''Água, em Olinda.'),
    (9, 'Seu Celé', 'Celestino Mota', 'Cabo de Santo Agostinho', 'PE', NULL, NULL,
     'Cerâmica vermelha utilitária',
     'Membro mais antigo do Grupo de Ceramistas do Cabo de Santo Agostinho',
     'Mestre ceramista do Cabo de Santo Agostinho, referência da cerâmica utilitária local. Sua obra serviu de base para a linha de utilitários de mesa desenvolvida com o Laboratório O Imaginário da UFPE.'),
    (10, 'Francisco Brennand', NULL, 'Recife', 'PE', 1927, 2019,
     'Cerâmica artística',
     'Fundador da Oficina Cerâmica Francisco Brennand',
     'Ceramista, pintor e escultor recifense. Transformou uma antiga olaria da família, na Várzea, na Oficina Cerâmica Francisco Brennand, um dos principais destinos culturais do Recife.');

INSERT INTO produto
    (id_produto, nome, descricao, tecnica, material, municipio_origem, preco_unitario, foto_url, id_artesao)
VALUES
    (1, 'Casal de noivos a cavalo', 'Reprodução de ateliê da cena clássica do casamento matuto, modelada à mão e pintada.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 180.00, '/img/produtos/vitalino-noivos-cavalo.jpg', 1),
    (2, 'Banda de pífanos', 'Conjunto de quatro músicos da banda de pífanos, no estilo do mestre.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 260.00, '/img/produtos/vitalino-banda-pifanos.jpg', 1),
    (3, 'Retirantes', 'Família de retirantes a caminho, tema recorrente da obra vitaliniana.', 'Modelagem figurativa', 'Barro cozido', 'Caruaru', 210.00, '/img/produtos/vitalino-retirantes.jpg', 1),
    (4, 'Folguedo mascarado', 'Personagens de folguedo popular com as máscaras que marcam o estilo do mestre.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 190.00, '/img/produtos/eudocio-folguedo.jpg', 2),
    (5, 'Autorretrato do artesão', 'Figura do artesão trabalhando o barro, inspirada no autorretrato de Manuel Eudócio.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 230.00, '/img/produtos/eudocio-autorretrato.jpg', 2),
    (6, 'Casa de farinha', 'Cena da casa de farinha com forno e trabalhadores.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 320.00, '/img/produtos/eudocio-casa-farinha.jpg', 2),
    (7, 'Vaqueiro encourado', 'Vaqueiro com gibão e chapéu de couro, produzido pelo ateliê da família.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 150.00, '/img/produtos/zecaboclo-vaqueiro.jpg', 3),
    (8, 'Feira de Caruaru', 'Banca de feira com feirante e mercadorias em miniatura.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 280.00, '/img/produtos/zecaboclo-feira.jpg', 3),
    (9, 'Rendeira', 'Rendeira sentada com almofada de bilros.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 140.00, '/img/produtos/zecaboclo-rendeira.jpg', 3),
    (10, 'Figura fantástica', 'Escultura de figura fantástica na linha estética de Mestre Galdino.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 250.00, '/img/produtos/galdino-figura-fantastica.jpg', 4),
    (11, 'Lampião e Maria Bonita', 'Casal do cangaço em barro sem pintura, acabamento natural.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 220.00, '/img/produtos/galdino-cangaco.jpg', 4),
    (12, 'Cavaleiro sertanejo', 'Cavaleiro com montaria em proporções alongadas.', 'Escultura figurativa', 'Barro cozido', 'Caruaru', 200.00, '/img/produtos/galdino-cavaleiro.jpg', 4),
    (13, 'Cena de São João', 'Quadrilha junina com fogueira em pequeno formato.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 290.00, '/img/produtos/marliete-sao-joao.jpg', 5),
    (14, 'Cozinha nordestina', 'Cozinha com fogão a lenha, panelas e cozinheira.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 270.00, '/img/produtos/marliete-cozinha.jpg', 5),
    (15, 'Procissão', 'Procissão religiosa com andor e fiéis.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 340.00, '/img/produtos/marliete-procissao.jpg', 5),
    (16, 'Matuto com jumento', 'Matuto conduzindo jumento carregado de caçuás.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 160.00, '/img/produtos/luizantonio-matuto.jpg', 6),
    (17, 'Casa de taipa', 'Casa de taipa com moradores e animais no terreiro.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 240.00, '/img/produtos/luizantonio-casa-taipa.jpg', 6),
    (18, 'Profissões do Agreste', 'Trio com ferreiro, sapateiro e costureira.', 'Modelagem figurativa', 'Barro cozido e pintado', 'Caruaru', 210.00, '/img/produtos/luizantonio-profissoes.jpg', 6),
    (19, 'Miniatura do Menino da Tarde', 'Miniatura de mesa do boneco gigante criado em 1974.', 'Bonecaria', 'Papel machê, tecido e madeira', 'Olinda', 350.00, '/img/produtos/botelho-menino-tarde.jpg', 7),
    (20, 'Boneco gigante sob encomenda', 'Boneco gigante personalizado para eventos e desfiles.', 'Bonecaria', 'Fibra de vidro, tecido e madeira', 'Olinda', 9500.00, '/img/produtos/botelho-boneco-gigante.jpg', 7),
    (21, 'Cabeça de boneco decorativa', 'Cabeça de boneco em tamanho reduzido para decoração.', 'Bonecaria', 'Papel machê pintado', 'Olinda', 420.00, '/img/produtos/botelho-cabeca.jpg', 7),
    (22, 'Ocarina de pássaro', 'Ocarina afinada em formato de pássaro.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 85.00, '/img/produtos/nado-ocarina-passaro.jpg', 8),
    (23, 'Ocarina de quatro furos', 'Ocarina didática para iniciação musical.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 60.00, '/img/produtos/nado-ocarina-didatica.jpg', 8),
    (24, 'Apito de barro', 'Apito em formato de animal da fauna local.', 'Cerâmica musical', 'Barro cozido', 'Olinda', 35.00, '/img/produtos/nado-apito.jpg', 8),
    (25, 'Moringa tradicional', 'Moringa para água em cerâmica vermelha.', 'Torno e modelagem', 'Argila vermelha', 'Cabo de Santo Agostinho', 70.00, '/img/produtos/cele-moringa.jpg', 9),
    (26, 'Jogo de pratos de mesa', 'Jogo com seis pratos vitrificados com esmalte natural.', 'Torno e vitrificação', 'Argila vermelha esmaltada', 'Cabo de Santo Agostinho', 260.00, '/img/produtos/cele-pratos.jpg', 9),
    (27, 'Panela de barro', 'Panela utilitária para cozimento lento.', 'Torno e modelagem', 'Argila vermelha', 'Cabo de Santo Agostinho', 95.00, '/img/produtos/cele-panela.jpg', 9),
    (28, 'Azulejo decorativo', 'Azulejo em cerâmica esmaltada com motivo vegetal.', 'Cerâmica esmaltada', 'Cerâmica de alta temperatura', 'Recife', 120.00, '/img/produtos/brennand-azulejo.jpg', 10),
    (29, 'Vaso esmaltado', 'Vaso de cerâmica com esmalte de alta temperatura.', 'Cerâmica esmaltada', 'Cerâmica de alta temperatura', 'Recife', 480.00, '/img/produtos/brennand-vaso.jpg', 10),
    (30, 'Painel cerâmico pequeno', 'Painel de parede com placas cerâmicas em relevo.', 'Cerâmica em relevo', 'Cerâmica de alta temperatura', 'Recife', 1350.00, '/img/produtos/brennand-painel.jpg', 10);

INSERT INTO empresa_cliente
    (id_empresa, razao_social, nome_fantasia, cnpj, email, telefone, municipio, uf)
VALUES
    (1, 'Hotel Demonstração Boa Viagem Ltda', 'Hotel Demo BV', '11222333000181', 'compras@hoteldemo.com.br', '8130000001', 'Recife', 'PE'),
    (2, 'Loja Conceito Demonstração Ltda', 'Conceito Demo', '44555666000181', 'pedidos@conceitodemo.com.br', '8130000002', 'Olinda', 'PE'),
    (3, 'Eventos Demonstração Nordeste Ltda', 'Eventos Demo', '77888999000181', 'contato@eventosdemo.com.br', '8130000003', 'Caruaru', 'PE'),
    (4, 'Restaurante Demonstração Ltda', 'Restaurante Demo', '12345678000195', 'compras@restaurantedemo.com.br', '8130000004', 'Recife', 'PE');

INSERT INTO pedido_corporativo
    (id_pedido, data_pedido, prazo_entrega, ped_status, observacao, id_empresa, id_usuario)
VALUES
    (1, '2026-11-03 10:00:00', '2026-12-05', 'CONFIRMADO', 'Brindes de fim de ano para hóspedes.', 1, 1),
    (2, '2026-11-05 15:30:00', '2026-12-15', 'ORCAMENTO', 'Vitrine temática de Natal.', 2, 1),
    (3, '2026-11-08 09:00:00', '2027-01-20', 'EM_PRODUCAO', 'Louça para o novo salão.', 4, 1);

INSERT INTO item_pedido_corporativo (quantidade, preco_unitario, id_pedido, id_produto) VALUES
    (40, 85.00, 1, 22),
    (20, 140.00, 1, 9),
    (10, 150.00, 2, 7),
    (6, 290.00, 2, 13),
    (12, 260.00, 3, 26),
    (24, 95.00, 3, 27);
