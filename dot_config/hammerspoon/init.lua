local ghosttyBundleID = "com.mitchellh.ghostty"

hs.ipc.cliInstall()

local paneHotkeys = {}
local paneHotkeysEnabled = false

local function focusGhosttyPane(index)
  local script = string.format([[
tell application "Ghostty"
  if not (exists front window) then return
  set selectedTab to selected tab of front window
  if (count of terminals of selectedTab) is greater than or equal to %d then
    focus item %d of terminals of selectedTab
  end if
end tell
]], index, index)

  hs.osascript.applescript(script)
end

local function reloadGhosttyConfig()
  local app = hs.application.get(ghosttyBundleID)
  if app == nil then
    return true
  end

  app:activate(true)
  hs.timer.doAfter(0.05, function()
    hs.eventtap.keyStroke({ "cmd", "shift" }, ",", 0)
  end)

  return true
end

local function ghosttyIsFrontmost()
  local app = hs.application.frontmostApplication()
  return app ~= nil and app:bundleID() == ghosttyBundleID
end

local function setGhosttyPaneHotkeysEnabled(enabled)
  if paneHotkeysEnabled == enabled then
    return
  end

  for _, hotkey in ipairs(paneHotkeys) do
    if enabled then
      hotkey:enable()
    else
      hotkey:disable()
    end
  end

  paneHotkeysEnabled = enabled
end

for index = 1, 9 do
  paneHotkeys[index] = hs.hotkey.new({ "cmd" }, tostring(index), function()
    focusGhosttyPane(index)
  end)
end

local function syncGhosttyPaneHotkeys()
  setGhosttyPaneHotkeysEnabled(ghosttyIsFrontmost())
end

local appWatcher = hs.application.watcher.new(function(_, eventType)
  if eventType == hs.application.watcher.activated then
    syncGhosttyPaneHotkeys()
  end
end)

appWatcher:start()
syncGhosttyPaneHotkeys()
local syncTimer = hs.timer.doEvery(0.25, syncGhosttyPaneHotkeys)
hs.autoLaunch(true)

_G.ghosttyPaneHotkeys = paneHotkeys
_G.focusGhosttyPane = focusGhosttyPane
_G.reloadGhosttyConfig = reloadGhosttyConfig
_G.ghosttyPaneWatcher = appWatcher
_G.ghosttyPaneSyncTimer = syncTimer
_G.syncGhosttyPaneHotkeys = syncGhosttyPaneHotkeys
