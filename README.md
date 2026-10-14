# BatteryTime

Minimal macOS menu bar app displaying battery time remaining.

![On battery](screenshots/on-battery.png) ![Charging](screenshots/charging.png) ![Calculating](screenshots/calculating.png)

## Display

| State | Display |
|-------|---------|
| On battery | `🔋3:45` |
| Charging | `⚡1:20` |
| Fully charged | `⚡` |
| Plugged in, not charging | `⚡` |
| Calculating | `🔋...` or `⚡...` |
| No battery | `No battery` |

## Menu

- Battery percentage
- Processes using significant energy, if any
- Battery Settings shortcut

Energy use is measured with `top` when the menu opens, never in the
background: it takes a few seconds and the menu shows "Measuring energy
use..." meanwhile. Up to five apps or processes with an energy impact
of 20 or more are listed, the same figure as Activity Monitor's Energy
Impact column; clicking one opens Activity Monitor.

## Install

```bash
./install.sh
```

Builds, copies to `/Applications`, and starts at login.

## Uninstall

```bash
./uninstall.sh
```

## Build only

```bash
./build.sh
open BatteryTime.app
```

## Test

```bash
swift test
```

## Lint

```bash
bin/lint
```

Runs `swift format` (shipped with the Swift toolchain) and `swiftlint`
(`brew install swiftlint`) in strict mode. `bin/lint --fix` applies
automatic corrections first.
