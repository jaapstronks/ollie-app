# Swift 6 Language Mode Migration

## Overview
Upgrade the project from Swift 5.0 language mode to Swift 6.0 to enable strict concurrency checking and catch data race bugs at compile time.

## Current State
- **Xcode project:** `SWIFT_VERSION = 5.0`
- **OllieShared package:** `swift-tools-version: 5.9`
- **Compiler:** Swift 6.x (running in Swift 5 compatibility mode)
- **Concurrency warnings:** Currently warnings, will become errors in Swift 6 mode

## Tasks

### 1. Update Version Settings
- [ ] Change `SWIFT_VERSION` to `6.0` in Xcode project build settings (all targets)
- [ ] Update `swift-tools-version: 6.0` in `OllieShared/Package.swift`

### 2. Fix Concurrency Errors
Common patterns to address:

**Actor isolation:**
- Add `@MainActor` to classes/structs that touch UI
- Add `nonisolated` to properties/methods that don't need actor isolation
- Use `@unchecked Sendable` sparingly for types that are thread-safe but can't prove it

**Sendable conformance:**
- Make value types `Sendable` where needed
- Mark classes as `final class ... : Sendable` or `@unchecked Sendable`
- Fix closures crossing actor boundaries

**Captured state in closures:**
- Avoid capturing `var` references in concurrent code (already fixed one in AtmosphereProvider)
- Use `[weak self]` with guard-let pattern before Task creation

### 3. Verify Third-Party Dependencies
- [ ] Sentry - appears Swift 6 ready (has Swift 6 sample project)
- [ ] Check any other SPM dependencies for Swift 6 compatibility

### 4. Test Thoroughly
- [ ] Run full test suite after migration
- [ ] Test CloudKit sync flows (PersistenceController uses concurrency heavily)
- [ ] Test notification scheduling
- [ ] Test background operations

## Already Fixed
- `AtmosphereProvider.swift:115` - Captured `self` in Timer closure (guard-let before Task)

## Known Issues to Address
These warnings currently appear and will become errors:
- Various `@MainActor` isolation issues (to be discovered when enabling Swift 6)
- Potential `Sendable` conformance gaps

## Approach
1. Create feature branch: `feature/swift6-migration`
2. Make version changes
3. Build and note all errors
4. Fix systematically by file/module
5. Run tests
6. Merge when stable

## Resources
- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/migrationguide/)
- [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

## Notes
- This is a maintenance task, not urgent
- Better to do in a focused session rather than alongside feature work
- Expect 20-50+ errors initially based on codebase size
