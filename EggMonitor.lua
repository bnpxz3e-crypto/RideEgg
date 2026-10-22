
-- RIDE A PET | EGG MONITOR
-- TELEGRAM + 4 EGG PHOTOS + COLLECT + EVENT 5

local TOKEN = "ใส่_TOKEN_ใหม่"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local SG = game:GetService("StarterGui")

local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local CG = game:GetService("CoreGui")
local A = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")

local H = (syn and syn.request)
    or (http and http.request)
    or http_request or request

local API = "https://api.telegram.org/bot" .. TOKEN

local EGGS = {
    ["Blackhole Egg"] = {
        id = "133246489138606", emoji = "🌌"
    },
    ["Volcanic Egg"] = {
        id = "132679696143806", emoji = "🌋"
    },
    ["Solaris Egg"] = {
        id = "131016816558781", emoji = "☀️"
    },
    ["Cherub Egg"] = {
        id = "78949206711037", emoji = "👼"
    }
}

local SWITCHES = {
    "Auto Collect Candy",
    "Auto Search Pumpkins",
    "Auto Trick Or Treat",
    "Auto Halloween Ritual",
    "Collect Rare Eggs First"
}

if not H or TOKEN == "ใส่_TOKEN_ใหม่" then
    warn("กรุณาตั้งค่า TOKEN / HTTP")
    return
end

-- ปิดสคริปต์รอบเก่าก่อนเริ่มรอบใหม่
getgenv().RideEggRun = (getgenv().RideEggRun or 0) + 1
local RUN = getgenv().RideEggRun

local function alive()
    return getgenv().RideEggRun == RUN
end

local function notify(s)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "EGG MONITOR",
            Text = s,
            Duration = 5
        })
    end)
end

local function api(method, body)
    local ok, res = pcall(function()
        return H({
            Url = API .. "/" .. method,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HS:JSONEncode(body)
        })
    end)

    if not ok or not res then return nil end

    local decoded, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    return decoded and data or nil
end

local function sendText(s)
    return api("sendMessage", {
        chat_id = CHAT,
        text = s
    })
end

local function imageURL(id)
    local ok, res = pcall(function()
        return H({
            Url = "https://thumbnails.roblox.com/v1/assets"
                .. "?assetIds=" .. id
                .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
    end)

    if not ok or not res then return nil end

    local decoded, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    if not decoded then return nil end

    local item = data.data and data.data[1]
    return item and item.imageUrl
end

-- กดปุ่มจาก callback ของ GUI
local function press(b)
    if not b or not b:IsA("GuiButton") then
        return false
    end

    if not getconnections then return false end

    for _, signal in ipairs({
        b.Activated,
        b.MouseButton1Click
    }) do
        local ok, connections = pcall(getconnections, signal)

        if ok then
            for _, c in ipairs(connections) do
                if c.Function then
                    local done = pcall(c.Function)
                    if done then return true end
                end
            end
        end
    end

    return false
end

-- ค้นหาข้อความใน GUI
local function findLabel(name)
    for _, root in ipairs({PG, CG}) do
        for _, v in ipairs(root:GetDescendants()) do
            if (v:IsA("TextLabel")
                or v:IsA("TextButton"))
                and v.Text == name then
                return v
            end
        end
    end
end

-- ปุ่ม Event: Switch > Holder > Button
local function eventButton(name)
    local label = findLabel(name)
    if not label then return nil end

    local p = label.Parent

    for _ = 1, 7 do
        if not p then break end

        local sw = p:FindFirstChild("Switch")
        local holder = sw and sw:FindFirstChild("Holder")
        local b = holder and holder:FindFirstChild("Button")

        if b and b:IsA("GuiButton") then
            return b
        end

        p = p.Parent
    end
end

-- อ่านสถานะ Event จาก GUI เท่าที่ตรวจได้
local function eventState(name)
    local label = findLabel(name)
    if not label then return nil end

    local p = label.Parent
    for _ = 1, 7 do
        if not p then break end

        local sw = p:FindFirstChild("Switch")
        if sw then
            for _, x in ipairs(sw:GetDescendants()) do
                if x:IsA("TextLabel") then
                    local t = x.Text:lower()
                    if t == "on" then return true end
                    if t == "off" then return false end
                end
            end
        end
        p = p.Parent
    end

    return nil
end

local function toggleEvents()
    local n = 0

    for _, name in ipairs(SWITCHES) do
        local b = eventButton(name)

        if b and press(b) then
            n = n + 1
        end

        task.wait(0.2)
    end

    return n
end

-- หา Open เฉพาะการ์ดไข่ที่ต้องการ
local function collectButton(name)
    local label = findLabel(name)
    if not label then return nil end

    local p = label.Parent

    for _ = 1, 5 do
        if not p then break end

        local b = p:FindFirstChild("Open")
        if b and b:IsA("GuiButton") then
            return b
        end

        p = p.Parent
    end
end

local function getEgg(uuid)
    local e = A:FindFirstChild(uuid)
    if not e then return nil end

    local name = e:GetAttribute("Egg")
    if EGGS[name] then
        return e, name
    end
end

local function getKG(name)
    local label = findLabel(name)
    if not label then return "ไม่ทราบ" end

    local p = label.Parent

    for _ = 1, 5 do
        if not p then break end

        local holder = p:FindFirstChild("Holder")
        local image = holder and holder:FindFirstChild("EggImage")
        local weight = image and image:FindFirstChild("EggWeight")

        if weight and weight:IsA("TextLabel") then
            return weight.Text
        end

        p = p.Parent
    end

    return "ไม่ทราบ"
end

local seen = {}
local pending = {}
local pendingCount = 0
local eventsPaused = false
local restoring = false

local function pauseEvents()
    if eventsPaused then return end

    eventsPaused = true
    local n = toggleEvents()

    notify("สั่งปิด Event " .. n .. "/5")
    sendText("⏸ สั่งปิด Event " .. n .. "/5 หัวข้อ")
end

local function restoreEvents()
    if restoring or not eventsPaused then return end

    restoring = true

    task.spawn(function()
        -- รอ 10 วินาทีหลังไข่ทั้งหมดที่สั่งเก็บหาย
        task.wait(10)

        if not alive() then return end

        -- ถ้ามีไข่ใหม่เข้าคิวระหว่างรอ ให้เลื่อนออกไป
        if pendingCount > 0 then
            restoring = false
            return
        end

        local n = toggleEvents()
        eventsPaused = false
        restoring = false

        notify("สั่งเปิด Event " .. n .. "/5")
        sendText("▶️ สั่งเปิด Event กลับ "
            .. n .. "/5 หัวข้อ")
    end)
end

local function collectEgg(uuid)
    if pending[uuid] then return end

    local e, name = getEgg(uuid)

    if not e then
        sendText("⚠️ ไม่พบไข่แล้ว: " .. uuid)
        return
    end

    if pendingCount >= 2 then
        sendText("⚠️ กำลังเก็บไข่ครบ 2 ใบแล้ว")
        return
    end

    pauseEvents()
    task.wait(0.4)

    local b = collectButton(name)

    if not b then
        sendText("❌ ไม่พบปุ่ม Collect: " .. name)
        if pendingCount == 0 then restoreEvents() end
        return
    end

    if not press(b) then
        sendText("❌ กด Collect ไม่สำเร็จ: " .. name)
        if pendingCount == 0 then restoreEvents() end
        return
    end

    pending[uuid] = {
        name = name,
        started = os.clock()
    }

    pendingCount = pendingCount + 1

    notify("สั่ง Collect: " .. name)

    sendText(
        "🥚 สั่ง Collect: " .. name ..
        "\n📦 กำลังติดตามไข่ " ..
        pendingCount .. "/2"
    )
end

-- แจ้งรูปไข่พร้อมปุ่ม Collect
local function announce(e)
    local name = e:GetAttribute("Egg")
    local egg = EGGS[name]
    if not egg then return end

    local uuid = e.Name
    local kg = getKG(name)

    local caption =
        egg.emoji .. " พบ " .. name ..
        "\n⚖️ KG: " .. kg ..
        "\n🥚 กดปุ่มเพื่อเก็บไข่"

    local keyboard = {
        inline_keyboard = {{
            {
                text = "🥚 เก็บไข่",
                callback_data = "C" .. uuid
            }
        }}
    }

    local url = imageURL(egg.id)
    local result

    if url then
        result = api("sendPhoto", {
            chat_id = CHAT,
            photo = url,
            caption = caption,
            reply_markup = keyboard
        })
    end

    if not result or not result.ok then
        result = api("sendMessage", {
            chat_id = CHAT,
            text = caption,
            reply_markup = keyboard
        })
    end

    if result and result.ok then
        notify("พบไข่: " .. name)
    end
end

-- Telegram polling
task.spawn(function()
    local offset = 0

    -- ข้ามคำสั่งเก่าที่ค้างก่อนเริ่มสคริปต์
    local ok, res = pcall(function()
        return H({
            Url = API .. "/getUpdates?timeout=0",
            Method = "GET"
        })
    end)

    if ok and res then
        local decoded, data = pcall(function()
            return HS:JSONDecode(res.Body or "{}")
        end)

        if decoded and data.ok then
            for _, u in ipairs(data.result or {}) do
                offset = math.max(offset, u.update_id + 1)
            end
        end
    end

    while alive() do
        local ok2, res2 = pcall(function()
            return H({
                Url = API .. "/getUpdates?offset="
                    .. offset .. "&timeout=0",
                Method = "GET"
            })
        end)

        if ok2 and res2 then
            local decoded, data = pcall(function()
                return HS:JSONDecode(res2.Body or "{}")
            end)

            if decoded and data.ok then
                for _, u in ipairs(data.result or {}) do
                    offset = math.max(offset, u.update_id + 1)

                    local cb = u.callback_query

                    if cb and cb.data
                        and cb.data:sub(1, 1) == "C" then

                        local fromChat = cb.message
                            and cb.message.chat
                            and tostring(cb.message.chat.id)

                        api("answerCallbackQuery", {
                            callback_query_id = cb.id,
                            text = "รับคำสั่งแล้ว"
                        })

                        if fromChat == CHAT then
                            local uuid = cb.data:sub(2)
                            task.spawn(collectEgg, uuid)
                        end
                    end
                end
            end
        end

        task.wait(3)
    end
end)

-- ตรวจไข่ใหม่และติดตามไข่ที่สั่งเก็บ
task.spawn(function()
    notify("EGG MONITOR เริ่มทำงาน")
    sendText("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")

    while alive() do
        for _, e in ipairs(A:GetChildren()) do
            local name = e:GetAttribute("Egg")

            if EGGS[name] and not seen[e.Name] then
                seen[e.Name] = true
                task.spawn(announce, e)
            end
        end

        for uuid, info in pairs(pending) do
            if not A:FindFirstChild(uuid) then
                pending[uuid] = nil
                pendingCount = math.max(0, pendingCount - 1)

                notify("ไข่หายจากรายการ: " .. info.name)

                sendText(
                    "✅ ไข่หายจากรายการแล้ว: " ..
                    info.name ..
                    "\n📦 เหลือรอติดตาม " ..
                    pendingCount .. " ใบ"
                )

                if pendingCount == 0 then
                    restoreEvents()
                end

            elseif os.clock() - info.started > 180 then
                pending[uuid] = nil
                pendingCount = math.max(0, pendingCount - 1)

                sendText(
                    "⚠️ รอ Collect เกิน 180 วินาที: " ..
                    info.name
                )

                if pendingCount == 0 then
                    restoreEvents()
                end
            end
        end

        task.wait(2)
    end
end)
