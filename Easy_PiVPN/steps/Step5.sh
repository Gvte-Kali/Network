# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"


# Étape 5 : Demander la configuration IP à l'utilisateur
step5() {
  echo -e "\n${GRAY_BLUE}=== Étape 5 : Configuration IP ===${NC}"
  read -p "Interface réseau (e.g., eth0) : " IP_Interface
  read -p "Adresse IP (e.g., 192.168.1.100) : " IP_Address
  read -p "Masque (e.g., /24) : " Netmask
  read -p "Passerelle (Gateway) : " Gateway
  read -p "DNS Primaire : " DNS_Primary
  read -p "DNS Secondaire : " DNS_Secondary

  # Validation de l'entrée utilisateur (simple vérification de base)
  if ! [[ "$IP_Interface" =~ ^[a-z0-9]+$ && "$IP_Address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Entrées non valides, réessayez."
    return 1
  fi
  echo
}

step5
