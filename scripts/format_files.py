#!/usr/bin/env python3
import sys
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


def display_file_contents(file_paths):
    for file_path_str in file_paths:
        file_path = Path(file_path_str)

        print(file_path_str)
        print()

        try:
            with open(file_path, "r", encoding="utf-8") as file:
                file_contents = file.read()
                code_block_language = get_file_extension_for_code_block(file_path_str)

                print(f"```{code_block_language}")
                print(file_contents, end="")
                print("```")
        except FileNotFoundError:
            print(f"Error: File '{file_path_str}' not found")
        except UnicodeDecodeError:
            print(f"Error: Could not decode '{file_path_str}' as UTF-8 text")
        except PermissionError:
            print(f"Error: Permission denied reading '{file_path_str}'")
        except Exception as e:
            print(f"Error reading '{file_path_str}': {e}")

        print()


def main():
    if len(sys.argv) < 2:
        print("Usage: format_files.py <file1> <file2> ...")
        print("Example: format_files.py a.py b/c.tsx")
        sys.exit(1)

    file_paths = sys.argv[1:]
    display_file_contents(file_paths)


if __name__ == "__main__":
    main()
