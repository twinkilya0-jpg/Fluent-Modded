local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    MIN_SENSITIVITY = 0.1,
    MAX_SENSITIVITY = 10,
    DEFAULT_SENSITIVITY = 1,
    SAVE_FOLDER = "TouchSensitivity",
    SAVE_FILE = "settings.txt"
}

local hasFileSystem = pcall(function() 
    return isfolder and makefolder and isfile and readfile and writefile 
end)

local currentSensitivity = CONFIG.DEFAULT_SENSITIVITY
local originalMouseDelta = nil
local cameraInputModule = nil
local hookActive = false

if hasFileSystem then
    pcall(function()
        if not isfolder(CONFIG.SAVE_FOLDER) then
            makefolder(CONFIG.SAVE_FOLDER)
        end
        
        local filePath = CONFIG.SAVE_FOLDER .. "/" .. CONFIG.SAVE_FILE
        if isfile(filePath) then
            local saved = tonumber(readfile(filePath))
            if saved then
                currentSensitivity = saved
            end
        end
    end)
end

local function setupCameraHook()
    local success = false
    
    pcall(function()
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        
        local playerModule = playerScripts:FindFirstChild("PlayerModule")
        if not playerModule then return end
        
        local cameraModule = playerModule:FindFirstChild("CameraModule")
        if cameraModule then
            local cameraInput = cameraModule:FindFirstChild("CameraInput")
            if cameraInput then
                cameraInputModule = require(cameraInput)
                if cameraInputModule and cameraInputModule.getRotation then
                    local originalGetRotation = cameraInputModule.getRotation
                    cameraInputModule.getRotation = function(disableRotation)
                        local rotation = originalGetRotation(disableRotation)
                        if UserInputService.TouchEnabled then
                            return rotation * currentSensitivity
                        end
                        return rotation
                    end
                    success = true
                    hookActive = true
                end
            end
        end
    end)
    
    if not success then
        pcall(function()
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", function(self, key)
                if self == UserInputService and key == "MouseDelta" and UserInputService.TouchEnabled then
                    local original = oldIndex(self, key)
                    return original * currentSensitivity
                end
                return oldIndex(self, key)
            end)
            success = true
            hookActive = true
        end)
    end
    
    if not success then
        RunService.RenderStepped:Connect(function()
            if UserInputService.TouchEnabled then
            end
        end)
    end
    
    return success
end

local cameraHooked = setupCameraHook()

local function createGUI()
    local existingGui = playerGui:FindFirstChild("TouchSensitivityGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TouchSensitivityGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 140)
    mainFrame.Position = UDim2.new(0.5, -100, 0, 30)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 25)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 8)
    titleFix.Position = UDim2.new(0, 0, 1, -8)
    titleFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "📱 Touch Sensitivity"
    titleLabel.Size = UDim2.new(1, -30, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local statusIndicator = Instance.new("Frame")
    statusIndicator.Size = UDim2.new(0, 8, 0, 8)
    statusIndicator.Position = UDim2.new(0, 167, 0, 8.5)
    statusIndicator.BackgroundColor3 = hookActive and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = titleBar
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusIndicator

    local collapseButton = Instance.new("TextButton")
    collapseButton.Text = "−"
    collapseButton.Size = UDim2.new(0, 25, 0, 25)
    collapseButton.Position = UDim2.new(1, -25, 0, 0)
    collapseButton.BackgroundTransparency = 1
    collapseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseButton.TextSize = 18
    collapseButton.Font = Enum.Font.SourceSansBold
    collapseButton.Parent = titleBar

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -35)
    contentFrame.Position = UDim2.new(0, 10, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local currentValueLabel = Instance.new("TextLabel")
    currentValueLabel.Text = string.format("Current: %.1f", currentSensitivity)
    currentValueLabel.Size = UDim2.new(1, 0, 0, 20)
    currentValueLabel.Position = UDim2.new(0, 0, 0, 0)
    currentValueLabel.BackgroundTransparency = 1
    currentValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    currentValueLabel.TextSize = 12
    currentValueLabel.Font = Enum.Font.SourceSans
    currentValueLabel.Parent = contentFrame

    local sliderContainer = Instance.new("Frame")
    sliderContainer.Size = UDim2.new(1, 0, 0, 30)
    sliderContainer.Position = UDim2.new(0, 0, 0, 22)
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Parent = contentFrame

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, 0, 0, 4)
    sliderTrack.Position = UDim2.new(0, 0, 0.5, -2)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = sliderContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 2)
    trackCorner.Parent = sliderTrack

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0.1, 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = sliderFill

    local sliderButton = Instance.new("TextButton")
    sliderButton.Text = ""
    sliderButton.Size = UDim2.new(0, 14, 0, 14)
    sliderButton.Position = UDim2.new(0.1, -7, 0.5, -7)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.BorderSizePixel = 0
    sliderButton.AutoButtonColor = false
    sliderButton.Parent = sliderContainer

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = sliderButton

    local minLabel = Instance.new("TextLabel")
    minLabel.Text = tostring(CONFIG.MIN_SENSITIVITY)
    minLabel.Size = UDim2.new(0, 25, 1, 0)
    minLabel.Position = UDim2.new(0, -28, 0, 0)
    minLabel.BackgroundTransparency = 1
    minLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    minLabel.TextSize = 10
    minLabel.Font = Enum.Font.SourceSans
    minLabel.Parent = sliderContainer

    local maxLabel = Instance.new("TextLabel")
    maxLabel.Text = tostring(CONFIG.MAX_SENSITIVITY)
    maxLabel.Size = UDim2.new(0, 25, 1, 0)
    maxLabel.Position = UDim2.new(1, 3, 0, 0)
    maxLabel.BackgroundTransparency = 1
    maxLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    maxLabel.TextSize = 10
    maxLabel.Font = Enum.Font.SourceSans
    maxLabel.Parent = sliderContainer

    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 25)
    inputContainer.Position = UDim2.new(0, 0, 0, 55)
    inputContainer.BackgroundTransparency = 1
    inputContainer.Parent = contentFrame

    local inputLabel = Instance.new("TextLabel")
    inputLabel.Text = "Custom:"
    inputLabel.Size = UDim2.new(0, 45, 1, 0)
    inputLabel.Position = UDim2.new(0, 0, 0, 0)
    inputLabel.BackgroundTransparency = 1
    inputLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    inputLabel.TextSize = 11
    inputLabel.Font = Enum.Font.SourceSans
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = inputContainer

    local inputBox = Instance.new("TextBox")
    inputBox.Text = tostring(currentSensitivity)
    inputBox.Size = UDim2.new(0, 70, 1, 0)
    inputBox.Position = UDim2.new(0, 48, 0, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inputBox.BorderSizePixel = 0
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.TextSize = 11
    inputBox.Font = Enum.Font.SourceSans
    inputBox.ClearTextOnFocus = false
    inputBox.PlaceholderText = "Number"
    inputBox.Parent = inputContainer

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputBox

    local applyButton = Instance.new("TextButton")
    applyButton.Text = "Apply"
    applyButton.Size = UDim2.new(0, 45, 1, 0)
    applyButton.Position = UDim2.new(1, -45, 0, 0)
    applyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    applyButton.BorderSizePixel = 0
    applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyButton.TextSize = 11
    applyButton.Font = Enum.Font.SourceSansBold
    applyButton.Parent = inputContainer

    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 4)
    applyCorner.Parent = applyButton

    local resetButton = Instance.new("TextButton")
    resetButton.Text = "Reset"
    resetButton.Size = UDim2.new(0, 45, 0, 20)
    resetButton.Position = UDim2.new(0.5, -22.5, 0, 83)
    resetButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    resetButton.BorderSizePixel = 0
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextSize = 11
    resetButton.Font = Enum.Font.SourceSans
    resetButton.Parent = contentFrame

    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 4)
    resetCorner.Parent = resetButton

    local isDraggingSlider = false
    local collapsed = false
    local expandedSize = mainFrame.Size
    
    local function saveSettings(value)
        if hasFileSystem then
            pcall(function()
                writefile(CONFIG.SAVE_FOLDER .. "/" .. CONFIG.SAVE_FILE, tostring(value))
            end)
        end
    end

    local function formatValue(value)
        return math.floor(value * 10 + 0.5) / 10
    end

    local function applySensitivity(value, fromSlider)
        currentSensitivity = value
        saveSettings(value)
        
        local displayValue = fromSlider and formatValue(value) or value
        currentValueLabel.Text = string.format("Current: %.1f", displayValue)
        
        if value >= CONFIG.MIN_SENSITIVITY and value <= CONFIG.MAX_SENSITIVITY then
            local percentage = (value - CONFIG.MIN_SENSITIVITY) / (CONFIG.MAX_SENSITIVITY - CONFIG.MIN_SENSITIVITY)
            sliderButton.Position = UDim2.new(percentage, -7, 0.5, -7)
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        end
        
        inputBox.Text = tostring(fromSlider and formatValue(value) or value)
    end

    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = false
        end
    end)

    RunService.Heartbeat:Connect(function()
        if isDraggingSlider then
            local mousePos = UserInputService:GetMouseLocation()
            local trackPos = sliderTrack.AbsolutePosition.X
            local trackSize = sliderTrack.AbsoluteSize.X
            local percentage = math.clamp((mousePos.X - trackPos) / trackSize, 0, 1)
            
            sliderButton.Position = UDim2.new(percentage, -7, 0.5, -7)
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            
            local value = CONFIG.MIN_SENSITIVITY + percentage * (CONFIG.MAX_SENSITIVITY - CONFIG.MIN_SENSITIVITY)
            applySensitivity(value, true)
        end
    end)

    applyButton.MouseButton1Click:Connect(function()
        local value = tonumber(inputBox.Text)
        if value then
            applySensitivity(value, false)
        else
            inputBox.Text = tostring(currentSensitivity)
        end
    end)

    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(inputBox.Text)
            if value then
                applySensitivity(value, false)
            else
                inputBox.Text = tostring(currentSensitivity)
            end
        end
    end)

    resetButton.MouseButton1Click:Connect(function()
        applySensitivity(CONFIG.DEFAULT_SENSITIVITY, false)
    end)

    local dragging = false
    local dragStart = nil
    local startPos = nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    collapseButton.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        
        if collapsed then
            local tween = TweenService:Create(mainFrame, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 25)
            })
            tween:Play()
            collapseButton.Text = "+"
            contentFrame.Visible = false
        else
            contentFrame.Visible = true
            local tween = TweenService:Create(mainFrame, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = expandedSize
            })
            tween:Play()
            collapseButton.Text = "−"
        end
    end)

    applySensitivity(currentSensitivity, false)
    
    return screenGui
end

local gui = createGUI()

if not cameraHooked then
    spawn(function()
        wait(1)
        local notification = Instance.new("TextLabel")
        notification.Text = "Failed"
        notification.Size = UDim2.new(0, 250, 0, 30)
        notification.Position = UDim2.new(0.5, -125, 0, 200)
        notification.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        notification.TextColor3 = Color3.fromRGB(255, 200, 100)
        notification.Font = Enum.Font.SourceSans
        notification.TextSize = 14
        notification.BorderSizePixel = 0
        notification.Parent = gui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 6)
        notifCorner.Parent = notification
        
        wait(2)
        notification:Destroy()
    end)
end