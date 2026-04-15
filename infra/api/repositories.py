from asyncpg import Pool

class AuthRepository:
    def __init__(self, pool: Pool):
        self.pool = pool
    
    async def validate_credentials(self, username: str, password: str):
        query = """
            SELECT id
            FROM dispositivos
            WHERE username_mqtt = $1
            AND token_senha_hash = crypt($2, token_senha_hash)
            AND status_ativo = TRUE
        """

        async with self.pool.acquire() as connection:
            return await connection.fetchval(query, username, password)
        
class ACLRepository:
    def __init__(self, pool: Pool):
        self.pool = pool

    async def validate_permission(self, username: str, topic: str, acl: int):
        query = """
            SELECT r.id
            FROM regras_acl r
            INNER JOIN dispositivos d ON r.dispositivo_id = d.id
            WHERE d.username_mqtt = $1
              AND r.topico = $2
              AND r.permissao_rw = $3
              AND d.status_ativo = TRUE
        """

        async with self.pool.acquire() as connection:
            return await connection.fetchval(query, username, topic, acl)


