# Load .profile
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Local config
[[ -f ~/.bash_profile.local ]] && source ~/.bash_profile.local

# fnm
if [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(fnm env --multi)"
fi