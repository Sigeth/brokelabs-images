# Kubernetes shell defaults of the workstation: completion for kubectl (and
# its usual alias k) and helm, and vim for kubectl edit.
if [ -n "${BASH_VERSION:-}" ]; then
  [ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
  # kubectl's completion loads on first use: load it now for the alias.
  [ -r /usr/share/bash-completion/completions/kubectl ] && . /usr/share/bash-completion/completions/kubectl
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi
export EDITOR="${EDITOR:-vim}"
