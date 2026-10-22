
-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local H = (syn and syn.request)
    or (http and http.request)
    or http_request or request

local HS = game:GetService("HttpService")
local P = game.Players.LocalPlayer

local env = getgenv()
env.TGTestVersion = (env.TGTestVersion or 0) + 1
local version = env.TGTestVersion

local old = P.PlayerGui:FindFirstChild("TGTestUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TGTestUI"
gui.ResetOnSpawn = false
gui.Parent = P.PlayerGui

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(340, 130)
label.Position = UDim2.new(.5, -170, .3, 0)
label.BackgroundColor3 = Color3.fromRGB(20,20,20)
label.TextColor3 = Color3.new(1,1,1)
label.TextSize = 17
label.TextWrapped = true
label.Text = "กำลังเชื่อมต่อ Telegram..."
label.Parent = gui

local function status(s)
    label.Text = s
end

if not H or TOKEN == "ใส่_BOT_TOKEN_ของคุณ" then
    status("❌ กรุณาใส่ Bot Token")
    return
end

local API = "https://api.telegram.org/bot" .. TOKEN

local function request(method, body)
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

    if not ok then
        return nil, tostring(res)
    end

    local decoded, data = pcall(function()
        return HS:JSONDecode(res.Body or "{}")
    end)

    if not decoded then
        return nil, "HTTP " .. tostring(res.StatusCode)
    end

    if not data.ok then
        return nil, tostring(data.description)
    end

    return data
end

-- ตรวจสอบการเชื่อมต่อ
local bot, err = request("getMe", {})

if not bot then
    status("❌ BOT ERROR\n" .. tostring(err))
    return
end

-- อ่านอัปเดตเก่าก่อนส่งปุ่มใหม่
local offset = 0
local init = request("getUpdates", {
    timeout = 0,
    limit = 100
})

if init then
    for _, u in ipairs(init.result or {}) do
        offset = math.max(offset, u.update_id + 1)
    end
else
    status("⚠️ getUpdates มีปัญหา")
end

local testId = "TEST_" .. tostring(math.random(100000,999999))

-- ส่งปุ่มทดสอบ
local sent, sendErr = request("sendMessage", {
    chat_id = CHAT,
    text = "🧪 ทดสอบ Telegram → Roblox\nกดปุ่มด้านล่างเพื่อทดสอบ",
    reply_markup = {
        inline_keyboard = {{
            {
                text = "✅ ทดสอบกดปุ่ม",
                callback_data = testId
            }
        }}
    }
})

if not sent then
    status("❌ ส่งปุ่มไม่สำเร็จ\n" .. tostring(sendErr))
    return
end

status("✅ ส่งปุ่มแล้ว\nรอกดจาก Telegram...")

-- รับคำสั่งจาก Telegram
task.spawn(function()
    while env.TGTestVersion == version do

        local data, pollErr = request("getUpdates", {
            offset = offset,
            timeout = 0,
            limit = 100
        })

        if data then
            for _, u in ipairs(data.result or {}) do
                offset = math.max(offset, u.update_id + 1)

                local cb = u.callback_query

                if cb and cb.data == testId then
                    local chat = cb.message
                        and cb.message.chat
                        and tostring(cb.message.chat.id)

                    if chat == CHAT then
                        status("✅ รับคำสั่ง Telegram สำเร็จ!")

                        request("answerCallbackQuery", {
                            callback_query_id = cb.id,
                            text = "Roblox ได้รับคำสั่งแล้ว!"
                        })

                        request("sendMessage", {
                            chat_id = CHAT,
                            text = "✅ Roblox Delta รับคำสั่งสำเร็จ!"
                        })
                    end
                end
            end
        else
            status("❌ GET UPDATES ERROR\n"
                .. tostring(pollErr))
        end

        task.wait(3)
    end
end)
