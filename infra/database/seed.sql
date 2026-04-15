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
    SELECT 
        id,
        'esp32_teste_01',
        crypt('token_123', gen_salt('bf'))
    FROM novo_usuario
    RETURNING id
)

INSERT INTO regras_acl (dispositivo_id, topico, permissao_rw)
SELECT 
    id, 
    'sensores/telemetria', 
    2
FROM novo_dispositivo;