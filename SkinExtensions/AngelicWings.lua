local p = game.Players.LocalPlayer
local assetId = 192557913

local function l(a, _)
    local b = Instance.new("Weld")
    b.Part0 = a.Parent
    b.Part1 = _.Parent
    b.C0 = a.CFrame
    b.C1 = _.CFrame
    b.Parent = a.Parent
end

local function _weld(_, a, b, d, c, e)
    local f = Instance.new("Weld")
    f.Name = _
    f.Part0 = b
    f.Part1 = d
    f.C0 = c
    f.C1 = e
    f.Parent = a
end

local function findAtt(_, b)
    for _, obj in pairs(_:GetChildren()) do
        if obj:IsA("Attachment") and obj.Name == b then
            return obj
        elseif not obj:IsA("Accoutrement") and not obj:IsA("Tool") then
            local res = findAtt(obj, b)
            if res then return res end
        end
    end
end

local function k(e, c)
    c.Parent = e
    local d = c:FindFirstChild("Handle")
    if d then
        local b = d:FindFirstChildOfClass("Attachment")
        if b then
            local att = findAtt(e, b.Name)
            if att then l(att, b) end
        else
            local head = e:FindFirstChild("Head")
            if head then
                _weld("HeadWeld", head, head, d, CFrame.new(0, 0.5, 0), c.AttachmentPoint)
            end
        end
    end
end

task.spawn(function()
    while true do
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if not char:FindFirstChild("AngelicWings_Grib") then
                local success, model = pcall(function()
                    return game:GetObjects("rbxassetid://" .. assetId)[1]
                end)
                if success and model then
                    model.Name = "AngelicWings_Grib"
                    k(char, model)
                end
            end
        end
        task.wait(2.9)
    end
end)