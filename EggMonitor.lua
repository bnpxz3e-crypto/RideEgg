-- Ride A Pet | Egg monitor + Telegram + Day/Night
-- Fill in a NEW Telegram bot token. Do not share it publicly.
local TOKEN = "8455689997:AAHwzIdo53Eo4v1IdaONYYkUhR8yGylUaCI"
local CHAT = "1813392489"

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
env.RideEggAuto=env.RideEggAuto or false
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

-- Telegram queue: network requests never execute in the egg scanner.
local queue,head={},1
local nextRequest=0
local blockedUntil=0
local function enqueue(method,data,waitResult)
 if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" then return nil end
 local job={method=method,data=data,done=false,result=nil}
 table.insert(queue,job)
 if not waitResult then return job end
 while alive() and not job.done do task.wait(.1) end
 return job.result
end
local function api(method,data) return enqueue(method,data,true) end
local function send(s) return enqueue("sendMessage",{chat_id=CHAT,text=s},false) end
local function requestNow(job)
 local ok,res=pcall(function()
  return req({Url="https://api.telegram.org/bot"..TOKEN.."/"..job.method,
   Method="POST",Headers={["Content-Type"]="application/json"},
   Body=HS:JSONEncode(job.data),Timeout=12})
 end)
 if not ok or not res then return nil,0 end
 local good,obj=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 return good and obj or nil,tonumber(res.StatusCode or res.Status) or 0
end
task.spawn(function()
 while alive() do
  local job=queue[head]
  if not job then
   if head>1 then queue={};head=1 end
   task.wait(.2)
  else
   local waitFor=math.max(nextRequest-os.clock(),blockedUntil-os.clock())
   if waitFor>0 then task.wait(math.min(waitFor,2))
   else
    nextRequest=os.clock()+2.2
    local obj,code=requestNow(job)
    if (obj and obj.error_code==429) or code==429 then
     local retry=tonumber(obj and obj.parameters and obj.parameters.retry_after) or 60
     blockedUntil=os.clock()+math.max(5,retry)+2
    else
     job.result=obj and obj.ok and obj or nil
     job.done=true
     head=head+1
    end
   end
  end
 end
end)

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

-- Small draggable egg ON/OFF button
for _,name in ipairs({"EggMonitorMini","DayNightLiveTest","DayNightTestV12"}) do
 local old=PG:FindFirstChild(name)
 if old then old:Destroy() end
end
local gui=Instance.new("ScreenGui")
gui.Name="EggMonitorMini";gui.ResetOnSpawn=false;gui.DisplayOrder=999;gui.Parent=PG
local button=Instance.new("TextButton")
button.Size=UDim2.fromOffset(68,68)
button.Position=UDim2.new(.08,0,.3,0)
button.BackgroundColor3=Color3.fromRGB(30,38,54)
button.Text="🥚";button.TextSize=36;button.Parent=gui
Instance.new("UICorner",button).CornerRadius=UDim.new(1,0)
local stroke=Instance.new("UIStroke",button)
stroke.Thickness=3
local dot=Instance.new("Frame")
dot.Size=UDim2.fromOffset(13,13);dot.Position=UDim2.new(1,-15,1,-15);dot.Parent=button
Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
local function render()
 local color=env.EggMonitorEnabled and Color3.fromRGB(50,215,110) or Color3.fromRGB(240,65,65)
 stroke.Color=color;dot.BackgroundColor3=color
end
render()
local dragging,dragStart,startPos,moved=false,nil,nil,false
button.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true;dragStart=input.Position;startPos=button.Position;moved=false
 end
end)
button.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
local dragConnection=UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) and dragStart then
  local delta=input.Position-dragStart
  if delta.Magnitude>8 then moved=true end
  button.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)
button.Activated:Connect(function()
 if moved then moved=false;return end
 env.EggMonitorEnabled=not env.EggMonitorEnabled
 render()
 task.spawn(send,env.EggMonitorEnabled and "🟢 เปิดระบบ Egg Monitor แล้ว" or "🔴 ปิดระบบ Egg Monitor แล้ว")
end)

-- Each active egg has its own lifecycle; do not mistake a reset for collection.
-- Preserve message IDs when rerunning this version in the same Roblox session.
env.RideEggTracked = env.RideEggTracked or {}
local tracked=env.RideEggTracked
local pending={}
local busy=false
local lastPhase,lastSeconds=nil,nil
local cycle=0
local warned={DAY=false,NIGHT=false}
local pendingReset={}
local function captionFor(record,status)
 local item=EGGS[record.name]
 return item.icon.." พบ "..record.name.."\n⚖️ น้ำหนัก: "..(record.weight or "กำลังอัปเดต").."\n"..(status or "🥚 กดปุ่มเพื่อเก็บไข่")
end

local function editEggMessage(record,status)
 if not record.messageId then return false end
 status=status or record.finalStatus
 local payload={chat_id=CHAT,message_id=record.messageId}
 if status then
  payload.reply_markup={inline_keyboard={}}
 elseif record.state=="active" then
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
 if record.messageId then task.spawn(editEggMessage,record,status) end
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
 record.state=record.collectSource or "telegram"
 finalize(record,record.collectSource=="auto" and "✅ Auto เก็บไข่สำเร็จแล้ว" or "✅ เก็บไข่สำเร็จ!")
 pending[record.id]=nil
 send((record.collectSource=="auto" and "🤖 Auto เก็บไข่สำเร็จแล้ว\n" or "✅ เก็บไข่สำเร็จ!\n")..describe(record))
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
 record.state="uncertain"
 finalize(record,"⚠️ ไข่หายจากข้อมูล ยังยืนยันการเก็บไม่ได้")
 send("⚠️ ไข่หายจากข้อมูล ยังยืนยันการเก็บไม่ได้\n"..describe(record))
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
   else send("☀️ อีก 1 นาที จะเข้าสู่ตอนเช้า") end
  end
 end
 -- If the countdown wrapped while image remained unchanged, avoid indefinite pending.
 if phase=="NIGHT" and seconds>60 then
  for id,record in pairs(pendingReset) do
   if os.clock()-(record.missingAt or 0)>35 then
    record.state="other";pendingReset[id]=nil
    finalize(record,"🥚 ไข่ถูกเก็บแล้ว (ไม่ได้เก็บผ่าน Telegram)")
    send("🥚 ไข่ถูกเก็บแล้ว (ไม่ได้เก็บผ่าน Telegram)\n"..describe(record))
   end
  end
 end
end

local function collectCycle(requestId,source)
 source=source or "telegram"
 if busy then send("⏳ กำลังเก็บไข่รอบก่อนอยู่");return end
 if not env.EggMonitorEnabled then send("🔴 ระบบ Egg Monitor ปิดอยู่");return end
 local chosen=Active:FindFirstChild(requestId)
 if not chosen or not EGGS[eggName(chosen)] then send("⚠️ ไข่จากปุ่มนี้หายไปแล้ว");return end
 busy=true
 local switched=false
 local function work()
  if source~="auto" then send("🥚 กำลังไปเก็บไข่\n"..eggName(chosen)) end
  local off=toggle5();switched=true
  if source~="auto" then send("⏸ สั่งปิด Halloween Event "..off.."/5") end
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
      used[id]=true;watching[id]=true;pending[id]=true
       if tracked[id] then tracked[id].collectSource=source end
       if source=="auto" then env.RideEggAutoAttempted[id]=true end
      count=count+1
      if source~="auto" then send("🥚 สั่ง Collect "..count.."/"..MAX_COLLECT..": "..card.name) end
     end
     break
    end
   end
   task.wait(.3)
  end
  if count==0 then send("⚠️ ไม่พบปุ่ม Collect ที่กดได้") end
  local start=os.clock()
  while alive() and next(watching) and os.clock()-start<(source=="auto" and 32 or COLLECT_TIMEOUT) do
   for id in pairs(watching) do
    if not Active:FindFirstChild(id) then
     watching[id]=nil
     local record=tracked[id]
     if record then
       record.state="uncertain"
       finalize(record,"⚠️ สั่งเก็บแล้ว แต่ยังยืนยันผลไม่ได้")
       send("⚠️ สั่งเก็บไข่แล้ว แต่ยังยืนยันผลไม่ได้\n"..describe(record))
      end
     pending[id]=nil
    end
   end
   if next(watching) then task.wait(1) end
  end
  for id in pairs(watching) do
   pending[id]=nil
   if source~="auto" then send("⚠️ ยังไม่ยืนยันการเก็บไข่: "..id) end
  end
  if count>0 and not next(watching) and source~="auto" then task.wait(REOPEN_DELAY) end
  local on=toggle5();switched=false
  if source~="auto" then send("▶️ สั่งเปิด Halloween Event กลับ "..on.."/5") end
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

-- Telegram commands + inline buttons, poll less often to avoid rate limits.
task.spawn(function()
 local offset=0
 local init=api("getUpdates",{timeout=0,limit=100,allowed_updates={"callback_query","message"}})
 if init then for _,u in ipairs(init.result or {}) do offset=math.max(offset,u.update_id+1) end end
 while alive() do
  local data=api("getUpdates",{offset=offset,timeout=0,limit=50,allowed_updates={"callback_query","message"}})
  if data then
   for _,u in ipairs(data.result or {}) do
    offset=math.max(offset,u.update_id+1)
    local m=u.message
    if m and m.chat and tostring(m.chat.id)==tostring(CHAT) then
     local cmd=tostring(m.text or ""):lower():match("^%s*(.-)%s*$")
     if cmd=="auto" then
      env.RideEggAuto=true
      send("🤖 เปิด Auto แล้ว: เก็บไข่ทุกเช้าเฉพาะช่วง 1 นาทีก่อนเช้า จนกว่าจะพิมพ์ stop")
     elseif cmd=="stop" then
      env.RideEggAuto=false
      send("🛑 ปิด Auto แล้ว ระบบแจ้งไข่และปุ่มเก็บเองยังทำงาน")
     end
    end
    local cb=u.callback_query
    if cb and type(cb.data)=="string" and cb.data:sub(1,1)=="C" then
     enqueue("answerCallbackQuery",{callback_query_id=cb.id,text="รับคำสั่งแล้ว"},false)
     if cb.message and cb.message.chat and tostring(cb.message.chat.id)==tostring(CHAT) then
      task.spawn(collectCycle,cb.data:sub(2),"telegram")
     end
    end
   end
  end
  task.wait(7)
 end
end)

-- Auto starts only in the final 60 seconds of NIGHT; attempts each ID once per dawn.
local autoWindow=false
local autoBusy=false
env.RideEggAutoAttempted={}
local function runAuto()
 if autoBusy then return end
 autoBusy=true
 while alive() and env.RideEggAuto and env.EggMonitorEnabled do
  local phase,seconds=readTime()
  if phase~="NIGHT" or not seconds or seconds>60 or seconds<=7 then break end
  if busy then task.wait(1)
  else
   local id=nil
   for _,e in ipairs(Active:GetChildren()) do
    if EGGS[e:GetAttribute("Egg")] and not env.RideEggAutoAttempted[e.Name] then
     local r=tracked[e.Name]
     if not r or r.state=="active" then id=e.Name;break end
    end
   end
   if id then
    env.RideEggAutoAttempted[id]=true
    collectCycle(id,"auto")
   else task.wait(1) end
  end
 end
 autoBusy=false
end


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
     if not tracked[id] then
      tracked[id]={id=id,name=name,state="active",cycle=cycle,spawnedAt=os.time()}
      task.spawn(announce,e,tracked[id])
     end
    end
   end
   -- Detect time transition first; classify eggs missing at sunrise as reset.
   local sunrise=(lastPhase=="NIGHT" and phase=="DAY")
   detectTime()
   local inWindow=(phase=="NIGHT" and seconds and seconds<=60)
   if inWindow and not autoWindow then env.RideEggAutoAttempted={} end
   autoWindow=not not inWindow
   if inWindow and env.RideEggAuto and not autoBusy then task.spawn(runAuto) end
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

-- Removed spawn-age counter and periodic Telegram edits.
-- No periodic edit requests are made for egg age.

task.spawn(function()
 while alive() do task.wait(1) end
 if dragConnection then dragConnection:Disconnect() end
 if gui.Parent then gui:Destroy() end
end)
