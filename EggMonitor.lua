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

-- HTTP is serialized in a separate worker; scan loops never wait for Telegram.
local httpJobs={}
local lastHttp=0
local function api(method,data)
 if not req or TOKEN=="PUT_NEW_BOT_TOKEN_HERE" then return nil end
 local job={method=method,data=data,done=false,result=nil}
 table.insert(httpJobs,job)
 local untilAt=os.clock()+35
 while alive() and not job.done and os.clock()<untilAt do task.wait(.1) end
 return job.result
end
local function queueSend(text)
 task.spawn(function() api("sendMessage",{chat_id=CHAT,text=text}) end)
end
task.spawn(function()
 while alive() do
  local job=table.remove(httpJobs,1)
  if job then
   local gap=2.2-(os.clock()-lastHttp)
   if gap>0 then task.wait(gap) end
   lastHttp=os.clock()
   local ok,res=pcall(function()
    return req({Url="https://api.telegram.org/bot"..TOKEN.."/"..job.method,Method="POST",Headers={["Content-Type"]="application/json"},Body=HS:JSONEncode(job.data),Timeout=12})
   end)
   if ok and res then
    local yes,obj=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
    if yes and obj and obj.ok then job.result=obj end
    if yes and obj and obj.error_code==429 then
     local delay=math.clamp(tonumber(obj.parameters and obj.parameters.retry_after) or 5,2,45)
     task.wait(delay)
    end
   end
   job.done=true
  else task.wait(.12) end
 end
end)
local function send(s) queueSend(s) end
local function thumbnail(id)
 if not req then return nil end
 local ok,res=pcall(function() return req({Url="https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false",Method="GET"}) end)
 if not ok or not res then return nil end
 local yes,data=pcall(function() return HS:JSONDecode(res.Body or "{}") end)
 local item=yes and data.data and data.data[1]
 return item and item.state=="Completed" and item.imageUrl or nil
end
-- Use the exact Chilli Hub switch path and Activated handler from the user's original code.
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
 local changed={}
 for _,name in ipairs(SWITCHES) do
  if not alive() then break end
  if press(switchButton(name)) then table.insert(changed,name) end
  task.wait(.3)
 end
 return #changed,changed
end
local function restore5(changed)
 local n=0
 for i=#changed,1,-1 do
  if press(switchButton(changed[i])) then n=n+1 end
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
-- Read only the EggWeight inside the SAME Chilli Map Eggs card.
-- Do not climb through unrelated parent containers: that mixed weights of other eggs.
local function weightOf(name)
 local matches={}
 for _,card in ipairs(cards()) do
  if card.name==name then
   local p=card.label.Parent
   for _=1,4 do
    if not p then break end
    local w=p:FindFirstChild("EggWeight",true)
    if w and w:IsA("TextLabel") and w.Text~="" then
     matches[w.Text]=true
     break
    end
    for _,x in ipairs(p:GetDescendants()) do
     if x:IsA("TextLabel") and x~=card.label and x.Text:lower():find("kg",1,true) then
      matches[x.Text]=true
      break
     end
    end
    if next(matches) then break end
    p=p.Parent
   end
  end
 end
 local value,count=nil,0
 for w in pairs(matches) do value=w;count=count+1 end
 if count==1 then return value end
 if count>1 then return "รอตรวจสอบ (ไข่ชื่อซ้ำ)" end
 return "รอตรวจสอบ (ยังไม่พบ EggWeight)"
end
-- Match the Map Eggs card by name. Only accept a unique card as evidence.
local function basketEvidence(name)
 local matches=0
 local basket=false
 for _,root in ipairs(roots) do
  for _,v in ipairs(root:GetDescendants()) do
   if v:IsA("TextLabel") and v.Text==name then
    local parent=v.Parent
    for depth=1,4 do
     if not parent then break end
     local textParts={}
     for _,x in ipairs(parent:GetDescendants()) do
      if x:IsA("TextLabel") then textParts[#textParts+1]=x.Text:lower() end
     end
     local text=table.concat(textParts," ")
     if text:find("in basket",1,true) then
      matches=matches+1;basket=true;break
     end
     if text:find("queued",1,true) or text:find("collect",1,true) then
      matches=matches+1;break
     end
     parent=parent.Parent
    end
   end
  end
 end
 return matches==1 and basket
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
local autoEnabled=false
local dawnNotified=false
local collectClaims={}
local pendingMissing={}
local busy=false
local activeSource={}
local lastAutoAttempt={}
local dawnCycle=0
local dawnStarted=false
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
local function confirmCollected(record,source)
 if record.state~="active" and record.state~="missing" then return end
 if record.notifiedSuccess then return end
 local prefix=source=="telegram" and "✅ กดเก็บ " or (source=="auto" and "✅ ระบบ AUTO เก็บ " or "✅ ระบบ Chilli เก็บ ")
 record.notifiedSuccess=true
 record.state="collected"
 pendingMissing[record.id]=nil
 pending[record.id]=nil
 finalize(record,prefix..record.name.." สำเร็จ")
 send(prefix..record.name.." สำเร็จ")
end
local function markMissing(record,phase,seconds)
 if record.state~="active" then return end
 record.state="missing"
 record.missingAt=os.clock()
 record.missingPhase=phase
 record.missingSeconds=seconds
 pendingMissing[record.id]=record
end
local function settleReset()
 for id,record in pairs(pendingMissing) do
  if record.state=="missing" then
   record.state="reset"
   finalize(record,"❌ ไข่ถูกรีเซ็ต ไม่มีระบบไหนเก็บไปได้")
   send("❌ ไข่ถูกรีเซ็ต ไม่มีระบบไหนเก็บไปได้\n"..describe(record))
  end
  pendingMissing[id]=nil
 end
end
local function detectTime()
 local phase,seconds=readTime()
 if not phase then return end
 if lastPhase and phase~=lastPhase then
  if lastPhase=="NIGHT" and phase=="DAY" then
   cycle=cycle+1
   dawnCycle=dawnCycle+1
   dawnStarted=false
   dawnNotified=false
   -- Allow final basket checks before declaring the reset.
   task.delay(4,function()
    if alive() then settleReset() end
   end)
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
   if phase=="DAY" then
    send("🌙 อีก 1 นาที จะเข้าสู่กลางคืน")
   else
    dawnNotified=true
    send("☀️ อีก 1 นาที จะเข้าสู่ตอนเช้า")
   end
  end
 end
end

local function collectCycle(requestId,source)
 source=source or "telegram"
 if busy or not env.EggMonitorEnabled then return end
 local chosen=Active:FindFirstChild(requestId)
 if not chosen or not EGGS[eggName(chosen)] then return end
 busy=true
 collectClaims[requestId]={source=source,at=os.clock()}
 local changed={}
 local function work()
  local n
  n,changed=toggle5()
  if n~=5 then error("ปิด Event ไม่ครบ 5/5 (กดได้ "..n..")") end
  task.wait(.5)
  local count=0
  local watching={}
  for _,card in ipairs(cards()) do
   if count>=MAX_COLLECT then break end
   local selected=nil
   for _,e in ipairs(Active:GetChildren()) do
    if eggName(e)==card.name and not pending[e.Name] and (e.Name==requestId or source=="auto") then
     selected=e.Name;break
    end
   end
   if selected and press(card.button) then
    pending[selected]=true
    activeSource[selected]=source
    watching[selected]=true
    count=count+1
   end
  end
  local started=os.clock()
  while alive() and next(watching) and os.clock()-started<math.min(COLLECT_TIMEOUT,55) do
   for id in pairs(watching) do
    if not Active:FindFirstChild(id) then
     watching[id]=nil
     local record=tracked[id]
     -- Wait for an actual basket state before reporting success.
     if record and basketEvidence(record.name) then
      confirmCollected(record,source)
     elseif record and record.state=="active" then
      markMissing(record,select(1,readTime()),select(2,readTime()))
     end
    end
   end
   task.wait(1)
  end
  for id in pairs(watching) do pending[id]=nil end
 end
 local ok,err=pcall(work)
 local restored=restore5(changed)
 if not ok then send("⚠️ เก็บไข่ไม่สำเร็จ: "..tostring(err)) end
 if #changed>0 and restored~=#changed then send("⚠️ เปิด Event กลับไม่ครบ โปรดตรวจสอบสวิตช์") end
 for id in pairs(pending) do pending[id]=nil;activeSource[id]=nil end
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
    local message=u.message
    if message and message.chat and tostring(message.chat.id)==tostring(CHAT) then
     local cmd=tostring(message.text or ""):lower():match("^%s*(.-)%s*$")
     if cmd=="auto" then
      autoEnabled=true
      send("🤖 เปิด AUTO สำรองแล้ว จะเก็บไข่ที่เหลือหลังแจ้งเตือน 1 นาทีก่อนเช้า")
     elseif cmd=="stop" then
      autoEnabled=false
      send("🛑 ปิด AUTO สำรองแล้ว ระบบตรวจไข่และปุ่ม Telegram ยังทำงาน")
     end
    end
    local cb=u.callback_query
    if cb and type(cb.data)=="string" and cb.data:sub(1,1)=="C" then
     local source=cb.message and cb.message.chat and tostring(cb.message.chat.id)
     api("answerCallbackQuery",{callback_query_id=cb.id,text="รับคำสั่งแล้ว"})
     if source==CHAT then task.spawn(collectCycle,cb.data:sub(2),"telegram") end
    end
   end
  end
  task.wait(7)
 end
end)

task.spawn(function()
 while alive() do
  if autoEnabled and env.EggMonitorEnabled and not busy then
   local phase,seconds=readTime()
   if phase=="NIGHT" and seconds and seconds<=60 and dawnNotified then
    for _,e in ipairs(Active:GetChildren()) do
     if EGGS[eggName(e)] and not pending[e.Name] and not lastAutoAttempt[e.Name] then
      lastAutoAttempt[e.Name]=true
      task.spawn(collectCycle,e.Name,"auto")
      break
     end
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
     if not tracked[id] then
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
     markMissing(record,phase,seconds)
    end
    if record.state=="missing" then
     if basketEvidence(record.name) then
      local claim=collectClaims[id]
      local source=claim and claim.source or "chilli"
      confirmCollected(record,source)
     elseif sunrise then
      -- Reset will be finalized after the sunrise grace period.
     end
    end
   end
  end
  task.wait(1)
 end
end)

task.spawn(function()
 while alive() do task.wait(1) end
 if dragConnection then dragConnection:Disconnect() end
 if gui.Parent then gui:Destroy() end
end)
