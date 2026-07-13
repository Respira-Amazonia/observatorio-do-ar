import json
import logging
import os
import time

import psycopg2
import paho.mqtt.client as mqtt

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger(__name__)

DB_DSN = {
    "host":     os.environ["DB_HOST"],
    "port":     int(os.environ.get("DB_PORT", 5432)),
    "dbname":   os.environ["DB_NAME"],
    "user":     os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
}

BROKER_HOST   = os.environ.get("BROKER_HOST", "observatorio_broker")
BROKER_PORT   = int(os.environ.get("BROKER_PORT", 1883))
MQTT_USERNAME = os.environ["MQTT_USERNAME"]
MQTT_PASSWORD = os.environ["MQTT_PASSWORD"]

TOPIC_PREFIX    = "sensores/telemetria/"
REQUIRED_FIELDS = {
    "capturado_em", "temperature", "humidity",
    "pm1_cf", "pm25_cf", "pm10_cf",
    "pm1_atm", "pm25_atm", "pm10_atm",
}

_db: psycopg2.extensions.connection = None


def connect_db() -> psycopg2.extensions.connection:
    for attempt in range(10):
        try:
            conn = psycopg2.connect(**DB_DSN)
            log.info("Banco conectado.")
            return conn
        except psycopg2.OperationalError as e:
            log.warning("Banco indisponível (%d/10): %s", attempt + 1, e)
            time.sleep(3)
    raise RuntimeError("Não foi possível conectar ao banco de dados.")


def get_dispositivo_id(conn, username_mqtt: str):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id FROM dispositivos WHERE username_mqtt = %s AND status_ativo = TRUE",
            (username_mqtt,),
        )
        row = cur.fetchone()
    return row[0] if row else None


def insert_leitura(conn, dispositivo_id, data: dict) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO leituras
                (dispositivo_id, capturado_em,
                 temperature, humidity,
                 pm1_cf, pm25_cf, pm10_cf,
                 pm1_atm, pm25_atm, pm10_atm)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                dispositivo_id,
                data["capturado_em"],
                data["temperature"],
                data["humidity"],
                data["pm1_cf"],
                data["pm25_cf"],
                data["pm10_cf"],
                data["pm1_atm"],
                data["pm25_atm"],
                data["pm10_atm"],
            ),
        )
    conn.commit()


def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code == 0:
        log.info("Broker conectado.")
        client.subscribe(f"{TOPIC_PREFIX}#")
    else:
        log.error("Falha ao conectar ao broker: %s", reason_code)


def on_message(client, userdata, msg):
    global _db
    topic = msg.topic

    if not topic.startswith(TOPIC_PREFIX):
        return

    username_mqtt = topic[len(TOPIC_PREFIX):]

    try:
        data = json.loads(msg.payload)
    except json.JSONDecodeError:
        log.warning("Payload não é JSON válido no tópico %s", topic)
        return

    missing = REQUIRED_FIELDS - data.keys()
    if missing:
        log.warning("Campos ausentes no tópico %s: %s", topic, missing)
        return

    try:
        dispositivo_id = get_dispositivo_id(_db, username_mqtt)
        if not dispositivo_id:
            log.warning("Dispositivo inativo ou não cadastrado: %s", username_mqtt)
            return

        insert_leitura(_db, dispositivo_id, data)
        log.info("Leitura persistida: %s @ %s", username_mqtt, data["capturado_em"])

    except psycopg2.Error as e:
        log.error("Erro de banco ao processar %s: %s", topic, e)
        try:
            _db.rollback()
        except Exception:
            pass
        try:
            _db = connect_db()
        except RuntimeError:
            log.critical("Não foi possível reconectar ao banco.")


def main():
    global _db
    _db = connect_db()

    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_message = on_message

    for attempt in range(10):
        try:
            client.connect(BROKER_HOST, BROKER_PORT, keepalive=60)
            break
        except Exception as e:
            log.warning("Broker indisponível (%d/10): %s", attempt + 1, e)
            time.sleep(3)
    else:
        raise RuntimeError("Não foi possível conectar ao broker MQTT.")

    client.loop_forever()


if __name__ == "__main__":
    main()
