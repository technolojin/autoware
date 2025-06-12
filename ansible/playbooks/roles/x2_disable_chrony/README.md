# X2 disable chrony

This role disables the chrony service.

## Role in system design

Main and Sub want to install exactly the same software for redundant configuration. However, we would like to disable Sub's `chrony.service` to perform time synchronization with Main as master.
Therefore, after installing the software in the exact same configuration as Main, execute this role to disable the synchrony.

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: x2_disable_chrony, tags: [x2_disable_chrony] }`

### Variables

### Preparation

## Related links

### Remarks
