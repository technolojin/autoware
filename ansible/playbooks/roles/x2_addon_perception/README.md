# X2 addon perception task

This role setup the perception node in Add-On ECU.

## Role in system design

The role has two functions:

- Install the [jetson_iv_container](https://github.com/tier4/jetson_iv_container), similar to anvil and ROSCube.
- Install an auto-start systemd service, similar to [jetson_perception_service](https://github.com/tier4/autoware_ecu_system_setup/tree/946955502aefa1b8afc0adbff737a541a1b0bd35/roles/jetson_perception_service).

## Dependency

## Usage

Add the following line to the Ansible playbook:
`- { role: x2_addon_perception, tags: [x2_addon_perception] }`

### Variables

| name                                             | default           | description                                                |
| ------------------------------------------------ | ----------------- | ---------------------------------------------------------- |
| x2_addon_perception_jetson_iv_container_version  | `x2/v2.3.1`       | The Git version for the jetson_iv_container.               |
| x2_addon_perception_jetson_container_install_dir | `/home/autoware/` | The workspace directory where the overlay_ws will be made. |

### Preparation

## Related links

- [JIRA ticket](https://tier4.atlassian.net/browse/RT0-34412)

### Remarks
