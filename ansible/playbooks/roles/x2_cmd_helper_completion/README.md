# x2_cmd_helper_completion

This Ansible role installs a bash completion script for the `cmd_helper.sh` command into the user's local completion directory (`~/.local/share/bash-completion/completions/`).

## Features

- Installs tab-completion for `cmd_helper.sh` with commonly used options
- Supports user-level installation (no root required)
- Ensures the correct directory structure is created

## Installed Completion Target

- **Command**: `cmd_helper.sh`
- **Completion file**: `~/.local/share/bash-completion/completions/cmd_helper.sh`

## Example Usage

Add the role to your playbook:

```yaml
- hosts: localhost
  roles:
    - x2_cmd_helper_completion
```
