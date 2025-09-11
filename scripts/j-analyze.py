#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
from typing import List, Dict, Optional

# --- Data Structure (No changes here) ---
class DirectoryNode:
    """Represents a directory in the tree structure."""
    def __init__(self, name: str, parent: Optional['DirectoryNode'] = None):
        self.name = name
        self.parent = parent
        self.children: Dict[str, 'DirectoryNode'] = {}
        # total_entries includes the node itself + all descendants
        self.total_entries: int = 0

    def get_full_path(self) -> str:
        """Constructs the full absolute path by traversing up to the root."""
        if self.parent is None:
            return self.name if self.name == "/" else ""
        if self.parent.parent is None and self.parent.name == "/":
            return f"/{self.name}"
        return os.path.join(self.parent.get_full_path(), self.name)

# --- Core Logic (No changes here) ---
def build_tree(paths: List[str]) -> DirectoryNode:
    """Builds a directory tree from a flat list of absolute paths."""
    print("Building directory tree structure...")
    root = DirectoryNode("/")
    
    for path in paths:
        if not path.strip(): continue
        # Handle cases like "/": parts will be [''] which we can ignore
        parts = [part for part in path.strip().split(os.path.sep) if part]
        current_node = root
        for part in parts:
            if part not in current_node.children:
                current_node.children[part] = DirectoryNode(part, parent=current_node)
            current_node = current_node.children[part]
    return root

def calculate_entries(node: DirectoryNode) -> int:
    """Recursively calculates the total number of entries for each node."""
    count = 1 + sum(calculate_entries(child) for child in node.children.values())
    node.total_entries = count
    return count

def find_node_by_path(root: DirectoryNode, path: str) -> Optional[DirectoryNode]:
    """Finds a node in the tree corresponding to a given absolute path."""
    if not path.startswith('/'): return None
    if path == '/': return root
        
    parts = [part for part in path.strip(os.path.sep).split(os.path.sep) if part]
    current_node = root
    for part in parts:
        if part in current_node.children:
            current_node = current_node.children[part]
        else:
            return None
    return current_node

def run_fd(start_dirs: List[str], ignore_patterns: List[str]) -> List[str]:
    """Runs the 'fd' command and captures its output."""
    try:
        command = ['fd', '--type', 'd', '--hidden', '--absolute-path', '.']
        
        for pattern in ignore_patterns:
            command.extend(['--exclude', pattern])
            
        command.extend(start_dirs)
        
        print(f"Running command: {' '.join(command)}")
        print("This might take a moment...")
        
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        # Also include the start_dirs themselves in the path list, as fd might not list them
        # if they are empty.
        all_paths = set(result.stdout.splitlines())
        all_paths.update(start_dirs)
        return sorted(list(all_paths))
    except FileNotFoundError:
        print("Error: 'fd' command not found. Please install it.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error running 'fd':\n{e.stderr}", file=sys.stderr)
        sys.exit(1)

# --- Interactive UI (No changes here) ---
def interactive_explorer(root: DirectoryNode, start_dirs: List[str]):
    """The main interactive loop for exploring the directory tree."""
    top_level_nodes = []
    for path in start_dirs:
        # Resolve symlinks and normalize path for consistency
        real_path = os.path.realpath(os.path.expanduser(path))
        node = find_node_by_path(root, real_path)
        if node:
            top_level_nodes.append(node)
        else:
            print(f"Warning: Start directory '{path}' (resolved to '{real_path}') not found by fd. Skipping.")

    current_node = None
    while True:
        os.system('cls' if os.name == 'nt' else 'clear')

        if current_node is None:
            print("--- Top Level Analysis ---")
            print("Showing total recursive directory entries for each starting path.\n")
            display_list = sorted(top_level_nodes, key=lambda n: n.total_entries, reverse=True)
            for i, node in enumerate(display_list):
                print(f" {i+1:>2}. {node.get_full_path()} ({node.total_entries} entries)")
        else:
            current_path = current_node.get_full_path()
            print(f"--- Analyzing: {current_path} ---")
            print(f"Total entries within this path: {current_node.total_entries}\n")
            display_list = sorted(current_node.children.values(), key=lambda n: n.total_entries, reverse=True)
            print("  0. .. (Go up)")
            for i, child in enumerate(display_list):
                dir_name = os.path.join(child.name, "")
                print(f" {i+1:>2}. {dir_name:<30} ({child.total_entries} entries)")

        print("\nEnter number to drill down, '..' or '0' to go up, 'q' to quit.")
        choice = input(">> ").strip()

        if choice.lower() == 'q': break
        elif choice in ('..', '0'):
            if current_node:
                parent = current_node.parent
                # Go to special top-level view if parent is root and not a start_dir itself
                if parent is root and parent not in top_level_nodes:
                    current_node = None
                else:
                    current_node = parent
            continue

        try:
            index = int(choice) - 1
            if index < 0: raise ValueError
            
            if current_node is None:
                if index < len(display_list): current_node = display_list[index]
            else:
                sorted_children = sorted(current_node.children.values(), key=lambda n: n.total_entries, reverse=True)
                if index < len(sorted_children): current_node = sorted_children[index]
        except (ValueError, IndexError):
            print("Invalid choice. Press Enter to continue.")
            input()

# --- Main Execution (Revised) ---
def main():
    """Parses arguments and orchestrates the script's execution."""
    parser = argparse.ArgumentParser(
        description="Interactively analyze directory entry counts.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        '-s', '--start-dir',
        action='append',
        dest='start_dirs',
        required=True, # We now require start dirs to be passed explicitly
        help='A directory to start searching from. Can be specified multiple times.\n(Required).'
    )
    parser.add_argument(
        '-i', '--ignore',
        action='append',
        dest='ignore_patterns',
        default=[],
        help='A directory name/pattern to ignore. Can be specified multiple times.'
    )
    args = parser.parse_args()

    # Expand user and get absolute paths for start directories
    start_dirs = [os.path.abspath(os.path.expanduser(d)) for d in args.start_dirs]
    ignore_patterns = args.ignore_patterns

    all_paths = run_fd(start_dirs, ignore_patterns)
    if not all_paths:
        print("No directories found. Exiting.")
        return

    root_node = build_tree(all_paths)
    
    print("Calculating total entries for all directories...")
    calculate_entries(root_node)
    
    interactive_explorer(root_node, start_dirs)

if __name__ == "__main__":
    main()
