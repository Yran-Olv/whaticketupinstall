# Correção do Erro 404 no Nginx

## Problema Identificado

O projeto estava retornando **404 Not Found** em produção porque a configuração do Nginx estava incompleta:

1. **Faltava a diretiva `listen`**: O Nginx não estava configurado para escutar nas portas 80 (HTTP) e 443 (HTTPS)
2. **Faltava configuração para arquivos estáticos**: O backend serve arquivos em `/public`, mas o Nginx não estava configurado para servir esses arquivos diretamente
3. **Faltava configuração de WebSocket**: Não havia configuração adequada para Socket.IO
4. **Faltavam timeouts adequados**: Não havia configuração de timeouts para requisições longas

## Correções Aplicadas

### 1. Configuração do Frontend (`lib/_frontend.sh`)

- ✅ Adicionada diretiva `listen 80` e `listen [::]:80` para IPv4 e IPv6
- ✅ Adicionados logs de acesso e erro
- ✅ Adicionado `client_max_body_size 100M` para uploads grandes
- ✅ Adicionada configuração para WebSocket (`/socket.io`)
- ✅ Adicionados timeouts (`proxy_read_timeout`, `proxy_connect_timeout`)
- ✅ Adicionada configuração comentada para HTTPS (SSL)
- ✅ Melhorado o reload do Nginx com validação (`nginx -t`)

### 2. Configuração do Backend (`lib/_backend.sh`)

- ✅ Adicionada diretiva `listen 80` e `listen [::]:80`
- ✅ Adicionada rota `/public` para servir arquivos estáticos diretamente do backend
- ✅ Adicionados logs de acesso e erro
- ✅ Adicionado `client_max_body_size 100M`
- ✅ Adicionada configuração para WebSocket (`/socket.io`) com timeout de 24h
- ✅ Adicionados timeouts adequados
- ✅ Adicionada configuração comentada para HTTPS (SSL)
- ✅ Melhorado o reload do Nginx com validação

### 3. Configuração de Alteração de Domínio (`lib/_system.sh`)

- ✅ Aplicadas as mesmas correções na função `configurar_dominio()`

## Como Aplicar as Correções

### Para Instalações Novas

As correções serão aplicadas automaticamente ao executar o instalador.

### Para Instalações Existentes - Atualização Automática

**A partir de agora, ao executar a opção `[1] Atualizar whaticket`, o sistema automaticamente:**

1. ✅ Atualiza o código do frontend e backend
2. ✅ **Atualiza automaticamente as configurações do Nginx** com as correções
3. ✅ Extrai automaticamente as informações (portas e domínios) das configurações existentes
4. ✅ Aplica as mesmas correções do instalador

**Não é necessário fazer nada manualmente!** Basta executar a atualização normalmente.

### Para Instalações Existentes - Atualização Manual

1. **Atualize os arquivos do instalador** com as correções
2. **Execute o script de atualização** ou recrie as configurações do Nginx:

```bash
# Recriar configuração do frontend
sudo nano /etc/nginx/sites-available/SUA_INSTANCIA-frontend
# Cole a nova configuração

# Recriar configuração do backend
sudo nano /etc/nginx/sites-available/SUA_INSTANCIA-backend
# Cole a nova configuração

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

## Configuração de SSL/HTTPS

Para habilitar HTTPS:

1. **Instale o Certbot** (se ainda não tiver):
```bash
sudo apt install certbot python3-certbot-nginx
```

2. **Obtenha o certificado SSL**:
```bash
sudo certbot --nginx -d seu-dominio-frontend.com -d seu-dominio-backend.com
```

3. **Descomente as seções HTTPS** nos arquivos de configuração do Nginx

4. **Recarregue o Nginx**:
```bash
sudo systemctl reload nginx
```

## Verificação

Após aplicar as correções, verifique:

1. **Status do Nginx**:
```bash
sudo systemctl status nginx
```

2. **Teste a configuração**:
```bash
sudo nginx -t
```

3. **Verifique os logs**:
```bash
# Logs de erro
sudo tail -f /var/log/nginx/SUA_INSTANCIA-frontend-error.log
sudo tail -f /var/log/nginx/SUA_INSTANCIA-backend-error.log

# Logs de acesso
sudo tail -f /var/log/nginx/SUA_INSTANCIA-frontend-access.log
sudo tail -f /var/log/nginx/SUA_INSTANCIA-backend-access.log
```

4. **Teste o acesso**:
- Frontend: `http://seu-dominio-frontend.com`
- Backend: `http://seu-dominio-backend.com`

## Estrutura de Arquivos Estáticos

O backend serve arquivos estáticos em:
- `/public/company{companyId}/` - Arquivos por empresa
- `/public/uploads/` - Uploads do FlowBuilder
- `/public/announcements/` - Anúncios
- `/public/logotipos/` - Logotipos

Esses arquivos agora são servidos diretamente pelo Nginx para melhor performance.

## Melhorias na Função de Atualização

A função de atualização (`software_update`) agora inclui:

### `backend_nginx_update()`
- Extrai automaticamente URL e porta do backend das configurações existentes
- Atualiza a configuração do Nginx com todas as correções
- Mantém as configurações SSL existentes (se houver)
- Valida e recarrega o Nginx automaticamente

### `frontend_nginx_update()`
- Extrai automaticamente URL e porta do frontend das configurações existentes
- Atualiza a configuração do Nginx com todas as correções
- Mantém as configurações SSL existentes (se houver)
- Valida e recarrega o Nginx automaticamente

### Fontes de Informação (em ordem de prioridade)
1. Arquivo `.env` do backend/frontend
2. Arquivo `server.js` do frontend
3. Configurações do PM2
4. Arquivos de configuração do Nginx existentes

Se não conseguir detectar automaticamente, a atualização do Nginx é pulada e você pode configurar manualmente.

## Notas Importantes

- ⚠️ **Porta 80**: Certifique-se de que a porta 80 está aberta no firewall
- ⚠️ **Permissões**: Verifique as permissões da pasta `/home/deploy/SUA_INSTANCIA/backend/public`
- ⚠️ **SELinux**: Se estiver usando SELinux, pode ser necessário ajustar as políticas
- ⚠️ **Firewall**: Configure o firewall para permitir as portas necessárias
- ✅ **Atualização Automática**: A partir de agora, toda atualização inclui a correção do Nginx automaticamente

## Suporte

Se ainda encontrar problemas:

1. Verifique os logs do Nginx
2. Verifique os logs do PM2: `pm2 logs`
3. Verifique se os serviços estão rodando: `pm2 status`
4. Verifique as portas: `sudo netstat -tlnp | grep -E '80|443|SUA_PORTA'`
