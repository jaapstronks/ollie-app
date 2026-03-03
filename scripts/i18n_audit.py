#!/usr/bin/env python3
"""
i18n Audit Script for Otis iOS App

Scans all .xcstrings files and reports:
- Missing translations per language
- Stale strings (may be removed from code)
- Translation coverage percentage
- Strings missing French (or any target language)

Usage:
    python scripts/i18n_audit.py                    # Full report
    python scripts/i18n_audit.py --summary          # Summary only
    python scripts/i18n_audit.py --missing fr       # Show strings missing French
    python scripts/i18n_audit.py --file Health      # Audit specific file
    python scripts/i18n_audit.py --json             # Output as JSON
    python scripts/i18n_audit.py --include-stale    # Include stale strings in counts

Note on "stale" strings:
    Xcode marks strings as "stale" when it can't verify them through extraction.
    This happens with custom table names (e.g., table: "Calendar") because Xcode's
    extraction always goes to Localizable.xcstrings regardless of the table parameter.

    Stale strings may still be ACTIVELY USED at runtime - the "stale" marking just
    means Xcode didn't extract them. Use --include-stale to count them.
"""

import json
import os
import sys
import argparse
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple, Any

# Configuration
SUPPORTED_LANGUAGES = ["en", "de", "es", "fr", "it", "nl"]
SOURCE_LANGUAGE = "en"
PROJECT_ROOT = Path(__file__).parent.parent
XCSTRINGS_DIRS = [
    PROJECT_ROOT / "Ollie-app",
    PROJECT_ROOT / "OllieWidget",
    PROJECT_ROOT / "OllieWatch Watch App",
]

# Files that use custom tables (Xcode marks these as stale but they're used at runtime)
# These are feature-specific string catalogs referenced via table: "TableName" in code
CUSTOM_TABLE_FILES = {
    "Calendar.xcstrings",
    "Common.xcstrings",
    "Contacts.xcstrings",
    "Development.xcstrings",
    "Documents.xcstrings",
    "Events.xcstrings",
    "FoodRecall.xcstrings",
    "Growth.xcstrings",
    "Health.xcstrings",
    "Medications.xcstrings",
    "Milestones.xcstrings",
    "Misc.xcstrings",
    "Onboarding.xcstrings",
    "OtisPlus.xcstrings",
    "Places.xcstrings",
    "Premium.xcstrings",
    "Settings.xcstrings",
    "Social.xcstrings",
    "SocializationItems.xcstrings",
    "Timeline.xcstrings",
    "Toast.xcstrings",
    "Training.xcstrings",
    "TrainingSession.xcstrings",
    "Walks.xcstrings",
    "WalkSchedule.xcstrings",
    "Widgets.xcstrings",
}


def find_xcstrings_files() -> List[Path]:
    """Find all .xcstrings files in the project."""
    files = []
    for directory in XCSTRINGS_DIRS:
        if directory.exists():
            files.extend(directory.rglob("*.xcstrings"))
    return sorted(files)


def parse_xcstrings(file_path: Path) -> Dict[str, Any]:
    """Parse an .xcstrings file and return its contents."""
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def audit_file(file_path: Path, target_languages: List[str] = None, include_stale: bool = False) -> Dict[str, Any]:
    """
    Audit a single .xcstrings file.

    Args:
        file_path: Path to the .xcstrings file
        target_languages: Languages to check (defaults to all except source)
        include_stale: If True, include stale strings in translation counts.
                       For custom table files, stale strings are often still used at runtime.

    Returns a dict with:
    - total_strings: number of strings
    - stale_strings: list of strings marked stale
    - missing_by_language: dict of language -> list of missing string keys
    - coverage_by_language: dict of language -> percentage
    """
    if target_languages is None:
        target_languages = [lang for lang in SUPPORTED_LANGUAGES if lang != SOURCE_LANGUAGE]

    data = parse_xcstrings(file_path)
    strings = data.get("strings", {})

    # Auto-include stale for custom table files (they're used at runtime)
    is_custom_table_file = file_path.name in CUSTOM_TABLE_FILES
    count_stale = include_stale or is_custom_table_file

    result = {
        "file": file_path.name,
        "path": str(file_path.relative_to(PROJECT_ROOT)),
        "total_strings": 0,
        "active_strings": 0,
        "stale_strings": [],
        "counted_strings": 0,  # Strings counted for translation (active + maybe stale)
        "is_custom_table": is_custom_table_file,
        "missing_by_language": {lang: [] for lang in target_languages},
        "coverage_by_language": {lang: 0.0 for lang in target_languages},
    }

    for key, value in strings.items():
        result["total_strings"] += 1

        # Check if stale
        extraction_state = value.get("extractionState", "")
        is_stale = extraction_state == "stale"

        if is_stale:
            result["stale_strings"].append(key)
        else:
            result["active_strings"] += 1

        # Determine if we should count this string for translation coverage
        should_count = not is_stale or count_stale

        if should_count:
            result["counted_strings"] += 1
            localizations = value.get("localizations", {})
            for lang in target_languages:
                if lang not in localizations:
                    result["missing_by_language"][lang].append(key)
                else:
                    # Check if it has a valid translation
                    lang_data = localizations[lang]
                    if "stringUnit" in lang_data:
                        state = lang_data["stringUnit"].get("state", "")
                        if state != "translated":
                            result["missing_by_language"][lang].append(key)
                    elif "variations" in lang_data:
                        # Plural variations - consider translated if variations exist
                        pass
                    else:
                        result["missing_by_language"][lang].append(key)

    # Calculate coverage
    for lang in target_languages:
        if result["counted_strings"] > 0:
            translated = result["counted_strings"] - len(result["missing_by_language"][lang])
            result["coverage_by_language"][lang] = round(
                (translated / result["counted_strings"]) * 100, 1
            )

    return result


def audit_all_files(target_languages: List[str] = None, include_stale: bool = False) -> List[Dict[str, Any]]:
    """Audit all .xcstrings files in the project."""
    files = find_xcstrings_files()
    results = []
    for file_path in files:
        try:
            result = audit_file(file_path, target_languages, include_stale)
            results.append(result)
        except Exception as e:
            print(f"Error parsing {file_path}: {e}", file=sys.stderr)
    return results


def print_summary(results: List[Dict[str, Any]], target_languages: List[str] = None):
    """Print a summary of translation coverage."""
    if target_languages is None:
        target_languages = [lang for lang in SUPPORTED_LANGUAGES if lang != SOURCE_LANGUAGE]

    print("=" * 70)
    print("i18n AUDIT SUMMARY")
    print("=" * 70)
    print()

    total_counted = sum(r["counted_strings"] for r in results)
    total_active = sum(r["active_strings"] for r in results)
    total_stale = sum(len(r["stale_strings"]) for r in results)
    custom_table_files = sum(1 for r in results if r.get("is_custom_table"))

    print(f"Total files:              {len(results)}")
    print(f"  Custom table files:     {custom_table_files} (stale strings still counted)")
    print(f"Total strings counted:    {total_counted}")
    print(f"  Xcode-extracted:        {total_active}")
    print(f"  Stale (in custom tables): {total_stale}")
    print()

    # Coverage by language
    print("COVERAGE BY LANGUAGE:")
    print("-" * 50)
    for lang in target_languages:
        total_missing = sum(len(r["missing_by_language"][lang]) for r in results)
        total_translated = total_counted - total_missing
        coverage = (total_translated / total_counted * 100) if total_counted > 0 else 0
        bar_width = 20
        filled = int(coverage / 100 * bar_width)
        bar = "█" * filled + "░" * (bar_width - filled)
        print(f"  {lang.upper()}: {bar} {coverage:5.1f}% ({total_translated:>4}/{total_counted}) - {total_missing} missing")
    print()

    # Files with lowest coverage
    print("FILES NEEDING MOST WORK (by French coverage):")
    print("-" * 50)
    sorted_results = sorted(results, key=lambda r: r["coverage_by_language"].get("fr", 100))
    shown = 0
    for r in sorted_results:
        if shown >= 15:
            break
        fr_coverage = r["coverage_by_language"].get("fr", 100)
        missing_count = len(r["missing_by_language"].get("fr", []))
        if missing_count > 0:
            marker = " (custom)" if r.get("is_custom_table") else ""
            print(f"  {r['file']:<35} {fr_coverage:5.1f}% ({missing_count:>3} missing){marker}")
            shown += 1
    print()


def print_detailed_report(results: List[Dict[str, Any]], target_languages: List[str] = None):
    """Print detailed report for each file."""
    if target_languages is None:
        target_languages = [lang for lang in SUPPORTED_LANGUAGES if lang != SOURCE_LANGUAGE]

    print_summary(results, target_languages)

    print("=" * 70)
    print("DETAILED REPORT BY FILE")
    print("=" * 70)

    for r in results:
        has_missing = any(len(r["missing_by_language"][lang]) > 0 for lang in target_languages)

        if not has_missing:
            continue

        print()
        is_custom = " (custom table)" if r.get("is_custom_table") else ""
        print(f"📁 {r['file']}{is_custom}")
        print(f"   Path: {r['path']}")
        print(f"   Strings: {r['counted_strings']} counted ({r['active_strings']} extracted, {len(r['stale_strings'])} stale)")

        # Coverage
        coverage_parts = []
        for lang in target_languages:
            cov = r["coverage_by_language"][lang]
            missing = len(r["missing_by_language"][lang])
            if missing > 0:
                coverage_parts.append(f"{lang.upper()}:{cov:.0f}%({missing})")
        if coverage_parts:
            print(f"   Coverage: {', '.join(coverage_parts)}")


def print_missing_translations(results: List[Dict[str, Any]], language: str):
    """Print all strings missing translations for a specific language."""
    print(f"STRINGS MISSING {language.upper()} TRANSLATION")
    print("=" * 70)

    total_missing = 0
    for r in results:
        missing = r["missing_by_language"].get(language, [])
        if missing:
            print()
            print(f"📁 {r['file']} ({len(missing)} missing)")
            print("-" * 40)
            for key in missing:
                display_key = key[:70] + "..." if len(key) > 70 else key
                print(f"  • {display_key}")
            total_missing += len(missing)

    print()
    print(f"Total missing {language.upper()} translations: {total_missing}")


def export_for_translation(results: List[Dict[str, Any]], language: str, output_file: str = None):
    """
    Export missing translations in a format ready for translation.

    Outputs JSON that can be:
    1. Translated (fill in the 'value' fields)
    2. Fed directly to i18n_apply.py
    """
    export_data = {
        "language": language,
        "instructions": "Translate the 'value' field from English. Keep placeholders like %@, %lld, ${...} intact.",
        "translations": []
    }

    for r in results:
        file_path = Path(r["path"])
        missing_keys = r["missing_by_language"].get(language, [])

        if not missing_keys:
            continue

        # Load the file to get English values
        try:
            full_path = PROJECT_ROOT / file_path
            with open(full_path, "r", encoding="utf-8") as f:
                xcstrings_data = json.load(f)

            strings = xcstrings_data.get("strings", {})

            for key in missing_keys:
                # The key itself is the English string in most cases
                # But check if there's an explicit English localization
                english_value = key  # Default: key is the English string

                if key in strings:
                    localizations = strings[key].get("localizations", {})
                    if "en" in localizations:
                        en_data = localizations["en"]
                        if "stringUnit" in en_data:
                            english_value = en_data["stringUnit"].get("value", key)

                export_data["translations"].append({
                    "file": r["file"],
                    "key": key,
                    "english": english_value,
                    "value": ""  # To be filled in
                })

        except Exception as e:
            print(f"Warning: Could not read {r['file']}: {e}", file=sys.stderr)

    # Output
    output_json = json.dumps(export_data, indent=2, ensure_ascii=False)

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(output_json)
            f.write("\n")
        print(f"Exported {len(export_data['translations'])} strings to {output_file}")
    else:
        print(output_json)

    return len(export_data["translations"])


def output_json(results: List[Dict[str, Any]]):
    """Output results as JSON."""
    print(json.dumps(results, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Audit i18n translations in .xcstrings files")
    parser.add_argument("--summary", action="store_true", help="Show summary only")
    parser.add_argument("--missing", metavar="LANG", help="Show strings missing for language (e.g., fr)")
    parser.add_argument("--export", metavar="LANG", help="Export missing strings for translation (e.g., fr)")
    parser.add_argument("--output", "-o", metavar="FILE", help="Output file for --export (default: stdout)")
    parser.add_argument("--file", metavar="NAME", help="Audit specific file (partial match)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--languages", metavar="LANGS", help="Comma-separated languages to check (default: de,es,fr,it,nl)")
    parser.add_argument("--include-stale", action="store_true",
                        help="Include stale strings in counts for ALL files (by default, only custom table files include stale)")

    args = parser.parse_args()

    # Parse languages
    target_languages = None
    if args.languages:
        target_languages = [l.strip() for l in args.languages.split(",")]

    # Get results
    include_stale = getattr(args, 'include_stale', False)
    results = audit_all_files(target_languages, include_stale)

    # Filter by file if specified
    if args.file:
        results = [r for r in results if args.file.lower() in r["file"].lower()]
        if not results:
            print(f"No files matching '{args.file}' found.")
            sys.exit(1)

    # Output
    if args.json:
        output_json(results)
    elif args.export:
        export_for_translation(results, args.export, args.output)
    elif args.missing:
        print_missing_translations(results, args.missing)
    elif args.summary:
        print_summary(results, target_languages)
    else:
        print_detailed_report(results, target_languages)


if __name__ == "__main__":
    main()
