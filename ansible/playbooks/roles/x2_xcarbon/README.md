<!-- cspell: ignore sdkkey xcarctl -->

# x2 xCarbon

Start xCarbon as a service automatically upon OS boot by invoking `xcarctl service enable`

## Role in system design

As tasks executed by this role, install xCarbon with sdkkey in files directory

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
    - { role: x2_xcarbon, tags: [x2_xcarbon] }
```
