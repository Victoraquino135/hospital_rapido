"""Prepara configuração local sem imprimir segredos nem sobrescrever valores."""
from pathlib import Path
import secrets
import sys
from dotenv import dotenv_values

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

# A checagem abaixo informa apenas nomes de campos e modo de transporte.
# Valores do .env nunca são impressos.
values = {key: (value or '').strip() for key, value in dotenv_values(path).items()}
required = ('SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASSWORD', 'SMTP_FROM')
placeholders = ('COLOQUE', 'COLOCAR', 'PREENCHER', '_AQUI')
invalid = [
    key for key in required
    if not values.get(key)
    or any(marker in values[key].upper() for marker in placeholders)
]
smtp_error = False
if invalid:
    smtp_error = True
    print(
        'AVISO SMTP: preencha valores reais em backend/.env para: '
        + ', '.join(invalid)
        + '. Nenhum valor foi exibido.'
    )
else:
    port = values.get('SMTP_PORT')
    tls_enabled = values.get('SMTP_USE_TLS', 'true').lower() == 'true'
    if port == '587' and tls_enabled:
        print('SMTP: configuração local completa; transporte STARTTLS na porta 587.')
    elif port == '465' and tls_enabled:
        print('SMTP: configuração local completa; transporte SSL na porta 465.')
    elif port not in {'465', '587'}:
        smtp_error = True
        print('AVISO SMTP: SMTP_PORT deve ser 587 (STARTTLS) ou 465 (SSL).')
    else:
        smtp_error = True
        print('AVISO SMTP: SMTP_USE_TLS deve permanecer true para envio seguro.')

if smtp_error and '--require-smtp' in sys.argv:
    print(
        'ERRO SMTP: corrija somente os campos indicados em backend/.env '
        'e execute INICIAR_TUDO.bat novamente.'
    )
    raise SystemExit(2)
