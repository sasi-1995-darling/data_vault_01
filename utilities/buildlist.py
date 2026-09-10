import argparse
import subprocess
import os
import sys

def show_help():
    print("Usage: python buildlist.py [options]")
    print("")
    print("Options:")
    print("  -h, --help         Show this help message")
    print("  --diff-only        Show only the diff of .sql files")
    print("  --build-only       Show only the dbt build command")
    print("  --full-refresh     Include the --full-refresh flag in the dbt build command")
    print("  --upstream         Include the + before each SQL file to build all upstream dependencies")
    print("  --downstream       Include the + after each SQL file to build all downstream dependencies")
    print("  (no options)       Show both the diff and the dbt build command")

def fetch_changes():
    """Fetch latest changes from origin. Exits gracefully on network failure."""
    try:
        subprocess.run(["git", "fetch", "origin"], check=True,
                       capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"WARNING: git fetch failed — working with local state only.")
        print(f"  (Network issue or no remote configured: {e.stderr.strip()})")
    except FileNotFoundError:
        print("ERROR: git not found on PATH.")
        sys.exit(1)

def get_repo_root():
    result = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
    return result.stdout.strip()

def get_changed_sql_files(repo_root):
    result = subprocess.run(["git", "-C", repo_root, "diff", "--name-only", "origin/main"], capture_output=True, text=True, check=True)
    changed_files = [line for line in result.stdout.splitlines() if line.endswith('.sql')]
    return changed_files

def main():
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument('--diff-only', action='store_true', help='Show only the diff of .sql files')
    parser.add_argument('--build-only', action='store_true', help='Show only the dbt build command')
    parser.add_argument('--full-refresh', action='store_true', help='Include the --full-refresh flag in the dbt build command')
    parser.add_argument('--upstream', action='store_true', help='Include the + before each SQL file to build all upstream dependencies')
    parser.add_argument('--downstream', action='store_true', help='Include the + after each SQL file to build all downstream dependencies')

    args = parser.parse_args()

    fetch_changes()
    repo_root = get_repo_root()
    changed_files = get_changed_sql_files(repo_root)

    if not changed_files:
        print("No changes detected. There are no .sql files to build.")
        return

    if args.diff_only or not args.build_only:
        print("Changed .sql files:")
        for file in changed_files:
            print(f"  {file}")
        print("")

    if args.build_only or not args.diff_only:
        dbt_command = "dbt build --select"
        for file in changed_files:
            file_name = os.path.splitext(os.path.basename(file))[0]
            prefix = "+" if args.upstream else ""
            suffix = "+" if args.downstream else ""
            dbt_command += f" {prefix}{file_name}{suffix}"

        if args.full_refresh:
            dbt_command += " --full-refresh"

        dbt_command += " --exclude 'ref_business_key_collision'"

        print("DBT Build Command:")
        print(f"  {dbt_command}")

    if not args.diff_only and not args.build_only:
        print("")
        print("Both diff and build command shown above.")

if __name__ == "__main__":
    main()