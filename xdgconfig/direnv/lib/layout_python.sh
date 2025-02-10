# Usage: layout python <python_exe>
#
# Creates and loads a virtual environment.
# You can specify the path of the virtual environment through VIRTUAL_ENV
# environment variable, otherwise it will be set to
# "$direnv_layout_dir/python-$python_version".
# For python older then 3.3 this requires virtualenv to be installed.
#
# It's possible to specify the python executable if you want to use different
# versions of python.
#
layout_python() {
  local old_env
  local python=${1:-python}
  [[ $# -gt 0 ]] && shift
  old_env=$(direnv_layout_dir)/virtualenv
  unset PYTHONHOME
  if [[ -d $old_env && $python == python ]]; then
    VIRTUAL_ENV=$old_env
  else
    local python_version ve
    # shellcheck disable=SC2046
    read -r python_version ve <<<$(echo -e 'import platform as p\ntry:\n import venv\n ve="venv"\nexcept Exception:\n try:\n  import virtualenv\n  ve="virtualenv"\n except Exception:\n  ve=""\nprint(p.python_version()+" "+ve)' | $python)
    if [[ -z $python_version ]]; then
      log_error "Could not find python's version"
      return 1
    fi

    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
      local REPLY
      realpath.absolute "$VIRTUAL_ENV"
      VIRTUAL_ENV=$REPLY
    else
      VIRTUAL_ENV=$(direnv_layout_dir)/python-$python_version
    fi
    case $ve in
    "venv")
      if [[ ! -d $VIRTUAL_ENV ]]; then
        $python -m venv "$@" "$VIRTUAL_ENV"
      fi
      ;;
    "virtualenv")
      if [[ ! -d $VIRTUAL_ENV ]]; then
        $python -m virtualenv "$@" "$VIRTUAL_ENV"
      fi
      ;;
    *)
      log_error "Error: neither venv nor virtualenv are available."
      return 1
      ;;
    esac
  fi
  export VIRTUAL_ENV
  PATH_add "$VIRTUAL_ENV/bin"
}
