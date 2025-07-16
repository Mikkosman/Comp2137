#!/bin/bash

# Step 1: Create users with bash shell and home directories
echo "Creating user accounts..."

user_list=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)

for user in "${user_list[@]}"; do
    if id "$user" &>/dev/null; then
        echo "User $user already exists. Skipping..."
    else
        echo "Creating user $user..."
        useradd -m -s /bin/bash "$user"
        if [[ "$user" == "dennis" ]]; then
            echo "Adding $user to sudo group..."
            usermod -aG sudo "$user"
        fi
    fi
done

echo "User creation step completed."
echo "Generating SSH keys and setting up authorized_keys..."

instructor_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for user in "${user_list[@]}"; do
    home_dir="/home/$user"
    ssh_dir="$home_dir/.ssh"
    rsa_key="$ssh_dir/id_rsa"
    ed_key="$ssh_dir/id_ed25519"
    auth_keys="$ssh_dir/authorized_keys"

    # Ensure .ssh directory exists with correct permissions
    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chown "$user:$user" "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    # Generate RSA key if not exists
    if [ ! -f "$rsa_key" ]; then
        sudo -u "$user" ssh-keygen -t rsa -b 2048 -f "$rsa_key" -N ""
    fi

    # Generate ED25519 key if not exists
    if [ ! -f "$ed_key" ]; then
        sudo -u "$user" ssh-keygen -t ed25519 -f "$ed_key" -N ""
    fi

    # Initialize authorized_keys if not present
    touch "$auth_keys"
    chmod 600 "$auth_keys"
    chown "$user:$user" "$auth_keys"

    # Add public keys to authorized_keys (only if not already present)
    for pubkey in "$rsa_key.pub" "$ed_key.pub"; do
        grep -q -f "$pubkey" "$auth_keys" || cat "$pubkey" >> "$auth_keys"
    done

    # For dennis, add instructor key if not present
    if [ "$user" == "dennis" ]; then
        grep -qF "$instructor_key" "$auth_keys" || echo "$instructor_key" >> "$auth_keys"
    fi
done

echo "SSH key configuration completed."
echo "Configuring Netplan network settings..."

# Set target IP and interface name
TARGET_IP="192.168.16.21/24"
NETPLAN_FILE=$(find /etc/netplan -name '*.yaml' | head -n 1)

# Get interface connected to 192.168.16 network
TARGET_IF=$(ip -o -4 addr show | awk '/192\.168\.16/ {print $2; exit}')

if [ -z "$TARGET_IF" ]; then
    echo "Error: Could not detect the correct interface for 192.168.16"
    exit 1
fi

# Backup original netplan file
cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"

# Write new netplan config (excluding mgmt interface)
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    $TARGET_IF:
      dhcp4: no
      addresses: [$TARGET_IP]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF

# Apply Netplan changes
netplan apply && echo "Netplan applied successfully." || echo "Netplan failed."
echo "Updating /etc/hosts..."

# Remove any outdated entries for server1
sed -i '/\sserver1$/d' /etc/hosts

# Add new correct mapping
echo "192.168.16.21 server1" >> /etc/hosts

echo "/etc/hosts updated successfully."
echo "Installing apache2 and squid..."

# Update package list
apt update -y

# Install apache2 if not already installed
if ! dpkg -l | grep -qw apache2; then
    echo "Installing apache2..."
    apt install -y apache2
else
    echo "apache2 is already installed."
fi

# Install squid if not already installed
if ! dpkg -l | grep -qw squid; then
    echo "Installing squid..."
    apt install -y squid
else
    echo "squid is already installed."
fi

# Enable and start services
systemctl enable apache2 --now
systemctl enable squid --now

# Check service status
echo ""
echo "Service Status:"
systemctl is-active apache2 && echo "✔ apache2 is running." || echo "❌ apache2 failed to start."
systemctl is-active squid && echo "✔ squid is running." || echo "❌ squid failed to start."
