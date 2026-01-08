#!/usr/bin/env python3

"""
This script is used to compare all yaml files between two directories.

1. Find out all "config/*.yaml" files in directory1.
2. Find out the corresponding files in another directory2. They generally will have the same file name with different paths, and there are some exceptions that we handle those mapping in a dictionary `FILE_MAPPING`.
3. For each pair of files, compare the content of the yaml files.
4. Demonstrate the differences in a human-readable format. The visual difference should identify either missing or extra keys in the yaml files.
"""

import os
from pathlib import Path
from typing import Dict
from typing import List
from typing import Tuple

from deepdiff import DeepDiff
import pandas as pd
import yaml


# Define the mapping for exceptions where file names are different between directories
def create_file_mapping() -> Dict[str, List[str]]:
    FILE_MAPPING_XX1_template = {
        "src/autoware/universe/control/autoware_mpc_lateral_controller/param/lateral_controller_defaults.param.yaml": "src/autoware/launcher/autoware_launch/config/control/trajectory_follower/{index}/lateral/mpc.param.yaml",
        "src/autoware/universe/control/autoware_pid_longitudinal_controller/param/longitudinal_controller_defaults.param.yaml": "src/autoware/launcher/autoware_launch/config/control/trajectory_follower/{index}/longitudinal/pid.param.yaml",
        "src/autoware/universe/perception/autoware_image_projection_based_fusion/config/roi_pointcloud_fusion.param.yaml": "src/autoware/launcher/autoware_launch/config/perception/object_recognition/detection/irregular_object_detection/irregular_object_detector.param.yaml",
    }
    FILE_MAPPING_X2_template = {
        "src/autoware/universe/control/autoware_mpc_lateral_controller/param/lateral_controller_defaults.param.yaml": "src/autoware/launcher/autoware_launch/config/control/trajectory_follower/lateral/mpc.param.yaml",
        "src/autoware/universe/control/autoware_pid_longitudinal_controller/param/longitudinal_controller_defaults.param.yaml": "src/autoware/launcher/autoware_launch/config/control/trajectory_follower/longitudinal/pid.param.yaml",
        "src/autoware/universe/perception/autoware_image_projection_based_fusion/config/roi_pointcloud_fusion.param.yaml": "src/autoware/launcher/autoware_launch/config/perception/object_recognition/detection/irregular_object_detection/irregular_object_detector.param.yaml",
    }
    FILE_MAPPING = {}
    for key, value in list(FILE_MAPPING_XX1_template.items()) + list(
        FILE_MAPPING_X2_template.items()
    ):
        if "{index}" not in value:
            # the file does not have a template needed to loop through
            if os.path.exists(value):
                FILE_MAPPING[key] = [value]
        else:
            # test index = default
            default_file_path = value.format(index="default")
            if os.path.exists(default_file_path):
                FILE_MAPPING[key] = [default_file_path]
            else:
                continue
            # test index = 1, 2, 3, 4, 5 until the file does not exist
            index = 1
            while True:
                file_path = value.format(index=index)
                if os.path.exists(file_path):
                    FILE_MAPPING[key].append(file_path)
                else:
                    break
                index += 1

    return FILE_MAPPING


FILE_MAPPING = create_file_mapping()


def check_if_ros_yaml(file_path: str) -> bool:
    """
    Check if the given YAML file is a ROS parameter file.

    Args:
        file_path (str): Path to the yaml file.

    Returns:
        bool: True if the file is a ROS parameter file, False otherwise.
    """
    try:
        yaml_content = load_yaml(file_path)
    except Exception:
        return False
    if yaml_content is None:
        return False
    if "/**" in yaml_content:
        if "ros__parameters" in yaml_content["/**"]:
            return True

    return False


def find_yaml_files(directory: str) -> List[str]:
    """
    Recursively find all yaml files under the given directory.

    Args:
        directory (str): The base directory to search for yaml files.

    Returns:
        List[str]: List of file paths for all yaml files found.
    """
    return [str(file) for file in Path(directory).rglob("*.yaml") if check_if_ros_yaml(file)]


def map_files_by_name(
    dir1_files: List[str], dir2_files: List[str], file_mapping: Dict[str, List[str]]
) -> List[Tuple[str, str]]:
    """
    Map files between two directories by matching file names.

    Args:
        dir1_files (List[str]): List of yaml files in directory1.
        dir2_files (List[str]): List of yaml files in directory2.
        file_mapping (Dict[str, str]): Custom mapping of files that don't follow the standard convention.

    Returns:
        List[Tuple[str, str]]: A list of tuples where each tuple contains the corresponding file paths from both directories.
    """
    mapped_files = []

    # Create a lookup dictionary for dir2 files based on their base names
    dir2_file_dict = {os.path.basename(file): file for file in dir2_files}

    for file1 in dir1_files:
        base_name = os.path.basename(file1)

        # Handle special cases where filenames don't match between directories
        if file1 in file_mapping:
            for mapped_file in file_mapping[file1]:
                mapped_files.append((file1, mapped_file))
            continue
        elif base_name in dir2_file_dict:
            mapped_file = dir2_file_dict[base_name]
        else:
            # print(f"Warning: No corresponding file found for {file1}")
            continue

        mapped_files.append((file1, mapped_file))

    return mapped_files


def load_yaml(file_path: str) -> Dict:
    """
    Load the content of a YAML file.

    Args:
        file_path (str): Path to the yaml file.

    Returns:
        Dict: Parsed content of the yaml file.
    """
    with open(file_path, "r") as file:
        return yaml.safe_load(file)


def compare_yaml_files(file1: str, file2: str) -> DeepDiff:
    """
    Compare two YAML files and return the differences.

    Args:
        file1 (str): Path to the first yaml file.
        file2 (str): Path to the second yaml file.

    Returns:
        DeepDiff: A dictionary representing the differences between the two files.
    """
    yaml1 = load_yaml(file1)
    yaml2 = load_yaml(file2)
    return DeepDiff(
        yaml1["/**"]["ros__parameters"], yaml2["/**"]["ros__parameters"], ignore_order=True
    )


def process_deepdiff_path(path_str: str) -> tuple:
    """
    Convert DeepDiff path strings from root['key_1']['key_2']...['key_n'].

    Convert to a more readable dot notation like key1.key2.key3...
    Ignores paths where the last key is a number (i.e., a list index).

    Args:
        path_str (str): The original DeepDiff path as a string.

    Returns:
        str: The refactored path string in dot notation or an empty string if ignored.
    """
    # Remove "root" from the path and split by "['" to isolate keys
    path_parts = path_str.replace("root", "").split("[")

    # Clean up the string by removing the trailing "']" and empty parts
    cleaned_parts = [
        part.replace("']", "").replace("]", "").replace("'", "")
        for part in path_parts
        if part.strip()
    ]

    # Check if the last part of the path is numeric (i.e., a list index)
    if cleaned_parts and cleaned_parts[-1].isdigit():
        # Return an empty string to signal that this difference should be ignored
        return "", False

    # Join the parts with dots to create the final readable path
    return ".".join(cleaned_parts), True


def deepdiff_to_diff_table(file1, file2, diff: DeepDiff) -> list:
    """Convert the DeepDiff object to a table format for exporting."""
    diff_table = []
    file_basename = os.path.basename(file1)
    if "dummy" in file_basename:
        return diff_table
    for change_type, changes in diff.items():
        if change_type == "dictionary_item_added":
            for change in changes:
                readable_path, valid_path = process_deepdiff_path(str(change))
                if not valid_path:
                    continue
                diff_table.append([file_basename, "extra params", readable_path, file2])
        elif change_type == "dictionary_item_removed":
            for change in changes:
                readable_path, valid_path = process_deepdiff_path(str(change))
                if not valid_path:
                    continue
                diff_table.append([file_basename, "missing params", readable_path, file2])
        else:
            continue  # Skip other change types

    return diff_table


def diff_table_to_markdown(diff_table: list, base_dir2, output_file: str) -> None:
    """Export the differences table to a markdown file."""
    # Initialize markdown content
    markdown_content = "# YAML Differences Report\n\n"

    # Track the current file being processed
    current_file = None
    current_file_table = []
    detailing = False

    for row in diff_table:
        filename, change_type, parameters, file2 = row

        if file2 != current_file:
            # Write the previous file's table to markdown if it exists
            if current_file is not None and current_file_table:
                markdown_content += pd.DataFrame(
                    current_file_table, columns=["Compared to Universe", "Parameters"]
                ).to_markdown(index=False)
                markdown_content += "\n\n"

            # Start a new section for the current file
            if detailing:
                markdown_content += "</details>\n\n"
            else:
                detailing = True

            markdown_content += "<details>\n\n"
            markdown_content += f"<summary>Differences for {file2.replace(base_dir2, '')} to {filename}</summary>\n\n"
            current_file = file2
            current_file_table = []

        # Append the current difference to the table
        current_file_table.append([change_type, parameters])

    # Write the last file's table to markdown
    if current_file_table:
        markdown_content += pd.DataFrame(
            current_file_table, columns=["Compared to Universe", "Parameters"]
        ).to_markdown(index=False)
        markdown_content += "\n\n"
    if detailing:
        markdown_content += "</details>\n\n"

    # Write the markdown content to the file
    with open(output_file, "w") as md_file:
        md_file.write(markdown_content)


def compare_all_yaml_files(dir1: str, dir2: str, file_mapping: Dict[str, List[str]]) -> None:
    """
    Compare all YAML files between two directories and show differences.

    Args:
        dir1 (str): Path to the first directory.
        dir2 (str): Path to the second directory.
        file_mapping (Dict[str, str]): Custom mapping of files that don't follow the standard convention.
    """
    dir1_files = find_yaml_files(dir1)
    dir2_files = find_yaml_files(dir2)

    mapped_files = map_files_by_name(dir1_files, dir2_files, file_mapping)

    diff_table = []
    for file1, file2 in mapped_files:
        diff = compare_yaml_files(file1, file2)
        diff_table.extend(deepdiff_to_diff_table(file1, file2, diff))

    diff_table_to_markdown(diff_table, dir2, "yaml_diff_report.md")


if __name__ == "__main__":
    # Replace with the actual paths of the two directories
    dir1 = "src/autoware/universe"
    dir2 = "src/autoware/launcher"

    compare_all_yaml_files(dir1, dir2, FILE_MAPPING)
