#!/usr/bin/env python3
"""Compare two Steampipe CLI snapshots and emit a Markdown diff report."""

import argparse
import json
import sys


def load(path):
    with open(path) as f:
        return json.load(f)


def diff_list(label, old, new):
    old_set = set(old or [])
    new_set = set(new or [])
    added = sorted(new_set - old_set)
    removed = sorted(old_set - new_set)
    lines = []
    if added or removed:
        lines.append(f"#### {label}")
        for item in added:
            lines.append(f"- ✅ `{item}` *(added)*")
        for item in removed:
            lines.append(f"- ❌ `{item}` *(removed)*")
    return lines


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("old", help="Path to old snapshot JSON")
    parser.add_argument("new", help="Path to new snapshot JSON")
    parser.add_argument("--output-md", required=True, help="Output Markdown file path")
    args = parser.parse_args()

    try:
        old = load(args.old)
    except Exception as e:
        old = {}
        print(f"Warning: could not load old snapshot: {e}", file=sys.stderr)

    try:
        new = load(args.new)
    except Exception as e:
        print(f"Error: could not load new snapshot: {e}", file=sys.stderr)
        sys.exit(1)

    sections = []

    sections += diff_list("Subcommands", old.get("subcommands"), new.get("subcommands"))
    sections += diff_list("`service` flags", old.get("service_start_flags"), new.get("service_start_flags"))
    sections += diff_list("`query` flags", old.get("query_flags"), new.get("query_flags"))
    sections += diff_list("`plugin` flags", old.get("plugin_flags"), new.get("plugin_flags"))
    sections += diff_list("Environment variables", old.get("env_vars"), new.get("env_vars"))

    hash_fields = ["help_text_hash", "service_help_hash", "query_help_hash"]
    hash_changes = []
    for field in hash_fields:
        old_val = old.get(field, "")
        new_val = new.get(field, "")
        if old_val != new_val:
            hash_changes.append(f"- `{field}`: `{old_val}` → `{new_val}`")

    if hash_changes:
        sections.append("#### Help text hashes")
        sections += hash_changes

    old_ver = old.get("version", "unknown")
    new_ver = new.get("version", "unknown")

    with open(args.output_md, "w") as f:
        if sections:
            f.write(f"<details>\n<summary>CLI changes between <code>{old_ver}</code> and <code>{new_ver}</code></summary>\n\n")
            f.write("\n".join(sections))
            f.write("\n\n</details>\n")
            print(f"Changes found between {old_ver} and {new_ver}")
            sys.exit(1)
        else:
            f.write(f"No CLI changes detected between `{old_ver}` and `{new_ver}`.\n")
            print(f"No changes between {old_ver} and {new_ver}")
            sys.exit(0)


if __name__ == "__main__":
    main()
