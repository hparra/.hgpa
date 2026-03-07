zmodload zsh/datetime
_hgpa_start=${EPOCHREALTIME}

# Files to skip when auto-sourcing
_hgpa_ignore=(
  init.zsh
  nvm-quick.zsh
)

for f in "${HOME}"/.hgpa/**/*.zsh(N); do
  local name="${f:t}"
  (( ${_hgpa_ignore[(Ie)$name]} )) && continue
  . "$f"
done
unset f _hgpa_ignore

_hgpa_ms=$(( (EPOCHREALTIME - _hgpa_start) * 1000 ))
echo "\033[2m🐋 \033[0m\033[1m.hgpa \033[0m\033[2m(latency: ${_hgpa_ms%.*}ms)\033[0m" >&2
unset _hgpa_start _hgpa_ms
