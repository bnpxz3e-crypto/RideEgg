-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local ROOTS = {PG, game:GetService("CoreGui")}
local Active = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")
local HTTP = (syn and syn.request) or (http and http.request) or http_request or request
local ENV = getgenv()
ENV.RideEggRun = (ENV.RideEggRun or 0) + 1
local RUN = ENV.RideEggRun
local function alive() return ENV.RideEggRun == RUN end

local MAX_COLLECT = 2
local MAP_WAIT = 10
local WEIGHT_RETRIES = 8
local COLLECT_TIMEOUT = 300
local REOPEN_DELAY = 10
local SWITCH_NAMES = {
    "Auto Collect Candy", "Auto Search Pumpkins", "Auto Trick Or Treat",
    "Auto Halloween Ritual", "Collect Rare Eggs First"
}
local EGGS = {
    ["Volcanic Egg"] = {id="132679696143806", icon="🌋"},
    ["Solaris Egg"] = {id="131016816558781", icon="☀️"},
    ["Cherub Egg"] = {id="78949206711037", icon="👼"}
}

-- UI
local old = PG:FindFirstChild("RideEggNeon")
if old then old:Destroy() end
local ui = Instance.new("ScreenGui")
ui.Name = "RideEggNeon"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.DisplayOrder = 250
ui.Parent = PG
local function corner(o,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o
end
local function stroke(o,color,w)
    local s=Instance.new("UIStroke"); s.Color=color; s.Thickness=w or 1; s.Parent=o
end
local function text(parent,str,size,color,bold)
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1; t.Text=str; t.TextSize=size
    t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextColor3=color; t.TextWrapped=true; t.Parent=parent
    return t
end
local gold=Color3.fromRGB(255,196,70)
local dark=Color3.fromRGB(14,18,30)
local white=Color3.fromRGB(242,245,255)
local eggButton=Instance.new("TextButton")
eggButton.Name="EggMenuButton"; eggButton.Size=UDim2.fromOffset(58,58)
eggButton.Position=UDim2.new(1,-76,.40,0)
eggButton.BackgroundColor3=dark; eggButton.Text="🥚"; eggButton.TextSize=29
 eggButton.TextColor3=white; eggButton.Parent=ui
corner(eggButton,18); stroke(eggButton,gold,2)
local panel=Instance.new("Frame")
panel.Name="ControlPanel"; panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.5); panel.Size=UDim2.fromOffset(320,292)
panel.BackgroundColor3=dark; panel.Visible=false; panel.Parent=ui
corner(panel,18); stroke(panel,gold,2)
local gradient=Instance.new("UIGradient")
gradient.Color=ColorSequence.new(Color3.fromRGB(27,31,53),dark)
gradient.Rotation=90; gradient.Parent=panel
local heading=text(panel,"🥚  EGG MONITOR",20,gold,true)
heading.Size=UDim2.new(1,-70,0,42); heading.Position=UDim2.fromOffset(16,10)
heading.TextXAlignment=Enum.TextXAlignment.Left
local close=Instance.new("TextButton")
close.Size=UDim2.fromOffset(36,36); close.Position=UDim2.new(1,-46,0,12)
close.Text="×"; close.TextSize=28; close.Font=Enum.Font.GothamBold
close.TextColor3=white; close.BackgroundColor3=Color3.fromRGB(183,54,66)
close.Parent=panel; corner(close,10)
local line=Instance.new("Frame")
line.Size=UDim2.new(1,-28,0,1); line.Position=UDim2.fromOffset(14,59)
line.BackgroundColor3=Color3.fromRGB(75,75,90); line.BorderSizePixel=0; line.Parent=panel
local power=Instance.new("TextButton")
power.Size=UDim2.new(1,-32,0,55); power.Position=UDim2.fromOffset(16,74)
power.TextSize=19; power.Font=Enum.Font.GothamBold
power.TextColor3=white; power.Parent=panel; corner(power,13)
local statusLabel=text(panel,"เริ่มต้นระบบ...",16,white,true)
statusLabel.Size=UDim2.new(1,-34,0,66); statusLabel.Position=UDim2.fromOffset(17,143)
local detail=text(panel,"รอการตรวจสอบไข่",13,Color3.fromRGB(179,188,211),false)
detail.Size=UDim2.new(1,-34,0,53); detail.Position=UDim2.fromOffset(17,215)
local function setStatus(s) if alive() and ui.Parent then statusLabel.Text=s end end
local function setDetail(s) if alive() and ui.Parent then detail.Text=s end end
local enabled=true
local function paintPower()
    power.Text=enabled and "● ระบบเปิด  ON" or "● ระบบปิด  OFF"
    power.BackgroundColor3=enabled and Color3.fromRGB(21,143,99) or Color3.fromRGB(166,49,66)
end
paintPower()
eggButton.Activated:Connect(function() panel.Visible=not panel.Visible end)
close.Activated:Connect(function() panel.Visible=false end)
power.Activated:Connect(function()
    enabled=not enabled; paintPower()
    setStatus(enabled and "🟢 เปิดตรวจไข่แล้ว" or "🔴 หยุดตรวจไข่ใหม่")
end)

if not HTTP then setStatus("❌ Delta ไม่รองรับ HTTP request"); return end
if TOKEN=="" or TOKEN=="PUT_NEW_TELEGRAM_BOT_TOKEN_HERE" then
    setStatus("⚠️ กรุณาใส่ Bot Token ใหม่"); panel.Visible=true; return
end
local API="https://api.telegram.org/bot"..TOKEN
local function api(method,body)
    local ok,res=pcall(function()
        return HTTP({Url=API.."/"..method,Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=HS:JSONEncode(body or {})})
    end)
    if not ok or not res then return nil,tostring(res) end
    local good,data=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
    if not good then return nil,"HTTP "..tostring(res.StatusCode) end
    if not data.ok then return nil,tostring(data.description or res.StatusCode) end
    return data
end
local function send(message)
    return api("sendMessage",{chat_id=CHAT,text=message})
end
local function photoURL(id)
    local ok,res=pcall(function()
        return HTTP({Url="https://thumbnails.roblox.com/v1/assets?assetIds="..id..
            "&size=420x420&format=Png&isCircular=false",Method="GET"})
    end)
    if not ok or not res then return nil end
    local parsed,d=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
    if not parsed then return nil end
    local item=d.data and d.data[1]
    if item and item.state=="Completed" then return item.imageUrl end
    return nil
end

local function press(b)
    if not b or not b:IsA("GuiButton") then return false end
    local success=false
    if type(getconnections)=="function" then
        pcall(function()
            for _,signal in ipairs({b.Activated,b.MouseButton1Click}) do
                for _,connection in ipairs(getconnections(signal)) do
                    if connection.Function then
                        connection.Function()
                        success=true
                        break
                    end
                end
                if success then break end
            end
        end)
    end
    return success
end
local function findSwitch(name)
    for _,root in ipairs(ROOTS) do
        local frame=root:FindFirstChild(name,true)
        if frame then
            local sw=frame:FindFirstChild("Switch",true)
            local b=sw and sw:FindFirstChild("Button",true)
            if b and b:IsA("GuiButton") then return b end
        end
    end
end
local function switchGroup()
    local toggled={}
    for _,name in ipairs(SWITCH_NAMES) do
        if not alive() then break end
        local b=findSwitch(name)
        if press(b) then table.insert(toggled,name) end
        task.wait(.25)
    end
    return toggled
end
local function restoreGroup(toggled)
    local n=0
    for _,name in ipairs(toggled) do
        local b=findSwitch(name)
        if press(b) then n=n+1 end
        task.wait(.25)
    end
    return n
end
local function getCards()
    local cards={}; local seen={}
    for _,root in ipairs(ROOTS) do
        for _,v in ipairs(root:GetDescendants()) do
            if v:IsA("TextLabel") and EGGS[v.Text] then
                local parent=v.Parent
                for _=1,6 do
                    if not parent then break end
                    local b=parent:FindFirstChild("Open")
                    if b and b:IsA("GuiButton") then
                        if not seen[b] then
                            seen[b]=true
                            table.insert(cards,{name=v.Text,label=v,button=b,frame=parent})
                        end
                        break
                    end
                    parent=parent.Parent
                end
            end
        end
    end
    return cards
end
local function readWeight(name)
    for _,card in ipairs(getCards()) do
        if card.name==name then
            local root=card.frame
            local w=root:FindFirstChild("EggWeight",true)
            if w and w:IsA("TextLabel") and w.Text:match("%d") then
                return w.Text
            end
            for _,d in ipairs(root:GetDescendants()) do
                if d:IsA("TextLabel") and d~=card.label
                    and d.Text:lower():find("kg",1,true) and d.Text:match("%d") then
                    return d.Text
                end
            end
        end
    end
end
local function eggName(e) return e:GetAttribute("Egg") end
local function getAvailable()
    local byName={}
    for _,e in ipairs(Active:GetChildren()) do
        local name=eggName(e)
        if EGGS[name] then
            byName[name]=byName[name] or {}
            table.insert(byName[name],e.Name)
        end
    end
    return byName
end
local seenEggs={}; local busy=false
local function announce(e)
    local name=eggName(e)
    local info=EGGS[name]
    if not info or not alive() or not enabled then return end
    setStatus(info.icon.." พบ "..name)
    setDetail("⏳ รอ Map Eggs 10 วินาที")
    task.wait(MAP_WAIT)
    if not alive() or not enabled or not e.Parent then return end
    local weight
    for i=1,WEIGHT_RETRIES do
        weight=readWeight(name)
        if weight then break end
        setDetail("🔎 กำลังอ่านน้ำหนัก "..i.."/"..WEIGHT_RETRIES)
        task.wait(2)
        if not alive() or not enabled or not e.Parent then return end
    end
    if not weight then
        -- Do not send a misleading unknown weight; keep retrying while egg exists.
        setDetail("⚠️ ยังอ่าน KG ไม่ได้ รอ Map Eggs")
        while alive() and enabled and e.Parent do
            task.wait(3)
            weight=readWeight(name)
            if weight then break end
        end
    end
    if not weight or not alive() or not enabled or not e.Parent then return end
    local caption=info.icon.." พบ "..name.."\n⚖️ KG: "..weight.."\n🥚 กดปุ่มเพื่อเก็บไข่"
    local keyboard={inline_keyboard={{{text="🥚 เก็บไข่",callback_data="C"..e.Name}}}}
    local result
    for _=1,3 do
        local url=photoURL(info.id)
        if url then
            result=api("sendPhoto",{chat_id=CHAT,photo=url,caption=caption,reply_markup=keyboard})
            if result then break end
        end
        task.wait(2)
    end
    if not result then
        result=api("sendMessage",{chat_id=CHAT,text=caption,reply_markup=keyboard})
    end
    setDetail(result and ("📨 ส่ง Telegram แล้ว | "..weight) or "❌ ส่ง Telegram ไม่สำเร็จ")
end

local function collectCycle(id)
    if busy then send("⏳ กำลังเก็บไข่รอบก่อนอยู่"); return end
    if not enabled then send("🔴 ระบบ Egg Monitor ปิดอยู่"); return end
    local target=Active:FindFirstChild(id)
    if not target or not EGGS[eggName(target)] then
        send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว"); return
    end
    busy=true
    local switched={}
    local function cycle()
        local wanted=eggName(target)
        setStatus("🥚 กำลังไปเก็บไข่ "..wanted)
        send("🥚 กำลังไปเก็บไข่\n"..wanted)
        setDetail("⏸ กำลังปิด Halloween Event")
        switched=switchGroup()
        send("⏸ สั่งปิด Halloween Event "..#switched.."/5")
        if #switched~=5 then
            error("กดสวิตช์ Event ไม่ครบ 5/5 ยกเลิก Collect เพื่อป้องกันสถานะผิด")
        end
        task.wait(1)
        local cards=getCards(); local available=getAvailable()
        table.sort(cards,function(a,b)
            return (a.name==wanted and b.name~=wanted)
        end)
        local watching={}; local used={}; local usedButtons={}; local count=0
        for _,card in ipairs(cards) do
            if count>=MAX_COLLECT or not alive() then break end
            if not usedButtons[card.button] then
                local list=available[card.name] or {}
                if card.name==wanted then
                    table.sort(list,function(a,b) return a==id and b~=id end)
                end
                for _,eggId in ipairs(list) do
                    if not used[eggId] and Active:FindFirstChild(eggId) then
                        if press(card.button) then
                            used[eggId]=true; usedButtons[card.button]=true
                            watching[eggId]=card.name; count=count+1
                            setDetail("🥚 Collect "..count.."/"..MAX_COLLECT.." "..card.name)
                            send("🥚 สั่ง Collect "..count.."/"..MAX_COLLECT.."\n"..card.name)
                        end
                        break
                    end
                end
            end
            task.wait(.3)
        end
        if count==0 then error("ไม่พบปุ่ม Collect ที่กดได้ใน Map Eggs") end
        local remaining=count; local elapsed=0
        setStatus("⏳ รอไข่ที่ Collect หาย "..remaining.." ใบ")
        while remaining>0 and elapsed<COLLECT_TIMEOUT and alive() do
            task.wait(2); elapsed=elapsed+2
            for eggId,name in pairs(watching) do
                if not Active:FindFirstChild(eggId) then
                    watching[eggId]=nil; remaining=remaining-1
                    setDetail("🥚 ไข่หาย "..name.." | เหลือ "..remaining)
                end
            end
        end
        if not alive() then return end
        if remaining>0 then error("หมดเวลารอไข่ ยังเหลือ "..remaining.." ใบ") end
        setStatus("✅ ไข่หายครบ รออีก 10 วินาที")
        task.wait(REOPEN_DELAY)
        if not alive() then return end
        local on=restoreGroup(switched)
        switched={}
        if on==5 then
            setStatus("✅ เก็บไข่สำเร็จ "..count.." ใบ")
            setDetail("▶️ เปิด Halloween Event กลับ 5/5")
            send("✅ เก็บไข่สำเร็จ!\n🥚 จำนวน "..count.." ใบ\n▶️ เปิด Halloween Event กลับแล้ว 5/5")
        else
            send("⚠️ ไข่หายครบ แต่เปิด Event กลับได้ "..on.."/5 กรุณาตรวจสอบ")
        end
    end
    local ok,err=pcall(cycle)
    if not ok then
        setStatus("⚠️ เกิดข้อผิดพลาด")
        setDetail(tostring(err):sub(1,150))
        local restored=restoreGroup(switched)
        send("⚠️ กระบวนการเก็บไข่ไม่สำเร็จ\n"..tostring(err)..
            "\n▶️ พยายามคืนสวิตช์ "..restored.."/"..#switched)
    end
    busy=false
end

local bot,err=api("getMe",{})
if not bot then setStatus("❌ Telegram: "..tostring(err)); panel.Visible=true; return end
local offset=0
local initial,initErr=api("getUpdates",{timeout=0,limit=100,allowed_updates={"callback_query"}})
if not initial then
    setStatus("❌ getUpdates: "..tostring(initErr)); panel.Visible=true; return
end
for _,u in ipairs(initial.result or {}) do
    offset=math.max(offset,u.update_id+1)
end
setStatus("🟢 Egg Monitor พร้อมทำงาน")
setDetail("ตรวจ Volcanic / Solaris / Cherub | Telegram เชื่อมต่อแล้ว")
send("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")

task.spawn(function()
    while alive() do
        local updates,pollErr=api("getUpdates",{
            offset=offset,timeout=0,limit=100,allowed_updates={"callback_query"}
        })
        if updates then
            for _,u in ipairs(updates.result or {}) do
                offset=math.max(offset,u.update_id+1)
                local cb=u.callback_query
                if cb and type(cb.data)=="string" then
                    local fromChat=cb.message and cb.message.chat and tostring(cb.message.chat.id)
                    if fromChat==CHAT and cb.data:sub(1,1)=="C" then
                        api("answerCallbackQuery",{callback_query_id=cb.id,text="กำลังไปเก็บไข่"})
                        task.spawn(collectCycle,cb.data:sub(2))
                    end
                end
            end
        else
            setDetail("⚠️ Telegram polling: "..tostring(pollErr):sub(1,90))
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while alive() do
        if enabled then
            for _,e in ipairs(Active:GetChildren()) do
                if EGGS[eggName(e)] and not seenEggs[e.Name] then
                    seenEggs[e.Name]=true
                    task.spawn(announce,e)
                end
            end
        end
        task.wait(2)
    end
end)
