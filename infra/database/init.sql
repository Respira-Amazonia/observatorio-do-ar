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