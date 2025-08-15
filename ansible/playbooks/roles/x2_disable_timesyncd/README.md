# X2 disable systemd-timesyncd

This role disables the systemd-timesyncd service.

## Role in system design

ECUs for which chrony is not installed, systemd-timesyncd is enabled by default.
As it interferes with PTP sync, it should be disabled on all ECUs that are not the PTP grandmaster.

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: x2_disable_timesyncd, tags: [x2_disable_timesyncd] }`

### Variables

### Preparation

## Related links

### Remarks
