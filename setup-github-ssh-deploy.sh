#!/usr/bin/env bash
#
# setup-github-ssh-deploy.sh
#
# Sets up an SSH key for GitHub, verifies the connection, then (optionally)
# deploys your project by pulling latest / restarting a service.
#
# Usage:
#   ./setup-github-ssh-deploy.sh
#
# You will be prompted for:
#   - Your email (used as a comment on the SSH key)
#   - Whether to run a deploy step after the connection check succeeds
#
set -euo pipefail

# ---------- Config (edit as needed) ----------
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519_github"
GIT_REPO_DIR="${GIT_REPO_DIR:-$(pwd)}"     # directory of the git repo to deploy
GIT_BRANCH="${GIT_BRANCH:-main}"           # branch to pull/deploy
DEPLOY_CMD="${DEPLOY_CMD:-}"               # e.g. "docker compose up -d --build" or "./deploy.sh"
# ----------------------------------------------

log()  { printf '\n\033[1;34m[*] %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m[OK] %s\033[0m\n' "$1"; }
err()  { printf '\033[1;31m[ERROR] %s\033[0m\n' "$1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Required command '$1' not found. Please install it first."; exit 1; }
}

require_cmd ssh
require_cmd ssh-keygen
require_cmd ssh-agent
require_cmd git

# ---------- Step 1: Generate SSH key (if needed) ----------
log "Checking for existing SSH key at ${SSH_KEY_PATH}"
if [ -f "${SSH_KEY_PATH}" ]; then
  ok "SSH key already exists, skipping generation."
else
  read -rp "Enter the email to associate with your new SSH key: " USER_EMAIL
  log "Generating a new ed25519 SSH key..."
  ssh-keygen -t ed25519 -C "${USER_EMAIL}" -f "${SSH_KEY_PATH}" -N ""
  ok "Key generated at ${SSH_KEY_PATH}"
fi

# ---------- Step 2: Start ssh-agent and add key ----------
log "Starting ssh-agent and adding key"
eval "$(ssh-agent -s)" >/dev/null
ssh-add "${SSH_KEY_PATH}"
ok "Key added to ssh-agent"

# ---------- Step 3: Configure ~/.ssh/config for github.com ----------
SSH_CONFIG="${HOME}/.ssh/config"
touch "${SSH_CONFIG}"
if ! grep -q "Host github.com" "${SSH_CONFIG}" 2>/dev/null; then
  log "Adding github.com entry to ${SSH_CONFIG}"
  {
    echo ""
    echo "Host github.com"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile ${SSH_KEY_PATH}"
    echo "  IdentitiesOnly yes"
  } >> "${SSH_CONFIG}"
  chmod 600 "${SSH_CONFIG}"
  ok "SSH config updated"
else
  ok "github.com already present in SSH config, skipping"
fi

# ---------- Step 4: Show the public key for the user to add to GitHub ----------
log "Your public key (add this to GitHub -> Settings -> SSH and GPG keys):"
echo "-------------------------------------------------------------------"
cat "${SSH_KEY_PATH}.pub"
echo "-------------------------------------------------------------------"
read -rp "Press Enter once you've added this key to your GitHub account..."

# ---------- Step 5: Test the connection ----------
log "Testing SSH connection to GitHub..."
set +e
SSH_TEST_OUTPUT=$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)
set -e

if echo "${SSH_TEST_OUTPUT}" | grep -q "successfully authenticated"; then
  ok "GitHub SSH connection verified:"
  echo "${SSH_TEST_OUTPUT}"
else
  err "GitHub SSH connection failed. Output was:"
  echo "${SSH_TEST_OUTPUT}"
  exit 1
fi

# ---------- Step 6: Deploy ----------
read -rp $'\nRun deploy step now? (y/N): ' RUN_DEPLOY
if [[ "${RUN_DEPLOY}" =~ ^[Yy]$ ]]; then
  if [ ! -d "${GIT_REPO_DIR}/.git" ]; then
    err "'${GIT_REPO_DIR}' is not a git repository. Set GIT_REPO_DIR env var to the correct path."
    exit 1
  fi

  log "Pulling latest changes in ${GIT_REPO_DIR} (branch: ${GIT_BRANCH})"
  git -C "${GIT_REPO_DIR}" fetch origin
  git -C "${GIT_REPO_DIR}" checkout "${GIT_BRANCH}"
  git -C "${GIT_REPO_DIR}" pull origin "${GIT_BRANCH}"
  ok "Repo updated"

  if [ -n "${DEPLOY_CMD}" ]; then
    log "Running deploy command: ${DEPLOY_CMD}"
    (cd "${GIT_REPO_DIR}" && eval "${DEPLOY_CMD}")
    ok "Deploy command finished"
  else
    log "No DEPLOY_CMD set — skipping the actual deploy command."
    echo "  Set it like: DEPLOY_CMD='./deploy.sh' $0"
    echo "  or edit the DEPLOY_CMD variable at the top of this script."
  fi
else
  log "Skipping deploy step."
fi

ok "Done."
