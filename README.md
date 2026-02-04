## 🚀 Instalação

### Primeira Instalação (Servidor Novo)

1. **Clone ou copie os arquivos para o servidor:**
```bash
cd /caminho/para/whaticketupinstall
```

2. **Torne os scripts executáveis:**
```bash
chmod +x install_primaria install_instancia
```

3. **Execute a instalação primária:**
```bash
sudo ./install_primaria
```

**⚠️ IMPORTANTE:** Antes de executar, certifique-se de que:
- Os domínios estão configurados no DNS apontando para o IP do servidor
- Você tem pelo menos 10GB de espaço em disco disponível
- As portas escolhidas não estão em uso

4. **Durante a instalação, você precisará fornecer:**
   - Senha para usuário deploy e banco de dados (Sem Caracteres Especiais)
   - Link do repositório Git
   - Nome da instância (ex: `empresa1`)
   - Quantidade máxima de conexões WhatsApp
   - Quantidade máxima de usuários/atendentes
   - Domínio do frontend (ex: `app.empresa.com`)
   - Domínio do backend (ex: `api.empresa.com`)
   - Porta do frontend (3000-3999)
   - Porta do backend (4000-4999)
   - Porta do Redis (5000-5999)

### Adicionar Nova Instância

1. **Execute o script de instância:**
```bash
sudo ./install_instancia
```

2. **Siga o mesmo processo de coleta de informações acima**

## 💻 Uso

### Menu Interativo

Ao executar qualquer script, um menu interativo será exibido:

```
[0] ☕ Instalar Sistema
[1] 🔂 Atualizar Sistema
[2] ❌ Deletar Sistema
[3] 🆔 Bloquear Sistema
[4] 🔀 Desbloquear Sistema
[5] 🔓 Alterar domínio Sistema
[6] 💾 Backup Banco Sistema
```

### Comandos Úteis

**Verificar status das instâncias no PM2:**
```bash
su - deploy
pm2 list
pm2 status
pm2 logs
```

**Verificar logs do Nginx:**
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

**Verificar status dos containers Docker (Redis):**
```bash
sudo docker ps
```

**Verificar bancos PostgreSQL:**
```bash
sudo su - postgres
psql -l
```

**Verificar certificados SSL:**
```bash
sudo certbot certificates
```

## 🔧 Gerenciamento de Instâncias

### Atualizar uma Instância

1. Execute `install_instancia` ou `install_primaria`
2. Selecione opção `[1] 🔂 Atualizar Sistema`
3. Informe o nome da instância
4. O sistema irá:
   - Parar os serviços PM2
   - Fazer `git pull`
   - Instalar/atualizar dependências
   - Recompilar o código
   - Executar migrations
   - Executar seeds
   - Reiniciar os serviços

### Deletar uma Instância

1. Execute o script e selecione `[2] ❌ Deletar Sistema`
2. Informe o nome da instância
3. O sistema irá remover:
   - Container Docker Redis
   - Configurações Nginx
   - Banco de dados PostgreSQL
   - Usuário do banco
   - Diretório do projeto
   - Processos PM2

### Bloquear/Desbloquear Instância

- **Bloquear**: Para os serviços backend (PM2 stop)
- **Desbloquear**: Reinicia os serviços backend (PM2 start)

Útil para suspender temporariamente uma instância sem deletar dados.

### Alterar Domínios

1. Selecione opção `[5] 🔓 Alterar domínio Sistema`
2. Informe:
   - Nome da instância
   - Novo domínio frontend
   - Novo domínio backend
   - Portas (mesmas da instalação original)
3. O sistema irá:
   - Atualizar variáveis de ambiente
   - Reconfigurar Nginx
   - Atualizar certificados SSL

## 💾 Backup

### Backup Automatizado

O sistema de backup é configurado **automaticamente** durante a instalação:

1. **Backup Diário Automático** - Executado diariamente às 2:00 AM via cron
2. **Backup de Banco de Dados** - Dump completo do PostgreSQL em formato custom
3. **Backup de Arquivos** - Backup dos arquivos da aplicação
4. **Limpeza Automática** - Remove backups mais antigos que 7 dias
5. **Compressão** - Backups são compactados automaticamente
6. **Logs** - Todas as operações são registradas em `/var/log/whaticket-backup.log`

### Executar Backup Manual

```bash
sudo /usr/local/bin/backup-<nome-instancia>.sh
```

### Restaurar Backup

```bash
# Use a função restore_backup no script
# ou execute manualmente:
sudo -u postgres pg_restore -d <nome-instancia> /backup/<nome-instancia>/db_YYYYMMDD_HHMMSS.dump
```

### Configuração do Backup

Edite o arquivo `lib/_backup.sh` para configurar:

```bash
# Diretório local de backup
PBACKUP="/backup"

# Diretório remoto de backup
RBACKUP="/backup/dumps"

# Usuário e host de destino (SSH)
SDESTINO="dumper@IP_remoto"

# Email para notificações
EMAIL="gerencia@minhaempresa.com.br"

# Dias para manter backups
NDIAS="5"
```

### Executar Backup Manual

1. Execute o script e selecione `[6] 💾 Backup Banco Sistema`
2. Ou execute diretamente:
```bash
source lib/_backup.sh
executar_backup
```

## ⚙️ Configuração

### Variáveis de Ambiente do Backend

O script configura automaticamente um arquivo `.env` no backend com:

```env
NODE_ENV=
BACKEND_URL=https://api.exemplo.com
FRONTEND_URL=https://app.exemplo.com
PROXY_PORT=443
PORT=4000

# Database
DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=nome_instancia
DB_PASS=senha_gerada
DB_NAME=nome_instancia
DB_PORT=5432

# JWT
JWT_SECRET=token_gerado
JWT_REFRESH_SECRET=token_gerado

# Redis
REDIS_URI=redis://:senha@127.0.0.1:5000
REDIS_HOST=127.0.0.1
REDIS_PORT=5000
REDIS_PASSWORD=senha

# Limites
USER_LIMIT=10
CONNECTIONS_LIMIT=5

# Token de Ambiente
ENV_TOKEN=TknAtevus

# Pagamentos (configurar manualmente)
GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=sua-id
GERENCIANET_CLIENT_SECRET=sua_chave_secreta
GERENCIANET_PIX_CERT=nome_do_certificado
GERENCIANET_PIX_KEY=chave_pix_gerencianet
```

### Variáveis de Ambiente do Frontend

O script configura automaticamente um arquivo `.env` no frontend com:

```env
REACT_APP_BACKEND_URL=https://api.exemplo.com
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_TRIALEXPIRATION=7
REACT_APP_ENV_TOKEN=TknAtevus
```

### Arquivo de Configuração (`config`)

Arquivo gerado automaticamente com senhas (permissões 700, root:root):

```bash
deploy_password=senha_do_usuario_deploy
mysql_root_password=senha_banco_dados
db_pass=senha_banco_gerada
```

⚠️ **IMPORTANTE**: Este arquivo contém senhas e não deve ser versionado!

### Personalização de Cores

As cores podem ser personalizadas em `variables/_fonts.sh`:

```bash
RED="\033[1;31m"
GREEN="\033[1;32m"
WHITE="\033[1;37m"
YELLOW="\033[1;33m"
GRAY_LIGHT="\033[0;37m"
CYAN_LIGHT="\033[1;36m"
```

## 🔒 Segurança

O sistema implementa várias medidas de segurança **automaticamente**:

1. **Firewall UFW** - Configurado automaticamente para permitir apenas portas necessárias
2. **Fail2ban** - Instalado e configurado automaticamente para proteção contra ataques de força bruta
3. **SSL/TLS** - Certificados Let's Encrypt via Certbot configurados automaticamente
4. **Atualizações Automáticas** - Sistema de atualizações de segurança configurado
5. **SSH Hardening** - Configurações de segurança SSH aplicadas automaticamente
6. **Isolamento de instâncias** - Cada instância tem seu próprio banco e Redis
7. **Permissões restritas** - Arquivo de configuração com permissões 700
8. **Usuário dedicado** - Aplicação roda como usuário `deploy` (não root)

### Validações Automáticas

O instalador agora realiza validações automáticas antes da instalação:
- ✅ Verificação de espaço em disco (mínimo 10GB)
- ✅ Validação de nomes de instância
- ✅ Verificação de portas disponíveis
- ✅ Validação de URLs e formatos
- ✅ Verificação de resolução DNS (aviso)
- ✅ Verificação de instâncias duplicadas

## 🐛 Troubleshooting

### Verificação de Saúde Automática

Após a instalação, o sistema executa uma verificação automática de saúde que verifica:
- ✅ Status dos processos PM2 (backend e frontend)
- ✅ Status do container Redis
- ✅ Existência do banco de dados PostgreSQL
- ✅ Status do serviço Nginx
- ✅ Configuração de certificados SSL

### Problemas comuns

**Erro de validação pré-instalação:**
- Verifique se as portas escolhidas não estão em uso: `sudo lsof -i :PORTA` ou `sudo netstat -tuln | grep PORTA`
- Verifique se há espaço em disco: `df -h`
- Verifique se os domínios estão configurados no DNS

**Erro ao clonar repositório Git:**
- Verifique se o servidor tem acesso ao repositório
- Verifique credenciais SSH/Git configuradas

**Erro ao instalar dependências npm:**
- Verifique conexão com internet
- Verifique versão do Node.js: `node -v` (deve ser 20.x)
- Limpe cache: `npm cache clean --force`

**Erro ao configurar SSL:**
- Verifique se os domínios apontam para o servidor
- Verifique se porta 80 está aberta no firewall
- Verifique logs: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`

**Erro ao iniciar PM2:**
- Verifique logs: `pm2 logs nome-instancia-backend`
- Verifique variáveis de ambiente no arquivo `.env`
- Verifique se as portas estão disponíveis

**Banco de dados não conecta:**
- Verifique se PostgreSQL está rodando: `sudo systemctl status postgresql`
- Verifique usuário e senha no `.env`
- Verifique se o banco foi criado: `sudo su - postgres -c "psql -l"`

**Firewall bloqueando conexões:**
- Verifique status do UFW: `sudo ufw status`
- Adicione regras se necessário: `sudo ufw allow PORTA/tcp`

**Logs PM2 muito grandes:**
- Os logs são rotacionados automaticamente
- Verifique configuração: `pm2 conf pm2-logrotate`

## 📝 Notas Importantes

1. **Portas**: O script agora verifica automaticamente se as portas estão disponíveis antes da instalação.

2. **Domínios**: Os domínios devem estar configurados no DNS apontando para o IP do servidor antes de executar a instalação. O script verifica e avisa se não estiverem configurados.

3. **Senhas**: Use senhas fortes. O script gera senhas aleatórias para JWT e algumas configurações.

4. **Backups**: Backups automáticos são configurados durante a instalação. Executados diariamente às 2:00 AM.

5. **Segurança**: Firewall, Fail2ban e atualizações automáticas são configurados automaticamente.

6. **Monitoramento**: Scripts de monitoramento são criados automaticamente e verificam a saúde dos serviços a cada 5 minutos.

7. **Logs**: Logs do PM2 são rotacionados automaticamente. Configuração padrão: máximo 10MB por arquivo, retenção de 7 dias.

8. **Múltiplas instâncias**: Cada instância deve usar portas diferentes. O script valida isso automaticamente.

9. **Espaço em Disco**: O script verifica se há pelo menos 10GB disponíveis antes de iniciar a instalação.

## 👨‍💻 Desenvolvimento

### Estrutura dos Scripts

Os scripts seguem uma arquitetura modular:

- **Manifests** (`manifest.sh`) - Carregam outros scripts
- **Libs** (`lib/*.sh`) - Contêm funções específicas
- **Utils** (`utils/*.sh`) - Funções utilitárias reutilizáveis
- **Variables** (`variables/*.sh`) - Definições de variáveis

### Adicionar Nova Funcionalidade

1. Crie função no arquivo apropriado em `lib/`
2. Adicione chamada no script principal (`install_primaria` ou `install_instancia`)
3. Se necessário, adicione opção no menu em `lib/_inquiry.sh`

### Testes

Teste sempre em ambiente de desenvolvimento antes de usar em produção!

## 📄 Licença

Este projeto é um conjunto de scripts de instalação. Consulte a licença do software SaaS principal.

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📧 Suporte

Para suporte, entre em contato através dos canais oficiais do projeto.
