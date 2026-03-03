#!/usr/bin/env python3
"""
i18n Translation Applier for Otis iOS App

Applies translations from a JSON file to .xcstrings files.

Usage:
    # Apply translations from a JSON file
    python scripts/i18n_apply.py translations.json

    # Dry run (show what would change without applying)
    python scripts/i18n_apply.py translations.json --dry-run

    # Apply to specific file only
    python scripts/i18n_apply.py translations.json --file Health.xcstrings

Input format (translations.json):
{
    "translations": [
        {
            "file": "Health.xcstrings",       // Target file (optional, will search if omitted)
            "key": "Weight",                   // String key (required)
            "language": "fr",                  // Target language (required)
            "value": "Poids"                   // Translation (required)
        },
        ...
    ]
}

Or simplified format (assumes single file):
{
    "file": "Health.xcstrings",
    "language": "fr",
    "translations": {
        "Weight": "Poids",
        "Height": "Taille",
        ...
    }
}
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent
XCSTRINGS_DIRS = [
    PROJECT_ROOT / "Ollie-app",
    PROJECT_ROOT / "OllieWidget",
    PROJECT_ROOT / "OllieWatch Watch App",
]


def find_xcstrings_file(filename: str) -> Optional[Path]:
    """Find an .xcstrings file by name."""
    for directory in XCSTRINGS_DIRS:
        if directory.exists():
            for file_path in directory.rglob("*.xcstrings"):
                if file_path.name == filename:
                    return file_path
    return None


def find_string_in_files(key: str) -> List[Path]:
    """Find which .xcstrings files contain a given key."""
    matches = []
    for directory in XCSTRINGS_DIRS:
        if directory.exists():
            for file_path in directory.rglob("*.xcstrings"):
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    if key in data.get("strings", {}):
                        matches.append(file_path)
                except Exception:
                    pass
    return matches


def load_xcstrings(file_path: Path) -> Dict[str, Any]:
    """Load an .xcstrings file."""
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_xcstrings(file_path: Path, data: Dict[str, Any]):
    """Save an .xcstrings file with proper formatting."""
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")  # Trailing newline


def apply_translation(data: Dict[str, Any], key: str, language: str, value: str) -> bool:
    """
    Apply a single translation to the data structure.
    Returns True if applied, False if key not found.
    """
    strings = data.get("strings", {})

    if key not in strings:
        return False

    # Ensure localizations dict exists
    if "localizations" not in strings[key]:
        strings[key]["localizations"] = {}

    # Add or update the translation
    strings[key]["localizations"][language] = {
        "stringUnit": {
            "state": "translated",
            "value": value
        }
    }

    return True


def parse_input_file(input_path: Path) -> List[Dict[str, str]]:
    """
    Parse the input JSON file and return a list of translation entries.
    Each entry has: file (optional), key, language, value

    Supported formats:
    1. List of objects with per-item language: {"translations": [{"key": "...", "language": "fr", "value": "..."}]}
    2. List with global language: {"language": "fr", "translations": [{"key": "...", "value": "..."}]}
    3. Dict with global language: {"language": "fr", "translations": {"key": "value", ...}}
    """
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    translations = []
    default_lang = data.get("language")
    default_file = data.get("file")

    # Format 1 & 2: List of translation objects
    if "translations" in data and isinstance(data["translations"], list):
        for item in data["translations"]:
            # Use item's language if present, otherwise fall back to default
            lang = item.get("language", default_lang)
            if not lang:
                raise ValueError(f"No language specified for key: {item.get('key')}")

            translations.append({
                "file": item.get("file", default_file),
                "key": item["key"],
                "language": lang,
                "value": item["value"]
            })

    # Format 3: Dict of key->value
    elif "translations" in data and isinstance(data["translations"], dict):
        if not default_lang:
            raise ValueError("Dict format requires 'language' field at top level")

        for key, value in data["translations"].items():
            translations.append({
                "file": default_file,
                "key": key,
                "language": default_lang,
                "value": value
            })

    else:
        raise ValueError("Invalid input format. Expected 'translations' key.")

    return translations


def apply_translations(translations: List[Dict[str, str]],
                       dry_run: bool = False,
                       target_file: Optional[str] = None) -> Dict[str, Any]:
    """
    Apply all translations to the appropriate .xcstrings files.

    Returns a summary dict with counts of applied, skipped, and errors.
    """
    # Group translations by file
    by_file: Dict[str, List[Dict[str, str]]] = defaultdict(list)
    no_file: List[Dict[str, str]] = []

    for t in translations:
        if t.get("file"):
            by_file[t["file"]].append(t)
        else:
            no_file.append(t)

    # For translations without a file, try to find the right file
    for t in no_file:
        matches = find_string_in_files(t["key"])
        if len(matches) == 1:
            by_file[matches[0].name].append(t)
        elif len(matches) > 1:
            # Prefer custom table files over Localizable.xcstrings
            non_localizable = [m for m in matches if m.name != "Localizable.xcstrings"]
            if len(non_localizable) == 1:
                by_file[non_localizable[0].name].append(t)
            else:
                print(f"Warning: Key '{t['key']}' found in multiple files: {[m.name for m in matches]}")
                by_file[matches[0].name].append(t)
        else:
            print(f"Warning: Key '{t['key']}' not found in any file")

    # Filter to target file if specified
    if target_file:
        by_file = {k: v for k, v in by_file.items() if target_file.lower() in k.lower()}

    # Apply translations
    summary = {
        "files_modified": 0,
        "translations_applied": 0,
        "translations_skipped": 0,
        "errors": []
    }

    for filename, file_translations in by_file.items():
        file_path = find_xcstrings_file(filename)
        if not file_path:
            summary["errors"].append(f"File not found: {filename}")
            continue

        try:
            data = load_xcstrings(file_path)
            applied_count = 0

            for t in file_translations:
                if apply_translation(data, t["key"], t["language"], t["value"]):
                    applied_count += 1
                    if dry_run:
                        print(f"  Would apply: [{t['language']}] {t['key'][:50]}...")
                else:
                    summary["translations_skipped"] += 1
                    print(f"  Skipped (key not found): {t['key']}")

            if applied_count > 0:
                if not dry_run:
                    save_xcstrings(file_path, data)
                summary["files_modified"] += 1
                summary["translations_applied"] += applied_count
                print(f"{'Would modify' if dry_run else 'Modified'}: {filename} ({applied_count} translations)")

        except Exception as e:
            summary["errors"].append(f"Error processing {filename}: {e}")

    return summary


def main():
    parser = argparse.ArgumentParser(description="Apply translations to .xcstrings files")
    parser.add_argument("input", help="JSON file containing translations")
    parser.add_argument("--dry-run", action="store_true", help="Show what would change without applying")
    parser.add_argument("--file", metavar="NAME", help="Only apply to specific file (partial match)")

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)

    try:
        translations = parse_input_file(input_path)
        print(f"Loaded {len(translations)} translations from {input_path.name}")
        print()

        summary = apply_translations(
            translations,
            dry_run=args.dry_run,
            target_file=args.file
        )

        print()
        print("=" * 50)
        print("SUMMARY")
        print("=" * 50)
        print(f"Files modified:        {summary['files_modified']}")
        print(f"Translations applied:  {summary['translations_applied']}")
        print(f"Translations skipped:  {summary['translations_skipped']}")

        if summary["errors"]:
            print(f"Errors:                {len(summary['errors'])}")
            for error in summary["errors"]:
                print(f"  - {error}")

        if args.dry_run:
            print()
            print("(Dry run - no changes were made)")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
