
-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local P = game:GetService("Players").LocalPlayer
local R = {P.PlayerGui, game.CoreGui}
local S = game:GetService("StarterGui")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local A = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")
local H = (syn and syn.request) or (http and http.request)
    or http_request or request

local MAX = 2
local TIMEOUT = 300
local REOPEN_DELAY = 10

local switches = {
    "Auto Collect Candy",
    "Auto Search Pumpkins",
    "Auto Trick Or Treat",
    "Auto Halloween Ritual",
    "Collect Rare Eggs First"
}

local eggs = {
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

if not H or TOKEN == "PUT_NEW_BOT_TOKEN_HERE" then
    warn("Set Telegram TOKEN and enable HTTP requests")
    return
end

getgenv().RideEggVersion =
    (getgenv().RideEggVersion or 0) + 1

local version = getgenv().RideEggVersion

local function alive()
    return getgenv().RideEggVersion == version
end

local function msg(t)
    pcall(function()
        S:SetCore("SendNotification", {
            Title = "EGG AUTO",
            Text = t,
            Duration = 6
        })
    end)
end

local function call(method, body)
    local ok, res = pcall(function()
        return H({
            Url = "https://api.telegram.org/bot"
                .. TOKEN .. "/" .. method,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HS:JSONEncode(body)
        })
    end)

    if not ok or not res then return nil end

    local good, obj = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    return good and obj or nil
end

local function send(t)
    return call("sendMessage", {
        chat_id = CHAT,
        text = t
    })
end

local function photoUrl(id)
    local ok, res = pcall(function()
        return H({
            Url = "https://thumbnails.roblox.com/v1/assets"
                .. "?assetIds=" .. id
                .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
    end)

    if not ok or not res then return nil end

    local good, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    return good and data.data
        and data.data[1]
        and data.data[1].imageUrl or nil
end

-- กดปุ่มแบบเดียวกับโค้ดเดิม
local function press(b)
    if not b or not b:IsA("GuiButton") then
        return false
    end

    local n = 0

    pcall(function()
        for _, c in ipairs(getconnections(b.Activated)) do
            if c.Function then
                c.Function()
                n = n + 1
            end
        end
    end)

    return n > 0
end

-- ปิด/เปิด Halloween Event ทั้ง 5
local function toggle5()
    local n = 0

    for _, name in ipairs(switches) do
        for _, r in ipairs(R) do
            local v = r:FindFirstChild(name, true)

            if v and v:IsA("Frame") then
                local sw = v:FindFirstChild("Switch", true)
                local b = sw and sw:FindFirstChild("Button", true)

                if press(b) then
                    n = n + 1
                end

                break
            end
        end

        task.wait(.3)
    end

    return n
end

-- ค้นหาการ์ดไข่และปุ่ม Open
local function getCards()
    local cards = {}
    local seen = {}

    for _, r in ipairs(R) do
        for _, v in ipairs(r:GetDescendants()) do
            if v:IsA("TextLabel") and eggs[v.Text] then
                local p = v.Parent

                for i = 1, 3 do
                    if not p then break end

                    local b = p:FindFirstChild("Open")

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

                    p = p.Parent
                end
            end
        end
    end

    return cards
end

-- UUID ของไข่ที่ยังอยู่
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

-- ค้นหาน้ำหนักจากการ์ดไข่
local function getWeight(name)
    for _, card in ipairs(getCards()) do
        if card.name == name then
            local p = card.label.Parent

            for _ = 1, 4 do
                if not p then break end

                local weight = p:FindFirstChild("EggWeight", true)

                if weight
                    and weight:IsA("TextLabel")
                    and weight.Text ~= "" then
                    return weight.Text
                end

                for _, x in ipairs(p:GetDescendants()) do
                    if x:IsA("TextLabel")
                        and x ~= card.label
                        and x.Text:lower():find("kg", 1, true) then
                        return x.Text
                    end
                end

                p = p.Parent
            end
        end
    end

    return "ไม่ทราบ (เปิด Map Eggs เพื่ออ่าน KG)"
end

local seen = {}
local busy = false

-- แจ้งเตือนพร้อมรูปและปุ่ม Telegram
local function announce(e)
    local name = e:GetAttribute("Egg")
    local egg = eggs[name]

    if not egg then return end

    local caption =
        egg.emoji .. " พบ " .. name
        .. "\n⚖️ KG: " .. getWeight(name)
        .. "\n🥚 กดปุ่มเพื่อเก็บไข่"

    local keyboard = {
        inline_keyboard = {{
            {
                text = "🥚 เก็บไข่",
                callback_data = "C" .. e.Name
            }
        }}
    }

    local url = photoUrl(egg.id)
    local res

    if url then
        res = call("sendPhoto", {
            chat_id = CHAT,
            photo = url,
            caption = caption,
            reply_markup = keyboard
        })
    end

    if not res or not res.ok then
        call("sendMessage", {
            chat_id = CHAT,
            text = caption,
            reply_markup = keyboard
        })
    end
end

-- กด Telegram แล้วเริ่มกระบวนการเดิม
local function collectCycle(requestId)
    if busy then
        send("⏳ กำลังทำงานรอบก่อนอยู่ กรุณารอจนเปิด Event กลับ")
        return
    end

    local chosen = A:FindFirstChild(requestId)

    if not chosen or not eggs[chosen:GetAttribute("Egg")] then
        send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว")
        return
    end

    busy = true

    local function run()
        -- 1. ปิด Event
        msg("กำลังปิด Halloween Event")
        send("⏸ กำลังปิด Halloween Event")

        local off = toggle5()

        msg("สั่งปิด Event " .. off .. "/5")
        send("⏸ สั่งปิด Event " .. off .. "/5")

        task.wait(1)

        -- 2. ค้นหาไข่
        local ids = getIds()
        local cards = getCards()

        local watching = {}
        local used = {}
        local count = 0

        local wanted = chosen:GetAttribute("Egg")

        -- ไข่ที่กดจาก Telegram มาก่อน
        table.sort(cards, function(a, b)
            return (a.name == wanted) and (b.name ~= wanted)
        end)

        -- 3. กด Collect สูงสุด 2 ใบ
        for _, card in ipairs(cards) do
            if count >= MAX then break end

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
                        watching[id] = card.name
                        count = count + 1

                        msg(
                            "🥚 Collect " .. count
                            .. "/" .. MAX .. ": " .. card.name
                        )

                        send(
                            "🥚 สั่ง Collect " .. count
                            .. "/" .. MAX .. ": " .. card.name
                        )
                    end

                    break
                end
            end

            task.wait(.3)
        end

        msg("ส่งคำสั่ง Collect " .. count .. " ใบ")

        -- 4. รอไข่หายจาก ActiveEggs
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

                    msg(
                        "🥚 ไข่หาย: " .. name
                        .. " | เหลือ " .. remaining .. " ใบ"
                    )

                    send(
                        "🥚 ไข่หาย: " .. name
                        .. " | เหลือ " .. remaining .. " ใบ"
                    )
                end
            end
        end

        -- 5. รอ 10 วินาทีหรือครบ 5 นาที
        if remaining == 0 and count > 0 then
            msg("✅ ไข่หายครบ " .. count .. " ใบ")

            send(
                "✅ ไข่หายครบ " .. count
                .. " ใบ\n⏳ รอ 10 วินาทีก่อนเปิด Event"
            )

            task.wait(REOPEN_DELAY)

        elseif remaining > 0 then
            msg("ครบ 5 นาที ยังเหลือ " .. remaining .. " ใบ")

            send(
                "⚠️ ครบ 5 นาที ยังเหลือ "
                .. remaining .. " ใบ"
            )

        else
            msg("ไม่มีไข่ที่สั่ง Collect")
            send("⚠️ ไม่มีไข่ที่สั่ง Collect")
        end

        -- 6. เปิด Event กลับ
        msg("กำลังเปิด Halloween Event")

        local on = toggle5()

        msg("เปิด Event กลับ " .. on .. "/5")
        send("▶️ สั่งเปิด Event กลับ " .. on .. "/5")
    end

    local ok, err = pcall(run)

    if not ok then
        msg("ERROR: " .. tostring(err))
        send("❌ เกิดข้อผิดพลาด: " .. tostring(err))
    end

    busy = false
end

-- รับคำสั่งจากปุ่ม Telegram
task.spawn(function()
    local offset = 0

    local init = call("getUpdates", {
        timeout = 0
    })

    if init and init.ok then
        for _, u in ipairs(init.result or {}) do
            offset = math.max(offset, u.update_id + 1)
        end
    end

    while alive() do
        local data = call("getUpdates", {
            offset = offset,
            timeout = 0,
            limit = 30
        })

        if data and data.ok then
            for _, u in ipairs(data.result or {}) do
                offset = math.max(offset, u.update_id + 1)

                local cb = u.callback_query

                if cb
                    and type(cb.data) == "string"
                    and cb.data:sub(1, 1) == "C" then

                    local source = cb.message
                        and cb.message.chat
                        and tostring(cb.message.chat.id)

                    call("answerCallbackQuery", {
                        callback_query_id = cb.id,
                        text = "รับคำสั่งแล้ว"
                    })

                    if source == CHAT then
                        task.spawn(
                            collectCycle,
                            cb.data:sub(2)
                        )
                    end
                end
            end
        end

        task.wait(3)
    end
end)

-- ตรวจไข่ใหม่
task.spawn(function()
    msg("EGG MONITOR เริ่มทำงาน")
    send("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")

    while alive() do
        for _, e in ipairs(A:GetChildren()) do
            if eggs[e:GetAttribute("Egg")]
                and not seen[e.Name] then

                seen[e.Name] = true
                task.spawn(announce, e)
            end
        end

        task.wait(2)
    end
end)
