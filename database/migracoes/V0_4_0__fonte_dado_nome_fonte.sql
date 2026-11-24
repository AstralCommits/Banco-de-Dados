SET NAMES utf8mb4;

USE confeccoes;

ALTER TABLE lancamento_mensal
    ADD COLUMN fonte_dado VARCHAR(20) NOT NULL DEFAULT 'FONTE_SECUNDARIA' AFTER origem,
    ADD COLUMN nome_fonte VARCHAR(200) NOT NULL DEFAULT 'Fonte não informada' AFTER fonte_dado,
    ADD CONSTRAINT chk_lanc_fonte CHECK (fonte_dado IN ('ENTREVISTA','QUESTIONARIO','FONTE_SECUNDARIA'));

ALTER TABLE lancamento_mensal ALTER COLUMN fonte_dado DROP DEFAULT;
