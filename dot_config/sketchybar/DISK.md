# SketchyBar disk speed

The disk display is split into two items:

- `disk_read`: `↓` plus the current aggregate read rate.
- `disk_write`: `↑` plus the current aggregate write rate.

The plugin samples cumulative `IOBlockStorageDriver` read/write byte counters
once per second and calculates the rate between samples. The values include
the internal disk and currently attached storage volumes, and are formatted as
`KB/s`, `MB/s`, or `GB/s`.

The first sample after SketchyBar starts or reloads displays `0 KB/s` while the
baseline is established. State is stored in
`${TMPDIR:-/tmp}/sketchybar-disk-speed.state`.
