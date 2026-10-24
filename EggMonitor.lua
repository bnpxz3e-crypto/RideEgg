-- Ride A Pet | Egg Monitor (Telegram throttling + compact Roblox status GUI)
-- IMPORTANT: Revoke the previously exposed Telegram token in BotFather.
local TOKEN = "8455689997:AAHwzIdo53Eo4v1IdaONYYkUhR8yGylUaCI"
local CHAT = "1813392489"

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer
local PG = P:WaitForChild("PlayerGui")
local Active = RS:WaitForChild("ServerData"):WaitForChild("ActiveEggs")
local roots = {PG, game:GetService("CoreGui")}
local req = (syn and syn.request) or (http and http.request) or http_request or request
local env = (getgenv and getgenv()) or _G
env.RideEggRun = (env.RideEggRun or 0) + 1
local run = env.RideEggRun
env.EggMonitorEnabled = true
local function alive() return env.RideEggRun == run end

local EGGS = {
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

-- UI: all diagnostics are visible on Roblox, not in an executor console.
for _,name in ipairs({"EggMonitorMini","EggMonitorStatus","DayNightLiveTest","DayNightTestV12","TelegramDebug"}) do
 local old=PG:FindFirstChild(name)
 if old then old:Destroy() end
end
local gui=Instance.new("ScreenGui")
gui.Name="EggMonitorStatus"
gui.ResetOnSpawn=false
gui.DisplayOrder=999
gui.Parent=PG

local function round(obj,r)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r)
 c.Parent=obj
end
local mini=Instance.new("TextButton")
mini.Name="EggButton"
mini.Size=UDim2.fromOffset(64,64)
mini.Position=UDim2.new(.06,0,.32,0)
mini.BackgroundColor3=Color3.fromRGB(27,37,55)
mini.Text="🥚"
mini.TextSize=32
mini.TextColor3=Color3.new(1,1,1)
mini.Parent=gui
round(mini,32)
local stroke=Instance.new("UIStroke",mini)
stroke.Thickness=3
local dot=Instance.new("Frame",mini)
dot.Size=UDim2.fromOffset(13,13)
dot.Position=UDim2.new(1,-15,1,-15)
round(dot,10)

local frame=Instance.new("Frame")
frame.Name="StatusPanel"
frame.Size=UDim2.fromOffset(325,240)
frame.Position=UDim2.new(.5,-162,.18,0)
frame.BackgroundColor3=Color3.fromRGB(23,31,46)
frame.Parent=gui
frame.Active=true
round(frame,12)
local header=Instance.new("TextLabel",frame)
header.Size=UDim2.new(1,-92,0,38)
header.Position=UDim2.fromOffset(12,3)
header.BackgroundTransparency=1
header.Text="🥚 EGG MONITOR"
header.Font=Enum.Font.GothamBold
header.TextSize=17
header.TextXAlignment=Enum.TextXAlignment.Left
header.TextColor3=Color3.new(1,1,1)
local function panelButton(txt,x)
 local b=Instance.new("TextButton",frame)
 b.Size=UDim2.fromOffset(36,32)
 b.Position=UDim2.new(1,x,0,5)
 b.BackgroundColor3=Color3.fromRGB(51,62,80)
 b.Text=txt
 b.TextSize=20
 b.TextColor3=Color3.new(1,1,1)
 round(b,7)
 return b
end
local collapse=panelButton("−",-82)
local close=panelButton("❌",-42)
local info=Instance.new("TextLabel",frame)
info.Size=UDim2.new(1,-20,1,-106)
info.Position=UDim2.fromOffset(10,46)
info.BackgroundTransparency=1
info.Font=Enum.Font.Gotham
info.TextSize=15
info.TextColor3=Color3.new(1,1,1)
info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top
info.TextWrapped=true
local power=Instance.new("TextButton",frame)
power.Size=UDim2.new(1,-20,0,39)
power.Position=UDim2.new(0,10,1,-49)
power.BackgroundColor3=Color3.fromRGB(30,120,75)
power.TextColor3=Color3.new(1,1,1)
power.Font=Enum.Font.GothamBold
power.TextSize=16
round(power,8)
local collapsed=false
local function setCollapsed(v)
 collapsed=v
 frame.Size=UDim2.fromOffset(325,v and 42 or 240)
 info.Visible=not v
 power.Visible=not v
 collapse.Text=v and "+" or "−"
end
collapse.Activated:Connect(function() setCollapsed(not collapsed) end)
close.Activated:Connect(function() frame.Visible=false end)

local function makeDraggable(obj,handle)
 local dragging=false
 local startPos,origin,dragInput
 handle.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true
   startPos=input.Position
   origin=obj.Position
   dragInput=input
  end
 end)
 handle.InputEnded:Connect(function(input)
  if input==dragInput then dragging=false end
 end)
 return UIS.InputChanged:Connect(function(input)
  if dragging and startPos and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local delta=input.Position-startPos
   obj.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,origin.Y.Scale,origin.Y.Offset+delta.Y)
  end
 end)
end
local frameDrag=makeDraggable(frame,header)
local miniDragging=false
local miniStart,miniOrigin,miniMoved=nil,nil,false
mini.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  miniDragging=true;miniStart=input.Position;miniOrigin=mini.Position;miniMoved=false
 end
end)
mini.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then miniDragging=false end
end)
local miniDrag=UIS.InputChanged:Connect(function(input)
 if miniDragging and miniStart and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=input.Position-miniStart
  if delta.Magnitude>8 then miniMoved=true end
  mini.Position=UDim2.new(miniOrigin.X.Scale,miniOrigin.X.Offset+delta.X,miniOrigin.Y.Scale,miniOrigin.Y.Offset+delta.Y)
 end
end)
local stats={sent=0,found=0,active=0,last="กำลังเริ่มระบบ",telegram="ยังไม่ตรวจสอบ",blockedUntil=0}
local function status(s) stats.last=tostring(s) end
local function render()
 local on=env.EggMonitorEnabled
 local c=on and Color3.fromRGB(65,215,115) or Color3.fromRGB(240,75,75)
 stroke.Color=c;dot.BackgroundColor3=c
 power.Text=on and "🟢 ปิดระบบตรวจไข่" or "🔴 เปิดระบบตรวจไข่"
 power.BackgroundColor3=on and Color3.fromRGB(36,113,75) or Color3.fromRGB(135,58,58)
 local waitFor=math.max(0,math.ceil(stats.blockedUntil-os.time()))
 local tg=waitFor>0 and ("HTTP 429: รอ "..math.ceil(waitFor/60).." นาที") or stats.telegram
 info.Text="ระบบ: "..(on and "เปิดอยู่" or "ปิดอยู่").."\n"..
  "ไข่เป้าหมายในเซิร์ฟ: "..stats.active.." ใบ\n"..
  "แจ้งไข่แล้ว: "..stats.found.." ใบ\n"..
  "ส่งข้อความ/รูปสำเร็จ: "..stats.sent.." ครั้ง\n"..
  "Telegram: "..tg.."\n"..
  "ล่าสุด: "..stats.last
end
power.Activated:Connect(function()
 env.EggMonitorEnabled=not env.EggMonitorEnabled
 status(env.EggMonitorEnabled and "เปิดตรวจไข่แล้ว" or "หยุดตรวจไข่ชั่วคราว")
 render()
end)
mini.Activated:Connect(function()
 if miniMoved then miniMoved=false;return end
 frame.Visible=not frame.Visible
 render()
end)
render()

-- Telegram: serialize requests and obey retry_after. No per-minute message edits.
local queue={}
local queueHead=1
local MIN_REQUEST_GAP=2
local lastRequestAt=0
local function enqueue(method,data,priority)
 if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" or CHAT=="PUT_CHAT_ID_HERE" then
  stats.telegram="ยังไม่ได้ตั้ง TOKEN / CHAT หรือไม่มี HTTP"
  return nil
 end
 local job={method=method,data=data,done=false,result=nil,error=nil}
 if priority then table.insert(queue,queueHead,job) else table.insert(queue,job) end
 return job
end
local function awaitJob(job,timeout)
 if not job then return nil end
 local start=os.clock()
 while alive() and not job.done and (not timeout or os.clock()-start<timeout) do task.wait(.1) end
 return job.done and job.result or nil
end
local function api(method,data)
 return awaitJob(enqueue(method,data),nil)
end
local function send(s)
 return api("sendMessage",{chat_id=CHAT,text=s})
end
local function fireStatus(s) status(s);render() end
local function parseResponse(res)
 if not res then return nil end
 local ok,obj=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 return ok and obj or nil
end
task.spawn(function()
 while alive() do
  local job=queue[queueHead]
  if not job then
   -- Compact completed jobs to avoid unbounded memory usage.
   if queueHead>1 then queue={};queueHead=1 end
   task.wait(.2)
  else
   local waitFor=stats.blockedUntil-os.time()
   if waitFor>0 then
    task.wait(math.min(5,waitFor))
   else
    local gap=MIN_REQUEST_GAP-(os.clock()-lastRequestAt)
    if gap>0 then task.wait(gap) end
    if not alive() then break end
    lastRequestAt=os.clock()
    local ok,res=pcall(function()
     return req({Url="https://api.telegram.org/bot"..TOKEN.."/"..job.method,
      Method="POST",Headers={["Content-Type"]="application/json"},Body=HS:JSONEncode(job.data)})
    end)
    local obj=ok and parseResponse(res) or nil
    local code=ok and res and (res.StatusCode or res.Status) or nil
    if obj and obj.ok then
     job.result=obj;job.done=true;queueHead=queueHead+1
     if job.method=="sendMessage" or job.method=="sendPhoto" then
      stats.sent=stats.sent+1
     end
     stats.telegram="พร้อมใช้งาน"
    elseif tonumber(code)==429 or (obj and obj.error_code==429) then
     local retry=tonumber(obj and obj.parameters and obj.parameters.retry_after) or 60
     stats.blockedUntil=os.time()+math.max(1,retry)+2
     stats.telegram="ถูกจำกัด HTTP 429"
     fireStatus("Telegram ขอพัก "..retry.." วินาที")
     -- Do not complete job: retry after the server's requested delay.
    else
     job.error=tostring(obj and obj.description or (ok and code or res))
     job.done=true;queueHead=queueHead+1
     stats.telegram="ส่งไม่สำเร็จ"
     fireStatus(job.method..": "..job.error)
    end
   end
  end
 end
end)

local function thumbnail(id)
 if not req then return nil end
 local ok,res=pcall(function()
  return req({Url="https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false",Method="GET"})
 end)
 if not ok or not res then return nil end
 local good,data=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 local item=good and data.data and data.data[1]
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

-- Lifecycle: edit each Telegram egg message only once on its final state.
env.RideEggTracked=env.RideEggTracked or {}
local tracked=env.RideEggTracked
local pending={}
local pendingReset={}
local busy=false
local lastPhase,lastSeconds=nil,nil
local cycle=0
local warned={DAY=false,NIGHT=false}
local function eggName(e) return e:GetAttribute("Egg") end
local function captionFor(r,final)
 local icon=(EGGS[r.name] and EGGS[r.name].icon) or "🥚"
 local s=icon.." พบ "..r.name.."\n⚖️ น้ำหนัก: "..(r.weight or "กำลังอัปเดต")
 if final then s=s.."\n"..final end
 return s
end
local function editEggMessage(r,final)
 if not r.messageId then return false end
 local payload={chat_id=CHAT,message_id=r.messageId}
 if r.isPhoto then
  payload.caption=captionFor(r,final)
  -- Omitting markup alone may not remove old buttons; send an explicit empty keyboard.
  payload.reply_markup={inline_keyboard={}}
  return api("editMessageCaption",payload)~=nil
 else
  payload.text=captionFor(r,final)
  payload.reply_markup={inline_keyboard={}}
  return api("editMessageText",payload)~=nil
 end
end
local function finalize(r,final)
 if r.finalStatus then return end
 r.finalStatus=final
 if r.messageId then
  task.spawn(function()
   if editEggMessage(r,final) then fireStatus(r.name.." → "..final) end
  end)
 end
end
local function announce(e,r)
 if r.sending or r.messageId or r.state~="active" then return end
 r.sending=true
 task.wait(2)
 if not alive() or not env.EggMonitorEnabled or not e.Parent or r.state~="active" then
  r.sending=false;return
 end
 r.weight=weightOf(r.name)
 local keyboard={inline_keyboard={{{text="🥚 เก็บไข่",callback_data="C"..r.id}}}}
 local url=thumbnail(EGGS[r.name].asset)
 local res=nil
 if url then
  res=api("sendPhoto",{chat_id=CHAT,photo=url,caption=captionFor(r),reply_markup=keyboard})
 end
 if res then r.isPhoto=true
 else
  res=api("sendMessage",{chat_id=CHAT,text=captionFor(r),reply_markup=keyboard})
  r.isPhoto=false
 end
 if res and res.result then
  r.messageId=res.result.message_id
  stats.found=stats.found+1
  fireStatus("พบ "..r.name.." และแจ้ง Telegram แล้ว")
  if r.finalStatus then task.spawn(editEggMessage,r,r.finalStatus) end
 else
  fireStatus("แจ้ง "..r.name.." ไม่สำเร็จ")
 end
 r.sending=false
end
local function confirmCollected(r)
 if not r or r.state~="active" then return end
 r.state="telegram"
 finalize(r,"✅ สำเร็จ")
 pending[r.id]=nil
 task.spawn(send,"✅ ไข่ "..r.name.." ถูกเก็บสำเร็จแล้ว")
end
local function notifyChilliCollected(r)
 if r.chilliNoticeSent then return end
 r.chilliNoticeSent=true
 task.spawn(send,"✅ Chilli hub เก็บไข่ให้แล้ว\n"..((EGGS[r.name] and EGGS[r.name].icon) or "🥚").." "..r.name)
end
local function markMissing(r,phase,seconds)
 if r.state~="active" then return end
 if pending[r.id] then confirmCollected(r);return end
 if phase=="NIGHT" and seconds and seconds<=60 then
  r.state="await-reset";r.missingAt=os.clock();pendingReset[r.id]=r
  return
 end
 -- Limitation: the client sees disappearance, not a definitive collection event.
 r.state="other"
 finalize(r,"✅ Chilli hub เก็บไข่ให้แล้ว")
 notifyChilliCollected(r)
end
local function settleReset()
 for id,r in pairs(pendingReset) do
  if r.state=="await-reset" then
   r.state="reset"
   finalize(r,"❌ ไข่โดนรีเซ็ต")
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
   settleReset()
  end
  warned={DAY=false,NIGHT=false}
 elseif lastSeconds and seconds>lastSeconds+60 then
  warned[phase]=false
 end
 lastPhase,lastSeconds=phase,seconds
 if env.EggMonitorEnabled and seconds<=60 and not warned[phase] then
  local hasEgg=false
  for id,r in pairs(tracked) do
   if r.state=="active" and Active:FindFirstChild(id) then hasEgg=true;break end
  end
  if hasEgg then
   warned[phase]=true
   task.spawn(send,phase=="DAY" and "🌙 อีก 1 นาที จะเข้าสู่กลางคืน" or "☀️ อีก 1 นาที จะเข้าสู่ตอนเช้า")
  end
 end
 if phase=="NIGHT" and seconds>60 then
  for id,r in pairs(pendingReset) do
   if os.clock()-(r.missingAt or 0)>35 then
    r.state="other";pendingReset[id]=nil
    finalize(r,"✅ Chilli hub เก็บไข่ให้แล้ว")
    notifyChilliCollected(r)
   end
  end
 end
end

local function collectCycle(requestId)
 if busy then fireStatus("กำลังเก็บไข่รอบก่อนอยู่");return end
 if not env.EggMonitorEnabled then fireStatus("Egg Monitor ปิดอยู่");return end
 local chosen=Active:FindFirstChild(requestId)
 if not chosen or not EGGS[eggName(chosen)] then fireStatus("ไข่จากปุ่มนี้หายไปแล้ว");return end
 busy=true
 local offAttempted=false
 local function work()
  fireStatus("กำลังเก็บ "..eggName(chosen))
  local off=toggle5();offAttempted=true
  if off~=5 then error("สั่งปิด Halloween Event ได้ "..off.."/5 (หยุดเพื่อป้องกันสวิตช์ผิดสถานะ)") end
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
      used[id]=true;watching[id]=true;pending[id]=true
      count=count+1
      fireStatus("สั่งเก็บ "..count.."/"..MAX_COLLECT..": "..card.name)
     end
     break
    end
   end
   task.wait(.3)
  end
  if count==0 then fireStatus("ไม่พบปุ่ม Collect ที่กดได้") end
  local start=os.clock()
  while alive() and next(watching) and os.clock()-start<COLLECT_TIMEOUT do
   for id in pairs(watching) do
    if not Active:FindFirstChild(id) then
     watching[id]=nil
     confirmCollected(tracked[id])
     pending[id]=nil
    end
   end
   if next(watching) then task.wait(1) end
  end
  for id in pairs(watching) do
   pending[id]=nil
   fireStatus("ยังยืนยันการเก็บไข่ไม่ได้: "..id)
  end
  if count>0 and not next(watching) then task.wait(REOPEN_DELAY) end
  local on=toggle5();offAttempted=false
  fireStatus("เปิด Halloween Event กลับ "..on.."/5")
 end
 local ok,err=pcall(work)
 if not ok then
  fireStatus("เก็บไข่ผิดพลาด: "..tostring(err))
  -- A partial toggle cannot safely be reversed without reading switch state.
  if offAttempted then status("ตรวจสถานะ Halloween Event ทั้ง 5 รายการด้วย") end
 end
 for id in pairs(pending) do pending[id]=nil end
 busy=false
end

-- Long-polling via serialized API. Avoid concurrent getUpdates requests.
task.spawn(function()
 if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" or CHAT=="PUT_CHAT_ID_HERE" then
  fireStatus("ตั้ง TOKEN และ CHAT ก่อนใช้งาน Telegram")
  return
 end
 local offset=0
 local init=api("getUpdates",{timeout=0,limit=100,allowed_updates={"callback_query"}})
 if init then
  for _,u in ipairs(init.result or {}) do offset=math.max(offset,u.update_id+1) end
 end
 while alive() do
  local data=api("getUpdates",{offset=offset,timeout=0,limit=50,allowed_updates={"callback_query"}})
  if data then
   for _,u in ipairs(data.result or {}) do
    offset=math.max(offset,u.update_id+1)
    local cb=u.callback_query
    if cb and type(cb.data)=="string" and cb.data:sub(1,1)=="C" then
     local source=cb.message and cb.message.chat and tostring(cb.message.chat.id)
     -- Acknowledge callback once; avoid Telegram spinner.
     task.spawn(function() api("answerCallbackQuery",{callback_query_id=cb.id,text="รับคำสั่งแล้ว"}) end)
     if source==CHAT then task.spawn(collectCycle,cb.data:sub(2)) end
    end
   end
  end
  task.wait(5)
 end
end)

-- Egg detection: no edit loop, no start/stop Telegram messages.
task.spawn(function()
 while alive() do
  if env.EggMonitorEnabled then
   local phase,seconds=readTime()
   local present={}
   local count=0
   for _,e in ipairs(Active:GetChildren()) do
    local name=eggName(e)
    if EGGS[name] then
     count=count+1
     local id=e.Name
     present[id]=true
     if not tracked[id] then
      tracked[id]={id=id,name=name,state="active"}
     end
     local r=tracked[id]
     if r.state=="active" and not r.messageId and not r.sending and os.clock()-(r.lastAttempt or 0)>=30 then
      r.lastAttempt=os.clock()
      task.spawn(announce,e,r)
     end
    end
   end
   stats.active=count
   local sunrise=lastPhase=="NIGHT" and phase=="DAY"
   detectTime()
   for id,r in pairs(tracked) do
    if r.state=="active" and not present[id] then
     if sunrise and not pending[id] then
      r.state="reset"
      finalize(r,"❌ ไข่โดนรีเซ็ต")
     else
      markMissing(r,phase,seconds)
     end
    end
   end
  end
  task.wait(1)
 end
end)

-- Refresh local UI only; this does NOT call Telegram.
task.spawn(function()
 while alive() do render();task.wait(1) end
 if frameDrag then frameDrag:Disconnect() end
 if miniDrag then miniDrag:Disconnect() end
 if gui.Parent then gui:Destroy() end
end)
