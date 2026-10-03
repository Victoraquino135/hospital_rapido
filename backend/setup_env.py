"""Prepara configuração local sem imprimir segredos nem sobrescrever valores."""
from pathlib import Path
import secrets

root = Path(__file__).resolve().parent
path = root / '.env'
if not path.exists():
    content = (root / '.env.example').read_text(encoding='utf-8')
    content = content.replace('JWT_SECRET_KEY=\n', 'JWT_SECRET_KEY=' + secrets.token_urlsafe(48) + '\n')
    with path.open('x', encoding='utf-8') as stream:
        stream.write(content)
    print('Configuração local criada. Preencha somente as opções SMTP para habilitar o Gmail.')
else:
    original = path.read_text(encoding='utf-8')
    lines = original.splitlines()
    values = {}
    for line in lines:
        if '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            values[key.strip()] = value.strip()
    defaults = {
        'SMTP_ENABLED': 'true',
        'SMTP_USE_TLS': 'true',
        'SMTP_PASSWORD': values.get('SMTP_APP_PASSWORD', ''),
        'SMTP_FROM': values.get('SMTP_USER', ''),
        'SEED_FUTURE_SCHEDULE': 'true',
    }
    missing = [f'{key}={value}' for key, value in defaults.items() if key not in values]
    if missing:
        with path.open('a', encoding='utf-8') as stream:
            stream.write(('\n' if original and not original.endswith('\n') else '') + '\n'.join(missing) + '\n')
        print('Configuração existente preservada e variáveis ausentes adicionadas.')
    else:
        print('A configuração existente foi preservada.')
