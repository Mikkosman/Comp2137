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
