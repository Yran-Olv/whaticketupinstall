# Melhorias Implementadas no Instalador

## ✅ Correções e Melhorias Aplicadas

### 1. Variáveis de Ambiente Completas

#### Backend (.env)
- ✅ `NODE_ENV=production` (antes estava vazio)
- ✅ `TZ=America/Sao_Paulo` (timezone)
- ✅ `DB_DEBUG=false` (debug do banco)
- ✅ `JWT_EXPIRES_IN` e `JWT_REFRESH_EXPIRES_IN` (expiração de tokens)
- ✅ `REDIS_HOST` e `REDIS_PORT` separados (além de REDIS_URI)
- ✅ `REDIS_PASSWORD` (senha do Redis)
- ✅ `STORAGE_TYPE=local` (tipo de armazenamento)
- ✅ `UPLOAD_FOLDER` (pasta de uploads)
- ✅ `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (notificações push)

#### Frontend (.env)
- ✅ `REACT_APP_API_URL` (URL da API)
- ✅ `REACT_APP_LOCALE=pt-br` (idioma)
- ✅ `REACT_APP_TIMEZONE=America/Sao_Paulo` (timezone)
- ✅ `REACT_APP_TRIALEXPIRATION=7` (expiração de trial)
- ✅ `REACT_APP_ENV_TOKEN` (token de ambiente)
- ✅ Corrigido espaçamento em `REACT_APP_HOURS_CLOSE_TICKETS_AUTO`

### 2. Dependências do Sistema

- ✅ **FFmpeg** - Instalação explícita do FFmpeg do sistema
- ✅ **PostgreSQL contrib** - Pacote adicional instalado
- ✅ Verificação de FFmpeg durante validação

### 3. Configurações de Produção

- ✅ **PM2 com limite de memória** - `--max-memory-restart 8096M` e `--max-old-space-size=8096`
- ✅ **Diretórios de upload** - Criação automática com permissões corretas
- ✅ **PostgreSQL** - Configuração de pg_hba.conf para conexões locais
- ✅ **PM2 save** - Salvamento automático após iniciar processos

### 4. Melhorias de Banco de Dados

- ✅ Criação de banco com verificação de existência
- ✅ Usuário criado com permissões corretas
- ✅ GRANT de privilégios no banco

### 5. Notificações Push

- ✅ Geração automática de chaves VAPID (se script existir)
- ✅ Variáveis VAPID configuradas no .env

### 6. Validações

- ✅ Verificação de espaço em disco aumentada para 15GB (produção)
- ✅ Verificação de FFmpeg durante validação pré-instalação

### 7. Redis

- ✅ Remoção de container existente antes de criar novo
- ✅ Configuração completa de variáveis Redis

## 📋 Checklist de Verificação

Antes de usar em produção, verifique:

- [ ] Domínios configurados no DNS
- [ ] Portas disponíveis (3000-3999 frontend, 4000-4999 backend, 5000-5999 Redis)
- [ ] Espaço em disco suficiente (mínimo 15GB)
- [ ] Acesso SSH configurado
- [ ] Firewall configurado (feito automaticamente)
- [ ] Backups configurados (feito automaticamente)

## 🔧 Configurações Opcionais Pós-Instalação

### Email SMTP
Edite o arquivo `.env` do backend para configurar:
```env
MAIL_HOST="smtp.seu-provedor.com"
MAIL_USER="seu-email@dominio.com"
MAIL_PASS="sua-senha"
MAIL_FROM="Nome <email@dominio.com>"
MAIL_PORT="465"
```

### Push Notifications
Se o script `scripts/generate-vapid-keys.js` não existir, gere manualmente:
```bash
cd backend
node scripts/generate-vapid-keys.js
```
E adicione as chaves no `.env`.

### Storage S3 (Opcional)
Para usar S3 em vez de armazenamento local:
```env
STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=sua-key
AWS_SECRET_ACCESS_KEY=sua-secret
AWS_REGION=us-east-1
AWS_BUCKET_NAME=seu-bucket
```

## 🐛 Problemas Conhecidos e Soluções

### FFmpeg não encontrado
**Solução**: O instalador agora instala FFmpeg automaticamente. Se ainda houver problemas:
```bash
sudo apt-get update
sudo apt-get install -y ffmpeg
```

### Erro ao criar banco PostgreSQL
**Solução**: O instalador agora verifica se o banco existe antes de criar. Se houver problemas:
```bash
sudo -u postgres psql -c "DROP DATABASE IF EXISTS nome_instancia;"
sudo -u postgres psql -c "CREATE DATABASE nome_instancia;"
```

### PM2 não inicia com memória suficiente
**Solução**: O instalador agora configura PM2 com `--max-old-space-size=8096`. Se ainda houver problemas:
```bash
pm2 delete nome-backend
pm2 start dist/server.js --name nome-backend --max-memory-restart 8096M --node-args="--max-old-space-size=8096"
pm2 save
```

## 📝 Notas de Versão

- **v2.1.0**: Adicionadas variáveis de ambiente completas, FFmpeg, configurações de produção
- **v2.0.0**: Validações, segurança, backups, monitoramento
- **v1.0.0**: Versão original
