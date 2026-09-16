if ! pkg_is_installed mmdc; then
  if command -v npm &>/dev/null; then
    npm install -g @mermaid-js/mermaid-cli
  elif command -v yay &>/dev/null; then
    pkg_install mermaid-cli
  fi
fi
