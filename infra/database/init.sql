CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    lgpd_aceite_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dispositivos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    username_mqtt VARCHAR(255) UNIQUE NOT NULL,
    token_senha_hash VARCHAR(255) NOT NULL,
    status_ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE regras_acl (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispositivo_id UUID NOT NULL REFERENCES dispositivos(id) ON DELETE CASCADE,
    topico VARCHAR(255) NOT NULL,
    permissao_rw INTEGER NOT NULL CHECK (permissao_rw IN (1,2,4)) 
);

CREATE INDEX idx_dispositivos_username ON dispositivos(username_mqtt);
CREATE INDEX idx_dispositivos_regras_acl_dispositivo ON regras_acl(dispositivo_id);

CREATE TABLE leituras (
    id             BIGSERIAL PRIMARY KEY,
    dispositivo_id UUID NOT NULL REFERENCES dispositivos(id),
    capturado_em   TIMESTAMPTZ NOT NULL,
    recebido_em    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    temperature    FLOAT NOT NULL,
    humidity       FLOAT NOT NULL,
    pm1_cf         INT NOT NULL,
    pm25_cf        INT NOT NULL,
    pm10_cf        INT NOT NULL,
    pm1_atm        INT NOT NULL,
    pm25_atm       INT NOT NULL,
    pm10_atm       INT NOT NULL
);

CREATE INDEX idx_leituras_dispositivo_tempo ON leituras(dispositivo_id, capturado_em DESC);