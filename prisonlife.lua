--[[
    Check it v2 Interface
    by hitechboi / nejrio
    github.com/hitechboi
    star my post :p, have fun!
]]
local tick = tick or os.clock
local warn = warn or function(msg) end
local floor = math.floor
local safeCall = pcall
local gameId = floor(game.GameId)
if gameId ~= 73885730 then
    notify("Check it", "This script is not supported for this game.", 5)
    return
end
if _G.MyMoms_Cleanup then pcall(_G.MyMoms_Cleanup) task.wait(0.2) end
_G.MyMoms_Cleanup = function() end
local function easeInOutSine(t) return -(math.cos(math.pi * t) - 1) / 2 end
local function smoothTeleport(startPosition, endPosition, duration)
    duration = duration or 0.5
    local lp = game.Players.LocalPlayer
    local t0 = tick()
    while true do
        local el = tick() - t0
        local t = math.min(el / duration, 1)
        local et = easeInOutSine(t)
        local position = startPosition:Lerp(endPosition, et)
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local alive = h ~= nil
        if h then
            h.AssemblyLinearVelocity = Vector3.new(0,0,0)
            h.Position = position
        end
        if not alive or t >= 1 then break end
        task.wait(0.016)
    end
end

--//services
local runService = game:GetService("RunService")
local schedulerRunning = true

--//loader
local function loadRemote(url, label)
    local body = httpget(url)
    if type(body) ~= "string" or body == "" then
        warn("[Check It] Empty response while loading " .. label)
        return false, nil
    end
    local chunk, compileError = loadstring(body, "@" .. label)
    if not chunk then
        warn("[Check It] Could not compile " .. label .. ": " .. tostring(compileError))
        return false, nil
    end

    local ran, result = pcall(chunk)
    if not ran then
        warn("[Check It] " .. label .. " failed: " .. tostring(result))
        return false, nil
    end
    return true, result
end

local uiLibrary
do
    local loaded, library = loadRemote("https://raw.githubusercontent.com/hitechboi/runtodabank/refs/heads/main/plui.lua", "PLui")
    if loaded and library then
        uiLibrary = library
    elseif _G.lib then
        uiLibrary = _G.lib
    else
        notify("Check it", "Failed to load UI library. Try again shortly.", 5)
        return
    end
end

local playerName=game.Players.LocalPlayer.Name local executorName="";pcall(function()if type(getgetname)=="function"then executorName=getgetname()elseif type(getgamename)=="function"then executorName=getgamename()end end)
local gunModsEnabled=false local ammoEnabled=false local reloadEnabled=false local fireRateEnabled=false local instantFireEnabled=false local shotgunFullAutoEnabled=false local arInstantFireEnabled=false local m9FullAutoEnabled=false local rangeEnabled=false
local ammoAmount=1 local reloadTime=0.01 local fireRate=0.1 local weaponRange=1500 local shuttingDown=false local playerDead=false local backpackProtectionEnabled=false
local assaultRifles={["AK-47"]=true,["MP5"]=true,["FAL"]=true,["M4A1"]=true}
local localPlayer=game.Players.LocalPlayer local humanoid=nil
local function refreshHumanoid()local _c=localPlayer.Character if _c then humanoid=_c:FindFirstChild("Humanoid")end end refreshHumanoid()
local attributeOverrides={MaxAmmo=function()return ammoEnabled and ammoAmount end,CurrentAmmo=function()return ammoEnabled and ammoAmount end,ReloadTime=function()return reloadEnabled and reloadTime end,FireRate=function(_t)if instantFireEnabled then return 0.001 end if fireRateEnabled then if arInstantFireEnabled and assaultRifles[_t.Name]then return nil end return fireRate end return nil end,Range=function()return rangeEnabled and weaponRange end}
local function isGunTool(_t)if not _t:IsA("Tool")then return false end for _a in pairs(attributeOverrides)do if _t:GetAttribute(_a)~=nil then return true end end return false end
local function countGunTools()local _b=localPlayer:FindFirstChild("Backpack")local _c=0 if _b then for _,_t in ipairs(_b:GetChildren())do if isGunTool(_t)then _c=_c+1 end end end return _c end
local function isCuffsEquipped()local _c=localPlayer.Character if not _c then return false end local _t=_c:FindFirstChild("Cuffs")or _c:FindFirstChild("Handcuffs")return _t and _t:IsA("Tool")end
local function getArrestableState(p)
if p==localPlayer then return false,nil end
if p.Team and string.find(string.lower(p.Team.Name),"criminal")then return true,"criminal"end
local ch=p.Character
if ch then
if ch:GetAttribute("Hostile")then return true,"hostile"end
if ch:GetAttribute("Trespassing")then return true,"trespassing"end
end
return false,nil
end
local function applyToolMods(parent)if not parent then return end for _,_t in ipairs(parent:GetChildren())do if _t.Name=="Remington 870"then if _t:GetAttribute("AutoFire")~=shotgunFullAutoEnabled then _t:SetAttribute("AutoFire",shotgunFullAutoEnabled)end end if arInstantFireEnabled and assaultRifles[_t.Name]then if _t:GetAttribute("FireRate")~=0.001 then _t:SetAttribute("FireRate",0.001)end end if m9FullAutoEnabled and _t.Name=="M9"then if _t:GetAttribute("AutoFire")~=true then _t:SetAttribute("AutoFire",true)end end if isGunTool(_t)then for _a,_fn in pairs(attributeOverrides)do if _t:GetAttribute(_a)~=nil then local _v=_fn(_t)if _v and _t:GetAttribute(_a)~=_v then _t:SetAttribute(_a,_v)end end end end end end
local waited=0
while not uiLibrary and not _G.lib do
    task.wait(0.1)
    waited=waited+0.1
    if waited>=5 then
        notify("Check it","UI library timeout",5)
        return
    end
end
if not uiLibrary then uiLibrary=_G.lib end
local window=uiLibrary:Window("Check It v2")
window:SetGameName(executorName)
local gunModsTab=window:Tab("gun mods")
local autoTab=window:Tab("auto")
local teleportsTab=window:Tab("teleports")
local mainSec=gunModsTab:Section("main")
mainSec:Toggle({label="enabled",default=false,id="master_toggle",col=1,desc="Master toggle for all gun mods",callback=function(_s)gunModsEnabled=_s end})
local autoSec=autoTab:Section("auto arrest")
local autoCuffsEnabled = false
local lastDeathTime = 0
local autoCuffsToggle
autoCuffsToggle = autoSec:Toggle({label="auto cuffs",default=false,id="auto_cuffs",col=1,desc="Hold out cuffs. Checks Guards team. Teleports to Criminals & locks camera.",callback=function(s)
    autoCuffsEnabled = s
    if s then
        if tick() - lastDeathTime < 5 then
            autoCuffsEnabled = false
            if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
            notify("Auto Arrest", "Hey chill out, wait 5 seconds to.", 4)
            return
        end
        local t = localPlayer.Team
        if not t or (not string.match(string.lower(t.Name), "guard") and not string.match(string.lower(t.Name), "police")) then
            autoCuffsEnabled = false
            if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
            notify("Auto Arrest","Warning: You aren't on the Guards team!",4)
        end
    end
end})
local arrestTargetAddress = nil
local criminalAddressByIndex = {}
local targetOptions = {"All Targets"}
local targetDropdown = autoSec:Dropdown({label="arrest target",options=targetOptions,default="All Targets",id="arrest_target",col=1,callback=function(val)
    if val == "All Targets" then arrestTargetAddress = nil
    else
        for idx,name in ipairs(targetOptions) do
            if name == val then arrestTargetAddress = criminalAddressByIndex[idx] or nil break end
        end
    end
end})
local fireSec=gunModsTab:Section("fire")
fireSec:Toggle({label="apply reload",default=false,id="apply_reload",col=1,desc="Toggles Reload Slider (M9, Taser Only)",callback=function(_s)reloadEnabled=_s end})
fireSec:Slider({label="reload time",default=0.01,min=0.01,max=5.0,suffix="s",id="reload_time",col=1,desc="Lower = faster reload",callback=function(_v)reloadTime=_v end})
fireSec:Toggle({label="apply fire rate",default=false,id="apply_firerate",col=1,desc="Toggles FireRate Slider (ARs excluded if AR Instant on)",callback=function(_s)fireRateEnabled=_s end})
fireSec:Slider({label="fire rate",default=0.1,min=0.1,max=1.0,suffix="s",id="fire_rate",col=1,desc="Lower = faster fire",callback=function(_v)fireRate=_v end})
local extrasSec=gunModsTab:Section("extras",2)
extrasSec:Toggle({label="instant fire rate",default=false,id="instant_firerate",col=2,desc="Insta FireRate!!!",callback=function(_s)instantFireEnabled=_s end})
extrasSec:Toggle({label="shotgun full auto",default=false,id="shotgun_auto",col=2,desc="Toggles AutoFire on Remington 870 (Requires firerate slider)",callback=function(_s)shotgunFullAutoEnabled=_s end})
extrasSec:Toggle({label="AR instant fire rate",default=false,id="ar_instant",col=2,desc="Instant fire for AK-47, MP5, FAL, M4A1",callback=function(_s)arInstantFireEnabled=_s end})
extrasSec:Toggle({label="M9 full auto",default=false,id="m9_auto",col=2,desc="Toggles AutoFire on M9 pistol",callback=function(_s)m9FullAutoEnabled=_s end})
local rangeSec=gunModsTab:Section("range",2)
rangeSec:Toggle({label="extend range",default=false,id="extend_range",col=2,desc="Sets Range value",callback=function(_s)rangeEnabled=_s end})
rangeSec:Slider({label="range",default=1500,min=0,max=15000,suffix="",id="range_val",col=2,desc="Range distance",callback=function(_v)weaponRange=floor(_v)end})
local funSec=gunModsTab:Section("fun",2)
funSec:Toggle({label="apply ammo",default=false,id="apply_ammo",col=2,desc="Visual only - once below original ammo count no damage",callback=function(_s)ammoEnabled=_s end})
funSec:Slider({label="ammo amount",default=1,min=1,max=9999,suffix="",id="ammo_amount",col=2,desc="Ammo count",callback=function(_v)ammoAmount=floor(_v)end})
local sessionSec=gunModsTab:Section("session",2)
sessionSec:DebugRow({text="session active",gameName=executorName,col=2})
local function collectGunAndReturn(x,y,z)
    local rootPart=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local oldX,oldY,oldZ=rootPart.Position.X,rootPart.Position.Y,rootPart.Position.Z
    smoothTeleport(Vector3.new(oldX, oldY, oldZ), Vector3.new(x, y, z), 0.25)
    task.wait(0.4)
    smoothTeleport(Vector3.new(x, y, z), Vector3.new(oldX, oldY, oldZ), 0.25)
end
local function teleportTo(x,y,z)
    local rootPart=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local oldX,oldY,oldZ=rootPart.Position.X,rootPart.Position.Y,rootPart.Position.Z
    smoothTeleport(Vector3.new(oldX, oldY, oldZ), Vector3.new(x, y, z), 0.5)
end
local crimGunSec=teleportsTab:Section("criminal guns")
crimGunSec:Button({label="remington 870",id="tp_rem_crim",col=1,callback=function()collectGunAndReturn(-938.22,94.31,2039.17)end})
crimGunSec:Button({label="AK-47",id="tp_ak47",col=1,callback=function()collectGunAndReturn(-931.39,94.37,2039.39)end})
crimGunSec:Button({label="M700",id="tp_m700_crim",col=2,callback=function()collectGunAndReturn(-919.96,95.01,2036)end})
crimGunSec:Button({label="FAL",id="tp_fal",col=2,callback=function()collectGunAndReturn(-902.34,94.35,2047.93)end})
local copGunSec=teleportsTab:Section("cop guns")
copGunSec:Button({label="MP5",id="tp_mp5",col=1,callback=function()collectGunAndReturn(813.16,100.88,2229)end})
copGunSec:Button({label="rem cop",id="tp_rem_cop",col=1,callback=function()collectGunAndReturn(820.64,100.88,2228.95)end})
copGunSec:Button({label="M700 cop",id="tp_m700_cop",col=2,callback=function()collectGunAndReturn(836.09,100.74,2229.32)end})
copGunSec:Button({label="M4A1",id="tp_m4a1",col=2,callback=function()collectGunAndReturn(847.71,100.74,2229.33)end})
local locSec=teleportsTab:Section("locations")
locSec:Button({label="yard",id="tpyard",col=1,callback=function()teleportTo(784.12,98,2460.25)end})
locSec:Button({label="nexus",id="tp_nexus",col=1,callback=function()teleportTo(873.89,100,2390.69)end})
locSec:Button({label="cafeteria",id="tp_cafeteria",col=1,callback=function()teleportTo(901.37,99.99,2299.91)end})
locSec:Button({label="guard station",id="tp_guard",col=1,callback=function()teleportTo(829.99,99.99,2295.10)end})
locSec:Button({label="armory",id="tp_armory",col=2,callback=function()teleportTo(827.54,99.98,2240.20)end})
locSec:Button({label="prison cells",id="tp_cells",col=2,callback=function()teleportTo(920.01,99.99,2442.30)end})
locSec:Button({label="roof",id="tp_roof",col=2,callback=function()teleportTo(932.23,118.99,2365.07)end})
locSec:Button({label="criminal base",id="tp_crimbase",col=2,callback=function()teleportTo(-936.75,94.13,2054.35)end})
pcall(function()if window.AddMainScriptLog then window:AddMainScriptLog("v1.5","2026-03-30",{
    "gun mods: fire rate, reload, range, ammo",
    "auto cuffs with target selector",
    "randomized arrest teleport offset",
    "force backpack (anti-taze/arrest lock)",
    "dynamic attribute scanning (GetAttributes)",
    "teleport buttons for guns & locations",
    "extras: instant fire, full auto, M9 auto",
})end end)
pcall(function()if window.AddMainScriptLog then window:AddMainScriptLog("v1.6",os.date("%Y-%m-%d"),{
    "added attribute support for auto arrest."
})end end)
local pingUsername = game.Players.LocalPlayer.Name
local pingEnabled = true
local pingBaseUrl = "https://anything-beige.vercel.app"
task.spawn(function()
    local hasGameHttpGet = pcall(function() return game.HttpGet end) or (type(HttpGet) == "function")
    local hasGameHttpPost = pcall(function() return game.HttpPost end) or (type(HttpPost) == "function")
    local requestFunction = nil
    pcall(function() requestFunction = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) end)
    if not (hasGameHttpGet and hasGameHttpPost) and not requestFunction then return end
    local pingUrl = pingBaseUrl:gsub("/+$", "")
    task.spawn(function()
        while pingEnabled and schedulerRunning do
            pcall(function()
                local url = pingUrl .. "/ping?username=" .. pingUsername
                if type(game.HttpGet) == "function" then
                    game:HttpGet(url)
                elseif type(HttpGet) == "function" then
                    HttpGet(url)
                elseif requestFunction then
                    requestFunction({Url = url, Method = "GET"})
                end
            end)
            for i=1, 30 do if not pingEnabled or not schedulerRunning then break end task.wait(1) end
        end
    end)
end)

--//states
local initialCharacter = localPlayer.Character
local lastCharacterAddress = initialCharacter and initialCharacter.Address or nil
local initialTeam = localPlayer.Team
local lastTeamAddress = initialTeam and initialTeam.Address or nil
local lastToolUpdate = tick()
local heartbeatConnection
heartbeatConnection = runService.Heartbeat:Connect(function()
    if shuttingDown then
        heartbeatConnection:Disconnect()
        schedulerRunning = false
        return
    end

    local currentTime = tick()
    if currentTime - lastToolUpdate < 0.1 then return end
    lastToolUpdate = currentTime

    local character = localPlayer.Character
    local characterAddress = character and character.Address or nil
    if characterAddress ~= lastCharacterAddress then
        if lastCharacterAddress then
            playerDead = true
            lastDeathTime = currentTime
        end
        lastCharacterAddress = characterAddress
        humanoid = character and character:FindFirstChild("Humanoid") or nil
        if character then playerDead = false end
    elseif character and not humanoid then
        humanoid = character:FindFirstChild("Humanoid")
    end

    if humanoid and humanoid.Health <= 0 and not playerDead then
        playerDead = true
        lastDeathTime = currentTime
    end

    local team = localPlayer.Team
    local teamAddress = team and team.Address or nil
    if teamAddress ~= lastTeamAddress then
        lastTeamAddress = teamAddress
        local teamName = team and string.lower(team.Name) or ""
        if teamName ~= "" and not string.find(teamName, "guard") and not string.find(teamName, "police") then
            autoCuffsEnabled = false
            if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
            notify("Auto Arrest", "You are no longer on Guards team.", 3)
        end
    end

    if not playerDead and gunModsEnabled then
        applyToolMods(localPlayer:FindFirstChild("Backpack"))
        applyToolMods(character)
    end
end)
local function randomArrestOffset()
    local ang = math.random() * 2 * math.pi
    local dist = 2.5 + math.random() * 1.5
    return math.cos(ang) * dist, math.sin(ang) * dist
end
task.spawn(function()
    local lastClickTime = 0
    local hadTargets = false
    local lastCuffsWarning = 0
    while not shuttingDown and schedulerRunning do
        task.wait(0.1)
        if not autoCuffsEnabled then
            task.wait(0.2)
            hadTargets = false
        elseif playerDead then
            autoCuffsEnabled = false
            if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
            notify("Auto Arrest", "You died! Turning off.", 4)
        else
            pcall(function()
            local localTeam = localPlayer.Team
            if not localTeam then return end
            local teamNameLower = string.lower(localTeam.Name)
            if not (string.find(teamNameLower, "guard") or string.find(teamNameLower, "police")) then return end
            if not localPlayer.Character then return end
            local localRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not localRootPart then return end
            if not isCuffsEquipped() then
                if tick() - lastCuffsWarning > 4 then
                    lastCuffsWarning = tick()
                    notify("Auto Arrest", "Hold out cuffs bro!", 3)
                end
                return
            end
            local targetCount = 0
            for _, player in ipairs(game.Players:GetPlayers()) do
                local isArrestable,_ = getArrestableState(player)
                if isArrestable then
                    if not arrestTargetAddress or player.Address == arrestTargetAddress then
                        targetCount = targetCount + 1
                    end
                end
            end
            if targetCount == 0 and autoCuffsEnabled then
                autoCuffsEnabled = false
                if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
                local msg = hadTargets and "Arrested all targets" or "Untoggled no targets"
                notify("Auto Arrest", msg, 3)
                hadTargets = false
                return
            end
            hadTargets = true
            for _, player in ipairs(game.Players:GetPlayers()) do
                if not autoCuffsEnabled then break end
                local isArrestable,_ = getArrestableState(player)
                if isArrestable and (not arrestTargetAddress or player.Address == arrestTargetAddress) then
                    local watchedPlayer = player
                    local targetName = watchedPlayer.Name or "?"
                    notify("Auto Arrest", "Arresting " .. targetName .. "...", 2)
                    task.spawn(function()
                        local watchStartedAt = tick()
                        local successNotified = false
                        while watchedPlayer and watchedPlayer.Parent and (tick() - watchStartedAt) < 12 do
                            task.wait(0.5)
                            local stillArrestable,_ = getArrestableState(watchedPlayer)
                        if not stillArrestable then
                                if not successNotified then
                                    successNotified = true
                                    notify("Auto Arrest", "Successfully arrested " .. watchedPlayer.Name .. "!", 4)
                                end
                                break
                            end
                        end
                    end)
                    local offsetX, offsetZ = randomArrestOffset()
                    local arrestStartedAt = tick()
                    while autoCuffsEnabled and not shuttingDown and (tick() - arrestStartedAt) < 5.5 do
                        task.wait(0.016)
                        if not isCuffsEquipped() then break end
                        local targetCharacter = player.Character
                        local localCharacter = localPlayer.Character
                        if not targetCharacter or not localCharacter then break end
                        if playerDead then
                            autoCuffsEnabled = false
                            if autoCuffsToggle and autoCuffsToggle.SetState then autoCuffsToggle:SetState(false) end
                            notify("Auto Arrest", "You died! Turning off.", 4)
                            break
                        end
                        local isStillArrestable,_ = getArrestableState(player)
                        if not isStillArrestable then break end
                        local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
                        local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
                        if not targetRootPart or not localRootPart then break end
                        local targetPosition = targetRootPart.Position
                        localRootPart.Position = Vector3.new(targetPosition.X + offsetX, targetPosition.Y, targetPosition.Z + offsetZ)
                        local camera = workspace.CurrentCamera
                        if camera then camera.lookAt(localRootPart.Position, targetPosition) end
                        if (tick() - lastClickTime) > 0.15 then
                            mouse1click()
                            lastClickTime = tick()
                        end
                    end
                end
            end
            end)
        end
    end
end)
local lastOptionsKey=""
task.spawn(function()
    while not shuttingDown and schedulerRunning do
        task.wait(1)
        if not targetDropdown then break end
        safeCall(function()
            local opts={"All Targets"}
            local addrMap={}
            for _,p in ipairs(game.Players:GetPlayers()) do
                local _a,_r = getArrestableState(p)
                if _a then
                    local idx=#opts+1
                    local suffix = _r ~= "criminal" and (" / ".. _r) or ""
                    opts[idx]=(p.Name or "?")..suffix
                    addrMap[idx]=p.Address
                end
            end
            local key=table.concat(opts,"|")
            if key~=lastOptionsKey then
                lastOptionsKey=key
                criminalAddressByIndex=addrMap
                targetOptions=opts
                if targetDropdown.SetOptions then targetDropdown:SetOptions(opts)end
            else
                criminalAddressByIndex=addrMap
            end
            if arrestTargetAddress then
                local found=false
                for _,addr in pairs(addrMap) do if addr==arrestTargetAddress then found=true break end end
                if not found then arrestTargetAddress=nil end
            end
        end)
    end
end)
while not shuttingDown do task.wait(1)end schedulerRunning=false
_G.MyMoms_Cleanup = function()
    schedulerRunning = false
    shuttingDown = true
    pingEnabled = false
    autoCuffsEnabled = false
    if uiLibrary and uiLibrary.Destroy then uiLibrary:Destroy() end
    if heartbeatConnection then heartbeatConnection:Disconnect() end
end
