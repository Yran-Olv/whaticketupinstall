#!/bin/bash

get_mysql_root_password() {
  
  print_banner
  printf "${WHITE} 💻 Insira senha para o usuario Deploy e Banco de Dados:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Esta senha será usada para o usuário 'deploy' do sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Também será usada para acessar o banco de dados PostgreSQL${NC}\n"
  printf "${GRAY_LIGHT}    • ⚠️  IMPORTANTE: Não utilize caracteres especiais (use apenas letras e números)${NC}\n"
  printf "${GRAY_LIGHT}    • Guarde esta senha em local seguro!${NC}\n\n"
  read -p "> " mysql_root_password
}

get_link_git() {
  
  print_banner
  printf "${WHITE} 💻 Insira o link do GitHub da sua instalação que deseja instalar:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • O sistema vai baixar o código do repositório GitHub${NC}\n"
  printf "${GRAY_LIGHT}    • Você pode usar qualquer repositório que tenha as pastas 'frontend' e 'backend'${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: https://github.com/usuario/whaticket.git${NC}\n\n"
  read -p "> " link_git
}

get_instancia_add() {
  
  print_banner
  printf "${WHITE} 💻 Informe um nome para a Instancia/Empresa que será instalada:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Este nome será usado para identificar sua instalação${NC}\n"
  printf "${GRAY_LIGHT}    • Será usado para criar pastas, bancos de dados e serviços${NC}\n"
  printf "${GRAY_LIGHT}    • ⚠️  IMPORTANTE: Use apenas letras minúsculas, números e hífens${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: empresa1, minhaempresa, cliente-abc${NC}\n\n"
  read -p "> " instancia_add
}

get_max_whats() {
  
  print_banner
  printf "${WHITE} 💻 Informe a Qtde de Conexões/Whats que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Define quantos números de WhatsApp podem ser conectados${NC}\n"
  printf "${GRAY_LIGHT}    • Cada conexão permite receber e enviar mensagens${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: Se digitar 5, poderá conectar até 5 números${NC}\n\n"
  read -p "> " max_whats
}

get_max_user() {
  
  print_banner
  printf "${WHITE} 💻 Informe a Qtde de Usuarios/Atendentes que a ${instancia_add} poderá cadastrar:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Define quantos usuários/atendentes podem ser cadastrados${NC}\n"
  printf "${GRAY_LIGHT}    • Cada usuário pode acessar o sistema e atender clientes${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: Se digitar 10, poderá cadastrar até 10 atendentes${NC}\n\n"
  read -p "> " max_user
}

get_frontend_url() {
  
  print_banner
  printf "${WHITE} 💻 Digite o domínio do FRONTEND/PAINEL para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que é o Frontend:${NC}\n"
  printf "${GRAY_LIGHT}    • É a interface web onde os usuários acessam o sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: app.empresa.com.br ou painel.empresa.com.br${NC}\n"
  printf "${GRAY_LIGHT}    • Você pode digitar com ou sem https:// (ex: app.exemplo.com.br)${NC}\n\n"
  read -p "> " frontend_url
  
  # Remove https:// ou http:// se o usuário digitou
  frontend_url=$(echo "$frontend_url" | sed 's|^https\?://||')
}

get_backend_url() {
  
  print_banner
  printf "${WHITE} 💻 Digite o domínio do BACKEND/API para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que é o Backend:${NC}\n"
  printf "${GRAY_LIGHT}    • É a API que processa as requisições do sistema${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: api.empresa.com.br ou backend.empresa.com.br${NC}\n"
  printf "${GRAY_LIGHT}    • Você pode digitar com ou sem https:// (ex: api.exemplo.com.br)${NC}\n\n"
  read -p "> " backend_url
  
  # Remove https:// ou http:// se o usuário digitou
  backend_url=$(echo "$backend_url" | sed 's|^https\?://||')
}

get_frontend_port() {
  
  print_banner
  printf "${WHITE} 💻 Digite a porta do FRONTEND para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • A porta é um número que identifica o serviço no servidor${NC}\n"
  printf "${GRAY_LIGHT}    • Use uma porta entre 3000 e 3999${NC}\n"
  printf "${GRAY_LIGHT}    • Cada instância deve usar uma porta diferente${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: 3000, 3001, 3100, etc.${NC}\n\n"
  read -p "> " frontend_port
}


get_backend_port() {
  
  print_banner
  printf "${WHITE} 💻 Digite a porta do BACKEND para esta instancia:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • A porta é um número que identifica o serviço no servidor${NC}\n"
  printf "${GRAY_LIGHT}    • Use uma porta entre 4000 e 4999${NC}\n"
  printf "${GRAY_LIGHT}    • Cada instância deve usar uma porta diferente${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: 4000, 4001, 4100, etc.${NC}\n\n"
  read -p "> " backend_port
}

get_redis_port() {
  
  print_banner
  printf "${WHITE} 💻 Digite a porta do REDIS/AGENDAMENTO MSG para a ${instancia_add}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 O que está sendo feito:${NC}\n"
  printf "${GRAY_LIGHT}    • Redis é usado para armazenar mensagens temporárias e agendamentos${NC}\n"
  printf "${GRAY_LIGHT}    • Use uma porta entre 5000 e 5999${NC}\n"
  printf "${GRAY_LIGHT}    • Cada instância deve usar uma porta diferente${NC}\n"
  printf "${GRAY_LIGHT}    • Exemplo: 5000, 5001, 5100, etc.${NC}\n\n"
  read -p "> " redis_port
}

#######################################
# Email SMTP Configuration
# Arguments:
#   None
#######################################
get_email_config() {
  print_banner
  printf "${WHITE} 📧 Configuração de Email SMTP (OBRIGATÓRIO para recuperação de senha)${GRAY_LIGHT}\n\n"
  printf "${YELLOW} ⚠️  Esta configuração é obrigatória para recuperação de senha funcionar${NC}\n\n"
  
  printf "${WHITE} Deseja configurar Email SMTP agora? (s/n):${GRAY_LIGHT}\n\n"
  read -p "> " config_email
  
  if [ "$config_email" = "s" ] || [ "$config_email" = "S" ] || [ "$config_email" = "sim" ] || [ "$config_email" = "Sim" ] || [ "$config_email" = "y" ] || [ "$config_email" = "Y" ]; then
    printf "\n${WHITE} Servidor SMTP (ex: smtp.gmail.com, smtp.hostinger.com):${GRAY_LIGHT}\n\n"
    read -p "> " mail_host
    
    printf "\n${WHITE} Porta SMTP (ex: 465 para SSL, 587 para TLS):${GRAY_LIGHT}\n\n"
    read -p "> " mail_port
    
    printf "\n${WHITE} Email de envio:${GRAY_LIGHT}\n\n"
    read -p "> " mail_user
    
    printf "\n${WHITE} Senha do email (ou senha de aplicativo):${GRAY_LIGHT}\n\n"
    read -sp "> " mail_pass
    printf "\n"
    
    printf "\n${WHITE} Nome e email remetente (ex: Whaticket <noreply@dominio.com>):${GRAY_LIGHT}\n\n"
    read -p "> " mail_from
    
    email_configured=true
  else
    # Valores padrão (devem ser configurados manualmente depois)
    mail_host="smtp.hostinger.com"
    mail_port="465"
    mail_user="contato@seusite.com"
    mail_pass="senha"
    mail_from="Recuperar Senha <contato@seusite.com>"
    email_configured=false
    
    printf "\n${YELLOW} ⚠️  Email não configurado. Configure manualmente após a instalação em:${NC}\n"
    printf "${GRAY_LIGHT}    /home/deploy/${instancia_add}/backend/.env${NC}\n\n"
    sleep 3
  fi
}

#######################################
# Push Notifications Configuration
# Arguments:
#   None
#######################################
get_push_notifications_config() {
  print_banner
  printf "${WHITE} 🔔 Configuração de Notificações Push (OPCIONAL)${GRAY_LIGHT}\n\n"
  printf "${GRAY_LIGHT} Notificações push permitem receber alertas mesmo com navegador fechado${NC}\n\n"
  
  printf "${WHITE} Deseja configurar Notificações Push? (s/n):${GRAY_LIGHT}\n\n"
  read -p "> " config_push
  
  if [ "$config_push" = "s" ] || [ "$config_push" = "S" ] || [ "$config_push" = "sim" ] || [ "$config_push" = "Sim" ] || [ "$config_push" = "y" ] || [ "$config_push" = "Y" ]; then
    printf "\n${WHITE} Email para VAPID Subject (ex: admin@dominio.com ou mailto:admin@dominio.com):${GRAY_LIGHT}\n\n"
    read -p "> " vapid_subject_input
    
    # Remove "mailto:" se o usuário não incluir
    if [[ ! "$vapid_subject_input" =~ ^mailto: ]]; then
      vapid_subject="mailto:$vapid_subject_input"
    else
      vapid_subject="$vapid_subject_input"
    fi
    
    push_configured=true
  else
    vapid_subject="mailto:deploy@${instancia_add}.com"
    push_configured=false
  fi
}

#######################################
# Storage Configuration
# Arguments:
#   None
#######################################
get_storage_config() {
  print_banner
  printf "${WHITE} 💾 Configuração de Armazenamento${GRAY_LIGHT}\n\n"
  printf "${GRAY_LIGHT} Escolha o tipo de armazenamento para arquivos e mídias${NC}\n\n"
  printf "   [1] Local (padrão - arquivos no servidor)\n"
  printf "   [2] Amazon S3 (AWS)\n"
  printf "\n"
  read -p "> " storage_option
  
  case "${storage_option}" in
    1)
      storage_type="local"
      storage_configured=false
      ;;
    2)
      storage_type="s3"
      printf "\n${WHITE} AWS Access Key ID:${GRAY_LIGHT}\n\n"
      read -p "> " aws_access_key_id
      
      printf "\n${WHITE} AWS Secret Access Key:${GRAY_LIGHT}\n\n"
      read -sp "> " aws_secret_access_key
      printf "\n"
      
      printf "\n${WHITE} AWS Region (ex: us-east-1, sa-east-1):${GRAY_LIGHT}\n\n"
      read -p "> " aws_region
      
      printf "\n${WHITE} AWS Bucket Name:${GRAY_LIGHT}\n\n"
      read -p "> " aws_bucket_name
      
      storage_configured=true
      ;;
    *)
      storage_type="local"
      storage_configured=false
      ;;
  esac
}

get_empresa_delete() {
  
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que será Deletada (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_delete
}

get_empresa_atualizar() {
  
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Atualizar (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_atualizar
}

get_empresa_bloquear() {
  
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Bloquear (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_bloquear
}

get_empresa_desbloquear() {
  
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Desbloquear (Digite o mesmo nome de quando instalou):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_desbloquear
}

get_empresa_dominio() {
  
  print_banner
  printf "${WHITE} 💻 Digite o nome da Instancia/Empresa que deseja Alterar os Dominios (Atenção para alterar os dominios precisa digitar os 2, mesmo que vá alterar apenas 1):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " empresa_dominio
}

get_alter_frontend_url() {
  
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do FRONTEND/PAINEL para a ${empresa_dominio}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 Você pode digitar com ou sem https:// (ex: app.exemplo.com.br)${NC}\n\n"
  read -p "> " alter_frontend_url
  
  # Remove https:// ou http:// se o usuário digitou
  alter_frontend_url=$(echo "$alter_frontend_url" | sed 's|^https\?://||')
}

get_alter_backend_url() {
  
  print_banner
  printf "${WHITE} 💻 Digite o NOVO domínio do BACKEND/API para a ${empresa_dominio}:${GRAY_LIGHT}"
  printf "\n\n"
  printf "${GRAY_LIGHT} 📚 Você pode digitar com ou sem https:// (ex: api.exemplo.com.br)${NC}\n\n"
  read -p "> " alter_backend_url
  
  # Remove https:// ou http:// se o usuário digitou
  alter_backend_url=$(echo "$alter_backend_url" | sed 's|^https\?://||')
}

get_alter_frontend_port() {
  
  print_banner
  printf "${WHITE} 💻 Digite a porta do FRONTEND da Instancia/Empresa ${empresa_dominio}; A porta deve ser o mesma informada durante a instalação ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_frontend_port
}


get_alter_backend_port() {
  
  print_banner
  printf "${WHITE} 💻 Digite a porta do BACKEND da Instancia/Empresa ${empresa_dominio}; A porta deve ser o mesma informada durante a instalação ${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " alter_backend_port
}


get_urls() {
  get_mysql_root_password
  get_link_git
  get_instancia_add
  get_max_whats
  get_max_user
  get_frontend_url
  get_backend_url
  get_frontend_port
  get_backend_port
  get_redis_port
  get_email_config
  get_push_notifications_config
  get_storage_config
}

software_update() {
  get_empresa_atualizar
  frontend_update
  backend_update
}

software_delete() {
  get_empresa_delete
  deletar_tudo
}

software_bloquear() {
  get_empresa_bloquear
  configurar_bloqueio
}

software_desbloquear() {
  get_empresa_desbloquear
  configurar_desbloqueio
}

software_dominio() {
  get_empresa_dominio
  get_alter_frontend_url
  get_alter_backend_url
  get_alter_frontend_port
  get_alter_backend_port
  configurar_dominio
}

inquiry_options() {
  
  print_banner
  printf "${WHITE} 💻 Bem vindo(a) ao Gerenciador PLW DESIGN, Selecione abaixo a proxima ação!${GRAY_LIGHT}"
  printf "\n\n"
  printf "   [0] Instalar whaticket\n"
  printf "   [1] Atualizar whaticket\n"
  printf "   [2] Deletar Whaticket\n"
  printf "   [3] Bloquear Whaticket\n"
  printf "   [4] Desbloquear Whaticket\n"
  printf "   [5] Alter. dominio Whaticket\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    0) get_urls ;;

    1) 
      software_update 
      exit
      ;;

    2) 
      software_delete 
      exit
      ;;
    3) 
      software_bloquear 
      exit
      ;;
    4) 
      software_desbloquear 
      exit
      ;;
    5) 
      software_dominio 
      exit
      ;;        

    *) exit ;;
  esac
}


