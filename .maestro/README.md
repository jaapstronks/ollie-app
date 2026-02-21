# Ollie App - UI Testing

This directory contains automated UI tests using Maestro.

## Setup

### 1. Install Java (required by Maestro)

```bash
brew install --cask temurin
```

### 2. Verify Maestro is installed

```bash
export PATH="$PATH:$HOME/.maestro/bin"
maestro --version
```

## Running Tests

### Run a single flow

```bash
maestro test .maestro/flows/launch-app.yaml
```

### Run the full test suite

```bash
maestro test .maestro/flows/full-test-suite.yaml
```

### Run all flows in the directory

```bash
maestro test .maestro/flows/
```

## Available Test Flows

| Flow | Description |
|------|-------------|
| `launch-app.yaml` | Basic app launch verification |
| `navigate-tabs.yaml` | Tab navigation (Today <-> Insights) |
| `fab-quick-log.yaml` | FAB long-press quick menu |
| `log-event.yaml` | Open event logging sheet |
| `settings.yaml` | Open and close settings |
| `full-test-suite.yaml` | Runs all flows sequentially |

## Screenshots

Screenshots are saved to `.maestro/screenshots/` during test runs.

## Tips

- Use `maestro studio` for interactive test development
- Run `maestro hierarchy` to inspect the current UI element tree
- Add `--debug` flag for verbose output

## Accessibility Identifiers

These identifiers are available for targeting UI elements:

| Identifier | Element |
|------------|---------|
| `FAB_BUTTON` | Floating Action Button |
| `settings_button` | Settings gear icon |

## Note on Language

The app supports English and Dutch. Maestro flows use `Text|Tekst` pattern to match either language.
