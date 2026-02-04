#!/bin/bash
#
# Validation and verification functions

#######################################
# Check if port is available
# Arguments:
#   $1 - Port number
# Returns:
#   0 if available, 1 if in use
#######################################
check_port_available() {
  local port=$1
  
  # Try lsof first
  if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
      return 1
    fi
  fi
  
  # Try netstat as fallback
  if command -v netstat >/dev/null 2>&1; then
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
      return 1
    fi
  fi
  
  # Try ss as another fallback
  if command -v ss >/dev/null 2>&1; then
    if ss -tuln 2>/dev/null | grep -q ":$port "; then
      return 1
    fi
  fi
  
  return 0
}

#######################################
# Validate port range
# Arguments:
#   $1 - Port number
#   $2 - Min port
#   $3 - Max port
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_port_range() {
  local port=$1
  local min=$2
  local max=$3
  
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  
  if [ "$port" -lt "$min" ] || [ "$port" -gt "$max" ]; then
    return 1
  fi
  
  return 0
}

#######################################
# Check if domain resolves to server IP
# Arguments:
#   $1 - Domain name
# Returns:
#   0 if resolves correctly, 1 if not
#######################################
check_domain_resolution() {
  local domain=$1
  
  # Try to get server IP
  local server_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "")
  
  if [ -z "$server_ip" ]; then
    printf "${YELLOW} ⚠️  Não foi possível obter o IP do servidor. Continuando...${NC}\n"
    return 0
  fi
  
  # Try to resolve domain
  local domain_ip=$(dig +short $domain 2>/dev/null | tail -n1 || echo "")
  
  if [ -z "$domain_ip" ]; then
    printf "${YELLOW} ⚠️  Domínio $domain não resolve para nenhum IP${NC}\n"
    printf "${YELLOW}    Configure o DNS antes de continuar${NC}\n"
    return 1
  fi
  
  if [ "$domain_ip" != "$server_ip" ]; then
    printf "${YELLOW} ⚠️  Domínio $domain resolve para $domain_ip, mas servidor está em $server_ip${NC}\n"
    printf "${YELLOW}    Configure o DNS antes de continuar${NC}\n"
    return 1
  fi
  
  return 0
}

#######################################
# Check disk space
# Arguments:
#   $1 - Required space in GB
# Returns:
#   0 if enough space, 1 if not
#######################################
check_disk_space() {
  local required_gb=$1
  local available_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
  
  if [ "$available_gb" -lt "$required_gb" ]; then
    printf "${RED} ❌ Espaço insuficiente. Necessário: ${required_gb}GB, Disponível: ${available_gb}GB${NC}\n"
    return 1
  fi
  
  return 0
}

#######################################
# Validate instance name
# Arguments:
#   $1 - Instance name
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_instance_name() {
  local name=$1
  
  # Check if contains only lowercase letters, numbers, and hyphens
  if ! [[ "$name" =~ ^[a-z0-9-]+$ ]]; then
    return 1
  fi
  
  # Check if starts with letter
  if ! [[ "$name" =~ ^[a-z] ]]; then
    return 1
  fi
  
  # Check length (3-30 chars)
  if [ ${#name} -lt 3 ] || [ ${#name} -gt 30 ]; then
    return 1
  fi
  
  return 0
}

#######################################
# Validate URL format
# Arguments:
#   $1 - URL
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_url() {
  local url=$1
  
  if [[ ! "$url" =~ ^https?:// ]]; then
    return 1
  fi
  
  return 0
}

#######################################
# Check if instance already exists
# Arguments:
#   $1 - Instance name
# Returns:
#   0 if exists, 1 if not
#######################################
check_instance_exists() {
  local instance=$1
  
  if [ -d "/home/deploy/$instance" ]; then
    return 0
  fi
  
  return 1
}

#######################################
# Pre-installation validation
# Arguments:
#   None
#######################################
pre_install_validation() {
  print_banner
  printf "${WHITE} 🔍 Validando pré-requisitos...${GRAY_LIGHT}\n\n"
  
  local errors=0
  
  # Check disk space (minimum 15GB for production)
  if ! check_disk_space 15; then
    errors=$((errors + 1))
  fi
  
  # Verify FFmpeg (warning if not installed)
  if ! verify_ffmpeg >/dev/null 2>&1; then
    printf "${YELLOW} ⚠️  FFmpeg não encontrado. Será instalado durante a instalação.${NC}\n"
  fi
  
  # Validate instance name
  if ! validate_instance_name "$instancia_add"; then
    printf "${RED} ❌ Nome da instância inválido. Use apenas letras minúsculas, números e hífens${NC}\n"
    errors=$((errors + 1))
  fi
  
  # Check if instance already exists
  if check_instance_exists "$instancia_add"; then
    printf "${RED} ❌ Instância '$instancia_add' já existe${NC}\n"
    errors=$((errors + 1))
  fi
  
  # Validate ports
  if ! validate_port_range "$frontend_port" 3000 3999; then
    printf "${RED} ❌ Porta do frontend inválida. Use entre 3000-3999${NC}\n"
    errors=$((errors + 1))
  fi
  
  if ! validate_port_range "$backend_port" 4000 4999; then
    printf "${RED} ❌ Porta do backend inválida. Use entre 4000-4999${NC}\n"
    errors=$((errors + 1))
  fi
  
  if ! validate_port_range "$redis_port" 5000 5999; then
    printf "${RED} ❌ Porta do Redis inválida. Use entre 5000-5999${NC}\n"
    errors=$((errors + 1))
  fi
  
  # Check if ports are available
  if ! check_port_available "$frontend_port"; then
    printf "${RED} ❌ Porta $frontend_port já está em uso${NC}\n"
    errors=$((errors + 1))
  fi
  
  if ! check_port_available "$backend_port"; then
    printf "${RED} ❌ Porta $backend_port já está em uso${NC}\n"
    errors=$((errors + 1))
  fi
  
  if ! check_port_available "$redis_port"; then
    printf "${RED} ❌ Porta $redis_port já está em uso${NC}\n"
    errors=$((errors + 1))
  fi
  
  # Validate URLs
  if ! validate_url "$frontend_url"; then
    printf "${RED} ❌ URL do frontend inválida. Use formato: https://dominio.com${NC}\n"
    errors=$((errors + 1))
  fi
  
  if ! validate_url "$backend_url"; then
    printf "${RED} ❌ URL do backend inválida. Use formato: https://dominio.com${NC}\n"
    errors=$((errors + 1))
  fi
  
  # Check domain resolution (warning only)
  printf "${YELLOW} ⚠️  Verificando resolução DNS...${NC}\n"
  check_domain_resolution "$(echo $frontend_url | sed 's|https\?://||' | cut -d/ -f1)" || true
  check_domain_resolution "$(echo $backend_url | sed 's|https\?://||' | cut -d/ -f1)" || true
  
  if [ $errors -gt 0 ]; then
    printf "\n${RED} ❌ Encontrados $errors erro(s). Corrija antes de continuar.${NC}\n"
    exit 1
  fi
  
  printf "${GREEN} ✅ Validação concluída com sucesso!${NC}\n\n"
  sleep 2
}
