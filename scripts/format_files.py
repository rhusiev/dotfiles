#!/usr/bin/env python3
import sys
import re
import argparse
from pathlib import Path


def get_file_extension_for_code_block(file_path):
    extension_map = {
        ".py": "py",
        ".tsx": "tsx",
        ".ts": "ts",
        ".js": "js",
        ".jsx": "jsx",
        ".cpp": "cpp",
        ".c": "c",
        ".h": "h",
        ".hpp": "hpp",
        ".rs": "rust",
        ".java": "java",
        ".sh": "bash",
        ".bash": "bash",
        ".zsh": "zsh",
        ".fish": "fish",
        ".html": "html",
        ".css": "css",
        ".scss": "scss",
        ".json": "json",
        ".yaml": "yaml",
        ".yml": "yaml",
        ".xml": "xml",
        ".md": "markdown",
        ".sql": "sql",
        ".go": "go",
        ".rb": "ruby",
        ".php": "php",
        ".swift": "swift",
        ".kt": "kotlin",
        ".scala": "scala",
        ".clj": "clojure",
        ".vim": "vim",
        ".lua": "lua",
        ".r": "r",
        ".m": "matlab",
        ".pl": "perl",
        ".tex": "latex",
        ".dockerfile": "dockerfile",
        ".gitignore": "gitignore",
        ".env": "bash",
        ".toml": "toml",
        ".ini": "ini",
        ".cfg": "ini",
        ".conf": "conf",
        ".properties": "properties",
    }

    file_suffix = Path(file_path).suffix.lower()
    file_name = Path(file_path).name.lower()

    if file_name == "dockerfile":
        return "dockerfile"
    elif file_name.startswith(".env"):
        return "bash"
    elif file_name in [".gitignore", ".dockerignore"]:
        return "gitignore"
    elif file_name == "makefile":
        return "makefile"

    return extension_map.get(file_suffix, "text")


def display_file_contents(file_paths, ignore_pattern=None):
    compiled_pattern = None
    if ignore_pattern:
        try:
            compiled_pattern = re.compile(ignore_pattern)
        except re.error as e:
            print(f"Error: Invalid regular expression provided: {e}")
            sys.exit(1)

    for file_path_str in file_paths:
        file_path = Path(file_path_str)
        
        file_contents = None
        error_msg = None

        try:
            with open(file_path, "r", encoding="utf-8") as file:
                file_contents = file.read()
        except FileNotFoundError:
            error_msg = f"Error: File '{file_path_str}' not found"
        except UnicodeDecodeError:
            error_msg = f"Error: Could not decode '{file_path_str}' as UTF-8 text"
        except PermissionError:
            error_msg = f"Error: Permission denied reading '{file_path_str}'"
        except Exception as e:
            error_msg = f"Error reading '{file_path_str}': {e}"

        if error_msg:
            print(file_path_str)
            print()
            print(error_msg)
            print()
            continue

        if compiled_pattern and compiled_pattern.search(file_contents):
            continue

        code_block_language = get_file_extension_for_code_block(file_path_str)

        print(f"{file_path_str}:")
        print()
        print(f"```{code_block_language}")
        print(file_contents)
        print("```")
        print()


def main():
    parser = argparse.ArgumentParser(
        description="Format files into markdown code blocks."
    )
    
    parser.add_argument(
        "-i", 
        "--ignore-pattern", 
        type=str, 
        help="A regex pattern. If a file's content matches this pattern, it will be skipped."
    )
    
    parser.add_argument(
        "files", 
        nargs="+", 
        help="The files you want to read and format."
    )

    args = parser.parse_args()

    display_file_contents(args.files, args.ignore_pattern)


if __name__ == "__main__":
    main()
