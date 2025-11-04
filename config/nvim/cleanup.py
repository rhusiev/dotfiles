import time
from pathlib import Path
import argparse


def delete_old_files(path: Path, days: int) -> None:
    current_time = time.time()
    cutoff_time = current_time - (days * 86400)

    deleted_count = 0
    error_count = 0

    for file_path in path.rglob("*"):
        if file_path.is_file():
            try:
                file_modified_time = file_path.stat().st_mtime
                if file_modified_time < cutoff_time:
                    file_path.unlink()
                    deleted_count += 1
                    print(f"Deleted: {file_path}")
            except Exception as e:
                error_count += 1
                print(f"Error deleting {file_path}: {e}")

    print(f"\nSummary: {deleted_count} files deleted, {error_count} errors")


def main():
    parser = argparse.ArgumentParser(
        description="Delete files older than specified number of days"
    )
    parser.add_argument(
        "path",
        nargs="?",
        default="~/.local/share/nvim/undodir",
        help="Directory path to clean (default: ~/.local/share/nvim/undodir)",
    )
    parser.add_argument(
        "days",
        nargs="?",
        type=int,
        default=30,
        help="Delete files older than this many days (default: 30)",
    )

    args = parser.parse_args()
    target_path = Path(args.path).expanduser().resolve()

    if not target_path.exists():
        print(f"Error: Path '{target_path}' does not exist")
        return

    if not target_path.is_dir():
        print(f"Error: '{target_path}' is not a directory")
        return

    print(f"Deleting files older than {args.days} days from: {target_path}")
    delete_old_files(target_path, args.days)


if __name__ == "__main__":
    main()
