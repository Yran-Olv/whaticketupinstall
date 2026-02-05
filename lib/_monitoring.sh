#!/bin/bash
#
# Monitoring and health check functions

#######################################
# Configure PM2 log rotation
# Arguments:
#   None
#######################################
configure_pm2_logs() {
  print_banner
  printf "${WHITE} 📊 Configurando rotação de logs PM2...${GRAY_LIGHT}\n\n"
  
  sleep 2
  
  sudo su - deploy <<EOF
  # Configure PM2 log rotation
  pm2 install pm2-logrotate
  
  # Configure log rotation settings
  pm2 set pm2-logrotate:max_size 10M
  pm2 set pm2-logrotate:retain 7
  pm2 set pm2-logrotate:compress true
  pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
  pm2 set pm2-logrotate:workerInterval 30
  pm2 set pm2-logrotate:rotateInterval 0 0 * * *
  
  pm2 save
EOF
  
  sleep 2
}

#######################################
# Health check after installation
# Arguments:
#   $1 - Instance name
#######################################
health_check() {
  local instance=$1
  
  print_banner
  printf "${WHITE} 🏥 Verificando saúde do sistema...${GRAY_LIGHT}\n\n"
  
  local errors=0
  local fixed=0
  
  # Check PM2 processes
  printf "Verificando processos PM2...\n"
  if ! sudo su - deploy -c "pm2 list | grep -q '${instance}-backend.*online'" 2>/dev/null; then
    printf "${YELLOW} ⚠️  Backend não está rodando. Tentando iniciar...${NC}\n"
    sudo su - deploy -c "cd /home/deploy/${instance}/backend && pm2 start dist/server.js --name ${instance}-backend --max-memory-restart 8096M --node-args=\"--max-old-space-size=8096\" 2>/dev/null && pm2 save" 2>/dev/null
    sleep 2
    if sudo su - deploy -c "pm2 list | grep -q '${instance}-backend.*online'" 2>/dev/null; then
      printf "${GREEN} ✅ Backend iniciado com sucesso!${NC}\n"
      fixed=$((fixed + 1))
    else
      printf "${RED} ❌ Não foi possível iniciar o backend${NC}\n"
      errors=$((errors + 1))
    fi
  else
    printf "${GREEN} ✅ Backend está rodando${NC}\n"
  fi
  
  if ! sudo su - deploy -c "pm2 list | grep -q '${instance}-frontend.*online'" 2>/dev/null; then
    printf "${YELLOW} ⚠️  Frontend não está rodando. Tentando iniciar...${NC}\n"
    sudo su - deploy -c "cd /home/deploy/${instance}/frontend && pm2 start server.js --name ${instance}-frontend 2>/dev/null && pm2 save" 2>/dev/null
    sleep 2
    if sudo su - deploy -c "pm2 list | grep -q '${instance}-frontend.*online'" 2>/dev/null; then
      printf "${GREEN} ✅ Frontend iniciado com sucesso!${NC}\n"
      fixed=$((fixed + 1))
    else
      printf "${RED} ❌ Não foi possível iniciar o frontend${NC}\n"
      errors=$((errors + 1))
    fi
  else
    printf "${GREEN} ✅ Frontend está rodando${NC}\n"
  fi
  
  # Check Redis container
  printf "Verificando Redis...\n"
  if ! sudo docker ps 2>/dev/null | grep -q "redis-${instance}"; then
    printf "${YELLOW} ⚠️  Container Redis não está rodando. Tentando iniciar...${NC}\n"
    sudo docker start redis-${instance} 2>/dev/null
    sleep 2
    if sudo docker ps 2>/dev/null | grep -q "redis-${instance}"; then
      printf "${GREEN} ✅ Redis iniciado com sucesso!${NC}\n"
      fixed=$((fixed + 1))
    else
      printf "${RED} ❌ Não foi possível iniciar o Redis${NC}\n"
      errors=$((errors + 1))
    fi
  else
    printf "${GREEN} ✅ Redis está rodando${NC}\n"
  fi
  
  # Check PostgreSQL
  printf "Verificando PostgreSQL...\n"
  if ! sudo su - postgres -c "psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw ${instance}" 2>/dev/null; then
    printf "${RED} ❌ Banco de dados não existe${NC}\n"
    errors=$((errors + 1))
  else
    printf "${GREEN} ✅ Banco de dados existe${NC}\n"
  fi
  
  # Check Nginx
  printf "Verificando Nginx...\n"
  if ! command -v nginx >/dev/null 2>&1; then
    printf "${RED} ❌ Nginx não está instalado${NC}\n"
    printf "${YELLOW}    Execute: sudo apt install -y nginx${NC}\n"
    errors=$((errors + 1))
  elif ! sudo systemctl is-active --quiet nginx 2>/dev/null; then
    printf "${YELLOW} ⚠️  Nginx não está rodando. Tentando iniciar...${NC}\n"
    
    # Test Nginx configuration first
    if sudo nginx -t 2>/dev/null; then
      sudo systemctl start nginx 2>/dev/null || sudo service nginx start 2>/dev/null
      sleep 2
      if sudo systemctl is-active --quiet nginx 2>/dev/null || sudo service nginx status >/dev/null 2>&1; then
        printf "${GREEN} ✅ Nginx iniciado com sucesso!${NC}\n"
        fixed=$((fixed + 1))
      else
        printf "${RED} ❌ Não foi possível iniciar o Nginx${NC}\n"
        printf "${YELLOW}    Verifique os logs: sudo tail -f /var/log/nginx/error.log${NC}\n"
        printf "${YELLOW}    Teste a configuração: sudo nginx -t${NC}\n"
        errors=$((errors + 1))
      fi
    else
      printf "${RED} ❌ Configuração do Nginx inválida${NC}\n"
      printf "${YELLOW}    Execute: sudo nginx -t para ver os erros${NC}\n"
      errors=$((errors + 1))
    fi
  else
    printf "${GREEN} ✅ Nginx está rodando${NC}\n"
  fi
  
  # Check SSL certificates
  printf "Verificando certificados SSL...\n"
  if sudo certbot certificates 2>/dev/null | grep -q "${instance}"; then
    printf "${GREEN} ✅ Certificados SSL configurados${NC}\n"
  else
    printf "${YELLOW} ⚠️  Certificados SSL não encontrados${NC}\n"
    printf "${GRAY_LIGHT}    Isso é normal se os domínios ainda não estão configurados no DNS${NC}\n"
  fi
  
  if [ $fixed -gt 0 ]; then
    printf "\n${GREEN} ✅ $fixed problema(s) corrigido(s) automaticamente!${NC}\n"
  fi
  
  if [ $errors -gt 0 ]; then
    printf "\n${RED} ❌ Encontrados $errors problema(s) que não puderam ser corrigidos automaticamente${NC}\n"
    printf "${GRAY_LIGHT}    Verifique os logs e tente corrigir manualmente${NC}\n"
    return 1
  else
    printf "\n${GREEN} ✅ Todos os serviços estão funcionando corretamente!${NC}\n"
    return 0
  fi
}

#######################################
# Create monitoring script
# Arguments:
#   $1 - Instance name
#######################################
create_monitoring_script() {
  local instance=$1
  
  sudo su - root <<EOF
  cat > /usr/local/bin/monitor-${instance}.sh << 'MONITOR_EOF'
#!/bin/bash
INSTANCE="${instance}"

# Check if processes are running
if ! pm2 list | grep -q "\${INSTANCE}-backend.*online"; then
  echo "Backend \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Backend Down" root
  pm2 restart \${INSTANCE}-backend
fi

if ! pm2 list | grep -q "\${INSTANCE}-frontend.*online"; then
  echo "Frontend \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Frontend Down" root
  pm2 restart \${INSTANCE}-frontend
fi

# Check Redis
if ! docker ps | grep -q "redis-\${INSTANCE}"; then
  echo "Redis \${INSTANCE} is down!" | mail -s "Alert: \${INSTANCE} Redis Down" root
  docker start redis-\${INSTANCE}
fi
MONITOR_EOF
  
  chmod +x /usr/local/bin/monitor-${instance}.sh
  
  # Add to crontab (every 5 minutes)
  (crontab -l 2>/dev/null | grep -v "monitor-${instance}"; echo "*/5 * * * * /usr/local/bin/monitor-${instance}.sh") | crontab -
EOF
}
