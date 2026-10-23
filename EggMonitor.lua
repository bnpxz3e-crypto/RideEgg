-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local A = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")

local ROOTS = {PG, CoreGui}

local H = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

local MAX = 2
local TIMEOUT = 300
local REOPEN_DELAY = 10
local MAP_WAIT = 10
local WEIGHT_RETRIES = 10
local PHOTO_RETRIES = 3

local eggs = {
    ["Volcanic Egg"] = {
        id = "132679696143806",
        emoji = "🌋"
    },
    ["Solaris Egg"] = {
        id = "131016816558781",
        emoji = "☀️"
    },
    ["Cherub Egg"] = {
        id = "78949206711037",
        emoji = "👼"
    }
}

local switches = {
    "Auto Collect Candy",
    "Auto Search Pumpkins",
    "Auto Trick Or Treat",
    "Auto Halloween Ritual",
    "Collect Rare Eggs First"
}

local ENV = getgenv()
ENV.RideEggRun = (ENV.RideEggRun or 0) + 1
local RUN = ENV.RideEggRun

local enabled = false
local busy = false
local offset = 0
local initialized = false
local seenEggs = {}

local function alive()
    return ENV.RideEggRun == RUN
end

local function active()
    return alive() and enabled
end

-- =============================
-- UI
-- =============================

local old = PG:FindFirstChild("RideEggChilliControl")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RideEggChilliControl"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 900
gui.Parent = PG

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local chilli = Instance.new("TextButton")
chilli.Name = "ChilliButton"
chilli.Size = UDim2.fromOffset(55, 55)
chilli.Position = UDim2.new(0, 12, 0.45, 0)
chilli.BackgroundColor3 = Color3.fromRGB(200, 43, 30)
chilli.Text = "🌶️"
chilli.TextSize = 30
chilli.TextColor3 = Color3.new(1, 1, 1)
chilli.Active = true
chilli.Draggable = true
chilli.Parent = gui
corner(chilli, 14)

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.fromOffset(310, 220)
panel.Position = UDim2.new(0.5, -155, 0.5, -110)
panel.BackgroundColor3 = Color3.fromRGB(23, 23, 27)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -65, 0, 45)
title.Position = UDim2.fromOffset(12, 3)
title.BackgroundTransparency = 1
title.Text = "🌶️ EGG MONITOR"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(38, 36)
close.Position = UDim2.new(1, -45, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(210, 50, 45)
close.Text = "X"
close.TextSize = 23
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = panel
corner(close, 8)

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -24, 0, 48)
toggle.Position = UDim2.fromOffset(12, 55)
toggle.BackgroundColor3 = Color3.fromRGB(125, 45, 45)
toggle.Text = "🔴 ระบบปิด OFF"
toggle.TextSize = 20
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.Parent = panel
corner(toggle, 8)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 100)
info.Position = UDim2.fromOffset(12, 112)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.new(1, 1, 1)
info.TextSize = 15
info.TextWrapped = true
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = "ระบบปิดอยู่"
info.Parent = panel

local function status(t)
    if alive() and info.Parent then
        info.Text = t
    end
end

chilli.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

close.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- =============================
-- TELEGRAM
-- =============================

local API = "https://api.telegram.org/bot" .. TOKEN

local function api(method, body)
    if not H then
        return nil, "HTTP request unavailable"
    end

    local ok, res = pcall(function()
        return H({
            Url = API .. "/" .. method,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HS:JSONEncode(body or {})
        })
    end)

    if not ok or not res then
        return nil, tostring(res)
    end

    local good, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    if not good then
        return nil, "HTTP " .. tostring(res.StatusCode)
    end

    if not data.ok then
        return nil, tostring(data.description)
    end

    return data
end

local function send(t)
    return api("sendMessage", {
        chat_id = CHAT,
        text = t
    })
end

local function photoUrl(id)
    if not H then return nil end

    local ok, res = pcall(function()
        return H({
            Url = "https://thumbnails.roblox.com/v1/assets"
                .. "?assetIds=" .. id
                .. "&size=420x420"
                .. "&format=Png"
                .. "&isCircular=false",
            Method = "GET"
        })
    end)

    if not ok or not res then
        return nil
    end

    local good, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    if not good then
        return nil
    end

    local item = data.data and data.data[1]

    if item
        and item.state == "Completed"
        and item.imageUrl
        and item.imageUrl ~= "" then
        return item.imageUrl
    end

    return nil
end

-- =============================
-- CHILLI HUB BUTTONS
-- =============================

local function press(b)
    if not b or not b:IsA("GuiButton") then
        return false
    end

    local count = 0

    pcall(function()
        for _, c in ipairs(getconnections(b.Activated)) do
            if c.Function then
                c.Function()
                count = count + 1
            end
        end
    end)

    return count > 0
end

local function findSwitch(name)
    for _, root in ipairs(ROOTS) do
        local frame = root:FindFirstChild(name, true)

        if frame and frame:IsA("Frame") then
            local sw = frame:FindFirstChild("Switch", true)
            local b = sw and sw:FindFirstChild("Button", true)

            if b and b:IsA("GuiButton") then
                return b
            end
        end
    end

    return nil
end

local function toggle5()
    local count = 0

    for _, name in ipairs(switches) do
        if press(findSwitch(name)) then
            count = count + 1
        end

        task.wait(0.3)
    end

    return count
end

-- =============================
-- MAP EGGS
-- =============================

local function getCards()
    local cards = {}
    local seen = {}

    for _, root in ipairs(ROOTS) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("TextLabel") and eggs[v.Text] then
                local parent = v.Parent

                for _ = 1, 5 do
                    if not parent then break end

                    local b = parent:FindFirstChild("Open")

                    if b and b:IsA("GuiButton") then
                        if not seen[b] then
                            seen[b] = true

                            table.insert(cards, {
                                name = v.Text,
                                button = b,
                                label = v
                            })
                        end

                        break
                    end

                    parent = parent.Parent
                end
            end
        end
    end

    return cards
end

local function getWeight(name)
    for _, card in ipairs(getCards()) do
        if card.name == name then
            local parent = card.label.Parent

            for _ = 1, 5 do
                if not parent then break end

                local w = parent:FindFirstChild(
                    "EggWeight", true
                )

                if w and w:IsA("TextLabel") then
                    local text = w.Text

                    if text
                        and text ~= ""
                        and text:lower():find(
                            "kg", 1, true
                        ) then
                        return text
                    end
                end

                parent = parent.Parent
            end
        end
    end

    return nil
end

local function getIds()
    local ids = {}

    for _, e in ipairs(A:GetChildren()) do
        local name = e:GetAttribute("Egg")

        if eggs[name] then
            ids[name] = ids[name] or {}
            table.insert(ids[name], e.Name)
        end
    end

    return ids
end

-- =============================
-- EGG ANNOUNCEMENT
-- =============================


local function announce(e)
    if not active() or not e.Parent then return end

    local name = e:GetAttribute("Egg")
    local egg = eggs[name]
    if not egg then return end

    local keyboard = {
        inline_keyboard = {{
            {
                text = "🥚 เก็บไข่",
                callback_data = "C" .. e.Name
            }
        }}
    }

    -- 1. แจ้งทันที ไม่รอรูปหรือ KG
    local sent, err = api("sendMessage", {
        chat_id = CHAT,
        text = egg.emoji .. " พบ " .. name
            .. "\n⚖️ KG: กำลังตรวจสอบ..."
            .. "\n🥚 กดปุ่มเพื่อเก็บไข่",
        reply_markup = keyboard
    })

    if not sent then
        status("❌ ส่ง Telegram ไม่ได้: " .. tostring(err))
        return
    end

    status("✅ แจ้ง Telegram แล้ว: " .. name)

    -- 2. รอ Map Eggs โหลด
    task.wait(10)

    if not alive() then return end

    -- 3. อ่านน้ำหนักซ้ำ
    local weight

    for i = 1, 10 do
        weight = getWeight(name)
        if weight then break end
        task.wait(1)
    end

    weight = weight or "ไม่ทราบ"

    -- 4. อัปเดตข้อความเดิม โดยเก็บปุ่ม Collect ไว้
    api("editMessageText", {
        chat_id = CHAT,
        message_id = sent.result.message_id,
        text = egg.emoji .. " พบ " .. name
            .. "\n⚖️ KG: " .. weight
            .. "\n🥚 กดปุ่มเพื่อเก็บไข่",
        reply_markup = keyboard
    })

    -- 5. ส่งรูปแยกต่างหาก
    for i = 1, 3 do
        local url = photoUrl(egg.id)

        if url then
            local result = api("sendPhoto", {
                chat_id = CHAT,
                photo = url,
                caption = egg.emoji .. " " .. name
                    .. "\n⚖️ KG: " .. weight
            })

            if result then
                status("✅ ส่งรูปแล้ว: " .. name)
                return
            end
        end

        task.wait(2)
    end

    status("⚠️ แจ้งข้อความแล้ว แต่ส่งรูปไม่สำเร็จ")
end


-- =============================
-- COLLECT PROCESS
-- =============================

local function collectCycle(requestId)
    if busy then
        send("⏳ กำลังเก็บไข่รอบก่อนอยู่")
        return
    end

    if not enabled then
        send("🔴 ระบบปิดอยู่")
        return
    end

    local chosen = A:FindFirstChild(requestId)

    if not chosen
        or not eggs[chosen:GetAttribute("Egg")] then
        send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว")
        return
    end

    busy = true

    local function run()
        local wanted = chosen:GetAttribute("Egg")

        status("🥚 กำลังไปเก็บไข่ " .. wanted)
        send("🥚 กำลังไปเก็บไข่\n" .. wanted)

        -- ปิด Halloween Event
        local off = toggle5()

        send(
            "⏸ สั่งปิด Halloween Event "
            .. off .. "/5"
        )

        task.wait(1)

        -- Collect สูงสุด 2 ใบ
        local ids = getIds()
        local cards = getCards()

        table.sort(cards, function(a, b)
            return a.name == wanted
                and b.name ~= wanted
        end)

        local watching = {}
        local used = {}
        local usedButtons = {}
        local count = 0

        for _, card in ipairs(cards) do
            if count >= MAX then break end

            if not usedButtons[card.button] then
                local list = ids[card.name] or {}

                if card.name == wanted then
                    table.sort(list, function(a, b)
                        return a == requestId
                            and b ~= requestId
                    end)
                end

                for _, id in ipairs(list) do
                    if not used[id] then
                        if press(card.button) then
                            used[id] = true
                            usedButtons[card.button] = true
                            watching[id] = card.name
                            count = count + 1

                            status(
                                "🥚 Collect "
                                .. count .. "/" .. MAX
                            )

                            send(
                                "🥚 สั่ง Collect "
                                .. count .. "/" .. MAX
                                .. "\n" .. card.name
                            )
                        end

                        break
                    end
                end
            end

            task.wait(0.3)
        end

        if count == 0 then
            send("⚠️ ไม่พบปุ่ม Collect ใน Map Eggs")
        end

        -- รอไข่หาย
        local remaining = count
        local elapsed = 0

        while remaining > 0
            and elapsed < TIMEOUT
            and alive() do

            task.wait(2)
            elapsed = elapsed + 2

            for id, name in pairs(watching) do
                if not A:FindFirstChild(id) then
                    watching[id] = nil
                    remaining = remaining - 1

                    send(
                        "🥚 ไข่หาย: " .. name
                        .. "\nเหลือ "
                        .. remaining .. " ใบ"
                    )
                end
            end
        end

        local success =
            count > 0 and remaining == 0

        -- รอ 10 วินาทีหลังไข่หายครบ
        if success then
            status("⏳ ไข่หายครบ รอ 10 วินาที")
            task.wait(REOPEN_DELAY)
        elseif remaining > 0 then
            send(
                "⚠️ ครบ 5 นาที ยังเหลือ "
                .. remaining .. " ใบ"
            )
        end

        -- เปิด Halloween Event กลับ
        local on = toggle5()

        if success and on == 5 then
            status("✅ เก็บไข่สำเร็จ")

            send(
                "✅ เก็บไข่สำเร็จ!"
                .. "\n🥚 จำนวน "
                .. count .. " ใบ"
                .. "\n▶️ เปิด Halloween Event กลับแล้ว 5/5"
            )
        else
            status(
                "⚠️ จบกระบวนการ Event "
                .. on .. "/5"
            )

            send(
                "⚠️ จบกระบวนการเก็บไข่"
                .. "\nไข่หายครบ: "
                .. tostring(success)
                .. "\nสั่งเปิด Event: "
                .. on .. "/5"
            )
        end
    end

    local ok, err = pcall(run)

    if not ok then
        status("❌ " .. tostring(err))
        send("❌ ERROR: " .. tostring(err))
    end

    busy = false
end

-- =============================
-- TELEGRAM POLLING
-- =============================

task.spawn(function()
    while alive() do
        if enabled then
            if not initialized then
                local data, err = api("getUpdates", {
                    timeout = 0,
                    limit = 100,
                    allowed_updates = {
                        "callback_query"
                    }
                })

                if data then
                    for _, u in ipairs(
                        data.result or {}
                    ) do
                        offset = math.max(
                            offset,
                            u.update_id + 1
                        )
                    end

                    initialized = true

                    status(
                        "🟢 ระบบเปิด\nรอไข่และคำสั่ง Telegram"
                    )

                    send(
                        "🟢 Ride A Pet Egg Monitor เริ่มทำงาน"
                    )
                else
                    status(
                        "❌ Telegram: "
                        .. tostring(err)
                    )
                end
            else
                local data, err = api("getUpdates", {
                    offset = offset,
                    timeout = 0,
                    limit = 100,
                    allowed_updates = {
                        "callback_query"
                    }
                })

                if data then
                    for _, u in ipairs(
                        data.result or {}
                    ) do
                        offset = math.max(
                            offset,
                            u.update_id + 1
                        )

                        local cb = u.callback_query

                        if cb
                            and type(cb.data) == "string" then

                            local chat = cb.message
                                and cb.message.chat
                                and tostring(
                                    cb.message.chat.id
                                )

                            if chat == CHAT
                                and cb.data:sub(1, 1) == "C" then

                                api(
                                    "answerCallbackQuery",
                                    {
                                        callback_query_id = cb.id,
                                        text = "กำลังไปเก็บไข่"
                                    }
                                )

                                task.spawn(
                                    collectCycle,
                                    cb.data:sub(2)
                                )
                            end
                        end
                    end
                else
                    status(
                        "⚠️ Telegram: "
                        .. tostring(err)
                    )
                end
            end
        end

        task.wait(2)
    end
end)

-- =============================
-- EGG MONITOR
-- =============================

-- ข้ามไข่ที่มีอยู่ก่อนเริ่มสคริปต์
for _, e in ipairs(A:GetChildren()) do
    seenEggs[e.Name] = true
end

task.spawn(function()
    while alive() do
        for _, e in ipairs(A:GetChildren()) do
            if not seenEggs[e.Name] then
                seenEggs[e.Name] = true

                local name = e:GetAttribute("Egg")

                if enabled and eggs[name] then
                    task.spawn(announce, e)
                end
            end
        end

        task.wait(2)
    end
end)

-- =============================
-- ON / OFF SWITCH
-- =============================

toggle.MouseButton1Click:Connect(function()
    if not alive() then return end

    if busy then
        status(
            "⏳ กำลังเก็บไข่\nกรุณารอให้จบรอบก่อน"
        )
        return
    end

    if not enabled then
        if TOKEN == "PUT_YOUR_NEW_BOT_TOKEN_HERE"
            or TOKEN == "" then

            status("❌ กรุณาใส่ Bot Token")
            return
        end

        if not H then
            status("❌ ไม่พบ HTTP request")
            return
        end

        enabled = true

        toggle.Text = "🟢 ระบบเปิด ON"
        toggle.BackgroundColor3 =
            Color3.fromRGB(30, 135, 75)

        status(
            "🟢 ระบบเปิด\nกำลังเชื่อมต่อ Telegram..."
        )
    else
        enabled = false

        toggle.Text = "🔴 ระบบปิด OFF"
        toggle.BackgroundColor3 =
            Color3.fromRGB(125, 45, 45)

        status("🔴 ระบบปิดแล้ว")
    end
end)

status("🌶️ กดปุ่ม ON เพื่อเริ่มระบบ")
