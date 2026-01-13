# Jetson Launch Ansible Role

(Copied and modified from `autoware.edge-auto-jetson.perception_application` / `beta/v0.48` ansible role.)

This Ansible role automates the configuration of the Edge Auto Jetson startup service.

## Role Structure

```bash
jetson_launch/
├── tasks/
│   ├── main.yaml                    # Systemd service setup tasks
├── templates/
│   ├── run.sh.edge_auto_x2.j2       # Template for perception launch script
│   ├── run.sh.addon.j2              # Template for addon perception launch script
│   └── perception-startup.service.j2 # Template for systemd service
├── defaults/
│   └── main.yaml                    # Default variable definitions
└── README.md                        # This documentation
```

## Role Variables

### Required Variables

- `jetson_launch_id`: Jetson ECU number `JETSON_ID`, used to determine the launch file.
  - The actual correspondence from `jetson_launch_id` to launch file varies for difference products.
- `jetson_launch_run_template`: Template file for run script.
  - Options: `run.sh.edge_auto_x2.j2`, `run.sh.addon.j2`
- `jetson_launch_perception_type`: Type of perception to run `tlr/od/addon`, will work as `jetson_{{ jetson_launch_perception_type }}_launch`.
- `jetson_launch_video_num`: The number of videos. Unused for addon.

## Role Tasks

- Creates service directory in `/opt/autoware/perception-startup-service`
- Installs launch script from appropriate template
- Configures and enables systemd service

## Dependencies

None.

## Usage

Include this role in your playbook:

```yaml
- { role: jetson_launch }
```

## Service Management

The perception service can be managed using standard systemd commands:

```bash
# Check service status
sudo systemctl status perception-startup.service

# Start the service
sudo systemctl start perception-startup.service

# Stop the service
sudo systemctl stop perception-startup.service

# Restart the service
sudo systemctl restart perception-startup.service
```

## Post-Installation

After successful installation:

1. A systemd service will be configured to automatically start the perception application
2. The service will be enabled to start on boot

## Troubleshooting

1. If the service fails to start:
   - Check service logs: `journalctl -u perception-startup.service`
   - Verify file permissions in the installation directory
   - Ensure all ROS 2 dependencies are properly sourced
