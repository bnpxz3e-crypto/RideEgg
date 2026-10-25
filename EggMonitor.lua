-- Ride A Pet | Cherub Route + Egg Monitor (Delta)
-- Set Telegram config before running, if needed:
getgenv().CherubTelegramToken = "8455689997:AAHwzIdo53Eo4v1IdaONYYkUhR8yGylUaCI"
getgenv().CherubTelegramChat = "1813392489"

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local VIM = game:GetService('VirtualInputManager')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
env.CherubComboGen = (env.CherubComboGen or 0)+1
local gen = env.CherubComboGen
local function alive() return env.CherubComboGen==gen end
-- Shut down previous instances of route and monitor.
env.CherubRouteGeneration=(env.CherubRouteGeneration or 0)+1
env.RideEggRun=(env.RideEggRun or 0)+1
env.EggMonitorEnabled=false
local old=pg:FindFirstChild('CherubComboPanel')
if old then old:Destroy() end
local DEST={
 {label='จุดเริ่มต้น',pos=Vector3.new(-484.85,42429.79,907.94)},
 {label='จุดที่ 1',pos=Vector3.new(-459.16,42430.86,879.43),hold=3,equip=true},
 {label='จุดที่ 2',pos=Vector3.new(-516.71,42431.29,927.74),hold=3,equip=true},
 {label='จุดที่ 3',pos=Vector3.new(-539.43,42432.33,848.25),hold=3,equip=true},
 {label='จุดที่ 4',pos=Vector3.new(-496.58,42430.93,893.82),hold=2},
 {label='บ้าน',pos=Vector3.new(174.74,40316.42,1061.15)}
}
local CAMERA={
 [1]=CFrame.new(-471.368866,42436.234375,907.315430)*CFrame.fromOrientation(-0.16520408,-0.11923753,0),
 [2]=CFrame.new(-490.110229,42437.496094,922.611450)*CFrame.fromOrientation(-0.19392118,1.49393189,0),
 [3]=CFrame.new(-519.581116,42439.113281,866.312988)*CFrame.fromOrientation(-0.20994413,0.72658545,0),
 [4]=CFrame.new(-481.348175,42436.113281,918.115417)*CFrame.fromOrientation(-0.15176621,0.58706641,0)
}
local gui=Instance.new('ScreenGui')
gui.Name='CherubComboPanel';gui.ResetOnSpawn=false;gui.DisplayOrder=995;gui.Parent=pg
local function corner(o,r) Instance.new('UICorner',o).CornerRadius=UDim.new(0,r or 9) end
local frame=Instance.new('Frame')
frame.Size=UDim2.fromOffset(330,290);frame.Position=UDim2.new(.5,-165,.3,0)
frame.BackgroundColor3=Color3.fromRGB(22,28,40);frame.Active=true;frame.Draggable=true;frame.Parent=gui
corner(frame,12)
local function label(text,y,h,size)
 local v=Instance.new('TextLabel');v.Size=UDim2.new(1,-20,0,h);v.Position=UDim2.fromOffset(10,y)
 v.BackgroundTransparency=1;v.Text=text;v.TextSize=size or 15;v.TextColor3=Color3.fromRGB(218,232,255)
 v.Font=Enum.Font.Gotham;v.TextWrapped=true;v.Parent=frame;return v
end
local title=label('👼 Cherub Route + Egg Monitor',5,30,18)
title.Font=Enum.Font.GothamBold
local function btn(txt,x,y,w,h,color)
 local b=Instance.new('TextButton');b.Text=txt;b.Size=UDim2.fromOffset(w,h);b.Position=UDim2.fromOffset(x,y)
 b.BackgroundColor3=color;b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBold;b.TextSize=15;b.Parent=frame;corner(b,8);return b
end
local close=btn('X',290,4,35,32,Color3.fromRGB(204,65,57))
local mini=btn('−',251,4,35,32,Color3.fromRGB(72,85,110))
local routeBtn=btn('ROUTE : OFF',10,45,310,44,Color3.fromRGB(120,60,60))
local speedLabel=label('ความเร็วบิน: 250 studs/s',95,24,15)
local speedBox=Instance.new('TextBox')
speedBox.Size=UDim2.fromOffset(105,32);speedBox.Position=UDim2.fromOffset(210,93)
speedBox.Text='250';speedBox.PlaceholderText='100-1000';speedBox.TextSize=17;speedBox.ClearTextOnFocus=false
speedBox.TextColor3=Color3.new(1,1,1);speedBox.BackgroundColor3=Color3.fromRGB(53,66,87);speedBox.Parent=frame;corner(speedBox,7)
local monitorBtn=btn('EGG MONITOR : OFF',10,135,310,44,Color3.fromRGB(120,60,60))
local status=label('พร้อมใช้งาน • ปิด Chilli Auto Collect ก่อนเปิด Route',184,80,14)
status.TextYAlignment=Enum.TextYAlignment.Top
local hint=label('Route วนซ้ำ | กลับบ้านรอ 5 วิ | E จุด 4 ไม่ขึ้น → เริ่มใหม่',265,19,11)
local routeOn=false
local speed=250
local held=false
local camConn=nil
local cameraOldType=nil
local monitorStarted=false
local function releaseE()
 if held then pcall(function() VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game) end);held=false end
end
local function releaseCamera()
 if camConn then camConn:Disconnect();camConn=nil end
 local cam=workspace.CurrentCamera
 if cam and cameraOldType then cam.CameraType=cameraOldType end
 cameraOldType=nil
end
local function lockCamera(i)
 releaseCamera()
 local cam=workspace.CurrentCamera
 if not cam then return end
 cameraOldType=cam.CameraType
 cam.CameraType=Enum.CameraType.Scriptable
 cam.CFrame=CAMERA[i]
 camConn=RunService.RenderStepped:Connect(function()
  if routeOn and alive() and workspace.CurrentCamera==cam then cam.CFrame=CAMERA[i] end
 end)
end
local function waitOn(seconds)
 local t=os.clock()+seconds
 while routeOn and alive() and os.clock()<t do task.wait(.1) end
 return routeOn and alive()
end
local function rootPart()
 local c=player.Character
 return c and c:FindFirstChild('HumanoidRootPart')
end
local function fly(pos,name)
 local root=rootPart()
 if not root then return false,'ไม่พบ HumanoidRootPart' end
 local stalled,last=0,math.huge
 local deadline=os.clock()+math.max(20,(root.Position-pos).Magnitude/math.max(speed,1)*5+15)
 while routeOn and alive() do
  local dt=RunService.Heartbeat:Wait()
  if not root.Parent then return false,'ตัวละครหายไป' end
  local delta=pos-root.Position;local d=delta.Magnitude
  if d<=4 then return true end
  if os.clock()>deadline then return false,'บินเกินเวลาที่กำหนด' end
  local step=math.min(speed*math.min(dt,.12),d)
  root.AssemblyLinearVelocity=Vector3.zero
  root.CFrame=CFrame.new(root.Position+delta.Unit*step)
  if d>=last-.15 then stalled=stalled+dt else stalled=0 end
  last=d
  status.Text=string.format('🚀 %s | เหลือ %.0f studs',name,d)
  if stalled>4 then return false,'ติดขัดหรือถูกดึงตำแหน่งกลับ' end
 end
 return false,'หยุดแล้ว'
end
local function equipEgg(labelText)
 local c=player.Character;local hum=c and c:FindFirstChildOfClass('Humanoid')
 local bp=player:FindFirstChildOfClass('Backpack')
 if not hum or not bp then return false,'ไม่พบตัวละครหรือกระเป๋า' end
 for _,t in ipairs(c:GetChildren()) do
  if t:IsA('Tool') and t.Name=='Cherub Egg' then return true end
 end
 for _,t in ipairs(bp:GetChildren()) do
  if t:IsA('Tool') and t.Name=='Cherub Egg' then
   status.Text='🥚 '..labelText..' | หยิบ Cherub Egg'
   hum:EquipTool(t)
   for _=1,15 do
    if t.Parent==c then return true end
    if not waitOn(.1) then return false,'หยุดแล้ว' end
   end
   return false,'หยิบไข่ไม่สำเร็จ'
  end
 end
 return false,'ไม่มี Cherub Egg ใน Backpack'
end
local function unequip()
 local c=player.Character;local hum=c and c:FindFirstChildOfClass('Humanoid')
 if hum then pcall(function() hum:UnequipTools() end) end
end
-- A few games render E as GUI rather than a ProximityPrompt.
local function visible(v)
 local p=v
 while p and p~=pg do
  if p:IsA('GuiObject') and not p.Visible then return false end
  p=p.Parent
 end
 return true
end
local function findGuiE()
 local checked=0
 for _,v in ipairs(pg:GetDescendants()) do
  checked=checked+1
  if checked>12000 then break end
  if v:IsA('TextLabel') or v:IsA('TextButton') then
   local t=(v.Text or ''):gsub('%s+',''):upper()
   if t=='E' and not v:IsDescendantOf(gui) and visible(v) then return v end
  end
 end
 return nil
end
local function findPrompt()
 local root=rootPart();if not root then return nil end
 local count=0;local nearest,best=nil,math.huge
 for _,obj in ipairs(workspace:GetDescendants()) do
  count=count+1;if count>15000 then break end
  if obj:IsA('ProximityPrompt') and obj.Enabled then
   local p=obj.Parent
   local position=p and (p:IsA('BasePart') and p.Position or p:IsA('Attachment') and p.WorldPosition)
   if position then
    local d=(position-root.Position).Magnitude
    if d<best and d<=math.max(14,obj.MaxActivationDistance+3) then nearest=obj;best=d end
   end
  end
 end
 return nearest
end
local function waitE(seconds)
 local deadline=os.clock()+seconds
 while routeOn and alive() and os.clock()<deadline do
  local prompt=findPrompt()
  if prompt then return true,prompt end
  if findGuiE() then return true,nil end
  if not waitOn(.25) then break end
 end
 return false,nil
end
local function pressE(hold,prompt)
 if not routeOn or not alive() then return false end
 -- Send a real E key hold; GUI-only interactions may depend on camera angle.
 local ok=pcall(function() VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game);held=true end)
 if not ok then return false end
 local completed=waitOn(hold)
 releaseE()
 return completed
end
local function doDeposit(i)
 local point=DEST[i+1]
 local ok,err=fly(point.pos,point.label)
 if not ok then return false,err end
 lockCamera(i)
 ok,err=equipEgg(point.label)
 if not ok then releaseCamera();return false,err end
 status.Text='🔎 '..point.label..' | ถือไข่แล้ว รอ E'
 local found,prompt=waitE(2.5)
 if not routeOn then return false,'หยุดแล้ว' end
 if not found then
  unequip();releaseCamera();status.Text='⏭ '..point.label..' | ไม่มี E ข้ามจุด'
  waitOn(.4)
  return true
 end
 status.Text='🖐 '..point.label..' | กด E เพื่อวาง'
 ok=pressE(point.hold,prompt)
 releaseCamera()
 if not ok then return false,'กด E ไม่สำเร็จ' end
 status.Text='✅ '..point.label..' | กด E แล้ว (ยังไม่ยืนยันการวาง)'
 waitOn(.5)
 return true
end
local function doPoint4()
 local point=DEST[5]
 local ok,err=fly(point.pos,point.label)
 if not ok then return false,err end
 lockCamera(4)
 status.Text='🔎 จุดที่ 4 | ตรวจ E'
 local found,prompt=waitE(2.5)
 if not routeOn then releaseCamera();return false,'หยุดแล้ว' end
 if not found then
  releaseCamera();status.Text='⏭ จุดที่ 4 ไม่มี E → เริ่มจุด 1 ใหม่'
  waitOn(.6)
  return true,'restart'
 end
 status.Text='🖐 จุดที่ 4 | กด E รอบแรก'
 ok=pressE(2,prompt)
 -- Release camera immediately after the FIRST E, as requested.
 releaseCamera()
 if not ok then return false,'กด E รอบแรกไม่สำเร็จ' end
 for i=5,1,-1 do
  status.Text='⏳ จุดที่ 4 | รอ '..i..' วิ ก่อนกดรอบสอง'
  if not waitOn(1) then return false,'หยุดแล้ว' end
 end
 status.Text='🖐 จุดที่ 4 | กด E รอบสอง'
 local found2,prompt2=waitE(2)
 if found2 then
  if not pressE(2,prompt2) then return false,'กด E รอบสองไม่สำเร็จ' end
 else
  status.Text='⚠️ จุดที่ 4 | ไม่พบ E รอบสอง (จะกลับบ้าน)'
 end
 return true,'home'
end
local function render()
 routeBtn.Text=routeOn and 'ROUTE : ON (กดเพื่อหยุด)' or 'ROUTE : OFF (กดเพื่อเริ่ม)'
 routeBtn.BackgroundColor3=routeOn and Color3.fromRGB(29,139,79) or Color3.fromRGB(120,60,60)
 monitorBtn.Text=env.EggMonitorEnabled and 'EGG MONITOR : ON' or 'EGG MONITOR : OFF'
 monitorBtn.BackgroundColor3=env.EggMonitorEnabled and Color3.fromRGB(29,139,79) or Color3.fromRGB(120,60,60)
 speedLabel.Text='ความเร็วบิน: '..tostring(speed)..' studs/s'
end
speedBox.FocusLost:Connect(function()
 local v=tonumber(speedBox.Text)
 if v then speed=math.clamp(math.floor(v),50,1000) end
 speedBox.Text=tostring(speed);render()
end)
local function stopRoute()
 routeOn=false;releaseE();releaseCamera();render()
end
routeBtn.Activated:Connect(function()
 if routeOn then stopRoute();status.Text='⏹ Route หยุดแล้ว';return end
 routeOn=true;render()
 task.spawn(function()
  local lap=0
  while routeOn and alive() do
   lap=lap+1
   status.Text='🔁 เริ่มรอบ '..lap
   local ok,err=fly(DEST[1].pos,DEST[1].label)
   if not ok then status.Text='⚠️ '..tostring(err);break end
   for i=1,3 do
    if not routeOn then break end
    ok,err=doDeposit(i)
    if not ok then break end
   end
   if not ok or not routeOn then status.Text='⚠️ '..tostring(err);break end
   local outcome
   ok,outcome=doPoint4()
   if not ok then status.Text='⚠️ '..tostring(outcome);break end
   if outcome=='restart' then
    -- No E at point 4: begin at staging point again without going home.
   else
    ok,err=fly(DEST[6].pos,DEST[6].label)
    if not ok then status.Text='⚠️ '..tostring(err);break end
    for n=5,1,-1 do
     status.Text='🏠 ถึงบ้าน | เริ่มรอบใหม่ใน '..n..' วิ'
     if not waitOn(1) then break end
    end
   end
  end
  stopRoute()
 end)
end)
mini.Activated:Connect(function()
 local collapsed=frame.Size.Y.Offset>50
 frame.Size=UDim2.fromOffset(330,collapsed and 40 or 290)
 for _,o in ipairs({routeBtn,speedLabel,speedBox,monitorBtn,status,hint}) do o.Visible=not collapsed end
 mini.Text=collapsed and '+' or '−'
end)
local function startEggMonitor()
-- Ride A Pet | Egg monitor + Telegram + Day/Night
-- Fill in a NEW Telegram bot token. Do not share it publicly.
local TOKEN = env.CherubTelegramToken or "PUT_NEW_BOT_TOKEN_HERE"
local CHAT = tostring(env.CherubTelegramChat or "PUT_CHAT_ID_HERE")

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local HS=game:GetService("HttpService")
local UIS=game:GetService("UserInputService")
local P=Players.LocalPlayer
local PG=P:WaitForChild("PlayerGui")
local Active=RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")
local roots={PG,game:GetService("CoreGui")}
local req=(syn and syn.request) or (http and http.request) or http_request or request
local env=(getgenv and getgenv()) or _G
env.RideEggRun=(env.RideEggRun or 0)+1
local run=env.RideEggRun
env.EggMonitorEnabled=true
local function alive() return env.RideEggRun==run end

local EGGS={
 ["Volcanic Egg"]={icon="🌋",asset="132679696143806"},
 ["Solaris Egg"]={icon="☀️",asset="131016816558781"},
 ["Cherub Egg"]={icon="👼",asset="78949206711037"}
}
local SWITCHES={"Auto Collect Candy","Auto Search Pumpkins","Auto Trick Or Treat","Auto Halloween Ritual","Collect Rare Eggs First"}
local MAX_COLLECT=2
local COLLECT_TIMEOUT=300
local REOPEN_DELAY=10
local DAY_ID="94969857695475"
local NIGHT_ID="106891725078200"

local function api(method,data)
 if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" or CHAT=="PUT_CHAT_ID_HERE" then return nil end
 local ok,res=pcall(function()
  return req({Url="https://api.telegram.org/bot"..TOKEN.."/"..method,Method="POST",Headers={["Content-Type"]="application/json"},Body=HS:JSONEncode(data)})
 end)
 if not ok or not res then return nil end
 local yes,obj=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 if yes and obj and obj.ok then return obj end
 if method=="editMessageCaption" or method=="editMessageText" then
  warn("[EGG TIMER] Telegram edit failed: "..tostring(yes and obj and obj.description or res.Body))
 end
 return nil
end
local function send(s) return api("sendMessage",{chat_id=CHAT,text=s}) end
local function thumbnail(id)
 if not req then return nil end
 local ok,res=pcall(function() return req({Url="https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false",Method="GET"}) end)
 if not ok or not res then return nil end
 local yes,data=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 local item=yes and data.data and data.data[1]
 return item and item.state=="Completed" and item.imageUrl or nil
end
local function press(b)
 if not b or not b:IsA("GuiButton") or not getconnections then return false end
 local done=false
 pcall(function()
  for _,c in ipairs(getconnections(b.Activated)) do
   if c.Function then c.Function();done=true end
  end
 end)
 return done
end
local function switchButton(name)
 for _,root in ipairs(roots) do
  local v=root:FindFirstChild(name,true)
  if v then
   local sw=v:FindFirstChild("Switch",true)
   local b=sw and sw:FindFirstChild("Button",true)
   if b and b:IsA("GuiButton") then return b end
  end
 end
end
local function toggle5()
 local n=0
 for _,name in ipairs(SWITCHES) do
  if not alive() then break end
  if press(switchButton(name)) then n=n+1 end
  task.wait(.3)
 end
 return n
end
local function cards()
 local found,seen={},{}
 for _,root in ipairs(roots) do
  for _,v in ipairs(root:GetDescendants()) do
   if v:IsA("TextLabel") and EGGS[v.Text] then
    local parent=v.Parent
    for _=1,5 do
     if not parent then break end
     local b=parent:FindFirstChild("Open")
     if b and b:IsA("GuiButton") then
      if not seen[b] then
       seen[b]=true
       table.insert(found,{name=v.Text,button=b,label=v})
      end
      break
     end
     parent=parent.Parent
    end
   end
  end
 end
 return found
end
local function weightOf(name)
 for _,c in ipairs(cards()) do
  if c.name==name then
   local p=c.label.Parent
   for _=1,4 do
    if not p then break end
    local w=p:FindFirstChild("EggWeight",true)
    if w and w:IsA("TextLabel") and w.Text~="" then return w.Text end
    for _,x in ipairs(p:GetDescendants()) do
     if x:IsA("TextLabel") and x~=c.label and x.Text:lower():find("kg",1,true) then return x.Text end
    end
    p=p.Parent
   end
  end
 end
 return "กำลังอัปเดต"
end
local function readTime()
 local main=PG:FindFirstChild("Main")
 local dn=main and main:FindFirstChild("DayNightRotation")
 local t=dn and dn:FindFirstChild("TimerLabel")
 local img=dn and dn:FindFirstChild("TimeImage")
 if not t or not img then return nil,nil end
 local str=t.Text or ""
 local m=tonumber(str:match("(%d+)%s*m")) or 0
 local s=tonumber(str:match("(%d+)%s*s")) or 0
 if not str:match("%d+%s*[ms]") then return nil,nil end
 local id=(img.Image or ""):match("(%d+)$")
 local phase=id==DAY_ID and "DAY" or (id==NIGHT_ID and "NIGHT" or nil)
 return phase,m*60+s
end

-- Each active egg has its own lifecycle; do not mistake a reset for collection.
-- Preserve message IDs when rerunning this version in the same Roblox session.
env.RideEggTracked = env.RideEggTracked or {}
local tracked=env.RideEggTracked
local pending={}
local pendingSource={}
local busy=false
local lastPhase,lastSeconds=nil,nil
local cycle=0
local warned={DAY=false,NIGHT=false}
local pendingReset={}
-- Spawn age timer removed as requested.
local autoEnabled=false
local autoTriggeredCycle=-1
local collectCycle -- forward declaration for auto backup
local function chilliWorking()
 -- Avoid competing with Chilli while it carries, queues, or returns an egg.
 for _,root in ipairs(roots) do
  for _,v in ipairs(root:GetDescendants()) do
   if v:IsA("TextLabel") then
    local t=(v.Text or ""):lower()
    if t:find("in basket",1,true) or t:find("bringing home",1,true)
      or t:find("queued #",1,true) or t:find("carrying ",1,true) and not t:find("carrying 0",1,true) then
     return true
    end
   end
  end
 end
 return false
end
local function chilliAutoOn()
 -- When Chilli Auto Collect Eggs is enabled, do not issue competing commands.
 for _,root in ipairs(roots) do
  local label=root:FindFirstChild("Auto Collect Eggs",true)
  if label then
   local sw=label:FindFirstChild("Switch",true)
   if sw then
    local b=sw:FindFirstChild("Button",true)
    if b then
     local parent=b.Parent
     if parent and parent:IsA("GuiObject") and parent.BackgroundColor3.G>parent.BackgroundColor3.R*1.3 then
      return true
     end
    end
   end
  end
 end
 return false
end
local function captionFor(record,status)
 local item=EGGS[record.name]
 return item.icon.." พบ "..record.name.."\n⚖️ น้ำหนัก: "..(record.weight or "กำลังอัปเดต").."\n"..(status or "🥚 กดปุ่มเพื่อเก็บไข่")
end
local function editEggMessage(record,status)
 if not record.messageId then return false end
 status=status or record.finalStatus
 local payload={chat_id=CHAT,message_id=record.messageId}
 if not status and record.state=="active" then
  payload.reply_markup={inline_keyboard={{{text="🥚 เก็บไข่",callback_data="C"..record.id}}}}
 end
 if record.isPhoto then
  payload.caption=captionFor(record,status)
  return api("editMessageCaption",payload) ~= nil
 else
  payload.text=captionFor(record,status)
  return api("editMessageText",payload) ~= nil
 end
end
local function finalize(record,status)
 record.finalStatus=status
 if record.messageId then editEggMessage(record,status) end
end

local function eggName(e) return e:GetAttribute("Egg") end
local function describe(r) return (EGGS[r.name] and EGGS[r.name].icon or "🥚").." "..r.name end
local function announce(e,record)
 task.wait(2)
 if not alive() or not env.EggMonitorEnabled or not e.Parent or record.state~="active" then return end
 local item=EGGS[record.name]
 record.weight=weightOf(record.name)
 local keyboard={inline_keyboard={{{text="🥚 เก็บไข่",callback_data="C"..record.id}}}}
 local url=thumbnail(item.asset)
 local res=url and api("sendPhoto",{chat_id=CHAT,photo=url,caption=captionFor(record),reply_markup=keyboard})
 if res then
  record.isPhoto=true
 else
  res=api("sendMessage",{chat_id=CHAT,text=captionFor(record),reply_markup=keyboard})
  record.isPhoto=false
 end
 if res and res.result then
  record.messageId=res.result.message_id
  if record.finalStatus then editEggMessage(record,record.finalStatus) end
 end
end
local function confirmCollected(record)
 if record.state~="active" then return end
 record.state="telegram"
 finalize(record,pendingSource[record.id]=="AUTO" and "✅ ระบบ AUTO เก็บ "..record.name.." สำเร็จ" or "✅ กดเก็บ "..record.name.." สำเร็จ")
 local source=pendingSource[record.id]
 pending[record.id]=nil;pendingSource[record.id]=nil
 send((source=="AUTO" and "✅ ระบบ AUTO เก็บ " or "✅ กดเก็บ ")..record.name.." สำเร็จ")
end
local function markMissing(record,phase,seconds)
 if record.state~="active" then return end
 if pending[record.id] then
  confirmCollected(record)
  return
 end
 -- If near the night->day transition, defer classification until the new day.
 if phase=="NIGHT" and seconds and seconds<=60 then
  record.state="await-reset"
  record.missingAt=os.clock()
  pendingReset[record.id]=record
  return
 end
 record.state="other"
 local status=(phase=="NIGHT" and seconds and seconds>60)
  and ("✅ ระบบ Chilli เก็บ "..record.name.." สำเร็จ")
  or "🥚 ไข่ถูกเก็บแล้ว (ไม่ได้เก็บผ่าน Telegram)"
 finalize(record,status)
 send(status)
end
local function settleReset()
 for id,record in pairs(pendingReset) do
  if record.state=="await-reset" then
   record.state="reset"
   finalize(record,"⚠️ ไข่ไม่ถูกเก็บ โดนรีเซ็ตไปแล้ว")
   send("⚠️ ไข่ไม่ถูกเก็บ โดนรีเซ็ตไปแล้ว\n"..describe(record))
  end
  pendingReset[id]=nil
 end
end
local function detectTime()
 local phase,seconds=readTime()
 if not phase then return end
 if lastPhase and phase~=lastPhase then
  if lastPhase=="NIGHT" and phase=="DAY" then
   cycle=cycle+1
   -- At sunrise, eggs that were active in the preceding cycle may have reset.
   for id,record in pairs(tracked) do
    if record.state=="active" and record.cycle<cycle and not Active:FindFirstChild(id) then
     record.state="reset"
     send("⚠️ ไข่ไม่ถูกเก็บ โดนรีเซ็ตไปแล้ว\n"..describe(record))
    end
   end
   settleReset()
  elseif lastPhase=="DAY" and phase=="NIGHT" then
   -- A missing egg at dusk is not automatically considered a reset.
  end
  warned={DAY=false,NIGHT=false}
 elseif lastSeconds and seconds>lastSeconds+60 then
  warned[phase]=false
 end
 lastPhase,lastSeconds=phase,seconds
 if env.EggMonitorEnabled and seconds<=60 and not warned[phase] then
  local hasEgg=false
  for id,record in pairs(tracked) do
   if record.state=="active" and Active:FindFirstChild(id) then hasEgg=true;break end
  end
  if hasEgg then
   warned[phase]=true
   if phase=="DAY" then send("🌙 อีก 1 นาที จะเข้าสู่กลางคืน")
   else
    send("☀️ อีก 1 นาที จะเข้าสู่ตอนเช้า")
    if autoEnabled and autoTriggeredCycle~=cycle then
     autoTriggeredCycle=cycle
     task.spawn(function()
      -- Keep checking during the remaining minute; don't silently give up
      -- after one busy/Chilli state check.
      -- AUTO diagnostics stay local; Telegram only gets per-egg start/success.
      local function report(reason)
       warn("[Egg AUTO] "..reason)
      end
      while alive() and autoEnabled and env.EggMonitorEnabled do
       local currentPhase,left=readTime()
       if currentPhase~="NIGHT" or not left or left>60 or left<=0 then
        report("สิ้นสุดช่วงก่อนเช้า ยังไม่มีการสั่งเก็บจาก AUTO")
        return
       end
       if busy then
        report("รอรอบเก็บไข่เดิมจบ")
       elseif chilliWorking() then
        report("Chilli กำลังขน/จองไข่ จึงไม่สั่งซ้ำ")
       elseif chilliAutoOn() then
        report("Chilli เปิด Auto Collect Eggs อยู่ จึงไม่สั่งชน")
       else
        local target=nil
        for _,e in ipairs(Active:GetChildren()) do
         if EGGS[eggName(e)] then target=e;break end
        end
        if not target then
         report("ไม่มีไข่เป้าหมายเหลือให้เก็บ")
         return
        end
        collectCycle(target.Name,"AUTO")
        return
       end
       task.wait(5)
      end
     end)
    end
   end
  end
 end
 -- If the countdown wrapped while image remained unchanged, avoid indefinite pending.
 if phase=="NIGHT" and seconds>60 then
  for id,record in pairs(pendingReset) do
   if os.clock()-(record.missingAt or 0)>35 then
    record.state="other";pendingReset[id]=nil
    local status="✅ ระบบ Chilli เก็บ "..record.name.." สำเร็จ"
    finalize(record,status)
    send(status)
   end
  end
 end
end

collectCycle=function(requestId,source)
 if busy then return end
 if source=="AUTO" and (not autoEnabled or chilliWorking() or chilliAutoOn()) then return end
 if not env.EggMonitorEnabled then send("🔴 ระบบ Egg Monitor ปิดอยู่");return end
 local chosen=Active:FindFirstChild(requestId)
 if not chosen or not EGGS[eggName(chosen)] then send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว");return end
 busy=true
 local switched=false
 local function work()
  local off=toggle5();switched=true
  if off~=5 then error("กดสวิตช์ Event ไม่ครบ 5/5; ตรวจสอบสถานะ Event ก่อนเปิดกลับ") end
  task.wait(1)
  local ids={}
  for _,e in ipairs(Active:GetChildren()) do
   local n=eggName(e)
   if EGGS[n] then
    ids[n]=ids[n] or {}
    table.insert(ids[n],e.Name)
   end
  end
  local list=cards()
  table.sort(list,function(a,b) return a.name==eggName(chosen) and b.name~=eggName(chosen) end)
  local watching,used={},{}
  local count=0
  for _,card in ipairs(list) do
   if count>=MAX_COLLECT or not alive() then break end
   local available=ids[card.name] or {}
   if card.name==eggName(chosen) then
    table.sort(available,function(a,b) return a==requestId and b~=requestId end)
   end
   for _,id in ipairs(available) do
    if not used[id] and Active:FindFirstChild(id) then
     if press(card.button) then
      used[id]=true;watching[id]=true;pending[id]=true;pendingSource[id]=source or "TELEGRAM"
      count=count+1
      send((source=="AUTO" and "🤖 ระบบ AUTO กำลังเริ่มเก็บ " or "🥚 ระบบ Telegram กำลังเริ่มเก็บ ")..card.name)
     end
     break
    end
   end
   task.wait(.3)
  end
  if count==0 then send("⚠️ ไม่พบปุ่ม Collect ที่กดได้") end
  local start=os.clock()
  while alive() and next(watching) and os.clock()-start<COLLECT_TIMEOUT do
   for id in pairs(watching) do
    if not Active:FindFirstChild(id) then
     watching[id]=nil
     local record=tracked[id]
     if record then confirmCollected(record) end
     pending[id]=nil
    end
   end
   if next(watching) then task.wait(1) end
  end
  for id in pairs(watching) do
   pending[id]=nil
   send("⚠️ ยังไม่ยืนยันการเก็บไข่: "..id)
  end
  if count>0 and not next(watching) then task.wait(REOPEN_DELAY) end
  local on=toggle5();switched=false
 end
 local ok,err=pcall(work)
 if not ok then
  send("❌ เกิดข้อผิดพลาดขณะเก็บไข่: "..tostring(err))
  -- Do not blindly toggle switches after a partial failure.
 end
 for id in pairs(pending) do pending[id]=nil end
 busy=false
end

if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" then
 warn("Egg Monitor: fill in Telegram TOKEN and ensure executor supports HTTP")
end

task.spawn(function()
 local offset=0
 local init=api("getUpdates",{timeout=0,limit=100,allowed_updates={"callback_query","message"}})
 if init then for _,u in ipairs(init.result or {}) do offset=math.max(offset,u.update_id+1) end end
 while alive() do
  local data=api("getUpdates",{offset=offset,timeout=0,limit=50,allowed_updates={"callback_query","message"}})
  if data then
   for _,u in ipairs(data.result or {}) do
    offset=math.max(offset,u.update_id+1)
    -- Handle text commands separately from inline callback buttons.
    local msg=u.message
    if msg and msg.chat and tostring(msg.chat.id)==tostring(CHAT) then
     local command=type(msg.text)=="string" and msg.text:lower():match("^%s*(.-)%s*$") or ""
     if command=="auto" or command=="/auto" then
      if autoEnabled then
       task.spawn(send,"🟢 AUTO เปิดอยู่แล้ว (สำรองก่อนเช้า 1 นาที)")
      else
       autoEnabled=true
       task.spawn(send,"🟢 เปิด AUTO สำรองแล้ว: รอแจ้งเตือน ☀️ อีก 1 นาทีจะเข้าสู่ตอนเช้า")
      end
     elseif command=="stop" or command=="/stop" then
      if not autoEnabled then
       task.spawn(send,"🔴 AUTO ปิดอยู่แล้ว")
      else
       autoEnabled=false
       task.spawn(send,"🔴 ปิด AUTO สำรองแล้ว (ปุ่มเก็บไข่ Telegram ยังใช้ได้)")
      end
     end
    end
    local cb=u.callback_query
    if cb and type(cb.data)=="string" and cb.data:sub(1,1)=="C" then
     local source=cb.message and cb.message.chat and tostring(cb.message.chat.id)
     api("answerCallbackQuery",{callback_query_id=cb.id,text="รับคำสั่งแล้ว"})
     if source==CHAT then task.spawn(collectCycle,cb.data:sub(2)) end
    end
   end
  end
  task.wait(2)
 end
end)

task.spawn(function()
 send("🟢 Ride A Pet Egg Monitor เริ่มทำงาน")
 while alive() do
  if env.EggMonitorEnabled then
   local phase,seconds=readTime()
   local present={}
   for _,e in ipairs(Active:GetChildren()) do
    local name=eggName(e)
    if EGGS[name] then
     local id=e.Name
     present[id]=true
     if not tracked[id] or tracked[id].state~="active" then
      tracked[id]={id=id,name=name,state="active",cycle=cycle,spawnedAt=os.time(),spawnedMs=DateTime.now().UnixTimestampMillis,lastEditMinute=-1}
      task.spawn(announce,e,tracked[id])
     end
    end
   end
   -- Detect time transition first; classify eggs missing at sunrise as reset.
   local sunrise=(lastPhase=="NIGHT" and phase=="DAY")
   detectTime()
   for id,record in pairs(tracked) do
    if record.state=="active" and not present[id] then
     if sunrise and record.cycle<cycle and not pending[id] then
      record.state="reset"
      finalize(record,"⚠️ ไข่ไม่ถูกเก็บ โดนรีเซ็ตไปแล้ว")
      send("⚠️ ไข่ไม่ถูกเก็บ โดนรีเซ็ตไปแล้ว\n"..describe(record))
     else
      markMissing(record,phase,seconds)
     end
    end
   end
  end
  task.wait(1)
 end
end)


end
monitorBtn.Activated:Connect(function()
 if env.EggMonitorEnabled then
  env.EggMonitorEnabled=false
  env.RideEggRun=(env.RideEggRun or 0)+1
  status.Text='🔴 Egg Monitor ปิดแล้ว'
 else
  env.EggMonitorEnabled=true
  status.Text='🟢 เริ่ม Egg Monitor / Telegram'
  task.spawn(startEggMonitor)
 end
 render()
end)
close.Activated:Connect(function()
 stopRoute()
 env.EggMonitorEnabled=false
 env.RideEggRun=(env.RideEggRun or 0)+1
 env.CherubComboGen=env.CherubComboGen+1
 gui:Destroy()
end)
render()
