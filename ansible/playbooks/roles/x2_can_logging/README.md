# X2 CAN Logging

Configure udev rules for CAN interfaces and link up them upon boot.

## Role in system design

This role adds the following files:

- 50-can.rules
  - Udev rules for CAN interfaces.
- can-logging.service
  - Systemd service to link up CAN interfaces upon boot.
- can-up.sh
  - A script to link up CAN interfaces.
- can-down.sh
  - A script to link down CAN interfaces.

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: x2_can_logging, tags: [x2_can_logging] }`

### Variables

### Preparation

## Related links

### Remarks
