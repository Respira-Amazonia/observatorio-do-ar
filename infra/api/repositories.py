from asyncpg import Pool


def _mqtt_topic_matches(pattern: str, topic: str) -> bool:
    """
    Verifica se um tópico MQTT concreto corresponde a um filtro de subscription.
    Suporta os wildcards '#' (multi-nível) e '+' (nível único).
    Necessário porque o broker faz dois checks distintos:
      acc=4 (subscribe): topic = filtro literal, ex: sensores/telemetria/#
      acc=1 (read/delivery): topic = tópico concreto, ex: sensores/telemetria/esp32_01
    A comparação SQL direta falharia no segundo caso.
    """
    if pattern == topic:
        return True
    return _match_parts(pattern.split('/'), topic.split('/'))


def _match_parts(pp: list, tp: list) -> bool:
    if not pp:
        return not tp
    if pp[0] == '#':
        return True
    if not tp:
        return False
    if pp[0] == '+' or pp[0] == tp[0]:
        return _match_parts(pp[1:], tp[1:])
    return False


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
            SELECT replace(r.topico, '%u', $1) AS topico_resolvido
            FROM regras_acl r
            INNER JOIN dispositivos d ON r.dispositivo_id = d.id
            WHERE d.username_mqtt = $1
              AND r.permissao_rw = $2
              AND d.status_ativo = TRUE
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, username, acl)

        for row in rows:
            if _mqtt_topic_matches(row['topico_resolvido'], topic):
                return row['topico_resolvido']
        return None
