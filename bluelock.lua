repeat wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
}

--==[ Variables ]==--
local LocalPlayer = Services.Players.LocalPlayer

--==[ Settings and Data Containers ]==--
getgenv().Settings = {
    Player = {
        CopiedStyle = nil,
        InfiniteStamina = {
            Enabled = true,
        },
        NoAbilityCooldown = {
            Enabled = true,
        },
        AutoDribble = {
            Enabled = true,
        },
    },
    FootBall = {
        HitboxExpander = {
            Size = 24,
            Enabled = true,
        },
        BigBall = {
            Enabled = true,
        },
    },
    ESP = {
        TeammateESP = {
            Enabled = true,
        },
        EnemyESP = {
            Enabled = true,
        },
        BallPredictionESP = {
            Enabled = true,
        },
    },
    Spin = {
        AutoSpin = {
            Enabled = nil,
        },
        SpinStyle = {
            Selected = nil,
        },
        SpinSlot = {
            Selected = nil,
        },
    },
}

getgenv().GameData = {
    Player = {
        OriginalStyle = LocalPlayer:WaitForChild("PlayerStats"):WaitForChild("Style").Value
    },
    Football = {
        Ball = nil,
        originalBallSize = Vector3.new(1.550985336303711, 1.550277590751648, 1.5693973302841187),
        LastBallPosition = nil,
    },
    ESP = {
        BallPredictionESP = {
            RayVisualizationPart = nil,
        }
    }
}

--==[ Utility Functions ]==--
local Utility = {}
Utility.__index = Utility

function Utility:GetAllTagged(tagName)
    return Services.CollectionService:GetTagged(tagName) or {}
end

function Utility:FindBall()
    for _, obj in pairs(self:GetAllTagged("Football")) do
        if obj.Name == "Football" and obj.Parent ~= Services.ReplicatedStorage.Assets then
            return obj
        end
    end
end

--==[ Player Class ]==--
local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    self.LocalPlayer = LocalPlayer
    self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
    self.Humanoid = self.Character:WaitForChild("Humanoid")
    return self
end

function Player:SetStyle(styleName)
    self.LocalPlayer:WaitForChild("PlayerStats"):WaitForChild("Style").Value = styleName
end

function Player:SetStamina()
    while task.wait() do
        self.LocalPlayer:WaitForChild("PlayerStats"):WaitForChild("Stamina").Value = 100
    end
end

function Player:SetNoAbilityCooldown()
    local AbilityController = require(game:GetService("ReplicatedStorage").Controllers.AbilityController)
    local OriginalAbilityCooldown = AbilityController.AbilityCooldown

    AbilityController.AbilityCooldown = function(self, abilitySlot, ...)
        return OriginalAbilityCooldown(self, abilitySlot, 0, ...)
    end
end

--==[ ESP Class ]==--
local ESP = {}
ESP.__index = ESP

function ESP.new()
    local self = setmetatable({}, ESP)
    self.LocalPlayer = LocalPlayer
    self.highlights = {}
    self.connections = {}
    return self
end

function ESP:_createHighlight(target, color)
    if not target or not target:IsA("BasePart") then return end
    
    local existingHighlight = target:FindFirstChildOfClass("Highlight")
    if existingHighlight then
        existingHighlight.FillColor = color
        existingHighlight.OutlineColor = color
        return existingHighlight
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    
    local conn; conn = target.AncestryChanged:Connect(function()
        if not target:IsDescendantOf(workspace) then
            conn:Disconnect()
            highlight:Destroy()
            self.highlights[target] = nil
        end
    end)
    
    self.highlights[target] = highlight
    return highlight
end

function ESP:_destroyHighlight(target)
    if self.highlights[target] then
        self.highlights[target]:Destroy()
        self.highlights[target] = nil
    end
end

-- function ESP:UpdateESP()
--     for target, highlight in pairs(self.highlights) do
--         if not target:IsDescendantOf(workspace) then
--             highlight:Destroy()
--             self.highlights[target] = nil
--         end
--     end

--     if getgenv().Settings.ESP.TeammateESP.Enabled or getgenv().Settings.ESP.EnemyESP.Enabled then
--         for _, player in ipairs(Services.Players:GetPlayers()) do
--             if player ~= self.LocalPlayer and player.Character then
--                 local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
--                 if rootPart then
--                     if player.Team == self.LocalPlayer.Team and getgenv().Settings.ESP.TeammateESP.Enabled then
--                         self:_createHighlight(rootPart, Color3.fromRGB(0, 255, 0)) -- Green for teammates
--                     elseif player.Team ~= self.LocalPlayer.Team and getgenv().Settings.ESP.EnemyESP.Enabled then
--                         self:_createHighlight(rootPart, Color3.fromRGB(255, 0, 0)) -- Red for enemies
--                     else
--                         self:_destroyHighlight(rootPart)
--                     end
--                 end
--             end
--         end
--     else
--         for target, highlight in pairs(self.highlights) do
--             highlight:Destroy()
--             self.highlights[target] = nil
--         end
--     end
-- end

-- ==[ Football Class ]==--
local FootBall = {}
FootBall.__index = FootBall

function FootBall.new()
    local self = setmetatable({}, FootBall)
    self.Ball = Utility:FindBall()
    self.LastPosition = nil
    return self
end

function FootBall:UpdateBallSize(size)
    if self.Ball and getgenv().GameData.Football.originalBallSize then
        self.Ball.Size = Vector3.new(getgenv().GameData.Football.originalBallSize.X * size, getgenv().GameData.Football.originalBallSize.Y * size, getgenv().GameData.Football.originalBallSize.Z * size)
    end
end

local player = Player.new()
local football = FootBall.new()
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/rapheephat-atiyat/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

local win = ui:CreateWindow({
	Name = "Mas Hub",
	LogoID = "78509977966121",
	LoadingEnabled = true,
	LoadingTitle = "Blue Lock: Rivals",
	LoadingSubtitle = "By Mas Hub",
	ConfigSettings = {
		ConfigFolder = "Mas Hub"
	},
	KeySystem = false,
})

local tabPlayer = win:CreateTab({
	Name = "Player",
	Icon = "person",
	ImageSource = "Material",
	ShowTitle = true
})

local tabFootball = win:CreateTab({
	Name = "Football",
	Icon = "sports_soccer",
	ImageSource = "Material",
	ShowTitle = true
})

local tabEsp = win:CreateTab({
    Name = "ESP",
    Icon = "visibility",
    ImageSource = "Material",
    ShowTitle = true
})

local tabSpin = win:CreateTab({
    Name = "Spin",
    Icon = "auto_awesome",
    ImageSource = "Material",
    ShowTitle = true
})

--== Player Tab ==--
local lblNote = tabPlayer:CreateLabel({
	Text = "ต้องการสไตล์ Reo เพื่อใช้ฟีเจอร์นี้",
	Style = 3
})

local dropStyle = tabPlayer:CreateDropdown({
	Name = "Style Selector",
	Description = "Select a style for your character.",
	Options = {
		"Sae", "Kaiser", "NEL Isagi", "Don Lorenzo", "Reo", "Kunigami", "Yukimiya", "Rin",
		"Shidou", "King", "Nagi", "Aiku", "Karasu", "Isagi", "Chigiri", "Bachira", "Otoya", "Hiori", "Gagamaru"
	},
	CurrentOption = getgenv().GameData.Player.OriginalStyle,
	MultipleOptions = false,
	Callback = function(value)
		player:SetStyle(value)
	end
}, "StyleDropdown")

tabPlayer:CreateDivider()

local btnStamina = tabPlayer:CreateButton({
	Name = "Infinite Stamina",
	Description = "Unlimited stamina for your character.",
	Callback = function()
        player:SetStamina()
	end
})

local btnAbilityNoCD = tabPlayer:CreateButton({
    Name = "No Ability Cooldown",
    Description = "Remove cooldown for abilities. (need good executor)",
    Callback = function()
        player:SetNoAbilityCooldown()
    end
})

local lblAutoDribble = tabPlayer:CreateLabel({
    Text = "ความสำเร็จของการเลี้ยงบอลอัตโนมัติขึ้นอยู่กับความปิงของผู้ใช้",
    Style = 2
})

local toggleAutoDribble = tabPlayer:CreateToggle({
    Name = "Auto Dribble",
    Description = "Automatically dribble.",
    CurrentValue = true,
    Callback = function(value)
        getgenv().Settings.Player.AutoDribble.Enabled = value
    end
}, "AutoDribble")

--== Football Tab ==--
local sliderHitbox = tabFootball:CreateSlider({
    Name = "Hitbox Size",
    Range = { 0, 24 },
    Increment = 1,
    CurrentValue = 24,
    Callback = function(value)
        getgenv().Settings.FootBall.HitboxExpander.Size = value
    end
}, "HitboxSize")

local toggleExpander = tabFootball:CreateToggle({
    Name = "Hitbox Expander",
    Description = "Expand the ball hitbox for better control.",
    CurrentValue = true,
    Callback = function(value)
        getgenv().Settings.FootBall.HitboxExpander.Enabled = value
    end
}, "HitboxExpander")

tabFootball:CreateDivider()

local toggleBigBall = tabFootball:CreateToggle({
    Name = "Big Ball",
    Description = "Make the ball bigger x5.",
    CurrentValue = true,
    Callback = function(bool)
        if bool then
            football:UpdateBallSize(5)
        else
            football:UpdateBallSize(1)
        end
    end
}, "BigBall")

--== ESP Tab ==--
local toggleEsp = tabEsp:CreateToggle({
    Name = "Teammate ESP",
    Description = "Enable ESP for teammates.",
    CurrentValue = true,
    Callback = function(value)
        getgenv().Settings.ESP.TeammateESP.Enabled = value
    end
}, "TeammateESP")

local toggleEnemyEsp = tabEsp:CreateToggle({
    Name = "Enemy ESP",
    Description = "Enable ESP for enemies.",
    CurrentValue = true,
    Callback = function(value)
        getgenv().Settings.ESP.EnemyESP.Enabled = value
    end
}, "EnemyESP")

local toggleBallEsp = tabEsp:CreateToggle({
    Name = "Ball Prediction ESP",
    Description = "Enable ESP for falling ball prediction.",
    CurrentValue = true,
    Callback = function(value)
        getgenv().Settings.ESP.BallPredictionESP.Enabled = value
    end
}, "BallESP")

--== Spin Tab ==--
local lblSpinNote = tabSpin:CreateParagraph({
    Title = "❓ วิธีการใช้งาน",
    Text = "- 1. เลือกสไตล์ที่คุณต้องการ\n- 2. เลือกช่องสล็อตที่คุณต้องการ\n- 3. เปิดใช้งาน Auto Spin\n- 4. รอให้สไตล์หมุนเสร็จสิ้น",
})

local lblSpinNote2 = tabSpin:CreateLabel({
    Text = "❗️ หมายเหตุ: หากข้อมูลหาย ไม่ต้องตกใจ ให้รอหรือรีสตาร์ทเกม",
    Style = 3
})

local dropSpin = tabSpin:CreateDropdown({
    Name = "Style Selector",
    Description = "Select a style for your spin.",
    Options = {
		"Kaiser", "Don Lorenzo", "NEL Isagi", "Sae", "Kunigami", "Yukimiya", "Rin", "Reo",
        "Shidou", "King", "Nagi", "Aiku", "Karasu", "Isagi", "Chigiri", "Bachira", "Otoya", "Hiori", "Gagamaru"
	},
    CurrentOption = { "Kaiser" },
    MultipleOptions = true,
    Callback = function(opt)
        print("Spin style selected: " .. opt)
    end
}, "SpinStyleDropdown")

local dropSlot = tabSpin:CreateDropdown({
    Name = "Style Slot",
    Description = "Select a slot for your spin.",
    Options = {
        "1", "2", "3", "4", "5", "6"
    },
    CurrentOption = { "1" },
    MultipleOptions = false,
    Callback = function(opt)
        print("Spin slot selected: " .. opt)
    end
}, "StyleSlotDropdown")

local ToggleSpin = tabSpin:CreateToggle({
    Name = "Auto Spin",
    Description = "Automatically spin the style.",
    CurrentValue = true,
    Callback = function(value)
        print("Auto Spin toggled: " .. tostring(value))
    end
}, "AutoSpin")


--==[ Main Loop ]==--
Services.RunService.Heartbeat:Connect(function()
    pcall(function()
        if not getgenv().Settings.Player.AutoDribble.Enabled and player.LocalPlayer.Team == "Visitor" then return end

        local animationController = Services.ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("AnimatonController")
        local animation = animationController:WaitForChild("Isagi")
    
        local animator = player.Humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = player.Humanoid
        end
    
        local animationTrack = animator:LoadAnimation(animation)
    
        for i, v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v ~= player.Character and v:FindFirstChild("Values") then
                local TargetHumanoidRootPart = v:FindFirstChild("HumanoidRootPart")
                local TargetValue = v:FindFirstChild("Values")
                local Distance = (TargetHumanoidRootPart.Position - player.HumanoidRootPart.Position).Magnitude
                if Distance <= 20 and TargetValue.Sliding.Value then
                    Services.ReplicatedStorage.Packages.Knit.Services.BallService.RE.Dribble:FireServer()
                    if player.Character.Values.Dribbling.Value then
                        animationTrack:Play()
                    end
                end
            end
        end
    end)
end)
