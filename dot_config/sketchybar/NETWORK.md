# SketchyBar networking

The network display is split into three items:

- `network_down`: `↓` plus the current receive rate.
- `network_up`: `↑` plus the current transmit rate.
- `network_connection`: the connection-type icon plus the cached
  `networkQuality` measurement, for example `􀺦 927 Mbps`.

The down/up items are disabled by default. The connection item owns the single
network poll so both traffic rates are calculated from the same counter sample.
Click the connection item to toggle the down/up pair. The toggle is stored in
the temporary file
`${TMPDIR:-/tmp}/sketchybar-network-traffic.state`, and starts `off` even if an
old `sketchybar-network-mode.state` contains the previous `traffic` mode.

The traffic labels retain the existing byte-rate formatting (`KB`, `MB`, or
`GB`). The connection measurement is refreshed in the background every five
minutes and remains visible while that measurement is unavailable, using `—`
until the cache is populated.
