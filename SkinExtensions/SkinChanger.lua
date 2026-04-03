local p = game.Players.LocalPlayer
_G.SavedAccessories = _G.SavedAccessories or {}

local function weldParts(a, b)
    local weld = Instance.new("Weld")
    weld.Part0 = a.Parent
    weld.Part1 = b.Parent
    weld.C0 = a.CFrame
    weld.C1 = b.CFrame
    weld.Parent = a.Parent
end

local function findAtt(parent, name)
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("Attachment") and obj.Name == name then
            return obj
        elseif not obj:IsA("Accoutrement") and not obj:IsA("Tool") then
            local res = findAtt(obj, name)
            if res then return res end
        end
    end
end
local function k(e, c)
    c.Parent = e
    for _, part in pairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
        end
    end
    
    local d = c:FindFirstChild("Handle")
    if d then
        local b = d:FindFirstChildOfClass("Attachment")
        if b then
            local att = findAtt(e, b.Name)
            if att then weldParts(att, b) end
        else
            local head = e:FindFirstChild("Head")
            if head then
                local f = Instance.new("Weld")
                f.Name = "HeadWeld"
                f.Part0 = head; f.Part1 = d
                f.C0 = CFrame.new(0, 0.5, 0); f.C1 = c.AttachmentPoint
                f.Parent = head
            end
        end
    end
end

local function ReapplySkins()
    local char = p.Character or p.CharacterAdded:Wait()
    task.wait(1) 
    for id, _ in pairs(_G.SavedAccessories) do
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)
        if success and result[1] then
            local model = result[1]
            model.Name = "WyrmSkin_" .. id
            k(char, model)
        end
    end
end

local assetId = _G.SavedID
if assetId and p.Character then
    _G.SavedAccessories[assetId] = true
    
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)
    end)
    
    if success and result[1] then
        local model = result[1]
        model.Name = "WyrmSkin_" .. assetId
        k(p.Character, model)
    end
end

if not _G.SkinInited then
    _G.SkinInited = true
    p.CharacterAdded:Connect(ReapplySkins)
end