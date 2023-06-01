# Usage: use nodenv <node version number>
#
# Example:
#
#    use nodenv 15.2.1
#
# Uses nodenv, use_node and layout_node to add the chosen node version and 
# "$PWD/node_modules/.bin" to the PATH
#
use_nodenv() {
  local node_version="${1}"
  local node_versions_dir
  local nodenv_version
  node_versions_dir="$(nodenv root)/versions"
  nodenv_version="${node_versions_dir}/${node_version}"
  if [[ -e "$nodenv_version" ]]; then
      # Put the selected node version in the PATH
      NODE_VERSIONS="${node_versions_dir}" NODE_VERSION_PREFIX="" use_node "${node_version}"
      # Add $PWD/node_modules/.bin to the PATH
      layout_node
  else
    log_error "nodenv: version '$node_version' not installed.  Use \`nodenv install ${node_version}\` to install it first."
    return 1
  fi
}
