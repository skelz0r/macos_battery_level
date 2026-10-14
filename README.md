# BatteryTime

Minimal macOS menu bar app displaying battery time remaining.

Requires macOS 26 (Liquid Glass).

![On battery](screenshots/on-battery.png) ![Charging](screenshots/charging.png) ![Calculating](screenshots/calculating.png)

## Display

| State | Time | % | Both |
|-------|------|---|------|
| On battery | `🔋3:45` | `🔋85%` | `🔋3:45 85%` |
| Charging | `⚡1:20` | `⚡60%` | `⚡1:20 60%` |
| Fully charged | `⚡` | `⚡100%` | `⚡100%` |
| Plugged in, not charging | `⚡` | `⚡80%` | `⚡80%` |
| Calculating | `🔋...` or `⚡...` | `🔋85%` or `⚡60%` | `🔋... 85%` or `⚡... 60%` |
| No battery | `No battery` | `No battery` | `No battery` |

## Panel

- Battery percentage, charge bar and time remaining
- Power drawn on battery (`Using 10.4 W`), or the charger's wattage and
  port when plugged in (`67W USB-C charger`)
- Charge level over the last 24 hours, plugged-in periods shaded green
- Processes using significant energy, with their app icon
- Menu bar title setting: time remaining (default), percentage or both
- Battery Settings shortcut
- Quit (⌘Q)

Energy use is measured with `top` when the panel opens, never in the
background: it takes a few seconds and the panel shows "Measuring energy
use..." meanwhile. Up to five apps or processes with an energy impact
of 20 or more are listed, the same figure as Activity Monitor's Energy
Impact column; clicking one opens Activity Monitor. Holding Option
turns the impact of each app into "Quit": an Option-click asks the app
to quit, as ⌘Q would. Processes that are not apps keep opening Activity
Monitor.

The charge history is sampled while the app runs, every five minutes or
on any change, and kept across restarts. The curve is cut wherever the
app was not running or the Mac was asleep for a while.

## Notifications

On battery, a notification when the charge drops to 20 % then to 10 %.
While plugged in, one when it reaches 80 % then 100 %. Each threshold
notifies once, then again only after the charge has gone back past it
the other way. macOS asks for permission on first launch.

## Install

```bash
./install.sh
```

Builds, copies to `/Applications`, and starts at login.

## Update

```bash
git pull
./install.sh
```

Replaces the installed app and restarts it.

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
