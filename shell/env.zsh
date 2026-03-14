# Editor
# EDITOR is used by CLI tools (git, crontab, etc.) for text input.
# VISUAL is preferred by full-screen programs; falls back to EDITOR if unset.
export EDITOR="vi"
export VISUAL="$EDITOR"

# Locale
# Ensures consistent character encoding and language settings across machines.
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
