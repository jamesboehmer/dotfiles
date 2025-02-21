# Usage: layout uv <python version number>
#
# Example:
#
#    layout uv cpython-3.11.11-linux-aarch64-gnu
#    layout uv cpython-3.12
#    layout uv v3.10.16
#    layout uv 3.10
#
# Uses uv create and load a virtual environment.
# "$direnv_layout_dir/uv/$python_version".
#
layout_uv() {
  if ! has uv; then
      log_error "uv is not installed"
      return 1
  fi
  local uv_version="${1}";
  local uv_layout_path="$(direnv_layout_dir)/uv/${uv_version}";
  if [[ ! -x "${uv_layout_path}" ]]; then
    if ! uv -q --no-config venv -p ${uv_version} "${uv_layout_path}"; then
      log_error "uv venv failed";
      return 1
    fi
  fi
  export VIRTUAL_ENV="$(readlink -f ${uv_layout_path})";
  export UV_PROJECT_ENVIRONMENT="${VIRTUAL_ENV}";
  export UV_PYTHON="${VIRTUAL_ENV}/bin/python";
  PATH_add "${VIRTUAL_ENV}/bin";
}
