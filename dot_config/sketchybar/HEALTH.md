# Apple Health in SketchyBar

This setup keeps personal Health data out of the dotfiles repository:

`iPhone / Apple Watch → Shortcuts → iCloud Drive/SketchyBar/*.json → Mac SketchyBar`

macOS cannot read the iPhone or Apple Watch Health store directly. The Mac
plugin therefore reads two small JSON snapshots from iCloud Drive:

- `health.json`: today's steps, active calories, Exercise minutes, and Stand
  hours.
- `workout.json`: whether a workout is active and, if so, when it started.

## One-time iPhone setup

Create an `iCloud Drive/SketchyBar` folder, then create a shortcut named
`SketchyBar Health Snapshot` on the iPhone that holds the Health data.

The shortcut should:

1. Get the current date and format it as `yyyy-MM-dd` for `date`. Format the
   current date with the custom format `yyyy-MM-dd'T'HH:mm:ssZZZZZ` for
   `updated_at`.
2. Use **Find Health Samples** for each of these types, bounded from the start
   of today through the current date:
   - Steps → get the sample values and **Calculate Statistics → Sum** → `steps`
   - Active Calories → get the sample values and **Calculate Statistics → Sum**
     → `active_calories`
   - Exercise Minutes → get the sample values and **Calculate Statistics → Sum**
     → `exercise_minutes`
   - Stand Hour → **Count** the samples → `stand_hours`
3. Add a **Text** action containing this JSON, replacing each placeholder with
   the corresponding Shortcut variable:

   ```json
   {
     "schema": 1,
     "date": "yyyy-MM-dd result",
     "updated_at": "ISO 8601 current date result",
     "steps": 0,
     "active_calories": 0,
     "exercise_minutes": 0,
     "stand_hours": 0
   }
   ```

   The numeric fields must be inserted as numbers, without quotation marks.
4. Save the Text result as `iCloud Drive/SketchyBar/health.json`, with **Ask
   Where to Save** off and **Overwrite If File Exists** on.

Run the shortcut once by hand and confirm that `health.json` appears in the
folder and grant the shortcut Health read access when prompted. If the step
total does not match the Fitness app, inspect the Health Samples source filter
and choose the source you use as authoritative (usually the Apple Watch). Raw
samples from multiple devices can overlap, so a naive sum can differ from
Fitness's de-duplicated total.

## Daily refresh automations

Create four iPhone **Time of Day** personal automations at 8:00 AM, 12:00 PM,
6:00 PM, and 10:00 PM. Each automation should run `SketchyBar Health Snapshot`.
Turn **Ask Before Running** off. These are intentionally a few daily writes,
not a continuous stream of Health data.

## Workout start/end automations

Create two shortcuts that save to the same iCloud Drive folder.

For each shortcut, use **Current Date → Format Date** with the custom format
`yyyy-MM-dd'T'HH:mm:ssZZZZZ`, put the result into the JSON Text action below,
then use **Save File** with **Ask Where to Save** off and **Overwrite If File
Exists** on.

`SketchyBar Workout Start` writes:

```json
{
  "schema": 1,
  "active": true,
  "started_at": "ISO 8601 current date result"
}
```

`SketchyBar Workout End` writes:

```json
{
  "schema": 1,
  "active": false,
  "ended_at": "ISO 8601 current date result"
}
```

Use an Apple Watch **Workout** automation for each shortcut: one for **When
Workout Starts**, and one for **When Workout Ends**. Select **Any Workout**
unless you want to limit the trigger to a specific workout type. Turn **Ask
Before Running** off. The iPhone must be paired with the Apple Watch for these
triggers.

## What appears in the bar

Once today's snapshot is present, the item shows:

`steps · active calories kcal · Exercise minutes m · Stand hours h`

The values appear in that order, for example `12,480 · 687 kcal · 52m · 9h`.

While a workout is active, it appends a live elapsed timer, for example
`· 27m`. These are raw values; the item deliberately does not show ring
percentages because this Shortcuts bridge does not receive Activity Summary
goals reliably enough to calculate them.

The plugin checks the files every 60 seconds and hides itself when the health
snapshot is missing, malformed, or from an earlier date. For a non-default
location, set `SKETCHYBAR_HEALTH_FILE` and `SKETCHYBAR_WORKOUT_FILE` in the
SketchyBar launch environment.
