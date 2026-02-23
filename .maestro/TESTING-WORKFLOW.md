# Claude-in-the-Loop UI Testing Workflow

This document describes how to use Claude as an automated QA tester for the Ollie app.

## Overview

The workflow enables:
1. Running UI tests that simulate real user behavior
2. Capturing screenshots at key moments
3. Generating reports that Claude can analyze
4. Claude suggesting or implementing improvements based on findings
5. Optionally running autonomously with minimal human intervention

## Quick Start

### Run a full test suite and have Claude analyze it

```bash
# 1. Run the tests
./scripts/run-ui-tests.sh -a

# 2. In Claude Code, say:
"Read the test report at .maestro/reports/latest/test-report.md and review the screenshots"
```

### Run a specific scenario with instructions

```bash
./scripts/run-ui-tests.sh -s poop-tracker-test -i "Check if the poop warning shows after 12+ hours"
```

## Directory Structure

```
.maestro/
├── config.yaml              # Maestro configuration
├── flows/                   # Standard test flows
│   ├── launch-app.yaml
│   ├── navigate-tabs.yaml
│   ├── complete-user-journey.yaml
│   └── ...
├── scenarios/               # Feature-specific test scenarios
│   ├── poop-tracker-test.yaml
│   └── ...
├── reports/                 # Generated test reports
│   ├── latest -> 20240221_143022/  # Symlink to most recent
│   └── 20240221_143022/
│       ├── test-report.md   # Claude-parseable report
│       ├── maestro_output.txt
│       ├── junit.xml
│       └── *.png            # Screenshots
└── TESTING-WORKFLOW.md      # This file
```

## Commands

### Test Runner Script

```bash
./scripts/run-ui-tests.sh [OPTIONS]

Options:
  -f, --flow <name>        Run a specific flow
  -s, --scenario <file>    Run a scenario from scenarios/
  -a, --all                Run the full test suite
  -i, --instructions <text> Custom instructions for Claude
  -v, --verbose            Show real-time output
```

### Examples

```bash
# Full test suite
./scripts/run-ui-tests.sh -a

# Specific flow
./scripts/run-ui-tests.sh -f complete-user-journey

# Scenario with instructions
./scripts/run-ui-tests.sh -s poop-tracker-test -i "Verify the warning appears correctly"

# Verbose mode (see output in real-time)
./scripts/run-ui-tests.sh -a -v
```

## For Claude: Analyzing Test Results

When asked to analyze test results, follow this process:

### 1. Read the Report

```
Read .maestro/reports/latest/test-report.md
```

### 2. Review Screenshots

The report lists screenshot paths. Read each one to visually inspect the UI:

```
Read .maestro/reports/latest/screenshots/journey-01-launch.png
Read .maestro/reports/latest/screenshots/journey-02-scrolled.png
...
```

### 3. Check for Issues

Look for:
- **Visual bugs**: Misaligned elements, cut-off text, wrong colors
- **Navigation issues**: Unable to reach expected screens
- **Missing features**: Expected elements not visible
- **Accessibility**: Text too small, poor contrast, missing labels
- **UX concerns**: Confusing layout, unclear icons, missing feedback

### 4. Generate Analysis Report

After reviewing, provide:
1. **Pass/Fail Summary**: Did the tests pass?
2. **Visual Issues Found**: List any UI problems observed
3. **UX Observations**: Notes on usability
4. **Recommended Fixes**: Specific code changes to make
5. **New Tests Needed**: Additional scenarios to add

### 5. Implement Fixes (if requested)

If the user says "fix the issues" or similar:
1. Make the necessary code changes
2. Re-run the tests to verify
3. Report on the fix

## Creating Custom Scenarios

### Scenario Structure

```yaml
# scenarios/my-feature-test.yaml
appId: jaapstronks.Ollie-app
---
- launchApp
- waitForAnimationToEnd

# Step 1: Description
- extendedWaitUntil:
    visible: "Expected Text"
    timeout: 5000
- takeScreenshot: "screenshots/step-01-description"

# Step 2: Interact with element
- tapOn: "Button Label"
- waitForAnimationToEnd
- takeScreenshot: "screenshots/step-02-after-tap"

# Step 3: Verify result
- assertVisible: "Success Message"
```

### Common Actions

```yaml
# Tap on text/element
- tapOn: "Button Text"
- tapOn:
    id: "accessibility_id"

# Tap by position (for FAB, etc.)
- tapOn:
    point: "90%,80%"

# Long press
- longPressOn:
    point: "90%,80%"

# Type text
- inputText: "Hello World"

# Swipe
- swipe:
    start: "20%,50%"
    end: "80%,50%"

# Scroll
- scroll

# Wait
- waitForAnimationToEnd
- extendedWaitUntil:
    visible: "Text"
    timeout: 5000

# Screenshot
- takeScreenshot: "screenshots/name"

# Assert
- assertVisible: "Expected Text"
- assertNotVisible: "Should Not See"
```

## Autonomous Testing Mode

For running tests without human intervention:

### 1. Create a Test Plan

```bash
# Create a file describing what to test
echo "Test the following:
1. Log a poop event with 'outdoor' location
2. Check if the poop card shows the correct time
3. Navigate to Insights and verify poop frequency shows
4. Add a second poop event
5. Verify the warning doesn't show (since we just logged one)
" > test-plan.txt
```

### 2. Have Claude Generate and Run Tests

In Claude Code:
```
Read test-plan.txt, then:
1. Create a Maestro scenario for these tests
2. Run the scenario
3. Analyze the results
4. Fix any issues found
5. Re-run to verify fixes
```

### 3. Review Results Later

The reports are saved with timestamps, so you can review later:
```bash
ls .maestro/reports/
cat .maestro/reports/latest/test-report.md
```

## Integration with Development Workflow

### After Implementing a Feature

1. Create a scenario for the feature
2. Run: `./scripts/run-ui-tests.sh -s feature-name`
3. Ask Claude to analyze results
4. Fix any issues
5. Commit the scenario with the feature

### Before a Release

1. Run full suite: `./scripts/run-ui-tests.sh -a`
2. Ask Claude to review all screenshots
3. Fix any issues found
4. Document any known issues

### Debugging a Bug

1. Create a scenario that reproduces the bug
2. Run with verbose mode: `./scripts/run-ui-tests.sh -s bug-repro -v`
3. Analyze screenshots to understand the issue
4. Fix and verify

## Tips

- **Use descriptive screenshot names**: `poop-test-03-after-logging` is better than `step3`
- **Add comments in scenarios**: Use `# Comment` lines to document steps
- **Test multiple languages**: The app supports EN/NL, use `Text|Tekst` patterns
- **Check edge cases**: Empty states, long text, different data conditions
- **Run on different simulators**: Test on iPhone SE and iPhone Pro Max
