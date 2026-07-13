#!/bin/bash
# =============================================================
# Seed de desenvolvimento local.
# A senha do subscriber é lida de MQTT_SUBSCRIBER_PASSWORD,
# que deve corresponder ao valor em infra/.env.
# As demais credenciais (token_123, senha123) são fixas e
# públicas por design — apenas para testes locais.
# Para produção, substitua este script por um dedicado.
# =============================================================
set -e

: "${MQTT_SUBSCRIBER_PASSWORD:?Variável MQTT_SUBSCRIBER_PASSWORD não definida. Configure infra/.env antes de subir a stack.}"

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname "$POSTGRES_DB" \
     -v subscriber_password="$MQTT_SUBSCRIBER_PASSWORD" \
<<'SQL'

WITH novo_usuario AS (
    INSERT INTO usuarios (email, senha_hash)
    VALUES (
        'admin_teste@ufpa.br',
        crypt('senha123', gen_salt('bf'))
    )
    RETURNING id
),

novo_dispositivo AS (
    INSERT INTO dispositivos (usuario_id, username_mqtt, token_senha_hash)
    SELECT id, 'esp32_teste_01', crypt('token_123', gen_salt('bf'))
    FROM novo_usuario
    RETURNING id
),

sistema_ingestao AS (
    INSERT INTO dispositivos (usuario_id, username_mqtt, token_senha_hash)
    SELECT id, 'sistema_ingestao', crypt(:'subscriber_password', gen_salt('bf'))
    FROM novo_usuario
    RETURNING id
),

acl_dispositivo AS (
    INSERT INTO regras_acl (dispositivo_id, topico, permissao_rw)
    SELECT id, 'sensores/telemetria/%u', 2
    FROM novo_dispositivo
)

-- acc=4 (MOSQ_ACL_SUBSCRIBE): verificado na chamada de subscribe()
-- acc=1 (MOSQ_ACL_READ):      verificado na entrega de cada mensagem
INSERT INTO regras_acl (dispositivo_id, topico, permissao_rw)
SELECT id, 'sensores/telemetria/#', 4 FROM sistema_ingestao
UNION ALL
SELECT id, 'sensores/telemetria/#', 1 FROM sistema_ingestao;

SQL
