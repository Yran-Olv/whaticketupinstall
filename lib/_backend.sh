#!/bin/bash
#
# functions for setting up app backend
#######################################
# creates REDIS db using docker
# Arguments:
#   None
#######################################
backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Criando Redis e Banco de Dados PostgreSQL...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Criando container Docker do Redis na porta ${redis_port}${NC}\n"
  printf "${GRAY_LIGHT}    • Redis armazena mensagens temporárias e agendamentos${NC}\n"
  printf "${GRAY_LIGHT}    • Criando banco de dados PostgreSQL '${instancia_add}'${NC}\n"
  printf "${GRAY_LIGHT}    • Criando usuário do banco de dados com as credenciais informadas${NC}\n"
  printf "${GRAY_LIGHT}    • O banco de dados armazenará todos os dados permanentes do sistema${NC}\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  
  # Remove existing Redis container if exists
  docker rm -f redis-${instancia_add} 2>/dev/null || true
  
  # Create Redis container
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  
  sleep 2
  
  # Create PostgreSQL database and user
  sudo -u postgres bash <<PSQL_SCRIPT
# Create database if not exists
if ! psql -lqt | cut -d \| -f 1 | grep -qw ${instancia_add}; then
  createdb ${instancia_add}
fi

# Drop user if exists and create new
psql -c "DROP USER IF EXISTS ${instancia_add};" || true
psql -c "CREATE USER ${instancia_add} WITH SUPERUSER INHERIT CREATEDB CREATEROLE PASSWORD '${mysql_root_password}';"

# Grant privileges
psql -c "GRANT ALL PRIVILEGES ON DATABASE ${instancia_add} TO ${instancia_add};"
PSQL_SCRIPT
EOF

sleep 2

}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Criando arquivo .env com todas as configurações do backend${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando conexões com banco de dados, Redis e URLs${NC}\n"
  printf "${GRAY_LIGHT}    • Definindo limites de usuários e conexões WhatsApp${NC}\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url

sudo su - deploy << EOF
  # Initialize variables if not set
  if [ -z "${email_configured}" ]; then
    email_configured=false
  fi
  
  if [ -z "${mail_host}" ]; then
    mail_host="smtp.hostinger.com"
    mail_port="465"
    mail_user="contato@seusite.com"
    mail_pass="senha"
    mail_from="Recuperar Senha <contato@seusite.com>"
  fi
  
  if [ -z "${storage_type}" ]; then
    storage_type="local"
  fi
  
  if [ -z "${storage_configured}" ]; then
    storage_configured=false
  fi
  
  if [ -z "${vapid_subject}" ]; then
    vapid_subject="mailto:deploy@${instancia_add}.com"
  fi
  
  if [ -z "${push_configured}" ]; then
    push_configured=false
  fi
  
  # Generate VAPID keys for push notifications (if configured)
  cd /home/deploy/${instancia_add}/backend
  if [ "${push_configured}" = "true" ] && [ -f "scripts/generate-vapid-keys.js" ]; then
    VAPID_KEYS=\$(node scripts/generate-vapid-keys.js 2>/dev/null || echo "")
    VAPID_PUBLIC_KEY=\$(echo "\$VAPID_KEYS" | grep "VAPID_PUBLIC_KEY" | cut -d'=' -f2)
    VAPID_PRIVATE_KEY=\$(echo "\$VAPID_KEYS" | grep "VAPID_PRIVATE_KEY" | cut -d'=' -f2)
  else
    VAPID_PUBLIC_KEY=""
    VAPID_PRIVATE_KEY=""
  fi
  
  if [ -z "${vapid_subject}" ]; then
    vapid_subject="mailto:deploy@${instancia_add}.com"
  fi
  
  if [ -z "${push_configured}" ]; then
    push_configured=false
  fi
  
  cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=production
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}
TZ=America/Sao_Paulo

DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_DEBUG=false

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
JWT_EXPIRES_IN=1d
JWT_REFRESH_EXPIRES_IN=7d

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_HOST=127.0.0.1
REDIS_PORT=${redis_port}
REDIS_PASSWORD=${mysql_root_password}
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true

STORAGE_TYPE=${storage_type}
UPLOAD_FOLDER=public/uploads

MAIL_HOST="${mail_host}"
MAIL_USER="${mail_user}"
MAIL_PASS="${mail_pass}"
MAIL_FROM="${mail_from}"
MAIL_PORT="${mail_port}"

VAPID_PUBLIC_KEY=\${VAPID_PUBLIC_KEY}
VAPID_PRIVATE_KEY=\${VAPID_PRIVATE_KEY}
VAPID_SUBJECT="${vapid_subject}"

[-]EOF
EOF

  # Add AWS S3 configuration if selected
  if [ "${storage_type}" = "s3" ] && [ "${storage_configured}" = "true" ]; then
    sudo su - deploy << AWS_EOF
cat >> /home/deploy/${instancia_add}/backend/.env << 'AWS_ENV'
AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
AWS_REGION=${aws_region}
AWS_BUCKET_NAME=${aws_bucket_name}
AWS_ENV
AWS_EOF
  fi
  
  # Show configuration summary
  printf "\n${WHITE} 📋 Resumo da Configuração:${NC}\n\n"
  
  # Email status
  if [ "${email_configured}" = "true" ]; then
    printf "${GREEN} ✅ Email SMTP configurado${NC}\n"
  else
    printf "${YELLOW} ⚠️  Email SMTP NÃO configurado (OBRIGATÓRIO)${NC}\n"
    printf "${YELLOW}    Configure manualmente em: /home/deploy/${instancia_add}/backend/.env${NC}\n"
    printf "${YELLOW}    Variáveis: MAIL_HOST, MAIL_USER, MAIL_PASS, MAIL_FROM, MAIL_PORT${NC}\n"
  fi
  
  # Push notifications status
  if [ "${push_configured}" = "true" ]; then
    printf "${GREEN} ✅ Notificações Push configuradas${NC}\n"
    if [ -z "\${VAPID_PUBLIC_KEY}" ] || [ "\${VAPID_PUBLIC_KEY}" = "" ]; then
      printf "${YELLOW}    ⚠️  Chaves VAPID não foram geradas automaticamente${NC}\n"
      printf "${GRAY_LIGHT}    Execute: cd /home/deploy/${instancia_add}/backend && node scripts/generate-vapid-keys.js${NC}\n"
    else
      printf "${GREEN}    ✅ Chaves VAPID geradas${NC}\n"
    fi
  else
    printf "${GRAY_LIGHT} ⚪ Notificações Push não configuradas (opcional)${NC}\n"
  fi
  
  # Storage status
  if [ "${storage_type}" = "s3" ] && [ "${storage_configured}" = "true" ]; then
    printf "${GREEN} ✅ Armazenamento S3 configurado${NC}\n"
  else
    printf "${GRAY_LIGHT} ⚪ Armazenamento Local (padrão)${NC}\n"
  fi
  
  printf "\n"
  sleep 2
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Instalando todas as bibliotecas necessárias para o backend${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar vários minutos dependendo da conexão${NC}\n"
  printf "${GRAY_LIGHT}    • As dependências são salvas no arquivo package.json${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npm install
EOF

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Convertendo o código TypeScript/JavaScript para produção${NC}\n"
  printf "${GRAY_LIGHT}    • Otimizando o código para melhor performance${NC}\n"
  printf "${GRAY_LIGHT}    • O código compilado será salvo na pasta 'dist'${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar alguns minutos...${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npm run build
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-backend
  git pull
  cd /home/deploy/${empresa_atualizar}/backend
  npm install
  npm update -f
  npm install @types/fs-extra
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:migrate
  npx sequelize db:seed
  pm2 start ${empresa_atualizar}-backend
  pm2 save 
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando migrations do banco de dados...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Criando todas as tabelas necessárias no banco de dados${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando a estrutura do banco de dados${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa é essencial para o funcionamento do sistema${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npx sequelize db:migrate
EOF

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Populando banco de dados com dados iniciais...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Inserindo dados iniciais no banco de dados${NC}\n"
  printf "${GRAY_LIGHT}    • Criando usuário administrador padrão${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando dados básicos do sistema${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando backend com PM2...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Iniciando o serviço backend usando PM2${NC}\n"
  printf "${GRAY_LIGHT}    • PM2 manterá o serviço rodando automaticamente${NC}\n"
  printf "${GRAY_LIGHT}    • Se o serviço cair, PM2 reiniciará automaticamente${NC}\n"
  printf "${GRAY_LIGHT}    • O backend ficará disponível na porta ${backend_port}${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  pm2 start dist/server.js --name ${instancia_add}-backend --max-memory-restart 8096M --node-args="--max-old-space-size=8096"
  pm2 save
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx para o backend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando Nginx para redirecionar requisições do domínio backend${NC}\n"
  printf "${GRAY_LIGHT}    • O domínio ${backend_url} será redirecionado para a porta ${backend_port}${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando proxy reverso para comunicação segura${NC}\n\n"

  sleep 2

  # Remove https:// ou http:// se presente
  backend_hostname=$(echo "${backend_url}" | sed 's|^https\?://||')

sudo su - root << EOF
cat > /etc/nginx/sites-available/${instancia_add}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
