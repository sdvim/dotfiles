function npm_backup
  set dir (npm get prefix)
  npm list --global --parseable --depth=0 | sed '1d' | awk -v DIR="$dir/lib/node_modules/" '{gsub(DIR,"",$1); print}' > .config/npm/global-packages
end