#!/bin/bash

# Version et lien de RustDesk
rustdesk_link="https://github.com/rustdesk/rustdesk/releases/download/1.3.7/rustdesk-1.3.7-x86_64.deb"
rustdesk_version="1.3.7"

# Couleurs
GRAY_BLUE="\033[1;34m"    # Gris bleu foncé
LIGHT_BLUE="\033[1;36m"   # Bleu clair
NC="\033[0m"              # Reset couleur

# Fonction pour afficher un menu principal
main_menu() {
  echo -e "${LIGHT_BLUE}=== Menu Principal ===${NC}"
  echo "1. Démarrer à partir de l'étape 1"
  echo "2. Aller à une étape spécifique"
  echo "0. Quitter"
  echo
  read -p "Choix : " main_choice
}

# Fonction pour afficher les choix à chaque étape (en bleu clair)
step_menu() {
  echo
  echo -e "${LIGHT_BLUE}[C]ontinuer | [S]top| [R]efaire l'étape précédente | [M]enu principal${NC}"

  echo
  read -p "Choix : " step_choice
}

check_prerequisites() {
  # Vérifier si l'utilisateur a les droits sudo
  if [[ $EUID -ne 0 ]]; then
     echo "Ce script doit être exécuté avec des privilèges sudo." 
     exit 1
  fi

  # Vérifier les dépendances
  dependencies=("curl" "wget" "jq")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      echo "Installation de $dep..."
      sudo apt install -y "$dep"
    fi
  done
}

# Appeler la vérification des prérequis
check_prerequisites

# Étape 0 : Préparation des répertoires et fichiers de configuration
step0() {
  echo -e "\n${GRAY_BLUE}=== Étape 0 : Préparation des répertoires ===${NC}"
  
  # Création du dossier vpn_config et public_cron
  mkdir -p "$HOME/vpn_config"
  
  # Création des fichiers de log et temporaires si nécessaire
  touch "$HOME/vpn_config/install_log.txt"
  touch "$HOME/vpn_config/temp_config.txt"
  
  # Récupération de l'adresse IP publique
  public_ip=$(curl -s ifconfig.me)
  echo "$public_ip" > "$HOME/vpn_config/public_ip"

  echo "Répertoires et fichiers de configuration créés."
  echo
}

# Étape 1 : Mettre à jour les paquets
step1() {
  echo -e "\n${GRAY_BLUE}=== Étape 1 : Mise à jour des paquets ===${NC}"
  sudo apt update && sudo apt upgrade -y
  echo
}

# Étape 2 : Télécharger et installer RustDesk
step2() {
  echo -e "\n${GRAY_BLUE}=== Étape 2 : Installation de RustDesk ===${NC}"
  
  # Vérifier si RustDesk est installé
  if dpkg -l | grep -q rustdesk; then
    # RustDesk est installé, vérifier la version
    current_version=$(dpkg -l | grep rustdesk | awk '{print $3}')
    
    echo "Version actuelle de RustDesk : $current_version"
    echo "Dernière version disponible : $rustdesk_version"
    
    # Comparer les versions
    if [ "$(printf '%s\n' "$rustdesk_version" "$current_version" | sort -V | head -n1)" = "$current_version" ]; then
      # Version actuelle est inférieure à la dernière version
      read -p "Une nouvelle version est disponible. Voulez-vous mettre à jour ? (O/n) : " update_choice
      
      if [[ "$update_choice" =~ ^[Oo]$ ]] || [ -z "$update_choice" ]; then
        # Téléchargement du fichier .deb
        echo "Téléchargement de RustDesk..."
        wget -O "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" "$rustdesk_link"
        
        # Tentative d'installation
        echo "Installation de RustDesk..."
        sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
        
        # Gestion des erreurs potentielles
        if [ $? -ne 0 ]; then
          echo "Une erreur est survenue lors de la mise à jour."
          
          # Mise à jour des paquets
          echo "Mise à jour des paquets..."
          sudo apt update
          
          # Résolution des dépendances manquantes
          echo "Installation des dépendances manquantes..."
          sudo apt install -f -y
          
          # Nouvelle tentative d'installation
          echo "Nouvelle tentative d'installation de RustDesk..."
          sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
          
          if [ $? -ne 0 ]; then
            echo "Échec de la mise à jour. Essai de réparation avec apt --fix-broken install"
            sudo apt --fix-broken install -y
            
            # Dernière tentative d'installation
            sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
          fi
        fi
      else
        echo "Mise à jour annulée. Continuation du script."
      fi
    else
      echo "Vous avez déjà la dernière version de RustDesk."
    fi
  else
    # RustDesk n'est pas installé, procéder à l'installation
    # Téléchargement du fichier .deb
    echo "Téléchargement de RustDesk..."
    wget -O "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" "$rustdesk_link"
    
    # Tentative d'installation
    echo "Installation de RustDesk..."
    sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
    
    # Gestion des erreurs potentielles
    if [ $? -ne 0 ]; then
      echo "Une erreur est survenue lors de l'installation."
      
      # Mise à jour des paquets
      echo "Mise à jour des paquets..."
      sudo apt update
      
      # Résolution des dépendances manquantes
      echo "Installation des dépendances manquantes..."
      sudo apt install -f -y
      
      # Nouvelle tentative d'installation
      echo "Nouvelle tentative d'installation de RustDesk..."
      sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
      
      if [ $? -ne 0 ]; then
        echo "Échec de l'installation. Essai de réparation avec apt --fix-broken install"
        sudo apt --fix-broken install -y
        
        # Dernière tentative d'installation
        sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
      fi
    fi
  fi
  
  # 1. Configuration du démarrage automatique
  echo "Configuration du démarrage automatique de RustDesk..."
  sudo systemctl enable rustdesk
  
  # 2. Vérification du service
  echo "Vérification du service RustDesk..."
  if ! systemctl is-active --quiet rustdesk; then
    echo "Le service RustDesk n'est pas en cours d'exécution. Démarrage..."
    sudo systemctl start rustdesk
    
    # Vérification après démarrage
    if ! systemctl is-active --quiet rustdesk; then
      echo "ERREUR : Impossible de démarrer le service RustDesk"
      return 1
    fi
  fi
  
  # 3. Message pour le mot de passe
  echo -e "\n${LIGHT_BLUE}IMPORTANT :${NC}"
  echo "Il faut mettre un mot de passe permanent sur votre session Rustdesk."
  echo "Allez dans les paramètres et mettez un mot de passe unique (one-time password)."
  echo
  
  # 4. Demande du numéro de session
  while true; do
    read -p "Entrez votre numéro de session RustDesk : " rustdesk_id
    
    # Validation simple du numéro de session
    if [[ "$rustdesk_id" =~ ^[0-9]+$ ]]; then
      echo "Numéro de session enregistré : $rustdesk_id"
      break
    else
      echo "Numéro de session invalide. Veuillez entrer uniquement des chiffres."
    fi
  done

  # Création du fichier rustdesk session
  echo "$rustdesk_id" > "$HOME/vpn_config/rustdesk"
  
  echo "Processus d'installation et de configuration de RustDesk terminé."
  echo
}

# Étape 3 : Installer OpenVPN
step3() {
  echo -e "\n${GRAY_BLUE}=== Étape 3 : Installer OpenVPN ===${NC}"
  sudo apt install -y openvpn
  echo
}

# Étape 4 : Afficher les informations réseau détaillées
step4() {
  echo -e "\n${GRAY_BLUE}=== Étape 4 : Informations réseau ===${NC}"
  
  # Utilisation de la commande ip et de la commande resolvconf pour récupérer les informations
  ip -br addr | while read -r interface status ip_info; do
    # Extraction de l'adresse IP et du masque
    ip_address=$(echo "$ip_info" | cut -d'/' -f1)
    netmask=$(echo "$ip_info" | cut -d'/' -f2)
    
    # Récupération de la passerelle
    gateway=$(ip route | grep default | awk '{print $3}')
    
    # Récupération des serveurs DNS
    dns_servers=$(grep -m 1 '^nameserver' /etc/resolv.conf | awk '{print $2}')
    
    # Affichage formatté
    echo -e "${LIGHT_BLUE}Interface${NC}   : $interface"
    echo -e "Adresse IP${NC} : $ip_address/$netmask"
    echo -e "Passerelle${NC} : $gateway"
    echo -e "DNS       : $dns_servers"
    echo "---"
  done
  
  echo
}

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

# Étape 6 : Appliquer la configuration au fichier /etc/dhcpcd.conf
step6() {
  echo -e "\n${GRAY_BLUE}=== Étape 6 : Appliquer la configuration IP ===${NC}"
  sudo bash -c "echo -e '\n# Configuration réseau statique\ninterface $IP_Interface\nstatic ip_address=$IP_Address$Netmask\nstatic routers=$Gateway\nstatic domain_name_servers=$DNS_Primary $DNS_Secondary' >> /etc/dhcpcd.conf"
  sudo systemctl restart dhcpcd
  echo "Configuration appliquée et service redémarré."
  echo
}

# Étape 7 : Guidage pour configurer l'autologin
step7() {
  echo -e "\n${GRAY_BLUE}=== Étape 7 : Configurer l'autologin ===${NC}"
  echo
  echo "Pour configurer l'autologin en mode Desktop (interface graphique) :"
  echo
  echo "1. Naviguez dans les sous-menus de raspi-config :"
  echo "   - Allez dans \"System Options\"."
  echo "   - Ensuite, allez dans \"Boot / Auto Login\"."
  echo "   - Enfin, sélectionnez \"Desktop Autologin\"."
  echo
  read -p "Appuyez sur Entrée pour continuer et ouvrir raspi-config..."
  sudo raspi-config
  echo
}

# Étape 8 : Configuration du cronjob Discord
step8() {
  echo -e "\n${GRAY_BLUE}=== Étape 8 : Configuration du cronjob Discord ===${NC}"
  
  # Demander les informations pour l'API Discord
  echo -e "${LIGHT_BLUE}Configuration de l'envoi des informations via Discord${NC}"
  
  # Demander l'URL du webhook Discord
  while true; do
    read -p "Entrez l'URL du webhook Discord : " discord_webhook
    
    # Validation simple de l'URL
    if [[ "$discord_webhook" =~ ^https://discord.com/api/webhooks/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
      break
    else
      echo "URL de webhook invalide. Veuillez entrer une URL valide de webhook Discord."
    fi
  done
  
  # Sauvegarder l'URL du webhook dans un fichier
  mkdir -p "$HOME/vpn_config"
  echo "$discord_webhook" > "$HOME/vpn_config/discord_webhook.txt"
  
  # Télécharger le script de mise à jour IP
  update_script="$HOME/vpn_config/update_pivpn_ip.sh"
  wget -O "$update_script" "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/discord_public_ip_update.sh"
  chmod +x "$update_script"
  
  # Créer un cronjob pour exécuter le script toutes les 10 minutes
  (crontab -l 2>/dev/null; echo "*/10 * * * * $update_script") | crontab -
  
  echo -e "\n${LIGHT_BLUE}Script de mise à jour IP téléchargé avec succès et cronjob configuré !${NC}"
  echo "Le script s'exécutera toutes les 10  toutes les 10 minutes pour vérifier et mettre à jour l'adresse IP publique."
  echo "Vous pouvez modifier ou supprimer ce cronjob à tout moment."
  echo
}

# Étape 9 : Installer PiVPN
step9() {
  echo -e "\n${GRAY_BLUE}=== Étape 9 : Installation de PiVPN ===${NC}"
  curl -L https://install.pivpn.io | bash
  echo
}

# Étape 10 : Configuration du routage et NAT entre interfaces VPN et réseau physique
step10() {
    configure_lan_vpn_routing() {
        # Nettoyer COMPLETEMENT les règles existantes
        echo -e "${YELLOW}Nettoyage complet des règles iptables...${NC}"
        sudo iptables -F
        sudo iptables -X
        sudo iptables -t nat -F
        sudo iptables -t nat -X

        # Définition des interfaces
        LAN_INTERFACE="eth0"
        VPN_INTERFACE="wg0"
        VPN_NETWORK="10.251.203.0/24"
        LAN_NETWORK="192.168.1.0/24"

        # Activation du forwarding IP
        echo -e "${YELLOW}Configuration du forwarding IP...${NC}"
        sudo sysctl -w net.ipv4.ip_forward=1
        sudo sed -i 's/#*net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf

        # Politique de forwarding EXPLICITE
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        sudo iptables -P FORWARD DROP  # Par défaut DROP

        # Autoriser le trafic sur la boucle locale
        sudo iptables -A INPUT -i lo -j ACCEPT
        sudo iptables -A OUTPUT -o lo -j ACCEPT

        # Autoriser les connexions déjà établies
        sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

        # Règles de forwarding DETAILLEES
        sudo iptables -A FORWARD -i "$VPN_INTERFACE" -o "$LAN_INTERFACE" -j ACCEPT
        sudo iptables -A FORWARD -i "$LAN_INTERFACE" -o "$VPN_INTERFACE" -j ACCEPT

        # Configuration NAT
        sudo iptables -t nat -A POSTROUTING -s "$VPN_NETWORK" -o "$LAN_INTERFACE" -j MASQUERADE
        sudo iptables -t nat -A POSTROUTING -s "$LAN_NETWORK" -o "$VPN_INTERFACE" -j MASQUERADE

        # Sauvegarder les règles
        sudo apt-get install -y iptables-persistent
        sudo netfilter-persistent save

        # Diagnostic détaillé
        diagnostic_routing() {
            echo -e "\n${GREEN}Diagnostic de configuration :${NC}"
            
            echo -e "${BLUE}Forwarding IP :${NC}"
            cat /proc/sys/net/ipv4/ip_forward
            
            echo -e "\n${BLUE}Routes :${NC}"
            ip route show
            
            echo -e "\n${BLUE}Règles iptables (Filter) :${NC}"
            sudo iptables -L -n -v
            
            echo -e "\n${BLUE}Règles iptables (NAT) :${NC}"
            sudo iptables -t nat -L -n -v
        }
        
        # Configuration des routes
        echo -e "${YELLOW}Configuration des routes...${NC}"
        # Ajouter une route pour le réseau VPN
        sudo ip route add "$LAN_NETWORK" dev "$VPN_INTERFACE" src 10.251.203.1

        # Redémarrer Wireguard
        sudo systemctl restart wg-quick@wg0

        # Lancer le diagnostic
        diagnostic_routing
    }

    # Vérification des prérequis
    check_prerequisites() {
        echo -e "${YELLOW}Vérification des prérequis...${NC}"
        
        # Vérifier Wireguard
        if ! command -v wg &> /dev/null; then
            echo -e "${RED}Wireguard n'est pas installé.${NC}"
            return 1
        fi

        # Vérifier configuration PiVPN
        if [[ ! -f /etc/wireguard/wg0.conf ]]; then
            echo -e "${RED}Configuration PiVPN introuvable.${NC}"
            return 1
        fi

        return 0
    }

    # Exécution
    if check_prerequisites; then
        configure_lan_vpn_routing
    else
        echo -e "${RED}Les prérequis ne sont pas satisfaits.${NC}"
        return 1
    fi
}

# Diagnostic supplémentaire
debug_network_routing() {
    echo -e "\n${CYAN}Diagnostic réseau avancé :${NC}"
    
    # Informations détaillées sur les interfaces
    echo -e "${YELLOW}Interfaces réseau :${NC}"
    ip -br addr
    
    # Connexions actives
    echo -e "\n${YELLOW}Connexions réseau actives :${NC}"
    sudo netstat -tunapl
    
    # Règles de routage complètes
    echo -e "\n${YELLOW}Table de routage complète :${NC}"
    ip route show table all
}

# Appeler le diagnostic si nécessaire
# debug_network_routing

step11() {
    echo -e "\n${CYAN}=== Configuration du NAT et accès réseau ===${NC}"
    
    # Identifier les passerelles réseau
    echo -e "${BLUE}Détection des passerelles réseau...${NC}"
    mapfile -t gateways < <(ip route | grep default)
    
    if [[ ${#gateways[@]} -eq 0 ]]; then
        echo -e "${RED}Erreur : Aucune passerelle réseau détectée.${NC}"
        return 1
    fi
    
    # Récupérer l'adresse IP de la passerelle et l'interface principale
    gateway_ip=$(ip route | grep default | awk '{print $3}' | head -n 1)
    main_interface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    local_ip=$(ip addr show "$main_interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # Détection du port VPN
    vpn_port=""
    vpn_type=""
    
    # Vérifier Wireguard en premier
    wireguard_config_files=(
        "/etc/wireguard/"*".conf"
        "$HOME/"*".conf"
        "/etc/wireguard/wg0.conf"
    )
    
    for config in "${wireguard_config_files[@]}"; do
        if [[ -f "$config" ]]; then
            vpn_port=$(grep -m 1 "ListenPort" "$config" | awk '{print $3}')
            if [[ -n "$vpn_port" ]]; then
                vpn_type="Wireguard"
                break
            fi
        fi
    done
    
    # Si Wireguard échoue, vérifier OpenVPN
    if [[ -z "$vpn_port" ]]; then
        vpn_port=$(grep "port " /etc/openvpn/server.conf 2>/dev/null | awk '{print $2}')
        if [[ -n "$vpn_port" ]]; then
            vpn_type="OpenVPN"
        fi
    fi
    
    # Port par défaut si non trouvé
    if [[ -z "$vpn_port" ]]; then
        vpn_port="51820"  # Port Wireguard par défaut
        vpn_type="Wireguard (par défaut)"
        echo -e "${YELLOW}Port VPN par défaut utilisé : $vpn_port${NC}"
    fi
    
    # Afficher les informations de configuration
    echo -e "\n${BLUE}Informations de configuration :${NC}"
    echo "Passerelle     : $gateway_ip"
    echo "Interface      : $main_interface"
    echo "IP locale      : $local_ip"
    echo "Type VPN       : $vpn_type"
    echo "Port VPN       : $vpn_port"
    
    # Explication de la configuration NAT
    echo -e "\n${CYAN}Configuration NAT requise :${NC}"
    echo "1. Accédez à l'interface web de votre routeur"
    echo "2. Naviguez dans les paramètres de redirection de port"
    echo "3. Créez une nouvelle règle de redirection :"
    echo "   - Port externe : $vpn_port"
    echo "   - Port interne : $vpn_port"
    echo "   - Adresse IP interne : $local_ip"
    echo "   - Protocole : UDP"
    
    # Ouverture de l'interface du routeur
    read -p "Appuyez sur Entrée pour ouvrir l'interface web du routeur..." 
    xdg-open "http://$gateway_ip" 2>/dev/null
    
    # Validation de la configuration NAT
    while true; do
        read -p "Avez-vous configuré la règle NAT sur le routeur ? (O/n) : " nat_config
        
        case "${nat_config,,}" in
            o|"")
                echo "Configuration NAT confirmée."
                break
                ;;
            n)
                echo "Veuillez configurer la règle NAT avant de continuer."
                read -p "Appuyez sur Entrée pour réessayer..."
                xdg-open "http://$gateway_ip" 2>/dev/null
                ;;
            *)
                echo "Réponse invalide. Utilisez O ou N."
                ;;
        esac
    done
    
    # Sauvegarde des informations de configuration
    mkdir -p "$HOME/vpn_config"
    cat > "$HOME/vpn_config/nat_port_forwarding" << EOL
GATEWAY_IP=$gateway_ip
MAIN_INTERFACE=$main_interface
LOCAL_IP=$local_ip
VPN_TYPE=$vpn_type
VPN_PORT=$vpn_port
EOL
    
    echo -e "\n${GREEN}Configuration NAT terminée.${NC}"
    echo "Informations sauvegardées dans $HOME/vpn_config/nat_port_forwarding"
    echo
}

# Étape 12 : Gestion des utilisateurs PiVPN
step12() {
  echo -e "\n${GRAY_BLUE}=== Étape 12 : Gestion des utilisateurs PiVPN ===${NC}"
  
  # Vérifier si PiVPN est installé
  if ! command -v pivpn &> /dev/null; then
    echo -e "${LIGHT_BLUE}PiVPN n'est pas installé.${NC}"
    echo "Veuillez d'abord installer PiVPN à l'étape 9."
    return 1
  fi

  # Fonction pour envoyer un message sur Discord
  send_discord_message() {
    local message="$1"
    local webhook_file="$HOME/vpn_config/discord_webhook.txt"
    local file_path="$2"

    if [ -f "$webhook_file" ]; then
      local discord_webhook=$(cat "$webhook_file")
      
      if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        # Envoi avec fichier
        curl -F "payload_json={\"content\":\"$message\"}" \
             -F "file=@$file_path" \
             "$discord_webhook"
      else
        # Envoi simple du message
        curl -X POST "$discord_webhook" \
             -H "Content-Type: application/json" \
             -d "{\"content\":\"$message\"}"
      fi
    else
      echo "Fichier webhook Discord non trouvé."
    fi
  }
  
  # Menu de gestion des utilisateurs
  while true; do
    echo -e "\n${LIGHT_BLUE}Options de gestion des utilisateurs PiVPN :${NC}"
    echo "1. Ajouter un nouvel utilisateur"
    echo "2. Lister les utilisateurs existants"
    echo "3. Supprimer un utilisateur"
    echo "4. Exporter la configuration d'un utilisateur"
    echo "0. Retour au menu principal"
    
    read -p "Votre choix : " user_choice
    
    case "$user_choice" in
      1)
        # Ajouter un nouvel utilisateur
        while true; do
          read -p "Entrez le nom d'utilisateur (sans espaces) : " new_user
          
          # Validation du nom d'utilisateur
          if [[ "$new_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            # Vérifier si l'utilisateur existe déjà
            if [ -f "/etc/wireguard/configs/$new_user.conf" ]; then
              echo -e "${GRAY_BLUE}Un utilisateur avec ce nom existe déjà.${NC}"
              read -p "Voulez-vous choisir un autre nom ? (O/n) : " retry_choice
              
              if [[ "$retry_choice" =~ ^[Nn]$ ]]; then
                break
              fi
            else
              # Création de l'utilisateur
              echo "Création de l'utilisateur $new_user..."
              sudo pivpn -a -n "$new_user"
              
              # Attendre que la création soit terminée
              sleep 2
              
              config_dir="/etc/wireguard/configs"
              user_config="$config_dir/$new_user.conf"
              
              if [ -f "$user_config" ]; then
                # Générer un QR code temporaire
                qr_file=$(mktemp).png
                sudo pivpn -qr "$new_user" > "$qr_file"
                
                # Envoi du message et des fichiers sur Discord
                send_discord_message "Nouvel utilisateur VPN créé : $new_user" "$user_config"
                send_discord_message "QR Code pour $new_user" "$qr_file"
                
                # Nettoyer le fichier QR temporaire
                rm "$qr_file"
                
                echo -e "\n${LIGHT_BLUE}Fichier de configuration créé et envoyé sur Discord.${NC}"
              else
                echo -e "${GRAY_BLUE}Erreur : Le fichier de configuration n'a pas été créé.${NC}"
              fi
              
              break
            fi
          else
            echo "Nom d'utilisateur invalide. Utilisez uniquement des lettres, chiffres, _ et -."
          fi
        done
        ;;
      
      2)
        # Lister les utilisateurs existants
        echo -e "\n${LIGHT_BLUE}Utilisateurs PiVPN existants :${NC}"
        existing_users=$(ls /etc/wireguard/configs/*.conf 2>/dev/null | sed 's/\/etc\/wireguard\/configs\///; s/\.conf//')
        echo "$existing_users"
        
        # Envoi de la liste sur Discord
        send_discord_message "Liste des utilisateurs VPN :\n$existing_users"
        ;;
      
      3)
        # Supprimer un utilisateur
        echo -e "\n${LIGHT_BLUE}Supprimer un utilisateur PiVPN :${NC}"
        existing_users=($(ls /etc/wireguard/configs/*.conf | sed 's/\/etc\/wireguard\/configs\///; s/\.conf//'))
        
        if [ ${#existing_users[@]} -eq 0 ]; then
          echo "Aucun utilisateur existant à supprimer."
          continue
        fi
        
        echo "Utilisateurs existants :"
        for i in "${!existing_users[@]}"; do
          echo "$((i+1)). ${existing_users[i]}"
        done
        
        while true; do
          read -p "Sélectionnez l'utilisateur à supprimer (1-${#existing_users[@]}) : " delete_choice
          
          if [[ "$delete_choice" =~ ^[0-9]+$ ]] && 
             [ "$delete_choice" -ge 1 ] && 
             [ "$delete_choice" -le "${#existing_users[@]}" ]; then
            
            user_to_delete="${existing_users[$((delete_choice-1))]}"
            echo "Suppression de l'utilisateur $user_to_delete..."
            sudo pivpn -r "$user_to_delete"
            
            # Envoi d'une notification sur Discord
            send_discord_message "Utilisateur VPN supprimé : $user_to_delete"
            
            echo "Utilisateur $user_to_delete supprimé."
            break
          else
            echo "Choix invalide. Veuillez sélectionner un numéro valide."
          fi
        done
        ;;
      
      4)
        # Exporter la configuration d'un utilisateur
        echo -e "\n${LIGHT_BLUE}Exporter la configuration d'un utilisateur PiVPN :${NC}"
        existing_users=($(ls /etc/wireguard/configs/*.conf | sed 's/\/etc\/wireguard\/configs\///; s/\.conf//'))
        
        if [ ${#existing_users[@]} -eq 0 ]; then
          echo "Aucun utilisateur existant à exporter."
          continue
        fi
        
        echo "Utilisateurs existants :"
        for i in "${!existing_users[@]}"; do
          echo "$((i+1)). ${existing_users[i]}"
        done
        
        while true; do
          read -p "Sélectionnez l'utilisateur à exporter (1-${#existing_users[@]}) : " export_choice
          
          if [[ "$export_choice" =~ ^[0-9]+$ ]] && 
             [ "$export_choice" -ge 1 ] && 
             [ "$export_choice" -le "${#existing_users[@]}" ]; then
            
            user_to_export="${existing_users[$((export_choice-1 ))]}"
            export_path="$HOME/vpn_config/${user_to_export}_config.conf"
            cp "/etc/wireguard/configs/$user_to_export.conf" "$export_path"
            
            # Envoi d'une notification sur Discord avec le fichier exporté
            send_discord_message "Configuration de l'utilisateur exportée : $user_to_export" "$export_path"
            echo "Configuration de l'utilisateur $user_to_export exportée vers $export_path."
            break
          else
            echo "Choix invalide. Veuillez sélectionner un numéro valide."
          fi
        done
        ;;
      
      0)
        # Retour au menu principal
        break
        ;;
      
      *)
        echo "Choix invalide. Réessayez."
        ;;
    esac
    
    # Pause pour visualisation
    read -p "Appuyez sur Entrée pour continuer..."
  done
  
  # Sauvegarde des utilisateurs
  mkdir -p "$HOME/vpn_config"
  ls /etc/wireguard/configs/*.conf 2>/dev/null | sed 's/\/etc\/wireguard\/configs\///; s/\.conf//' > "$HOME/vpn_config/vpn_users"
  
  echo -e "\n${LIGHT_BLUE}Liste des utilisateurs sauvegardée dans $HOME/vpn_config/vpn_users${NC}"
  send_discord_message "Liste des utilisateurs sauvegardée dans $HOME/vpn_config/vpn_users"
  echo
}

# Étape 13 : Mise à jour de l'adresse IP publique PiVPN
step13() {
  echo -e "\n${GRAY_BLUE}=== Étape 13 : Mise à jour de l'adresse IP publique PiVPN ===${NC}"
  
  # Vérifier si PiVPN est installé
  if ! command -v pivpn &> /dev/null; then
    echo -e "${LIGHT_BLUE}PiVPN n'est pas installé.${NC}"
    echo "Veuillez d'abord installer PiVPN à l'étape 9."
    return 1
  fi
  
  # Récupérer l'adresse IP publique actuelle
  current_public_ip=$(curl -s ifconfig.me)
  
  # Vérifier la configuration actuelle de PiVPN
  pivpn_config="/etc/wireguard/wg0.conf"
  
  if [ ! -f "$pivpn_config" ]; then
    echo -e "${GRAY_BLUE}Fichier de configuration PiVPN introuvable.${NC}"
    return 1
  fi
  
  # Extraire l'adresse IP publique actuelle de la configuration
  old_public_ip=$(grep "Endpoint" "$pivpn_config" | awk '{print $3}' | cut -d':' -f1)
  
  echo -e "${LIGHT_BLUE}Informations actuelles :${NC}"
  echo "Adresse IP publique actuelle   : $current_public_ip"
  echo "Adresse IP configurée dans PiVPN : $old_public_ip"
  
  # Comparer les adresses IP
  if [ "$current_public_ip" == "$old_public_ip" ]; then
    echo -e "\n${GRAY_BLUE}L'adresse IP publique n'a pas changé.${NC}"
    read -p "Voulez-vous forcer la mise à jour ? (O/n) : " force_update
    
    if [[ ! "$force_update" =~ ^[Oo]$ ]]; then
      echo "Mise à jour annulée."
      return 0
    fi
  fi
  
  # Confirmer la mise à jour
  read -p "Voulez-vous mettre à jour l'adresse IP publique ? (O/n) : " confirm_update
  
  if [[ ! "$confirm_update" =~ ^[Oo]$ ]]; then
    echo "Mise à jour annulée."
    return 0
  fi
  
  # Sauvegarder la configuration originale
  sudo cp "$pivpn_config" "$pivpn_config.bak"
  
  # Mettre à jour l'adresse IP dans la configuration du serveur
  echo "Mise à jour de la configuration PiVPN..."
  sudo sed -i "s/$old_public_ip/$current_public_ip/g" "$pivpn_config"
  
  # Mettre à jour les configurations des clients
  client_configs_dir="/etc/wireguard/configs"
  
  echo "Mise à jour des configurations des clients..."
  for client_config in "$client_configs_dir"/*.conf; do
    if [ -f "$client_config" ]; then
      sudo sed -i "s/$old_public_ip/$current_public_ip/g" "$client_config"
      echo "Mise à jour de ${client_config##*/}"
    fi
  done
  
  # Redémarrer le service Wireguard
  echo "Redémarrage du service Wireguard..."
  sudo systemctl restart wg-quick@wg0
  
  # Sauvegarde des informations de mise à jour
  mkdir -p "$HOME/vpn_config"
  cat > "$HOME/vpn_config/ip_update_log" << EOL
Date de mise à jour : $(date)
Ancienne adresse IP : $old_public_ip
Nouvelle adresse IP : $current_public_ip
EOL
  
  echo -e "\n${LIGHT_BLUE}Mise à jour terminée :${NC}"
  echo "- Adresse IP mise à jour dans la configuration serveur"
  echo "- Configurations des clients mises à jour"
  echo "- Service Wireguard redémarré"
  echo "- Journal de mise à jour sauvegardé dans $HOME/vpn_config/ip_update_log"
  
  # Afficher le QR code pour les clients existants
  echo -e "\n${LIGHT_BLUE}Codes QR des configurations clients :${NC}"
  for client_config in "$client_configs_dir"/*.conf; do
    if [ -f "$client_config" ]; then
      client_name=$(basename "$client_config" .conf)
      echo "Configuration pour $client_name :"
      sudo pivpn -qr "$client_name"
      echo
    fi
  done
}

# Fonction pour gérer les étapes et le choix d'action
run_step() {
  while true; do
    step_menu
    case "$step_choice" in
      C|c) return 0 ;;
      S|s) echo "Script arrêté."; exit 0 ;;
      R|r) echo "Réexécution de l'étape actuelle."; return 1 ;;
      M|m) main_menu_flow; return 0 ;;
      *) echo "Choix invalide. Veuillez réessayer."; continue ;;
    esac
  done
}

# Fonction pour afficher la liste des étapes
display_steps() {
  echo -e "${LIGHT_BLUE}=== Liste des Étapes ===${NC}"
  echo "0. Préparation des répertoires"
  echo "1. Mise à jour des paquets"
  echo "2. Installer RustDesk"
  echo "3. Installer OpenVPN"
  echo "4. Lister les interfaces réseau"
  echo "5. Configuration IP"
  echo "6. Appliquer la configuration IP"
  echo "7. Configurer l'autologin"
  echo "8. Configurer le cronjob Discord"
  echo "9. Installer PiVPN"
  echo "10. Configurer routage et NAT VPN sur Raspberry Pi"
  echo "11. Configurer NAT et port forwarding sur routeur"
  echo "12. Gérer les utilisateurs PiVPN"
  echo "13. Mettre à jour manuellement l'adresse IP publique PiVPN"
  echo
}

# Flux principal du menu
main_menu_flow() {
  main_menu
  case "$main_choice" in
    1)
      # Démarre toutes les étapes de setup
      for i in {0..12}; do
        "step$i" || continue
        run_step || return
      done
      ;;
    2)
      # Affiche la liste des étapes et permet de choisir une étape spécifique
      display_steps
      read -p "À quelle étape souhaitez-vous aller (0-13) ? : " specific_step
      echo
      "step$specific_step" || continue
      run_step
      ;;
    0) echo "Sortie du script."; exit 0 ;;
    *) echo "Choix invalide. Retour au menu principal..."; main_menu_flow ;;
  esac
}

# Lancement du script
main_menu_flow 
