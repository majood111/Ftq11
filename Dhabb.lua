-- Dhabb GUI v3
-- رادار + صيد تلقائي للضبان + أداة فحص الأسماء

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== الإعدادات =====
local CONFIG = {
    -- كلمات البحث في اسم الضب (تقدر تضيف من الواجهة)
    -- اسم الضب في اللعبة: Dhab_xxxxxx (من نتيجة الفحص)
    keywords = { "dhab", "ضب" },
    shootRange = 40,        -- من أي مسافة يوجّه السلاح ويطلق
    showTags = true,        -- سهم + مسافة فوق كل ضب
    -- لو شغّلتها يلوّن أي حيوان (Model فيه Humanoid) مو لاعب
    detectAnimals = true,
    radarInterval = 2,
    huntInterval = 0.4,
    interactRange = 12,
    maxHuntRange = 500,
    scanRadius = 80,        -- نطاق أداة الفحص
}

-- ===== تنظيف النسخة القديمة =====
local oldGui = playerGui:FindFirstChild("DhabbGui")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DhabbGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- ===== الواجهة =====
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 380)
frame.Position = UDim2.new(0.05, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 42)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Dhabb GUI v3"
title.TextColor3 = Color3.fromRGB(255, 165, 0)
title.TextSize = 17
title.Font = Enum.Font.SourceSansBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 42)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Text = "X"
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local function makeButton(text, y, h)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.88, 0, 0, h or 38)
    b.Position = UDim2.new(0.06, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Font = Enum.Font.SourceSansBold
    b.Text = text
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local radarBtn = makeButton("Radar: OFF", 52)
local huntBtn = makeButton("Auto Hunt: OFF", 96)
local scanBtn = makeButton("Scan: أسماء اللي حولي", 140)

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.88, 0, 0, 34)
keyBox.Position = UDim2.new(0.06, 0, 0, 184)
keyBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
keyBox.TextColor3 = Color3.new(1, 1, 1)
keyBox.PlaceholderText = "اكتب اسم الضب واضغط Enter"
keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyBox.Text = ""
keyBox.ClearTextOnFocus = false
keyBox.TextSize = 14
keyBox.Font = Enum.Font.SourceSans
keyBox.Parent = frame
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.88, 0, 0, 140)
status.Position = UDim2.new(0.06, 0, 0, 226)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 13
status.Font = Enum.Font.SourceSans
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "الحالة: جاهز"
status.Parent = frame

local function setToggle(btn, label, on)
    btn.Text = label .. (on and ": ON" or ": OFF")
    btn.BackgroundColor3 = on and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(60, 60, 60)
end

-- ===== أدوات مساعدة =====

-- هل الشي يخص لاعب (شخصيتي أو غيري) أو أداة/سلاح؟ نتجاهله
local function isPlayerStuff(object)
    if object:FindFirstAncestorOfClass("Tool") or object:IsA("Tool") then
        return true
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p.Character
        if ch and (object == ch or object:IsDescendantOf(ch)) then
            return true
        end
    end
    return false
end

local function hasKeyword(object)
    local name = object.Name:lower()
    for _, k in ipairs(CONFIG.keywords) do
        if name:find(k:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function isAnimal(object)
    return object:IsA("Model")
        and object:FindFirstChildOfClass("Humanoid") ~= nil
end

local function matches(object)
    if not (object:IsA("Model") or object:IsA("BasePart")) then
        return false
    end
    if object:IsA("Terrain") or isPlayerStuff(object) then
        return false
    end
    if hasKeyword(object) then
        return true
    end
    return CONFIG.detectAnimals and isAnimal(object)
end

local function getPart(object)
    if object:IsA("BasePart") then
        return object
    end
    return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
end

-- ===== الرادار =====
local radarOn = false
local markers = {}

local function clearMarkers()
    for object, marker in pairs(markers) do
        marker:Destroy()
        markers[object] = nil
    end
end

local function updateRadar()
    if not radarOn then
        clearMarkers()
        return
    end

    local count = 0
    for _, object in ipairs(Workspace:GetDescendants()) do
        if matches(object) then
            count += 1
            -- نتجنب تكرار: لو أبوه Model ملوّن، ما نلوّن الجزء
            if not markers[object]
                and not (object:IsA("BasePart") and object.Parent ~= Workspace
                    and markers[object.Parent]) then
                local marker = Instance.new("Highlight")
                marker.Name = "DhabbESP"
                marker.Adornee = object
                marker.FillColor = Color3.fromRGB(255, 140, 0)
                marker.OutlineColor = Color3.fromRGB(255, 255, 0)
                marker.FillTransparency = 0.4
                marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                marker.Parent = gui
                markers[object] = marker

                -- سهم + مسافة فوق الضب، يلحقه وين ما راح
                local part = getPart(object)
                if CONFIG.showTags and part then
                    local tag = Instance.new("BillboardGui")
                    tag.Name = "DhabbTag"
                    tag.Adornee = part
                    tag.AlwaysOnTop = true
                    tag.Size = UDim2.fromOffset(90, 44)
                    tag.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
                    tag.Parent = marker

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Dist"
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextSize = 16
                    lbl.Font = Enum.Font.SourceSansBold
                    lbl.Text = "▼"
                    lbl.Parent = tag
                end
            end
        end
    end

    for object, marker in pairs(markers) do
        if not object:IsDescendantOf(Workspace) or isPlayerStuff(object) then
            marker:Destroy()
            markers[object] = nil
        end
    end

    status.Text = "الرادار: لقيت " .. count .. " هدف"
end

-- ===== أداة الفحص: تعرض أسماء الأشياء اللي حولك =====
local function scanNearby()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        status.Text = "الفحص: الشخصية مو جاهزة"
        return
    end

    local found, seen = {}, {}
    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart"))
            and not object:IsA("Terrain")
            and not isPlayerStuff(object) then
            local part = getPart(object)
            if part then
                local d = (part.Position - root.Position).Magnitude
                -- نتجاهل الأجزاء الكبيرة (أرض/جدران) والأسماء العامة
                local big = part.Size.Magnitude > 40
                if d <= CONFIG.scanRadius and not big and not seen[object.Name] then
                    seen[object.Name] = true
                    table.insert(found, { name = object.Name, class = object.ClassName, d = d })
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.d < b.d end)

    local lines = {}
    for i = 1, math.min(#found, 8) do
        local f = found[i]
        lines[#lines + 1] = string.format("%s (%s) %dm", f.name, f.class, f.d)
        print("[DhabbScan]", f.name, f.class, math.floor(f.d))
    end

    status.Text = #lines > 0
        and ("أقرب الأسماء:\n" .. table.concat(lines, "\n") .. "\nوقف جنب الضب واضغط Scan، وانسخ اسمه في الخانة.")
        or "الفحص: ما لقيت شي قريب"
end

-- ===== الصيد التلقائي =====
local huntOn = false

local function findNearest(root)
    local best, bestDist = nil, CONFIG.maxHuntRange
    for _, object in ipairs(Workspace:GetDescendants()) do
        if matches(object) then
            local part = getPart(object)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < bestDist then
                    best, bestDist = object, d
                end
            end
        end
    end
    return best, bestDist
end

local function interact(object)
    local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        fireproximityprompt(prompt)
        return true
    end
    local click = object:FindFirstChildWhichIsA("ClickDetector", true)
    if click and fireclickdetector then
        fireclickdetector(click)
        return true
    end
    return false
end

-- يجهّز السلاح: يمسكه لو كان في الشنطة
local function getTool(char, humanoid)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    tool = backpack and backpack:FindFirstChildOfClass("Tool")
    if tool then
        humanoid:EquipTool(tool)
    end
    return tool
end

-- يوجّه الشخصية والكاميرا للضب
local function aimAt(root, part)
    local flat = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
    root.CFrame = CFrame.lookAt(root.Position, flat)
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
    end
end

local function huntStep()
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (humanoid and root) or humanoid.Health <= 0 then
        status.Text = "الصيد: الشخصية مو جاهزة"
        return
    end

    local target, dist = findNearest(root)
    if not target then
        status.Text = "الصيد: ما فيه ضب قريب"
        return
    end

    local part = getPart(target)
    local tool = getTool(char, humanoid)

    if dist > CONFIG.shootRange then
        humanoid:MoveTo(part.Position)
        status.Text = string.format("الصيد: ألحق %s (%d م)", target.Name, dist)
        return
    end

    -- داخل المدى: وجّه وأطلق (والضب يهرب فنتبعه بنفس الوقت)
    aimAt(root, part)
    humanoid:MoveTo(part.Position)

    if tool then
        tool:Activate()
        status.Text = string.format("الصيد: أطلق على %s (%d م)", target.Name, dist)
    elseif dist <= CONFIG.interactRange and interact(target) then
        status.Text = "الصيد: تفاعلت مع " .. target.Name
    else
        status.Text = "الصيد: ما معي سلاح في الشنطة"
    end
end

-- ===== الأزرار =====
radarBtn.Activated:Connect(function()
    radarOn = not radarOn
    setToggle(radarBtn, "Radar", radarOn)
    updateRadar()
    if not radarOn then
        status.Text = "الرادار: متوقف"
    end
end)

huntBtn.Activated:Connect(function()
    huntOn = not huntOn
    setToggle(huntBtn, "Auto Hunt", huntOn)
    if not huntOn then
        status.Text = "الصيد: متوقف"
    end
end)

scanBtn.Activated:Connect(scanNearby)

keyBox.FocusLost:Connect(function(enterPressed)
    local text = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if enterPressed and text ~= "" then
        table.insert(CONFIG.keywords, text)
        keyBox.Text = ""
        status.Text = "أضفت الاسم: " .. text
        if radarOn then
            updateRadar()
        end
    end
end)

closeBtn.Activated:Connect(function()
    radarOn, huntOn = false, false
    gui:Destroy()
end)

-- ===== الحلقات =====
task.spawn(function()
    while gui.Parent do
        task.wait(CONFIG.radarInterval)
        if radarOn then
            pcall(updateRadar)
        end
    end
end)

-- تحديث المسافة فوق كل ضب
task.spawn(function()
    while gui.Parent do
        task.wait(0.3)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if radarOn and root then
            for object, marker in pairs(markers) do
                local part = object.Parent and getPart(object)
                local lbl = marker:FindFirstChild("DhabbTag")
                    and marker.DhabbTag:FindFirstChild("Dist")
                if part and lbl then
                    lbl.Text = string.format("▼\n%d م", (part.Position - root.Position).Magnitude)
                end
            end
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(CONFIG.huntInterval)
        if huntOn then
            local ok, err = pcall(huntStep)
            if not ok then
                status.Text = "خطأ: " .. tostring(err)
            end
        end
    end
end)

gui.Destroying:Connect(clearMarkers)
