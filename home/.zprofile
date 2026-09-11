# /etc/zprofile has just run path_helper, which demotes everything .zshenv set
# below /usr/bin. Reapply it (idempotent - path is typeset -U).
source ~/.zshenv

[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
