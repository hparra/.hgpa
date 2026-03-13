zmodload zsh/datetime
_hgpa_start=${EPOCHREALTIME}

for f in "${HOME}"/.hgpa/shell/**/*.zsh(N); do
  local name="${f:t}"
  [[ "$name" == "init.zsh" || "$name" == "nvm-quick.zsh" ]] && continue
  . "$f"
done

for f in "${HOME}"/.hgpa/commands/**/*.zsh(N); do
  . "$f"
done

unset f

_hgpa_ms=$(( (EPOCHREALTIME - _hgpa_start) * 1000 ))
echo "\033[2m🐋 \033[0m\033[1m.hgpa \033[0m\033[2m(latency: ${_hgpa_ms%.*}ms)\033[0m" >&2
unset _hgpa_start _hgpa_ms
