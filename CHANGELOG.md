# Changelog - Melhorias do Instalador

## [2.1.0] - 2025-12-31

### Adicionado
- ✅ Instalação automática do FFmpeg
- ✅ Configuração completa de variáveis de ambiente (backend e frontend)
- ✅ Geração automática de chaves VAPID para push notifications
- ✅ Criação automática de diretórios de upload com permissões
- ✅ Configuração de PM2 com limite de memória (8096M)
- ✅ Configuração de PostgreSQL (pg_hba.conf)
- ✅ Variáveis de timezone e locale
- ✅ Variáveis de storage e upload

### Corrigido
- 🔧 NODE_ENV agora é definido como "production"
- 🔧 Variáveis Redis completas (HOST, PORT, PASSWORD)
- 🔧 Espaçamento em variáveis do frontend
- 🔧 Criação de banco PostgreSQL com verificação de existência
- 🔧 PM2 save após iniciar processos
- 🔧 Remoção de containers Redis existentes antes de criar novos

### Melhorado
- 🔧 Validação de espaço em disco aumentada para 15GB
- 🔧 Verificação de FFmpeg durante validação
- 🔧 Configuração de PostgreSQL mais robusta

## [2.0.0] - 2025-12-31

### Adicionado
- ✅ Validação pré-instalação completa (portas, DNS, espaço em disco)
- ✅ Configuração automática de firewall UFW
- ✅ Configuração de Fail2ban para proteção contra ataques
- ✅ Atualizações automáticas de segurança
- ✅ Hardening SSH automático
- ✅ Sistema de backups automáticos configurável
- ✅ Rotação de logs PM2 automática
- ✅ Scripts de monitoramento de saúde
- ✅ Verificação de saúde pós-instalação
- ✅ Tratamento de erros melhorado
- ✅ Validação de entrada de dados robusta

### Melhorado
- 🔧 Validação de nomes de instância
- 🔧 Validação de URLs e portas
- 🔧 Verificação de portas disponíveis
- 🔧 Verificação de resolução DNS
- 🔧 Tratamento de erros em todas as funções

### Segurança
- 🔒 Firewall UFW configurado automaticamente
- 🔒 Fail2ban instalado e configurado
- 🔒 Atualizações de segurança automáticas
- 🔒 SSH hardening aplicado
- 🔒 Permissões de arquivos melhoradas

### Monitoramento
- 📊 Logs PM2 com rotação automática
- 📊 Scripts de monitoramento de saúde
- 📊 Verificação automática de serviços
- 📊 Alertas por email (configurável)

### Backup
- 💾 Backups automáticos diários
- 💾 Retenção configurável de backups
- 💾 Scripts de restauração
- 💾 Compressão automática

## [1.0.0] - Versão Original

### Funcionalidades Iniciais
- Instalação básica do sistema
- Configuração de instâncias múltiplas
- Gerenciamento via PM2
- Configuração Nginx
- Certificados SSL via Certbot
