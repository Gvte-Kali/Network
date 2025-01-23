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
  echo -e "${LIGHT_BLUE}[C]ontinuer à l'étape suivante | [S]topper le script | [R]efaire l'étape précédente | [M]enu principal${NC}"

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
  echo -e "\n${GRAY_BLUE}=== Étape 10 : Configuration du routage et NAT entre interfaces sur Raspberry Pi ===${NC}"
  
  echo -e "${LIGHT_BLUE}Objectif :${NC} Établir une connexion réseau entre votre interface VPN Wireguard et votre interface réseau physique."
  echo "Cette configuration permettra le routage et la traduction d'adresses (NAT)."
  echo
  
  # Détection des interfaces Wireguard
  wireguard_interfaces=($(ip -br link show | awk '$1 ~ /^wg/ {print $1}'))
  
  if [ ${#wireguard_interfaces[@]} -eq 0 ]; then
    echo -e "${GRAY_BLUE}Erreur : Aucune interface Wireguard détectée.${NC}"
    echo "Assurez-vous d'avoir configuré un tunnel Wireguard avant cette étape."
    return 1
  fi
  
  # Sélection de l'interface Wireguard
  echo "Interfaces Wireguard disponibles :"
  for i in "${!wireguard_interfaces[@]}"; do
    echo "$((i+1)). ${wireguard_interfaces[i]}"
  done
  
  while true; do
    read -p "Sélectionnez l'interface Wireguard (1-${#wireguard_interfaces[@]}) : " wg_choice
    
    if [[ "$wg_choice" =~ ^[0-9]+$ ]] && 
       [ "$wg_choice" -ge 1 ] && 
       [ "$wg_choice" -le "${#wireguard_interfaces[@]}" ]; then
      
      wireguard_interface="${wireguard_interfaces[$((wg_choice-1))]}"
      break
    else
      echo "Choix invalide. Veuillez sélectionner un numéro valide."
    fi
  done
  
  # Vérification des règles iptables existantes
  echo -e "\n${LIGHT_BLUE}Vérification des règles iptables existantes :${NC}"
  existing_nat_rules=$(sudo iptables -t nat -L POSTROUTING -v -n | grep -E "$wireguard_interface|MASQUERADE")
  
  if [ -n "$existing_nat_rules" ]; then
    echo -e "${GRAY_BLUE}Règles iptables existantes détectées :${NC}"
    echo "$existing_nat_rules"
    
    # Option de suppression des règles existantes
    while true; do
      read -p "Voulez-vous supprimer ces règles ? (O/n) : " remove_choice
      case "$remove_choice" in
        [Oo]|"")
          # Supprimer toutes les règles MASQUERADE pour cette interface
          sudo iptables -t nat -F POSTROUTING
          sudo iptables -t nat -D POSTROUTING -j MASQUERADE 2>/dev/null
          
          # Supprimer les règles spécifiques à l'interface
          sudo iptables -t nat -D POSTROUTING -o "$wireguard_interface" -j MASQUERADE 2>/dev/null
          
          echo "Règles iptables supprimées."
          break
          ;;
        [Nn])
          echo "Conservation des règles existantes."
          break
          ;;
        *)
          echo "Choix invalide. Répondez par O ou N."
          ;;
      esac
    done
  else
    echo "Aucune règle iptables existante pour cette interface."
  fi
  
  # Détection des interfaces physiques
  physical_interfaces=($(ip -br link show | awk '$2 == "UP" && $1 !~ /^(lo|wg|tun|docker|br)/ {print $1}'))
  
  echo -e "\n${LIGHT_BLUE}Interfaces réseau physiques disponibles :${NC}"
  for i in "${!physical_interfaces[@]}"; do
    echo "$((i+1)). ${physical_interfaces[i]}"
  done
  
  # Sélection de l'interface physique
  while true; do
    read -p "Sélectionnez l'interface physique pour le routage (1-${#physical_interfaces[@]}) : " phys_choice
    
    if [[ "$phys_choice" =~ ^[0-9]+$ ]] && 
       [ "$phys_choice" -ge 1 ] && 
       [ "$phys_choice" -le "${#physical_interfaces[@]}" ]; then
      
      physical_interface="${physical_interfaces[$((phys_choice-1))]}"
      break
    else
      echo "Choix invalide. Veuillez sélectionner un numéro valide."
    fi
  done
  
  # Demande du réseau Wireguard
  while true; do
    read -p "Entrez le réseau Wireguard (format CIDR, e.g., 10.0.0.0/24) : " wireguard_network
    
    if [[ "$wireguard_network" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
      break
    else
      echo "Format de réseau invalide. Utilisez le format x.x.x.x/xx"
    fi
  done
  
  # Configuration du routage et NAT
  echo -e "\n${LIGHT_BLUE}Configuration du routage et NAT :${NC}"
  
  # Activer le forwarding IP
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo bash -c "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
  
  # Configurer le NAT avec masquerade
  sudo iptables -t nat -A POSTROUTING -s "$wireguard_network" -o "$physical_interface" -j MASQUERADE
  
  # Sauvegarder les règles iptables de manière permanente
  sudo apt-get install -y iptables-persistent
  sudo netfilter-persistent save
  
  # Sauvegarde de la configuration
  mkdir -p "$HOME/vpn_config"
  cat > "$HOME/vpn_config/nat_routing_config" << EOL
WIREGUARD_INTERFACE=$wireguard_interface
PHYSICAL_INTERFACE=$physical_interface
WIREGUARD_NETWORK=$wireguard_network
EOL
  
  echo -e "\n${GRAY_BLUE}Résumé de la configuration :${NC}"
  echo "Interface Wireguard : $wireguard_interface"
  echo "Interface physique  : $physical_interface"
  echo "Réseau Wireguard   : $wireguard_network"
  echo "Statut             : Routage et NAT configurés"
  
  echo -e "\n${LIGHT_BLUE}IMPORTANT :${NC}"
  echo "- Le routage entre les interfaces est maintenant activé"
  echo "- La traduction d'adresses (NAT) est configurée"
  echo "- Les connexions du réseau Wireguard seront masquerades sur l'interface physique"
  
  echo "Configuration terminée."
  echo
}

# Étape 11 : Configuration du NAT et accès à l'interface web
step11() {
  echo -e "\n${GRAY_BLUE}=== Étape 11 : Configuration du NAT routeur et accès à l'interface web ===${NC}"
  
  # Identifier les passerelles réseau
  echo -e "${LIGHT_BLUE}Passerelles réseau actuelles :${NC}"
  gateways=$(ip route | grep default)
  
  if [ -z "$gateways" ]; then
    echo "Aucune passerelle réseau détectée."
    return 1
  fi
  
  # Afficher les passerelles
  echo "$gateways"
  
  # Récupérer l'adresse IP de la passerelle
  gateway_ip=$(ip route | grep default | awk '{print $3}')
  
  # Récupérer l'interface réseau principale
  main_interface=$(ip route | grep default | awk '{print $5}')
  
  # Récupérer l'adresse IP locale
  local_ip=$(ip addr show "$main_interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  
  # Vérifier la configuration PiVPN
  pivpn_port=$(grep "port " /etc/openvpn/server.conf | awk '{print $2}')
  
  if [ -z "$pivpn_port" ]; then
    echo "Impossible de déterminer le port PiVPN."
    pivpn_port="NUMÉRO_DE_PORT"
  fi
  
  # Afficher les informations de configuration
  echo -e "\n${LIGHT_BLUE}Informations de configuration :${NC}"
  echo "Passerelle     : $gateway_ip"
  echo "Interface      : $main_interface"
  echo "IP locale      : $local_ip"
  echo "Port PiVPN     : $pivpn_port"
  
  # Explication de la configuration NAT
  echo -e "\n${GRAY_BLUE}Configuration NAT requise :${NC}"
  echo "1. Accédez à l'interface web de votre routeur"
  echo "2. Naviguez dans les paramètres de redirection de port (Port Forwarding ou NAT)"
  echo "3. Créez une nouvelle règle de redirection avec les paramètres suivants :"
  echo "   - Port externe : $pivpn_port"
  echo "   - Port interne : $pivpn_port"
  echo "   - Adresse IP interne : $local_ip"
  echo "   - Protocole : UDP"
  
  # Attente de confirmation
  read -p "Appuyez sur Entrée pour ouvrir l'interface web du routeur..."
  
  # Ouvrir l'interface web du routeur
  xdg-open "http://$gateway_ip"
  
  # Attente de validation
  while true; do
    read -p "Avez-vous configuré la règle NAT sur le routeur ? (y/n) : " nat_config
    
    case "$nat_config" in
      [Yy]|"")
        echo "Configuration NAT confirmée."
        break
        ;;
      [Nn])
        echo "Veuillez configurer la règle NAT avant de continuer."
        read -p "Appuyez sur Entrée pour réessayer..."
        xdg-open "http://$gateway_ip"
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
PIVPN_PORT=$pivpn_port
EOL
  
  echo -e "\n${LIGHT_BLUE}Configuration NAT terminée.${NC}"
  echo "Les informations ont été sauvegardées dans $HOME/vpn_config/nat_port_forwarding"
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