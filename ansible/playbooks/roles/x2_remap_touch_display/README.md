# x2 remap touch display

## Role in system design

This role configures a multi-display environment where a touchscreen device is positioned alongside a standard monitor. It ensures the touchscreen is correctly mapped, assigned its own MPX master pointer, and used as the display target for a specific application window.

Specifically, the role:

- Installs necessary dependencies such as `wmctrl`.
- Creates and deploys a setup script (`remap_touch_display.sh`) that:
  - Detects and arranges the display layout using `xrandr`.
  - Sets up an MPX pointer for isolating touchscreen input.
  - Maps the touch input device to the designated display output.
  - Waits for and resizes a specific application window on the touchscreen.
- Installs and enables a systemd service to execute the script during boot.

## Variables

| Variable                      | Default Value                | Description                                  |
| ----------------------------- | ---------------------------- | -------------------------------------------- |
| `x2_touch_display_name`       | `eGalaxTouch`                | Identifier substring for the touch device    |
| `x2_touch_app_name`           | `Maintenance Operation Tool` | Title of the window to be moved/resized      |
| `x2_touch_display_resolution` | `1024x768`                   | Resolution of the touch panel                |
| `x2_mpx_name`                 | `touch_master`               | Name of the MPX master pointer to be created |

## Preparation

```yaml
# playbook.yaml
- hosts: all
  roles:
    - { role: x2_remap_touch_display, tags: [x2_remap_touch_display] }
```

## Requirements

The host must be running an Xorg-based environment with xrandr, xinput, and wmctrl available.

The touch device and the target window must be detectable by name (via xinput and wmctrl, respectively).

This setup assumes the presence of a DISPLAY=:0 environment and appropriate .Xauthority permissions.
