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
