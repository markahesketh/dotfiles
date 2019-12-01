# Load .profile
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Local config
[[ -f ~/.bash_profile.local ]] && source ~/.bash_profile.local

##
# Your previous /Users/mhesketh/.bash_profile file was backed up as /Users/mhesketh/.bash_profile.macports-saved_2019-04-08_at_14:34:07
##

# fnm
if [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(fnm env --multi)"
    export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
fi