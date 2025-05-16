# x2_sub_misc

Configure the `/etc/fstab` file that describes how to mount the file system

## Role in system design

Sub ECU of X2 has an internal storage for temporary storage of bag files and an external storage for taking bag files out. This role configures the mount settings for them.

## Dependency

## Usage

### Variables

| Variables                     | Roles                                                              |
| ----------------------------- | ------------------------------------------------------------------ |
| temporary_logging_directory   | mount point of tmpfs                                               |
| rosbag_storage_label          | label of internal storage for temporary storage of bag files       |
| rosbag_logging_directory      | Mount point of internal storage for temporary storage of bag files |
| rosbag_external_storage_label | Label of external storage for retrieve bag files                   |
| rosbag_copy_directory         | Mount point of external storage for retrieve bag files             |

### Preparation

```YAML
- { role: x2_sub_misc, tags: [x2_sub_misc] }

```

## Related links

### Remarks

- Copying and extending `fstab` role
  - It is difficult to use original `fstab` while sharing it with other products
- Temporary workaround
