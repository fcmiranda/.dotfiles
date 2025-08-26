# yq - YAML/JSON/XML processor
export PATH="$HOME/.local/bin:$PATH"

# Useful aliases for different output formats
alias yq-json='yq -o json'
alias yq-yaml='yq -o yaml'
alias yq-xml='yq -o xml'
alias yq-pretty='yq -P'

# Common yq operations
alias yq-keys='yq "keys"'
alias yq-length='yq "length"'

# YAML validation
alias yaml-validate='yq eval "." --exit-status'
alias json-validate='yq -p json eval "." --exit-status'
