#!/usr/bin/env python3
"""
Standalone script to update .repos and ansible-galaxy-requirements.yaml files.

Resolves version fields to commit SHAs from branch/tag names.

Usage:
    # Preview changes (print to stdout)
    ./repos-fetch.py autoware.repos

    # Update and save back to file
    ./repos-fetch.py autoware.repos --update

How it works:
    - For each repository entry, checks the 'version' field
    - If 'version' contains a branch/tag name (not a commit SHA), resolves it to a commit SHA
    - Updates the 'version' field with the resolved SHA
    - If 'version' is already a commit SHA, leaves it unchanged

Supported files:
    - .repos files (e.g., autoware.repos, simulator.repos)
    - ansible-galaxy-requirements.yaml with special handling for git collections
"""

import argparse
from io import StringIO
from pathlib import Path
import subprocess
import sys
from typing import Optional

from ruamel.yaml import YAML

COMMIT_HASH_LENGTH = 40

yaml = YAML()
yaml.preserve_quotes = True
yaml.default_flow_style = False
yaml.indent(mapping=2, sequence=4, offset=2)


def get_ref_hash(
    repo_url: str,
    ref_name: str,
    *,
    allow_tags: bool,
) -> Optional[str]:
    """
    Fetch the commit hash for a given ref (branch or tag) using git ls-remote.

    Args:
        repo_url: Git repository URL
        ref_name: Branch or tag name
        allow_tags: Whether to allow tags instead of SHA (default: True)

    Returns:
        Commit hash if found (may be a tag if allow_tags is True), None otherwise

    """
    try:
        # Try as a branch first
        result = subprocess.run(
            ["git", "ls-remote", repo_url, f"refs/heads/{ref_name}"],  # noqa: S607
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip().split()[0]

        # Try as a tag - use ^{} to dereference annotated tags to commit SHA
        result = subprocess.run(
            ["git", "ls-remote", repo_url, f"refs/tags/{ref_name}^{{}}"],  # noqa: S607
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        if result.returncode == 0 and result.stdout.strip():
            if allow_tags:
                return ref_name  # Return the tag name if tags are allowed
            return result.stdout.strip().split()[0]

        # Fallback: try without dereferencing (for lightweight tags)
        result = subprocess.run(
            ["git", "ls-remote", repo_url, f"refs/tags/{ref_name}"],  # noqa: S607
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        if result.returncode == 0 and result.stdout.strip():
            if allow_tags:
                return ref_name  # Return the tag name if tags are allowed

            return result.stdout.strip().split()[0]

        return None  # noqa: TRY300
    except (subprocess.TimeoutExpired, Exception) as e:
        print(f"Error fetching ref {ref_name} from {repo_url}: {e}", file=sys.stderr)  # noqa: T201
        return None


def is_commit_hash(value: str) -> bool:
    """Check if a string looks like a commit hash (40 hex chars)."""
    return len(value) == COMMIT_HASH_LENGTH and all(c in "0123456789abcdef" for c in value.lower())


def process_entry(entry: dict, url: str) -> None:
    """
    Process entry by resolving version field to SHA if needed.

    Args:
        entry: Entry configuration dict from YAML (repo or collection)
        url: Repository URL

    """
    version = entry.get("branch", entry.get("version"))

    # If version is not a commit hash, resolve it
    if version and not is_commit_hash(version):
        allow_tags = True
        resolved_hash = get_ref_hash(url, version, allow_tags=allow_tags)
        if resolved_hash:
            if not allow_tags and not is_commit_hash(resolved_hash):
                msg = f"Resolved ref '{version}' for repository '{url}' to a non-commit value: {resolved_hash}"
                raise RuntimeError(msg)
            entry["version"] = resolved_hash


def update_repos_file(filepath: str) -> str:
    """
    Update a .repos file with resolved commit hashes.

    Args:
        filepath: Path to the .repos file

    Returns:
        Updated YAML content as string

    """
    with Path(filepath).open() as f:
        data = yaml.load(f)

    if not data or "repositories" not in data:
        print(f"No repositories found in {filepath}", file=sys.stderr)  # noqa: T201
        return ""

    for _repo_name, repo_config in data["repositories"].items():
        if not isinstance(repo_config, dict):
            continue

        url = repo_config.get("url")
        if not url:
            continue

        process_entry(repo_config, url)

    # Convert to string
    output = StringIO()
    yaml.dump(data, output)
    return output.getvalue()


def update_ansible_galaxy_file(filepath: str) -> str:
    """
    Update an ansible-galaxy-requirements.yaml file with resolved commit hashes.

    Args:
        filepath: Path to the ansible-galaxy-requirements.yaml file

    Returns:
        Updated YAML content as string

    """
    with Path(filepath).open() as f:
        data = yaml.load(f)

    if not data or "collections" not in data:
        print(f"No collections found in {filepath}", file=sys.stderr)  # noqa: T201
        return ""

    for collection in data["collections"]:
        if not isinstance(collection, dict):
            continue

        # Skip non-git collections
        if collection.get("type") != "git":
            continue

        url = collection.get("name")
        if not url:
            continue

        # Extract base URL (remove #/path suffix)
        base_url = url.split("#")[0] if "#" in url else url

        process_entry(collection, base_url)

    # Convert to string
    output = StringIO()
    yaml.dump(data, output)
    return output.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update .repos or ansible-galaxy-requirements.yaml files with resolved commit hashes"
    )
    parser.add_argument("file", help="Path to .repos or ansible-galaxy-requirements.yaml file")
    parser.add_argument(
        "--update",
        action="store_true",
        help="Save changes back to file instead of printing to stdout",
    )

    args = parser.parse_args()

    if not Path(args.file).exists():
        print(f"Error: File not found: {args.file}", file=sys.stderr)  # noqa: T201
        sys.exit(1)

    # Determine file type and update accordingly
    if args.file.endswith(".repos"):
        updated_content = update_repos_file(args.file)
    elif args.file.endswith("requirements.yaml"):
        updated_content = update_ansible_galaxy_file(args.file)
    else:
        print(f"Error: Unknown file type: {args.file}", file=sys.stderr)  # noqa: T201
        sys.exit(1)

    if not updated_content:
        sys.exit(1)

    if args.update:
        # Write back to file
        with Path(args.file).open("w") as f:
            f.write(updated_content)
        print(f"Updated {args.file}", file=sys.stderr)  # noqa: T201
    else:
        # Print to stdout
        print(updated_content, end="")  # noqa: T201


if __name__ == "__main__":
    main()
