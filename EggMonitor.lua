
-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local SG = game:GetService("StarterGui")

local P = Players.LocalPlayer
local ROOTS = {P.PlayerGui, game.CoreGui}
local A = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")

local H = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

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
        id = "133246489138606",
        emoji = "🌌"
    },
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

if not H or TOKEN == "PUT_YOUR_NEW_BOT_TOKEN_HERE" then
    warn("กรุณาใส่ Telegram Bot Token")
    return
end

local ENV = getgenv()
ENV.RideEggRun = (ENV.RideEggRun or 0) + 1
local RUN = ENV.RideEggRun

local function alive()
    return ENV.RideEggRun == RUN
end

local function notify(t)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "EGG AUTO",
            Text = t,
            Duration = 6
        })
    end)
end

local old = P.PlayerGui:FindFirstChild("RideEggStatus")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RideEggStatus"
gui.ResetOnSpawn = false
gui.Parent = nil

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(350, 115)
label.Position = UDim2.new(.5, -175, .3, 0)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 17
label.TextWrapped = true
label.Text = "กำลังเชื่อมต่อ Telegram..."
label.Parent = gui

local function status(t)

end

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

local function send(t)
    return api("sendMessage", {
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

    if not good then return nil end

    local item = data.data and data.data[1]
    return item and item.imageUrl or nil
end

-- กด GUI แบบเดียวกับโค้ดที่เคยใช้ได้
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

-- ใช้การ Toggle เหมือนโค้ดต้นฉบับ
local function toggle5()
    local n = 0

    for _, name in ipairs(switches) do
        if press(findSwitch(name)) then
            n = n + 1
        end

        task.wait(.3)
    end

    return n
end

local function getCards()
    local cards = {}
    local seen = {}

    for _, root in ipairs(ROOTS) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("TextLabel") and eggs[v.Text] then
                local parent = v.Parent

                for _ = 1, 4 do
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

            for _ = 1, 4 do
                if not parent then break end

                local w = parent:FindFirstChild("EggWeight", true)

                if w and w:IsA("TextLabel")
                    and w.Text ~= "" then
                    return w.Text
                end

                parent = parent.Parent
            end
        end
    end

    return "ไม่ทราบ"
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

local seenEggs = {}
local busy = false

local function announce(e)
    if not alive() or not e.Parent then return end

    local name = e:GetAttribute("Egg")
    local info = eggs[name]

    if not info then return end

    local caption =
        info.emoji .. " พบ " .. name
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

-- กระบวนการเก็บไข่
local function collectCycle(requestId)
    if busy then
        send("⏳ กำลังเก็บไข่รอบก่อนอยู่")
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

        -- 1. แจ้ง Telegram
        status("กำลังไปเก็บไข่ " .. wanted)
        send("🥚 กำลังไปเก็บไข่\n" .. wanted)

        -- 2. ปิด Event
        status("กำลังปิด Halloween Event")
        local off = toggle5()

        send("⏸ สั่งปิด Halloween Event " .. off .. "/5")

        task.wait(1)

        -- 3. หาไข่และปุ่ม Collect
        local ids = getIds()
        local cards = getCards()

        local watching = {}
        local used = {}
        local usedButtons = {}
        local count = 0

        -- ให้ไข่ที่กดใน Telegram มาก่อน
        table.sort(cards, function(a, b)
            return (a.name == wanted and b.name ~= wanted)
        end)

        for _, card in ipairs(cards) do
            if count >= MAX then break end

            if not usedButtons[card.button] then
                local list = ids[card.name] or {}

                if card.name == wanted then
                    table.sort(list, function(a, b)
                        return a == requestId and b ~= requestId
                    end)
                end

                for _, id in ipairs(list) do
                    if count >= MAX then break end

                    if not used[id] then
                        if press(card.button) then
                            used[id] = true
                            usedButtons[card.button] = true
                            watching[id] = card.name
                            count = count + 1

                            status(
                                "Collect " .. count .. "/" .. MAX
                                .. ": " .. card.name
                            )

                            send(
                                "🥚 สั่ง Collect " .. count .. "/" .. MAX
                                .. "\n" .. card.name
                            )
                        end

                        break
                    end
                end
            end

            task.wait(.3)
        end

        if count == 0 then
            send("⚠️ ไม่พบปุ่ม Collect ใน Map Eggs")
        end

        -- 4. รอไข่หาย
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
                        .. "\nเหลือ " .. remaining .. " ใบ"
                    )
                end
            end
        end

        if not alive() then return end

        local collectedAll = count > 0 and remaining == 0

        -- 5. รอ 10 วินาที
        if collectedAll then
            status("ไข่หายครบ รอ 10 วินาที")

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
        else
            send("⚠️ ไม่มีไข่ที่สั่ง Collect")
        end

        if not alive() then return end

        -- 6. เปิด Event กลับ
        status("กำลังเปิด Halloween Event กลับ")
        local on = toggle5()

        send("▶️ สั่งเปิด Halloween Event " .. on .. "/5")

        -- 7. แจ้งผล
        if collectedAll and on == 5 then
            status("เก็บไข่สำเร็จ")

            send(
                "✅ เก็บไข่สำเร็จ!\n"
                .. "🥚 จำนวน " .. count .. " ใบ\n"
                .. "▶️ เปิด Halloween Event กลับแล้ว 5/5"
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
        status("ERROR: " .. tostring(err))
        send("❌ เกิดข้อผิดพลาด: " .. tostring(err))
    end

    busy = false
end

-- เชื่อมต่อ Telegram
local bot, botErr = api("getMe", {})

if not bot then
    status("BOT ERROR: " .. tostring(botErr))
    return
end

-- อ่าน Update เก่าก่อนเริ่ม
local offset = 0

local init, initErr = api("getUpdates", {
    timeout = 0,
    limit = 100,
    allowed_updates = {"callback_query"}
})

if not init then
    status("GET UPDATES ERROR: " .. tostring(initErr))
    return
end

for _, u in ipairs(init.result or {}) do
    offset = math.max(offset, u.update_id + 1)
end

status("EGG MONITOR เริ่มทำงาน")
send("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")

-- รับปุ่มจาก Telegram
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
                            text = "กำลังไปเก็บไข่"
                        })

                        task.spawn(
                            collectCycle,
                            cb.data:sub(2)
                        )
                    end
                end
            end
        else
            status("Telegram ERROR: " .. tostring(err))
        end

        task.wait(2)
    end
end)

-- ตรวจหาไข่ใหม่
task.spawn(function()
    while alive() do
        for _, e in ipairs(A:GetChildren()) do
            local name = e:GetAttribute("Egg")

            if eggs[name] and not seenEggs[e.Name] then
                seenEggs[e.Name] = true
                task.spawn(announce, e)
            end
        end

        task.wait(2)
    end
end)

