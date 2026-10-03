"""Configuração exclusiva do servidor; nenhum segredo tem valor padrão."""
import os
from pathlib import Path
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / '.env')
SECRET = os.getenv('JWT_SECRET_KEY', '')
ALGORITHM = 'HS256'
ORIGINS = [x.strip() for x in os.getenv('ALLOWED_ORIGINS', 'http://localhost:8080,http://127.0.0.1:8080').split(',') if x.strip()]

def check_config():
    if len(SECRET) < 32 or SECRET.startswith('troque'):
        raise RuntimeError('Configure JWT_SECRET_KEY com uma chave aleatória de pelo menos 32 caracteres no backend/.env.')
