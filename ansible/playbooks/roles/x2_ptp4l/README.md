# X2 ptp4l

This role adds ptp4l and phc2sys configs for Main ECU and Sub ECU.

## Role in system design

## Dependency

## Usage

### Variables

| Name         | Default | Description                                               |
| ------------ | ------- | --------------------------------------------------------- |
| x2_ptp4l_ecu | main    | Allowed value is `main` or `sub`. Specify the target ECU. |

### Preparation

`- { role: x2_ptp4l, tags: [x2_ptp4l] }`

## Related links

### Remarks
