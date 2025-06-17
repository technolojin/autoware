# x2 reconnect touch display

This role reconnects the touch display connected to the Logging ECU because it occasionally fails to be recognized by the ECU.
Please note that this is only a temporary workaround until the issue is fully resolved.

## Role in system design

None

### Variables

None

### Preparation

```yaml
# playbook.yaml
- roles:
    - { role: x2_reconnect_touch_display, tags: [x2_reconnect_touch_display] }
```
