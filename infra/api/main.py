from fastapi import FastAPI, HTTPException, status, Request, Response
from pydantic import BaseModel
from pydantic_settings import BaseSettings, SettingsConfigDict
from contextlib import asynccontextmanager
from repositories import ACLRepository, AuthRepository
import asyncpg
import asyncio

class Settings(BaseSettings):
    db_user: str
    db_password: str
    db_name: str
    db_host: str
    db_port: int = 5432

    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    tentativas_maximas = 5
    intervalo_segundos = 3
    
    for tentativa in range(tentativas_maximas):
        try:
            app.state.db_pool = await asyncpg.create_pool(
                user=settings.db_user,
                password=settings.db_password,
                database=settings.db_name,
                host=settings.db_host,
                port=settings.db_port,
                min_size=10,
                max_size=20
            )
            print("Conexao com o banco de dados estabelecida.")
            break
        except Exception as e:
            print(f"Falha de I/O TCP. Retentando em {intervalo_segundos}s... ({tentativa + 1}/{tentativas_maximas})")
            if tentativa == tentativas_maximas - 1:
                raise Exception("Tempo limite de conexao com PostgreSQL excedido.")
            await asyncio.sleep(intervalo_segundos)
    
    yield

    await app.state.db_pool.close()

class AuthRequest(BaseModel):
    username: str = None
    password: str = None
    clientid: str = None

class ACLRequest(BaseModel):
    username: str = None
    clientid: str = None
    topic: str
    acc: int

app = FastAPI(title="Observatorio do Ar - API MQTT Auth", lifespan= lifespan)

@app.post("/api/mqtt/auth")
async def authenticate_client(req: AuthRequest, request: Request):
    if not req.username or not req.password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    
    repo = AuthRepository(request.app.state.db_pool)

    try:
        dispositivo_id = await repo.validate_credentials(req.username, req.password)
    except Exception as e:
        print(f"Erro de Banco de Dados (Auth): {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)

    if dispositivo_id is not None:
        return Response(status_code=status.HTTP_200_OK)
    else:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)


@app.post("/api/mqtt/acl")
async def check_acl(req: ACLRequest, request: Request):
    if not req.username or not req.topic or not req.acc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    
    repo = ACLRepository(request.app.state.db_pool)

    try:
        regra_id = await repo.validate_permission(req.username, req.topic, req.acc)
    except Exception as e:
        print(f"Erro de Banco de Dados (ACL): {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    if regra_id is not None:
        return Response(status_code=status.HTTP_200_OK)
    else:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)