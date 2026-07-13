# Tutorial — Subindo o servidor Observatório do Ar para testes

Este tutorial cobre como iniciar a stack completa localmente, verificar cada serviço e simular um dispositivo ESP32 publicando telemetria.

---

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) com o plugin Compose (versão `docker compose`, não `docker-compose`)
- Cliente MQTT para simular o ESP32. Instale um dos dois:
  - **mosquitto-clients** (recomendado): `sudo apt install mosquitto-clients`
  - **Python + paho-mqtt**: `pip install paho-mqtt` (alternativa via script)

Verifique as instalações:

```bash
docker compose version
mosquitto_pub --version
```

---

## Visão geral da stack

```
┌─────────────────────────────────────────────────────┐
│                   observatorio_net                  │
│                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐  │
│  │    db    │◄───│   api    │◄───│  mosquitto   │  │
│  │ :5432    │    │  :8000   │    │   :1883      │  │
│  └──────────┘    └──────────┘    └──────┬───────┘  │
│       ▲                                 │           │
│       │                        publish  │           │
│  ┌────┴─────┐                           │           │
│  │subscriber│◄──────────────────────────┘           │
│  └──────────┘   subscribe sensores/telemetria/#     │
└─────────────────────────────────────────────────────┘
         ▲ porta exposta no host
         └─ 5432 (banco), 1883 (broker), 8000 (api)
```

Serviços:
| Serviço      | Imagem / Build        | Função                                      |
|--------------|-----------------------|---------------------------------------------|
| `db`         | `postgres:15-alpine`  | Banco de dados PostgreSQL                   |
| `api`        | `./api`               | Auth e ACL MQTT via HTTP                    |
| `mosquitto`  | `iegomez/mosquitto-go-auth` | Broker MQTT sem conexão anônima       |
| `subscriber` | `./subscriber`        | Consome telemetria e persiste em `leituras` |

---

## 1. Configurando as variáveis de ambiente

A stack lê credenciais de `infra/.env`. Copie o exemplo e preencha os valores:

```bash
cd infra/
cp .env.example .env
```

Edite `infra/.env` com as credenciais desejadas. Para desenvolvimento local, os valores padrão do `.env.example` já funcionam com o seed de teste — basta renomeá-los e descomentar.

> **Importante:** o arquivo `.env` nunca deve ser commitado. Ele já está no `.gitignore`.
>
> O valor de `MQTT_SUBSCRIBER_PASSWORD` definido aqui é o mesmo que será gravado no banco durante a inicialização — o seed lê a variável diretamente. Se você alterar este valor depois que a stack já subiu, será necessário recriar o volume (`docker compose down -v`) para o seed rodar novamente com a senha nova.

---

## 2. Subindo a stack

```bash
cd infra/
docker compose up -d --build
```

A flag `--build` garante que as imagens da API e do subscriber sejam (re)construídas. Nas execuções seguintes sem alteração de código, pode omiti-la:

```bash
docker compose up -d
```

Aguarde alguns segundos e verifique se todos os contêineres estão `running`:

```bash
docker compose ps
```

Saída esperada:

```
NAME                     STATUS
observatorio_db          running
observatorio_api         running
observatorio_broker      running
observatorio_subscriber  running
```

---

## 3. Verificando cada serviço

### Banco de dados

```bash
docker exec -it observatorio_db psql -U admin_ufpa -d observatorio -c "\dt"
```

Saída esperada — as quatro tabelas devem aparecer:

```
         List of relations
 Schema |    Name     | Type  |   Owner
--------+-------------+-------+-----------
 public | dispositivos| table | admin_ufpa
 public | leituras    | table | admin_ufpa
 public | regras_acl  | table | admin_ufpa
 public | usuarios    | table | admin_ufpa
```

Confira que o seed foi aplicado (dispositivo de teste e subscriber cadastrados):

```bash
docker exec -it observatorio_db psql -U admin_ufpa -d observatorio \
  -c "SELECT username_mqtt FROM dispositivos;"
```

Saída esperada:

```
   username_mqtt
-----------------
 esp32_teste_01
 sistema_ingestao
```

### API de autenticação

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:8000/api/mqtt/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "esp32_teste_01", "password": "token_123"}'
```

Saída esperada: `200`

Teste com credenciais inválidas (deve retornar `401`):

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:8000/api/mqtt/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "esp32_teste_01", "password": "senha_errada"}'
```

### Subscriber

```bash
docker compose logs subscriber
```

Saída esperada:

```
... INFO Banco conectado.
... INFO Broker conectado.
```

---

## 4. Simulando um dispositivo ESP32

O dispositivo de teste está pré-cadastrado no seed com as seguintes credenciais:

| Campo          | Valor                          |
|----------------|--------------------------------|
| `username_mqtt`| `esp32_teste_01`               |
| `token`        | `token_123`                    |
| Tópico         | `sensores/telemetria/esp32_teste_01` |

### Publicando uma leitura com mosquitto_pub

```bash
mosquitto_pub \
  -h localhost -p 1883 \
  -u esp32_teste_01 -P token_123 \
  -t "sensores/telemetria/esp32_teste_01" \
  -m '{"capturado_em":"2026-06-26T10:30:00Z","temperature":28.5,"humidity":72.1,"pm1_cf":12,"pm25_cf":18,"pm10_cf":24,"pm1_atm":11,"pm25_atm":17,"pm10_atm":23}'
```

### Alternativa: script Python

```python
import paho.mqtt.client as mqtt
import json

payload = {
    "capturado_em": "2026-06-26T10:30:00Z",
    "temperature": 28.5,
    "humidity": 72.1,
    "pm1_cf": 12, "pm25_cf": 18, "pm10_cf": 24,
    "pm1_atm": 11, "pm25_atm": 17, "pm10_atm": 23,
}

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.username_pw_set("esp32_teste_01", "token_123")
client.connect("localhost", 1883)
client.publish("sensores/telemetria/esp32_teste_01", json.dumps(payload))
client.disconnect()
```

---

## 5. Verificando a ingestão

Após publicar, o subscriber deve logar a leitura:

```bash
docker compose logs subscriber
```

Saída esperada:

```
... INFO Leitura persistida: esp32_teste_01 @ 2026-06-26T10:30:00Z
```

Confirme no banco:

```bash
docker exec -it observatorio_db psql -U admin_ufpa -d observatorio \
  -c "SELECT capturado_em, recebido_em, temperature, humidity, pm25_cf FROM leituras ORDER BY recebido_em DESC LIMIT 5;"
```

Saída esperada:

```
       capturado_em        |         recebido_em          | temperature | humidity | pm25_cf
---------------------------+------------------------------+-------------+----------+---------
 2026-06-26 10:30:00+00    | 2026-06-26 13:45:01.234+00   |        28.5 |     72.1 |      18
```

A diferença entre `recebido_em` e `capturado_em` indica a latência de entrega (ou o tempo que o dispositivo ficou offline).

---

## 6. Testando rejeição de acesso

O broker não aceita conexões anônimas nem publicações em tópicos não autorizados.

**Conexão sem credenciais (deve falhar):**

```bash
mosquitto_pub -h localhost -p 1883 \
  -t "sensores/telemetria/esp32_teste_01" \
  -m "teste" 2>&1
```

Saída esperada: `Connection error: Connection Refused: not authorised.`

**Publicação em tópico alheio (rejeição silenciosa no cliente):**

```bash
mosquitto_pub \
  -h localhost -p 1883 \
  -u esp32_teste_01 -P token_123 \
  -t "sensores/telemetria/outro_dispositivo" \
  -m "teste"
```

Em MQTT 3.1.1 com QoS 0, o broker descarta a mensagem sem notificar o cliente — o comando termina com exit 0 e sem output. A rejeição é visível na API (`401` no log) e confirmável pelo banco: nenhuma linha nova deve aparecer em `leituras`.

```bash
# Confirma que a mensagem não foi gravada
docker exec -it observatorio_db psql -U admin_ufpa -d observatorio \
  -c "SELECT COUNT(*) FROM leituras;"
```

O contador deve permanecer o mesmo de antes da tentativa.

---

## 7. Acompanhando os logs em tempo real

Para depurar o fluxo completo durante os testes, abra dois terminais:

**Terminal 1 — subscriber:**
```bash
cd infra && docker compose logs -f subscriber
```

**Terminal 2 — broker (requer acesso ao log do mosquitto):**
```bash
cd infra && docker compose logs -f mosquitto
```

---

## 8. Parando a stack

```bash
cd infra && docker compose down
```

Os dados do banco são persistidos no volume `db_data`. Para destruir os dados também (útil para reiniciar do zero):

```bash
docker compose down -v
```

> **Atenção:** `down -v` apaga o volume do banco. Use somente quando quiser resetar o estado completo da stack (ex: após alterar `init.sql` ou `seed.sql`).

---

## Referência rápida de credenciais de teste

| Entidade          | username_mqtt      | senha/token            |
|-------------------|--------------------|------------------------|
| ESP32 de teste    | `esp32_teste_01`   | `token_123`            |
| Subscriber        | `sistema_ingestao` | `ingestao_token_123`   |
| Usuário admin     | —                  | `senha123` (banco)     |
| PostgreSQL        | `admin_ufpa`       | `observatorio_laai`    |
