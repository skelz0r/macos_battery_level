<p align="center">
  <img src="docs/logo.svg" width="112" alt="BatteryTime logo">
</p>

<h1 align="center">BatteryTime</h1>

<p align="center">
  <b>The battery time remaining, back in the macOS menu bar.</b><br>
  A minimal menu bar app with a Liquid Glass panel for charge, power
  draw, history, health and energy hogs.
</p>

<p align="center">
  <img src="screenshots/panel.png" width="336" alt="The panel: charge, charger, health, 24-hour history and energy hogs">
</p>

<p align="center">
  <img src="screenshots/on-battery.png" width="102" alt="On battery: battery icon and time remaining">
  &nbsp;
  <img src="screenshots/low-battery.png" width="102" alt="Low battery: time remaining in orange">
  &nbsp;
  <img src="screenshots/charging.png" width="100" alt="Charging: charging battery icon and time to full">
  &nbsp;
  <img src="screenshots/calculating.png" width="85" alt="Calculating the time remaining">
</p>

macOS no longer shows how long the battery will last. BatteryTime puts
it next to the battery icon, colors it when the charge runs low, and
opens a panel with everything worth knowing about the battery: what
draws power, how the charge evolved over the day, and how worn the
battery is.

## Highlights

- **Time at a glance.** Time remaining on battery, time to full while
  charging, right in the menu bar.
- **Warns before it's too late.** The title turns orange at 20 %, red at
  10 %, and a notification follows.
- **Finds what drains it.** The apps with a significant energy impact,
  with their icon; Option-click to quit one.
- **The last 24 hours.** A charge curve with plugged-in periods shaded.
- **Battery health.** Cycle count, maximum capacity and condition, as in
  System Settings.
- **Quiet.** Follows power source events instead of polling; energy use
  is only measured while the panel is open.

## Menu bar

| State | Display |
|-------|---------|
| On battery | battery icon then `3:45` |
| Charging | charging battery icon then `1:20` |
| Fully charged | charging battery icon |
| Plugged in, not charging | charging battery icon |
| Calculating | battery icon or charging battery icon, then `...` |
| No battery | `No battery` |

On battery, the battery icon shows the charge level. Plugged in, the
charging battery icon stays full: SF Symbols has no battery with a bolt
for lower levels.

On battery, the title turns orange at 20 % or less and red at 10 % or
less, the same thresholds as the charge bar of the panel.

## Panel

- Battery percentage, charge bar and time remaining
- Power drawn on battery (`Using 10.4 W`), or the charger's wattage and
  port when plugged in (`67W USB-C charger`)
- Charge level over the last 24 hours, plugged-in periods shaded green
- Battery health: cycle count, maximum capacity and condition
- Processes using significant energy, with their app icon
- Open at Login, off until chosen
- Battery Settings shortcut
- Quit (⌘Q)

### Energy use

Energy use is measured with `top` when the panel opens, never in the
background: it takes a few seconds and the panel shows "Measuring energy
use..." meanwhile. Up to five apps or processes with an energy impact
of 20 or more are listed, the same figure as Activity Monitor's Energy
Impact column; clicking one opens Activity Monitor. Holding Option
turns the impact of each app into "Quit": an Option-click asks the app
to quit, as ⌘Q would. Processes that are not apps keep opening Activity
Monitor.

### Charge history

The charge history is sampled while the app runs, every five minutes or
on any change, and kept across restarts. The curve is cut wherever the
app was not running or the Mac was asleep for a while.

### Battery health

Maximum capacity is the full charge capacity against the design
capacity, as in System Settings. The condition turns to "Service" when
the battery reports a permanent failure or falls under 80 %, the
threshold Apple uses for its service recommendation.

## Notifications

On battery, a notification when the charge drops to 20 % then to 10 %.
While plugged in, one when it reaches 80 % then 100 %. Each threshold
notifies once, then again only after the charge has gone back past it
the other way. macOS asks for permission on first launch.

## Requirements

- A Mac with a battery on macOS 26 (the panel uses Liquid Glass)
- To build it from source, the Swift toolchain (Xcode or Command Line
  Tools)

## Install

Download `BatteryTime-<version>.dmg` from the
[latest release](https://github.com/skelz0r/macos_battery_level/releases/latest),
open it and drag BatteryTime to Applications. The app is signed and
notarized, so it opens without a Gatekeeper warning.

To start it at login, choose Open at Login in the panel.

### From source

```sh
./install.sh         # builds, copies to /Applications and opens it
```

To update, pull and install again: the running app is replaced and
restarted.

```sh
git pull
./install.sh
```

To remove it:

```sh
./uninstall.sh
```

Both remove the LaunchAgent that earlier versions of `install.sh` used
to start the app at login.

## Development

```sh
./build.sh && open BatteryTime.app   # build and run without installing
swift test                           # run the tests
bin/lint                             # swift format and swiftlint, strict
bin/lint --fix                       # apply automatic corrections first
```

`bin/lint` needs `swiftlint` (`brew install swiftlint`); `swift format`
ships with the Swift toolchain.

`build.sh` signs ad hoc with version 0.0.0; `VERSION` and
`SIGN_IDENTITY` override them, the latter adding the hardened runtime
and a secure timestamp.

## Release

```sh
bin/release 1.2.0             # build, sign, notarize, publish v1.2.0
bin/release --dry-run 1.2.0   # stop after the signed disk image
```

`bin/release` builds the app with the given version, signs it with the
Developer ID Application certificate of the keychain, puts it in
`dist/BatteryTime-<version>.dmg` next to a link to Applications, then
notarizes and staples the image, tags `v<version>` and creates the
GitHub release with the image attached.

It needs:

- a Developer ID Application certificate in the keychain
  (`DEVELOPER_ID` picks another identity)
- an App Store Connect API key: `ASC_KEY_ID`, `ASC_KEY_ISSUER_ID` and
  `ASC_KEY_PATH` (the `.p8` file)
- `gh`, logged in
