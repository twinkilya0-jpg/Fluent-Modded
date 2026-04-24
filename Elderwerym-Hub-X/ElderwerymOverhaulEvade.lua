local Fluent = loadstring(game:HttpGet("https://github.com/Vraigos/Fluent-Modded/releases/download/Test/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vraigos/Fluent-Modded/refs/heads/master/Addons/SaveManager.lua"))()
local FBM = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vraigos/Fluent-Modded/refs/heads/master/Addons/SaveFloatingButtonManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vraigos/Fluent-Modded/refs/heads/master/Addons/InterfaceManager.lua"))()

if not Fluent or not SaveManager or not InterfaceManager or not FBM then return game.Players.LocalPlayer:Kick("Error: Interface didn't load") end

if _G.ElderwyrmHubXIsAlreadyRunning then
   game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Script is already running!",
        Text = ""
    })
   return
end

_G.ElderwyrmHubXIsAlreadyRunning = true

local Window = Fluent:CreateWindow({
    Title = "Elderwyrm Hub X - Evade Overhaul",
    SubTitle = "V2.9.2 Made by Vraigos and Aerave",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Azure",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "rbxassetid://7733960981" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farms", Icon = "rbxassetid://10709811110" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "rbxassetid://10734975692" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "rbxassetid://7734068321" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "rbxassetid://10709819149" }),
    Info = Window:AddTab({ Title = "Info", Icon = "rbxassetid://10723415903" }),
    Settings = Window:AddTab({ Title = "Configuration", Icon = "rbxassetid://7734052335" }),
    Extension = Window:AddTab({ Title = "Extension", Icon = "rbxassetid://10734930886" })
}

local Options = Fluent.Options

-- Services

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService('Lighting')
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local CAS = game:GetService("ContextActionService")

-- Optimize (1)

local function GetAutoDuration()
    local dt = RunService.RenderStepped:Wait()
    local fps = 1 / dt

    local duration = 60 / math.clamp(fps, 5, 60)
    return math.clamp(duration, 1, 6)
end

local Duration = GetAutoDuration()

-- Toggle Gui
local openshit = Instance.new("ScreenGui")
openshit.Name = "openshit"
openshit.Parent = LocalPlayer.PlayerGui
openshit.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
openshit.ResetOnSpawn = false

local mainopen = Instance.new("TextButton")
mainopen.Name = "mainopen"
mainopen.Parent = openshit
mainopen.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainopen.BackgroundTransparency = 1
mainopen.Position = UDim2.new(0.101969875, 0, 0.110441767, 0)
mainopen.Size = UDim2.new(0, 64, 0, 42)
mainopen.Text = ""
mainopen.Visible = true

local mainopens = Instance.new("UICorner")
mainopens.Parent = mainopen

local SizeBackMulti = 0.1
local AssetsIcon = "rbxassetid://103822431806952"
local AssetsBackground = "rbxassetid://95198449172379"

-- === ROTATING BACKGROUND IMAGE (inside the button) ===
local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Name = "RotatingBackground"
backgroundImage.Parent = mainopen
backgroundImage.Size = UDim2.new(1.8 + SizeBackMulti, 0, 1.8 + SizeBackMulti, 0)
backgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
backgroundImage.AnchorPoint = Vector2.new(0.5, 0.5)
backgroundImage.BackgroundTransparency = 1
backgroundImage.Image = AssetsBackground
backgroundImage.SizeConstraint = Enum.SizeConstraint.RelativeXX
backgroundImage.ZIndex = 0

-- === STATIC FRONT IMAGE ===
local frontImage = Instance.new("ImageLabel")
frontImage.Name = "StaticIcon"
frontImage.Parent = mainopen
frontImage.Size = UDim2.new(0.8, 0, 1, 0)
frontImage.Position = UDim2.new(0.5, 0, 0.5, 0)
frontImage.AnchorPoint = Vector2.new(0.5, 0.5)
frontImage.BackgroundTransparency = 1
frontImage.Image = AssetsIcon
frontImage.ZIndex = 1

local frontCorner = Instance.new("UICorner")
frontCorner.CornerRadius = UDim.new(1, 0)
frontCorner.Parent = frontImage

-- === ROTATION LOOP ===
local rotation = 0
local speed = 90 
local lastTime = tick()

task.spawn(function()
	while true do
		local now = tick()
		local delta = now - lastTime
		lastTime = now
		
		rotation = (rotation + speed * delta) % 360
		backgroundImage.Rotation = rotation

		task.wait()
	end
end)

local function MakeDraggable(topbarobject, object, locked)
    local Dragging = false
    local DragInput
    local DragStart
    local StartPosition

    local Holding = false
    local HoldTime = 1.0
    local MoveCancelThreshold = 6
    local HoldToken = 0

    object:SetAttribute("Locked", locked or false)

    local function Update(input)
        if object:GetAttribute("Locked") then return end
        local delta = input.Position - DragStart
        object.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end

    local function ToggleLock()
        local newState = not object:GetAttribute("Locked")
        object:SetAttribute("Locked", newState)

        Fluent:Notify({
            Title = newState and "Button Locked" or "Button Unlocked",
            Content = newState and "This button is now locked in place." or "This button can now be moved.",
            Duration = 2
        })
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        Dragging = not object:GetAttribute("Locked")
        Holding = true
        DragStart = input.Position
        StartPosition = object.Position

        HoldToken += 1
        local token = HoldToken

        task.delay(HoldTime, function()
            if Holding and token == HoldToken then
                ToggleLock()
            end
        end)

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                Holding = false
            end
        end)
    end)

    topbarobject.InputChanged:Connect(function(input)
        if not DragStart then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            if (input.Position - DragStart).Magnitude > MoveCancelThreshold then
                Holding = false
            end
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

MakeDraggable(mainopen, mainopen, false)

local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

mainopen.MouseButton1Click:Connect(function()
    local sounds = { "7127123605", "137566474343039", "438666542" }
    playSound(sounds[math.random(#sounds)])
    Window:Minimize()

    local function smoothSpeed(target, duration)
        local start = speed
        local steps = 30
        for i = 1, steps do
            speed = start + (target - start) * (i / steps)
            task.wait(duration / steps)
        end
        speed = target
    end
    
    smoothSpeed(360, 0.4)
    task.wait(0.5)
    smoothSpeed(180, 0.4)
    task.wait(0.3)
    smoothSpeed(90, 0.4)
end)

-- FPS Counter

local Stats = game:GetService("Stats")

local fpsCounter = Instance.new("ScreenGui")
fpsCounter.Name = "FPSCounter"
fpsCounter.Parent = game.CoreGui
fpsCounter.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fpsCounter.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = fpsCounter
frame.Size = UDim2.new(0, 180, 0, 80)
frame.Position = UDim2.new(0, 300, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.BackgroundTransparency = 0.7

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 180, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
gradient.Parent = frame

task.spawn(function()
    while task.wait(0.03) do
        gradient.Rotation = (gradient.Rotation + 1) % 360
    end
end)

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(80, 180, 255)
uiStroke.Parent = frame

task.spawn(function()
    local a = Color3.fromRGB(80, 180, 255)
    local b = Color3.fromRGB(255, 255, 255)
    local t, d = 0, 1
    while task.wait(0.03) do
        t += 0.02 * d
        if t >= 1 then t, d = 1, -1 elseif t <= 0 then t, d = 0, 1 end
        uiStroke.Color = a:Lerp(b, t)
    end
end)

local label = Instance.new("TextLabel")
label.Parent = frame
label.Size = UDim2.new(1, -10, 1, -10)
label.Position = UDim2.new(0, 5, 0, 5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBlack
label.TextSize = 10
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.Text = "FPS: 0 | Ping: 0 ms\nClient Timer: 0h 0m 0s"

MakeDraggable(frame, frame, false)

local function GetPing()
    local n = Stats:FindFirstChild("Network")
    if not n then return 0 end
    local s = n:FindFirstChild("ServerStatsItem")
    if not s then return 0 end
    local p = s:FindFirstChild("Data Ping")
    if not p then return 0 end
    return math.floor(p:GetValue())
end

local startTime = tick()
local lastUpdateTime = startTime
local frameCount = 0
local previousText = ""

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    local dt = now - lastUpdateTime

    if dt >= 1 then
        local fps = math.round(frameCount / dt)
        local elapsed = now - startTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = math.floor(elapsed % 60)
        local ping = GetPing()

        local text = string.format(
            "FPS: %d | Ping: %d ms\nClient Timer: %dh %dm %ds",
            fps, ping, h, m, s
        )

        if text ~= previousText then
            label.Text = text
            previousText = text
        end

        lastUpdateTime = now
        frameCount = 0
    end
end)

-- UNC Requirements

if not require then
    return LocalPlayer:Kick("UNC RESTRICTION MISSING: require(path) | PLEASE TRY OTHER EXECUTORS")
else
   print("Supported require()")
end

if not firetouchinterest  then
    return LocalPlayer:Kick("UNC RESTRICTION MISSING: firetouchinterest() | PLEASE TRY OTHER EXECUTORS")
else
   print("Supported firetouchinterest()")
end

if game.Players then
   print("Advance Api")
else
   print("Common Api")
end

-- Announcement

-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Vraigos/Elderwyrm-Hub-X/refs/heads/main/Configurations/Announcement.lua"))()

-- Scripts

function CreateBillboardESP(Name, Part, Color, TextSize)
  if not Part or Part:FindFirstChild(Name) then return nil end

  local BillboardGui = Instance.new("BillboardGui")
  local TextLabel = Instance.new("TextLabel")
  local TextStroke = Instance.new("UIStroke")

  BillboardGui.Parent = Part
  BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  BillboardGui.Name = Name
  BillboardGui.AlwaysOnTop = true
  BillboardGui.LightInfluence = 1
  BillboardGui.Size = UDim2.new(0, 200, 0, 50)
  BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
  BillboardGui.MaxDistance = 1000

  TextLabel.Parent = BillboardGui
  TextLabel.BackgroundTransparency = 1
  TextLabel.Size = UDim2.new(1, 0, 1, 0)
  TextLabel.TextScaled = false
  TextLabel.Font = Enum.Font.SourceSans
  TextLabel.TextSize = TextSize or 14
  TextLabel.TextColor3 = Color or Color3.fromRGB(255, 255, 255)

  TextStroke.Parent = TextLabel
  TextStroke.Thickness = 1
  TextStroke.Color = Color3.new(0, 0, 0)

  return BillboardGui
end

function UpdateBillboardESP(Name, Part, NameText, Color, TextSize, PartPosition)
  if not Part then return false end

  local esp = Part:FindFirstChild(Name)
  if esp and esp:FindFirstChildOfClass("TextLabel") then
    local label = esp:FindFirstChildOfClass("TextLabel")
    
    if Color then
      label.TextColor3 = Color
    end
    
    if TextSize then
      label.TextSize = TextSize
    end
    
    if PartPosition then
      local Pos 
      if typeof(PartPosition) == "Instance" and PartPosition:IsA("BasePart") then
        Pos = PartPosition.Position
      elseif typeof(PartPosition) == "Vector3" then
        Pos = PartPosition
      end

      if Pos then
        local distance = math.floor((Pos - Part.Position).Magnitude)
        local name = NameText or Part.Parent and Part.Parent.Name or Part.Name
        label.Text = string.format("%s - [ %d M ]", name, distance)
      end
    else
      local name = NameText or Part.Parent and Part.Parent.Name or Part.Name
      label.Text = name
    end    
    return true
  end
  return false
end

function DestroyBillboardESP(Name, Part)
  if not Part then return false end
  
  local esp = Part:FindFirstChild(Name)
  if esp then
    esp:Destroy()
    return true
  end
  
  return false
end

function CreateTracerESP(tracerTable, part, thickness, color)
  local tracer = Drawing.new("Line")
  tracer.Thickness = thickness or 2
  tracer.Color = color or Color3.fromRGB(255, 255, 255)
  tracer.Transparency = 1
  tracer.Visible = false
  tracerTable[part] = tracer
  return tracer
end

function UpdateTracerESP(tracerTable, part, color)
  local tracer = tracerTable[part]
  if not tracer then return end

  if typeof(part) ~= "Instance" then
    tracerTable[part] = nil
    return
  end
  
  if not part.Parent or not part:IsDescendantOf(workspace) then
    tracer.Visible = false
    DestroyTracerESP(tracerTable, part)
    return
  end

  local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)  
  if onScreen then
    if color then tracer.Color = color end
    tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
    tracer.To = Vector2.new(screenPos.X, screenPos.Y)
    tracer.Visible = true
  else
    tracer.Visible = false
  end
end

function DestroyTracerESP(tracerTable, part)
  if typeof(part) ~= "Instance" then
    tracerTable[part] = nil
    return
  end
  
  local tracer = tracerTable[part]
  if tracer then 
    if tracer.Remove then tracer:Remove() end
    tracerTable[part] = nil
  end 
end

function CreateHighlightESP(Name, Part, HighlightColor, OutlineColor, ShowHighlight)
  if not Part then return false end

  local Highlight = Instance.new("Highlight")
  Highlight.Name = Name
  Highlight.FillColor = HighlightColor or Color3.fromRGB(255, 255, 255)
  Highlight.OutlineColor = OutlineColor or Color3.fromRGB(0, 0, 0)

  if ShowHighlight then
    Highlight.FillTransparency = 0
  else
    Highlight.FillTransparency = 1
  end

  Highlight.OutlineTransparency = 0
  Highlight.Parent = Part

  return true
end

function UpdateHighlightESP(Name, Part, HighlightColor, OutlineColor, ShowHighlight)
  local Highlight = Part and Part:FindFirstChild(Name)

  if not Highlight or not Highlight:IsA("Highlight") then return false end

  if HighlightColor then Highlight.FillColor = HighlightColor end
  if OutlineColor then Highlight.OutlineColor = OutlineColor end

  if ShowHighlight ~= nil then
    Highlight.FillTransparency = ShowHighlight and 0 or 0.5
  end

  return true
end

function DestroyHighlightESP(Name, Part)
  local Highlight = Part and Part:FindFirstChild(Name)

  if Highlight and Highlight:IsA("Highlight") then
    Highlight:Destroy()
    return true
  end

  return false
end

-- Local Variables
local DFunctions = {}
local DConfiguration = {
    ESP = {
        Players = false,
        Nextbots = false,
        Tickets = false,
        Objective = false,
    },

    Tracers = {
        Players = false,
        Nextbots = false,
        Tickets = false,
        Objective = false,
    },
    
    Highlight = {
        Players = false,
        Nextbots = false,
        Tickets = false,
        Objective = false,
        OutlineOnly = false,
    },

    Boxes = {
        Players = false,
        Nextbots = false,
        Tickets = false,
        Objective = false,
    },

    Removals = {
        CameraShake = false,
        Vignette = false,
        InvisibleWalls = false,
        ReducingRewards = false,
        DamageParts = false,
    },

    Main = {
        AntiAFK = true,
        AutoRespawn = false,
        RespawnType = "Spawnpoint",
        AutoWhistle = false,
        ShowTimer = false,
        Fly = false,
        FlySpeed = 20,
        Noclip = false,
    },
    
    Battlepass = {
	    BypassTimer = false,
    },

    AutoFarm = {
        FarmingStates = {
            IsReviving = false,
            IsCompletingObjective = false,
            IsCollectingTickets = false,
            IsCatchingNPC = false,
        },

        AFKFarm = false,
        FarmTickets = false,
        CompleteObjective = false,
        FarmTokens = false,
        
        PurchaseAutomations = {
            Enabled = false,
	        Selected = "Cola",	        
        },
        
        VIPAutomations = {
            AutoVote = false,
            MapSection = 1,
            GamemodeSection = 1,
	        AutoMap = false,
	        MapInput = "DesertBus",
	        AutoSpecialRound = false,
	        SpecialRoundInput = "Plushie Hell",
	        AutoTimer = false,
	        TimerInput = "",
	        AutoProMode = false,
        },
    },

    Combat = {
        AntiNextbot = false,
        AntiNextbotRange = 15,
        AntiNextbotType = "Spawn",
    },

    Misc = {
        PlayerAdjustment = {
            Default = {
                Speed = 1500,
                JumpHeight = 3,
                JumpCap = 1,
                JumpAcceleration = 1.5,
                AirStrafe = 182,
                GroundAcceleration = 5,
                BHOPEnabled = false,
            },

            Update = {
                Speed = 1500,
                JumpHeight = 3,
                JumpCap = 1,
                JumpAcceleration = 1.5,
                AirStrafe = 182,
                GroundAcceleration = 5,
                BHOPEnabled = false,
            },

            Saved = {
                Speed = 1500,
                JumpHeight = 3,
                JumpCap = 1,
                JumpAcceleration = 1.5,
                AirStrafe = 182,
                GroundAcceleration = 5,
            },

            Tick = {
                Speed = 0,
                JumpHeight = 0,
                JumpCap = 0,
                JumpAcceleration = 0,
                AirStrafe = 0,
                GroundAcceleration = 0,
                BHOPEnabled = 0,
            },

            Debounce = {
                Speed = false,
                JumpHeight = false,
                JumpCap = false,
                JumpAcceleration = false,
                AirStrafe = false,
                GroundAcceleration = false,
                BHOPEnabled = false,
            },
        },

        Humanoids = {
            WalkspeedCF = false,
            OriginalJumpHeight = false,
            CF = 5,
            JP = 20,
        },

        Utilities = {
            GetCurrentSpeed = 0,

            BounceModification = {
                Enabled = false,
                DefaultBounce = 80,
                EmoteBounce = 120,
                SuperBounce = false,
                SuperBounceStrength = -50,
            },
            
            EdgeTrimpModification = {
	            Enabled = false,
	            HeightMultiplier = 1.5,
	            DownThreshold = 4.5
            },

            LagSwitch = {
                MSDelay = 200,
                Mode = "Normal",
            },
        },

        CameraAdjustment = {
            StretchX = 1,
            StretchY = 1,
        },

        GunAdjustment = {
            v = nil,
        },

        GameAutomation = {
            Revive = {
                Enabled = false,
                FloatingButton = false,
                Keybind = false,
                WhileEmote = false,
                Delay = 0.1,
            },

            Carry = {
                Enabled = false,
                FloatingButton = false,
                Keybind = false,
                WhileEmote = false,
            },

            Macro = {
                SelectedEmote = "BoldMarch",
                FloatingButton = false,
                Keybind = false,
            },
        },

        MovementModification = {
            AggressiveEmoteDash = {
                Enabled = false,
                Type = "Blatant",
                Speed = 3000,
                Acceleration = -2,
            },

            SlideModification = {
                FloatingButton = false,
                Enabled = false,
                Acceleration = -3,
            },

            Gravity = {
                FloatingButton = false,
                Keybind = false,
                Value = 10,
            },
            
            BHOP = {
                Enabled = false,
                Keybind = false,
                HoldKeybind = false,
                FloatingButton = false,
                JumpButton = false,
                HipHeight1 = 0,
                HipHeight2 = 0,
                lastTick = 0.01,
                Settings = {
	                AutoAcceleration = {
		                Enabled = false,
		                MaxAccelerate = 3,
		                MinAccelerate = -1,
		                MinSpeed = 70
	                },
	                SpiderHop = false,
	                Backwards = false,
	                Type = "Acceleration",
	                JumpType = "Simulated",
	                Acceleration = -0.1,
                },
            },
            
            Crouch = {
	            FloatingButton = false,
	            Keybind = false,
	            Type = "Rapid",
	            isHolding = false,
	            debounce = 0.1,
	            lastTick = 0.1,
	            lastReleaseTick = 0.1,
            },
        },
    },
    
    Visual = {
        OriginalCosmetics = {
            Cosmetics1 = "",
            Cosmetics2 = "",
            Cosmetics3 = "",
            Cosmetics4 = "",
        },
        
        ModifyCosmetics = {
            Cosmetics1 = "",
            Cosmetics2 = "",
            Cosmetics3 = "",
            Cosmetics4 = "",
        },

        OriginalEmotes = {
            Emote1 = "",
            Emote2 = "",
            Emote3 = "",
            Emote4 = "",
            Emote5 = "",
            Emote6 = "",
            Emote7 = "",
            Emote8 = "",
            Emote9 = "",
            Emote10 = "",
            Emote11 = "",
            Emote12 = "",
        },

        ModifyEmotes = {
            Emote1 = "",
            Emote2 = "",
            Emote3 = "",
            Emote4 = "",
            Emote5 = "",
            Emote6 = "",
            Emote7 = "",
            Emote8 = "",
            Emote9 = "",
            Emote10 = "",
            Emote11 = "",
            Emote12 = "",
        },
    },

    Settings = {
        GuiScale = {
            Respawn = 0,
            SuperBounce = 0,
            AutoCarry = 0,
            InstantRevive = 0,
            AutoEmoteDash = 0,
            Gravity = 0,
            InfiniteSlide = 0,
            AutoJump = 0,
            AutoCrouch = 0,
            LagSwitch = 0,
        },
    },
}

-- Functions

function DFunctions.CreateButton(ButtonName, Name, Size1, Size2, ScriptLogic, CircleMode)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = ButtonName
    screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = ButtonName
    frame.Size = UDim2.new(Size1, 0, Size2, 0)
    frame.Position = UDim2.new(0.5 - Size1 / 2, 0, 0.5 - Size2 / 2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0.7
    frame.Parent = screenGui

    local gradient = Instance.new("UIGradient")
    gradient.Color = getgenv().ButtonGradients.Background
    gradient.Parent = frame

    task.spawn(function()
        while task.wait(0.03) do
            gradient.Rotation = (gradient.Rotation + 1) % 360
            gradient.Color = getgenv().ButtonGradients.Background
        end
    end)

	local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Parent = frame

    local gradientstroke = Instance.new("UIGradient")
    gradientstroke.Color = getgenv().ButtonGradients.Stroke
    
    gradientstroke.Rotation = 0
    gradientstroke.Parent = stroke

    task.spawn(function()
        while frame.Parent do
           gradientstroke.Rotation = (gradientstroke.Rotation + 0.5) % 360
           gradientstroke.Color = getgenv().ButtonGradients.Stroke
           task.wait()
        end
    end)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = Name
    button.Font = Enum.Font.SourceSansBold
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.TextScaled = false
    button.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 28, 0, 28)
    toggle.Position = UDim2.new(1, 6, 0.5, -14)
    toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggle.Text = "○"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Visible = false
    toggle.Parent = frame

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = toggle

    local originalSize = UDim2.new(Size1, 0, Size2, 0)
    local holding = false
    local holdStart = 0
    local hideAt = 0

    frame:SetAttribute("IsCircle", false)

    local isCircle
    if CircleMode ~= nil then
        isCircle = CircleMode
    else
        isCircle = frame:GetAttribute("IsCircle")
    end

    local function applyShape(circle)
        frame:SetAttribute("IsCircle", circle)
        local s = math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
        if circle then
            frame.Size = UDim2.new(0, s, 0, s)
            button.TextWrapped = true
            button.TextScaled = true
            button.TextSize = math.floor(s * 0.45)
            corner.CornerRadius = UDim.new(1, 0)
            toggle.Text = "▢"
        else
            frame.Size = originalSize
            button.TextWrapped = false
            button.TextScaled = false
            button.TextSize = 24
            corner.CornerRadius = UDim.new(0, 15)
            toggle.Text = "○"
        end
    end

    applyShape(isCircle)

    task.spawn(function()
        while task.wait(0.25) do
            if toggle.Visible and tick() - hideAt >= 10 then
                toggle.Visible = false
            end
        end
    end)

    button.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            holding = true
            holdStart = tick()
        end
    end)

    button.InputEnded:Connect(function(i)
        if holding and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            holding = false
            if tick() - holdStart >= 0.6 then
                toggle.Visible = true
                hideAt = tick()
            end
        end
    end)

    toggle.MouseButton1Click:Connect(function()
        hideAt = tick()
        local current = frame:GetAttribute("IsCircle")
        applyShape(not current)
    end)

    button.Activated:Connect(function()
        if ScriptLogic then
            ScriptLogic(button)
        end
    end)

    FBM:AddButton(ButtonName, frame, false)
    MakeDraggable(button, frame, false)

    return button
end

function DFunctions.UpdateButton(Name, Size1, Size2)
    local gui = LocalPlayer.PlayerGui:FindFirstChild(Name)
    if gui then
        local frame = gui:FindFirstChild(Name)
        if frame then
            frame.Size = UDim2.new(Size1, 0, Size2, 0)
            local isCircle = frame:GetAttribute("IsCircle")
            if isCircle then
                local s = math.min(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
                frame.Size = UDim2.new(0, s, 0, s)
            end
        end
    end
end

function DFunctions.DestroyButton(Name)
	local gui = LocalPlayer.PlayerGui:FindFirstChild(Name)
	if gui then
		gui:Destroy()
	end
end

-- Main logic

function DFunctions.AutoRespawn()
 	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
     local RespawnType = DConfiguration.Main.RespawnType
     
	 if Character and Character:GetAttribute("Downed") == true and RespawnType == "Spawnpoint" then
		 ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
     elseif Character and Character:GetAttribute("Downed") == true and RespawnType == "Fake Revive" then
	     local PreviousPosition
	     PreviousPosition = LocalPlayer.Character.HumanoidRootPart.Position
    	 wait(0.2)
	     ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
	     wait(1)
	     LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(PreviousPosition)
	 end
end

function DFunctions.RemoveDamagePart()
   local Map = Workspace.Game.Map
   
   for i, v in pairs(Map:GetDescendants()) do
     if v:IsA("BasePart") and v.CanTouch == true then
          v.CanTouch = false
       end
   end
end

function DFunctions.DisableTouch(t)
	for i, v in next, t:GetChildren() do
		if v.IsA(v, 'BasePart') then
			v.CanTouch = false
		end
	end
end

function DFunctions.CreateTimer()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false
    screenGui.Name = "TimerGui"

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Parent = screenGui
    timerLabel.Size = UDim2.new(0, 200, 0, 50)
    timerLabel.Position = UDim2.new(0.5, -100, 0.1, 0) 
    timerLabel.BackgroundTransparency = 1 
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSans
    timerLabel.TextColor3 = Color3.new(1, 1, 1) 
end

function DFunctions.RemoveTimer()
   if LocalPlayer.PlayerGui:FindFirstChild("TimerGui") then
       LocalPlayer.PlayerGui.TimerGui:Destroy()
    end
end

function DFunctions.RemoveReduceRewards()
    for i, v in pairs(Workspace.Game.Map.SafeZones:GetDescendants()) do
       if v:IsA("BasePart") then
          v:Destroy()
       end
    end
end

function DFunctions.DisableInvisParts(state)
    for i, v in pairs(Workspace.Game.Map.InvisParts:GetChildren()) do
       if v:IsA("BasePart") then
          v.CanCollide = state
       end
    end
end

function DFunctions.DisableCameraShake()
    local FOVAdjusters = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Camera") and LocalPlayer.PlayerScripts.Camera:FindFirstChild("FOVAdjusters")
    local CameraSet = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Camera") and LocalPlayer.PlayerScripts.Camera:FindFirstChild("Set")

    if FOVAdjusters and CameraSet then
       FOVAdjusters:SetAttribute("Fear", 1)
       CameraSet:Invoke("CFrameOffset", "Shake", CFrame.new())
    end
end

function DFunctions.DisableVignette()
	local HUD = LocalPlayer:FindFirstChild("Shared") and LocalPlayer.Shared:FindFirstChild("HUD")
	local NextbotNoise = HUD and HUD:FindFirstChild("NextbotNoise")
	
	if HUD and NextbotNoise then
	   NextbotNoise.ImageTransparency = 1
	   local Noise = NextbotNoise:FindFirstChild("Noise")
	   local Noise2 = NextbotNoise:FindFirstChild("Noise2")
	   
	   if Noise then
	       Noise.ImageTransparency = 1
	   elseif Noise2 then
	       Noise2.ImageTransparency = 1
	   end
	end
end

-- Auto farm logiv

function DFunctions.GetDownedPlayer()
    for i,v in pairs(Workspace.Game.Players:GetChildren()) do
        if v:GetAttribute("Downed") then
            return v
        end
    end
end

function DFunctions.GetEventNPC()
    for i,v in pairs(Workspace.Game.Players:GetChildren()) do
        if v.Name == "Lupen" and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
end

function DFunctions.TPEventNPC()
    local npc = DFunctions.GetEventNPC()
    
    DConfiguration.AutoFarm.FarmingStates.IsCatchingNPC = false
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHrp = npc:FindFirstChild("HumanoidRootPart") 
        local targetHum = npc:FindFirstChild("Humanoid") 

        if hrp and targetHrp then
            hrp.CFrame = CFrame.new(targetHrp.Position + targetHum.MoveDirection)
            DConfiguration.AutoFarm.FarmingStates.IsCatchingNPC = true
        end
    end
end

function DFunctions.GetObjective()
    local ObjectiveFolder = Workspace.Game.Map.Parts:FindFirstChild("Objectives")
    if not ObjectiveFolder then return nil end

    local Parts = {}

    for _, v in ipairs(ObjectiveFolder:GetChildren()) do
        if v:IsA("Model") then
            local part = v:FindFirstChildWhichIsA("BasePart")
            if part then
                table.insert(Parts, part)
            end
        end
    end

    if #Parts == 0 then
        return nil
    end

    return Parts[math.random(1, #Parts)]
end

local FarmPart

function DFunctions.AFKFarming()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not FarmPart then
        FarmPart = Instance.new("Part")
        FarmPart.Size = Vector3.new(10, 1, 10)
        FarmPart.Anchored = true
        FarmPart.CanCollide = true
        FarmPart.Name = "AFKFarmPad"
        FarmPart.CFrame = CFrame.new(0, hrp.Position.Y + 10000, 0)
        FarmPart.Parent = workspace
    end

    hrp.CFrame = FarmPart.CFrame + Vector3.new(0, 3, 0)
end

function DFunctions.RevivePlayer()
    local downedplr = DFunctions.GetDownedPlayer()
    
    DConfiguration.AutoFarm.FarmingStates.IsReviving = false
    if downedplr and downedplr:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHrp = downedplr:FindFirstChild("HumanoidRootPart")

        if hrp and targetHrp then
            hrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 2, 0))

            local Interact = ReplicatedStorage.Events.Character.Interact
            Interact:FireServer("Revive", true, tostring(downedplr))
            Interact:FireServer("Revive", true, tostring(downedplr))
            Interact:FireServer("Revive", true, tostring(downedplr))
            DConfiguration.AutoFarm.FarmingStates.IsReviving = true
        end
    end
    
    if not DConfiguration.AutoFarm.FarmingStates.IsReviving then
        DFunctions.AFKFarming()
    end 
end

function DFunctions.PointFarming()
    local Objective = DFunctions.GetObjective()
    
    DConfiguration.AutoFarm.FarmingStates.IsCompletingObjective = false
    if Objective then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if hrp then
            hrp.CFrame = CFrame.new(Objective.Position)
            LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({Down = true, Key = "Interact"})
            DConfiguration.AutoFarm.FarmingStates.IsCompletingObjective = true
        end
    end
end

function DFunctions.TicketsFarming()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    DConfiguration.AutoFarm.FarmingStates.IsCollectingTickets = false

    for _, v in ipairs(Workspace.Game.Effects.Tickets:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "HumanoidRootPart" then
            hrp.CFrame = CFrame.new(v.Position)
            DConfiguration.AutoFarm.FarmingStates.IsCollectingTickets = true
            return
        end
    end
    
    DFunctions.AFKFarming()
end

function DFunctions.AutoVote(section1, section2)
	if section1 then
	    ReplicatedStorage.Events.Player.Vote:FireServer(section1)
	end
	
	if section2 then
	    ReplicatedStorage.Events.Player.Vote:FireServer(section1, true)
	end
end

function DFunctions.SetVIPCommands(map, specialround, timer)
    local VIPCommand = ReplicatedStorage.Events.Admin.VIPCommand

    if typeof(map) == "string" and map ~= "" then
        VIPCommand:InvokeServer("!map " .. map)
    end

    if typeof(specialround) == "string" and specialround ~= "" then
        VIPCommand:InvokeServer("!specialround " .. specialround)
    end
    
    if typeof(timer) == "string" and specialround ~= "" then
        VIPCommand:InvokeServer("!timer " .. timer)
    end
end

function DFunctions.BuyItem(Name, Type)
	local Purchase = ReplicatedStorage.Events.Data.Purchase
	local Folder = ReplicatedStorage.Items[Type][Name]
	local ID = Folder:GetAttribute("ID")
	
	Purchase:InvokeServer(ID)
end

local EmoteNames = {}
local LoadoutNames = {}

function DFunctions.GetEmotesName()
    EmoteNames = {}
    local emotesFolder = game:GetService("ReplicatedStorage").Items.Emotes

    for _, thing in ipairs(emotesFolder:GetChildren()) do
        if thing:IsA("LocalScript") or thing:IsA("ModuleScript") then
            EmoteNames[#EmoteNames + 1] = thing.Name 
        end
        if _ % 50 == 0 then
            task.wait(3)
        end
    end

    return EmoteNames
end

function DFunctions.GetLoadoutName()
    LoadoutNames = {}
    local loadoutFolder = game:GetService("ReplicatedStorage").Items.Loadout

    for _, thing in ipairs(loadoutFolder:GetChildren()) do
        if thing:IsA("LocalScript") or thing:IsA("ModuleScript") then
            LoadoutNames[#LoadoutNames + 1] = thing.Name 
        end
        if _ % 50 == 0 then
            task.wait(3)
        end
    end

    return LoadoutNames
end

DFunctions.GetEmotesName()
DFunctions.GetLoadoutName()

-- Combat logic

function DFunctions.AntiNextbot()
    if Workspace:FindFirstChild("Game") and game.Workspace.Game:FindFirstChild("Players") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    
        local playerTeam = Workspace.Game.Players[LocalPlayer.Name]:GetAttribute("Team")
        if playerTeam == "Nextbot" then
            return 
        end
    
        for i, v in pairs(Workspace.Game.Players:GetDescendants()) do
            if v:IsA("Model") and v:GetAttribute("Team") == "Nextbot" then
                local humanoidRootPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("HRP")
                if humanoidRootPart then
                    if not LocalPlayer.Character and not LocalPlayer.Character.HumanoidRootPart then 
                        return
                    end
                    
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                    
                    if distance < DConfiguration.Combat.AntiNextbotRange then
                        if DConfiguration.Combat.AntiNextbotType == "Spawn" then
                            local parts = workspace.Game.Map.ItemSpawns:GetChildren()
                            local randomPart = parts[math.random(1, #parts)]
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(randomPart.Position)
                        elseif DConfiguration.Combat.AntiNextbotType == "Players" then
                            local randomPlayer = Players:GetPlayers()[math.random(1, #game.Players:GetPlayers())]
                            if randomPlayer then
                              LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(randomPlayer.Character.Head.Position.X, randomPlayer.Character.Head.Position.Y, randomPlayer.Character.Head.Position.Z)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Misc logic

local CurrentAdjustment = {}

function DFunctions.GetAdjustments()
	table.clear(CurrentAdjustment)
	local character = LocalPlayer.Character
	if not character then
		return
	end

	for _, v in pairs(getgc(true)) do
		if type(v) == "table" then
			local char = rawget(v, "Character")
			local stats = rawget(v, "overrideMovementStats")
			local stats2 = rawget(v, "defaultMovementStats")

			if typeof(char) == "Instance" and char == character then
				if type(stats) == "table" then
					table.insert(CurrentAdjustment, stats)
				end
				if type(stats2) == "table" then
					table.insert(CurrentAdjustment, stats2)
				end
			end
		end
	end
end

function DFunctions.setTSpeed(newSpeed)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.Speed ~= newSpeed and now - DConfiguration.Misc.PlayerAdjustment.Tick.Speed >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.Speed = newSpeed
        DConfiguration.Misc.PlayerAdjustment.Tick.Speed = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "Speed") then
                rawset(stats, "Speed", newSpeed)
            end
        end
    end
end

function DFunctions.setTJump(newJump)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.JumpHeight ~= newJump and now - DConfiguration.Misc.PlayerAdjustment.Tick.JumpHeight >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.JumpHeight = newJump
        DConfiguration.Misc.PlayerAdjustment.Tick.JumpHeight = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "JumpHeight") then
                rawset(stats, "JumpHeight", newJump)
            end
        end
    end
end

function DFunctions.setTJumpCap(newJumpCap)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.JumpCap ~= newJumpCap and now - DConfiguration.Misc.PlayerAdjustment.Tick.JumpCap >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.JumpCap = newJumpCap
        DConfiguration.Misc.PlayerAdjustment.Tick.JumpCap = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "JumpCap") then
                rawset(stats, "JumpCap", newJumpCap)
            end
        end
    end
end

function DFunctions.setTJumpAcceleration(newJumpAcce)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.JumpAcceleration ~= newJumpAcce and now - DConfiguration.Misc.PlayerAdjustment.Tick.JumpAcceleration >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.JumpAcceleration = newJumpAcce
        DConfiguration.Misc.PlayerAdjustment.Tick.JumpAcceleration = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "JumpSpeedMultiplier") then
                rawset(stats, "JumpSpeedMultiplier", newJumpAcce)
            end
        end
    end
end

function DFunctions.setTFriction(newFriction)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.GroundAcceleration ~= newFriction and now - DConfiguration.Misc.PlayerAdjustment.Tick.GroundAcceleration >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.GroundAcceleration = newFriction
        DConfiguration.Misc.PlayerAdjustment.Tick.GroundAcceleration = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "Friction") then
                rawset(stats, "Friction", newFriction)
            end
        end
    end
end

function DFunctions.setBhopEnabled(bool)  
    for i = 1, #CurrentAdjustment do  
        local stats = CurrentAdjustment[i]  
        if rawget(stats, "BhopEnabled") ~= nil then  
            stats.BhopEnabled = bool
        end  
    end  
end  

function DFunctions.setStrafeAcceleration(newAcceleration)
    local now = tick()
    if DConfiguration.Misc.PlayerAdjustment.Default.AirStrafe ~= newAcceleration and now - DConfiguration.Misc.PlayerAdjustment.Tick.AirStrafe >= 0.1 then
        DConfiguration.Misc.PlayerAdjustment.Default.AirStrafe = newAcceleration
        DConfiguration.Misc.PlayerAdjustment.Tick.AirStrafe = now

        for i = 1, #CurrentAdjustment do
            local stats = CurrentAdjustment[i]
            if rawget(stats, "AirStrafeAcceleration") then
                rawset(stats, "AirStrafeAcceleration", newAcceleration)
            end
            if rawget(stats, "AirAcceleration") then
                rawset(stats, "AirAcceleration", 3)
            end
        end
    end
end

function DFunctions.SetPreviousAdjustment()
    for i = 1, #CurrentAdjustment do
        local stats = CurrentAdjustment[i]

        if rawget(stats, "Speed") then
            rawset(stats, "Speed", DConfiguration.Misc.PlayerAdjustment.Default.Speed)
        end
        if rawget(stats, "JumpHeight") then
            rawset(stats, "JumpHeight", DConfiguration.Misc.PlayerAdjustment.Default.JumpHeight)
        end
        if rawget(stats, "JumpCap") then
            rawset(stats, "JumpCap", DConfiguration.Misc.PlayerAdjustment.Default.JumpCap)
        end
        if rawget(stats, "JumpSpeedMultiplier") then
            rawset(stats, "JumpSpeedMultiplier", DConfiguration.Misc.PlayerAdjustment.Default.JumpAcceleration)
        end
        if rawget(stats, "AirStrafeAcceleration") then
            rawset(stats, "AirStrafeAcceleration", DConfiguration.Misc.PlayerAdjustment.Default.AirStrafe)
        end
        if rawget(stats, "AirAcceleration") then
            rawset(stats, "AirAcceleration", 3)
        end
    end
end

function DFunctions.GetSpeedometer()
    local shared = LocalPlayer.PlayerGui:WaitForChild("Shared", 9e9)
    if not shared then return end
    local speedometer = shared.HUD.Overlay.Default.CharacterInfo.Item:WaitForChild("Speedometer", 9e9)
    if not speedometer then return end
    local player = speedometer.Players
    
    return player
end

function DFunctions.BounceFunction()
    local speedometer = DFunctions.GetSpeedometer()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char and char:FindFirstChild("Humanoid")

    if speedometer then
        DConfiguration.Misc.Utilities.GetCurrentSpeed = tonumber(speedometer.Text)
    end

    if not DConfiguration.Misc.Utilities.BounceModification.Enabled and humanoid then
        humanoid.WalkSpeed = 0
        return
    end
     
    if char and humanoid then
        if char:GetAttribute("State") == "Default" or char:GetAttribute("State") == "Downed" or not DConfiguration.Misc.Utilities.BounceModification.Enabled then
            humanoid.WalkSpeed = 0
        elseif char:GetAttribute("State") == "Emoting" or char:GetAttribute("State") == "EmotingAir" or char:GetAttribute("State") == "EmotingSlide" or char:GetAttribute("State") == "EmotingSlideAir" then
            humanoid.WalkSpeed = DConfiguration.Misc.Utilities.BounceModification.EmoteBounce + DConfiguration.Misc.Utilities.GetCurrentSpeed
        elseif DConfiguration.Misc.Utilities.GetCurrentSpeed < 15 or char:GetAttribute("State") == "Default" then
            humanoid.WalkSpeed = 0
        else
            humanoid.WalkSpeed = DConfiguration.Misc.Utilities.BounceModification.DefaultBounce + DConfiguration.Misc.Utilities.GetCurrentSpeed
        end
    end
end

function DFunctions.SuperBounce()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    local Humanoid = char:FindFirstChild("Humanoid")
    local PreviousHipHeight = 0
    
    if char:FindFirstChild("R15Visual") then
        PreviousHipHeight = 0.75
    else
	    PreviousHipHeight = -1.25
    end
   
    if not HumanoidRootPart or not Humanoid then return end
    
    HumanoidRootPart.CanCollide = false
    Humanoid.HipHeight = -100
    wait(2)
    HumanoidRootPart.CanCollide = true
    Humanoid.HipHeight = PreviousHipHeight
end

local CachedRayParams = RaycastParams.new()
CachedRayParams.FilterType = Enum.RaycastFilterType.Exclude

function DFunctions.StartLag(ms)
	local LagTime = ms * 0.002
	local LagType = DConfiguration.Misc.Utilities.LagSwitch.Mode
	local Character = LocalPlayer.Character
	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return end

	local StoredVelocity = HumanoidRootPart.AssemblyLinearVelocity
	if StoredVelocity.Magnitude < 1 then return end

	local start = tick()
	while tick() - start < LagTime do end
	
	if LagType == "FastFlag" or LagTime < 0.2 then
	   setfflag("MaxMissedWorldStepsRemembered", "9999")
	   return
	end
	
	if LagType ~= "Demon" or LagTime < 0.2 then return end
	
	CachedRayParams.FilterDescendantsInstances = {Character}

	local Multiplier = math.random(2, 10)
	local HorizontalVelocity = Vector3.new(StoredVelocity.X, 0, StoredVelocity.Z)
	local direction = HorizontalVelocity.Magnitude > 0 and HorizontalVelocity.Unit or HumanoidRootPart.CFrame.LookVector
	local distance = math.min(HorizontalVelocity.Magnitude * LagTime * Multiplier, 30)
	local forwardPos = HumanoidRootPart.Position + direction * distance
	local targetPos = forwardPos

	local forwardResult = workspace:Raycast(HumanoidRootPart.Position, forwardPos - HumanoidRootPart.Position, CachedRayParams)
	if forwardResult then
		targetPos = forwardResult.Position - direction * 2
	end

	local function detectSlope(dir, dist)
		return workspace:Raycast(HumanoidRootPart.Position + dir * dist, Vector3.new(0, -60, 0), CachedRayParams)
	end

	local LongSlopeCheck = detectSlope(direction, 50)
	local ShortSlopeCheck = nil

	for i = 2, 20, 2 do
		local result = detectSlope(direction, i)
		if result then
			ShortSlopeCheck = result
			break
		end
	end

	local SlopeLengthBoost, shortSlopeBoost = 1, 1
	local SlopeDirBoost = 1
	local HoverBuffer = 0
	local SlopeAngle = 0
	local EarlyBounce = false

	if LongSlopeCheck then
		local normal = LongSlopeCheck.Normal
		SlopeAngle = math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0))))
		if SlopeAngle >= 20 and SlopeAngle <= 80 then
			SlopeLengthBoost = math.clamp(SlopeAngle / 25, 1, 2.2)
			SlopeDirBoost = math.clamp(SlopeAngle / 40, 1, 2)
			HoverBuffer = math.clamp((SlopeAngle - 20) * 0.06, 0, 3)
			if SlopeAngle < 35 then
				targetPos = targetPos + Vector3.new(0, 3, 0) + direction * (2 * SlopeDirBoost)
			else
				targetPos = targetPos + Vector3.new(0, SlopeAngle * 0.3 + HoverBuffer, 0)
			end
		end
	end

	if ShortSlopeCheck then
		local normal = ShortSlopeCheck.Normal
		SlopeAngle = math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0))))
		if SlopeAngle >= 20 and SlopeAngle <= 80 then
			ShortSlopeBoost = math.clamp(SlopeAngle / 22, 1, 2.5)
			SlopeDirBoost = SlopeDirBoost + math.clamp(SlopeAngle / 50, 0, 1.6)
			HoverBuffer = HoverBuffer + math.clamp((SlopeAngle - 20) * 0.05, 0, 3)
			local verticalDist = HumanoidRootPart.Position.Y - ShortSlopeCheck.Position.Y
			local minForward = 4
			local minUp = 4
			if SlopeAngle >= 50 and verticalDist < 3 then
				earlyBounce = true
				targetPos = targetPos + direction * minForward + Vector3.new(0, minUp, 0)
			else
				if SlopeAngle < 35 then
					targetPos = targetPos + Vector3.new(0, 3, 0) + direction * (2 * SlopeDirBoost)
				else
					targetPos = targetPos + Vector3.new(0, SlopeAngle * 0.4 + HoverBuffer, 0)
				end
			end
		end
	end

	if SlopeAngle >= 35 then
		targetPos = targetPos + direction * (5 * SlopeDirBoost)
	end

	local safetyCheck = workspace:Raycast(HumanoidRootPart.Position, targetPos - HumanoidRootPart.Position, CachedRayParams)
	if safetyCheck then
		targetPos = safetyCheck.Position + Vector3.new(0, 2, 0) - direction * 2
	end

	if ShortSlopeCheck or LongSlopeCheck then
		local hitPos = (ShortSlopeCheck or LongSlopeCheck).Position
		local verticalDist = HumanoidRootPart.Position.Y - hitPos.Y
		if verticalDist < 2 then
			targetPos = HumanoidRootPart.Position + direction * 2 + Vector3.new(0, 2, 0)
		end
	end

	HumanoidRootPart.CFrame = CFrame.new(targetPos, targetPos + HumanoidRootPart.CFrame.LookVector)

	local Delta = targetPos - HumanoidRootPart.Position
	local Speed = StoredVelocity.Magnitude
	local forwardBoost = math.clamp(Speed * 0.4, 5, 20)
	local safeDir = Delta.Magnitude > 0 and Delta.Unit or direction
	local safeCheck = workspace:Raycast(HumanoidRootPart.Position, safeDir * forwardBoost, CachedRayParams)

	if not safeCheck then
		HumanoidRootPart.AssemblyLinearVelocity += safeDir * forwardBoost
	else
		local safeDist = (safeCheck.Position - HumanoidRootPart.Position).Magnitude
		if safeDist > 3 then
			HumanoidRootPart.AssemblyLinearVelocity += safeDir * (safeDist * 0.6)
		end
	end

	local bounceMultiplier = 1.2
	if SlopeAngle >= 45 then
		local angleBoost = math.clamp((SlopeAngle - 45) / 20, 0, 1.5)
		bounceMultiplier = 1.2 + angleBoost
	end

	if StoredVelocity.Y < -60 then
		bounceMultiplier *= 0.9 * SlopeLengthBoost * ShortSlopeBoost
	elseif StoredVelocity.Y < -30 then
		bounceMultiplier *= 1.0 * SlopeLengthBoost * ShortSlopeBoost
	end

	if StoredVelocity.Y < -10 then
		local angleFactor = math.clamp((SlopeAngle - 20) / 40, 0, 1)
		local bounceY = math.abs(StoredVelocity.Y) * (1.1 + angleFactor * 0.9)
		bounceY = bounceY + StoredVelocity.Magnitude * (0.3 + angleFactor * 0.5)
		bounceY = math.clamp(bounceY * bounceMultiplier * 1.0, 0, 60 + StoredVelocity.Magnitude * 0.4)

		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
			StoredVelocity.X * SlopeDirBoost,
			bounceY,
			StoredVelocity.Z * SlopeDirBoost
		)

		if earlyBounce then
			local forwardBoost = math.clamp(5 + StoredVelocity.Magnitude * 0.1, 6, 20)
			local forwardCheck = workspace:Raycast(HumanoidRootPart.Position, direction * forwardBoost, CachedRayParams)
			if not forwardCheck then
				hrp.CFrame = HumanoidRootPart.CFrame + direction * forwardBoost
			else
				local safeDist = (forwardCheck.Position - HumanoidRootPart.Position).Magnitude
				if safeDist > 3 then
					HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + direction * (safeDist * 0.5)
				end
			end
		end
	end
	
	HumanoidRootPart.Size = Vector3.new(3, 25, 3)
	wait(0.1)
	HumanoidRootPart.Size = Vector3.new(2, 4, 2)
end

local EdgeParams = RaycastParams.new()
EdgeParams.FilterType = Enum.RaycastFilterType.Blacklist
EdgeParams.FilterDescendantsInstances = {}

function DFunctions.ModifyEdgeTrimp()
    local Character = LocalPlayer.Character
    if not Character then return end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Root or not Humanoid then return end

    local Velocity = Root.AssemblyLinearVelocity
    local HorizontalVel = Vector3.new(Velocity.X, 0, Velocity.Z)
    local Speed = HorizontalVel.Magnitude
    if Speed < 22 then return end

    local MoveDir = HorizontalVel.Unit
    local LookDir = Root.CFrame.LookVector.Unit

    EdgeParams.FilterDescendantsInstances = {Character}

    local PredictTime = math.clamp(Speed / 110, 0.14, 0.24)
    local EarlyOffset = 2.5

    local FutureMovePos = Root.Position + HorizontalVel * PredictTime + MoveDir * EarlyOffset
    local FutureLookPos = Root.Position + HorizontalVel * PredictTime + LookDir * EarlyOffset

    if Velocity.Y > 5 then return end

    local validEdge = false
    local minRaysForTrigger = 2
    local maxSlope = 0.8
    local minHeightDiff = 1.5

    local fanOffsets = {
        Vector3.new(0,0,0),
        Vector3.new(0.25,0,0.25),
        Vector3.new(-0.25,0,-0.25),
        Vector3.new(0.25,0,-0.25),
        Vector3.new(-0.25,0,0.25)
    }

    local moveHits = 0
    local lookHits = 0

    for _, offset in ipairs(fanOffsets) do
        local startMove = FutureMovePos + offset
        local forwardHitMove = workspace:Raycast(startMove + Vector3.new(0,2,0), MoveDir * 3.5, EdgeParams)

        if forwardHitMove and forwardHitMove.Normal.Y < 0.2 then
            local topCheckMove = workspace:Raycast(
                forwardHitMove.Position + Vector3.new(0,2.2,0),
                Vector3.new(0,-5,0),
                EdgeParams
            )

            if topCheckMove and topCheckMove.Normal.Y >= maxSlope then
                if topCheckMove.Position.Y - Root.Position.Y > minHeightDiff then
                    moveHits += 1
                end
            end
        end

        local startLook = FutureLookPos + offset
        local forwardHitLook = workspace:Raycast(startLook + Vector3.new(0,2,0), LookDir * 3.5, EdgeParams)

        if forwardHitLook and forwardHitLook.Normal.Y < 0.2 then
            local topCheckLook = workspace:Raycast(
                forwardHitLook.Position + Vector3.new(0,2.2,0),
                Vector3.new(0,-5,0),
                EdgeParams
            )

            if topCheckLook and topCheckLook.Normal.Y >= maxSlope then
                if topCheckLook.Position.Y - Root.Position.Y > minHeightDiff then
                    lookHits += 1
                end
            end
        end
    end

    if moveHits >= 1 and lookHits >= 1 then
        validEdge = true
    end

    local downVotes = 0
    local earlyForward = MoveDir * 2
    local dropThreshold = DConfiguration.Misc.Utilities.EdgeTrimpModification.DownThreshold
    local halfDepth = Root.Size.Z / 2
    local forwardDistances = {
	    halfDepth + 0.1,
	    halfDepth + 0.4,
	    halfDepth + 0.7,
	    halfDepth + 1
    }

    for _, offset in ipairs(fanOffsets) do
        local startPos = FutureMovePos + offset + earlyForward

        local downHit = workspace:Raycast(
            startPos + Vector3.new(0,2,0),
            Vector3.new(0,-6,0),
            EdgeParams
        )

        if downHit then
            local drop = Root.Position.Y - downHit.Position.Y

            local edgeFound = false

            for _, dist in ipairs(forwardDistances) do
                local check = workspace:Raycast(
                    Root.Position + MoveDir * dist,
                    Vector3.new(0,-6,0),
                    EdgeParams
                )

                if not check then
                    edgeFound = true
                    break
                end
            end

            if drop >= dropThreshold and edgeFound then
                downVotes += 1
            end
        end
    end

    if downVotes >= minRaysForTrigger then
        validEdge = true
    end

    if not validEdge then return end

    Root.AssemblyLinearVelocity =
        HorizontalVel * 1.05 +
        Vector3.new(0, math.clamp(Speed * 0.7, 22, 85), 0) *
        DConfiguration.Misc.Utilities.EdgeTrimpModification.HeightMultiplier
end

local WorkspacePlayers = game:GetService("Workspace").Game.Players

function DFunctions.getNearestDownedPlayer()
    local nearestPlayer = nil
    local nearestDistance = 10
    local HumanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return nil end

    for _, v in pairs(WorkspacePlayers:GetChildren()) do
        local targetRoot = v:FindFirstChild("HumanoidRootPart")
        if v:GetAttribute("Downed") and targetRoot and not targetRoot.Anchored then
            local distance = (HumanoidRootPart.Position - targetRoot.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = v
            end
        end
    end

    return nearestPlayer
end

function DFunctions.InstantRevive()
    local nearestPlayer = DFunctions.getNearestDownedPlayer()
    if not nearestPlayer then return end

    local State = LocalPlayer.Character:GetAttribute("State")
    local AllowWhileEmote = DConfiguration.Misc.GameAutomation.Revive.WhileEmote or (State == "Run" or State == "Air" or State == "Slide" or State == "Fall" or State == "Jump" or State == "Crouch")

    if AllowWhileEmote then
        for i = 1, 7 do
            ReplicatedStorage.Events.Character.Interact:FireServer("Revive", nil, tostring(nearestPlayer))
            ReplicatedStorage.Events.Character.Interact:FireServer("Revive", false, tostring(nearestPlayer))
            ReplicatedStorage.Events.Character.Interact:FireServer("Revive", true, tostring(nearestPlayer))
        end
    end
end

function DFunctions.CarryPlayer()
    local nearestPlayer = DFunctions.getNearestDownedPlayer()
    if not nearestPlayer then return end

    local State = LocalPlayer.Character:GetAttribute("State")
    local AllowWhileEmote = DConfiguration.Misc.GameAutomation.Revive.WhileEmote or (State == "Run" or State == "Air" or State == "Slide" or State == "Fall" or State == "Jump" or State == "Crouch")

    if AllowWhileEmote then
        for i = 1, 7 do
            ReplicatedStorage.Events.Character.Interact:FireServer("Carry", nil, tostring(nearestPlayer))
            ReplicatedStorage.Events.Character.Interact:FireServer("Carry", false, tostring(nearestPlayer))
            ReplicatedStorage.Events.Character.Interact:FireServer("Carry", true, tostring(nearestPlayer))
        end
    end
end

function DFunctions.AggressiveEmoteDashFunction()
	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local Type = DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Type
	
	if Type == "Legit" and (Character and Character:GetAttribute("State") == "EmotingSlide") then
	    DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Acceleration
    else
        if DConfiguration.Misc.MovementModification.BHOP.Enabled then return end
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.PlayerAdjustment.Default.GroundAcceleration
	end
	
	if Type == "Blatant" and (Character and Character:GetAttribute("State") == "Emoting" or Character:GetAttribute("State") == "EmotingAir" or Character:GetAttribute("State") == "EmotingSlide" or Character:GetAttribute("State") == "EmotingSlideAir") then
		DConfiguration.Misc.PlayerAdjustment.Update.Speed = DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Speed
	else
	    DConfiguration.Misc.PlayerAdjustment.Update.Speed = DConfiguration.Misc.PlayerAdjustment.Saved.Speed
	end
end

function DFunctions.SetToMovableEmote(EmoteName, Speed)
	local EmoteFolder = ReplicatedStorage.Items.Emotes
	local EmoteInfo = require(EmoteFolder[EmoteName]).EmoteInfo
	EmoteInfo.SpeedMult = Speed
end

function DFunctions.InfiniteSlideFunction()
	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	
	if Character and Character:GetAttribute("State") == "Slide" or Character:GetAttribute("State") == "EmotingSlide" then
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = DConfiguration.Misc.MovementModification.SlideModification.Acceleration
	else
		DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
	end
end

function DFunctions.BHOPFunction()
    local speedometer = DFunctions.GetSpeedometer()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoidrootpart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local BHOPConfig = DConfiguration.Misc.MovementModification.BHOP
    local Settings = BHOPConfig.Settings
    local debounce
    
    if not Character then return end
    if not Humanoidrootpart then return end
    if not Humanoid then return end
    
    if BHOPConfig.Settings.SpiderHop and Character and Character:GetAttribute("State") == "Wallrunning" then
        LocalPlayer.PlayerScripts.Events.temporary_events.EndJump:Fire()
        LocalPlayer.PlayerScripts.Events.temporary_events.JumpReact:Fire()
    end
    
    if Settings.Type == "Acceleration" then
        if tonumber(speedometer.Text) > 60 then
            if Character:FindFirstChild("R15Visual") then
                BHOPConfig.HipHeight2 = 1
            else
                BHOPConfig.HipHeight2 = -1.05
            end
        else
            if Character:FindFirstChild("R15Visual") then
                BHOPConfig.HipHeight2 = 0.9
            else
                BHOPConfig.HipHeight2 = -1.10
            end
        end
        
        debounce = 0.01
        Humanoid.HipHeight = BHOPConfig.HipHeight2
    elseif Settings.Type == "Ground Acceleration" then
        if Character:FindFirstChild("R15Visual") then
           BHOPConfig.HipHeight2 = 0.5
        else
           BHOPConfig.HipHeight2 = -2
        end
        
        Humanoid.HipHeight = BHOPConfig.HipHeight2
        debounce = 0.01      
    elseif Settings.Type == "No Acceleration" then
        debounce = 0.125
    end
    
    local CanBHOPBackwards = true
    
    if Settings.AutoAcceleration.Enabled then
        local Speed = tonumber(speedometer.Text)
        local MaxAccel = Settings.AutoAcceleration.MaxAccelerate
        local MinAccel = Settings.AutoAcceleration.MinAccelerate
        if MinAccel > MaxAccel then
            MinAccel, MaxAccel = MaxAccel, MinAccel
        end
        local MinSpeed = Settings.AutoAcceleration.MinSpeed
        local Threshold = math.clamp(Speed, 25, 50)
        local Devisor = math.clamp(Speed / Threshold, 0, 6) 
        local Decrease = math.clamp(5 - (Devisor * 1.7), MinAccel, MaxAccel)
        
        if Settings.Type == "No Acceleration" then
           return
        end
        
        if Speed < MinSpeed then
            DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = MinAccel
            CanBHOPBackwards = true
        else 
            DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = Decrease
            CanBHOPBackwards = false
        end
    else
        if Settings.Type == "No Acceleration" then
           return
        end
        
        DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = Settings.Acceleration
    end
    
    local now = tick()
    local lastGrounded = 0

    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        lastGrounded = now
    end

    local grounded = (now - lastGrounded) < 0.06
    
    if Settings.JumpType == "Simulated" then
        if grounded and (now - BHOPConfig.lastTick) > debounce then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            BHOPConfig.lastTick = now
        end
    elseif Settings.JumpType == "Realistic" then
        if grounded and (now - BHOPConfig.lastTick) > debounce then
            LocalPlayer.PlayerScripts.Events.temporary_events.EndJump:Fire()
            LocalPlayer.PlayerScripts.Events.temporary_events.JumpReact:Fire()
            BHOPConfig.lastTick = now
        end
    end
    
    if BHOPConfig.Settings.Backwards then
	    local LookVector = Humanoidrootpart.CFrame.LookVector
        local Velocity = Humanoidrootpart.AssemblyLinearVelocity
        local MoveDir = Humanoid.MoveDirection

        local HorizontalVelocity = Vector3.new(Velocity.X, 0, Velocity.Z)
        local Speed = HorizontalVelocity.Magnitude
        
        local VelocityBackwards = false
        local InputBackwards = false

        if Speed > 1 then
            VelocityBackwards = (LookVector:Dot(HorizontalVelocity.Unit) < -0.3)
        end

        if MoveDir.Magnitude > 0 then
            InputBackwards = (LookVector:Dot(MoveDir) < -0.3)
        end

        if VelocityBackwards or InputBackwards then
            DFunctions.setBhopEnabled(CanBHOPBackwards)
            RunService.Heartbeat:Wait()
            DFunctions.setBhopEnabled(false)
        end
    end
end

function DFunctions.ResetBHOP()
   local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
   local Humanoid = Character:FindFirstChildOfClass("Humanoid")
   local BHOPConfig = DConfiguration.Misc.MovementModification.BHOP
   
   if Character:FindFirstChild("R15Visual") then
       BHOPConfig.HipHeight1 = 0.75
       BHOPConfig.HipHeight2 = 0.9
   else
       BHOPConfig.HipHeight1 = -1.25
       BHOPConfig.HipHeight2 = -1.10
   end
           
   if Humanoid then
       Humanoid.HipHeight = BHOPConfig.HipHeight1
       DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
       wait(0.3)
       DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
       DFunctions.setBhopEnabled(false)
    end
end

function DFunctions.CrouchFunction()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not Character then return end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HumanoidRootPart then return end

    local Config = DConfiguration.Misc.MovementModification.Crouch
    local Type = Config.Type or "Normal"

    Config.isHolding = Config.isHolding or false
    Config.lastTick = Config.lastTick or 0
    Config.lastReleaseTick = Config.lastReleaseTick or 0

    local now = tick()

    local function tapCrouch()
        if not Config.isHolding and (now - Config.lastTick) >= Config.debounce then
            LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({
                Key = "Crouch",
                Down = true
            })
            Config.isHolding = true
            Config.lastTick = now
        elseif Config.isHolding and (now - Config.lastTick) >= Config.debounce then
            LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({
                Key = "Crouch",
                Down = false
            })
            Config.isHolding = false
            Config.lastReleaseTick = now
        end
    end

    local isOnGround = Humanoid.FloorMaterial ~= Enum.Material.Air
    local VelocityY = HumanoidRootPart.Velocity.Y

    if Type == "Rapid" then
        tapCrouch()
    elseif Type == "Ground" then
        if isOnGround or VelocityY < -1 then
            tapCrouch()
        end
    elseif Type == "Air" then
        if not isOnGround then
            tapCrouch()
        end
    elseif Type == "Normal" then
        if isOnGround or VelocityY < -1 then
            tapCrouch()
        end
    end
end

local Folder = Instance.new("Folder", ReplicatedStorage.Items)
Folder.Name = "D-Folder"

function DFunctions.Normalize(input)
	return input:lower():gsub("%s+", "") 
end

function DFunctions.FindRealName(folder, userInput)
	local normalizedInput = DFunctions.Normalize(userInput)
	for _, item in ipairs(folder:GetChildren()) do
		if DFunctions.Normalize(item.Name) == normalizedInput then
			return item.Name
		end
	end
	return nil
end

function DFunctions.ChangeCosmetics(Name1, Name2)
	local Cosmetics = ReplicatedStorage.Items.Cosmetics
	local RealName1 = DFunctions.FindRealName(Cosmetics, Name1)
	local RealName2 = DFunctions.FindRealName(Cosmetics, Name2)
	if not (RealName1 and RealName2) then return end

	local I = Cosmetics:FindFirstChild(RealName1)
	local V = Cosmetics:FindFirstChild(RealName2)
	if not (I and V) then return end

	if I:FindFirstChild("OriginalName") or V:FindFirstChild("OriginalName") then
		return
	end

	local s1 = Instance.new("StringValue")
	s1.Name = "OriginalName"
	s1.Value = I.Name
	s1.Parent = I

	local s2 = Instance.new("StringValue")
	s2.Name = "OriginalName"
	s2.Value = V.Name
	s2.Parent = V

	for _, partName in ipairs({ "Character", "CharacterClassic", "Viewmodel" }) do
		local a = I:FindFirstChild(partName)
		local b = V:FindFirstChild(partName)

		if a and not a:FindFirstChild("OriginalParent") then
			local p = Instance.new("StringValue")
			p.Name = "OriginalParent"
			p.Value = I.Name
			p.Parent = a
		end

		if b and not b:FindFirstChild("OriginalParent") then
			local p = Instance.new("StringValue")
			p.Name = "OriginalParent"
			p.Value = V.Name
			p.Parent = b
		end

		if a then a.Parent = Folder end
		if b then b.Parent = I end
		if a then a.Parent = V end
	end
end

function DFunctions.RestoreCosmetics()
	local Cosmetics = ReplicatedStorage.Items.Cosmetics

	for _, cosmetic in ipairs(Cosmetics:GetChildren()) do
		for _, container in ipairs(cosmetic:GetChildren()) do
			local op = container:FindFirstChild("OriginalParent")
			if op then
				local original = Cosmetics:FindFirstChild(op.Value)
				if original then
					container.Parent = original
				end
				op:Destroy()
			end
		end
	end

	for _, container in ipairs(Folder:GetChildren()) do
		local op = container:FindFirstChild("OriginalParent")
		if op then
			local original = Cosmetics:FindFirstChild(op.Value)
			if original then
				container.Parent = original
			end
			op:Destroy()
		end
	end

	for _, cosmetic in ipairs(Cosmetics:GetChildren()) do
		local sv = cosmetic:FindFirstChild("OriginalName")
		if sv then
			sv:Destroy()
		end
	end
end

local SelectedVersion = "A"
local IsCurrentPlaying = false

function DFunctions.ChangeAnimation(EmoteFolder, Version)
	if not EmoteFolder then return end

	local options = EmoteFolder:FindFirstChild("PossibleOptions")
	local optionsClassic = EmoteFolder:FindFirstChild("PossibleOptionsClassic")
	if not options and not optionsClassic then return end

	local chosenR15 = options and options:FindFirstChild(Version)
	local chosenR6  = optionsClassic and optionsClassic:FindFirstChild(Version)

	local animR15 = chosenR15 and chosenR15:FindFirstChildWhichIsA("Animation")
	local animR6  = chosenR6 and chosenR6:FindFirstChildWhichIsA("Animation")

	if animR15 and EmoteFolder:FindFirstChild("Animation") then
		local tag = Instance.new("StringValue")
		tag.Name = "OriginalAnimId"
		tag.Value = EmoteFolder.Animation.AnimationId
		tag.Parent = EmoteFolder
		EmoteFolder.Animation.AnimationId = animR15.AnimationId
	end

	if animR6 and EmoteFolder:FindFirstChild("AnimationClassic") then
		local tag = Instance.new("StringValue")
		tag.Name = "OriginalAnimIdClassic"
		tag.Value = EmoteFolder.AnimationClassic.AnimationId
		tag.Parent = EmoteFolder
		EmoteFolder.AnimationClassic.AnimationId = animR6.AnimationId
	end
end

function DFunctions.ChangeEmotes(Name1, Name2)
	local EmotesFolder = ReplicatedStorage.Items.Emotes
	if not EmotesFolder then return end

	local RealName1 = DFunctions.FindRealName(EmotesFolder, Name1)
	local RealName2 = DFunctions.FindRealName(EmotesFolder, Name2)
	if not RealName1 or not RealName2 then return end
	if not IsCurrentPlaying then return end

	local Emote1 = EmotesFolder:FindFirstChild(RealName1)
	local Emote2 = EmotesFolder:FindFirstChild(RealName2)
	if not Emote1 or not Emote2 then return end

	if not Emote1:FindFirstChild("OriginalName") then
		local t = Instance.new("StringValue")
		t.Name = "OriginalName"
		t.Value = Emote1.Name
		t.Parent = Emote1
	end

	if not Emote2:FindFirstChild("OriginalName") then
		local t = Instance.new("StringValue")
		t.Name = "OriginalName"
		t.Value = Emote2.Name
		t.Parent = Emote2
	end

	if not Emote1:FindFirstChild("OriginalParent") then
		local t = Instance.new("StringValue")
		t.Name = "OriginalParent"
		t.Value = Emote1.Parent:GetFullName()
		t.Parent = Emote1
	end

	if not Emote2:FindFirstChild("OriginalParent") then
		local t = Instance.new("StringValue")
		t.Name = "OriginalParent"
		t.Value = Emote2.Parent:GetFullName()
		t.Parent = Emote2
	end

	local hasOptions = Emote2:FindFirstChild("PossibleOptions")
	local hasOptionsClassic = Emote2:FindFirstChild("PossibleOptionsClassic")

	if not hasOptions and not hasOptionsClassic or hasOptions:FindFirstChild("Sun") and hasOptions:FindFirstChild("Moon") then
		local n1, n2 = Emote1.Name, Emote2.Name
		Emote1.Name = n2
		Emote2.Name = n1
		return
	end

	local function MoveModule(obj, parentName)
		if obj and not obj:FindFirstChild("OriginalParent") then
			local t = Instance.new("StringValue")
			t.Name = "OriginalParent"
			t.Value = parentName
			t.Parent = obj
			obj.Parent = Folder
		end
	end

	MoveModule(Emote2:FindFirstChild("EmoteModule"), Emote2.Name)
	MoveModule(Emote2:FindFirstChild("EmoteModuleClassic"), Emote2.Name)

	if Emote1.Parent ~= Folder then
		Emote1.Parent = Folder
	end

	Emote2.Name = Emote1:FindFirstChild("OriginalName").Value

	DFunctions.ChangeAnimation(Emote2, SelectedVersion)
end

function DFunctions.ResetEmoteChanges()
	local Emotes = ReplicatedStorage.Items.Emotes

	for _, emote in ipairs(Emotes:GetChildren()) do
		local originalTag = emote:FindFirstChild("OriginalName")
		if originalTag then
			if emote.Name ~= originalTag.Value then
				emote.Name = originalTag.Value
			end
			originalTag:Destroy()
		end
	end

	for _, emote in ipairs(Folder:GetChildren()) do
		local ptag = emote:FindFirstChild("OriginalParent")
		if ptag then
			local parent = ReplicatedStorage.Items:FindFirstChild(ptag.Value)
			if parent then
				emote.Parent = parent
			else
				emote.Parent = Emotes
			end
			ptag:Destroy()
		end
	end
	
	for _, obj in ipairs(Folder:GetChildren()) do
		if obj:IsA("ModuleScript") then
			local originalParentTag = obj:FindFirstChild("OriginalParent")
			if originalParentTag then
				local parentEmote = Emotes:FindFirstChild(originalParentTag.Value)
				if parentEmote then
					obj.Parent = parentEmote
				else
					obj.Parent = Emotes
				end
				originalParentTag:Destroy()
			end
		end
	end
end

function DFunctions.RestoreEmoteChanges()
    DFunctions.ResetEmoteChanges() 
    wait(0.1)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote1, DConfiguration.Visual.ModifyEmotes.Emote1)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote2, DConfiguration.Visual.ModifyEmotes.Emote2)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote3, DConfiguration.Visual.ModifyEmotes.Emote3)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote4, DConfiguration.Visual.ModifyEmotes.Emote4)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote5, DConfiguration.Visual.ModifyEmotes.Emote5)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote6, DConfiguration.Visual.ModifyEmotes.Emote6)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote7, DConfiguration.Visual.ModifyEmotes.Emote7)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote8, DConfiguration.Visual.ModifyEmotes.Emote8)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote9, DConfiguration.Visual.ModifyEmotes.Emote9)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote10, DConfiguration.Visual.ModifyEmotes.Emote10)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote11, DConfiguration.Visual.ModifyEmotes.Emote11)
    DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote12, DConfiguration.Visual.ModifyEmotes.Emote12)
end

-- Main
local GamePlayers = workspace:WaitForChild("Game"):WaitForChild("Players")

Tabs.Main:AddSection("Billboard ESP")

local Toggle = Tabs.Main:AddToggle("BillboardNextbots", {Title = "Billboard Nextbots", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.ESP.Nextbots = value
   
    while DConfiguration.ESP.Nextbots and wait(0.1) do
        for _, v in pairs(GamePlayers:GetChildren()) do
            if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
                local ESPName = "NextbotESP"
                local hrp
                
                if v:FindFirstChild("Hitbox") then
                   hrp = v.Hitbox
                elseif v:FindFirstChild("Base") then
                   hrp = v.Base
                elseif v:FindFirstChild("Head") then
                   hrp = v.Head
                else
                   hrp = v:FindFirstChildWhichIsA("Part")
                end
                
                if hrp and not hrp:FindFirstChild(ESPName) then
                   CreateBillboardESP(ESPName, hrp, Color3.fromRGB(255, 255, 255), 18)
                end
                
                if hrp then
	                UpdateBillboardESP(ESPName, hrp, v.Name, Color3.fromRGB(255, 0, 0), 18, Camera.CFrame.Position)
                end
            end
        end
    end
    
    if not DConfiguration.ESP.Nextbots then
	    for _, v in pairs(GamePlayers:GetDescendants()) do
            if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
                local hrp 
                
                if v:FindFirstChild("Hitbox") then
                   hrp = v.Hitbox
                elseif v:FindFirstChild("Base") then
                   hrp = v.Base
                elseif v:FindFirstChild("Head") then
                   hrp = v.Head
                else
                   hrp = v:FindFirstChildWhichIsA("Part")
                end
                
                if not hrp then return end
                
                DestroyBillboardESP("NextbotESP", hrp)
            end
        end
    end
end)

local Toggle = Tabs.Main:AddToggle("BillboardPlayers", {Title = "Billboard Players", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.ESP.Players = value
   
    while DConfiguration.ESP.Players and wait(0.1) do
	    for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			    local ESPName = "PlayerESP"
				local PlayerChar = v.Character
				
                if PlayerChar then
					if not PlayerChar.HumanoidRootPart:FindFirstChild(ESPName) then
					   CreateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, Color3.fromRGB(255, 255, 255), 14)
					end
				
					local PlayerStats = GamePlayers:FindFirstChild(v.Name)
					if PlayerStats and PlayerStats:GetAttribute("Downed") == true then
						UpdateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, v.Name, Color3.fromRGB(0, 255, 0), 14, Camera.CFrame.Position)
					else
						UpdateBillboardESP(ESPName, PlayerChar.HumanoidRootPart, v.Name, Color3.fromRGB(255, 255, 255), 14, Camera.CFrame.Position)
					end
				end
			end
		end
    end

   if not DConfiguration.ESP.Players then
	   for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				DestroyBillboardESP("PlayerESP", v.Character.HumanoidRootPart)
		 	end
		 end
     end
end)

local Toggle = Tabs.Main:AddToggle("BillboardTicket", {Title = "Billboard Tickets", Default = false })

    Toggle:OnChanged(function(State)
        DConfiguration.ESP.Tickets = State
        
        while DConfiguration.ESP.Tickets and wait(0.1) do
	        for _, v in pairs(Workspace.Game.Effects.Tickets:GetDescendants()) do
		        if v:IsA("BasePart") and v.Name == "HumanoidRootPart" then 
		            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()	
		            local ESPName = "TicketESP"
		            
		            if not char then
		               return
		            end
		            
		            if not v:FindFirstChild(ESPName) then
		               CreateBillboardESP(ESPName, v, Color3.fromRGB(255, 213, 128), 18)
		            end
		            
		            UpdateBillboardESP(ESPName, v, v.Parent.Name, Color3.fromRGB(255, 213, 128), 18, Camera.CFrame.Position)
		        end
	        end
        end
        
    if not DConfiguration.ESP.Tickets then
       for _, v in pairs(Workspace.Game.Effects.Tickets:GetDescendants()) do
      	 if v:IsA("BasePart") and v.Name == "HumanoidRootPart" then 
               DestroyBillboardESP("TicketESP", v)
             end
	  	end
  	end
 end)
 
Tabs.Main:AddSection("Tracer ESP")
 
local TracerLinesBots = {}
local TracerLines = {}
local TracerLinesTickets = {}

local Toggle = Tabs.Main:AddToggle("TracersPlayers", {
    Title = "Tracer Players",
    Default = false
})

Toggle:OnChanged(function(State)
    DConfiguration.Tracers.Players = State

    if not DConfiguration.Tracers.Players then
        for part, _ in pairs(TracerLines) do
            if typeof(part) == "Instance" then
                DestroyTracerESP(TracerLines, part)
            else
                TracerLines[part] = nil
            end
        end
        TracerLines = {}
        return
    end

    task.spawn(function()
        while DConfiguration.Tracers.Players and task.wait() do
            if not DConfiguration.Tracers.Players then break end
            pcall(function()
                local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localHRP then return end

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not TracerLines[hrp] then
                                CreateTracerESP(TracerLines, hrp, 2, Color3.fromRGB(255, 255, 255))
                            end

                            local color = Color3.fromRGB(255, 255, 255)
                            local gamePlayer = workspace:FindFirstChild("Game") and workspace.Game.Players:FindFirstChild(player.Name)
                            if gamePlayer and gamePlayer:GetAttribute("Downed") then
                                color = Color3.fromRGB(0, 255, 0)
                            end

                            UpdateTracerESP(TracerLines, hrp, color)
                        end
                    end
                end

                for part, tracer in pairs(TracerLines) do
                    if typeof(part) ~= "Instance" or not part.Parent then
                        DestroyTracerESP(TracerLines, part)
                    elseif tracer and tracer.Visible and not part:IsDescendantOf(workspace) then
                        tracer.Visible = false
                        DestroyTracerESP(TracerLines, part)
                    end
                end
            end)
        end
    end)
end)

local Toggle = Tabs.Main:AddToggle("TracersBots", {
    Title = "Tracer Bots",
    Default = false
})

Toggle:OnChanged(function(State)
    DConfiguration.Tracers.Nextbots = State

    if not DConfiguration.Tracers.Nextbots then
        for part, _ in pairs(TracerLinesBots) do
            if typeof(part) == "Instance" then
                DestroyTracerESP(TracerLinesBots, part)
            else
                TracerLinesBots[part] = nil
            end
        end
        TracerLinesBots = {}
        return
    end

    task.spawn(function()
        while DConfiguration.Tracers.Nextbots and task.wait() do
            if not DConfiguration.Tracers.Nextbots then break end
            pcall(function()
                local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localHRP then return end

                local gamePlayers = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                if not gamePlayers then return end

                for _, bot in pairs(gamePlayers:GetChildren()) do
                    local hrp = bot:FindFirstChild("HumanoidRootPart")
                    if hrp and not Players:FindFirstChild(bot.Name) then
                        if not TracerLinesBots[hrp] then
                            CreateTracerESP(TracerLinesBots, hrp, 5, Color3.fromRGB(255, 0, 0))
                        end
                        UpdateTracerESP(TracerLinesBots, hrp, Color3.fromRGB(255, 0, 0))
                    end
                end

                for part, tracer in pairs(TracerLinesBots) do
                    if typeof(part) ~= "Instance" or not part.Parent then
                        DestroyTracerESP(TracerLinesBots, part)
                    elseif tracer and tracer.Visible and not part:IsDescendantOf(workspace) then
                        tracer.Visible = false
                        DestroyTracerESP(TracerLinesBots, part)
                    end
                end
            end)
        end
    end)
end)

local Toggle = Tabs.Main:AddToggle("TracerTickets", {
    Title = "Tracer Tickets",
    Default = false
})

Toggle:OnChanged(function(State)
    DConfiguration.Tracers.Tickets = State

    if not DConfiguration.Tracers.Tickets then
        for part, _ in pairs(TracerLinesTickets) do
            if typeof(part) == "Instance" then
                DestroyTracerESP(TracerLinesTickets, part)
            else
                TracerLinesTickets[part] = nil
            end
        end
        TracerLinesTickets = {}
        return
    end

    task.spawn(function()
        while DConfiguration.Tracers.Tickets and task.wait() do
            if not DConfiguration.Tracers.Tickets then break end
            pcall(function()
                local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localHRP then return end

                local ticketsFolder = workspace:FindFirstChild("Game") and workspace.Game.Effects:FindFirstChild("Tickets")
                if not ticketsFolder then return end

                for _, v in pairs(ticketsFolder:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name == "HumanoidRootPart" then
                        if not TracerLinesTickets[v] then
                            CreateTracerESP(TracerLinesTickets, v, 2, Color3.fromRGB(255, 213, 128))
                        end
                        UpdateTracerESP(TracerLinesTickets, v, Color3.fromRGB(255, 213, 128))
                    end
                end

                for part, tracer in pairs(TracerLinesTickets) do
                    if typeof(part) ~= "Instance" or not part.Parent then
                        DestroyTracerESP(TracerLinesTickets, part)
                    elseif tracer and tracer.Visible and not part:IsDescendantOf(workspace) then
                        tracer.Visible = false
                        DestroyTracerESP(TracerLinesTickets, part)
                    end
                end
            end)
        end
    end)
end)

Tabs.Main:AddSection("Highlight ESP")

local Toggle = Tabs.Main:AddToggle("HighlightNextbot", {Title = "Highlight Nextbots", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.Highlight.Nextbots = value
   
    while DConfiguration.Highlight.Nextbots and wait(0.1) do
        for _, v in pairs(GamePlayers:GetChildren()) do
            if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
                local ESPName = "NextbotHighlight"
                local hrp = v:FindFirstChild("Hitbox")
                
                if v and not v:FindFirstChild(ESPName) then
                   CreateHighlightESP(ESPName, v, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0), DConfiguration.Highlight.OutlineOnly)
                end
                
                if v then
	                UpdateHighlightESP(ESPName, v, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0), DConfiguration.Highlight.OutlineOnly)
	                if hrp then
		                hrp.Transparency = 0.1
	                end
                end
            end
        end
    end
    
    if not DConfiguration.Highlight.Nextbots then
	    for _, v in pairs(GamePlayers:GetDescendants()) do
            if not Players:FindFirstChild(v.Name) and v:FindFirstChild("HumanoidRootPart") then
                local hrp = v:FindFirstChild("Hitbox")
                
                if not hrp then return end
                
                if hrp then
	                hrp.Transparency = 1
                end
                DestroyHighlightESP("NextbotHighlight", v)
            end
        end
    end
end)

local Toggle = Tabs.Main:AddToggle("HighlightPlayers", {Title = "Highlight Players", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.Highlight.Players = value
   
    while DConfiguration.Highlight.Players and wait(0.1) do
	    for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			    local ESPName = "PlayerHighlight_D"
				local PlayerChar = v.Character
				
                if PlayerChar then
					if not PlayerChar:FindFirstChild(ESPName) then
					   CreateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					end
				
					local PlayerStats = GamePlayers:FindFirstChild(v.Name)
					if PlayerStats and PlayerStats:GetAttribute("Downed") == true then
						UpdateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					else
						UpdateHighlightESP(ESPName, PlayerChar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), DConfiguration.Highlight.OutlineOnly)
					end
				end
			end
		end
    end

   if not DConfiguration.Highlight.Players then
	   for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				DestroyHighlightESP("PlayerHighlight_D", v.Character)
		 	end
		 end
     end
end)

local Toggle = Tabs.Main:AddToggle("HighlightTicket", {Title = "Highlight Tickets", Default = false })

    Toggle:OnChanged(function(State)
        DConfiguration.Highlight.Tickets = State
        
        if DConfiguration.Highlight.Tickets then
        	CreateHighlightESP("HighlightTicket_D", Workspace.Game.Effects.Tickets, Color3.fromRGB(255, 213, 128), Color3.fromRGB(255, 213, 128), DConfiguration.Highlight.OutlineOnly)
        else
            DestroyHighlightESP("HighlightTicket_D", Workspace.Game.Effects.Tickets)
        end
 end)

Tabs.Main:AddSection("Game Modification")
    
local Toggle = Tabs.Main:AddToggle("AutoRespawn", {Title = "Auto Respawn", Default = false })

    Toggle:OnChanged(function(value)
       DConfiguration.Main.AutoRespawn = value
        
       while DConfiguration.Main.AutoRespawn and wait(0.1) do
          spawn(DFunctions.AutoRespawn)
	 end
end)

local Toggle = Tabs.Main:AddToggle("RespawnButton", {Title = "Respawn (Button)", Default = false})

Toggle:OnChanged(function(State)
    if State then
          DFunctions.CreateButton("RespawnButton", "Respawn", 0.15 + DConfiguration.Settings.GuiScale.Respawn, 0.1 + DConfiguration.Settings.GuiScale.Respawn, function(btn)
         	btn.Text = "Respawning..."
             spawn(DFunctions.AutoRespawn)
             wait(0.1)
             btn.Text = "Respawned!"
             wait(0.2)
             btn.Text = "Respawn"
          end)
     else
         DFunctions.DestroyButton("RespawnButton")
     end
end)

Tabs.Main:AddInput("RespawnButtonSize", {
    Title = "Respawn Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.Respawn),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.Respawn = num * 0.01
        else
            DConfiguration.Settings.GuiScale.Respawn = 0
        end
        
        DFunctions.UpdateButton("RespawnButton", 0.15 + DConfiguration.Settings.GuiScale.Respawn, 0.1 + DConfiguration.Settings.GuiScale.Respawn)
    end
})

Tabs.Main:AddButton({
    Title = "Force Respawn",
    Description = "",
    Callback = function()
        ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
    end
})

local Dropdown = Tabs.Main:AddDropdown("RespawnType", {
        Title = "Respawn Type",
        Values = {"Spawnpoint", "Fake Revive"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(value)
        DConfiguration.Main.RespawnType = value
    end)
    
Tabs.Main:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Main:AddToggle("AutoWhistle", {Title = "Auto Whistle", Default = false })

    Toggle:OnChanged(function(value)
        DConfiguration.Main.AutoWhistle = value
        
      while task.wait(1) and DConfiguration.Main.AutoWhistle do
	   	 ReplicatedStorage.Events.Character.Whistle:FireServer()
		end
    end)

Tabs.Main:AddSection("Alternative Settings")
    
local Toggle = Tabs.Main:AddToggle("AntiAfk", {Title = "Anti-AFK", Default = false })

    Toggle:OnChanged(function()
    local vu = game:GetService("VirtualUser")
    
    repeat wait() until game:IsLoaded() 
	   LocalPlayer.Idled:connect(function()
       game:GetService("VirtualUser"):ClickButton2(Vector2.new())
	  	vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	  	wait(1)
		  vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
     end)
 end)
 
 Options.AntiAfk:SetValue(true)
 
 local Toggle = Tabs.Main:AddToggle("ShowTimer", {Title = "Show Timer", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.Main.ShowTimer = State

    if DConfiguration.Main.ShowTimer then
        if not LocalPlayer.PlayerGui:FindFirstChild("TimerGui") then
            DFunctions.CreateTimer()
        end
    else
        DFunctions.RemoveTimer()
    end

    while DConfiguration.Main.ShowTimer and wait(0.1) do
        if LocalPlayer.PlayerGui:FindFirstChild("TimerGui") then
            local seconds = workspace.Game.Stats:GetAttribute("Timer")
            local minutes = math.floor(seconds / 60)
            local remainingSeconds = seconds % 60

            LocalPlayer.PlayerGui.TimerGui.TextLabel.Text = string.format("%d:%02d", minutes, remainingSeconds)
        end
    end
end)
 
 local Toggle = Tabs.Main:AddToggle("DisableCameraShake", {Title = "Disable Camera Shake", Default = false })

local CameraShakeConnection 

Toggle:OnChanged(function(value)
    DConfiguration.Removals.CameraShake = value

    if CameraShakeConnection then
        CameraShakeConnection:Disconnect()
        CameraShakeConnection = nil
    end

    if value then
        CameraShakeConnection = RunService.RenderStepped:Connect(function()
            DFunctions.DisableCameraShake()
        end)
    end
end)

local Toggle = Tabs.Main:AddToggle("DisableVignette", {Title = "Disable Vignette", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.Removals.Vignette = value

    while DConfiguration.Removals.Vignette and wait(0.1) do
       spawn(DFunctions.DisableVignette)
    end
end)

local LeaderboardModule
local LeaderboardMenu

Tabs.Main:AddButton({
        Title = "Open Leaderboard",
        Description = "",
        Callback = function()
	       if not LeaderboardModule and not LeaderboardMenu then
	           LeaderboardModule = require(ReplicatedStorage.Modules.Client.Loader.CharacterController.UIController.Leaderboard)
               LeaderboardMenu = LeaderboardModule.new()
           end
           
           LeaderboardMenu:Initialize()
           LeaderboardMenu:KeyUsed("Leaderboard", true, {Key = "Leaderboard", Down = true})
        end
    })
    
Tabs.Main:AddSection("Map Modification")
    
local Toggle = Tabs.Main:AddToggle("RemoveDamage", {Title = "Remove Damage Objects", Default = false })

    Toggle:OnChanged(function(value)
        DConfiguration.Removals.DamageParts = value
        
      while task.wait(1) and DConfiguration.Removals.DamageParts do
			spawn(DFunctions.RemoveDamagePart)
		end
    end)
    
 local Toggle = Tabs.Main:AddToggle("RemoveReducingRewards", {Title = "Remove Reducing Rewards", Default = false })

    Toggle:OnChanged(function(value)
        DConfiguration.Removals.ReducingRewards = value
        
      while task.wait(1) and DConfiguration.Removals.ReducingRewards do
			spawn(DFunctions.RemoveReduceRewards)
		end
    end)

local Toggle = Tabs.Main:AddToggle("RemoveReducingRewards", {Title = "Remove Invisible Walls", Default = false })

    Toggle:OnChanged(function(value)
        DConfiguration.Removals.InvisibleWalls = value
        
      while task.wait(1) and DConfiguration.Removals.InvisibleWalls do
          spawn(function()
				DFunctions.DisableInvisParts(false)
			end)
		end
		
		if not DConfiguration.Removals.InvisibleWalls then
			DFunctions.DisableInvisParts(true)
		end
    end)
    
Tabs.Main:AddSection("Battlepass Modification")

local Toggle = Tabs.Main:AddToggle("BypassTimer", { Title = "Bypass Timer", Default = false })

Toggle:OnChanged(function(value)
    DConfiguration.Battlepass.BypassTimer = value

    while DConfiguration.Battlepass.BypassTimer and task.wait(1) do
        local Unlocked = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Menu") and LocalPlayer.PlayerGui.Menu:FindFirstChild("Views") and LocalPlayer.PlayerGui.Menu.Views:FindFirstChild("Battlepass") and LocalPlayer.PlayerGui.Menu.Views.Battlepass:FindFirstChild("ViewPass") and LocalPlayer.PlayerGui.Menu.Views.Battlepass.ViewPass:FindFirstChild("Center") and LocalPlayer.PlayerGui.Menu.Views.Battlepass.ViewPass.Center:FindFirstChild("ViewPass") and LocalPlayer.PlayerGui.Menu.Views.Battlepass.ViewPass.Center.ViewPass:FindFirstChild("Unlocked")

        if Unlocked then
            Unlocked.Visible = false
        end
    end
end)

local Toggle = Tabs.Main:AddToggle("EnableExchange", {Title = "Enable Exchange", Default = false })

Toggle:OnChanged(function(value)
    local Center = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Menu") and LocalPlayer.PlayerGui.Menu:FindFirstChild("Views") and LocalPlayer.PlayerGui.Menu.Views:FindFirstChild("Battlepass") and LocalPlayer.PlayerGui.Menu.Views.Battlepass:FindFirstChild("Center")
    local Exchange = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Menu") and LocalPlayer.PlayerGui.Menu:FindFirstChild("Views") and LocalPlayer.PlayerGui.Menu.Views:FindFirstChild("Battlepass") and LocalPlayer.PlayerGui.Menu.Views.Battlepass:FindFirstChild("Exchange")

    if Center and Exchange then
        Center.Visible = not value
        Exchange.Visible = value
    end
end)

Tabs.Main:AddSection("Player Modification")
    
local Toggle = Tabs.Main:AddToggle("Noclip", {Title = "Noclip", Default = false })

Toggle:OnChanged(function(value)
   DConfiguration.Main.Noclip = value
end)

local FLYING = false
local velocityHandlerName = "VelocityHandler"
local gyroHandlerName = "GyroHandler"
local mfly1, mfly2
local currentCharacter

local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function unmobilefly(player)
    pcall(function()
        FLYING = false
        local character = player.Character
        if character then
            local root = getRoot(character)
            if root then
                local velocityHandler = root:FindFirstChild(velocityHandlerName)
                local gyroHandler = root:FindFirstChild(gyroHandlerName)

                if velocityHandler then
                    velocityHandler:Destroy()
                end

                if gyroHandler then
                    gyroHandler:Destroy()
                end

                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end
        end

        if mfly1 then
            mfly1:Disconnect()
        end

        if mfly2 then
            mfly2:Disconnect()
        end
    end)
end

local function mobilefly(player, vfly)
    unmobilefly(player)
    FLYING = true

    local character = player.Character
    local root = getRoot(character)

    if character and root then
        local camera = workspace.CurrentCamera
        local v3none = Vector3.new()
        local v3zero = Vector3.new(0, 0, 0)
        local v3inf = Vector3.new(9e9, 9e9, 9e9)

        local controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        local bv = Instance.new("BodyVelocity")
        bv.Name = velocityHandlerName
        bv.Parent = root
        bv.MaxForce = v3zero
        bv.Velocity = v3zero

        local bg = Instance.new("BodyGyro")
        bg.Name = gyroHandlerName
        bg.Parent = root
        bg.MaxTorque = v3inf
        bg.P = 1000
        bg.D = 2

        mfly1 = player.CharacterAdded:Connect(function()
            unmobilefly(player)
            currentCharacter = player.Character
            mobilefly(player, vfly)
        end)

        mfly2 = RunService.RenderStepped:Connect(function()
            root = getRoot(player.Character)
            camera = workspace.CurrentCamera
            if player.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
                local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
                local VelocityHandler = root:FindFirstChild(velocityHandlerName)
                local GyroHandler = root:FindFirstChild(gyroHandlerName)

                if VelocityHandler and GyroHandler then
                    VelocityHandler.MaxForce = v3inf
                    GyroHandler.MaxTorque = v3inf

                    if not vfly and humanoid then
                        humanoid.PlatformStand = false
                    end

                    GyroHandler.CFrame = camera.CoordinateFrame
                    VelocityHandler.Velocity = v3none

                    local direction = controlModule:GetMoveVector()
                    if direction.X ~= 0 or direction.Z ~= 0 then
                        local moveVector = Vector3.new(direction.X, 0, direction.Z).unit
                        local rightVector = camera.CFrame.RightVector
                        local forwardVector = camera.CFrame.LookVector

                        local flyDirection = (rightVector * moveVector.X - forwardVector * moveVector.Z).unit

                        VelocityHandler.Velocity = flyDirection * (_G.flySpeed * 20)
                        RunService.RenderStepped:Wait()
                    end
                end
            end
        end)
    end
end

local function toggleFly(player, toggleValue)
    if toggleValue then
        mobilefly(player, true)
    else
        unmobilefly(player)
    end
end

_G.Fly = false

local function flyLoop()
    while wait(10) do
        if _G.Fly then
            local player = LocalPlayer
            if player and player.Character then
                mobilefly(player, true)
            end
        end
    end
end

local Toggle = Tabs.Main:AddToggle("FlyToggle", { Title = "Fly Toggle", Default = false })

Toggle:OnChanged(function(Value)
    local player = LocalPlayer
    _G.Fly = Value
    toggleFly(player, Value)
end)

Options.FlyToggle:SetValue(false)

_G.flySpeed = 20 

local FlySpeedInput = Tabs.Main:AddInput("FlySpeedInput", {
    Title = "Fly Speed",
    Default = tostring(_G.flySpeed),
    Placeholder = "Enter fly speed",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        _G.flySpeed = tonumber(Value) or 20
    end
})

spawn(flyLoop)
    
wait(Duration)

-- Auto Farm

Tabs.AutoFarm:AddSection("Farmings")
    
local Toggle = Tabs.AutoFarm:AddToggle("AutoFarmMoney", {Title = "Auto Farm Money", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.AutoFarm.FarmTokens = State

    while DConfiguration.AutoFarm.FarmTokens and wait(3) do
        spawn(DFunctions.RevivePlayer)
    end
end)

local Toggle = Tabs.AutoFarm:AddToggle("AutoFarmTickets", {Title = "Auto Farm Tickets", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.AutoFarm.FarmTickets = State

    while DConfiguration.AutoFarm.FarmTickets and wait(1) do
        spawn(DFunctions.TicketsFarming)
    end
end)
 
 local Toggle = Tabs.AutoFarm:AddToggle("AutoCompleteObjectives", {Title = "Auto Complete Objective", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.AutoFarm.CompleteObjective = State

    while DConfiguration.AutoFarm.CompleteObjective and wait(3) do
        spawn(DFunctions.PointFarming)
    end
end)

local Toggle = Tabs.AutoFarm:AddToggle("AutoCatchNPC", {Title = "Auto Catch NPC", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.CatchEventNPC = State
       
      while DConfiguration.AutoFarm.CatchEventNPC and RunService.RenderStepped:Wait() do
          spawn(DFunctions.TPEventNPC)
      end
 end)
    
local Toggle = Tabs.AutoFarm:AddToggle("AFKFarm", {Title = "AFK Farm", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.AFKFarm = State
      
      while DConfiguration.AutoFarm.AFKFarm and wait(3) do
         spawn(DFunctions.AFKFarming)
       end
    end)
    
Tabs.AutoFarm:AddSection("Purchase Automations")

local Toggle = Tabs.AutoFarm:AddToggle("AutoBuy", {Title = "Auto Purchase Selected Item", Default = false })

    Toggle:OnChanged(function(State)
       DConfiguration.AutoFarm.PurchaseAutomations.Enabled = State
       
       while DConfiguration.AutoFarm.PurchaseAutomations.Enabled and wait() do
          DFunctions.BuyItem(DConfiguration.AutoFarm.PurchaseAutomations.Selected, "Loadout")
       end
    end)

local Dropdown = Tabs.AutoFarm:AddDropdown("SelectedItem", {
        Title = "Select Item",
        Values = LoadoutNames,
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.AutoFarm.PurchaseAutomations.Selected = Value
    end)
    
Tabs.AutoFarm:AddSection("VIP Automations")

local Toggle = Tabs.AutoFarm:AddToggle("AutoVote", {Title = "Auto Vote", Default = false })

    Toggle:OnChanged(function(State)
       DConfiguration.AutoFarm.VIPAutomations.AutoVote = State
       
       while DConfiguration.AutoFarm.VIPAutomations.AutoVote and wait(1) do
          DFunctions.AutoVote(DConfiguration.AutoFarm.VIPAutomations.MapSection, DConfiguration.AutoFarm.VIPAutomations.GamemodeSection)
       end
    end)
    
local Dropdown = Tabs.AutoFarm:AddDropdown("MapSection", {
        Title = "Map Section",
        Values = {1, 2, 3, 4},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.AutoFarm.VIPAutomations.MapSection = Value
    end)
    
local Dropdown = Tabs.AutoFarm:AddDropdown("GamemodeSection", {
        Title = "Gamemode Section",
        Values = {1, 2, 3, 4},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.AutoFarm.VIPAutomations.GamemodeSection = Value
    end)
    
Tabs.AutoFarm:AddParagraph({
        Title = " ",
        Content = ""
    })

local Toggle = Tabs.AutoFarm:AddToggle("AutoSetMap", {Title = "Auto Set Map", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.VIPAutomations.AutoMap = State
      
      if DConfiguration.AutoFarm.VIPAutomations.AutoMap then
         DFunctions.SetVIPCommands(DConfiguration.AutoFarm.VIPAutomations.MapInput, nil)
      end
    end)
    
local Toggle = Tabs.AutoFarm:AddToggle("AutoSetSpecialRound", {Title = "Auto Set Special Round", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.VIPAutomations.AutoSpecialRound = State
      
      if DConfiguration.AutoFarm.VIPAutomations.AutoSpecialRound then
         DFunctions.SetVIPCommands(nil, DConfiguration.AutoFarm.VIPAutomations.SpecialRoundInput)
       end
    end)
    
local Toggle = Tabs.AutoFarm:AddToggle("AutoSetSpecialRound", {Title = "Auto Set Timer", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.VIPAutomations.AutoTimer = State
      
      if DConfiguration.AutoFarm.VIPAutomations.AutoTimer then
         DFunctions.SetVIPCommands(nil, nil, DConfiguration.AutoFarm.VIPAutomations.TimerInput)
       end
    end)
    
local Toggle = Tabs.AutoFarm:AddToggle("AutoSetMap", {Title = "Auto Set Gamemode to Pro (RECOMMENDED)", Default = false })

    Toggle:OnChanged(function(State)
      DConfiguration.AutoFarm.VIPAutomations.AutoProMode = State
      
      if DConfiguration.AutoFarm.VIPAutomations.AutoProMode then
         ReplicatedStorage.Events.CustomServers.Admin:FireServer("Gamemode", "Pro")
	     wait(3)
	     game:GetService("ReplicatedStorage").Events.Player.ChangePlayerMode:FireServer(true)
      end
   end)
    
Tabs.AutoFarm:AddInput("MapInput", {
    Title = "Map Input",
    Default = "DesertBus",
    Placeholder = "DesertBus",
    Numeric = false, 
    Finished = false, 
    Description = "NO SPACE NEEDED",
    Callback = function(Value)
        DConfiguration.AutoFarm.VIPAutomations.MapInput = Value
    end
})

Tabs.AutoFarm:AddInput("SpecialRoundInput", {
    Title = "Special Round Input",
    Default = "Plushie Hell",
    Placeholder = "Plushie Hell",
    Numeric = false, 
    Finished = false, 
    Callback = function(Value)
        DConfiguration.AutoFarm.VIPAutomations.SpecialRoundInput = Value
    end
})

Tabs.AutoFarm:AddInput("TimerInput", {
    Title = "Timer Input",
    Default = "180",
    Placeholder = "180",
    Numeric = false, 
    Finished = false, 
    Callback = function(Value)
        DConfiguration.AutoFarm.VIPAutomations.TimerInput = Value
    end
})

-- Combat

wait(Duration)

-- Combat

Tabs.Combat:AddSection("Nextbot Modification")

local Toggle = Tabs.Combat:AddToggle("AntiNextbotToggle", {Title = "Anti Nextbot Toggle", Default = false })

    Toggle:OnChanged(function(value)
    DConfiguration.Combat.AntiNextbot = value
        
    while DConfiguration.Combat.AntiNextbot and wait(0.1) do
          spawn(DFunctions.AntiNextbot)
       end
    end)

local Dropdown = Tabs.Combat:AddDropdown("AntiBotTeleport", {
        Title = "Anti Nextbot Teleport Type",
        Values = {"Spawn", "Players"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Combat.AntiNextbotType = Value
    end)
    
  Tabs.Combat:AddInput("NextbotDistance", {
    Title = "Anti Nextbot Distance",
    Default = 15,
    Placeholder = "Number",
    Numeric = false, 
    Finished = false, 
    Callback = function(Value)
        DConfiguration.Combat.AntiNextbotRange = tonumber(Value) or 15 
    end
})

wait(Duration)

-- Misc

Tabs.Misc:AddSection("Player Adjustments")

Tabs.Misc:AddInput("PlayerSpeed", {
    Title = "Player Speed",
    Description = "Change how fast your character moves.",
    Default = "1500",
    Placeholder = "Speed Number",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DConfiguration.Misc.PlayerAdjustment.Update.Speed = tonumber(Value) or 1500
        DConfiguration.Misc.PlayerAdjustment.Saved.Speed = tonumber(Value) or 1500
    end
})

Tabs.Misc:AddInput("PlayerJump", {
    Title = "Player Jump",
    Description = "Change how high your character jumps,",
    Default = "3",
    Placeholder = "Jump Number",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DConfiguration.Misc.PlayerAdjustment.Update.JumpHeight = tonumber(Value) or 3
        DConfiguration.Misc.PlayerAdjustment.Saved.JumpHeight = tonumber(Value) or 3
    end
})

Tabs.Misc:AddInput("PlayerJumpAcce", {
    Title = "Player Jump Acceleration",
    Description = "Your speed increases when you jump.",
    Default = "1.5",
    Placeholder = "Jump Acceleration Number",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DConfiguration.Misc.PlayerAdjustment.Update.JumpAcceleration = tonumber(Value) or 1.5
        DConfiguration.Misc.PlayerAdjustment.Saved.JumpAcceleration = tonumber(Value) or 1.5
    end
})

Tabs.Misc:AddInput("PlayerJumpCap", {
    Title = "Player Jump Cap",
    Description = "Allows air jumping.",
    Default = "1",
    Placeholder = "Jump Cap Number",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DConfiguration.Misc.PlayerAdjustment.Update.JumpCap = tonumber(Value) or 1
        DConfiguration.Misc.PlayerAdjustment.Saved.JumpCap = tonumber(Value) or 1
    end
})

Tabs.Misc:AddInput("PlayerStrafeAcceleration", {
    Title = "Player Strafe Acceleration",
    Description = "Change how fast you move sideways in the air.",
    Default = "182",
    Placeholder = "Number",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DConfiguration.Misc.PlayerAdjustment.Update.AirStrafe = tonumber(Value) or 182
        DConfiguration.Misc.PlayerAdjustment.Saved.AirStrafe = tonumber(Value) or 182
    end
})
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("PlayerJumpPower", {Title = "Jump Power Toggle", Default = false })

    Toggle:OnChanged(function(State)
        DConfiguration.Misc.Humanoids.OriginalJumpHeight = State
     
       while DConfiguration.Misc.Humanoids.OriginalJumpHeight and wait(0.1) do
           local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
           if not UseOriginalJump and humanoid then
               humanoid.UseJumpPower = false
               humanoid.JumpPower = 20
           end
     
          if LocalPlayer.Character and humanoid then
               humanoid.UseJumpPower = true
               humanoid.JumpPower = DConfiguration.Misc.Humanoids.JP
         end
    end
end)

 Tabs.Misc:AddInput("PlayerJumpPower", {
        Title = "Player Jump Power",
        Default = "20",
        Placeholder = "Jump Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Humanoids.JP = tonumber(Value) or 20
        end
    })
    
local Toggle = Tabs.Misc:AddToggle("PlayerWalkspeed", {Title = "Walkspeed Toggle", Default = false })

    Toggle:OnChanged(function(State)
        DConfiguration.Misc.Humanoids.WalkspeedCF = State
 
        while DConfiguration.Misc.Humanoids.WalkspeedCF and wait(0.01) do
            local hb = RunService.Heartbeat
            local speaker = game.Players.LocalPlayer
            local chr = speaker.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            local delta = hb:Wait()

            if chr and hum.MoveDirection.Magnitude > 0 then
               chr:TranslateBy(hum.MoveDirection * DConfiguration.Misc.Humanoids.CF * delta * 10)
           end
        end
    end)

 Tabs.Misc:AddInput("PlayerWalkCf", {
        Title = "Player Walkspeed",
        Default = "5",
        Placeholder = "Walk Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Humanoids.CF = tonumber(Value) or 5
        end
    })
    
Tabs.Misc:AddSection("Utilities")

local Toggle = Tabs.Misc:AddToggle("LagSwitch", {Title = "Lag Switch (Button)", Default = false})

Toggle:OnChanged(function(State)
    if State then
        DFunctions.CreateButton("LagSwitchButton", "Start Lag", 0.15 + DConfiguration.Settings.GuiScale.LagSwitch, 0.1 + DConfiguration.Settings.GuiScale.LagSwitch, function(btn)
           task.spawn(function() 
	           DFunctions.StartLag(DConfiguration.Misc.Utilities.LagSwitch.MSDelay) 
           end)
           btn.Text = "..."
           wait(0.1)
           btn.Text = "Start Lag"
       end)
    else
        DFunctions.DestroyButton("LagSwitchButton")
    end
end)

local Keybind = Tabs.Misc:AddKeybind("LagSwitchKey", {
        Title = "Lag Switch Keybind",
        Mode = "Toggle", -- Always, Toggle, Hold
        Default = "H",
        
        Callback = function()
          task.spawn(function() 
	          DFunctions.StartLag(DConfiguration.Misc.Utilities.LagSwitch.MSDelay) 
          end)
     end,
    })
    
Tabs.Misc:AddInput("LagSwitchButtonSize", {
    Title = "Lag Switch Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.LagSwitch),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.LagSwitch = num * 0.01
        else
            DConfiguration.Settings.GuiScale.LagSwitch = 0
        end
        
        DFunctions.UpdateButton("LagSwitchButton", 0.15 + DConfiguration.Settings.GuiScale.LagSwitch, 0.1 + DConfiguration.Settings.GuiScale.LagSwitch)
    end
})
    
 Tabs.Misc:AddInput("DelayMS", {
        Title = "Delay MS",
        Default = "200",
        Placeholder = "Value",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Misc.Utilities.LagSwitch.MSDelay = tonumber(Value) or 200
        end
    })
    
local Dropdown = Tabs.Misc:AddDropdown("LagMode", {
        Title = "Lag Mode",
        Values = {"Normal", "Demon", "FastFlag"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.Utilities.LagSwitch.Mode = Value
    end)

Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("AdjustBounce", {Title = "Modify Bounce", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.Misc.Utilities.BounceModification.Enabled = State
     
    while DConfiguration.Misc.Utilities.BounceModification.Enabled and wait(0.1) do
        spawn(DFunctions.BounceFunction)
    end
end)

local Toggle = Tabs.Misc:AddToggle("SuperBounce", {Title = "Super Bounce", Default = false})

Toggle:OnChanged(function(State)
    if State then
        DFunctions.CreateButton("SuperBounceButton", "Super Bounce", 0.1 + DConfiguration.Settings.GuiScale.SuperBounce, 0.1 + DConfiguration.Settings.GuiScale.SuperBounce, function(btn)
           DFunctions.SuperBounce()
           btn.Text = "..."
           wait(0.1)
           btn.Text = "Super Bounce"
       end)
    else
        DFunctions.DestroyButton("SuperBounceButton")
    end
end)

 Tabs.Misc:AddInput("PlayerBounce", {
        Title = "Player Bounce",
        Default = "80",
        Placeholder = "Bounce Number",
        Numeric = false,
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Utilities.BounceModification.DefaultBounce = tonumber(Value) or 80
        end
    })
    
 Tabs.Misc:AddInput("EmoteBounce", {
        Title = "Emote Bounce",
        Default = "120",
        Placeholder = "Bounce Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Utilities.BounceModification.EmoteBounce = tonumber(Value) or 120
        end
    })
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("AdjustEdgeTrimp", {Title = "Modify Edge Trimp", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.Misc.Utilities.EdgeTrimpModification.Enabled = State
     
    while DConfiguration.Misc.Utilities.EdgeTrimpModification.Enabled and wait(0.1) do
        spawn(DFunctions.ModifyEdgeTrimp)
    end
end)

Tabs.Misc:AddInput("EdgeTrimpHeight", {
        Title = "Height Multiplier",
        Default = "1.5",
        Placeholder = "Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Utilities.EdgeTrimpModification.HeightMultiplier = tonumber(Value) or 1.5
        end
    })
    
Tabs.Misc:AddInput("DownThreshold", {
        Title = "Falling Threshold",
        Default = "4.5",
        Placeholder = "Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.Utilities.EdgeTrimpModification.DownThreshold = tonumber(Value) or 4.5
        end
    })
    
Tabs.Misc:AddSection("Camera Adjustments")

Tabs.Misc:AddInput("CamX", {
        Title = "Stretch Horizontal",
        Default = "1",
        Placeholder = "Number",
        Numeric = false,
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.CameraAdjustment.StretchX = tonumber(Value) or 1
        end
    })
    
 Tabs.Misc:AddInput("CamY", {
        Title = "Stretch Vertical",
        Default = "1",
        Placeholder = "Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.CameraAdjustment.StretchY = tonumber(Value) or 1
        end
    })
    
 Tabs.Misc:AddInput("PlayerFOV", {
        Title = "Player FOV",
        Default = "1",
        Placeholder = "Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            LocalPlayer.PlayerScripts.Camera.FOVAdjusters.Zoom.Value = Value
        end
    })
    
Tabs.Misc:AddButton({
        Title = "Set Camera Stretch",
        Description = "(Warning: Stretch settings can make billboards look weird or disappear from far away.)",
        Callback = function()
           LocalPlayer:SetAttribute("StretchX", DConfiguration.Misc.CameraAdjustment.StretchX)
           LocalPlayer:SetAttribute("StretchY", DConfiguration.Misc.CameraAdjustment.StretchY)
        end
    })
    
Tabs.Misc:AddButton({
        Title = "Enable Front Camera",
        Description = "",
        Callback = function()
           LocalPlayer.PlayerGui.Shared.HUD.Mobile.Right.Mobile.ReloadButton.Visible = true
        end
    })
    
 Tabs.Misc:AddSection("Gun Adjustments")

Tabs.Misc:AddButton({
        Title = "Set to Infinite Ammo",
        Description = " ",
        Callback = function()
             for i, v in pairs(getgc(true)) do
                 if type(v) == "table" and rawget(v, "Ammo") then
                    v.Cap = 99999e99999
                    v.Ammo = 99999e99999
                 end
             end
        end
    })
    
Tabs.Misc:AddButton({
        Title = "Set to Infinite Range",
        Description = " ",
        Callback = function()
         for i, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "Range") then
               v.Range = 99999e99999
            end 
            
            if type(v) == "table" and rawget(v, "SpreadInfo") then
               v.MaxSpread = 99999
               v.MinSpread = 0
               v.ReductionRate = 99999
            end 
        end
     end
    })
    
Tabs.Misc:AddButton({
        Title = "No Cooldown",
        Description = " ",
        Callback = function()
        for i, v in pairs(getgc(true)) do
          if type(v) == "table" and rawget(v, "SpreadIncrease") and rawget(v, "Gravity") then
         v.Speed = 5000
         v.SpreadIncrease = 1000
         v.Gravity = Vector3.new(0, 0, 0)
         v.Cooldown = 0 
         v.Lifetime = 1 
      end
end 
        end
    })
    
Tabs.Misc:AddSection("Game Automations")

local Toggle = Tabs.Misc:AddToggle("InstantReviveButton", {Title = "Instant Revive (Button)", Default = false})

Toggle:OnChanged(function(State)
    if State then
          DFunctions.CreateButton("InstantReviveButton", "Instant Revive: OFF", 0.15 + DConfiguration.Settings.GuiScale.InstantRevive, 0.1 + DConfiguration.Settings.GuiScale.InstantRevive, function(btn)
         	DConfiguration.Misc.GameAutomation.Revive.FloatingButton = not DConfiguration.Misc.GameAutomation.Revive.FloatingButton
             btn.Text = DConfiguration.Misc.GameAutomation.Revive.FloatingButton and "Instant Revive: ON" or "Instant Revive: OFF"
          end)
     else
         DFunctions.DestroyButton("InstantReviveButton")
     end
end)

local Toggle = Tabs.Misc:AddToggle("InstantRevive", {Title = "Instant Revive", Default = false})

Toggle:OnChanged(function(State)
    DConfiguration.Misc.GameAutomation.Revive.Enabled = State
    
  while DConfiguration.Misc.GameAutomation.Revive.Enabled and wait(DConfiguration.Misc.GameAutomation.Revive.Delay) do
      if DConfiguration.Misc.GameAutomation.Revive.WhileEmote then
          spawn(DFunctions.InstantRevive)
      else
           spawn(DFunctions.InstantReviveNoEmote)
       end
    end
end)

local Toggle = Tabs.Misc:AddToggle("InsQua", {Title = "Instant Revive While Emote", Default = false})

Toggle:OnChanged(function(State)
    DConfiguration.Misc.GameAutomation.Revive.WhileEmote = State
end)

local Slider = Tabs.Misc:AddSlider("ReviveDelay", {
        Title = "Revive Delay",
        Description = "",
        Default = 0.1,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(v)
            DConfiguration.Misc.GameAutomation.Revive.Delay = v
        end
    })
    
local Keybind = Tabs.Misc:AddKeybind("KeybindRevive", {
        Title = "Keybind to Instant Revive",
        Mode = "Toggle", 
        Default = "RightShift",
        
        Callback = function(Bool)
        DConfiguration.Misc.GameAutomation.Revive.Keybind = Bool
   end,
    })

Tabs.Misc:AddInput("InstantReviveButtonSize", {
    Title = "Instant Revive Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.InstantRevive),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.InstantRevive = num * 0.01
        else
            DConfiguration.Settings.GuiScale.InstantRevive = 0
        end
        
        DFunctions.UpdateButton("InstantReviveButton", 0.15 + DConfiguration.Settings.GuiScale.InstantRevive, 0.1 + DConfiguration.Settings.GuiScale.InstantRevive)
    end
})
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("AutoCarry", {Title = "Auto Carry (Button)", Default = false})

Toggle:OnChanged(function(State)
    if State then
      DFunctions.CreateButton("AutoCarryGui", "Auto Carry: OFF", 0.15 + DConfiguration.Settings.GuiScale.AutoCarry, 0.1 + DConfiguration.Settings.GuiScale.AutoCarry, function(btn)
      	DConfiguration.Misc.GameAutomation.Carry.FloatingButton = not DConfiguration.Misc.GameAutomation.Carry.FloatingButton
          btn.Text = DConfiguration.Misc.GameAutomation.Carry.FloatingButton and "Auto Carry: ON" or "Auto Carry: OFF"
       end)
  else
      DFunctions.DestroyButton("AutoCarryGui")
    end
end)

local Toggle = Tabs.Misc:AddToggle("EmoteCarry", {Title = "Carry While Emote", Default = false})

Toggle:OnChanged(function(State)
    DConfiguration.Misc.GameAutomation.Carry.WhileEmote = State
end)

local Keybind = Tabs.Misc:AddKeybind("KeybindCarry", {
        Title = "Keybind to Carry",
        Mode = "Toggle", 
        Default = "Q",
        
        Callback = function(Bool)
        DConfiguration.Misc.GameAutomation.Carry.Keybind = Bool
   end,
})

Tabs.Misc:AddInput("CarryButtonSize", {
    Title = "Auto Carry Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.AutoCarry),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.AutoCarry = num * 0.01
        else
            DConfiguration.Settings.GuiScale.AutoCarry = 0
        end
        
        DFunctions.UpdateButton("AutoCarryGui", 0.15 + DConfiguration.Settings.GuiScale.AutoCarry, 0.1 + DConfiguration.Settings.GuiScale.AutoCarry)
    end
})

Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })

wait(Duration)

local Toggle = Tabs.Misc:AddToggle("AutoEmote", {Title = "Auto Emote Dash Button", Default = false})

Toggle:OnChanged(function(State)
    if State then
      DFunctions.CreateButton("EmoteDashButton", "Start Emote", 0.15 + DConfiguration.Settings.GuiScale.AutoEmoteDash, 0.1 + DConfiguration.Settings.GuiScale.AutoEmoteDash, function(btn)
           btn.Text = "Emoting..."
           ReplicatedStorage.Events.Character.Emote:FireServer(DConfiguration.Misc.GameAutomation.Macro.SelectedEmote)
           wait(0.1)
           btn.Text = "Crouching..."
           LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = true })
           wait(0.1)
           btn.Text = "Start Emote"
       end)
    else
        DFunctions.DestroyButton("EmoteDashButton")
    end
end)

Tabs.Misc:AddInput("EmoteButtonSize", {
    Title = "Auto Emote Dash Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.AutoEmoteDash),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.AutoEmoteDash = num * 0.01
        else
            DConfiguration.Settings.GuiScale.AutoEmoteDash = 0
        end
        
        DFunctions.UpdateButton("EmoteDashButton", 0.15 + DConfiguration.Settings.GuiScale.AutoEmoteDash, 0.1 + DConfiguration.Settings.GuiScale.AutoEmoteDash)
    end
})

local Keybind = Tabs.Misc:AddKeybind("KeyEmoteDash", {
        Title = "Keybind to Emote Dash",
        Mode = "Toggle", 
        Default = "RightControl",
        
        Callback = function(Bool)
        DConfiguration.Misc.GameAutomation.Macro.Keybind = Bool
        
        if DConfiguration.Misc.GameAutomation.Macro.Keybind then
           ReplicatedStorage.Events.Character.Emote:FireServer(DConfiguration.Misc.GameAutomation.SelectedEmote)
           wait(0.1)
           LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = true })
        end
   end,
    })
    
local Dropdown = Tabs.Misc:AddDropdown("EmoteID", {
        Title = "Select Emote ID",
        Values = EmoteNames,
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.GameAutomation.Macro.SelectedEmote = Value
    end)

Tabs.Misc:AddSection("Movement Modification")

local Toggle = Tabs.Misc:AddToggle("AggressiveEmoteDash", {Title = "Aggressive Emote Dash", Default = false })

Toggle:OnChanged(function(State)
	DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Enabled = State
	
	if not DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Enabled then
	    DConfiguration.Misc.PlayerAdjustment.Debounce.GroundAcceleration = false
	    DFunctions.setTSpeed(DConfiguration.Misc.PlayerAdjustment.Saved.Speed)
	end
end)

local Dropdown = Tabs.Misc:AddDropdown("AggressiveEmoteType", {
        Title = "Aggressive Emote Type",
        Values = {"Legit", "Blatant"},
        Multi = false,
        Default = 2,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Type = Value
    end)
    
 Tabs.Misc:AddInput("EmoteSpeed", {
        Title = "Aggressive Emote Speed",
        Default = "2000",
        Placeholder = "Emote Speed Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Speed = tonumber(Value) or 2000
        end
    })
    
Tabs.Misc:AddInput("CrouchSpeed", {
        Title = "Aggressive Emote Acceleration (Negative Only)",
        Default = "-2",
        Placeholder = "Acceleration Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Acceleration = tonumber(Value) or -2
        end
    })
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })

local Toggle = Tabs.Misc:AddToggle("InfiniteSlide", {Title = "Infinite Slide", Default = false })

Toggle:OnChanged(function(State)
    DConfiguration.Misc.MovementModification.SlideModification.Enabled = State
    
    if not DConfiguration.Misc.MovementModification.SlideModification.Enabled then
        DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
        wait(0.1)
        DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
    end
end)

local Toggle = Tabs.Misc:AddToggle("InfiniteSlideButton", {Title = "Infinite Slide (Button)", Default = false })

Toggle:OnChanged(function(State)
    if State then
        DFunctions.CreateButton("InfiniteSlideButton", "Infinite Slide: OFF", 0.15 + DConfiguration.Settings.GuiScale.InfiniteSlide, 0.1 + DConfiguration.Settings.GuiScale.InfiniteSlide, function(btn)
            DConfiguration.Misc.MovementModification.SlideModification.FloatingButton = not DConfiguration.Misc.MovementModification.SlideModification.FloatingButton
            btn.Text = DConfiguration.Misc.MovementModification.SlideModification.FloatingButton and "Infinite Slide: ON" or "Infinite Slide: OFF"
            DConfiguration.Misc.MovementModification.SlideModification.Enabled = DConfiguration.Misc.MovementModification.SlideModification.FloatingButton
            
            if not DConfiguration.Misc.MovementModification.SlideModification.FloatingButton then
                DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
                wait(0.1)
                DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
            end
        end)
    else
        DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration = 5
        wait(0.1)
        DFunctions.DestroyButton("InfiniteSlideButton")
    end
end)

Tabs.Misc:AddInput("InfiniteSlideButtonSize", {
    Title = "Infinite Slide Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.InfiniteSlide),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.InfiniteSlide = num * 0.01
        else
            DConfiguration.Settings.GuiScale.InfiniteSlide = 0
        end
        
        DFunctions.UpdateButton("InfiniteSlideButton", 0.15 + DConfiguration.Settings.GuiScale.InfiniteSlide, 0.1 + DConfiguration.Settings.GuiScale.InfiniteSlide)
    end
})

 Tabs.Misc:AddInput("CrouchSpeed", {
        Title = "Slide Speed (Negative Only)",
        Default = "-3",
        Placeholder = "Crouch Speed Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.SlideModification.Acceleration = tonumber(Value) or -3
        end
    })

 Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })

local NormalGravity = game.Workspace.Gravity

local Toggle = Tabs.Misc:AddToggle("GravityToggle", {Title = "Gravity Button", Default = false })

    Toggle:OnChanged(function(State)
      if State then
          DFunctions.CreateButton("GravityGui", "Gravity: OFF", 0.15 + DConfiguration.Settings.GuiScale.Gravity, 0.1 + DConfiguration.Settings.GuiScale.Gravity, function(btn)
         	DConfiguration.Misc.MovementModification.Gravity.FloatingButton = not DConfiguration.Misc.MovementModification.Gravity.FloatingButton
             btn.Text = DConfiguration.Misc.MovementModification.Gravity.FloatingButton and "Gravity: ON" or "Gravity: OFF"
          end)
     else
         DFunctions.DestroyButton("GravityGui")
     end
end)

Tabs.Misc:AddInput("GravityButtonSize", {
    Title = "Gravity Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.Gravity),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.Gravity = num * 0.01
        else
            DConfiguration.Settings.GuiScale.Gravity = 0
        end
        
        DFunctions.UpdateButton("GravityGui", 0.15 + DConfiguration.Settings.GuiScale.Gravity, 0.1 + DConfiguration.Settings.GuiScale.Gravity)
    end
})

local Keybind = Tabs.Misc:AddKeybind("GravitKey", {
        Title = "Gravity Keybind",
        Mode = "Toggle", 
        Default = "J",
        
        Callback = function(Bool)
	        DConfiguration.Misc.MovementModification.Gravity.Keybind = Bool
        end,
    })
    
 Tabs.Misc:AddInput("GravityAdjust", {
        Title = "Gravity Adjustment",
        Default = "10",
        Placeholder = " Number",
        Numeric = false, 
        Finished = false, 
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.Gravity.Value = tonumber(Value) or  10
        end
    })
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("BHOPToggle", {Title = "BHOP (Button)", Default = false })

    Toggle:OnChanged(function(State)
       
       if State then
          DFunctions.CreateButton("BHOPGui", "Auto Jump: OFF", 0.15 + DConfiguration.Settings.GuiScale.AutoJump, 0.1 + DConfiguration.Settings.GuiScale.AutoJump, function(btn)
         	DConfiguration.Misc.MovementModification.BHOP.FloatingButton = not DConfiguration.Misc.MovementModification.BHOP.FloatingButton
             btn.Text = DConfiguration.Misc.MovementModification.BHOP.FloatingButton and "Auto Jump: ON" or "Auto Jump: OFF"
             
             while DConfiguration.Misc.MovementModification.BHOP.FloatingButton and wait(0.1) do
                 DConfiguration.Misc.MovementModification.BHOP.Enabled = DConfiguration.Misc.MovementModification.BHOP.FloatingButton
             end
             
             if not DConfiguration.Misc.MovementModification.BHOP.FloatingButton then          
              spawn(DFunctions.ResetBHOP)
              wait(0.1)
              spawn(DFunctions.ResetBHOP)
              DConfiguration.Misc.MovementModification.BHOP.Enabled = false
          end
      end)
   else
      DFunctions.DestroyButton("BHOPGui")
     end
end)

local Toggle = Tabs.Misc:AddToggle("BHOPJumpButton", {Title = "BHOP (Jump Button)", Default = false })

 Toggle:OnChanged(function(State)
      DConfiguration.Misc.MovementModification.BHOP.JumpButton = State
end)

if UserInputService.TouchEnabled then
    local JumpButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):FindFirstChild("JumpButton")
    
    if JumpButton then
        local isJumping = false

        JumpButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and DConfiguration.Misc.MovementModification.BHOP.JumpButton then
                if not isJumping then
                    isJumping = true
                    DConfiguration.Misc.MovementModification.BHOP.Enabled = true
                end
            end
        end)

        JumpButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and DConfiguration.Misc.MovementModification.BHOP.JumpButton and not DConfiguration.Misc.MovementModification.BHOP.FloatingButton then
                if isJumping then
                    isJumping = false
                    DConfiguration.Misc.MovementModification.BHOP.Enabled = false
                    spawn(DFunctions.ResetBHOP)
                    wait(0.1)
                    spawn(DFunctions.ResetBHOP)
                end
            end
        end)
    end
end

local Keybind = Tabs.Misc:AddKeybind("KeybindBHOP", {
        Title = "Keybind to BHOP",
        Mode = "Toggle", 
        Default = "B",
        
        Callback = function(Bool)
        DConfiguration.Misc.MovementModification.BHOP.Keybind = Bool
        
        if not DConfiguration.Misc.MovementModification.BHOP.Keybind then         
           spawn(DFunctions.ResetBHOP)
        end
   end,
    })
    
local Keybind = Tabs.Misc:AddKeybind("KeybindBHOP2", {
        Title = "Keybind to BHOP (Hold)",
        Mode = "Hold", 
        Default = "Space",
        
        Callback = function(Bool)
        DConfiguration.Misc.MovementModification.BHOP.HoldKeybind = Bool
        
        if not DConfiguration.Misc.MovementModification.BHOP.HoldKeybind then         
           spawn(DFunctions.ResetBHOP)
        end
   end,
    })

Tabs.Misc:AddInput("BHOPButtonSize", {
    Title = "BHOP Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.AutoJump),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.AutoJump = num * 0.01
        else
            DConfiguration.Settings.GuiScale.AutoJump = 0
        end
        
        DFunctions.UpdateButton("BHOPGui", 0.15 + DConfiguration.Settings.GuiScale.AutoJump, 0.1 + DConfiguration.Settings.GuiScale.AutoJump)
    end
})

local Dropdown = Tabs.Misc:AddDropdown("BHOPVersion", {
        Title = "Select BHOP Version",
        Values = {"Acceleration", "Ground Acceleration", "No Acceleration"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.MovementModification.BHOP.Settings.Type = Value
    end)
    
local Dropdown = Tabs.Misc:AddDropdown("JumpType", {
        Title = "Select Jump Type",
        Values = {"Simulated", "Realistic"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.MovementModification.BHOP.Settings.JumpType = Value
    end)
    
local Toggle = Tabs.Misc:AddToggle("BackwardBHOP", {Title = "BHOP Backwards", Default = false })

 Toggle:OnChanged(function(State)
      DConfiguration.Misc.MovementModification.BHOP.Settings.Backwards = State
end)

local Toggle = Tabs.Misc:AddToggle("SpiderHop", {Title = "Spider Hop (Beta)", Default = false })

 Toggle:OnChanged(function(State)
      DConfiguration.Misc.MovementModification.BHOP.Settings.SpiderHop = State
end)
    
Tabs.Misc:AddInput("BHOPAcceleration", {
        Title = "BHOP Acceleration (Negative Only)",
        Default = "-0.1",
        Placeholder = "-1",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.BHOP.Settings.Acceleration = tonumber(Value) or -0.1
        end
    })
    
Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("BHOPAutoAccelerate", {Title = "Auto Acceleration (Legit)", Default = false })

 Toggle:OnChanged(function(State)
      DConfiguration.Misc.MovementModification.BHOP.Settings.AutoAcceleration.Enabled = State
end)

Tabs.Misc:AddInput("AutoAccelerationMaxAccel", {
        Title = "Max Acceleration",
        Default = "3",
        Placeholder = "3",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.BHOP.Settings.AutoAcceleration.MaxAccelerate = tonumber(Value) or 3
        end
    })
    
Tabs.Misc:AddInput("AutoAccelerationMinAccel", {
        Title = "Min Acceleration",
        Default = "-1",
        Placeholder = "-1",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.BHOP.Settings.AutoAcceleration.MinAccelerate = tonumber(Value) or -1
        end
    })

Tabs.Misc:AddInput("AutoAccelerationMaxSpeed", {
        Title = "Max Speed",
        Default = "70",
        Placeholder = "70",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Misc.MovementModification.BHOP.Settings.AutoAcceleration.MinSpeed = tonumber(Value) or 70
        end
    })

Tabs.Misc:AddParagraph({
        Title = " ",
        Content = ""
    })
    
local Toggle = Tabs.Misc:AddToggle("AutoCrouch", {Title = "Auto Crouch (Button)", Default = false })

    Toggle:OnChanged(function(State)       
       if State then
	         DFunctions.CreateButton("AutoCrouchGui", "Auto Crouch: OFF", 0.15 + DConfiguration.Settings.GuiScale.AutoCrouch, 0.1 + DConfiguration.Settings.GuiScale.AutoCrouch, function(btn)
	         	DConfiguration.Misc.MovementModification.Crouch.FloatingButton = not DConfiguration.Misc.MovementModification.Crouch.FloatingButton
	             btn.Text = DConfiguration.Misc.MovementModification.Crouch.FloatingButton and "Auto Crouch: ON" or "Auto Crouch: OFF"
	             if not DConfiguration.Misc.MovementModification.Crouch.FloatingButton then
	                LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = false })
	                wait(0.1)
	                LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = false })
	            end
            end)
        else
	      DFunctions.DestroyButton("AutoCrouchGui")
     end
end)

local Keybind = Tabs.Misc:AddKeybind("KeybindCrouch", {
        Title = "Keybind to Auto Crouch (Hold)",
        Mode = "Hold", 
        Default = "RightControl",
        
        Callback = function(Bool)
        DConfiguration.Misc.MovementModification.Crouch.Keybind = Bool
        
        if not DConfiguration.Misc.MovementModification.Crouch.Keybind then         
           LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = false })
	       wait(0.1)
	       LocalPlayer.PlayerScripts.Events.temporary_events.UseKeybind:Fire({ ["Key"] = "Crouch", ["Down"] = false })
        end
   end,
    })

Tabs.Misc:AddInput("CrouchButtonSize", {
    Title = "Auto Crouch Gui Size",
    Default = tostring(DConfiguration.Settings.GuiScale.AutoCrouch),
    Placeholder = "0",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            DConfiguration.Settings.GuiScale.AutoCrouch = num * 0.01
        else
            DConfiguration.Settings.GuiScale.AutoCrouch = 0
        end
        
        DFunctions.UpdateButton("AutoCrouchGui", 0.15 + DConfiguration.Settings.GuiScale.AutoCrouch, 0.1 + DConfiguration.Settings.GuiScale.AutoCrouch)
    end
})

local Dropdown = Tabs.Misc:AddDropdown("CrouchType", {
        Title = "Select Crouch Type",
        Values = {"Rapid", "Ground", "Air", "Normal"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        DConfiguration.Misc.MovementModification.Crouch.Type = Value
    end)

Tabs.Misc:AddInput("CrouchDebounce", {
    Title = "Crouch Speed",
    Default = "0.1",
    Placeholder = "0.1",
    Numeric = true, 
    Finished = false, 
    Callback = function(Value)
        DConfiguration.Misc.MovementModification.Crouch.debounce = tonumber(Value) or 0.1
    end
})

-- Visual

Tabs.Visual:AddParagraph({
        Title = "Warning: Do not use locked emotes from the emote changer or you may get banned easily",
        Content = ""
    })
    
Tabs.Visual:AddParagraph({
        Title = "To change it back to the original, please rejoin.",
        Content = ""
    })

Tabs.Visual:AddSection("Cosmetics Changer")
    
 Tabs.Visual:AddInput("O_C1", {
        Title = "Current Cosmetics 1",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalCosmetics.Cosmetics1 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_C2", {
        Title = "Current Cosmetics 2",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalCosmetics.Cosmetics2 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_C3", {
        Title = "Current Effect",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalCosmetics.Cosmetics3 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_C4", {
        Title = "Current Character",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalCosmetics.Cosmetics4 = Value
        end
    })

Tabs.Visual:AddParagraph({
        Title = " ",
        Content = ""
    })
    
 Tabs.Visual:AddInput("M_C1", {
        Title = "Select Cosmetics 1",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyCosmetics.Cosmetics1 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_C2", {
        Title = "Select Cosmetics 2",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyCosmetics.Cosmetics2 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_C3", {
        Title = "Select Effect",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyCosmetics.Cosmetics3 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_C4", {
        Title = "Select Character",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyCosmetics.Cosmetics4 = Value
        end
    })
    
Tabs.Visual:AddButton({
        Title = "Change Cosmetics",
        Description = "" ,
        Callback = function()
          spawn(function()
             DFunctions.RestoreCosmetics()
             wait(0.1)
             DFunctions.ChangeCosmetics(DConfiguration.Visual.OriginalCosmetics.Cosmetics1, DConfiguration.Visual.ModifyCosmetics.Cosmetics1)
             DFunctions.ChangeCosmetics(DConfiguration.Visual.OriginalCosmetics.Cosmetics2, DConfiguration.Visual.ModifyCosmetics.Cosmetics2)
           end)
        end
    })

Tabs.Visual:AddButton({
        Title = "Change Effect",
        Description = "" ,
        Callback = function()
          spawn(function()
             DFunctions.RestoreCosmetics()
             wait(0.1)
             DFunctions.ChangeCosmetics(DConfiguration.Visual.OriginalCosmetics.Cosmetics3, DConfiguration.Visual.ModifyCosmetics.Cosmetics3)
           end)
        end
    })

Tabs.Visual:AddButton({
        Title = "Change Character",
        Description = "" ,
        Callback = function()
          spawn(function()
             DFunctions.RestoreCosmetics()
             wait(0.1)
             DFunctions.ChangeCosmetics(DConfiguration.Visual.OriginalCosmetics.Cosmetics4, DConfiguration.Visual.ModifyCosmetics.Cosmetics4)
           end)
        end
    })

Tabs.Visual:AddButton({
        Title = "Restore Cosmetics",
        Description = "" ,
        Callback = function()
          spawn(function()
             DFunctions.RestoreCosmetics()
           end)
        end
    })

Tabs.Visual:AddSection("Emote Changer")

 Tabs.Visual:AddInput("O_E1", {
        Title = "Current Emote 1",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote1 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E2", {
        Title = "Current Emote 2",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote2 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E3", {
        Title = "Current Emote 3",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote3 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E4", {
        Title = "Current Emote 4",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote4 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E5", {
        Title = "Current Emote 5",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote5 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E6", {
        Title = "Current Emote 6",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote6 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E7", {
        Title = "Current Emote 7",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote7 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E8", {
        Title = "Current Emote 8",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote8 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E9", {
        Title = "Current Emote 9",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote9 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E10", {
        Title = "Current Emote 10",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote10 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E5", {
        Title = "Current Emote 11",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote11 = Value
        end
    })
    
 Tabs.Visual:AddInput("O_E12", {
        Title = "Current Emote 12",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.OriginalEmotes.Emote12 = Value
        end
    })
    
Tabs.Visual:AddParagraph({
        Title = " ",
        Content = ""
    })
    
 Tabs.Visual:AddInput("M_E1", {
        Title = "Select Emote 1",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote1 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E2", {
        Title = "Select Emote 2",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote2 = Value
        end
    })

 Tabs.Visual:AddInput("M_E3", {
        Title = "Select Emote 3",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote3 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E4", {
        Title = "Select Emote 4",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote4 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E5", {
        Title = "Select Emote 5",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote5 = Value
        end
    })

 Tabs.Visual:AddInput("M_E6", {
        Title = "Select Emote 6",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote6 = Value
        end
    })
    
Tabs.Visual:AddInput("M_E7", {
        Title = "Select Emote 7",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote7 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E8", {
        Title = "Select Emote 8",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote8 = Value
        end
    })

 Tabs.Visual:AddInput("M_E9", {
        Title = "Select Emote 9",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote9 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E10", {
        Title = "Select Emote 10",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote10 = Value
        end
    })
    
 Tabs.Visual:AddInput("M_E11", {
        Title = "Select Emote 11",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote11 = Value
        end
    })

 Tabs.Visual:AddInput("M_E12", {
        Title = "Select Emote 12",
        Default = " ",
        Placeholder = "",
        Numeric = false, -- Only allows numbers
        Finished = false, -- Only calls callback when you press enter
        Callback = function(Value)
            DConfiguration.Visual.ModifyEmotes.Emote12 = Value
        end
    })

local Dropdown = Tabs.Visual:AddDropdown("EmoteOption", {
        Title = "Select Animation Type",
        Values = {"A", "B", "C", "D"},
        Multi = false,
        Default = 1,
    })

    Dropdown:OnChanged(function(Value)
        SelectedVersion = Value
    end)


Tabs.Visual:AddButton({
        Title = "Change Emotes",
        Description = "" ,
        Callback = function()
          spawn(function()
              DFunctions.ResetEmoteChanges() 
              wait(0.1)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote1, DConfiguration.Visual.ModifyEmotes.Emote1)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote2, DConfiguration.Visual.ModifyEmotes.Emote2)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote3, DConfiguration.Visual.ModifyEmotes.Emote3)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote4, DConfiguration.Visual.ModifyEmotes.Emote4)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote5, DConfiguration.Visual.ModifyEmotes.Emote5)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote6, DConfiguration.Visual.ModifyEmotes.Emote6)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote7, DConfiguration.Visual.ModifyEmotes.Emote7)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote8, DConfiguration.Visual.ModifyEmotes.Emote8)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote9, DConfiguration.Visual.ModifyEmotes.Emote9)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote10, DConfiguration.Visual.ModifyEmotes.Emote10)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote11, DConfiguration.Visual.ModifyEmotes.Emote11)
              DFunctions.ChangeEmotes(DConfiguration.Visual.OriginalEmotes.Emote12, DConfiguration.Visual.ModifyEmotes.Emote12)
           end)
        end
    })

Tabs.Visual:AddButton({
        Title = "Restore Emotes",
        Description = "Having Trouble?" ,
        Callback = function()
           DFunctions.ResetEmoteChanges() 
        end
    })
    
-- info

Tabs.Info:AddParagraph({
        Title = "Elderwyrm Hub X / Overhaul Script",
        Content = "Created by Vraigos"
    })
    
Tabs.Info:AddParagraph({
        Title = "Adjustments / Movement Modification",
        Content = "Created by Vraigos and Aerave"
    })

Tabs.Info:AddParagraph({
        Title = "Adjustments / ESP / Legacy Script",
        Content = "Created by Aerave"
    })

Tabs.Info:AddButton({
        Title = "Join Discord",
        Description = "Tap to copy link",
        Callback = function()
           setclipboard("https://discord.gg/zvhjwgVVbR")
        end
    })
    
Tabs.Info:AddParagraph({
        Title = "UI: Fluent",
        Content = "Created by dawidscripts"
    })
    
-- Settings

Tabs.Settings:AddParagraph({
        Title = "Configuration",
        Content = " "
    })

Tabs.Settings:AddButton({
        Title = "Remove FPS Counter",
        Description = "",
        Callback = function()
            fpsCounter:Destroy()
        end
    })
    
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
FBM:SetLibrary(Fluent)

SaveManager:SetIgnoreIndexes({})

-- Save Folder
InterfaceManager:SetFolder("ElderwyrmHubXUniversal")
FBM:SetFolder("ElderwyrmHubXUniversal/Evade/FloatingButtons")
SaveManager:SetFolder("ElderwyrmHubXUniversal/Evade")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
FBM:BuildConfigSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

-- Auto Load Configuration
SaveManager:LoadAutoloadConfig()

-- Extension

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService('Lighting')

Tabs.Extension:AddSection("Character Extension")

Tabs.Extension:AddButton(
    {
        Title = "Korblox's R6 & R15",
        Description = "",
        Callback = function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local RunService = game:GetService("RunService")
            
            local KORBLOX_MESH_ID = "rbxassetid://101851696" -- Korblox right leg mesh
            local KORBLOX_COLOR = Color3.fromRGB(50, 50, 50) -- Dark Grey for Korblox color

            local function applyKorbloxLeg(character)
                -- Handle R6
                local rightLeg = character:WaitForChild("Right Leg", 9e9) or character:WaitForChild("RightUpperLeg", 9e9)
                if not rightLeg then
                    warn("Right Leg/Upper Leg not found!")
                    return
                end

                for _, child in ipairs(rightLeg:GetChildren()) do
                    if child:IsA("SpecialMesh") or child:IsA("CharacterMesh") then
                        child:Destroy()
                    end
                end

                rightLeg.Color = KORBLOX_COLOR
                rightLeg:GetPropertyChangedSignal("Color"):Connect(
                    function()
                        if rightLeg.Color ~= KORBLOX_COLOR then
                            rightLeg.Color = KORBLOX_COLOR
                        end
                    end
                )

                local korbloxMesh = Instance.new("SpecialMesh")
                korbloxMesh.MeshType = Enum.MeshType.FileMesh
                korbloxMesh.MeshId = KORBLOX_MESH_ID
                korbloxMesh.Scale = Vector3.new(1, 1, 1)
                korbloxMesh.Parent = rightLeg
            end

            local function applyCharacter(character)
                applyKorbloxLeg(character)
            end

            local function applyToLocalPlayer()
                if player.Character then
                    applyCharacter(player.Character)
                end
            end

            player.CharacterAdded:Connect(
                function(character)
                    applyCharacter(character)
                end
            )

            applyToLocalPlayer()
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Headless",
        Description = "",
        Callback = function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local RunService = game:GetService("RunService")
            local HEADLESS_MESH_ID = "rbxassetid://1095708"   

            local function applyHeadless(head)
                if not head then
                    return
                end

                head.Transparency = 1
                head.CanCollide = false
                
                local function removeFace()
                    local face = head:FindFirstChild("face")
                    if face then
                        face:Destroy()
                    end
                end

                removeFace()

                local mesh = Instance.new("SpecialMesh")
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = HEADLESS_MESH_ID
                mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
                mesh.Parent = head

                head:GetPropertyChangedSignal("Transparency"):Connect(
                    function()
                        if head.Transparency ~= 1 then
                            head.Transparency = 1
                        end
                    end
                )

                head.ChildAdded:Connect(
                    function(child)
                        if child.Name == "face" and child:IsA("Decal") then
                            child:Destroy()
                        end
                    end
                )
            end

            local function applyCharacter(character)
                local head = character:WaitForChild("Head", 9e9)
                if head then
                    applyHeadless(head)
                end
            end

            local function applyToLocalPlayer()
                if player.Character then
                    applyCharacter(player.Character)
                end
            end

            
            player.CharacterAdded:Connect(
                function(character)
                    applyCharacter(character)
                end
            )

            applyToLocalPlayer()
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Desync",
        Description = "Can be used as Semi-Immortal",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Desync-Playground-Desync-V1-script-63594"))()
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Avatar Changer",
        Description = "Makes your avatar cooler.",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/darkdexv2/universalavatarchanger/main/avatarchanger"))()
        end
    }
)
    
 Tabs.Extension:AddSection("Camera Extension")

Tabs.Extension:AddButton(
    {
        Title = "Touch Sensitivity",
        Description = "",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/RkgRJhck"))()
        end
    }
)

Tabs.Extension:AddSection("Shader Extension")

local function ClearLighting()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name ~= "MenuBlur" then
            child:Destroy()
        end
    end
end

Tabs.Extension:AddButton(
    {
        Title = "Day",
        Description = "",
        Callback = function()
            ClearLighting()

            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0.568627, 0.501961, 0.372549)
            Lighting.Brightness = 3.130000114440918
            Lighting.ClockTime = 14.5
            Lighting.ExposureCompensation = 0
            Lighting.FogColor = Color3.new(0.572549, 0.815686, 1)
            Lighting.FogEnd = 3000
            Lighting.FogStart = 300
            Lighting.GlobalShadows = true
            Lighting.GeographicLatitude = 143
            Lighting.EnvironmentDiffuseScale = 0.5830000042915344
            Lighting.EnvironmentSpecularScale = 1
            Lighting.ShadowSoftness = 0.03999999910593033
            Lighting.ColorShift_Top = Color3.new(0.737255, 0.552941, 0.00392157)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            Lighting.Technology = Enum.Technology.ShadowMap
            Lighting.TimeOfDay = "14:30:00"

            local Sky = Instance.new("Sky")
            Sky.Name = "Sky"
            Sky.SkyboxBk = "rbxassetid://6444884337"
            Sky.SkyboxDn = "rbxassetid://6444884785"
            Sky.SkyboxFt = "rbxassetid://6444884337"
            Sky.SkyboxLf = "rbxassetid://6444884337"
            Sky.SkyboxRt = "rbxassetid://6444884337"
            Sky.SkyboxUp = "rbxassetid://6412503613"
            Sky.MoonAngularSize = 11
            Sky.SunAngularSize = 11
            Sky.MoonTextureId = "rbxassetid://6444320592"
            Sky.SunTextureId = "rbxassetid://1084351190"
            Sky.StarCount = 0
            Sky.Parent = Lighting

            local Bloom = Instance.new("BloomEffect")
            Bloom.Name = "Bloom"
            Bloom.Enabled = true
            Bloom.Intensity = 1
            Bloom.Threshold = 2
            Bloom.Size = 90
            Bloom.Parent = Lighting

            local ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = "ColorCorrection"
            ColorCorrection.Enabled = true
            ColorCorrection.Brightness = 0.03999999910593033
            ColorCorrection.Contrast = 0.1899999976158142
            ColorCorrection.Saturation = 0.11999999731779099
            ColorCorrection.TintColor = Color3.new(1, 1, 1)
            ColorCorrection.Parent = Lighting
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Sunset",
        Description = "",
        Callback = function()
            ClearLighting()

            Lighting.Ambient = Color3.new(0.67451, 0.67451, 0.67451)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            Lighting.Brightness = 3.799999952316284
            Lighting.ClockTime = 7.099999904632568
            Lighting.ExposureCompensation = -0.23999999463558197
            Lighting.FogColor = Color3.new(0, 0, 0)
            Lighting.FogEnd = 100000000
            Lighting.FogStart = 20
            Lighting.GlobalShadows = true
            Lighting.GeographicLatitude = 72
            Lighting.EnvironmentDiffuseScale = 0.30000001192092896
            Lighting.EnvironmentSpecularScale = 0.05999999865889549
            Lighting.ShadowSoftness = 0.10000000149011612
            Lighting.ColorShift_Top = Color3.new(1, 0.682353, 0.168627)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            Lighting.Technology = Enum.Technology.Future
            Lighting.TimeOfDay = "07:06:00"

            local Sky = Instance.new("Sky")
            Sky.Name = "Sky"
            Sky.CelestialBodiesShown = true
            Sky.SkyboxBk = "rbxassetid://1009082031"
            Sky.SkyboxDn = "rbxassetid://1009082487"
            Sky.SkyboxFt = "rbxassetid://1009082252"
            Sky.SkyboxLf = "rbxassetid://1009082137"
            Sky.SkyboxRt = "rbxassetid://1009081946"
            Sky.SkyboxUp = "rbxassetid://1009082428"
            Sky.MoonAngularSize = 0
            Sky.SunAngularSize = 9
            Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
            Sky.SunTextureId = "rbxasset://sky/sun.jpg"
            Sky.StarCount = 3000
            Sky.Parent = Lighting

            local Bloom = Instance.new("BloomEffect")
            Bloom.Name = "Bloom"
            Bloom.Enabled = true
            Bloom.Intensity = 1
            Bloom.Threshold = 1.8240000009536743
            Bloom.Size = 56
            Bloom.Parent = Lighting

            local SunRays = Instance.new("SunRaysEffect")
            SunRays.Name = "SunRays"
            SunRays.Enabled = true
            SunRays.Intensity = 0.18000000715255737
            SunRays.Spread = 0.11999999731779099
            SunRays.Parent = Lighting

            local ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = "ColorCorrection"
            ColorCorrection.Enabled = true
            ColorCorrection.Brightness = 0
            ColorCorrection.Contrast = 0.10000000149011612
            ColorCorrection.Saturation = -0.20000000298023224
            ColorCorrection.TintColor = Color3.new(1, 1, 1)
            ColorCorrection.Parent = Lighting

            local Atmosphere = Instance.new("Atmosphere")
            Atmosphere.Name = "Atmosphere"
            Atmosphere.Color = Color3.new(0.780392, 0.666667, 0.419608)
            Atmosphere.Density = 0.41999998688697815
            Atmosphere.Offset = 0
            Atmosphere.Glare = 0
            Atmosphere.Haze = 0
            Atmosphere.Parent = Lighting
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Shore",
        Description = "",
        Callback = function()
            ClearLighting()

            Lighting.Ambient = Color3.new(0.427451, 0.458824, 0.529412)
            Lighting.OutdoorAmbient = Color3.new(0.141176, 0.184314, 0.227451)
            Lighting.Brightness = 1.9210000038146973
            Lighting.ClockTime = -6.399722099304199
            Lighting.ExposureCompensation = -0.20000000298023224
            Lighting.FogColor = Color3.new(0.752941, 0.752941, 0.752941)
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.GlobalShadows = true
            Lighting.GeographicLatitude = 0
            Lighting.EnvironmentDiffuseScale = 0.1720000058412552
            Lighting.EnvironmentSpecularScale = 0.6380000114440918
            Lighting.ShadowSoftness = 0.25
            Lighting.ColorShift_Top = Color3.new(0.886275, 0.294118, 0)
            Lighting.ColorShift_Bottom = Color3.new(0.972549, 0.647059, 0.623529)
            Lighting.Technology = Enum.Technology.ShadowMap
            Lighting.TimeOfDay = "-06:23:59"

            local Sky = Instance.new("Sky")
            Sky.Name = "Sky"
            Sky.CelestialBodiesShown = true
            Sky.SkyboxBk = "rbxassetid://88585370973398"
            Sky.SkyboxDn = "rbxassetid://128014535205529"
            Sky.SkyboxFt = "rbxassetid://85323615042244"
            Sky.SkyboxLf = "rbxassetid://77415797450913"
            Sky.SkyboxRt = "rbxassetid://127566931602371"
            Sky.SkyboxUp = "rbxassetid://102320981098060"
            Sky.MoonAngularSize = 0
            Sky.SunAngularSize = 4
            Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
            Sky.SunTextureId = "rbxasset://sky/sun.jpg"
            Sky.StarCount = 5000
            Sky.Parent = Lighting

            local SunRays = Instance.new("SunRaysEffect")
            SunRays.Name = "SunRays"
            SunRays.Enabled = true
            SunRays.Intensity = 0.024000000208616257
            SunRays.Spread = 0.46299999952316284
            SunRays.Parent = Lighting

            local Bloom = Instance.new("BloomEffect")
            Bloom.Name = "Bloom"
            Bloom.Enabled = true
            Bloom.Intensity = 1
            Bloom.Threshold = 2.2911999225616455
            Bloom.Size = 50
            Bloom.Parent = Lighting

            local ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = "ColorCorrection"
            ColorCorrection.Enabled = true
            ColorCorrection.Brightness = 0
            ColorCorrection.Contrast = 0.20000000298023224
            ColorCorrection.Saturation = 0
            ColorCorrection.TintColor = Color3.new(1, 1, 1)
            ColorCorrection.Parent = Lighting

            local Atmosphere = Instance.new("Atmosphere")
            Atmosphere.Name = "Atmosphere"
            Atmosphere.Color = Color3.new(1, 0.847059, 0.760784)
            Atmosphere.Density = 0.35899999737739563
            Atmosphere.Offset = 0
            Atmosphere.Glare = 2.9700000286102295
            Atmosphere.Haze = 1.5199999809265137
            Atmosphere.Parent = Lighting

            local Blur = Instance.new("BlurEffect")
            Blur.Name = "Blur"
            Blur.Size = 4
            Blur.Parent = Lighting
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Cloudy",
        Description = "",
        Callback = function()
            ClearLighting()

            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0.34902, 0.266667, 0.184314)
            Lighting.Brightness = 5.630000114440918
            Lighting.ClockTime = 17.628889083862305
            Lighting.ExposureCompensation = 0.6299999952316284
            Lighting.FogColor = Color3.new(0.572549, 0.815686, 1)
            Lighting.FogEnd = 3000
            Lighting.FogStart = 300
            Lighting.GlobalShadows = true
            Lighting.GeographicLatitude = 21.58930015563965
            Lighting.EnvironmentDiffuseScale = 0.5830000042915344
            Lighting.EnvironmentSpecularScale = 1
            Lighting.ShadowSoftness = 0.03999999910593033
            Lighting.ColorShift_Top = Color3.new(0.811765, 0.447059, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            Lighting.Technology = Enum.Technology.ShadowMap
            Lighting.TimeOfDay = "17:37:44"

            local Sky = Instance.new("Sky")
            Sky.Name = "Sky"
            Sky.CelestialBodiesShown = true
            Sky.SkyboxBk = "rbxassetid://2177969403"
            Sky.SkyboxDn = "rbxassetid://2177972406"
            Sky.SkyboxFt = "rbxassetid://2177970251"
            Sky.SkyboxLf = "rbxassetid://2177969836"
            Sky.SkyboxRt = "rbxassetid://2177968823"
            Sky.SkyboxUp = "rbxassetid://2177971305"
            Sky.MoonAngularSize = 1.5
            Sky.SunAngularSize = 3
            Sky.MoonTextureId = "rbxassetid://1075087760"
            Sky.SunTextureId = "rbxasset://sky/sun.jpg"
            Sky.StarCount = 500
            Sky.Parent = Lighting

            local Bloom = Instance.new("BloomEffect")
            Bloom.Name = "Bloom"
            Bloom.Enabled = true
            Bloom.Intensity = 1
            Bloom.Threshold = 2
            Bloom.Size = 90
            Bloom.Parent = Lighting

            local ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = "ColorCorrection"
            ColorCorrection.Enabled = true
            ColorCorrection.Brightness = 0.03999999910593033
            ColorCorrection.Contrast = 0.15000000596046448
            ColorCorrection.Saturation = 0.20000000298023224
            ColorCorrection.TintColor = Color3.new(1, 1, 1)
            ColorCorrection.Parent = Lighting

            local SunRays = Instance.new("SunRaysEffect")
            SunRays.Name = "SunRays"
            SunRays.Enabled = true
            SunRays.Intensity = 0.004000000189989805
            SunRays.Spread = 0.16699999570846558
            SunRays.Parent = Lighting

            local Atmosphere = Instance.new("Atmosphere")
            Atmosphere.Name = "Atmosphere"
            Atmosphere.Color = Color3.new(0.647059, 0.647059, 0.647059)
            Atmosphere.Density = 0.3569999933242798
            Atmosphere.Offset = 0
            Atmosphere.Glare = 0.20999999344348907
            Atmosphere.Haze = 1.4600000381469727
            Atmosphere.Parent = Lighting
        end
    }
)

Tabs.Extension:AddButton(
    {
        Title = "Night",
        Description = "",
        Callback = function()
            ClearLighting()

            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            Lighting.Brightness = 2
            Lighting.ClockTime = 3
            Lighting.ExposureCompensation = 0
            Lighting.FogColor = Color3.new(0, 0, 0)
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.GlobalShadows = true
            Lighting.GeographicLatitude = 41.733001708984375
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0.20000000298023224
            Lighting.ColorShift_Top = Color3.new(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            Lighting.Technology = Enum.Technology.Future
            Lighting.TimeOfDay = "03:00:00"

            local Sky = Instance.new("Sky")
            Sky.Name = "Sky"
            Sky.CelestialBodiesShown = true
            Sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
            Sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
            Sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
            Sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
            Sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
            Sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
            Sky.MoonAngularSize = 11
            Sky.SunAngularSize = 21
            Sky.MoonTextureId = "rbxasset://sky/moon.jpg"
            Sky.SunTextureId = "rbxasset://sky/sun.jpg"
            Sky.StarCount = 5000
            Sky.Parent = Lighting

            local Blur = Instance.new("BlurEffect")
            Blur.Name = "Blur"
            Blur.Enabled = true
            Blur.Size = 0
            Blur.Parent = Lighting

            local Atmosphere = Instance.new("Atmosphere")
            Atmosphere.Name = "Atmosphere"
            Atmosphere.Color = Color3.new(0, 0, 0)
            Atmosphere.Density = 0.5600000023841858
            Atmosphere.Offset = 0
            Atmosphere.Glare = 0
            Atmosphere.Haze = 0
            Atmosphere.Parent = Lighting
        end
    }
)

Tabs.Extension:AddSection("Lightning Extension")

local normalLighting = {
    Ambient = Lighting.Ambient,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness
}

local function applyFullBright()
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
end

local function restoreLighting()
    for prop, value in pairs(normalLighting) do
        Lighting[prop] = value
    end
end

local Fullbrighting = false

local Toggle = Tabs.Extension:AddToggle("FullBright", {Title = "Full Bright", Default = false})

Toggle:OnChanged(
    function(state)
        Fullbrighting = state
        if Fullbrighting then
            applyFullBright()
        else
            restoreLighting()
        end
    end
)

Tabs.Extension:AddSection("Anti Lags Extension")

local Lag1 = false

local Toggle = Tabs.Extension:AddToggle("Anti_Lag1", {Title = "Anti Lag 1", Default = false})

Toggle:OnChanged(
    function(Value1)
        Lag1 = Value1
        if Lag1 then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                    v.Material = Enum.Material.SmoothPlastic
                    if v:IsA("Texture") then
                        v:Destroy()
                    end
                end
            end
        end
    end
)

local Toggle = Tabs.Extension:AddToggle("Anti_Lag2", {Title = "Anti Lag 2", Default = false})

Toggle:OnChanged(
    function(Value3)
        if Value3 then
            local decalsyeeted = true -- Leaving this on makes games look shitty but the fps goes up by at least 20.
            local g = game
            local w = g.Workspace
            local l = g.Lighting
            local t = w.Terrain
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 0
            l.GlobalShadows = false
            l.FogEnd = 9e9
            l.Brightness = 0
            settings().Rendering.QualityLevel = "Level01"
            wait(1)
            for i, v in pairs(g:GetDescendants()) do
                if v:IsA("Part") or v:IsA("Union") or v:IsA("MeshPart") then
                    v.Material = "Plastic"
                    v.Reflectance = 0
                elseif v:IsA("Decal") and decalsyeeted then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                end
            end
        end
    end
)

local Toggle = Tabs.Extension:AddToggle("Anti_Lag3", {Title = "Anti Lag 3", Default = false})

Toggle:OnChanged(
    function(Value4)
        if Value4 then
            local decalsyeeted = true
            local g = game
            local w = g.Workspace
            local l = g.Lighting
            local t = w.Terrain
            sethiddenproperty(l, "Technology", 2)
            sethiddenproperty(t, "Decoration", false)
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 0
            l.GlobalShadows = 0
            l.FogEnd = 9e9
            l.Brightness = 0
            settings().Rendering.QualityLevel = "Level01"
            for i, v in pairs(w:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsA("MeshPart") then
                    v.Material = "Plastic"
                    v.Reflectance = 0
                elseif (v:IsA("Decal") or v:IsA("Texture")) and decalsyeeted then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                elseif v:IsA("Explosion") then
                    v.BlastPressure = 1
                    v.BlastRadius = 1
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                elseif v:IsA("MeshPart") and decalsyeeted then
                    v.Material = "Plastic"
                    v.Reflectance = 0
                    v.TextureID = 10385902758728957
                elseif v:IsA("SpecialMesh") and decalsyeeted then
                    v.TextureId = 0
                elseif v:IsA("ShirtGraphic") and decalsyeeted then
                    v.Graphic = 0
                elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
                    v[v.ClassName .. "Template"] = 0
                end
            end
            for i = 1, #l:GetChildren() do
                e = l:GetChildren()[i]
                if
                    e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or
                        e:IsA("BloomEffect") or
                        e:IsA("DepthOfFieldEffect")
                 then
                    e.Enabled = false
                end
            end
            w.DescendantAdded:Connect(
                function(v)
                    wait(1)
                    if v:IsA("BasePart") and not v:IsA("MeshPart") then
                        v.Material = "Plastic"
                        v.Reflectance = 0
                    elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        v.Lifetime = NumberRange.new(0)
                    elseif v:IsA("Explosion") then
                        v.BlastPressure = 1
                        v.BlastRadius = 1
                    elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                        v.Enabled = false
                    elseif v:IsA("MeshPart") and decalsyeeted then
                        v.Material = "Plastic"
                        v.Reflectance = 0
                        v.TextureID = 10385902758728957
                    elseif v:IsA("SpecialMesh") and decalsyeeted then
                        v.TextureId = 0
                    elseif v:IsA("ShirtGraphic") and decalsyeeted then
                        v.ShirtGraphic = 0
                    elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
                        v[v.ClassName .. "Template"] = 0
                    end
                end
            )
        end
    end
)

Tabs.Extension:AddSection("Fast Flag Extension")

if setfflag then
    Tabs.Extension:AddButton(
        {
            Title = "Blox Strap Script",
            Description = "",
            Callback = function()
                getgenv().autosetup = {
				    path = 'Bloxstrap', --> doesnt work rn
				    setup = true --> init after installaiton
				}

				loadstring(game.HttpGet(game, 'https://raw.githubusercontent.com/new-qwertyui/Bloxstrap/refs/heads/main/Main/Bloxstrap.lua', true))()
            end
        }
    )
    
    Tabs.Extension:AddButton(
        {
            Title = "Accurate Low Quality",
            Description = "(FastFlag)",
            Callback = function()
                -- made by guesttester_1 (pls credit to me)
                -- i forgot to add remove textures script

                setfpscap(900) -- normal fps cap for other executors

                setfflag("TaskSchedulerTargetFps", "900") -- for setfpscap unc missing or unsupported for executors

                local function removeWater()
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("Terrain") then
                            obj.WaterTransparency = 1
                            obj.WaterWaveSize = 0
                            obj.WaterWaveSpeed = 0
                            obj.WaterReflectance = 0
                        end
                    end
                end

                local function removeReflections()
                    local lighting = game:GetService("Lighting")
                    lighting.EnvironmentSpecularScale = 0
                    lighting.EnvironmentDiffuseScale = 0
                end

                local function removeEffects()
                    for _, effect in pairs(workspace:GetDescendants()) do
                        if
                            effect:IsA("ParticleEmitter") or effect:IsA("Smoke") or effect:IsA("Fire") or
                                effect:IsA("Sparkles")
                         then
                            effect.Enabled = false
                        end
                    end
                end

                local function removeGrass()
                    setfflag("FRMMinGrassDistance", "0")
                    setfflag("FRMMaxGrassDistance", "0")
                    setfflag("RenderGrassDetailStrands", "0")
                end

                local function removeExplosions()
                    for _, explosion in pairs(workspace:GetDescendants()) do
                        if explosion:IsA("Explosion") then
                            explosion:Destroy()
                        end
                    end
                end

                local function setLowShadows()
                    game.Lighting.Technology = Enum.Technology.Voxel
                    game.Lighting.GlobalShadows = false
                end

                local function setLowQuality()
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                end

                local function setFlagsGraphics()
                    setfflag("DebugGraphicsPreferVulkan", "true")
                    setfflag("DebugTextureManagerSkipMips", "2")
                    setfflag("TaskSchedulerLimitTargetFpsTo2402", "false")
                    setfflag("TaskSchedulerTargetFps", "900")
                end

                local function reduceLag()
                    removeWater()
                    removeReflections()
                    --    removeEffects()
                    --    removeExplosions()
                    setLowShadows()
                    setLowQuality()
                    setFlagsGraphics()
                    removeGrass()
                end

                reduceLag()

                workspace.DescendantAdded:Connect(
                    function(descendant)
                        if descendant:IsA("Terrain") then
                            wait(0.5)
                            reduceLag()
                        end
                    end
                )
            end
        }
    )
end

Tabs.Extension:AddSection("Network Replication")

if not getgenv().CurrentServerPing then
   getgenv().CurrentServerPing = 0
   
   spawn(function()
        while true do
           getgenv().CurrentServerPing = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
           RunService.PreSimulation:Wait()
        end
    end)
end

local ServerDesync = Instance.new("Part")
ServerDesync.Size = Vector3.new(2, 5, 1)
ServerDesync.Anchored = true
ServerDesync.CanCollide = false
ServerDesync.Material = Enum.Material.ForceField
ServerDesync.Color = Color3.fromRGB(255, 100, 100)
ServerDesync.Parent = workspace

local ClientDesync = ServerDesync:Clone()
ClientDesync.Color = Color3.fromRGB(100, 150, 255)
ClientDesync.Parent = workspace

local serverHistory, clientHistory = {}, {}
local ServerDsync, ClientDsync

local function clampHistory(history, max)
    while #history > max do
        table.remove(history, 1)
    end
end

local function findClosest(history, targetTime)
    local closest, smallestDiff = history[1], math.huge
    for _, data in ipairs(history) do
        local diff = math.abs(data.t - targetTime)
        if diff < smallestDiff then
            smallestDiff, closest = diff, data
        end
    end
    return closest
end

local function getAdaptiveExaggeration(ping_ms)
    local MIN_EXAG = 1.5
    local MAX_EXAG = 6
    local REFERENCE_PING = 90

    local scale = REFERENCE_PING / math.max(ping_ms, 1)
    return math.clamp(MAX_EXAG * scale, MIN_EXAG, MAX_EXAG)
end

local Toggle = Tabs.Extension:AddToggle("ServerDesync", {Title = "Show Character Position (Server Ping)", Default = false})
Toggle:OnChanged(function(enabled)
    ServerDesync.Transparency = enabled and 0 or 1

    if enabled then
        ServerDsync = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart

            table.insert(serverHistory, {cf = root.CFrame, t = workspace:GetServerTimeNow()})
            clampHistory(serverHistory, 2000)

            local ping_ms = getgenv().CurrentServerPing or (LocalPlayer:GetNetworkPing() * 1000)
            local exaggeration = getAdaptiveExaggeration(ping_ms)
            local targetTime = workspace:GetServerTimeNow() - ((ping_ms / 1000) * exaggeration)

            local snapshot = findClosest(serverHistory, targetTime)
            if snapshot then
                ServerDesync.CFrame = ServerDesync.CFrame:Lerp(snapshot.cf, 0.25)
            end
        end)
    else
        if ServerDsync then ServerDsync:Disconnect() end
        ServerDsync, serverHistory = nil, {}
    end
end)

local Toggle2 = Tabs.Extension:AddToggle("ClientDesync", {Title = "Show Character Position (Client Ping)", Default = false})
Toggle2:OnChanged(function(enabled)
    ClientDesync.Transparency = enabled and 0 or 1

    if enabled then
        ClientDsync = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local now = os.clock()

            table.insert(clientHistory, {cf = root.CFrame, t = now})
            clampHistory(clientHistory, 2000)

            local ping_ms = LocalPlayer:GetNetworkPing() * 1000
            local exaggeration = getAdaptiveExaggeration(ping_ms)
            local targetTime = now - ((ping_ms / 1000) * exaggeration)

            local snapshot = findClosest(clientHistory, targetTime)
            if snapshot then
                ClientDesync.CFrame = ClientDesync.CFrame:Lerp(snapshot.cf, 0.25)
            end
        end)
    else
        if ClientDsync then ClientDsync:Disconnect() end
        ClientDsync, clientHistory = nil, {}
    end
end)

RunService.Heartbeat:Connect(function()
    local stop = false
    
    if DConfiguration.Main.Noclip then
	    spawn(DFunctions.Noclip)
    end
    
    if DConfiguration.Misc.GameAutomation.Revive.FloatingButton or DConfiguration.Misc.GameAutomation.Revive.Keybind then
        spawn(DFunctions.InstantRevive)
    end
       
    if DConfiguration.Misc.GameAutomation.Carry.FloatingButton or DConfiguration.Misc.GameAutomation.Carry.Keybind then
        spawn(DFunctions.CarryPlayer)
    end
    
    if DConfiguration.Misc.MovementModification.Gravity.FloatingButton or DConfiguration.Misc.MovementModification.Gravity.Keybind then
        game.Workspace.Gravity = DConfiguration.Misc.MovementModification.Gravity.Value
    else
        game.Workspace.Gravity = NormalGravity
    end

    if DConfiguration.Misc.MovementModification.BHOP.Enabled or DConfiguration.Misc.MovementModification.BHOP.Keybind or DConfiguration.Misc.MovementModification.BHOP.HoldKeybind then
        task.spawn(DFunctions.BHOPFunction)
        stop = true
    end
    
    if DConfiguration.Misc.MovementModification.Crouch.FloatingButton or DConfiguration.Misc.MovementModification.Crouch.Keybind then
        task.spawn(DFunctions.CrouchFunction)
        stop = true
    end

    if not stop then
        if DConfiguration.Misc.MovementModification.AggressiveEmoteDash.Enabled then
            task.spawn(DFunctions.AggressiveEmoteDashFunction)
        end
        
        if DConfiguration.Misc.MovementModification.SlideModification.Enabled then
            task.spawn(DFunctions.InfiniteSlideFunction)
        end
    end
    
    RunService.RenderStepped:Wait()
end)

local IsPCMode = false

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "Shared" then
        IsCurrentPlaying = true
    end
end)

if UserInputService.TouchEnabled then
    local returnValues = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Character"):WaitForChild("CharacterTable"):WaitForChild("CharacterController"):WaitForChild("Local"):WaitForChild("Movement"):WaitForChild("returnValues"))
	local old = returnValues.new        
        
	returnValues.new = function(...)
		local result = {old(...)}
		
		task.delay(1, function()
			table.clear(CurrentAdjustment)

			local unpacked = table.unpack(result)
			for i, v in pairs(unpacked) do
				if i == "overrideMovementStats" or i == "defaultMovementStats" then
					table.insert(CurrentAdjustment, v)
				end
			end

			if #CurrentAdjustment > 0 then
				DFunctions.SetPreviousAdjustment()
			end
		end)

		return table.unpack(result)
	end
else
	IsPCMode = true
end

local lastRespawn = 0
local debounceDuration = 1

LocalPlayer.CharacterAdded:Connect(function(character)
    local Map = Workspace.Game:WaitForChild("Map", 9e9)
	local Stats = Workspace.Game:WaitForChild("Stats", 9e9)
	local Settings = Workspace.Game:WaitForChild("Settings", 9e9)
	
	if DConfiguration.AutoFarm.VIPAutomations.AutoMap and Map and Map:GetAttribute("Map") == DConfiguration.AutoFarm.VIPAutomations.MapInput then
	   DFunctions.SetVIPCommands(DConfiguration.AutoFarm.VIPAutomations.MapInput, nil)
	end
	
	if DConfiguration.AutoFarm.VIPAutomations.AutoSpecialRound and Stats and not Stats:GetAttribute("NextSpecialRound") then
		DFunctions.SetVIPCommands(nil, DConfiguration.AutoFarm.VIPAutomations.SpecialRoundInput)
	end
	
	if DConfiguration.AutoFarm.VIPAutomations.AutoTimer then
		DFunctions.SetVIPCommands(nil, nil, DConfiguration.AutoFarm.VIPAutomations.TimerInput)
	end
	
	if DConfiguration.AutoFarm.VIPAutomations.AutoProMode and Settings and Settings:GetAttribute("Gamemode") ~= "Pro" then
	    ReplicatedStorage.Events.CustomServers.Admin:FireServer("Gamemode", "Pro")
	    wait(3)
	    game:GetService("ReplicatedStorage").Events.Player.ChangePlayerMode:FireServer(true)
	end
	
	lastRespawn = tick()
	IsCurrentPlaying = true

	task.delay(3, function()
		if IsPCMode and LocalPlayer.Character then
			table.clear(CurrentAdjustment)
			DFunctions.GetAdjustments()
			task.wait(1)
			if #CurrentAdjustment > 0 then
				DFunctions.SetPreviousAdjustment()
			end
		end

		if tick() - lastRespawn >= debounceDuration then
		    repeat task.wait(1) until LocalPlayer.PlayerGui:FindFirstChild("Shared")
		    DFunctions.RestoreEmoteChanges()
		end
	end)

	character.Destroying:Connect(function()
		if IsCurrentPlaying then
			IsCurrentPlaying = false
			DFunctions.ResetEmoteChanges()
		end
	end)
end)

if LocalPlayer.Character then
    DFunctions.GetAdjustments()
    IsCurrentPlaying = true
end

spawn(function()
	while task.wait(0.1) do
		if #CurrentAdjustment > 0 then
			DFunctions.setTSpeed(DConfiguration.Misc.PlayerAdjustment.Update.Speed)
			DFunctions.setStrafeAcceleration(DConfiguration.Misc.PlayerAdjustment.Update.AirStrafe)
			DFunctions.setTJump(DConfiguration.Misc.PlayerAdjustment.Update.JumpHeight)
			DFunctions.setTJumpCap(DConfiguration.Misc.PlayerAdjustment.Update.JumpCap)
			DFunctions.setTFriction(DConfiguration.Misc.PlayerAdjustment.Update.GroundAcceleration)
			DFunctions.setTJumpAcceleration(DConfiguration.Misc.PlayerAdjustment.Update.JumpAcceleration)
		end
	end
end) 
