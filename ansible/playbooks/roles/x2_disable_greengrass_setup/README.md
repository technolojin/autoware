# X2 disable greengrass setup

This role disables the greengrass-v2-setup service.

## Role in system design

Main and Sub want to install exactly the same software for redundant configuration. However, we would like to disable Sub's `greengrass-v2-setup.timer` because Sub ECU is not connected to the network currently.
Therefore, after installing the software in the exact same configuration as Main, execute this role to disable greengrass setup.

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: x2_disable_greengrass_setup, tags: [x2_disable_greengrass_setup] }`

### Variables

### Preparation

## Related links

### Remarks
