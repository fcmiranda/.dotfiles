# Obsidian - Knowledge base and note-taking app
export PATH="$HOME/.local/bin:$PATH"

# Obsidian aliases for convenience
alias obs='obsidian'
alias notes='obsidian'

# Function to open Obsidian with a specific vault
obsidian-vault() {
  if [ $# -eq 0 ]; then
    echo "Usage: obsidian-vault <vault-path>"
    echo "Example: obsidian-vault ~/Documents/MyVault"
    return 1
  fi
  obsidian "$1" &
  disown
}

# Function to create a new vault
obsidian-new-vault() {
  if [ $# -eq 0 ]; then
    echo "Usage: obsidian-new-vault <vault-name> [path]"
    echo "Example: obsidian-new-vault MyVault ~/Documents"
    return 1
  fi
  
  local vault_name="$1"
  local vault_path="${2:-$HOME/Documents}/$vault_name"
  
  if [ -d "$vault_path" ]; then
    echo "Vault directory already exists: $vault_path"
    return 1
  fi
  
  mkdir -p "$vault_path"
  echo "# $vault_name" > "$vault_path/README.md"
  echo "Created new Obsidian vault at: $vault_path"
  obsidian "$vault_path" &
  disown
}
