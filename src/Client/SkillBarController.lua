-- SkillBarController.lua
-- Debe ir dentro de StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SkillDefinitions = require(sharedFolder:WaitForChild("SkillDefinitions"))

local SkillBar = {
    Slots = {},
    SelectedSlot = nil,
    InventoryOpen = false,
    Inventory = nil,
    Cooldowns = {},
}

local function rounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function createSlotFrame(parent, index)
    local slot = Instance.new("Frame")
    slot.Name = "SkillSlot" .. index
    slot.Size = UDim2.new(0, 100, 0, 100)
    slot.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    slot.BorderSizePixel = 0
    slot.Parent = parent
    rounded(slot, 14)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, -18, 1, -18)
    icon.Position = UDim2.new(0, 9, 0, 9)
    icon.BackgroundTransparency = 1
    icon.Image = ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = slot

    local emptyText = Instance.new("TextLabel")
    emptyText.Name = "EmptyText"
    emptyText.Size = UDim2.new(1, -12, 1, -12)
    emptyText.Position = UDim2.new(0, 6, 0, 6)
    emptyText.Text = "Vacío"
    emptyText.TextScaled = true
    emptyText.TextColor3 = Color3.fromRGB(180, 180, 180)
    emptyText.Font = Enum.Font.GothamBold
    emptyText.BackgroundTransparency = 1
    emptyText.Parent = slot

    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "DarkOverlay"
    darkOverlay.Size = UDim2.new(1, 0, 1, 0)
    darkOverlay.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    darkOverlay.BackgroundTransparency = 0.7
    darkOverlay.BorderSizePixel = 0
    darkOverlay.Visible = false
    darkOverlay.Parent = slot
    rounded(darkOverlay, 14)

    local cooldownFill = Instance.new("Frame")
    cooldownFill.Name = "CooldownFill"
    cooldownFill.Size = UDim2.new(1, 0, 0, 8)
    cooldownFill.Position = UDim2.new(0, 0, 1, -8)
    cooldownFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    cooldownFill.BorderSizePixel = 0
    cooldownFill.Visible = false
    cooldownFill.Parent = slot

    local fillBar = Instance.new("Frame")
    fillBar.Name = "FillBar"
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(255, 220, 0)
    fillBar.BorderSizePixel = 0
    fillBar.Parent = cooldownFill

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(0, 24, 0, 20)
    keyLabel.Position = UDim2.new(1, -28, 1, -22)
    keyLabel.Text = tostring(index)
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    keyLabel.BorderSizePixel = 0
    keyLabel.Parent = slot
    rounded(keyLabel, 8)

    local slotData = {
        SlotIndex = index,
        Icon = icon,
        EmptyText = emptyText,
        DarkOverlay = darkOverlay,
        CooldownFill = cooldownFill,
        FillBar = fillBar,
        KeyLabel = keyLabel,
        Skill = nil,
        IsCooldown = false,
        CooldownDuration = 0,
    }

    slot.MouseButton1Click:Connect(function()
        if slotData.Skill then
            SkillBar:UseSkill(index)
        else
            SkillBar:SelectSlot(index)
        end
    end)

    return slotData
end

local function getSkillById(skillId)
    for _, skill in ipairs(SkillDefinitions) do
        if skill.Id == skillId then
            return skill
        end
    end
    return nil
end

local function createInventory(parent)
    local inventory = Instance.new("Frame")
    inventory.Name = "SkillInventory"
    inventory.Size = UDim2.new(0, 420, 0, 250)
    inventory.Position = UDim2.new(0.5, -210, 0.5, -125)
    inventory.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
    inventory.BorderSizePixel = 0
    inventory.Visible = false
    inventory.Parent = parent
    rounded(inventory, 18)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.Text = "Libro de habilidades"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = inventory

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -50)
    container.Position = UDim2.new(0, 10, 0, 42)
    container.BackgroundTransparency = 1
    container.Parent = inventory

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.CellSize = UDim2.new(0, 110, 0, 110)
    grid.FillDirectionMaxCells = 3
    grid.Parent = container

    for _, skill in ipairs(SkillDefinitions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 110, 0, 110)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.Parent = container
        rounded(btn, 12)

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, -18, 1, -18)
        icon.Position = UDim2.new(0, 9, 0, 9)
        icon.BackgroundTransparency = 1
        icon.Image = skill.Icon
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = btn

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -12, 0, 18)
        name.Position = UDim2.new(0, 6, 1, -24)
        name.Text = skill.Name
        name.Font = Enum.Font.GothamBold
        name.TextScaled = true
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.BackgroundTransparency = 1
        name.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if SkillBar.SelectedSlot then
                SkillBar:EquipSkill(SkillBar.SelectedSlot, skill.Id)
            end
        end)
    end

    return inventory
end

function SkillBar:SelectSlot(slotIndex)
    self.SelectedSlot = slotIndex

    for _, slot in ipairs(self.Slots) do
        if slot.SlotIndex == slotIndex then
            slot.KeyLabel.BackgroundColor3 = Color3.fromRGB(255, 210, 0)
            slot.KeyLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
        else
            slot.KeyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            slot.KeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    if self.InventoryOpen then
        self.Inventory.Visible = false
        self.InventoryOpen = false
    else
        self.Inventory.Visible = true
        self.InventoryOpen = true
    end
end

function SkillBar:HideInventory()
    if self.Inventory then
        self.Inventory.Visible = false
    end
    self.InventoryOpen = false
end

function SkillBar:EquipSkill(slotIndex, skillId)
    local slot = self.Slots[slotIndex]
    if not slot then
        return
    end

    local skill = getSkillById(skillId)
    if not skill then
        return
    end

    slot.Skill = skill
    slot.Icon.Image = skill.Icon
    slot.EmptyText.Visible = false
    slot.DarkOverlay.Visible = false
    slot.FillBar.Size = UDim2.new(0, 0, 1, 0)
    slot.CooldownFill.Visible = false
    self:HideInventory()
end

function SkillBar:UseSkill(slotIndex)
    local slot = self.Slots[slotIndex]
    if not slot or not slot.Skill then
        return
    end

    local now = os.clock()
    local skill = slot.Skill
    local cooldown = self.Cooldowns[slotIndex]

    if cooldown and now < cooldown.EndTime then
        return
    end

    self.Cooldowns[slotIndex] = {
        EndTime = now + skill.Cooldown,
        Duration = skill.Cooldown,
    }

    slot.DarkOverlay.Visible = true
    slot.CooldownFill.Visible = true
    slot.FillBar.Size = UDim2.new(0, 0, 1, 0)

    print("Habilidad usada:", skill.Name)
end

function SkillBar:UpdateCooldowns()
    local now = os.clock()

    for index, slot in ipairs(self.Slots) do
        local cooldown = self.Cooldowns[index]
        if cooldown then
            local remaining = cooldown.EndTime - now
            if remaining <= 0 then
                slot.DarkOverlay.Visible = false
                slot.CooldownFill.Visible = false
                self.Cooldowns[index] = nil
                slot.FillBar.Size = UDim2.new(0, 0, 1, 0)
            else
                local progress = 1 - (remaining / cooldown.Duration)
                slot.FillBar.Size = UDim2.new(progress, 0, 1, 0)
                slot.DarkOverlay.Visible = true
            end
        else
            slot.FillBar.Size = UDim2.new(0, 0, 1, 0)
        end
    end
end

function SkillBar:Create()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkillBarGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local bar = Instance.new("Frame")
    bar.Name = "SkillBar"
    bar.Size = UDim2.new(0, 720, 0, 110)
    bar.Position = UDim2.new(0.5, -360, 1, -120)
    bar.BackgroundTransparency = 1
    bar.Parent = screenGui

    local slotContainer = Instance.new("Frame")
    slotContainer.Size = UDim2.new(0, 720, 0, 100)
    slotContainer.Position = UDim2.new(0, 0, 0, 0)
    slotContainer.BackgroundTransparency = 1
    slotContainer.Parent = bar

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Parent = slotContainer

    for i = 1, 7 do
        local slot = createSlotFrame(slotContainer, i)
        table.insert(self.Slots, slot)
    end

    self.Inventory = createInventory(screenGui)

    local inventoryToggle = Instance.new("TextButton")
    inventoryToggle.Size = UDim2.new(0, 180, 0, 38)
    inventoryToggle.Position = UDim2.new(0.5, -90, 1, -170)
    inventoryToggle.Text = "Libro de habilidades"
    inventoryToggle.Font = Enum.Font.GothamBold
    inventoryToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    inventoryToggle.TextSize = 16
    inventoryToggle.BackgroundColor3 = Color3.fromRGB(55, 145, 255)
    inventoryToggle.BorderSizePixel = 0
    inventoryToggle.Parent = screenGui
    rounded(inventoryToggle, 12)

    inventoryToggle.MouseButton1Click:Connect(function()
        if self.InventoryOpen then
            self:HideInventory()
        else
            self.Inventory.Visible = true
            self.InventoryOpen = true
        end
    end)

    return screenGui
end

local function setup()
    SkillBar:Create()

    task.defer(function()
        SkillBar:EquipSkill(1, "Fireball")
        SkillBar:EquipSkill(2, "Shield")
        SkillBar:EquipSkill(3, "Slash")
        SkillBar:EquipSkill(4, "Heal")
        SkillBar:EquipSkill(5, "Dash")
        SkillBar:EquipSkill(6, "Meteor")
        SkillBar:EquipSkill(7, "AoeStrike")
    end)

    RunService.RenderStepped:Connect(function()
        SkillBar:UpdateCooldowns()
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Q then
            SkillBar:SelectSlot(1)
        elseif input.KeyCode == Enum.KeyCode.E then
            SkillBar:SelectSlot(2)
        elseif input.KeyCode == Enum.KeyCode.R then
            SkillBar:SelectSlot(3)
        elseif input.KeyCode == Enum.KeyCode.F then
            SkillBar:SelectSlot(4)
        elseif input.KeyCode == Enum.KeyCode.C then
            SkillBar:SelectSlot(5)
        elseif input.KeyCode == Enum.KeyCode.V then
            SkillBar:SelectSlot(6)
        elseif input.KeyCode == Enum.KeyCode.B then
            SkillBar:SelectSlot(7)
        end
    end)
end

setup()
