-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local ROOTS = {PG, game.CoreGui}

local H = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

if not H then
    warn("ไม่พบ HTTP request")
    return
end

if TOKEN == "PUT_YOUR_NEW_BOT_TOKEN_HERE"
    or TOKEN == "" then
    warn("กรุณาใส่ Telegram Bot Token")
    return
end

local A = RS:WaitForChild("ServerData")
    :WaitForChild("ActiveEggs")

local ENV = getgenv()
ENV.RideEggRun = (ENV.RideEggRun or 0) + 1
local RUN = ENV.RideEggRun

ENV.EggMonitorEnabled = true

local MAX_COLLECT = 2
local MAP_WAIT = 2
local REOPEN_DELAY = 10
local COLLECT_TIMEOUT = 300

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

local function alive()
    return ENV.RideEggRun == RUN
end

--==================================================
-- TELEGRAM API
--==================================================

local API = "https://api.telegram.org/bot" .. TOKEN

local function api(method, body)
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

local function send(text)
    return api("sendMessage", {
        chat_id = CHAT,
        text = text
    })
end

local function photoUrl(id)
    local ok, res = pcall(function()
        return H({
            Url =
                "https://thumbnails.roblox.com/v1/assets"
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

    if item and item.state == "Completed" then
        return item.imageUrl
    end

    return nil
end

--==================================================
-- MINI UI
--==================================================

for _, name in ipairs({
    "RideEggStatus",
    "EggMonitorUI",
    "EggMonitorMini"
}) do
    local old = PG:FindFirstChild(name)

    if old then
        old:Destroy()
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "EggMonitorMini"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = PG

local button = Instance.new("TextButton")
button.Name = "EggToggle"
button.Size = UDim2.fromOffset(68, 68)
button.Position = UDim2.new(0, 15, 0.45, 0)
button.BackgroundColor3 = Color3.fromRGB(8, 18, 32)
button.Text = "🥚"
button.TextSize = 34
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Parent = button

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(12, 12)
dot.Position = UDim2.new(1, -15, 0, 5)
dot.BorderSizePixel = 0
dot.Parent = button

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local function refreshButton()
    if ENV.EggMonitorEnabled then
        stroke.Color = Color3.fromRGB(0, 230, 130)
        dot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    else
        stroke.Color = Color3.fromRGB(255, 65, 65)
        dot.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
    end
end

refreshButton()

-- ลากปุ่มได้ทั้งมือถือและคอม
local dragging = false
local moved = false
local dragStart
local startPos
local activeInput

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        moved = false
        dragStart = input.Position
        startPos = button.Position
        activeInput = input
    end
end)

local dragChanged = UIS.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input == activeInput then

        local delta = input.Position - dragStart

        if delta.Magnitude > 8 then
            moved = true
        end

        button.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local dragEnded = UIS.InputEnded:Connect(function(input)
    if input == activeInput then
        dragging = false
    end
end)

button.Activated:Connect(function()
    if moved then
        moved = false
        return
    end

    ENV.EggMonitorEnabled = not ENV.EggMonitorEnabled
    refreshButton()

    if ENV.EggMonitorEnabled then
        task.spawn(send, "🟢 เปิดระบบ Egg Monitor แล้ว")
    else
        task.spawn(send, "🔴 ปิดระบบ Egg Monitor แล้ว")
    end
end)

--==================================================
-- GUI BUTTON PRESS
--==================================================

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
end

local function toggle5()
    local n = 0

    for _, name in ipairs(switches) do
        if not alive() then break end

        if press(findSwitch(name)) then
            n = n + 1
        end

        task.wait(0.3)
    end

    return n
end

--==================================================
-- MAP EGGS
--==================================================

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

                local w = parent:FindFirstChild("EggWeight", true)

                if w and w:IsA("TextLabel")
                    and w.Text ~= "" then
                    return w.Text
                end

                for _, x in ipairs(parent:GetDescendants()) do
                    if x:IsA("TextLabel")
                        and x ~= card.label
                        and x.Text:lower():find("kg", 1, true) then
                        return x.Text
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

--==================================================
-- ANNOUNCE EGG
--==================================================

local seenEggs = {}
local busy = false

local function announce(e)
    if not alive() or not e.Parent then return end

    local name = e:GetAttribute("Egg")
    local info = eggs[name]

    if not info then return end

    -- รอ Map Eggs อัปเดต
    task.wait(MAP_WAIT)

    if not alive()
        or not ENV.EggMonitorEnabled
        or not e.Parent then
        return
    end

    local weight = getWeight(name)

    -- ส่งทันทีหลังรอ 2 วินาที ไม่รอ KG ซ้ำอีก 10 วินาที
    -- หาก Map Eggs ยังไม่อัปเดต จะแจ้ง KG ว่ากำลังอัปเดต

    if not alive()
        or not ENV.EggMonitorEnabled
        or not e.Parent then
        return
    end

    local caption =
        info.emoji .. " พบ " .. name
        .. "\n⚖️ KG: " .. (weight or "กำลังอัปเดต")
        .. "\n🥚 กดปุ่มเพื่อเก็บไข่"

    local keyboard = {
        inline_keyboard = {{
            {
                text = "🥚 เก็บไข่",
                callback_data = "C" .. e.Name
            }
        }}
    }

    local url = photoUrl(info.id)
    local result

    if url then
        result = api("sendPhoto", {
            chat_id = CHAT,
            photo = url,
            caption = caption,
            reply_markup = keyboard
        })
    end

    if not result then
        api("sendMessage", {
            chat_id = CHAT,
            text = caption,
            reply_markup = keyboard
        })
    end
end

--==================================================
-- AUTO COLLECT
--==================================================

local function collectCycle(requestId)
    if busy then
        send("⏳ กำลังเก็บไข่รอบก่อนอยู่")
        return
    end

    if not ENV.EggMonitorEnabled then
        send("🔴 ระบบ Egg Monitor ปิดอยู่")
        return
    end

    local chosen = A:FindFirstChild(requestId)

    if not chosen or not eggs[chosen:GetAttribute("Egg")] then
        send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว")
        return
    end

    busy = true

    local function run()
        local wanted = chosen:GetAttribute("Egg")

        send("🥚 กำลังไปเก็บไข่\n" .. wanted)

        -- ปิด Halloween Event
        local off = toggle5()
        send("⏸ สั่งปิด Halloween Event " .. off .. "/5")

        task.wait(1)

        local ids = getIds()
        local cards = getCards()

        local watching = {}
        local used = {}
        local usedButtons = {}
        local count = 0

        table.sort(cards, function(a, b)
            return a.name == wanted and b.name ~= wanted
        end)

        for _, card in ipairs(cards) do
            if count >= MAX_COLLECT or not alive() then
                break
            end

            if not usedButtons[card.button] then
                local list = ids[card.name] or {}

                if card.name == wanted then
                    table.sort(list, function(a, b)
                        return a == requestId and b ~= requestId
                    end)
                end

                for _, id in ipairs(list) do
                    if not used[id] then
                        if press(card.button) then
                            used[id] = true
                            usedButtons[card.button] = true
                            watching[id] = card.name
                            count = count + 1

                            send(
                                "🥚 สั่ง Collect " .. count
                                .. "/" .. MAX_COLLECT
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

        local remaining = count
        local elapsed = 0

        while remaining > 0
            and elapsed < COLLECT_TIMEOUT
            and alive() do

            task.wait(2)
            elapsed = elapsed + 2

            for id, name in pairs(watching) do
                if not A:FindFirstChild(id) then
                    watching[id] = nil
                    remaining = remaining - 1

                    send(
                        "🥚 ไข่หาย: " .. name
                        .. "\nเหลือ " .. remaining .. " ใบ"
                    )
                end
            end
        end

        if not alive() then return end

        local collectedAll = count > 0 and remaining == 0

        if collectedAll then
            send(
                "✅ ไข่หายครบ " .. count
                .. " ใบ\n⏳ รอ 10 วินาทีก่อนเปิด Event"
            )

            task.wait(REOPEN_DELAY)
        elseif remaining > 0 then
            send(
                "⚠️ ครบ 5 นาที ยังเหลือ "
                .. remaining .. " ใบ"
            )
        end

        if not alive() then return end

        -- เปิด Halloween Event กลับ
        local on = toggle5()

        if collectedAll and on == 5 then
            send(
                "✅ เก็บไข่สำเร็จ!\n"
                .. "🥚 จำนวน " .. count .. " ใบ\n"
                .. "▶️ สั่งเปิด Halloween Event กลับแล้ว 5/5"
            )
        else
            send(
                "⚠️ จบกระบวนการเก็บไข่\n"
                .. "ไข่หายครบ: " .. tostring(collectedAll)
                .. "\nสั่งเปิด Event: " .. on .. "/5"
            )
        end
    end

    local ok, err = pcall(run)

    if not ok then
        send("❌ เกิดข้อผิดพลาด: " .. tostring(err))
    end

    busy = false
end

--==================================================
-- CONNECT TELEGRAM
--==================================================

local bot, botErr = api("getMe", {})

if not bot then
    warn("Telegram ERROR: " .. tostring(botErr))
    stroke.Color = Color3.fromRGB(255, 65, 65)
    return
end

local offset = 0

local init, initErr = api("getUpdates", {
    timeout = 0,
    limit = 100,
    allowed_updates = {"callback_query"}
})

if not init then
    warn("getUpdates ERROR: " .. tostring(initErr))
    return
end

for _, u in ipairs(init.result or {}) do
    offset = math.max(offset, u.update_id + 1)
end

send("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")

--==================================================
-- TELEGRAM CALLBACK POLLING
--==================================================

task.spawn(function()
    while alive() do
        local data, err = api("getUpdates", {
            offset = offset,
            timeout = 0,
            limit = 100,
            allowed_updates = {"callback_query"}
        })

        if data then
            for _, u in ipairs(data.result or {}) do
                offset = math.max(offset, u.update_id + 1)

                local cb = u.callback_query

                if cb and type(cb.data) == "string" then
                    local chat = cb.message
                        and cb.message.chat
                        and tostring(cb.message.chat.id)

                    if chat == CHAT
                        and cb.data:sub(1, 1) == "C" then

                        api("answerCallbackQuery", {
                            callback_query_id = cb.id,
                            text = ENV.EggMonitorEnabled
                                and "กำลังไปเก็บไข่"
                                or "ระบบปิดอยู่"
                        })

                        task.spawn(
                            collectCycle,
                            cb.data:sub(2)
                        )
                    end
                end
            end
        else
            warn("Telegram polling: " .. tostring(err))
        end

        task.wait(2)
    end
end)

--==================================================
-- MONITOR NEW EGGS
--==================================================

task.spawn(function()
    while alive() do
        if ENV.EggMonitorEnabled then
            for _, e in ipairs(A:GetChildren()) do
                local name = e:GetAttribute("Egg")

                if eggs[name] and not seenEggs[e.Name] then
                    seenEggs[e.Name] = true
                    task.spawn(announce, e)
                end
            end
        end

        task.wait(2)
    end
end)

--==================================================
-- CLEANUP OLD UI CONNECTIONS ON RE-RUN
--==================================================

task.spawn(function()
    while alive() do
        task.wait(2)
    end

    if dragChanged then dragChanged:Disconnect() end
    if dragEnded then dragEnded:Disconnect() end
end)
