#!/usr/bin/env python3
"""A script that re-implements the cleanup logic from metadata_gen.py.

See `gen_metadata` function at
https://github.com/tier4/ota-metadata/blob/053196bfdb26ad87eed00bb682a6976cf0a201ce/metadata/ota_metadata/metadata_gen.py#L202

This script deletes files under build directory that are:
- Not symlinks
- Not directories
- Not matching special patterns (hook, egg-info, .so in build dir)
- Not referenced by symbolic links
"""

import os
import re
import stat
import sys
from pathlib import Path

AUTOWARE_BUILD_GLOB = "home/autoware/*/build/**/*"

# Skip patterns for build directory only (hook, egg-info, .so files)
# These patterns only match build directory, not src directory
SKIP_PATTERN = [
    re.compile(r"home/autoware/[^/]*/build/.*/hook/.*"),
    re.compile(r"home/autoware/[^/]*/build/.*/.*.egg-info/.*"),
    re.compile(r"home/autoware/[^/]*/build/.*/.*.so$"),
]

AUTOWARE_BUILD_PATTERN = re.compile(r"home/autoware/[^/]+/build/")


def _collect_symlink_targets(_rootfs: Path) -> set[str]:
    """Collect all resolved symlink targets that point to files in build directory.

    Only file targets are collected. Directory targets are ignored since
    directories are not deleted by the cleanup function.
    """
    targets: set[str] = set()
    _rootfs_str = str(_rootfs)
    for dirpath, _, filenames in os.walk(_rootfs):
        for name in filenames:
            full_path = os.path.join(dirpath, name)
            if not os.path.islink(full_path):
                continue

            try:
                _target = os.path.realpath(full_path)
                _target_rel_path = os.path.relpath(_target, _rootfs_str)
                if AUTOWARE_BUILD_PATTERN.match(_target_rel_path):
                    targets.add(_target_rel_path)
            except (OSError, ValueError):
                continue

    return targets


def cleanup(_rootfs: Path):
    """Delete files under build directory that are not needed.

    Files are deleted if they are:
    - Regular files (not symlinks, not directories)
    - Not matching special patterns (hook, egg-info, .so in build dir)
    - Not referenced by symbolic links anywhere in the rootfs
    """
    # First, collect all files referenced by symlinks
    _symlink_targets = _collect_symlink_targets(_rootfs)

    _count, _size = 0, 0

    # Process build directory
    for _full_path in _rootfs.glob(AUTOWARE_BUILD_GLOB):
        # Use single lstat call for symlink/file check and size
        try:
            _st = _full_path.lstat()
        except OSError:
            continue

        # Skip symlinks and non-regular files (directories, etc.)
        if stat.S_ISLNK(_st.st_mode) or not stat.S_ISREG(_st.st_mode):
            continue

        _rel_path_str = str(_full_path.relative_to(_rootfs))

        # Skip files matching special patterns (hook, egg-info, .so)
        if any(_pa.match(_rel_path_str) for _pa in SKIP_PATTERN):
            continue

        # Skip files that are referenced by symbolic links
        if _rel_path_str in _symlink_targets:
            continue

        _count += 1
        _size += _st.st_size
        _full_path.unlink(missing_ok=True)

    print(f"total {_count} files({_size} bytes) are cleaned up.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: clean-up-build.py <rootfs_path>")
        sys.exit(1)
    cleanup(Path(sys.argv[1]))
