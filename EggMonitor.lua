
-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")

local P = Players.LocalPlayer
local ROOTS = {P:WaitForChild("PlayerGui"), game.CoreGui}
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

if not H then
    warn("ไม่พบ HTTP request")
    return
end

if TOKEN == "" or TOKEN == "PUT_YOUR_BOT_TOKEN_HERE" then
    warn("กรุณาใส่ Telegram Bot Token")
    return
end

-- หยุดสคริปต์เวอร์ชันก่อน
local ENV = getgenv()
ENV.RideEggRun = (ENV.RideEggRun or 0) + 1

local RUN = ENV.RideEggRun

local function alive()
    return ENV.RideEggRun == RUN
end

-- ไม่มี GUI และไม่มี Notification กลางจอ
local function status(t)
    print("[RIDE EGG] " .. tostring(t))
end

-- ลบหน้าต่างสถานะเก่าของสคริปต์
local old = P.PlayerGui:FindFirstChild("RideEggStatus")
if old then
    old:Destroy()
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

-- กดปุ่ม GUI
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

-- หา Halloween Event Switch
local function findSwitch(name)
    for _, root in ipairs(ROOTS) do
        local frame = root:FindFirstChild(name, true)

        if frame then
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
    local n = 0

    for _, name in ipairs(switches) do
        if not alive() then
            break
        end

        if press(findSwitch(name)) then
            n = n + 1
        end

        task.wait(0.3)
    end

    return n
end

-- หา Map Eggs Card
local function getCards()
    local cards = {}
    local seen = {}

    for _, root in ipairs(ROOTS) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("TextLabel") then
                local name = v.Text

                if eggs[name] then
                    local parent = v.Parent

                    for _ = 1, 5 do
                        if not parent then
                            break
                        end

                        local b = parent:FindFirstChild("Open")

                        if b and b:IsA("GuiButton") then
                            if not seen[b] then
                                seen[b] = true

                                table.insert(cards, {
                                    name = name,
                                    button = b,
                                    label = v,
                                    container = parent
                                })
                            end

                            break
                        end

                        parent = parent.Parent
                    end
                end
            end
        end
    end

    return cards
end

-- อ่านน้ำหนักจากการ์ดที่ตรงกับไข่
local function readWeight(name)
    for _, card in ipairs(getCards()) do
        if card.name == name then
            local parent = card.container

            for _ = 1, 5 do
                if not parent then
                    break
                end

                local w = parent:FindFirstChild("EggWeight", true)

                if w and w:IsA("TextLabel") then
                    local value = w.Text

                    if value and value ~= ""
                        and value:lower():find("kg", 1, true) then
                        return value
                    end
                end

                -- สำรอง: ค้นหา TextLabel ที่มี KG
                for _, x in ipairs(parent:GetDescendants()) do
                    if x:IsA("TextLabel")
                        and x ~= card.label then

                        local value = x.Text

                        if value
                            and value:lower():find("kg", 1, true) then
                            return value
                        end
                    end
                end

                parent = parent.Parent
            end
        end
    end

    return nil
end

-- รอให้ GUI โหลดน้ำหนัก
local function getWeight(name)
    for attempt = 1, 12 do
        if not alive() then
            return "ไม่ทราบ"
        end

        local weight = readWeight(name)

        if weight then
            return weight
        end

        task.wait(0.5)
    end

    return "ไม่ทราบ"
end

-- รายการไข่ที่ยังอยู่ใน ActiveEggs
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

-- แจ้งเตือนพบไข่
local function announce(e)
    if not alive() or not e.Parent then
        return
    end

    local name = e:GetAttribute("Egg")
    local info = eggs[name]

    if not info then
        return
    end

    local weight = getWeight(name)

    if not alive() or not e.Parent then
        return
    end

    local caption =
        info.emoji .. " พบ " .. name
        .. "\n⚖️ KG: " .. weight
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

-- เก็บไข่ตามคำสั่ง Telegram
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

        -- 1. แจ้งว่ากำลังไปเก็บไข่
        status("กำลังไปเก็บไข่ " .. wanted)

        send(
            "🥚 กำลังไปเก็บไข่\n"
            .. wanted
        )

        -- 2. ปิด Halloween Event
        status("กำลังปิด Halloween Event")

        local off = toggle5()

        send(
            "⏸ สั่งปิด Halloween Event "
            .. off .. "/5"
        )

        task.wait(1)

        -- 3. Collect สูงสุด 2 ใบ
        local ids = getIds()
        local cards = getCards()

        local watching = {}
        local used = {}
        local usedButtons = {}
        local count = 0

        table.sort(cards, function(a, b)
            return a.name == wanted
                and b.name ~= wanted
        end)

        for _, card in ipairs(cards) do
            if count >= MAX or not alive() then
                break
            end

            if not usedButtons[card.button] then
                local list = ids[card.name] or {}

                if card.name == wanted then
                    table.sort(list, function(a, b)
                        return a == requestId
                            and b ~= requestId
                    end)
                end

                for _, id in ipairs(list) do
                    if count >= MAX then
                        break
                    end

                    if not used[id] then
                        if press(card.button) then
                            used[id] = true
                            usedButtons[card.button] = true
                            watching[id] = card.name
                            count = count + 1

                            status(
                                "Collect " .. count
                                .. "/" .. MAX
                                .. " " .. card.name
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

        -- 4. รอไข่ที่สั่ง Collect หายครบ
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

        if not alive() then
            return
        end

        local collectedAll =
            count > 0 and remaining == 0

        -- 5. รออีก 10 วินาที
        if collectedAll then
            status("ไข่หายครบ รอ 10 วินาที")

            send(
                "✅ ไข่หายครบ "
                .. count .. " ใบ"
                .. "\n⏳ รอ 10 วินาที"
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

        if not alive() then
            return
        end

        -- 6. เปิด Halloween Event กลับ
        status("กำลังเปิด Halloween Event กลับ")

        local on = toggle5()

        -- 7. ส่งผลเข้า Telegram
        if collectedAll and on == 5 then
            status("เก็บไข่สำเร็จ")

            send(
                "✅ เก็บไข่สำเร็จ!\n"
                .. "🥚 จำนวน " .. count .. " ใบ\n"
                .. "▶️ สั่งเปิด Halloween Event กลับ "
                .. on .. "/5"
            )
        else
            send(
                "⚠️ จบกระบวนการเก็บไข่\n"
                .. "ไข่หายครบ: "
                .. tostring(collectedAll)
                .. "\nสั่งเปิด Event: "
                .. on .. "/5"
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

-- ตรวจสอบ Telegram
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

-- รับปุ่ม Telegram
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
                offset = math.max(
                    offset,
                    u.update_id + 1
                )

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

-- ตรวจไข่ใหม่
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

