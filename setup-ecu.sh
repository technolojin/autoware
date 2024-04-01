#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
ansible_args=()

while [ "$1" != "" ]; do
    case "$1" in
    -e)
        # extra vars
        ansible_args+=("--extra-vars" "$2")
        ;;
    -v)
        # Enable debug outputs.
        option_verbose=true
        ;;
    -y)
        # Use non-interactive mode.
        option_yes=true
        ;;
    esac
    shift
done

# Check yes Option
if [ "$option_yes" = "true" ]; then
    echo -e "\e[36mRun the setup in non-interactive mode.\e[m"
else
    read -rp ">  Are you sure you want to run setup? [y/N] " answer

    # Check whether to cancel
    if ! [[ ${answer:0:1} =~ y|Y ]]; then
        echo -e "\e[33mCancelled.\e[0m"
        exit 1
    fi

    ansible_args+=("--ask-become-pass")
fi

# Check verbose option
if [ "$option_verbose" = "true" ]; then
    ansible_args+=("-vvv")
fi

# Install sudo
if ! (command -v sudo >/dev/null 2>&1); then
    apt-get -y update
    apt-get -y install sudo
fi

# Install git
if ! (command -v git >/dev/null 2>&1); then
    sudo apt-get -y update
    sudo apt-get -y install git
fi

# Install pip for ansible
if ! (python3 -m pip --version >/dev/null 2>&1); then
    sudo apt-get -y update
    sudo apt-get -y install python3-pip python3-venv
fi

# Install pipx for ansible
if ! (python3 -m pipx --version >/dev/null 2>&1); then
    sudo apt-get -y update
    python3 -m pip install --user pipx
fi

# Install ansible
python3 -m pipx ensurepath
export PATH="${PIPX_BIN_DIR:=$HOME/.local/bin}:$PATH"
pipx install --include-deps --force "ansible==6.*"

# Install ansible collections
echo -e "\e[36m"ansible-galaxy collection install -f -r "$SCRIPT_DIR/ansible-galaxy-requirements.yaml" "\e[m"
ansible-galaxy collection install -f -r "$SCRIPT_DIR/ansible-galaxy-requirements.yaml"

# Run ansible
echo -e "\e[36m"ansible-playbook ./ansible/playbooks/ecu_setup.yaml "${ansible_args[@]}" "\e[m"
if ansible-playbook "$SCRIPT_DIR/ansible/playbooks/ecu_setup.yaml" "${ansible_args[@]}"; then
    echo -e "\e[32mCompleted.\e[0m"
    exit 0
else
    echo -e "\e[31mFailed.\e[0m"
    exit 1
fi
