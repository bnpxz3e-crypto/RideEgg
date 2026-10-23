-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local ROOTS = {PG, game:GetService("CoreGui")}
local Active -- initialize after the UI appears
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

-- Ornate fantasy / sci-fi UI inspired by the approved mockup.
-- Roblox cannot display the concept illustration until it is uploaded as an image asset.
local old=PG:FindFirstChild("RideEggNeon")
if old then old:Destroy() end
local ui=Instance.new("ScreenGui")
ui.Name="RideEggNeon"; ui.ResetOnSpawn=false; ui.IgnoreGuiInset=true
ui.DisplayOrder=350; ui.Parent=PG
local C={gold=Color3.fromRGB(255,191,72),blue=Color3.fromRGB(49,179,255),
    dark=Color3.fromRGB(7,13,27),panel=Color3.fromRGB(12,23,40),
    pale=Color3.fromRGB(246,247,255),dim=Color3.fromRGB(160,178,203),
    green=Color3.fromRGB(24,184,106),red=Color3.fromRGB(192,51,59)}
local function round(o,r)
    local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,r); x.Parent=o
end
local function stroke(o,c,w)
    local x=Instance.new("UIStroke"); x.Color=c; x.Thickness=w or 1; x.Parent=o
    return x
end
local function gradient(o,a,b,rot)
    local x=Instance.new("UIGradient")
    x.Color=ColorSequence.new(a,b); x.Rotation=rot or 0; x.Parent=o
end
local function frame(parent,pos,size,color,r,border)
    local x=Instance.new("Frame"); x.Position=pos; x.Size=size
    x.BorderSizePixel=0; x.BackgroundColor3=color; x.Parent=parent
    if r then round(x,r) end
    if border then stroke(x,border,1.5) end
    return x
end
local function txt(parent,s,pos,size,fontsize,color,bold)
    local x=Instance.new("TextLabel"); x.BackgroundTransparency=1
    x.Position=pos; x.Size=size; x.Text=s; x.TextColor3=color
    x.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    x.TextSize=fontsize; x.TextWrapped=true; x.TextXAlignment=Enum.TextXAlignment.Left
    x.Parent=parent; return x
end
local function btn(parent,s,pos,size,bg,fg,font)
    local x=Instance.new("TextButton"); x.Text=s; x.Position=pos; x.Size=size
    x.BorderSizePixel=0; x.BackgroundColor3=bg; x.TextColor3=fg
    x.Font=Enum.Font.GothamBold; x.TextSize=font or 18; x.Parent=parent
    round(x,10); return x
end
local eggButton=btn(ui,"🥚",UDim2.new(0,12,.43,0),UDim2.fromOffset(62,62),C.dark,C.gold,34)
stroke(eggButton,C.gold,3)
local glow=frame(ui,UDim2.new(0,18,.43,6),UDim2.fromOffset(50,50),C.gold,25)
glow.BackgroundTransparency=.88; glow.ZIndex=0; eggButton.ZIndex=2
local panel=frame(ui,UDim2.fromScale(.5,.5),UDim2.fromOffset(680,440),C.dark,18,C.gold)
panel.AnchorPoint=Vector2.new(.5,.5); panel.Visible=true; panel.ClipsDescendants=true
stroke(panel,C.blue,1.3)
local scale=Instance.new("UIScale"); scale.Parent=panel
local function resize()
    local camera=workspace.CurrentCamera
    local viewport=camera and camera.ViewportSize or Vector2.new(800,600)
    scale.Scale=math.min(1,math.max(.46,math.min((viewport.X-24)/680,(viewport.Y-24)/440)))
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
local border=frame(panel,UDim2.fromOffset(5,5),UDim2.new(1,-10,1,-10),C.panel,15,C.gold)
border.BackgroundTransparency=.25
local header=frame(panel,UDim2.fromOffset(9,9),UDim2.new(1,-18,0,67),Color3.fromRGB(21,28,45),12,C.gold)
gradient(header,Color3.fromRGB(55,30,18),Color3.fromRGB(6,30,56))
local heading=txt(header,"✦  EGG MONITOR",UDim2.fromOffset(23,8),UDim2.fromOffset(480,38),31,C.gold,true)
stroke(heading,Color3.fromRGB(75,39,12),.5)
txt(header,"R I D E   A   P E T     •     TELEGRAM CONTROL",UDim2.fromOffset(28,45),UDim2.fromOffset(460,16),10,C.pale,true)
local close=btn(header,"✕",UDim2.new(1,-56,0,10),UDim2.fromOffset(43,43),C.red,C.pale,27)
stroke(close,C.gold,2)
local power=btn(panel,"●  ระบบเปิด ON",UDim2.fromOffset(22,90),UDim2.fromOffset(397,61),Color3.fromRGB(8,115,79),C.pale,24)
stroke(power,Color3.fromRGB(82,255,164),2)
gradient(power,Color3.fromRGB(8,91,76),Color3.fromRGB(13,149,100))
local tg=frame(panel,UDim2.fromOffset(430,90),UDim2.fromOffset(228,61),Color3.fromRGB(13,31,54),12,C.blue)
txt(tg,"✈  TELEGRAM",UDim2.fromOffset(13,7),UDim2.fromOffset(210,24),18,C.blue,true)
local tgState=txt(tg,"กำลังเชื่อมต่อ...",UDim2.fromOffset(15,34),UDim2.fromOffset(200,18),13,C.pale)
txt(panel,"🥚 ไข่ที่ตรวจจับ",UDim2.fromOffset(24,161),UDim2.fromOffset(390,27),18,C.gold,true)
txt(panel,"⚙ ระบบกิจกรรม",UDim2.fromOffset(432,161),UDim2.fromOffset(215,27),18,C.gold,true)
local eggNames={{"Volcanic Egg","132679696143806","🌋"},{"Solaris Egg","131016816558781","☀"},{"Cherub Egg","78949206711037","👼"}}
local eggCards={}
for i,item in ipairs(eggNames) do
    local x=frame(panel,UDim2.fromOffset(23+(i-1)*132,194),UDim2.fromOffset(124,108),C.panel,10,i==1 and C.red or (i==2 and C.gold or C.blue))
    local im=Instance.new("ImageLabel")
    im.BackgroundTransparency=1; im.Size=UDim2.fromOffset(72,72); im.Position=UDim2.fromOffset(26,4)
    im.Image="rbxthumb://type=Asset&id="..item[2].."&w=150&h=150"
    im.ScaleType=Enum.ScaleType.Fit; im.Parent=x
    local nm=txt(x,item[1],UDim2.fromOffset(5,79),UDim2.fromOffset(115,23),12,C.pale,true)
    nm.TextXAlignment=Enum.TextXAlignment.Center
    eggCards[item[1]]=x
end
local switchesUI={}
local switchRows={}
for i,name in ipairs(SWITCH_NAMES) do
    local y=193+(i-1)*28
    local row=frame(panel,UDim2.fromOffset(430,y),UDim2.fromOffset(228,26),Color3.fromRGB(14,30,48),6)
    txt(row,name,UDim2.fromOffset(7,1),UDim2.fromOffset(184,24),11,C.pale)
    local dot=frame(row,UDim2.fromOffset(204,6),UDim2.fromOffset(14,14),C.gold,7)
    switchesUI[name]=dot
    local hit=Instance.new("TextButton")
    hit.Name="SwitchHit"; hit.Text=""; hit.BackgroundTransparency=1
    hit.Size=UDim2.fromScale(1,1); hit.Parent=row
    switchRows[name]=hit
end
local infoBox=frame(panel,UDim2.fromOffset(22,313),UDim2.fromOffset(395,105),Color3.fromRGB(8,18,32),10,C.gold)
txt(infoBox,"▣  สถานะการทำงาน",UDim2.fromOffset(12,7),UDim2.fromOffset(365,25),16,C.gold,true)
local statusLabel=txt(infoBox,"กำลังเริ่มระบบ...",UDim2.fromOffset(13,35),UDim2.fromOffset(365,28),16,C.pale,true)
local detail=txt(infoBox,"รอตรวจสอบไข่",UDim2.fromOffset(13,66),UDim2.fromOffset(365,32),13,C.dim)
local helpBox=frame(panel,UDim2.fromOffset(429,345),UDim2.fromOffset(229,73),Color3.fromRGB(9,28,45),10,C.blue)
txt(helpBox,"✦  MONITOR ACTIVE",UDim2.fromOffset(10,9),UDim2.fromOffset(210,20),14,C.gold,true)
txt(helpBox,"รอ Map Eggs 10 วินาที\nส่งรูป + KG ไป Telegram",UDim2.fromOffset(10,30),UDim2.fromOffset(210,39),12,C.pale)
local enabled=true
local busy=false
local function setStatus(s)
    if alive() and ui.Parent then statusLabel.Text=s end
end
local function setDetail(s)
    if alive() and ui.Parent then detail.Text=s end
end
local function paintPower()
    power.Text=enabled and "●  ระบบเปิด ON" or "○  ระบบปิด OFF"
    power.BackgroundColor3=enabled and Color3.fromRGB(8,126,81) or C.red
    local edge=power:FindFirstChildOfClass("UIStroke")
    if edge then edge.Color=enabled and Color3.fromRGB(82,255,164) or C.gold end
end
paintPower()
-- Drag the small egg launcher on touch screens or with a mouse.
local dragging, dragStart, startPos, moved = false, nil, nil, false
local function clampEgg(pos)
    local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
    return UDim2.fromOffset(math.clamp(pos.X,0,math.max(0,vp.X-62)),math.clamp(pos.Y,0,math.max(0,vp.Y-62)))
end
eggButton.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; moved=false; dragStart=input.Position
        startPos=eggButton.AbsolutePosition
    end
end)
UIS.InputChanged:Connect(function(input)
    if not dragging or not dragStart then return end
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position-dragStart
        if delta.Magnitude>8 then moved=true end
        if moved then
            eggButton.Position=clampEgg(startPos+Vector2.new(delta.X,delta.Y))
            glow.Position=eggButton.Position
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        if dragging then
            dragging=false
            if not moved then panel.Visible=not panel.Visible end
        end
    end
end)
close.Activated:Connect(function() panel.Visible=false end)
local sendPowerNotice=function() end
power.Activated:Connect(function()
    if not alive() then return end
    if busy then setDetail("⏳ กำลังเก็บไข่ กรุณารอจนเสร็จ"); return end
    enabled=not enabled; paintPower()
    setStatus(enabled and "🟢 เปิดตรวจไข่แล้ว" or "🔴 หยุดตรวจไข่แล้ว")
    setDetail(enabled and "กำลังเฝ้าดูไข่ใหม่" or "ปิดการแจ้งไข่ใหม่และรับคำสั่งเก็บไข่")
    task.spawn(function() sendPowerNotice(enabled) end)
end)
setStatus("⏳ กำลังตรวจข้อมูลเกม...")
local serverData = RS:FindFirstChild("ServerData") or RS:WaitForChild("ServerData", 12)
if not serverData then
    setStatus("❌ ไม่พบ ServerData ภายใน 12 วินาที")
    setDetail("ตรวจสอบว่าเข้าเกม Ride A Pet ถูกเซิร์ฟเวอร์")
    return
end
Active = serverData:FindFirstChild("ActiveEggs") or serverData:WaitForChild("ActiveEggs", 12)
if not Active then
    setStatus("❌ ไม่พบ ActiveEggs ภายใน 12 วินาที")
    setDetail("ระบบ GUI เปิดแล้ว แต่ข้อมูลไข่ในเกมยังไม่พร้อม")
    return
end
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
sendPowerNotice=function(on)
    local msg=on and "🟢 Egg Monitor: เปิดระบบ ON\n🥚 เริ่มตรวจหาไข่และรับคำสั่งเก็บไข่แล้ว"
        or "🔴 Egg Monitor: ปิดระบบ OFF\n⏸ หยุดแจ้งไข่ใหม่และไม่รับคำสั่งเก็บไข่"
    local result,err=send(msg)
    if not result then setDetail("⚠️ แจ้ง Telegram ไม่สำเร็จ: "..tostring(err):sub(1,80)) end
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
-- Individual event rows can toggle the matching Chilli Hub control.
-- Yellow = button was located, gray = not located. The game owns actual switch state.
for name,hit in pairs(switchRows) do
    hit.Activated:Connect(function()
        if not alive() or busy then return end
        local b=findSwitch(name)
        if press(b) then
            setDetail("⚙ สั่งสลับ "..name)
            task.spawn(function() send("⚙ สั่งสลับกิจกรรม: "..name) end)
        else
            setDetail("⚠️ ไม่พบปุ่มกิจกรรม: "..name)
        end
    end)
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
local seenEggs={} -- busy declared with the UI
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
if not bot then setStatus("❌ Telegram: "..tostring(err)); tgState.Text="● เชื่อมต่อไม่สำเร็จ"; panel.Visible=true; return end
local offset=0
local initial,initErr=api("getUpdates",{timeout=0,limit=100,allowed_updates={"callback_query"}})
if not initial then
    setStatus("❌ getUpdates: "..tostring(initErr)); panel.Visible=true; return
end
for _,u in ipairs(initial.result or {}) do
    offset=math.max(offset,u.update_id+1)
end
setStatus("🟢 Egg Monitor พร้อมทำงาน")
tgState.Text="● เชื่อมต่อแล้ว"
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
                    if fromChat==CHAT and enabled and cb.data:sub(1,1)=="C" then
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
