#!/bin/bash

# Chemins des fichiers de configuration
PIVPN_CONFIG="/etc/wireguard/wg0.conf"
CLIENT_CONFIGS_DIR="/etc/wireguard/configs"
VPN_CONFIG_DIR="$HOME/vpn_config"
LOG_FILE="$VPN_CONFIG_DIR/ip_change_log.txt"

# Créer le répertoire de logs s'il n'existe pas
mkdir -p "$VPN_CONFIG_DIR"

# Récupérer l'adresse IP publique actuelle
current_public_ip=$(curl -s ifconfig.me)

# Vérifier si le fichier de configuration PiVPN existe
if [ ! -f "$PIVPN_CONFIG" ]; then
    echo "$(date): Erreur : Fichier de configuration PiVPN introuvable." >> "$LOG_FILE"
    exit 1
fi

# Extraire l'adresse IP publique actuelle de la configuration
old_public_ip=$(grep "Endpoint" "$PIVPN_CONFIG" | awk '{print $3}' | cut -d':' -f1)

# Vérifier si l'adresse IP a changé
if [ "$current_public_ip" == "$old_public_ip" ]; then
    echo "$(date): Adresse IP publique inchangée. Aucune action requise." >> "$LOG_FILE"
    exit 0
fi

# Sauvegarder la configuration originale
sudo cp "$PIVPN_CONFIG" "$PIVPN_CONFIG.bak"

# Créer un répertoire temporaire pour stocker les nouveaux fichiers
temp_config_dir=$(mktemp -d)

# Mettre à jour l'adresse IP dans la configuration du serveur
echo "$(date): Mise à jour de la configuration du serveur PiVPN..." >> "$LOG_FILE"
sudo sed -i "s/$old_public_ip/$current_public_ip/g" "$PIVPN_CONFIG"

# Mettre à jour les configurations des clients
echo "$(date): Mise à jour des configurations des clients..." >> "$LOG_FILE"
for client_config in "$CLIENT_CONFIGS_DIR"/*.conf; do
    if [ -f "$client_config" ]; then
        client_name=$(basename "$client_config" .conf)
        
        # Copier et mettre à jour le fichier de configuration
        cp "$client_config" "$temp_config_dir/${client_name}_new.conf"
        sed -i "s/$old_public_ip/$current_public_ip/g" "$temp_config_dir/${client_name}_new.conf"
        
        echo "$(date): Mise à jour de la configuration pour $client_name" >> "$LOG_FILE"
    fi
done

# Redémarrer le service Wireguard
echo "$(date): Redémarrage du service Wireguard..." >> "$LOG_FILE"
sudo systemctl restart wg-quick@wg0

# Préparer l'envoi sur Discord
if [ -f "$VPN_CONFIG_DIR/discord_webhook.txt" ]; then
    discord_webhook=$(cat "$VPN_CONFIG_DIR/discord_webhook.txt")
    
    # Créer un message avec les fichiers de configuration
    message="New IP Address : $current_public_ip, here are the new vpn user files."
    
    # Préparer les fichiers pour l'envoi
    zip_file="$temp_config_dir/vpn_user_configs.zip"
    zip -j "$zip_file" "$temp_config_dir"/*.conf
    
    # Envoyer le message et les fichiers sur Discord
    curl -F "payload_json={\"content\":\"$message\"}" \
         -F "file=@$zip_file" \
         "$discord_webhook"
else
    echo "$(date): Fichier webhook Discord non trouvé." >> "$LOG_FILE"
fi

# Nettoyer les fichiers temporaires
rm -rf "$temp_config_dir"

# Sauvegarder les informations de mise à jour
cat > "$VPN_CONFIG_DIR/ip_update_log" << EOL
Date de mise à jour : $(date)
Ancienne adresse IP : $old_public_ip
Nouvelle adresse IP : $current_public_ip
EOL

echo "$(date): Mise à jour terminée avec succès." >> "$LOG_FILE"
