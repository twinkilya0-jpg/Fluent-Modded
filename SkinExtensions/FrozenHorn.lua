local Players = game:GetService("Players")
local player = Players.LocalPlayer
local assetId = 74891470
local function createWeld(partA, partB)
    local weld = Instance.new("Weld")
    weld.Part0 = partA.Parent
    weld.Part1 = partB.Parent
    weld.C0 = partA.CFrame
    weld.C1 = partB.CFrame
    weld.Parent = partA.Parent
end

local function createNamedWeld(name, parent, p0, p1, c0, c1)
    local weld = Instance.new("Weld")
    weld.Name = name
    weld.Part0 = p0
    weld.Part1 = p1
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = parent
end

local function findBodyPart(parent, partName)
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("BasePart") and child.Name == partName then
            return child
        elseif not child:IsA("Accessory") and not child:IsA("Hat") then
            local found = findBodyPart(child, partName)
            if found then return found end
        end
    end
end

local function equipAccessory(character, accessory)
    accessory.Parent = character
    local handle = accessory:FindFirstChild("Handle")
    
    if handle then
        local weldConstraint = handle:FindFirstChildOfClass("WeldConstraint")
        if weldConstraint then
            local targetPart = findBodyPart(character, weldConstraint.Name)
            if targetPart then
                createWeld(targetPart, weldConstraint)
            end
        else
            local head = character:FindFirstChild("Head")
            if head then
                createNamedWeld("AccessoryWeld", head, head, handle, CFrame.new(0, 0.5, 0), accessory.AttachmentPoint)
            end
        end
    end
end

task.spawn(function()
    while true do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            if not character:FindFirstChild("CustomModel_Accessory") then
                local success, objects = pcall(function()
                    return game:GetObjects("rbxassetid://" .. assetId)
                end)
                
                if success and objects and objects[1] then
                    local model = objects[1]
                    model.Name = "CustomModel_Accessory"
                    equipAccessory(character, model)
                end
            end
        end
        task.wait(2.5)
    end
end)
