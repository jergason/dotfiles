require("hs.ipc")

-- The installer links init.lua, so load the module beside its actual file.
local configFile = hs.fs.symlinkAttributes(hs.configdir .. "/init.lua", "target")
  or hs.configdir .. "/init.lua"
if configFile:sub(1, 1) ~= "/" then configFile = hs.configdir .. "/" .. configFile end
agentBrowser = dofile(configFile:match("^(.*)/") .. "/agent-browser.lua")
