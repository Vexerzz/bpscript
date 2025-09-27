-- example script by https://github.com/mstudio45/LinoriaLib/blob/main/Example.lua and modified by deivid
-- You can suggest changes with a pull request or something

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false -- Forces AddToggle to AddCheckbox
Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Set Resizable to true if you want to have in-game resizable Window
	-- Set MobileButtonsSide to "Left" or "Right" if you want the ui toggle & lock buttons to be on the left or right side of the window
	-- Set ShowCustomCursor to false if you don't want to use the Linoria cursor
	-- NotifySide = Changes the side of the notifications (Left, Right) (Default value = Left)
	-- Position and Size are also valid options here
	-- but you do not need to define them unless you are changing them :)
	Resizable = true,
	Title = "Bloody.hook>>>",
	Footer = "V 1.0.0",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
-- You can find more icons in https://lucide.dev/
local Tabs = {
	-- Creates a new tab titled Main
	["Aims"] = Window:AddTab("Aims(silent aim/Aimbot)", "crosshair"),
	["HBE"] = Window:AddTab("HBE", "square-dashed"),
	["human"] = Window:AddTab("Humanoid", "person-standing"),
	["visuals"] = Window:AddTab("Visuals", "eye"),
	["utility"] = Window:AddTab("Utility", "wrench"),
    ["Killaura"] = Window:AddTab("Killaura", "knife"),
	["anti"] = Window:AddTab("Anti", "shield-ban"),
	["Proximity"] = Window:AddTab("Proximity", "square-plus"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
	["Credits"] = Window:AddTab("Credits", "brain-cog"),
}

local Config = {
	Enabled = false,
	FovEnabled = true,
	FovSize = 75,
	FovTransparency = 0.5,
	FovColor = Color3.fromRGB(255, 255, 255),
	AimbotSmoothing = 0.2,
	AimbotHumanizer = 0.1,
	AimbotVisible = true,
	AimLockPart = "Head",
	AimKey = Enum.UserInputType.MouseButton2,
	TeamCheck = false,
	WallCheck = false,

	-- Humanizer settings
	RandomOffset = false,
	RandomOffsetStrength = 0.5,
	SmoothCurve = false,
	SmoothCurveStrength = 0.3,
	HandTremor = false,
	HandTremorStrength = 1,
	MouseMomentum = false,
	MouseMomentumStrength = 0.3,
	Overshoot = false,
	OvershootChance = 0.1,
	OvershootStrength = 1.1,
	RecoveryTime = false,
	RecoveryStrength = 2,
	AdaptiveSensitivity = false
}



local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "B",
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = Settings
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(255, 1, 1)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(250, 25, 25)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end


--[[file handling]] do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
    
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "UniversalSilentAim", tostring(game.PlaceId)))

-- functions
local function GetFiles() -- credits to the linoria lib for this function, listfiles returns the files full path and its annoying
	local out = {}
	for i = 1, #Files do
		local file = Files[i]
		if file:sub(-4) == '.lua' then
			-- i hate this but it has to be done ...

			local pos = file:find('.lua', 1, true)
			local start = pos

			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end

			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end
	
	return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local LeftGroupBox = Tabs.Aims:AddLeftGroupbox("Silent aim", "locate")


--[[
Example of how to add a warning box to a tab; the title AND text support rich text formatting.

local WarningTab = Tabs["UI Settings"]:AddTab("Warning Box", "user")

WarningTab:UpdateWarningBox({
	Visible = true,
	Title = "Warning",
	Text = "This is a warning box!",
})

]]

-- Groupbox and Tabbox inherit the same functions
-- except Tabboxes you have to call the functions on a tab (Tabbox:AddTab(Name))

-- We can also get our Main tab via the following code:
-- local LeftGroupBox = Window.Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

-- Tabboxes are a tiny bit different, but here's a basic example:
--[[

local TabBox = Tabs.Main:AddLeftTabbox() -- Add Tabbox on left side

local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")

-- You can now call AddToggle, etc on the tabs you added to the Tabbox
]]

    
LeftGroupBox:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
Options.aim_Enabled_KeyPicker:OnClick(function()
    SilentAimSettings.Enabled = not SilentAimSettings.Enabled
    
    Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
    Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
    
    mouse_box.Visible = SilentAimSettings.Enabled
end)

LeftGroupBox:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
    SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
end)
LeftGroupBox:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
    SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
end)
LeftGroupBox:AddDropdown("TargetPart", {AllowNull = true, Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart"}}):OnChanged(function()
    SilentAimSettings.TargetPart = Options.TargetPart.Value
end)
LeftGroupBox:AddDropdown("Method", {AllowNull = true, Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
    "Raycast"
}}):OnChanged(function() 
    SilentAimSettings.SilentAimMethod = Options.Method.Value 
end)
LeftGroupBox:AddSlider('HitChance', {
    Text = 'Hit chance',
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,

    Compact = false,
})
Options.HitChance:OnChanged(function()
    SilentAimSettings.HitChance = Options.HitChance.Value
end)

local FieldOfViewBOX = Tabs.Aims:AddLeftGroupbox("FOV")

-- FOV Circle
FieldOfViewBOX:AddToggle("Visible", {Text = "Show FOV"}):AddColorPicker("Color", {Default = Color3.fromRGB(247, 36, 36)}):OnChanged(function()
    fov_circle.Visible = Toggles.Visible.Value
    SilentAimSettings.FOVVisible = Toggles.Visible.Value
end)
FieldOfViewBOX:AddSlider("Radius", {Text = "FOV Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
    fov_circle.Radius = Options.Radius.Value
    SilentAimSettings.FOVRadius = Options.Radius.Value
end)

resume(create(function()
RenderStepped:Connect(function()
    if  Toggles.aim_Enabled.Value then
        if getClosestPlayer() then 
            local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
            local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
            -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
            
            mouse_box.Visible = IsOnScreen
            mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
        else 
            mouse_box.Visible = false 
            mouse_box.Position = Vector2.new()
        end
    end
    
    if Toggles.Visible.Value then 
        fov_circle.Visible = Toggles.Visible.Value
        fov_circle.Color = Options.Color.Value
        fov_circle.Position = getMousePosition()
    end
end)
end))

local AimbotBOX = Tabs.Aims:AddRightGroupbox("Aimbot", "locate-fixed")

-- Reference to the Exunys aimbot environment
local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()

-- Helper: Settings table for UI <-> Aimbot.Settings
local Settings = Aimbot and Aimbot.Settings or {}

-- Helper: FOVSettings table for UI <-> Aimbot.FOVSettings
local FOVSettings = Aimbot and Aimbot.FOVSettings or {}

-- UI: Enable/Disable Aimbot
AimbotBOX:AddToggle("Enable Aimbot", {
	Text = "Enable Aimbot",
	Default = Settings.Enabled,
	Tooltip = "Toggle the aimbot on or off",
	Callback = function(v)
		Settings.Enabled = v
	end
})

-- UI: FOV Circle Enable/Disable
AimbotBOX:AddToggle("FOV Circle", {
	Text = "FOV Circle",
	Default = FOVSettings.Enabled,
	Tooltip = "Enable/disable the FOV circle",
	Callback = function(value)
		FOVSettings.Enabled = value
	end
})

-- UI: FOV Circle Visible
AimbotBOX:AddToggle("FOV Visible", {
	Text = "FOV Visible",
	Default = FOVSettings.Visible,
	Tooltip = "Show/hide the FOV circle",
	Callback = function(value)
		FOVSettings.Visible = value
	end
})

-- UI: FOV Radius
AimbotBOX:AddSlider("FOV Radius", {
	Text = "FOV Radius",
	Default = FOVSettings.Radius,
	Min = 10,
	Max = 500,
	Rounding = 0,
	Suffix = "px",
	Tooltip = "Adjust the radius of the FOV circle",
	Callback = function(value)
		FOVSettings.Radius = value
	end
})

-- UI: FOV Sides
AimbotBOX:AddSlider("FOV Sides", {
	Text = "FOV Sides",
	Default = FOVSettings.NumSides,
	Min = 3,
	Max = 100,
	Rounding = 0,
	Tooltip = "Number of sides for the FOV circle",
	Callback = function(value)
		FOVSettings.NumSides = value
	end
})

-- UI: FOV Thickness
AimbotBOX:AddSlider("FOV Thickness", {
	Text = "FOV Thickness",
	Default = FOVSettings.Thickness,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Tooltip = "Thickness of the FOV circle",
	Callback = function(value)
		FOVSettings.Thickness = value
	end
})

-- UI: FOV Transparency
AimbotBOX:AddSlider("FOV Transparency", {
	Text = "FOV Transparency",
	Default = FOVSettings.Transparency,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Tooltip = "Transparency of the FOV circle",
	Callback = function(value)
		FOVSettings.Transparency = value
	end
})

-- UI: FOV Filled
AimbotBOX:AddToggle("FOV Filled", {
	Text = "FOV Filled",
	Default = FOVSettings.Filled,
	Tooltip = "Fill the FOV circle",
	Callback = function(value)
		FOVSettings.Filled = value
	end
})

-- UI: FOV Color
AimbotBOX:AddLabel("FOV Color"):AddColorPicker("FOV Color", {
	Default = FOVSettings.Color,
	Name = "FOV Color",
	Callback = function(value)
		FOVSettings.Color = value
	end
})

-- UI: FOV Outline Color
AimbotBOX:AddLabel("FOV Outline Color"):AddColorPicker("FOV Outline Color", {
	Default = FOVSettings.OutlineColor,
	Name = "FOV Outline Color",
	Callback = function(value)
		FOVSettings.OutlineColor = value
	end
})

-- UI: FOV Locked Color
AimbotBOX:AddLabel("FOV Locked Color"):AddColorPicker("FOV Locked Color", {
	Default = FOVSettings.LockedColor,
	Name = "FOV Locked Color",
	Callback = function(value)
		FOVSettings.LockedColor = value
	end
})

-- UI: Rainbow Color
AimbotBOX:AddToggle("FOV Rainbow Color", {
	Text = "FOV Rainbow Color",
	Default = FOVSettings.RainbowColor,
	Tooltip = "Enable rainbow color for FOV",
	Callback = function(value)
		FOVSettings.RainbowColor = value
	end
})

AimbotBOX:AddToggle("FOV Rainbow Outline", {
	Text = "FOV Rainbow Outline",
	Default = FOVSettings.RainbowOutlineColor,
	Tooltip = "Enable rainbow color for FOV outline",
	Callback = function(value)
		FOVSettings.RainbowOutlineColor = value
	end
})

-- UI: Team Check
AimbotBOX:AddToggle("Team Check", {
	Text = "Team Check",
	Default = Settings.TeamCheck,
	Tooltip = "Enable/disable team check for aimbot",
	Callback = function(value)
		Settings.TeamCheck = value
	end
})

-- UI: Alive Check
AimbotBOX:AddToggle("Alive Check", {
	Text = "Alive Check",
	Default = Settings.AliveCheck,
	Tooltip = "Only aim at alive players",
	Callback = function(value)
		Settings.AliveCheck = value
	end
})

-- UI: Wall Check
AimbotBOX:AddToggle("Wall Check", {
	Text = "Wall Check",
	Default = Settings.WallCheck,
	Tooltip = "Enable/disable wall check for aimbot",
	Callback = function(value)
		Settings.WallCheck = value
	end
})

-- UI: Lock Part
AimbotBOX:AddDropdown("Lock Part", {
	Values = {"Head", "HumanoidRootPart", "Torso"},
	Default = Settings.LockPart,
	Multi = false,
	Text = "Lock Part",
	Tooltip = "Select the part to aim at",
	Callback = function(value)
		Settings.LockPart = value
	end
})

-- UI: Lock Mode
AimbotBOX:AddDropdown("Lock Mode", {
	Values = {"CFrame", "MouseMoveRel"},
	Default = (Settings.LockMode == 2 and "MouseMoveRel") or "CFrame",
	Multi = false,
	Text = "Lock Mode",
	Tooltip = "CFrame = camera snap, MouseMoveRel = mouse movement",
	Callback = function(value)
		if value == "MouseMoveRel" then
			Settings.LockMode = 2
		else
			Settings.LockMode = 1
		end
	end
})

-- UI: Sensitivity (CFrame animation time)
AimbotBOX:AddSlider("Sensitivity", {
	Text = "Sensitivity (CFrame)",
	Default = Settings.Sensitivity,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Tooltip = "Animation time for CFrame lock (0 = instant)",
	Callback = function(value)
		Settings.Sensitivity = value
	end
})

-- UI: Sensitivity2 (MouseMoveRel)
AimbotBOX:AddSlider("Sensitivity2", {
	Text = "Sensitivity (MouseMoveRel)",
	Default = Settings.Sensitivity2,
	Min = 0.1,
	Max = 10,
	Rounding = 2,
	Tooltip = "Sensitivity for mousemoverel mode",
	Callback = function(value)
		Settings.Sensitivity2 = value
	end
})

-- UI: Offset to Move Direction
AimbotBOX:AddToggle("Offset To Move Direction", {
	Text = "Offset To Move Direction",
	Default = Settings.OffsetToMoveDirection,
	Tooltip = "Offset aim to target's move direction",
	Callback = function(value)
		Settings.OffsetToMoveDirection = value
	end
})

AimbotBOX:AddSlider("Offset Increment", {
	Text = "Offset Increment",
	Default = Settings.OffsetIncrement,
	Min = 1,
	Max = 30,
	Rounding = 0,
	Tooltip = "Offset increment for move direction",
	Callback = function(value)
		Settings.OffsetIncrement = value
	end
})

-- UI: Trigger Key
AimbotBOX:AddDropdown("Trigger Key", {
	Values = {
		"MouseButton2", "MouseButton1", "Q", "E", "LeftShift", "LeftControl"
	},
	Default = (Settings.TriggerKey and tostring(Settings.TriggerKey.Name)) or "MouseButton2",
	Multi = false,
	Text = "Trigger Key",
	Tooltip = "Key to activate aimbot",
	Callback = function(value)
		-- Map string to Enum
		local map = {
			MouseButton2 = Enum.UserInputType.MouseButton2,
			MouseButton1 = Enum.UserInputType.MouseButton1,
			Q = Enum.KeyCode.Q,
			E = Enum.KeyCode.E,
			LeftShift = Enum.KeyCode.LeftShift,
			LeftControl = Enum.KeyCode.LeftControl
		}
		Settings.TriggerKey = map[value] or Enum.UserInputType.MouseButton2
	end
})

-- UI: Toggle/hold mode
AimbotBOX:AddToggle("Toggle Mode", {
	Text = "Toggle Mode",
	Default = Settings.Toggle,
	Tooltip = "Toggle (on/off) or hold to aim",
	Callback = function(value)
		Settings.Toggle = value
	end
})

-- UI: Blacklist/Whitelist (simple text input)
AimbotBOX:AddInput("Blacklist Player", {
	Text = "Blacklist Player",
	Tooltip = "Type a player name to blacklist from aimbot",
	Placeholder = "PlayerName",
	Callback = function(value)
		if value and value ~= "" then
			pcall(function() Aimbot:Blacklist(value) end)
		end
	end
})

AimbotBOX:AddInput("Whitelist Player", {
	Text = "Whitelist Player",
	Tooltip = "Type a player name to remove from blacklist",
	Placeholder = "PlayerName",
	Callback = function(value)
		if value and value ~= "" then
			pcall(function() Aimbot:Whitelist(value) end)
		end
	end
})

-- UI: Restart/Unload
AimbotBOX:AddButton({
	Text = "Restart Aimbot",
	Tooltip = "Restart the aimbot module",
	Func = function()
		if Aimbot and Aimbot.Restart then
			Aimbot:Restart()
		end
	end
})

AimbotBOX:AddButton({
	Text = "Unload Aimbot",
	Tooltip = "Unload the aimbot module",
	Func = function()
		if Aimbot and Aimbot.Exit then
			Aimbot:Exit()
		end
	end
})

-- Load the aimbot logic
if Aimbot and Aimbot.Load then
	Aimbot.Load()
end



local hbeBOX = Tabs.HBE:AddLeftGroupbox("HBE", "square-dashed")

-- Hitbox Expander (improved, more robust, all controls connected)

local player = game:GetService("Players").LocalPlayer

-- State variables for all controls
local hitboxEnabled = false
local selectedParts = {"Head"}
local expandSize = Vector3.new(2,2,2)
local transparency = 0.5

-- Store original part data for restoration
local originalPartData = {}

-- Connections for property enforcement
local canCollideConnections = setmetatable({}, {__mode = "k"})
local masslessConnections = setmetatable({}, {__mode = "k"})
local folderListeners = {}

-- Helper: always return a table of part names
local function toTable(val)
	if typeof(val) == "string" then
		return {val}
	elseif typeof(val) == "table" then
		return val
	else
		return {}
	end
end

-- Save original part properties if not already saved
local function saveOriginalPartData(part)
	if not originalPartData[part] then
		originalPartData[part] = {
			Size = part.Size,
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			Massless = part.Massless
		}
	end
end

-- Restore original part properties if saved
local function restoreOriginalPartData(part)
	local data = originalPartData[part]
	if data then
		part.Size = data.Size
		part.Transparency = data.Transparency
		part.CanCollide = data.CanCollide
		part.Massless = data.Massless
	end
end

-- Disconnect property listeners
local function disconnectCanCollideConnection(part)
	if canCollideConnections[part] then
		canCollideConnections[part]:Disconnect()
		canCollideConnections[part] = nil
	end
end
local function disconnectMasslessConnection(part)
	if masslessConnections[part] then
		masslessConnections[part]:Disconnect()
		masslessConnections[part] = nil
	end
end

-- Enforce CanCollide = false
local function connectCanCollideConnection(part)
	disconnectCanCollideConnection(part)
	if part.CanCollide then part.CanCollide = false end
	canCollideConnections[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
		if part.CanCollide then part.CanCollide = false end
	end)
end

-- Enforce Massless = true
local function connectMasslessConnection(part)
	disconnectMasslessConnection(part)
	if not part.Massless then part.Massless = true end
	masslessConnections[part] = part:GetPropertyChangedSignal("Massless"):Connect(function()
		if not part.Massless then part.Massless = true end
	end)
end

-- Apply hitbox settings to a part
local function applyHitboxToPart(part)
	if not hitboxEnabled then return end
	for _, name in ipairs(selectedParts) do
		if part.Name == name then
			saveOriginalPartData(part)
			part.Size = expandSize
			part.Transparency = transparency
			break
		end
	end
	connectCanCollideConnection(part)
	connectMasslessConnection(part)
end

-- Apply hitbox settings to all relevant parts
local function applyHitboxSettings()
	local humans = workspace:FindFirstChild("Humans")
	if not humans then return end
	for _, model in ipairs(humans:GetChildren()) do
		if model:IsA("Model") and model ~= player.Character then
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					applyHitboxToPart(part)
				end
			end
		end
	end
end

-- Setup listeners for Humans folder and models/parts
local function setupHumansFolderListeners()
	local humans = workspace:FindFirstChild("Humans")
	if not humans then return end

	-- Disconnect old listeners
	for _, conn in pairs(folderListeners) do
		conn:Disconnect()
	end
	folderListeners = {}

	-- Helper to process a model
	local function processModel(model)
		if model:IsA("Model") and model ~= player.Character then
			-- Apply to existing parts
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					applyHitboxToPart(part)
				end
			end
			-- Listen for new parts
			local addConn = model.ChildAdded:Connect(function(part)
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					applyHitboxToPart(part)
				end
			end)
			local remConn = model.ChildRemoved:Connect(function(part)
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					disconnectCanCollideConnection(part)
					disconnectMasslessConnection(part)
				end
			end)
			table.insert(folderListeners, addConn)
			table.insert(folderListeners, remConn)
		end
	end

	-- Listen for new models
	local modelAddConn = humans.ChildAdded:Connect(function(model)
		processModel(model)
	end)
	local modelRemConn = humans.ChildRemoved:Connect(function(model)
		if model:IsA("Model") then
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					disconnectCanCollideConnection(part)
					disconnectMasslessConnection(part)
				end
			end
		end
	end)
	table.insert(folderListeners, modelAddConn)
	table.insert(folderListeners, modelRemConn)

	-- Process existing models
	for _, model in ipairs(humans:GetChildren()) do
		processModel(model)
	end
end

-- Cleanup all listeners and restore all parts
local function cleanup()
	for part, conn in pairs(canCollideConnections) do
		if conn then conn:Disconnect() end
		if part and part.Parent then
			restoreOriginalPartData(part)
		end
	end
	canCollideConnections = {}
	for part, conn in pairs(masslessConnections) do
		if conn then conn:Disconnect() end
	end
	masslessConnections = {}
	for _, conn in pairs(folderListeners) do
		conn:Disconnect()
	end
	folderListeners = {}
end

-- Monitor Humans folder existence
local humansCheckConnection
local function startHumansFolderMonitor()
	if humansCheckConnection then
		humansCheckConnection:Disconnect()
	end
	humansCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
		local humans = workspace:FindFirstChild("Humans")
		if humans and not folderListeners[1] then
			setupHumansFolderListeners()
			if hitboxEnabled then
				applyHitboxSettings()
			end
		elseif not humans and folderListeners[1] then
			cleanup()
		end
	end)
end

startHumansFolderMonitor()


	-- Enable toggle
	hbeBOX:AddToggle("Enable", {
		Text = "Enable",
		Default = false,
		Tooltip = "Enable hitbox expander",
		Callback = function(value)
			hitboxEnabled = value
			if hitboxEnabled then
				setupHumansFolderListeners()
				applyHitboxSettings()
			else
				cleanup()
				startHumansFolderMonitor()
			end
		end
	})

	-- Parts dropdown (multi-select)
	hbeBOX:AddDropdown("Expand", {
		Values = {"Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Torso"},
		Default = "Head",
		Multi = true,
		Text = "Expand",
		Tooltip = "Expand hitbox (select one or more parts)",
		Callback = function(value)
			selectedParts = toTable(value)
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})

	-- Unified expand size slider
	hbeBOX:AddSlider("Expand Size", {
		Text = "Expand Size",
		Default = 2,
		Min = 0,
		Max = 10,
		Rounding = 1,
		Tooltip = "Adjust the expand size (all axes)",
		Callback = function(value)
			expandSize = Vector3.new(value, value, value)
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})

	-- Separate X/Y/Z sliders
	hbeBOX:AddSlider("Expand Size X", {
		Text = "Expand X",
		Default = 2,
		Min = 0,
		Max = 10,
		Rounding = 1,
		Tooltip = "Adjust expand size X",
		Callback = function(value)
			expandSize = Vector3.new(value, expandSize.Y, expandSize.Z)
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})
	hbeBOX:AddSlider("Expand Size Y", {
		Text = "Expand Y",
		Default = 2,
		Min = 0,
		Max = 10,
		Rounding = 1,
		Tooltip = "Adjust expand size Y",
		Callback = function(value)
			expandSize = Vector3.new(expandSize.X, value, expandSize.Z)
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})
	hbeBOX:AddSlider("Expand Size Z", {
		Text = "Expand Z",
		Default = 2,
		Min = 0,
		Max = 10,
		Rounding = 1,
		Tooltip = "Adjust expand size Z",
		Callback = function(value)
			expandSize = Vector3.new(expandSize.X, expandSize.Y, value)
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})

	-- Transparency slider
	hbeBOX:AddSlider("Transparency", {
		Text = "Transparency",
		Default = 0.5,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Tooltip = "Adjust the transparency of the hitbox",
		Callback = function(value)
			transparency = value
			if hitboxEnabled then
				applyHitboxSettings()
			end
		end
	})

-- Cleanup on script/library destroy
if library and library.OnDestroy then
	library.OnDestroy:Connect(function()
		cleanup()
		if humansCheckConnection then
			humansCheckConnection:Disconnect()
		end
	end)
end



local HumanoidBOX = Tabs.human:AddLeftGroupbox("Humanoid", "person-standing")


-- CFrame-based speed changer
local cframeSpeedEnabled = false
local cframeSpeedValue = 2 -- Default speed multiplier
local cframeSpeedConnection

HumanoidBOX:AddToggle("CFrameSpeed", {Text = "CFrame Speed", Default = false}):OnChanged(function()
	cframeSpeedEnabled = Toggles.CFrameSpeed.Value
	if cframeSpeedEnabled then
		if not cframeSpeedConnection then
			cframeSpeedConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
				local plr = game.Players.LocalPlayer
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
					-- Move in the direction the player is moving, scaled by cframeSpeedValue
					hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * cframeSpeedValue)
				end
			end)
		end
	else
		if cframeSpeedConnection then
			cframeSpeedConnection:Disconnect()
			cframeSpeedConnection = nil
		end
	end
end)

HumanoidBOX:AddSlider("CFrameSpeedValue", {
	Text = "CFrame Speed Value",
	Min = 1,
	Max = 50,
	Default = 25,
	Rounding = 1,
	Suffix = "x",
	Tooltip = "Adjust the CFrame speed multiplier"
}):OnChanged(function()
	cframeSpeedValue = Options.CFrameSpeedValue.Value
end)

anticonf = {
	antistun = false,
	antiragdoll = false,
	antidowned = false,
}

local function antistun()
	if anticonf.antistun then
		local plr = game:GetService("Players").LocalPlayer
		local char = plr.Character
		if char then
			char:SetAttribute("Stunned", false)
		end
	end
end

local function antiragdoll()
	if anticonf.antiragdoll then
		local plr = game:GetService("Players").LocalPlayer
		local char = plr.Character
		if char then
			char:SetAttribute("Ragdoll", false)
		end
	end
end

local function antidowned()
	if anticonf.antidowned then
		local plr = game:GetService("Players").LocalPlayer
		local char = plr.Character
		if char then
			char:SetAttribute("Downed", false)
		end
	end
end

-- Run all protections continuously
spawn(function()
	while true do
		antistun()
		antiragdoll()
		antidowned()
		wait(0.1) -- Adjust timing as needed
	end
end)

HumanoidBOX:AddToggle("Anti stun", {
	Text = "Anti Stun",
	Default = false,
	Callback = function(Value)
		anticonf.antistun = Value
	end
})

HumanoidBOX:AddToggle("Anti Ragdoll", {
	Text = "Anti Ragdoll",
	Default = false,
	Callback = function(Value)
		anticonf.antiragdoll = Value
	end
})

HumanoidBOX:AddToggle("Anti Downed", {
	Text = "Anti Downed",
	Default = false,
	Callback = function(Value)
		anticonf.antidowned = Value
	end
})

local autoHealEnabled = false
local originalCFrame = nil
local isAtHealPart = false
local healPart = workspace.Map.Tower.Traps.Buttons.Heal100Brick

local function hptp()
	if not autoHealEnabled then
		return
	end
	
	local plr = game:GetService("Players").LocalPlayer
	local char = plr.Character
	
	if not char then
		return
	end
	
	-- Check if ragdoll is true, if so, don't do anything
	if char:GetAttribute("Ragdoll") == true then
		return
	end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	
	if not hrp or not humanoid then
		return
	end
	
	-- Check current health
	if humanoid.Health < 100 then
		-- If not at heal part, save current position and teleport to heal part
		if not isAtHealPart then
			originalCFrame = hrp.CFrame -- Save current position before teleporting
			hrp.CFrame = healPart.CFrame
			isAtHealPart = true
		end
	else
		-- If health is 100 and at heal part, return to original position
		if isAtHealPart and originalCFrame then
			hrp.CFrame = originalCFrame
			isAtHealPart = false
		end
	end
end

-- Monitor character changes
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
	if autoHealEnabled then
		wait(1) -- Wait for character to fully load
		-- Reset the state when character respawns
		originalCFrame = nil
		isAtHealPart = false
	end
end)

-- Continuous loop to check health and teleport accordingly
spawn(function()
	while true do
		hptp()
		wait(0.5) -- Check every 0.5 seconds (adjust as needed)
	end
end)

HumanoidBOX:AddToggle("auto heal", {
	Text = "Auto Heal",
	Default = false,
	Callback = function(Value)
		autoHealEnabled = Value
		
		if Value then
			-- When enabling, reset the state
			originalCFrame = nil
			isAtHealPart = false
		else
			-- When disabling, if currently at heal part, return to original position
			if isAtHealPart and originalCFrame then
				local plr = game:GetService("Players").LocalPlayer
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = originalCFrame
					isAtHealPart = false
				end
			end
			-- Reset originalCFrame when disabling
			originalCFrame = nil
			isAtHealPart = false
		end
	end
})

local confasss = {
    Enabled = false,
    Distance = 5,
    Waiting = 5,
    UnderTp = 30,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Define the antiCarHitEnabled variable
local antiCarHitEnabled = false

local function avoidcarhit()
    if not antiCarHitEnabled then return end
    
    local plr = Players.LocalPlayer
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local originalCFrame = hrp.CFrame
    
    -- Find the car (assuming it's in workspace.Testing)
    local testingFolder = workspace:FindFirstChild("Testing")
    if not testingFolder then return end
    
    local car = testingFolder:FindFirstChild("Car")
    if not car or not car:FindFirstChild("EngineBlock") then return end
    
    local engineBlock = car.EngineBlock
    local carPosition = engineBlock.Position
    local playerPosition = hrp.Position
    
    -- Calculate distance to car
    local distance = (carPosition - playerPosition).Magnitude
    
    -- Check if car is within the distance range
    if distance >= confasss.Distance and distance <= confasss.Distance + 3 then
        -- Create baseplate for player to stand on
        local baseplate = Instance.new("Part")
        baseplate.Name = "AntiCarHitBaseplate"
        baseplate.Size = Vector3.new(6, 1, 6)
        baseplate.Position = Vector3.new(playerPosition.X, playerPosition.Y - confasss.UnderTp - 0.5, playerPosition.Z)
        baseplate.Anchored = true
        baseplate.CanCollide = true
        baseplate.Material = Enum.Material.SmoothPlastic
        baseplate.BrickColor = BrickColor.new("Really black")
        baseplate.Parent = workspace
        
        -- Teleport player down to the baseplate
        hrp.CFrame = CFrame.new(playerPosition.X, playerPosition.Y - confasss.UnderTp, playerPosition.Z)
        
        -- Wait for configured time
        task.wait(confasss.Waiting)
        
        -- Check if car is still near the original position
        local newCarDistance = (engineBlock.Position - originalCFrame.Position).Magnitude
        
        if newCarDistance >= confasss.Distance and newCarDistance <= confasss.Distance + 3 then
            -- Calculate direction from car to original position
            local direction = (originalCFrame.Position - engineBlock.Position).Unit
            -- Teleport 30 studs back from car position
            local newTeleportPos = engineBlock.Position + direction * confasss.UnderTp
            hrp.CFrame = CFrame.new(newTeleportPos.X, originalCFrame.Y, newTeleportPos.Z)
        else
            -- Teleport back to original position
            hrp.CFrame = originalCFrame
        end
        
        -- Clean up the baseplate
        baseplate:Destroy()
    end
end

-- Continuous execution
local connection
local function startAntiCarHit()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        if antiCarHitEnabled then
            avoidcarhit()
        end
    end)
end

-- Start the system
startAntiCarHit()

-- GUI Elements (assuming HumanoidBOX is your GUI library)
HumanoidBOX:AddToggle("Anti car hit", {
    Text = "Anti car hit",
    Default = false,
    Callback = function(Value)
        antiCarHitEnabled = Value
    end
}):OnChanged(function(value)
    confasss.Enabled = value
end)

HumanoidBOX:AddSlider("Anti car hit distance", {
    Text = "Anti car hit distance",
    Min = 1,
    Max = 10,
    Default = confasss.Distance,
    Rounding = 1
}):OnChanged(function(value)
    confasss.Distance = value
end)

HumanoidBOX:AddSlider("Anti car hit waiting", {
    Text = "Anti car hit waiting",
    Min = 1,
    Max = 10,
    Default = confasss.Waiting,
    Rounding = 1,
}):OnChanged(function(value)
    confasss.Waiting = value
end)

HumanoidBOX:AddSlider("Anti car hit under tp", {
    Text = "Anti car hit under tp",
    Min = 1,
    Max = 100,
    Default = confasss.UnderTp,
    Rounding = 1,
}):OnChanged(function(value)
    confasss.UnderTp = value
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local turnconf = {
    Enabled = false,
    Distance = 15,
}

-- Function to find the nearest player
local function findNearestPlayer()
    local nearestPlayer = nil
    local nearestDistance = turnconf.Distance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                if distance <= nearestDistance then
                    nearestPlayer = player
                    nearestDistance = distance
                end
            end
        end
    end
    
    return nearestPlayer, nearestDistance
end

-- Function to turn character towards target
local function turnToTarget(targetPosition)
    if not rootPart then return end
    
    local direction = (targetPosition - rootPart.Position).Unit
    local lookAt = Vector3.new(direction.X, 0, direction.Z) -- Keep horizontal only
    
    -- Set the character's CFrame to look at the target
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + lookAt)
end

-- Function to move towards target
local function moveToTarget(targetPosition)
    if not humanoid then return end
    
    local direction = (targetPosition - rootPart.Position).Unit
    humanoid:MoveTo(rootPart.Position + direction * 5) -- Move 5 studs towards target
end

-- Main loop
local connection
local function startAutoTurn()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        if not turnconf.Enabled or not character or not rootPart or not humanoid then
            -- Re-get character references if needed
            character = localPlayer.Character
            if character then
                humanoid = character:FindFirstChild("Humanoid")
                rootPart = character:FindFirstChild("HumanoidRootPart")
            end
            return
        end
        
        local nearestPlayer, distance = findNearestPlayer()
        
        if nearestPlayer and nearestPlayer.Character then
            local targetRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                -- Turn towards the target
                turnToTarget(targetRoot.Position)
                
                -- Optional: Also move towards the target if you want following behavior
                -- moveToTarget(targetRoot.Position)
            end
        end
    end)
end

-- Character added event (for respawns)
localPlayer.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- Toggle functionality (assuming this is part of your existing UI)
HumanoidBOX:AddToggle("Auto turn char at nearest player", {
    Text = "Auto turn at nearest player",
    Default = false,
    Callback = function(Value)
        turnconf.Enabled = Value
        startAutoTurn()
    end
})

HumanoidBOX:AddSlider("Distance", {
    Text = "Auto turn distance",
    Min = 1,
    Max = 100,
    Default = 15,
    Rounding = 1,
    Callback = function(Value)
        turnconf.Distance = Value
    end
})


local VisualsBOX = Tabs.visuals:AddLeftGroupbox("Visuals", "eye")


-- Bullet Tracer and Bullet Hit Settings
local bulletTracerSettings = {
	Enabled = false,
	Color = Color3.fromRGB(255, 255, 255),
	Size = 0.1,
	Transparency = 0.1,
	FadeTime = 3
}

local bulletHitSettings = {
	Enabled = false,
	Color = Color3.fromRGB(255, 0, 0),
	Transparency = 0.5,
	Size = 0.5,
	FadeTime = 1
}

-- Create a 3D bullet tracer using simple BaseParts and create a sphere at hit point
local function createBulletTracerAndHit(bullet)
	if not bullet or not bullet.Parent then return end

	local startCFrame = bullet.CFrame
	local startPosition = startCFrame.Position
	local direction = startCFrame.LookVector

	-- Raycast to find where bullet would hit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {bullet}

	-- Add local player character and all its parts to blacklist to ignore them
	local localPlayer = game:GetService("Players").LocalPlayer
	if localPlayer.Character then
		table.insert(raycastParams.FilterDescendantsInstances, localPlayer.Character)
		for _, part in ipairs(localPlayer.Character:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(raycastParams.FilterDescendantsInstances, part)
			end
		end
	end

	local raycastResult = workspace:Raycast(startPosition, direction * 10000, raycastParams)
	local endPosition = raycastResult and raycastResult.Position or (startPosition + direction * 10000)

	-- Calculate distance and create tracer
	local distance = (endPosition - startPosition).Magnitude

	-- Create a simple long BasePart tracer
	if bulletTracerSettings.Enabled then
		local tracer = Instance.new("Part")
		tracer.Name = "BulletTracer"
		tracer.Material = Enum.Material.Neon
		tracer.Color = bulletTracerSettings.Color
		tracer.Transparency = bulletTracerSettings.Transparency
		tracer.CanCollide = false
		tracer.Anchored = true
		tracer.Parent = workspace
		tracer.CanQuery = false
		tracer.CanTouch = false
		tracer.Size = Vector3.new(bulletTracerSettings.Size, bulletTracerSettings.Size, distance)
		local midPoint = (startPosition + endPosition) / 2
		tracer.CFrame = CFrame.lookAt(midPoint, endPosition)

		-- Fade out over time
		local fadeTime = bulletTracerSettings.FadeTime
		local startTime = tick()
		local fadeConnection
		fadeConnection = game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			if elapsed >= fadeTime then
				tracer:Destroy()
				fadeConnection:Disconnect()
			else
				local alpha = 1 - (elapsed / fadeTime)
				local newTransparency = bulletTracerSettings.Transparency + (0.9 * (1 - alpha))
				tracer.Transparency = newTransparency
			end
		end)
	end

	-- Create a sphere at the hit position
	if bulletHitSettings.Enabled then
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Name = "BulletHitSphere"
		sphere.Material = Enum.Material.Neon
		sphere.Color = bulletHitSettings.Color
		sphere.Transparency = bulletHitSettings.Transparency
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.CanQuery = false
		sphere.CanTouch = false
		sphere.Size = Vector3.new(bulletHitSettings.Size, bulletHitSettings.Size, bulletHitSettings.Size)
		sphere.Position = endPosition
		sphere.Parent = workspace

		-- Fade out over time
		local fadeTime = bulletHitSettings.FadeTime
		local startTime = tick()
		local fadeConnection
		fadeConnection = game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			if elapsed >= fadeTime then
				sphere:Destroy()
				fadeConnection:Disconnect()
			else
				local alpha = 1 - (elapsed / fadeTime)
				local newTransparency = bulletHitSettings.Transparency + (0.9 * (1 - alpha))
				sphere.Transparency = newTransparency
			end
		end)
	end
end

-- Listen for new bullets appearing in workspace.Cache
workspace.Cache.ChildAdded:Connect(function(child)
	if child.Name == "Default" then
		if bulletTracerSettings.Enabled or bulletHitSettings.Enabled then
			createBulletTracerAndHit(child)
		end
	end
end)

-- Also check for existing bullet on script start
local existingBullet = workspace.Cache:FindFirstChild("Default")
if existingBullet and (bulletTracerSettings.Enabled or bulletHitSettings.Enabled) then
	createBulletTracerAndHit(existingBullet)
end

-- Bullet Tracers Toggle and Options
VisualsBOX:AddToggle("BulletTracers", {Text = "Bullet Tracers", Default = false})
	:AddColorPicker("BulletTracersColor", {Default = bulletTracerSettings.Color})
	:OnChanged(function()
		bulletTracerSettings.Enabled = Toggles.BulletTracers.Value
	end)

Options.BulletTracersColor:OnChanged(function()
	bulletTracerSettings.Color = Options.BulletTracersColor.Value
end)

VisualsBOX:AddSlider("BulletTracersSize", {
	Text = "Bullet Tracers Size",
	Min = 0.1,
	Max = 1,
	Default = bulletTracerSettings.Size,
	Rounding = 3,
	Suffix = "m",
	Tooltip = "Adjust the size of the bullet tracers"
}):OnChanged(function()
	bulletTracerSettings.Size = Options.BulletTracersSize.Value
end)

VisualsBOX:AddSlider("BulletTracersTransparency", {
	Text = "Bullet Tracers Transparency",
	Min = 0,
	Max = 1,
	Default = bulletTracerSettings.Transparency,
	Rounding = 2,
	Tooltip = "Adjust the transparency of the bullet tracers"
}):OnChanged(function()
	bulletTracerSettings.Transparency = Options.BulletTracersTransparency.Value
end)

VisualsBOX:AddSlider("BulletTracersFadeTime", {
	Text = "Bullet Tracers Fade Time",
	Min = 0.1,
	Max = 20, 
	Default = bulletTracerSettings.FadeTime,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Adjust the fade time of the bullet tracers"
}):OnChanged(function()
	bulletTracerSettings.FadeTime = Options.BulletTracersFadeTime.Value
end)

-- Bullet Hit Sphere Toggle and Options
VisualsBOX:AddToggle("BulletHits", {
	Text = "Bullet Hits (Sphere)",
	Default = false,
	Tooltip = "Enable bullet hit spheres at bullet impact points",
	Callback = function(value)
		bulletHitSettings.Enabled = value
	end
})


VisualsBOX:AddLabel("BulletHitsColor"):AddColorPicker("BulletHitsColor", {
	Default = bulletHitSettings.Color,
	Name = "bullet hits color",
	Callback = function(value)
		bulletHitSettings.Color = value
	end
})

VisualsBOX:AddSlider("BulletHitsTransparency", {
	Text = "Bullet Hit Sphere Transparency",
	Min = 0,
	Max = 1,
	Default = bulletHitSettings.Transparency,
	Rounding = 2,
	Tooltip = "Adjust the transparency of the bullet hit sphere"
}):OnChanged(function()
	bulletHitSettings.Transparency = Options.BulletHitsTransparency.Value
end)

VisualsBOX:AddSlider("BulletHitsSize", {
	Text = "Bullet Hit Sphere Size",
	Min = 0.1,
	Max = 3,
	Default = bulletHitSettings.Size,
	Rounding = 2,
	Tooltip = "Adjust the size of the bullet hit sphere"
}):OnChanged(function()
	bulletHitSettings.Size = Options.BulletHitsSize.Value
end)

VisualsBOX:AddSlider("BulletHitsFadeTime", {
	Text = "Bullet Hit Sphere Fade Time",
	Min = 0.1,
	Max = 10,
	Default = bulletHitSettings.FadeTime,
	Rounding = 2,
	Suffix = "s",
	Tooltip = "Adjust the fade time of the bullet hit sphere"
}):OnChanged(function()
	bulletHitSettings.FadeTime = Options.BulletHitsFadeTime.Value
end)

VisualsBOX:AddLabel("Fov changer")

-- FOV Changer UI
-- Store the last FOV we set so we can reapply it if something resets it (like equipping a gun)
local lastFovChangerValue = 90
local fovConnection

VisualsBOX:AddToggle("FovChanger", {Text = "Fov Changer", Default = false})
	:OnChanged(function()
		fovchanger = Toggles.FovChanger.Value
		local camera = game:GetService("Workspace").CurrentCamera

		if fovchanger then
			lastFovChangerValue = Options.FovChangerValue.Value
			camera.FieldOfView = lastFovChangerValue

			-- Listen for FOV changes and reapply if something else changes it (e.g., equipping a gun)
			if fovConnection then fovConnection:Disconnect() end
			fovConnection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
				if Toggles.FovChanger.Value and math.abs(camera.FieldOfView - lastFovChangerValue) > 0.1 then
					camera.FieldOfView = lastFovChangerValue
				end
			end)
		else
			-- Reset FOV to default (90) when disabled
			if fovConnection then fovConnection:Disconnect() end
			camera.FieldOfView = 90
		end
	end)

	VisualsBOX:AddSlider("FovChangerValue", {
	Text = "Fov Changer Value",
	Min = 0,
	Max = 120,
	Default = 90,
	Rounding = 0,
	Suffix = "°",
	Tooltip = "Adjust the value of fov changer"
}):OnChanged(function()
	if Toggles.FovChanger.Value then
		lastFovChangerValue = Options.FovChangerValue.Value
		game:GetService("Workspace").CurrentCamera.FieldOfView = lastFovChangerValue
	end
end)

local sensing = Tabs.visuals:AddRightGroupbox("ESP", "scan")

-- 1. Load the library
local Sense = loadstring(game:HttpGet('https://sirius.menu/sense'))()

-- 2. Create configuration (используем настройки из примера)
Sense.whitelist = {}
Sense.sharedSettings = {
    textSize = 13,
    textFont = 2,
    limitDistance = false,
    maxDistance = 150,
    useTeamColor = false
}

Sense.teamSettings = {
    enemy = {
        enabled = false,
        box = false,
        boxColor = { Color3.new(1,0,0), 1 },
        boxOutline = true,
        boxOutlineColor = { Color3.new(), 1 },
        boxFill = false,
        boxFillColor = { Color3.new(1,0,0), 0.5 },
        healthBar = false,
        healthyColor = Color3.new(0,1,0),
        dyingColor = Color3.new(1,0,0),
        healthBarOutline = true,
        healthBarOutlineColor = { Color3.new(), 0.5 },
        healthText = false,
        healthTextColor = { Color3.new(1,1,1), 1 },
        healthTextOutline = true,
        healthTextOutlineColor = Color3.new(),
        box3d = false,
        box3dColor = { Color3.new(1,0,0), 1 },
        name = false,
        nameColor = { Color3.new(1,1,1), 1 },
        nameOutline = true,
        nameOutlineColor = Color3.new(),
        weapon = false,
        weaponColor = { Color3.new(1,1,1), 1 },
        weaponOutline = true,
        weaponOutlineColor = Color3.new(),
        distance = false,
        distanceColor = { Color3.new(1,1,1), 1 },
        distanceOutline = true,
        distanceOutlineColor = Color3.new(),
        tracer = false,
        tracerOrigin = "Bottom",
        tracerColor = { Color3.new(1,0,0), 1 },
        tracerOutline = true,
        tracerOutlineColor = { Color3.new(), 1 },
        offScreenArrow = false,
        offScreenArrowColor = { Color3.new(1,1,1), 1 },
        offScreenArrowSize = 15,
        offScreenArrowRadius = 150,
        offScreenArrowOutline = true,
        offScreenArrowOutlineColor = { Color3.new(), 1 },
        chams = false,
        chamsVisibleOnly = false,
        chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
        chamsOutlineColor = { Color3.new(1,0,0), 0 },
    },
    friendly = {
        enabled = false,
        box = false,
        boxColor = { Color3.new(0,1,0), 1 },
        boxOutline = true,
        boxOutlineColor = { Color3.new(), 1 },
        boxFill = false,
        boxFillColor = { Color3.new(0,1,0), 0.5 },
        healthBar = false,
        healthyColor = Color3.new(0,1,0),
        dyingColor = Color3.new(1,0,0),
        healthBarOutline = true,
        healthBarOutlineColor = { Color3.new(), 0.5 },
        healthText = false,
        healthTextColor = { Color3.new(1,1,1), 1 },
        healthTextOutline = true,
        healthTextOutlineColor = Color3.new(),
        box3d = false,
        box3dColor = { Color3.new(0,1,0), 1 },
        name = false,
        nameColor = { Color3.new(1,1,1), 1 },
        nameOutline = true,
        nameOutlineColor = Color3.new(),
        weapon = false,
        weaponColor = { Color3.new(1,1,1), 1 },
        weaponOutline = true,
        weaponOutlineColor = Color3.new(),
        distance = false,
        distanceColor = { Color3.new(1,1,1), 1 },
        distanceOutline = true,
        distanceOutlineColor = Color3.new(),
        tracer = false,
        tracerOrigin = "Bottom",
        tracerColor = { Color3.new(0,1,0), 1 },
        tracerOutline = true,
        tracerOutlineColor = { Color3.new(), 1 },
        offScreenArrow = false,
        offScreenArrowColor = { Color3.new(1,1,1), 1 },
        offScreenArrowSize = 15,
        offScreenArrowRadius = 150,
        offScreenArrowOutline = true,
        offScreenArrowOutlineColor = { Color3.new(), 1 },
        chams = false,
        chamsVisibleOnly = false,
        chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
        chamsOutlineColor = { Color3.new(0,1,0), 0 }
    }
}

sensing:AddLabel("Enemy")

sensing:AddToggle("Enable Enemy ESP", {
    Text = "Enable Enemy ESP",
    Default = false,
    Tooltip = "Enable ESP for enemies",
    Callback = function(value)
        Sense.teamSettings.enemy.enabled = value
    end
})

sensing:AddToggle("Enable Friendly ESP", {
    Text = "Enable Friendly ESP",
    Default = false,
    Tooltip = "Enable ESP for teammates",
    Callback = function(value)
        Sense.teamSettings.friendly.enabled = value
    end
})

sensing:AddToggle("Use Team Color", {
    Text = "Use Team Color",
    Default = false,
    Tooltip = "Use team colors for ESP",
    Callback = function(value)
        Sense.sharedSettings.useTeamColor = value
    end
})

sensing:AddToggle("Limit Distance", {
    Text = "Limit Distance",
    Default = false,
    Tooltip = "Limit ESP render distance",
    Callback = function(value)
        Sense.sharedSettings.limitDistance = value
    end
})

sensing:AddSlider("Max Distance", {
    Text = "Max Distance",
    Min = 50,
    Max = 1000,
    Default = 150,
    Rounding = 0,
    Tooltip = "Maximum ESP render distance",
    Callback = function(value)
        Sense.sharedSettings.maxDistance = value
    end
})

sensing:AddSlider("Text Size", {
    Text = "Text Size",
    Min = 8,
    Max = 24,
    Default = 13,
    Rounding = 0,
    Tooltip = "Text size for ESP elements",
    Callback = function(value)
        Sense.sharedSettings.textSize = value
    end
})

sensing:AddDropdown("Text Font", {
    Text = "Text Font",
    Default = 2,
    Tooltip = "Font for ESP text",
    Options = {1, 2, 3},
    Callback = function(value)
        Sense.sharedSettings.textFont = value
    end
})

sensing:AddToggle("Enemy Box", {
    Text = "Box",
    Default = false,
    Tooltip = "Show box around enemies",
    Callback = function(value)
        Sense.teamSettings.enemy.box = value
    end
}):AddColorPicker("Enemy Box Color", {
    Default = Color3.new(1,0,0),
    Tooltip = "Enemy box color",
    Callback = function(value)
        Sense.teamSettings.enemy.boxColor = {value, 1}
    end
})

sensing:AddToggle("Enemy Box Outline", {
    Text = "Box Outline",
    Default = true,
    Tooltip = "Show box outline",
    Callback = function(value)
        Sense.teamSettings.enemy.boxOutline = value
    end
})

sensing:AddToggle("Enemy Box Fill", {
    Text = "Box Fill",
    Default = false,
    Tooltip = "Fill the box",
    Callback = function(value)
        Sense.teamSettings.enemy.boxFill = value
    end
}):AddColorPicker("Enemy Box Fill Color", {
    Default = Color3.new(1,0,0),
    Tooltip = "Enemy box fill color",
    Callback = function(value)
        Sense.teamSettings.enemy.boxFillColor = {value, 0.5}
    end
})

sensing:AddToggle("Enemy Health Bar", {
    Text = "Health Bar",
    Default = false,
    Tooltip = "Show health bar",
    Callback = function(value)
        Sense.teamSettings.enemy.healthBar = value
    end
}):AddColorPicker("Enemy Healthy Color", {
    Default = Color3.new(0,1,0),
    Tooltip = "Color for high health",
    Callback = function(value)
        Sense.teamSettings.enemy.healthyColor = value
    end
}):AddColorPicker("Enemy Dying Color", {
    Default = Color3.new(1,0,0),
    Tooltip = "Color for low health",
    Callback = function(value)
        Sense.teamSettings.enemy.dyingColor = value
    end
})

sensing:AddToggle("Enemy Health Text", {
    Text = "Health Text",
    Default = false,
    Tooltip = "Show health text",
    Callback = function(value)
        Sense.teamSettings.enemy.healthText = value
    end
})

sensing:AddToggle("Enemy Name", {
    Text = "Name",
    Default = false,
    Tooltip = "Show player name",
    Callback = function(value)
        Sense.teamSettings.enemy.name = value
    end
})

sensing:AddToggle("Enemy Weapon", {
    Text = "Weapon",
    Default = false,
    Tooltip = "Show weapon name",
    Callback = function(value)
        Sense.teamSettings.enemy.weapon = value
    end
})

sensing:AddToggle("Enemy Distance", {
    Text = "Distance",
    Default = false,
    Tooltip = "Show distance",
    Callback = function(value)
        Sense.teamSettings.enemy.distance = value
    end
})

sensing:AddToggle("Enemy Tracer", {
    Text = "Tracer",
    Default = false,
    Tooltip = "Show tracer line",
    Callback = function(value)
        Sense.teamSettings.enemy.tracer = value
    end
})

sensing:AddDropdown("Enemy Tracer Origin", {
    Text = "Tracer Origin",
    Default = "Bottom",
    Tooltip = "Tracer starting point",
    Options = {"Bottom", "Top", "Middle"},
    Callback = function(value)
        Sense.teamSettings.enemy.tracerOrigin = value
    end
})

sensing:AddToggle("Enemy Off-Screen Arrows", {
    Text = "Off-Screen Arrows",
    Default = false,
    Tooltip = "Show arrows for off-screen players",
    Callback = function(value)
        Sense.teamSettings.enemy.offScreenArrow = value
    end
})

sensing:AddSlider("Enemy Arrow Size", {
    Text = "Arrow Size",
    Min = 10,
    Max = 30,
    Default = 15,
    Rounding = 0,
    Tooltip = "Size of off-screen arrows",
    Callback = function(value)
        Sense.teamSettings.enemy.offScreenArrowSize = value
    end
})

sensing:AddToggle("Enemy Chams", {
    Text = "Chams",
    Default = false,
    Tooltip = "Show chams",
    Callback = function(value)
        Sense.teamSettings.enemy.chams = value
    end
})

sensing:AddLabel("Friendly")

sensing:AddToggle("Friendly Box", {
    Text = "Box",
    Default = false,
    Tooltip = "Show box around teammates",
    Callback = function(value)
        Sense.teamSettings.friendly.box = value
    end
}):AddColorPicker("Friendly Box Color", {
    Default = Color3.new(0,1,0),
    Tooltip = "Friendly box color",
    Callback = function(value)
        Sense.teamSettings.friendly.boxColor = {value, 1}
    end
})

sensing:AddToggle("Friendly Health Bar", {
    Text = "Health Bar",
    Default = false,
    Tooltip = "Show health bar",
    Callback = function(value)
        Sense.teamSettings.friendly.healthBar = value
    end
})

sensing:AddToggle("Friendly Name", {
    Text = "Name",
    Default = false,
    Tooltip = "Show player name",
    Callback = function(value)
        Sense.teamSettings.friendly.name = value
    end
})

sensing:AddToggle("Friendly Weapon", {
    Text = "Weapon",
    Default = false,
    Tooltip = "Show weapon name",
    Callback = function(value)
        Sense.teamSettings.friendly.weapon = value
    end
})

sensing:AddToggle("Friendly Distance", {
    Text = "Distance",
    Default = false,
    Tooltip = "Show distance",
    Callback = function(value)
        Sense.teamSettings.friendly.distance = value
    end
})

sensing:AddToggle("Friendly Tracer", {
    Text = "Tracer",
    Default = false,
    Tooltip = "Show tracer line",
    Callback = function(value)
        Sense.teamSettings.friendly.tracer = value
    end
})

sensing:AddDropdown("Friendly Tracer Origin", {
    Text = "Tracer Origin",
    Default = "Bottom",
    Tooltip = "Tracer starting point",
    Options = {"Bottom", "Top", "Middle"},
    Callback = function(value)
        Sense.teamSettings.friendly.tracerOrigin = value
    end
})

sensing:AddLabel("Controls")

sensing:AddButton("Load ESP", {
    Text = "Load ESP",
    Tooltip = "Load the ESP",
    Callback = function()
        Sense.Load()
    end
})

sensing:AddButton("Unload ESP", {
    Text = "Unload ESP",
    Tooltip = "Unload the ESP",
    Callback = function()
        Sense.Unload()
    end
})

sensing:AddButton("Refresh ESP", {
    Text = "Refresh ESP",
    Tooltip = "Refresh ESP settings",
    Callback = function()
        Sense.Unload()
        wait(0.1)
        Sense.Load()
    end
})

-- 4. Загружаем ESP
Sense.Load()

-- 5. Добавляем возможность выгрузки при закрытии
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Sense ESP Settings" then
        Sense.Unload()
    end
end)

local UtilityBOX = Tabs.utility:AddLeftGroupbox("Utility", "wrench")


local plr = game:GetService("Players").LocalPlayer
local BigHit = false

-- Only set Combat's "Count" and "OldCount" attributes if BigHit is enabled
game:GetService("RunService").Heartbeat:Connect(function()
	if BigHit then
		local char = plr.Character
		if char then
			local combat = char:FindFirstChild("Combat")
			if combat then
				pcall(function()
					if combat:GetAttribute("Count") ~= nil then
						combat:SetAttribute("Count", 3)
					end
					if combat:GetAttribute("OldCount") ~= nil then
						combat:SetAttribute("OldCount", 0)
					end
					if combat:GetAttribute("Cooldown") ~= nil then
						combat:SetAttribute("Cooldown", false)
					end
				end)
			end
		end
	end
end)

-- Variables
local targetname = nil
local carBeamEnabled = false

-- Function to teleport car to target
local function tpcar()
    if not carBeamEnabled then
        return
    end
    
    local plr = game:GetService("Players").LocalPlayer
    local char = plr.Character
    
    -- Find the car engine block
    local carEngine = workspace:FindFirstChild("Vehicles")
    if not carEngine then return end
    
    carEngine = carEngine:FindFirstChild("Car")
    if not carEngine then return end
    
    carEngine = carEngine:FindFirstChild("EngineBlock")
    if not carEngine then return end
    
    -- Find target character
    local targetchar = workspace:FindFirstChild("Humans"):FindFirstChild(targetname)
    if not targetchar then return end
    
    local targethrp = targetchar:FindFirstChild("HumanoidRootPart")
    if not targethrp then return end
    
    -- Teleport car to target
    carEngine.CFrame = targethrp.CFrame
end

-- Continuous loop for car beam
spawn(function()
    while true do
        tpcar()
        wait(0.1) -- Adjust timing as needed
    end
end)

-- Car target input
UtilityBOX:AddInput("Car target", {
    Default = "car target",
    Numeric = false,
    Finished = true,
    ClearTextOnFocus = false,
    Text = "Input car targets name",
    Tooltip = "Input car targets name",
    Callback = function(value)
        if value then
            targetname = value
        end
    end
})

-- Car beam toggle
UtilityBOX:AddToggle("Car beam", {
    Text = "Car beam(must be in car)",
    Default = false,
    Callback = function(value)
        carBeamEnabled = value
    end
})

UtilityBOX:AddToggle("Always big hit", {
	Text = "Always 3nd hit",
	Default = false,
	Tooltip = "Always set 3nd hit",
	Callback = function(value)
		BigHit = value
	end
})

-- Rapid fire: set all tools' Cooldown attribute to false
local rapidFireConnection = nil

UtilityBOX:AddToggle("Rapid fire", {
	Text = "Rapid fire",
	Default = false,
	Tooltip = "Set all tools' Cooldown attribute to false rapidly",
	Callback = function(value)
		if value then
			if rapidFireConnection then
				rapidFireConnection:Disconnect()
			end
			rapidFireConnection = game:GetService("RunService").Heartbeat:Connect(function()
				local char = plr.Character
				if char then
					for _, tool in ipairs(char:GetChildren()) do
						if tool:IsA("Tool") then
							pcall(function()
								if tool:GetAttribute("Cooldown") ~= nil then
									tool:SetAttribute("Cooldown", false)
								end
							end)
						end
					end
				end
			end)
		else
			if rapidFireConnection then
				rapidFireConnection:Disconnect()
				rapidFireConnection = nil
			end
		end
	end
})

local triggerBotConnection = nil
local triggerbotDelay = 0.05
local triggerBotFovConnection = nil
local AliveCheck = false

-- Helper: Get mouse position
local function getMousePosition()
	return game:GetService("UserInputService"):GetMouseLocation()
end

-- Helper: Get position on screen
local function getPositionOnScreen(position)
	local Camera = game.Workspace.CurrentCamera
	local screenPos, onScreen = Camera:WorldToScreenPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Helper: Check if player is alive
local function isPlayerAlive(player)
	if not player.Character then return false end
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	return true
end

-- Helper: Check if player is in FOV
local function isPlayerInSilentAimFOV(player)
	if not player.Character then return false end
	local partName = SilentAimSettings.TargetPart or "HumanoidRootPart"
	local part = player.Character:FindFirstChild(partName)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not part or not humanoid or humanoid.Health <= 0 then return false end
	local mousePos = getMousePosition()
	if not mousePos then return false end
	local screenPos, onScreen = getPositionOnScreen(part.Position)
	if not onScreen then return false end
	local dist = (mousePos - screenPos).Magnitude
	return dist <= SilentAimSettings.FOVRadius
end

-- Helper: Simple debounce timer
local function makeDebounce()
	local last = 0
	return function(delay)
		local now = tick()
		if now - last >= delay then
			last = now
			return true
		end
		return false
	end
end

UtilityBOX:AddLabel("Triggerbot")

UtilityBOX:AddToggle("Trigger bot", {
	Text = "Trigger bot",
	Default = false,
	Tooltip = "Trigger bot",
	Callback = function(value)
		if value then
			if triggerBotConnection then
				triggerBotConnection:Disconnect()
			end
			local Players = game:GetService("Players")
			local LocalPlayer = Players.LocalPlayer
			local Mouse = LocalPlayer:GetMouse()
			local canClick = makeDebounce()
			triggerBotConnection = game:GetService("RunService").RenderStepped:Connect(function()
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local alive = true
						if AliveCheck then
							alive = isPlayerAlive(player)
						end
						if alive then
							local mouseTarget = Mouse.Target
							if mouseTarget and mouseTarget:IsDescendantOf(player.Character) then
								if canClick(triggerbotDelay) then
									mouse1press()
									mouse1release()
								end
								break
							end
						end
					end
				end
			end)
		else
			if triggerBotConnection then
				triggerBotConnection:Disconnect()
				triggerBotConnection = nil
			end
		end
	end
})

UtilityBOX:AddSlider("Triggerbot delay", {
	Text = "Triggerbot delay",
	Default = 0.05,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Tooltip = "Delay between triggerbot clicks (in seconds)",
	Callback = function(value)
		triggerbotDelay = value
	end
})

UtilityBOX:AddLabel("Random things")

local trollbox = workspace.Map.Tower.Traps.Buttons.Blowup.ProximityPrompt
local function explode()
	fireclickdetector(trollbox)
end

local function checkPlayersNearTrollbox()
	local trollboxPosition = workspace.Map.Tower.Traps.Buttons.Blowup.Position
	local players = game:GetService("Players"):GetPlayers()

	for _, player in ipairs(players) do
		if player ~= game:GetService("Players").LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - trollboxPosition).Magnitude
			if distance <= 15 then
				explode()
				break
			end
		end
	end
end

local trollConnection
local trollState = {enabled = false}
local trollToggle = UtilityBOX:AddToggle("Troll", {Text = "Auto click exploding box", Default = false})
trollToggle:OnChanged(function(value)
	trollState.enabled = value
	if trollState.enabled then
		trollConnection = game:GetService("RunService").Heartbeat:Connect(checkPlayersNearTrollbox)
	else
		if trollConnection then
			trollConnection:Disconnect()
			trollConnection = nil
		end
		local ok, err = pcall(function()
			removeHighlight()
		end)
		if not ok then
			print("[Troll] Error disabling troll: " .. tostring(err))
		end
	end
end)

local function eatsandwich()
	local plr = game:GetService("Players").LocalPlayer
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local sandwich = workspace.Map.Tower.Houses.Shack["Turkey Sandwich"].Cheese
	local sandwichpp = sandwich.ProximityPrompt

	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		local originalCFrame = plr.Character.HumanoidRootPart.CFrame
		hrp.CFrame = sandwich.CFrame
		task.wait(0.25)
		fireproximityprompt(sandwichpp)
		task.wait(0.25)
		hrp.CFrame = originalCFrame
	end
end

UtilityBOX:AddButton({
	Text = "Eat sandwich",
	Func = function()
		eatsandwich()
	end,
	Tooltip = "Eat sandwich",
	DoubleClick = false,
})

local kauraBOX = Tabs.Killaura:AddLeftGroupbox("Killaura")

-- Configuration
local kconfig = {
    enabled = false,
    range = 10,
    delaying = 0.5,
    HitPart = "Head"
}

-- Variables
local nearestplayer = nil
local probablyguns = {
    "AK47",
    "Spas 12",
    "P250",
    "Deagle",
    "Remington"
}

-- Function to check if player has a gun
local function hasGun(character)
    if not character then return false, nil end
    
    for _, gunName in pairs(probablyguns) do
        if character:FindFirstChild(gunName) then
            return true, gunName
        end
    end
    
    return false, nil
end

-- Function to get nearest player
local function getnearestplayer()
    local players = game:GetService("Players"):GetPlayers()
    local nearestplayer = nil
    local localPlayer = game:GetService("Players").LocalPlayer
    
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPosition = localPlayer.Character.HumanoidRootPart.Position
    
    for i, v in pairs(players) do
        if v ~= localPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
            if v.Character.Humanoid.Health > 0 then
                local distance = (v.Character.HumanoidRootPart.Position - localPosition).magnitude
                if distance <= kconfig.range then
                    if nearestplayer == nil then
                        nearestplayer = v
                    else
                        local currentDistance = (nearestplayer.Character.HumanoidRootPart.Position - localPosition).magnitude
                        if distance < currentDistance then
                            nearestplayer = v
                        end
                    end
                end
            end
        end
    end
    
    return nearestplayer
end

-- Fire event function
local function fire()
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    
    local hasGunBool, gunName = hasGun(character)
    if not hasGunBool then
        return
    end
    
    local args = {
        character:WaitForChild(gunName),
        "Fire",
        {
            direction = Vector3.new(0.49055737257003784, -0.12968432903289795, 0.8617050051689148),
            bullet = game:GetService("ReplicatedStorage"):WaitForChild("Models"):WaitForChild("Bullets"):WaitForChild("Default"),
            velocity = 2000,
            origin = Vector3.new(565.5264282226562, 2405.215087890625, 386.8387451171875)
        }
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fire"):FireServer(unpack(args))
end

-- Hit event function
local function hit()
    if not nearestplayer then
        return
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local hasGunBool, gunName = hasGun(localPlayer.Character)
    
    if not hasGunBool then
        return
    end
    
    local args = {
        gunName, -- Using the actual gun name (in quotes like "AK47" or "Spas 12")
        "Hit",
        {
            normal = Vector3.new(0.06565561145544052, 0, -0.9978423714637756),
            velocity = Vector3.new(981.11474609375, -272.4038391113281, 1723.4100341796875),
            hit = nearestplayer.Character:WaitForChild(kconfig.HitPart),
            position = Vector3.new(626.642578125, 2388.672607421875, 494.1943664550781)
        }
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fire"):FireServer(unpack(args))
end

-- Main kill aura function
local function kattack()
    if kconfig.enabled then
        nearestplayer = getnearestplayer()
        if nearestplayer then
            local localPlayer = game:GetService("Players").LocalPlayer
            local hasGunBool, gunName = hasGun(localPlayer.Character)
            
            if hasGunBool then
                fire()
                task.wait(kconfig.delaying)
                hit()
            end
        end
    end
end

-- Continuous loop for kill aura
spawn(function()
    while true do
        kattack()
        wait(0.1) -- Adjust timing as needed
    end
end)

-- UI Elements
-- Kill aura toggle
kauraBOX:AddToggle("kill aura", {
    Text = "Kill aura",
    Default = false,
    Tooltip = "Enable kill aura",
    Callback = function(value)
        kconfig.enabled = value
    end
})

-- Kill aura range slider
kauraBOX:AddSlider("Kaura range", {
    Text = "Kaura range",
    Default = 10,
    Min = 1,
    Max = 1000,
    Rounding = 1,
    Tooltip = "Adjust the kill aura range",
    Callback = function(value)
        kconfig.range = value
    end
})

-- Kill aura delay slider
kauraBOX:AddSlider("Kaura delay", {
    Text = "Kaura delay",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Tooltip = "Adjust the kill aura delay",
    Callback = function(value)
        kconfig.delaying = value
    end
})

-- Hit part dropdown
kauraBOX:AddDropdown("HitPart", {
    Text = "HitPart",
    Default = "Head",
    Values = {"Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Torso"},
    Tooltip = "Select the part to hit",
    Callback = function(value)
        kconfig.HitPart = value
    end
})

local AntiAimBOX = Tabs.anti:AddLeftGroupbox("AntiAim")

	local methods = {
		"Desync Jitter(broken)",
		"Body Velocity(works some)", 
		"Angle Inversion(broken)",
		"Random Offset(broken)",
		"Smooth Movement(broken)",
		"Random AntiAim(semi works)"
	}

	-- Переменные
	local DesyncEnabled = false
	local AntiAimMethod = "Desync Jitter"
	local antiAimConnection = nil

	-- Основные функции анти-аима
	local function ApplyDesyncJitter(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local currentTick = tick()
		local jitterAngle = math.sin(currentTick * 8) * 25 -- ±25 градусов
		rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(jitterAngle), 0)
	end

	local function ApplyBodyVelocity(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local vel = rootPart:FindFirstChild("AntiAimVelocity") or Instance.new("BodyVelocity")
		vel.Name = "AntiAimVelocity"
		vel.Parent = rootPart
		vel.MaxForce = Vector3.new(4000, 0, 4000)
		vel.Velocity = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	end

	local function ApplyAngleInversion(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local invertedAngle = CFrame.Angles(0, math.rad(180), 0)
		rootPart.CFrame = CFrame.new(rootPart.Position) * invertedAngle
	end

	local function ApplyRandomOffset(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") and part ~= rootPart then
				local weld = part:FindFirstChildOfClass("Weld")
				if weld then
					local offset = Vector3.new(math.random(-8, 8)/100, math.random(-3, 3)/100, math.random(-8, 8)/100)
					weld.C0 = weld.C0 + CFrame.new(offset)
				end
			end
		end
	end

	local function ApplySmoothMovement(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local time = tick()
		local smoothAngle = math.sin(time * 4) * 20 -- ±20 градусов
		rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(smoothAngle), 0)
	end

	local function ApplyRandomAntiAim(character)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local angle = math.random(-360, 360)
		local breaks = math.random(3, 10)
		local inc = angle / breaks
		local currentAngle = 0

		for i = 1, breaks do
			task.wait(math.random(0.01, 0.1))
			currentAngle = currentAngle + inc
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(currentAngle), 0)
		end
	end

	-- Основная функция применения анти-аима
	local function ApplyAntiAim(character)
		if not character or not character:FindFirstChild("Humanoid") then return end

		if AntiAimMethod == "Desync Jitter" then
			ApplyDesyncJitter(character)
		elseif AntiAimMethod == "Body Velocity" then
			ApplyBodyVelocity(character)
		elseif AntiAimMethod == "Angle Inversion" then
			ApplyAngleInversion(character)
		elseif AntiAimMethod == "Random Offset" then
			ApplyRandomOffset(character)
		elseif AntiAimMethod == "Smooth Movement" then
			ApplySmoothMovement(character)
		elseif AntiAimMethod == "Random AntiAim" then
			ApplyRandomAntiAim(character)
		end
	end

	-- Функция очистки анти-аима
	local function CleanupAntiAim(character)
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local vel = rootPart:FindFirstChild("AntiAimVelocity")
				if vel then
					vel:Destroy()
				end
			end

			-- Восстановление оригинальных позиций weld
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					local weld = part:FindFirstChildOfClass("Weld")
					if weld and weld:FindFirstChild("OriginalC0") then
						weld.C0 = weld.OriginalC0.Value
						weld.OriginalC0:Destroy()
					end
				end
			end
		end
	end

	-- Запуск анти-аима
	function StartAntiAim()
		if antiAimConnection then
			antiAimConnection:Disconnect()
		end

		-- Сохраняем оригинальные позиции weld
		local character = game.Players.LocalPlayer.Character
		if character then
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					local weld = part:FindFirstChildOfClass("Weld")
					if weld and not weld:FindFirstChild("OriginalC0") then
						local originalValue = Instance.new("CFrameValue")
						originalValue.Name = "OriginalC0"
						originalValue.Value = weld.C0
						originalValue.Parent = weld
					end
				end
			end
		end

		antiAimConnection = game:GetService("RunService").Heartbeat:Connect(function()
			if not DesyncEnabled or not AntiAimMethod then return end

			local player = game.Players.LocalPlayer
			if player and player.Character then
				ApplyAntiAim(player.Character)
			end
		end)
	end

	-- Остановка анти-аима
	function StopAntiAim()
		if antiAimConnection then
			antiAimConnection:Disconnect()
			antiAimConnection = nil
		end

		local player = game.Players.LocalPlayer
		if player and player.Character then
			CleanupAntiAim(player.Character)
		end
	end

	AntiAimBOX:AddToggle("Anti Aim", {
		Text = "Anti Aim",
		Default = false,
		Tooltip = "Anti Aim",
		Callback = function(value)
			DesyncEnabled = value
			if value then
				StartAntiAim()
			else
				StopAntiAim()
			end
		end
	})

	AntiAimBOX:AddDropdown("Anti Aim Method", {
		Values = methods,
		Default = "Desync Jitter",
		Multi = false,
		Text = "Anti Aim Method",
		Tooltip = "Select the anti aim method",
		Callback = function(value)
			AntiAimMethod = value
		end
	})

	-- Очистка при выходе из игры
	game.Players.LocalPlayer.CharacterRemoving:Connect(function(character)
		if DesyncEnabled then
			CleanupAntiAim(character)
		end
	end)



local ppas = Tabs.Proximity:AddLeftGroupbox("PP abuse")


local pps = {
	axepp = workspace.Map["Weapon Tables"]["Fire Axe"].ProximityPrompt,
	deaglepp = workspace.Map["Weapon Tables"]["Deagle"].ProximityPrompt,
	flashbangpp = workspace.Map["Weapon Tables"].Flashbang.ProximityPrompt,
	fraggrenadepp = workspace.Map["Weapon Tables"]["Frag Grenade"].ProximityPrompt,
	p250pp = workspace.Map["Weapon Tables"].P250.ProximityPrompt,
	remingtonpp = workspace.Map["Weapon Tables"].Remington.ProximityPrompt,
	ak47pp = workspace.Map["Weapon Tables"].AK47.ProximityPrompt,
	spas12pp = workspace.Map["Weapon Tables"]["Spas 12"].ProximityPrompt,
}
local toolspos = {
	Axe = workspace.Map["Weapon Tables"]["Fire Axe"].CFrame,
	Deagle = workspace.Map["Weapon Tables"]["Deagle"].CFrame,
	FlashBang = workspace.Map["Weapon Tables"].Flashbang.CFrame,
	Fraggrenade = workspace.Map["Weapon Tables"]["Frag Grenade"].CFrame,
	p250 = workspace.Map["Weapon Tables"].P250.CFrame,
	Remington = workspace.Map["Weapon Tables"].Remington.CFrame,
	ak47 = workspace.Map["Weapon Tables"].AK47.CFrame,
	spas12 = workspace.Map["Weapon Tables"]["Spas 12"].CFrame,
}

	ppas:AddButton({
		Text = "Tp to axe",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.Axe
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.axepp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to axe",
	})

	ppas:AddButton({
		Text = "Tp to deagle",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.Deagle
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.deaglepp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to deagle",
	})

	ppas:AddButton({
		Text = "Tp to flashbang",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.FlashBang
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.flashbangpp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to flashbang",
	})

	ppas:AddButton({
		Text = "Tp to frag grenade",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.Fraggrenade
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.fraggrenadepp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to frag grenade",
	})

	ppas:AddButton({
		Text = "Tp to p250",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.p250
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.p250pp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to p250",
	})

	ppas:AddButton({
		Text = "Tp to remington",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.Remington
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.remingtonpp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to remington",
	})

	ppas:AddButton({
		Text = "Tp to ak47",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.ak47
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.ak47pp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to ak47",
	})

	ppas:AddButton({
		Text = "Tp to spas 12",
		Func = function()
			local originalCFrame = nil
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				originalCFrame = plr.Character.HumanoidRootPart.CFrame
			end
			local plr = game:GetService("Players").LocalPlayer
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			hrp.CFrame = toolspos.spas12
			task.wait(0.1)
			-- Fire the proximity prompt
			fireproximityprompt(pps.spas12pp)
			task.wait(0.1)
			-- Teleport back to original position
			plr.Character.HumanoidRootPart.CFrame = originalCFrame
		end,
		DoubleClick = false,
		Tooltip = "Tp to spas 12",
	})


local ppss = Tabs.Proximity:AddRightGroupbox("PP")
	ppss:AddButton({
		Text = "Insta Proximity prompts",
		Func = function()
			-- Set all proximity prompts hold duration to 0
			for _, proximityPrompt in pairs(workspace:GetDescendants()) do
				if proximityPrompt:IsA("ProximityPrompt") then
					proximityPrompt.HoldDuration = 0
				end
			end
		end,
		DoubleClick = false,
		Tooltip = "make pp faster",
	})

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()

local CreditsBOX = Tabs.Credits:AddLeftGroupbox("Credits")

CreditsBOX:AddLabel("Made by Vexerzzz")

resume(create(function()
	RenderStepped:Connect(function()
		if Toggles.aim_Enabled.Value then
			if getClosestPlayer() then 
				local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
				local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
				-- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)

				mouse_box.Visible = IsOnScreen
				mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
			else 
				mouse_box.Visible = false 
				mouse_box.Position = Vector2.new()
			end
		end

		if Toggles.Visible.Value then 
			fov_circle.Visible = Toggles.Visible.Value
			fov_circle.Color = Options.Color.Value
			fov_circle.Position = getMousePosition()
		end
	end)
end))

-- hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
	local Method = getnamecallmethod()
	local Arguments = {...}
	local self = Arguments[1]
	local chance = CalculateChance(SilentAimSettings.HitChance)
	if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
		if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
			if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
				local A_Ray = Arguments[2]

				local HitPart = getClosestPlayer()
				if HitPart then
					local Origin = A_Ray.Origin
					local Direction = getDirection(Origin, HitPart.Position)
					Arguments[2] = Ray.new(Origin, Direction)

					return oldNamecall(unpack(Arguments))
				end
			end
		elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
			if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
				local A_Ray = Arguments[2]

				local HitPart = getClosestPlayer()
				if HitPart then
					local Origin = A_Ray.Origin
					local Direction = getDirection(Origin, HitPart.Position)
					Arguments[2] = Ray.new(Origin, Direction)

					return oldNamecall(unpack(Arguments))
				end
			end
		elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
			if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
				local A_Ray = Arguments[2]

				local HitPart = getClosestPlayer()
				if HitPart then
					local Origin = A_Ray.Origin
					local Direction = getDirection(Origin, HitPart.Position)
					Arguments[2] = Ray.new(Origin, Direction)

					return oldNamecall(unpack(Arguments))
				end
			end
		elseif Method == "Raycast" and Options.Method.Value == Method then
			if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
				local A_Origin = Arguments[2]

				local HitPart = getClosestPlayer()
				if HitPart then
					Arguments[3] = getDirection(A_Origin, HitPart.Position)

					return oldNamecall(unpack(Arguments))
				end
			end
		end
	end
	return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
	if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
		local HitPart = getClosestPlayer()

		if Index == "Target" or Index == "target" then 
			return HitPart
		elseif Index == "Hit" or Index == "hit" then 
			return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
		elseif Index == "X" or Index == "x" then 
			return self.X 
		elseif Index == "Y" or Index == "y" then 
			return self.Y 
		elseif Index == "UnitRay" then 
			return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
		end
	end

	return oldIndex(self, Index)
end))
