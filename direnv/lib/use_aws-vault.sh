use_aws-vault() {
# Usage: use aws-vault <profile>
#
# Invokes aws-vault to create  AWS environment variables for the specified profile.
# The environment variables are stored in a file under the direnv layout directory.
    has aws-vault || { log_error "aws-vault is not installed" && return 1; }
    [[ $# -lt 1 ]] && log_error "Usage: aws-vault <profile>" && return 1;
    profile=$1;
    DIRENV_LAYOUT_DIR="$(direnv_layout_dir)";
    mkdir -p "${DIRENV_LAYOUT_DIR}/aws-vault";
    ENVFILE="${DIRENV_LAYOUT_DIR}/aws-vault/${profile}.env";
    touch "${ENVFILE}";
    chmod 600 "${ENVFILE}";
    # eval "$(aws-vault export --format=export-env "${profile}")";
    aws-vault export --format=export-env "${profile}" >"${ENVFILE}";
    source_env_if_exists "${ENVFILE}";
}