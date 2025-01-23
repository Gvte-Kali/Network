#!/bin/bash

# Récupérer l'utilisateur actuel
CURRENT_USER=$(whoami)

# Chemins des fichiers de configuration
OPENVPN_CONFIG="/etc/openvpn/server/server.conf"
CLIENT_CONFIGS_DIR="/home/$CURRENT_USER/ovpns"
VPN_CONFIG_DIR="$HOME/vpn_config"
LOG_FILE="$VPN_CONFIG_DIR/ip_change_log.txt"

# Créer le répertoire de logs s'il n'existe pas
mkdir -p "$VPN_CONFIG_DIR"

# Fonction pour obtenir l'adresse IPv4 publique
get_ipv4() {
    # Plusieurs méthodes pour obtenir l'IPv4
    local ipv4_methods=(
        "curl -4 -s ifconfig.me"
        "curl -4 -s ipv4.icanhazip.com"
        "curl -4 -s ipinfo.io/ip"
        "dig +short myip.opendns.com @resolver1.opendns.com"
    )
    
    for method in "${ipv4_methods[@]}"; do
        local ip=$(${method})
        # Validation basique de l'IPv4
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    echo "Impossible de déterminer l'IPv4" >> "$LOG_FILE"
    return 1
}

# Fonction pour envoyer un message sur Discord
send_discord_message() {
    local message="$1"
    local webhook_file="$VPN_CONFIG_DIR/discord_webhook.txt"
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
        echo "$(date): Fichier webhook Discord non trouvé." >> "$LOG_FILE"
    fi
}

# Récupérer l'adresse IP publique IPv4 actuelle
current_public_ip=$(get_ipv4)

# Vérifier si le fichier de configuration OpenVPN existe
if [ ! -f "$OPENVPN_CONFIG" ]; then
    echo "$(date): Erreur : Fichier de configuration OpenVPN introuvable." >> "$LOG_FILE"
    exit 1
fi

# Vérifier si le répertoire des configurations clients existe
if [ ! -d "$CLIENT_CONFIGS_DIR" ]; then
    echo "$(date): Erreur : Répertoire des configurations clients introuvable." >> "$LOG_FILE"
    exit 1
fi

# Créer un répertoire temporaire pour stocker les nouveaux fichiers
temp_config_dir=$(mktemp -d)

# Préparer un zip avec tous les fichiers de configuration des clients
echo "$(date): Préparation des fichiers de configuration des clients..." >> "$LOG_FILE"
zip_file="$temp_config_dir/vpn_user_configs.zip"
zip -j "$zip_file" "$CLIENT_CONFIGS_DIR"/*.ovpn

# Vérifier si des fichiers ont été ajoutés au zip
if [ ! -f "$zip_file" ]; then
    echo "$(date): Aucun fichier de configuration client trouvé." >> "$LOG_FILE"
    rm -rf "$temp_config_dir"
    exit 1
fi

# Préparer le message Discord
message="🌐 Mise à jour de l'adresse IP publique\n"
message+="👤 Utilisateur : $CURRENT_USER\n"
message+="📍 Nouvelle adresse IP : $current_public_ip\n"
message+="📅 Date : $(date)\n"
message+="📦 Fichiers de configuration des utilisateurs VPN joints."

# Envoyer le message et les fichiers sur Discord
send_discord_message "$message" "$zip_file"

# Sauvegarder les informations de mise à jour
cat > "$VPN_CONFIG_DIR/ip_update_log" << EOL
Date de mise à jour : $(date)
Utilisateur : $CURRENT_USER
Nouvelle adresse IP : $current_public_ip
EOL

# Nettoyer les fichiers temporaires
rm -rf "$temp_config_dir"

echo "$(date): Mise à jour terminée avec succès." >> "$LOG_FILE"
