# x2 autoware

Start autoware.launch.xml as a service automatically upon OS boot

## Role in system design

As tasks executed by this role, copy two files that exist in files

### run.sh

- To be copied under `/opt/autoware/services`
- After sourcing setup.sh of set-autoware.env, launch autoware.launch.xml

### autoware.service

- To be copied under `/etc/systemd/system/`
- Start `run.sh` as a service with autoware user permissions

## Dependency

set-autoware-env

## Usage

### Variables

None

### Preparation

```yaml
# playbook.yaml
- roles:
    - { role: x2_autoware, tags: [x2_autoware] }
```
