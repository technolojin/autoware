import sys
from pathlib import Path
from ruamel.yaml import YAML
yaml = YAML()

def main(non_base_repos_path: str, base_repos_path: str) -> None:
    merged_repositories = {}

    with Path(base_repos_path).open() as f:
        base_data = yaml.load(f)
        for repo_name, repo_entry in base_data["repositories"].items():
            if repo_entry["base"] != True:
                continue
            if "branch" in repo_entry:
                del repo_entry["branch"]
            if "labels" in repo_entry:
                repo_entry["labels"].fa.set_flow_style()
            merged_repositories[repo_name] = repo_entry

    with Path(non_base_repos_path).open() as f:
        non_base_data = yaml.load(f)
        for repo_name, repo_entry in non_base_data["repositories"].items():
            # For old simulator.repos and tools.repos which don't have base field yet, treat all entries as base entries
            # The actual base=true / false is determined from vanilla side.
            if repo_entry.get("base", True) != False:
                continue
            if "labels" in repo_entry:
                repo_entry["labels"].fa.set_flow_style()
            merged_repositories[repo_name] = repo_entry

    with Path(non_base_repos_path).open("w") as f:
        yaml.dump({"repositories": merged_repositories}, f)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: repos-formatter.py <non_base_repos_path> <base_repos_path>", file=sys.stderr)  # noqa: T201
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
