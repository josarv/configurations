#!/usr/bin/env bash

set -e

VERBOSE=false

# parse arguments
for arg in "$@"; do
  case $arg in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
  esac
done

# loggers
log_info() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
    fi
}

log_done() {
    if [ "$VERBOSE" = true ]; then
        echo "[OK] $1"
    fi
}

log_error() {
    echo "[ERROR] $1" >&2
}

# command wrapper
run_wrapper() {
    local cmd_name="$1"
    shift
    if [ "$VERBOSE" = true ]; then
        if output="$("$@" 2>&1)"; then  # capture output
            return 0
        else
            log_error "Command '$cmd_name' failed."
            echo "$output"
            return 1
        fi
    else
        "$@"  # just run the command
    fi
}

# install poetry if not present
if ! command -v poetry &> /dev/null; then
    log_info "Poetry not found. Installing via pipx..."
    pipx install poetry
    log_done "Poetry installed."
else
    log_info "Poetry is already installed."
fi

# install dependencies based on available files
if [ -f "poetry.lock" ]; then
    log_info "Detected 'poetry.lock'. Installing via Poetry..."
    poetry config virtualenvs.create false # install into system python container
    poetry install --no-interaction --no-ansi
    og_done "Dependencies installed via Poetry."
elif [ -f "pyproject.toml" ]; then
    log_info "Detected 'pyproject.toml' (no lock file). Installing editable..."
    pip install -e .[dev]
    log_done "Project installed in editable mode."
elif [ -f "requirements.txt" ]; then
    log_info "Detected 'requirements.txt'. Installing via pip..."
    pip install -r requirements.txt
    log_done "Dependencies installed via pip."
else
    log_info "No dependency files found. Skipping installation."
fi
