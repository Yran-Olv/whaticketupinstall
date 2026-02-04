# ⚙️ Configurações Opcionais Durante Instalação

Durante a instalação, o sistema oferece opções para configurar recursos opcionais:

## 📧 Email SMTP (OBRIGATÓRIO)

### Por que é obrigatório?
- Necessário para recuperação de senha
- Necessário para notificações por email
- Necessário para envio de relatórios

### Durante a Instalação

Quando solicitado, você pode:
- **Configurar agora (recomendado)**: Informe os dados do seu servidor SMTP
- **Pular**: Configure manualmente depois em `/home/deploy/<instancia>/backend/.env`

### Dados Necessários

- **Servidor SMTP**: Ex: `smtp.gmail.com`, `smtp.hostinger.com`
- **Porta**: 
  - `465` para SSL
  - `587` para TLS
- **Email de envio**: Seu email
- **Senha**: Senha do email ou senha de aplicativo
- **Remetente**: Ex: `Whaticket <noreply@dominio.com>`

### Exemplos de Provedores

#### Gmail
```
Servidor: smtp.gmail.com
Porta: 465 (SSL) ou 587 (TLS)
Email: seu-email@gmail.com
Senha: Senha de aplicativo (não a senha normal)
```

#### Hostinger
```
Servidor: smtp.hostinger.com
Porta: 465
Email: seu-email@seudominio.com
Senha: Sua senha
```

#### SendGrid
```
Servidor: smtp.sendgrid.net
Porta: 587
Email: apikey
Senha: Sua API Key do SendGrid
```

### Configuração Manual (se pular)

Edite `/home/deploy/<instancia>/backend/.env`:
```env
MAIL_HOST="smtp.seu-provedor.com"
MAIL_PORT="465"
MAIL_USER="seu-email@dominio.com"
MAIL_PASS="sua-senha"
MAIL_FROM="Nome <email@dominio.com>"
```

Depois reinicie: `pm2 restart <instancia>-backend`

---

## 🔔 Notificações Push (OPCIONAL)

### Por que configurar?
- Receber notificações mesmo com navegador fechado
- Melhor experiência do usuário
- Alertas em tempo real

### Durante a Instalação

Quando solicitado:
- **Configurar**: Informe o email para VAPID Subject
- **Pular**: Pode configurar depois

### Email VAPID Subject

Formato: `mailto:admin@dominio.com` ou apenas `admin@dominio.com`

O sistema adiciona `mailto:` automaticamente se você não incluir.

### Geração Automática de Chaves

Se o script `scripts/generate-vapid-keys.js` existir no projeto, as chaves serão geradas automaticamente.

### Configuração Manual (se necessário)

```bash
cd /home/deploy/<instancia>/backend
node scripts/generate-vapid-keys.js
```

Adicione as chaves no `.env`:
```env
VAPID_PUBLIC_KEY=sua-chave-publica
VAPID_PRIVATE_KEY=sua-chave-privada
VAPID_SUBJECT=mailto:admin@dominio.com
```

Reinicie: `pm2 restart <instancia>-backend`

---

## 💾 Armazenamento S3 (OPCIONAL)

### Por que usar S3?
- Escalabilidade
- Redundância
- CDN integrado
- Backup automático

### Durante a Instalação

Escolha:
- **[1] Local**: Arquivos ficam no servidor (padrão)
- **[2] S3**: Arquivos na nuvem AWS

### Configuração S3

Se escolher S3, informe:

- **AWS Access Key ID**: Sua chave de acesso AWS
- **AWS Secret Access Key**: Sua chave secreta AWS
- **AWS Region**: Região do bucket (ex: `us-east-1`, `sa-east-1`)
- **AWS Bucket Name**: Nome do bucket S3

### Pré-requisitos S3

1. Conta AWS ativa
2. Bucket S3 criado
3. IAM user com permissões:
   - `s3:PutObject`
   - `s3:GetObject`
   - `s3:DeleteObject`
   - `s3:ListBucket`

### Configuração Manual (se necessário)

Edite `/home/deploy/<instancia>/backend/.env`:
```env
STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=sua-access-key
AWS_SECRET_ACCESS_KEY=sua-secret-key
AWS_REGION=us-east-1
AWS_BUCKET_NAME=seu-bucket
```

Reinicie: `pm2 restart <instancia>-backend`

---

## 📋 Resumo das Opções

| Configuração | Obrigatória | Quando Configurar |
|--------------|-------------|-------------------|
| Email SMTP | ✅ Sim | Durante instalação (recomendado) |
| Push Notifications | ❌ Não | Durante instalação ou depois |
| Storage S3 | ❌ Não | Durante instalação ou depois |

---

## ⚠️ Avisos Importantes

### Email SMTP
- **NUNCA pule** se precisar de recuperação de senha
- Configure antes de colocar em produção
- Teste o envio após configurar

### Push Notifications
- Funciona melhor com HTTPS (configurado automaticamente)
- Requer permissão do navegador
- Chaves VAPID são específicas por domínio

### Storage S3
- Custos adicionais da AWS
- Configure CORS no bucket se necessário
- Teste upload/download após configurar

---

## 🔧 Verificar Configurações Após Instalação

```bash
# Verificar Email
grep MAIL_ /home/deploy/<instancia>/backend/.env

# Verificar Push Notifications
grep VAPID_ /home/deploy/<instancia>/backend/.env

# Verificar Storage
grep STORAGE_TYPE /home/deploy/<instancia>/backend/.env
grep AWS_ /home/deploy/<instancia>/backend/.env
```

---

**Última atualização:** 31/12/2025
