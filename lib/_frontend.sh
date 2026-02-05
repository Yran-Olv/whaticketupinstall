#!/bin/bash
# 
# functions for setting up app frontend

#######################################
# installed node packages
# Arguments:
#   None
#######################################
frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Instalando todas as bibliotecas necessárias para o frontend${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar vários minutos dependendo da conexão${NC}\n"
  printf "${GRAY_LIGHT}    • As dependências incluem React e outras bibliotecas de interface${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm install
EOF

  sleep 2
}

#######################################
# compiles frontend code
# Arguments:
#   None
#######################################
frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Compilando o código React para produção${NC}\n"
  printf "${GRAY_LIGHT}    • Otimizando imagens, CSS e JavaScript${NC}\n"
  printf "${GRAY_LIGHT}    • O código compilado será salvo na pasta 'build'${NC}\n"
  printf "${GRAY_LIGHT}    • Esta etapa pode levar vários minutos...${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  npm run build
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-frontend
  git pull
  cd /home/deploy/${empresa_atualizar}/frontend
  npm install
  rm -rf build
  npm run build
  pm2 start ${empresa_atualizar}-frontend
  pm2 save
EOF

  sleep 2
}


#######################################
# sets frontend environment variables
# Arguments:
#   None
#######################################
frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Criando arquivo .env com configurações do frontend${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando URL do backend para comunicação${NC}\n"
  printf "${GRAY_LIGHT}    • Definindo configurações de localização e timezone${NC}\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_API_URL=${backend_url}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
REACT_APP_LOCALE=pt-br
REACT_APP_TIMEZONE=America/Sao_Paulo
REACT_APP_TRIALEXPIRATION=7
REACT_APP_ENV_TOKEN=TknWhaticket
[-]EOF
EOF

  sleep 2

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/frontend/server.js
//simple express server to run frontend production build;
const express = require("express");
const path = require("path");
const app = express();
app.use(express.static(path.join(__dirname, "build")));
app.get("/*", function (req, res) {
	res.sendFile(path.join(__dirname, "build", "index.html"));
});
app.listen(${frontend_port});

[-]EOF
EOF

  sleep 2
}

#######################################
# starts pm2 for frontend
# Arguments:
#   None
#######################################
frontend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando frontend com PM2...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Iniciando o serviço frontend usando PM2${NC}\n"
  printf "${GRAY_LIGHT}    • PM2 manterá o serviço rodando automaticamente${NC}\n"
  printf "${GRAY_LIGHT}    • Se o serviço cair, PM2 reiniciará automaticamente${NC}\n"
  printf "${GRAY_LIGHT}    • O frontend ficará disponível na porta ${frontend_port}${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando PM2 para iniciar automaticamente no boot do sistema${NC}\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/frontend
  pm2 start server.js --name ${instancia_add}-frontend
  pm2 save
EOF

 sleep 2
  
  sudo su - root <<EOF
   pm2 startup
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
EOF
  sleep 2
}

#######################################
# sets up nginx for frontend
# Arguments:
#   None
#######################################
frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx para o frontend...${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando Nginx para redirecionar requisições do domínio frontend${NC}\n"
  printf "${GRAY_LIGHT}    • O domínio ${frontend_url} será redirecionado para a porta ${frontend_port}${NC}\n"
  printf "${GRAY_LIGHT}    • Configurando proxy reverso para comunicação segura${NC}\n"
  printf "${GRAY_LIGHT}    • Permitindo conexões WebSocket para atualizações em tempo real${NC}\n\n"

  sleep 2

  # Remove https:// ou http:// se presente
  frontend_hostname=$(echo "${frontend_url}" | sed 's|^https\?://||')

sudo su - root << EOF

cat > /etc/nginx/sites-available/${instancia_add}-frontend << 'END'
server {
  server_name $frontend_hostname;

  location / {
    proxy_pass http://127.0.0.1:${frontend_port};
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

ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
EOF

  sleep 2
}
