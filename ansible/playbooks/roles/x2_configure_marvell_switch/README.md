# Configure Marvell Switch

This role adds the systemd service that configures the Marvell switch.
This service loads the configuration once upon the first boot and does nothing if the configuration file already exists.

Please see the following page for the details.

<https://tier4.atlassian.net/wiki/spaces/SI/pages/3129837805/Marvell+Switch+Configuration>

## Role in system design

## Dependency

## Usage

Add the following line to the Ansible playbook:

`- { role: configure_marvell_switch, tags: [configure_marvell_switch] }`

### Variables

| name                                  | default                                 | description                            |
| ------------------------------------- | --------------------------------------- | -------------------------------------- |
| x2_configure_marvell_switch_interface | `enp4s0`                                | The target interface to configure.     |
| x2_configure_marvell_switch_file      | `marvell_switch_configuration_main.xml` | The file used to configure the switch. |

### Preparation

## Related links

### Remarks
