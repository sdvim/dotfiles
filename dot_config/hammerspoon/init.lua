local ghosttyBundleID = "com.mitchellh.ghostty"

hs.ipc.cliInstall()

local paneHotkeys = {}
local paneHotkeysEnabled = false
local openPrHotkey
local openPrTask

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

local function focusedGhosttyWorkingDirectory()
  local script = [[
tell application "Ghostty"
  if not (exists front window) then return ""
  set selectedTab to selected tab of front window
  set selectedTerminal to focused terminal of selectedTab
  return working directory of selectedTerminal
end tell
]]

  local ok, workingDirectory = hs.osascript.applescript(script)
  if not ok or type(workingDirectory) ~= "string" or workingDirectory == "" then
    return nil
  end

  return workingDirectory
end

local function openGhosttyGitHubPr()
  if openPrTask ~= nil and openPrTask:isRunning() then
    return
  end

  local workingDirectory = focusedGhosttyWorkingDirectory()
  if workingDirectory == nil then
    hs.alert.show("Could not determine Ghostty working directory")
    return
  end

  local helperPath = os.getenv("HOME") .. "/.local/bin/open-github-pr"
  local task = hs.task.new(helperPath, function(exitCode, stdOut, stdErr)
    openPrTask = nil

    if exitCode ~= 0 then
      local message = stdErr ~= "" and stdErr or stdOut
      message = message:gsub("^%s+", ""):gsub("%s+$", "")
      hs.alert.show(message ~= "" and message or "open-github-pr failed")
    end
  end)

  if task == nil or not task:setWorkingDirectory(workingDirectory) then
    hs.alert.show("Could not start open-github-pr")
    return
  end

  local environment = task:environment()
  environment.PATH = "/opt/homebrew/bin:" .. (environment.PATH or "/usr/bin:/bin:/usr/sbin:/sbin")
  task:setEnvironment(environment)

  openPrTask = task
  if not task:start() then
    openPrTask = nil
    hs.alert.show("Could not start open-github-pr")
  end
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

  if enabled then
    openPrHotkey:enable()
  else
    openPrHotkey:disable()
  end

  paneHotkeysEnabled = enabled
end

for index = 1, 9 do
  paneHotkeys[index] = hs.hotkey.new({ "cmd" }, tostring(index), function()
    focusGhosttyPane(index)
  end)
end

openPrHotkey = hs.hotkey.new({ "cmd" }, "r", openGhosttyGitHubPr)

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
_G.focusedGhosttyWorkingDirectory = focusedGhosttyWorkingDirectory
_G.openGhosttyGitHubPr = openGhosttyGitHubPr
_G.ghosttyOpenPrHotkey = openPrHotkey
_G.ghosttyPaneWatcher = appWatcher
_G.ghosttyPaneSyncTimer = syncTimer
_G.syncGhosttyPaneHotkeys = syncGhosttyPaneHotkeys
