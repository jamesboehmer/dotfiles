export_function() {
  local alias_dir=$PWD/.direnv/aliases
  mkdir -p "$alias_dir"
  PATH_add "$alias_dir"
  for name in ${@}; do
    local name=$1
    local target="$alias_dir/$name"
    if declare -f "$name" >/dev/null; then
      echo "#!/usr/bin/env ${SHELL}" > "$target"
      declare -f "$name" >> "$target" 2>/dev/null
      echo "$name \${@}" >> "$target"
      chmod +x "$target"
    fi
  done
}
