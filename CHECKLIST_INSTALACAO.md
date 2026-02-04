# ✅ Checklist de Instalação - Whaticket Gold

## Pré-Instalação

### Requisitos do Servidor
- [ ] Ubuntu 20.04+ ou Debian 11+
- [ ] Mínimo 2GB RAM (recomendado 4GB+)
- [ ] Mínimo 15GB espaço em disco
- [ ] Acesso root/sudo
- [ ] Conexão com internet

### Configurações DNS
- [ ] Domínio frontend configurado e apontando para o IP do servidor
- [ ] Domínio backend configurado e apontando para o IP do servidor
- [ ] Tempo de propagação DNS respeitado (pode levar até 48h)

### Preparação
- [ ] Portas escolhidas e disponíveis:
  - [ ] Frontend: 3000-3999
  - [ ] Backend: 4000-4999
  - [ ] Redis: 5000-5999
- [ ] Nome da instância definido (apenas letras minúsculas, números e hífens)
- [ ] Link do repositório Git preparado
- [ ] Senha para deploy e banco de dados definida (sem caracteres especiais)

## Durante a Instalação

### Instalação Primária (Primeira Vez)
```bash
cd /caminho/para/whaticketupinstall
chmod +x install_primaria install_instancia
sudo ./install_primaria
```

**O instalador irá:**
1. ✅ Validar pré-requisitos automaticamente
2. ✅ Instalar Node.js 20.x
3. ✅ Instalar FFmpeg
4. ✅ Instalar PostgreSQL
5. ✅ Instalar Docker e Redis
6. ✅ Instalar Nginx e Certbot
7. ✅ Configurar firewall UFW
8. ✅ Configurar Fail2ban
9. ✅ Configurar atualizações automáticas
10. ✅ Criar usuário deploy
11. ✅ Clonar repositório Git
12. ✅ Configurar variáveis de ambiente
13. ✅ Instalar dependências
14. ✅ Compilar código
15. ✅ Executar migrations
16. ✅ Executar seeds
17. ✅ Iniciar serviços PM2
18. ✅ Configurar Nginx
19. ✅ Configurar SSL (Let's Encrypt)
20. ✅ Configurar backups automáticos
21. ✅ Configurar monitoramento
22. ✅ Verificar saúde do sistema

### Instalação de Nova Instância
```bash
sudo ./install_instancia
```

## Pós-Instalação

### Verificações Obrigatórias

#### 1. Verificar Serviços PM2
```bash
su - deploy
pm2 list
pm2 logs
```
- [ ] Backend está online
- [ ] Frontend está online
- [ ] Sem erros nos logs

#### 2. Verificar Redis
```bash
sudo docker ps | grep redis
```
- [ ] Container Redis está rodando

#### 3. Verificar PostgreSQL
```bash
sudo su - postgres
psql -l
```
- [ ] Banco de dados criado
- [ ] Usuário criado

#### 4. Verificar Nginx
```bash
sudo systemctl status nginx
sudo nginx -t
```
- [ ] Nginx está rodando
- [ ] Configuração válida

#### 5. Verificar SSL
```bash
sudo certbot certificates
```
- [ ] Certificados SSL configurados
- [ ] Sem avisos de expiração

#### 6. Verificar Firewall
```bash
sudo ufw status
```
- [ ] Firewall ativo
- [ ] Portas corretas abertas

#### 7. Testar Acesso
- [ ] Frontend acessível via HTTPS
- [ ] Backend API respondendo
- [ ] Login funcionando
- [ ] Conexão WhatsApp funcionando

### Configurações Manuais Necessárias

#### 1. Email SMTP (Obrigatório para recuperação de senha)
Edite `/home/deploy/<instancia>/backend/.env`:
```env
MAIL_HOST="smtp.seu-provedor.com"
MAIL_USER="seu-email@dominio.com"
MAIL_PASS="sua-senha"
MAIL_FROM="Nome <email@dominio.com>"
MAIL_PORT="465"
```
Depois reinicie: `pm2 restart <instancia>-backend`

#### 2. Push Notifications (Opcional)
Se o script de geração de VAPID keys não existir:
```bash
cd /home/deploy/<instancia>/backend
node scripts/generate-vapid-keys.js
```
Adicione as chaves no `.env` e reinicie o backend.

#### 3. Storage S3 (Opcional)
Se quiser usar S3 em vez de armazenamento local:
```env
STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=sua-key
AWS_SECRET_ACCESS_KEY=sua-secret
AWS_REGION=us-east-1
AWS_BUCKET_NAME=seu-bucket
```

## Troubleshooting

### Problemas Comuns

#### Backend não inicia
```bash
# Verificar logs
pm2 logs <instancia>-backend

# Verificar variáveis de ambiente
cat /home/deploy/<instancia>/backend/.env

# Verificar se porta está em uso
sudo lsof -i :<porta>
```

#### Frontend não carrega
```bash
# Verificar se build foi criado
ls -la /home/deploy/<instancia>/frontend/build

# Verificar PM2
pm2 list

# Verificar Nginx
sudo tail -f /var/log/nginx/error.log
```

#### Banco de dados não conecta
```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Testar conexão
sudo -u postgres psql -d <instancia> -U <instancia>

# Verificar .env
grep DB_ /home/deploy/<instancia>/backend/.env
```

#### SSL não funciona
```bash
# Verificar certificados
sudo certbot certificates

# Verificar DNS
dig <dominio>

# Verificar Nginx
sudo nginx -t
sudo systemctl reload nginx
```

## Manutenção

### Atualizar Instância
```bash
sudo ./install_instancia
# Escolha opção [1] Atualizar Sistema
```

### Backup Manual
```bash
sudo /usr/local/bin/backup-<instancia>.sh
```

### Verificar Saúde
```bash
# O script de monitoramento verifica automaticamente a cada 5 minutos
# Para verificar manualmente:
pm2 list
sudo docker ps
sudo systemctl status postgresql nginx
```

### Logs
```bash
# PM2
pm2 logs

# Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log

# Backup
sudo tail -f /var/log/whaticket-backup.log
```

## Segurança

### Checklist de Segurança
- [ ] Firewall UFW configurado e ativo
- [ ] Fail2ban instalado e funcionando
- [ ] Atualizações automáticas habilitadas
- [ ] Senhas fortes configuradas
- [ ] SSL/TLS configurado (HTTPS)
- [ ] Arquivo `config` com permissões 700
- [ ] Usuário deploy não tem acesso root
- [ ] Backups automáticos configurados

### Recomendações Adicionais
- [ ] Configure fail2ban para proteger outros serviços
- [ ] Configure log rotation para todos os serviços
- [ ] Configure monitoramento externo (opcional)
- [ ] Configure alertas por email (opcional)
- [ ] Faça backups regulares e teste restauração

## Suporte

Em caso de problemas:
1. Verifique os logs
2. Execute o health check: `health_check <instancia>`
3. Consulte a documentação em `docs/DOCUMENTACAO.md`
4. Verifique o arquivo `MELHORIAS.md` para melhorias implementadas
