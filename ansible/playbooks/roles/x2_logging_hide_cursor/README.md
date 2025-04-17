# x2 hide cursor

## Role in system design

This role sets up a background service that hides the mouse cursor after a period of inactivity using `unclutter-xfixes`. It is useful in kiosk or touchscreen setups where a visible cursor may not be needed.

The role performs the following:

- Installs the `unclutter-xfixes` utility.
- Deploys a `systemd` service to automatically start the cursor-hiding process.
- Enables the service to start on boot.

## Variables

None
