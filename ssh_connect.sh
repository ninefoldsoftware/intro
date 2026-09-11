```bash
#!/usr/bin/env bash

set -e

# ==========================================
# GitHub SSH Setup Script
# ==========================================

KEY_NAME="id_ed25519_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
SSH_CONFIG="$HOME/.ssh/config"

echo "=========================================="
echo " GitHub SSH Setup"
echo "=========================================="

# ------------------------------------------
# 1. Check required commands
# ------------------------------------------

for cmd in ssh ssh-keygen git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' is not installed."
        exit 1
    fi
done

# ------------------------------------------
# 2. Create ~/.ssh
# ------------------------------------------

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ------------------------------------------
# 3. Generate SSH key if it doesn't exist
# ------------------------------------------

if [ -f "$KEY_PATH" ]; then
    echo
    echo "SSH key already exists:"
    echo "  $KEY_PATH"
else
    echo
    echo "Generating ED25519 SSH key..."

    read -rp "Enter your GitHub email: " GITHUB_EMAIL

    if [ -z "$GITHUB_EMAIL" ]; then
        echo "ERROR: Email cannot be empty."
        exit 1
    fi

    ssh-keygen \
        -t ed25519 \
        -C "$GITHUB_EMAIL" \
        -f "$KEY_PATH"

    echo "SSH key generated."
fi

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# ------------------------------------------
# 4. Start ssh-agent
# ------------------------------------------

echo
echo "Starting ssh-agent..."

eval "$(ssh-agent -s)" >/dev/null

# ------------------------------------------
# 5. Add SSH key to agent
# ------------------------------------------

ssh-add "$KEY_PATH"

# ------------------------------------------
# 6. Configure ~/.ssh/config
# ------------------------------------------

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if ! grep -q "Host github.com" "$SSH_CONFIG"; then

    cat >> "$SSH_CONFIG" <<EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF

    echo "GitHub SSH configuration added."
else
    echo "GitHub SSH configuration already exists."
fi

# ------------------------------------------
# 7. Display public key
# ------------------------------------------

echo
echo "=========================================="
echo " Your GitHub SSH Public Key"
echo "=========================================="
echo

cat "$KEY_PATH.pub"

echo
echo "=========================================="
echo " Next step"
echo "=========================================="
echo
echo "Copy the key above and add it to:"
echo
echo "GitHub → Settings → SSH and GPG keys"
echo
echo "Then press Enter to test the connection."
read -r

# ------------------------------------------
# 8. Test GitHub connection
# ------------------------------------------

echo
echo "Testing GitHub SSH connection..."
echo

ssh -T -o StrictHostKeyChecking=accept-new git@github.com || true

echo
echo "=========================================="
echo " Setup complete"
echo "=========================================="
echo
echo "You can test again with:"
echo
echo "    ssh -T git@github.com"
echo
echo "For Git repositories, use:"
echo
echo "    git@github.com:USERNAME/REPOSITORY.git"
echo
```

