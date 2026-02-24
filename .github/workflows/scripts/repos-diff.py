#!/usr/bin/env python3
"""
Compare .repos and ansible-galaxy-requirements.yaml files between two git revisions and generate markdown diff.

Handles added, removed, and changed entries.
"""

import sys
import subprocess
from ruamel.yaml import YAML
import re
from typing import Optional

COMMIT_HASH_LENGTH = 40
COMMIT_HASH_DISPLAY_LENGTH = 8

def is_commit_hash(value: str) -> bool:
    return len(value) == COMMIT_HASH_LENGTH and all(c in "0123456789abcdef" for c in value.lower())

def read_yaml_from_git(filepath: str, revision: str) -> dict:
    try:
        result = subprocess.run([
            "git", "show", f"{revision}:{filepath}"
        ], capture_output=True, text=True, check=False)
        if result.returncode != 0:
            return {}
        yaml = YAML()
        return yaml.load(result.stdout)
    except Exception:
        return {}

def extract_github_repo(url: str) -> Optional[str]:
    if "github.com" in url:
        if url.startswith("git@github.com:"):
            repo_path = url.replace("git@github.com:", "").replace(".git", "")
        else:
            repo_path = url.split("github.com/")[-1].replace(".git", "")
        return repo_path.split("#")[0]
    return None

def format_version_display(version: str) -> str:
    if is_commit_hash(version):
        return version[:COMMIT_HASH_DISPLAY_LENGTH]
    return version

def format_commit_title(commit_title: str, github_repo: Optional[str]) -> str:
    if not github_repo:
        return commit_title
    pr_match = re.search(r"\(#(\d+)\)", commit_title)
    if pr_match:
        pr_number = pr_match.group(1)
        pr_link = f"https://github.com/{github_repo}/pull/{pr_number}"
        return re.sub(r"\(#\d+\)", f"([#{pr_number}]({pr_link}))", commit_title)
    return commit_title

def get_commit_messages(repo_url: str, old_hash: str, new_hash: str) -> list[str]:
    messages = []
    # Optionally implement fetching commit messages if needed
    return messages

def compare_repos_file(old_data: dict, new_data: dict) -> list[dict]:
    changes = []
    old_repos = old_data.get("repositories", {}) if old_data else {}
    new_repos = new_data.get("repositories", {}) if new_data else {}
    old_repos_keys = set(old_repos.keys())
    # First, process entries in old_repos (preserve order)
    for repo_name in old_repos:
        old_config = old_repos.get(repo_name)
        new_config = new_repos.get(repo_name)
        if old_config and not new_config:
            changes.append({"name": repo_name, "type": "removed", "old": old_config})
        elif old_config and new_config:
            old_version = old_config.get("version")
            new_version = new_config.get("version")
            url = new_config.get("url")
            if old_version != new_version:
                github_repo = extract_github_repo(url)
                changes.append({
                    "name": repo_name,
                    "type": "changed",
                    "url": url,
                    "github_repo": github_repo,
                    "previous_version": old_version,
                    "new_version": new_version,
                })
    # Then, process entries only in new_repos (preserve order)
    for repo_name in new_repos:
        if repo_name in old_repos_keys:
            continue
        new_config = new_repos.get(repo_name)
        if new_config:
            changes.append({"name": repo_name, "type": "added", "new": new_config})
    return changes

def compare_ansible_galaxy_file(old_data: dict, new_data: dict) -> list[dict]:
    changes = []
    old_collections = old_data.get("collections", []) if old_data else []
    new_collections = new_data.get("collections", []) if new_data else []
    old_names = {c.get("name"): c for c in old_collections if isinstance(c, dict)}
    new_names = {c.get("name"): c for c in new_collections if isinstance(c, dict)}
    old_names_keys = set(old_names.keys())
    # First, process entries in old_collections (preserve order)
    for c in old_collections:
        if not isinstance(c, dict):
            continue
        name = c.get("name")
        if not name:
            continue
        old = old_names.get(name)
        new = new_names.get(name)
        if old and not new:
            changes.append({"name": name, "type": "removed", "old": old})
        elif old and new:
            old_version = old.get("version")
            new_version = new.get("version")
            base_url = name.split("#")[0] if "#" in name else name
            if old_version != new_version:
                github_repo = extract_github_repo(base_url)
                changes.append({
                    "name": github_repo or name,
                    "type": "changed",
                    "url": base_url,
                    "github_repo": github_repo,
                    "previous_version": old_version,
                    "new_version": new_version,
                })
    # Then, process entries only in new_collections (preserve order)
    for c in new_collections:
        if not isinstance(c, dict):
            continue
        name = c.get("name")
        if name in old_names_keys:
            continue
        new = new_names.get(name)
        if new:
            changes.append({"name": name, "type": "added", "new": new})
    return changes

def generate_markdown_diff(changes: list[dict], filepath: str) -> str:
    lines = [f"### {filepath}"]
    if not changes:
        lines.append("No changes detected.")
        return "\n".join(lines)

    for change in changes:
        if change["type"] == "added":
            lines.append(f"- **Added**: {change['name']} {change.get('new', {}).get('version', '')}")
        elif change["type"] == "removed":
            lines.append(f"- **Removed**: {change['name']} {change.get('old', {}).get('version', '')}")
        elif change["type"] == "changed":
            prev_display = format_version_display(change["previous_version"])
            new_display = format_version_display(change["new_version"])
            github_repo = change.get("github_repo")
            if github_repo:
                compare_url = f"https://github.com/{github_repo}/compare/{change['previous_version']}...{change['new_version']}"
                lines.append(f"- **{change['name']}**: [`{prev_display}`...`{new_display}`]({compare_url})")
            else:
                lines.append(f"- **{change['name']}**: `{prev_display}` → `{new_display}`")
    return "\n".join(lines)

def main():
    if len(sys.argv) != 4:
        print("Usage: repos-compare.py <file> <old-revision> <new-revision>")
        sys.exit(1)
    filepath = sys.argv[1]
    old_rev = sys.argv[2]
    new_rev = sys.argv[3]
    old_data = read_yaml_from_git(filepath, old_rev)
    new_data = read_yaml_from_git(filepath, new_rev)
    if filepath.endswith(".repos"):
        changes = compare_repos_file(old_data, new_data)
        print(generate_markdown_diff(changes, filepath))
    elif filepath.endswith("requirements.yaml"):
        changes = compare_ansible_galaxy_file(old_data, new_data)
        print(generate_markdown_diff(changes, filepath))
    else:
        print("Unsupported file type")

if __name__ == "__main__":
    main()
