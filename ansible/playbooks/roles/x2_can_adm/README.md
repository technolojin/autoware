# X2 udev CAN ADM

Configure udev rules for CAN interfaces and link up them upon boot.

## Role in system design

This role adds the following files:

- 50-can.rules
  - Udev rules for CAN interfaces.
- can-adm.service
  - Systemd service to link up CAN interfaces upon boot.
- can-up.sh
  - A script to link up CAN interfaces.
- can-down.sh
  - A script to link down CAN interfaces.

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: udev_can_adm, tags: [udev_can_adm] }`

### Variables

### Preparation

## Related links

### Remarks
