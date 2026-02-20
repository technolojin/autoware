#!/usr/bin/env python3
"""
Workflow script to update .repos files and generate PR body with changes.

This script uses repos-fetch.py to update files and tracks changes for PR generation.
"""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import Optional

from ruamel.yaml import YAML

COMMIT_HASH_LENGTH = 40
COMMIT_HASH_DISPLAY_LENGTH = 8


def is_commit_hash(value: str) -> bool:
    """
    Check if a string is a valid commit hash (40 hex characters).

    Args:
        value: String to check

    Returns:
        True if the string is a 40-character hexadecimal hash

    """
    return len(value) == COMMIT_HASH_LENGTH and all(c in "0123456789abcdef" for c in value.lower())


def read_yaml_file(filepath: str) -> dict:
    """Read a YAML file and return its contents."""
    yaml = YAML()
    with Path(filepath).open() as f:
        return yaml.load(f)


def extract_github_repo(url: str) -> Optional[str]:
    """Extract GitHub repository path (owner/repo) from URL if it's a GitHub URL."""
    if "github.com" in url:
        if url.startswith("git@github.com:"):
            repo_path = url.replace("git@github.com:", "").replace(".git", "")
        else:
            repo_path = url.split("github.com/")[-1].replace(".git", "")
        return repo_path.split("#")[0]
    return None


def format_version_display(version: str) -> str:
    """Format version string for display, clamping to 8 chars only if it's a 40-char hex hash."""
    if is_commit_hash(version):
        return version[:COMMIT_HASH_DISPLAY_LENGTH]
    return version


def format_commit_title(commit_title: str, github_repo: Optional[str]) -> str:
    """
    Format commit title by converting PR references to links.

    Args:
        commit_title: The commit title/message
        github_repo: GitHub repository path (owner/repo) or None

    Returns:
        Formatted commit title with PR links

    """
    if not github_repo:
        return commit_title

    pr_match = re.search(r"\(#(\d+)\)", commit_title)
    if pr_match:
        pr_number = pr_match.group(1)
        pr_link = f"https://github.com/{github_repo}/pull/{pr_number}"
        return re.sub(r"\(#\d+\)", f"([#{pr_number}]({pr_link}))", commit_title)

    return commit_title


def run_repos_fetch(filepath: str) -> subprocess.CompletedProcess:
    """
    Run repos-fetch.py script to update a file.

    Args:
        filepath: Path to the file to update

    Returns:
        CompletedProcess result from subprocess.run

    """
    return subprocess.run(
        ["python3", "repos-fetch.py", filepath, "--update"],  # noqa: S607
        capture_output=True,
        text=True,
        check=False,
    )


def get_commit_messages(repo_url: str, old_hash: str, new_hash: str) -> list[str]:
    """Get commit messages between two hashes using git CLI."""
    messages = []

    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            subprocess.run(
                ["git", "init", "--bare"],  # noqa: S607
                cwd=temp_dir,
                capture_output=True,
                check=True,
                timeout=10,
            )

            # Fetch both old and new hashes to ensure git log can access both endpoints
            fetch_result = subprocess.run(
                ["git", "fetch", "--depth=200", repo_url, old_hash, new_hash],  # noqa: S607
                cwd=temp_dir,
                capture_output=True,
                timeout=30,
                check=False,
            )

            # Check if fetch succeeded
            if fetch_result.returncode != 0:
                print(  # noqa: T201
                    f"  Warning: Failed to fetch commits from {repo_url}: {fetch_result.stderr.decode()}",
                    file=sys.stderr,
                )
                return messages

            result = subprocess.run(
                ["git", "log", "--oneline", f"{old_hash}..{new_hash}"],  # noqa: S607
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )

            if result.returncode == 0 and result.stdout.strip():
                github_repo = extract_github_repo(repo_url)

                for line in result.stdout.strip().split("\n"):
                    parts = line.split(" ", 1)
                    if len(parts) == 2:  # noqa: PLR2004
                        commit_title = parts[1]
                        commit_title = format_commit_title(commit_title, github_repo)
                        messages.append(commit_title)

    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, OSError) as e:
        print(f"  Warning: Failed to get commit messages: {e}", file=sys.stderr)  # noqa: T201
    except Exception as e:  # noqa: BLE001
        print(f"  Warning: Error getting commit messages: {e}", file=sys.stderr)  # noqa: T201

    return messages


def compare_repos_file(_filepath: str, old_data: dict, new_data: dict) -> list[dict]:
    """Compare old and new .repos data and return list of changes."""
    changes = []

    if not old_data or "repositories" not in old_data:
        return changes
    if not new_data or "repositories" not in new_data:
        return changes

    for repo_name, new_config in new_data["repositories"].items():
        if not isinstance(new_config, dict):
            continue

        old_config = old_data["repositories"].get(repo_name)
        if not old_config or not isinstance(old_config, dict):
            continue

        old_version = old_config.get("version")
        new_version = new_config.get("version")
        url = new_config.get("url")

        if old_version and new_version and url and old_version != new_version:
            github_repo = extract_github_repo(url)
            changes.append(
                {
                    "name": repo_name,
                    "url": url,
                    "github_repo": github_repo,
                    "previous_version": old_version,
                    "new_version": new_version,
                }
            )

    return changes


def compare_ansible_galaxy_file(_filepath: str, old_data: dict, new_data: dict) -> list[dict]:
    """Compare old and new ansible-galaxy data and return list of changes."""
    changes = []

    if not old_data or "collections" not in old_data:
        return changes
    if not new_data or "collections" not in new_data:
        return changes

    old_collections = old_data["collections"]
    new_collections = new_data["collections"]

    # Match collections by name
    for i, new_collection in enumerate(new_collections):
        if not isinstance(new_collection, dict):
            continue

        if new_collection.get("type") != "git":
            continue

        new_url = new_collection.get("name")
        if not new_url:
            continue

        # Find corresponding old collection
        old_collection = None
        if (
            i < len(old_collections)
            and isinstance(old_collections[i], dict)
            and old_collections[i].get("name") == new_url
        ):
            old_collection = old_collections[i]

        if old_collection:
            old_version = old_collection.get("version")
            new_version = new_collection.get("version")

            base_url = new_url.split("#")[0] if "#" in new_url else new_url

            if old_version and new_version and old_version != new_version:
                github_repo = extract_github_repo(base_url)
                changes.append(
                    {
                        "name": base_url,
                        "url": base_url,
                        "github_repo": github_repo,
                        "previous_version": old_version,
                        "new_version": new_version,
                    }
                )

    return changes


def generate_pr_body(changes: list[dict]) -> str:
    """Generate PR body with compare links and commit messages for all changes."""
    if not changes:
        return "No changes"

    lines = ["## Updated Dependencies\n"]

    for change in changes:
        name = change["name"]
        prev_version = change["previous_version"]
        new_version = change["new_version"]
        github_repo = change["github_repo"]
        repo_url = change["url"]

        prev_display = format_version_display(prev_version)
        new_display = format_version_display(new_version)

        # New version must always be a SHA (repos-fetch.py guarantees this)
        if not is_commit_hash(new_version):
            error_msg = f"new_version is not a commit SHA for {name}: {new_version}"
            print(f"Error: {error_msg}", file=sys.stderr)  # noqa: T201
            sys.exit(1)

        if github_repo:
            compare_url = f"https://github.com/{github_repo}/compare/{prev_version}...{new_version}"
            lines.append(
                f"- **{github_repo}** ({name}): [`{prev_display}`...`{new_display}`]({compare_url})"
            )
        else:
            lines.append(f"- **{name}**: `{prev_display}` → `{new_display}`")

        # If previous version was not a SHA, skip commit message generation
        # (resolving branch/tag now would give current state, not historical)
        if not is_commit_hash(prev_version):
            lines.append("  - Version pinned to specific commit SHA")
            continue

        # Both prev and new are SHAs, fetch commit messages
        commit_messages = get_commit_messages(repo_url, prev_version, new_version)
        if commit_messages:
            lines.append("  - Changes:")
            for msg in commit_messages:
                lines.append(f"    - {msg}")

    return "\n".join(lines)


def main() -> None:  # noqa: C901, PLR0912, PLR0915
    # Files to update
    repos_files = ["autoware.repos", "simulator.repos", "tools.repos", "awsim.repos"]
    ansible_files = ["ansible-galaxy-requirements.yaml"]

    all_changes = []

    print("Processing repos files...", file=sys.stderr)  # noqa: T201
    for repos_file in repos_files:
        if not Path(repos_file).exists():
            continue

        print(f"  Processing {repos_file}...", file=sys.stderr)  # noqa: T201

        # Read old data
        old_data = read_yaml_file(repos_file)

        # Update using repos-fetch.py
        result = run_repos_fetch(repos_file)

        if result.returncode != 0:
            print(f"  Error updating {repos_file}: {result.stderr}", file=sys.stderr)  # noqa: T201
            continue

        # Read new data
        new_data = read_yaml_file(repos_file)

        # Compare and collect changes
        changes = compare_repos_file(repos_file, old_data, new_data)
        all_changes.extend(changes)

        if changes:
            print(  # noqa: T201
                f"  Updated {repos_file} with {len(changes)} changes", file=sys.stderr
            )
        else:
            print(f"  No changes in {repos_file}", file=sys.stderr)  # noqa: T201

    print("Processing ansible-galaxy files...", file=sys.stderr)  # noqa: T201
    for ansible_file in ansible_files:
        if not Path(ansible_file).exists():
            continue

        print(f"  Processing {ansible_file}...", file=sys.stderr)  # noqa: T201

        old_data = read_yaml_file(ansible_file)

        result = run_repos_fetch(ansible_file)

        if result.returncode != 0:
            print(  # noqa: T201
                f"  Error updating {ansible_file}: {result.stderr}", file=sys.stderr
            )
            continue

        new_data = read_yaml_file(ansible_file)

        changes = compare_ansible_galaxy_file(ansible_file, old_data, new_data)
        all_changes.extend(changes)

        if changes:
            print(  # noqa: T201
                f"  Updated {ansible_file} with {len(changes)} changes", file=sys.stderr
            )
        else:
            print(f"  No changes in {ansible_file}", file=sys.stderr)  # noqa: T201

    # Generate PR body
    github_output = os.environ.get("GITHUB_OUTPUT")

    if all_changes:
        print("Changes made")  # noqa: T201

        pr_body = generate_pr_body(all_changes)
        if github_output:
            try:
                with Path(github_output).open("a") as f:
                    f.write("pr-body<<EOF\n")
                    f.write(pr_body)
                    f.write("\nEOF\n")
                    f.write("has-changes=true\n")
                print(  # noqa: T201
                    f"Wrote PR body with {len(all_changes)} changes to GITHUB_OUTPUT",
                    file=sys.stderr,
                )
            except OSError as e:
                print(  # noqa: T201
                    f"Warning: Failed to write to GITHUB_OUTPUT: {e}", file=sys.stderr
                )
        else:
            print("\n" + pr_body)  # noqa: T201
    else:
        print("No changes")  # noqa: T201
        if github_output:
            try:
                with Path(github_output).open("a") as f:
                    f.write("has-changes=false\n")
            except OSError as e:
                print(  # noqa: T201
                    f"Warning: Failed to write to GITHUB_OUTPUT: {e}", file=sys.stderr
                )


if __name__ == "__main__":
    main()
