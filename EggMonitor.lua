-- Ride A Pet Egg Monitor | Chilli / Telegram / Auto backup
-- Set a NEW bot token privately. Never publish a token to public GitHub.
local TOKEN = "8455689997:AAHwzIdo53Eo4v1IdaONYYkUhR8yGylUaCI"
local CHAT = "1813392489"
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local HS=game:GetService('HttpService')
local UIS=game:GetService('UserInputService')
local PG=Players.LocalPlayer:WaitForChild('PlayerGui')
local Active=RS:WaitForChild('ServerData'):WaitForChild('ActiveEggs')
local roots={PG,game:GetService('CoreGui')}
local req=(syn and syn.request) or (http and http.request) or http_request or request
local env=(getgenv and getgenv()) or _G
env.RideEggRun=(env.RideEggRun or 0)+1
local RUN=env.RideEggRun
local function alive() return env.RideEggRun==RUN end
env.EggMonitorEnabled=true
env.RideEggAuto=env.RideEggAuto or false
local EGGS={['Volcanic Egg']={icon='🌋',asset='132679696143806'},['Solaris Egg']={icon='☀️',asset='131016816558781'},['Cherub Egg']={icon='👼',asset='78949206711037'}}
local SWITCHES={'Auto Collect Candy','Auto Search Pumpkins','Auto Trick Or Treat','Auto Halloween Ritual','Collect Rare Eggs First'}
local DAY_ID='94969857695475'
local NIGHT_ID='106891725078200'
local function eggName(e) return e:GetAttribute('Egg') end
local function desc(r) return (EGGS[r.name] and EGGS[r.name].icon or '🥚')..' '..r.name end

-- Telegram is isolated in one bounded, paced queue. No HTTP on the scan loop.
local jobs,head={},1
local lastHTTP=0
local blockedUntil=0
local offset=0
local function enqueue(method,data,callback,priority)
 if not req or TOKEN=='PUT_NEW_BOT_TOKEN_HERE' or CHAT=='PUT_CHAT_ID_HERE' then return false end
 if #jobs-head>90 and not priority then return false end
 local job={method=method,data=data,callback=callback,tries=0}
 if priority then table.insert(jobs,head,job) else table.insert(jobs,job) end
 return true
end
local function send(msg) return enqueue('sendMessage',{chat_id=CHAT,text=msg}) end
local function decode(body)
 local ok,obj=pcall(function() return HS:JSONDecode(body or '{}') end)
 return ok and obj or nil
end
task.spawn(function()
 while alive() do
  local job=jobs[head]
  if not job then
   if head>1 then jobs={};head=1 end
   task.wait(.25)
  elseif os.clock()<blockedUntil then
   task.wait(math.min(2,blockedUntil-os.clock()))
  else
   local gap=2.2-(os.clock()-lastHTTP)
   if gap>0 then task.wait(gap) end
   if not alive() then break end
   lastHTTP=os.clock()
   local ok,res=pcall(function()
    return req({Url='https://api.telegram.org/bot'..TOKEN..'/'..job.method,Method='POST',Headers={['Content-Type']='application/json'},Body=HS:JSONEncode(job.data),Timeout=12})
   end)
   local obj=ok and res and decode(res.Body) or nil
   local status=tonumber(ok and res and (res.StatusCode or res.Status)) or 0
   if status==429 or (obj and obj.error_code==429) then
    blockedUntil=os.clock()+math.max(3,tonumber(obj and obj.parameters and obj.parameters.retry_after) or 30)+2
   else
    head=head+1
    if job.callback then task.spawn(job.callback,obj and obj.ok and obj or nil) end
    if not (obj and obj.ok) and job.method~='getUpdates' then
     warn('EggMonitor Telegram '..job.method..' failed: '..tostring(obj and obj.description or status))
    end
   end
  end
 end
end)

-- Small draggable on/off egg button, unchanged basic workflow.
local old=PG:FindFirstChild('EggMonitorMini')
if old then old:Destroy() end
local gui=Instance.new('ScreenGui')
gui.Name='EggMonitorMini';gui.ResetOnSpawn=false;gui.DisplayOrder=999;gui.Parent=PG
local button=Instance.new('TextButton')
button.Size=UDim2.fromOffset(68,68);button.Position=UDim2.new(.08,0,.3,0)
button.BackgroundColor3=Color3.fromRGB(30,38,54);button.Text='🥚';button.TextSize=36;button.Parent=gui
Instance.new('UICorner',button).CornerRadius=UDim.new(1,0)
local stroke=Instance.new('UIStroke',button);stroke.Thickness=3
local dot=Instance.new('Frame',button);dot.Size=UDim2.fromOffset(13,13);dot.Position=UDim2.new(1,-15,1,-15)
Instance.new('UICorner',dot).CornerRadius=UDim.new(1,0)
local function render()
 local c=env.EggMonitorEnabled and Color3.fromRGB(50,215,110) or Color3.fromRGB(240,65,65)
 stroke.Color=c;dot.BackgroundColor3=c
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
 if dragging and dragStart and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
  local delta=input.Position-dragStart
  if delta.Magnitude>8 then moved=true end
  button.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)
button.Activated:Connect(function()
 if moved then moved=false;return end
 env.EggMonitorEnabled=not env.EggMonitorEnabled
 render()
 send(env.EggMonitorEnabled and '🟢 เปิดระบบ Egg Monitor แล้ว' or '🔴 ปิดระบบ Egg Monitor แล้ว')
end)

local function readTime()
 local main=PG:FindFirstChild('Main')
 local dn=main and main:FindFirstChild('DayNightRotation')
 local t=dn and dn:FindFirstChild('TimerLabel')
 local img=dn and dn:FindFirstChild('TimeImage')
 if not t or not img then return nil,nil end
 local str=t.Text or ''
 if not str:match('%d+%s*[ms]') then return nil,nil end
 local m=tonumber(str:match('(%d+)%s*m')) or 0
 local s=tonumber(str:match('(%d+)%s*s')) or 0
 local id=(img.Image or ''):match('(%d+)$')
 return id==DAY_ID and 'DAY' or (id==NIGHT_ID and 'NIGHT' or nil),m*60+s
end

-- Cache Chilli GUI controls. Scan only once every 3s and yield while traversing.
local cardCache,swCache,basketCache={},{},{}
local function guiScan()
 local found,seen={},{}
 local switches={}
 local baskets={}
 for _,root in ipairs(roots) do
  local nodes=root:GetDescendants()
  for i,v in ipairs(nodes) do
   if i%350==0 then task.wait() end
   if v:IsA('TextLabel') and EGGS[v.Text] then
    local p=v.Parent
    for _=1,5 do
     if not p then break end
     local b=p:FindFirstChild('Open')
     if b and b:IsA('GuiButton') then
      if not seen[b] then seen[b]=true;table.insert(found,{name=v.Text,button=b,label=v}) end
      break
     end
     p=p.Parent
    end
   end
   if (v:IsA('TextLabel') or v:IsA('TextButton')) and v.Text:lower():find('in basket',1,true) then
    local p=v.Parent
    for _=1,4 do
     if not p then break end
     for _,q in ipairs(p:GetChildren()) do
      if q:IsA('TextLabel') and EGGS[q.Text] then baskets[q.Text]=true end
     end
     p=p.Parent
    end
   end
   if v.Name=='Switch' and v.Parent and (v.Parent.Name=='Auto Collect Eggs' or table.find(SWITCHES,v.Parent.Name)) then
    local b=v:FindFirstChild('Button',true)
    if b and b:IsA('GuiButton') then switches[v.Parent.Name]=b end
   end
  end
 end
 cardCache,swCache,basketCache=found,switches,baskets
end
task.spawn(function()
 while alive() do
  if env.EggMonitorEnabled then pcall(guiScan) end
  task.wait(3)
 end
end)
local function weightOf(name)
 for _,c in ipairs(cardCache) do
  if c.name==name and c.label.Parent then
   local p=c.label.Parent
   for _=1,4 do
    if not p then break end
    local w=p:FindFirstChild('EggWeight',true)
    if w and w:IsA('TextLabel') and w.Text~='' then return w.Text end
    for _,v in ipairs(p:GetDescendants()) do
     if v:IsA('TextLabel') and v.Text:lower():find('kg',1,true) then return v.Text end
    end
    p=p.Parent
   end
  end
 end
 -- Fallback: search visible egg cards directly when the cache has not loaded.
 for _,root in ipairs(roots) do
  local seen=0
  for _,v in ipairs(root:GetDescendants()) do
   seen=seen+1
   if seen%450==0 then task.wait() end
   if v:IsA('TextLabel') and v.Text==name then
    local p=v.Parent
    for _=1,4 do
     if not p then break end
     local w=p:FindFirstChild('EggWeight',true)
     if w and w:IsA('TextLabel') and w.Text:lower():find('kg',1,true) then return w.Text end
     for _,x in ipairs(p:GetDescendants()) do
      if x:IsA('TextLabel') and x.Text:lower():find('kg',1,true) then return x.Text end
     end
     p=p.Parent
    end
   end
  end
 end
 return 'กำลังอัปเดต'
end
-- Use the original user's Chilli switch path, with a click-signal fallback.
local function press(b)
 if not b or not b.Parent or not b:IsA('GuiButton') or not getconnections then return false end
 for _,signal in ipairs({b.Activated,b.MouseButton1Click,b.MouseButton1Down}) do
  local ok,done=pcall(function()
   for _,c in ipairs(getconnections(signal)) do
    if c.Function then c.Function();return true end
   end
   return false
  end)
  if ok and done then return true end
 end
 return false
end
local function switchButton(name)
 for _,root in ipairs(roots) do
  local v=root:FindFirstChild(name,true)
  if v then
   local sw=v:FindFirstChild('Switch',true)
   local b=sw and sw:FindFirstChild('Button',true)
   if b and b:IsA('GuiButton') then return b,sw end
  end
 end
 return nil,nil
end
-- Green switch backgrounds are ON in the user's screenshot.
-- Do not blindly toggle an already-OFF switch, and never touch Auto Collect Eggs.
local function switchState(sw)
 if not sw then return nil end
 local bg=sw:IsA('GuiObject') and sw or sw:FindFirstChildWhichIsA('Frame')
 if not bg then return nil end
 local c=bg.BackgroundColor3
 local r,g,b=c.R,c.G,c.B
 if g>r*1.22 and g>b*1.22 and g>.24 then return true end
 if r<.35 and g<.35 and b<.35 then return false end
 return nil
end
local eventOriginal={}
local function setEventsOff()
 local changed={}
 for _,name in ipairs(SWITCHES) do
  if not alive() then break end
  local button,sw=switchButton(name)
  if not button then return false,changed,'ไม่พบสวิตช์ '..name end
  local wasOn=switchState(sw)
  if wasOn==false then
   eventOriginal[name]=false
  elseif wasOn==true then
   eventOriginal[name]=true
   if not press(button) then return false,changed,'กดปิดไม่ได้ '..name end
   table.insert(changed,name)
   task.wait(.35)
   local _,after=switchButton(name)
   if switchState(after)~=false then return false,changed,'สวิตช์ยังไม่ปิด '..name end
  else
   return false,changed,'อ่านสถานะสวิตช์ไม่ได้ '..name
  end
 end
 return true,changed
end
local function restoreEvents(changed)
 for i=#changed,1,-1 do
  if not alive() then break end
  local name=changed[i]
  local button,sw=switchButton(name)
  if button and switchState(sw)==false then
   press(button)
   task.wait(.35)
  end
 end
end
-- Chilli state is NOT inferred from a green button; this is game/UI dependent.
-- An explicit In basket label is stronger evidence, but may be ambiguous for duplicate names.
local function inBasket(name)
 return basketCache[name]==true
end
local thumbCache={}
local function thumbnail(id)
 if thumbCache[id] then return thumbCache[id] end
 if not req then return nil end
 local ok,res=pcall(function()
  return req({Url='https://thumbnails.roblox.com/v1/assets?assetIds='..id..'&size=420x420&format=Png&isCircular=false',Method='GET',Timeout=8})
 end)
 if not ok or not res then return nil end
 local good,data=pcall(function() return HS:JSONDecode(res.Body or '{}') end)
 local item=good and data and data.data and data.data[1]
 if item and item.state=='Completed' and item.imageUrl then
  thumbCache[id]=item.imageUrl
  return item.imageUrl
 end
 return nil
end
local chilliNoticeAt={}
local tracked={}
local pending={}
local busy=false
local autoWindow=false
local attempted={}
local lastPhase,lastSeconds=nil,nil
local warned={DAY=false,NIGHT=false}
local cycle=0
local function caption(r,final)
 return desc(r):gsub('^','🥚 พบ ')..'\n⚖️ น้ำหนัก: '..(r.weight or 'กำลังอัปเดต')..(final and ('\n'..final) or '\n🥚 กดปุ่มเพื่อเก็บไข่')
end
local function edit(r)
 if not r.messageId or not r.final then return end
 local data={chat_id=CHAT,message_id=r.messageId,reply_markup={inline_keyboard={}}}
 if r.isPhoto then data.caption=caption(r,r.final) else data.text=caption(r,r.final) end
 enqueue(r.isPhoto and 'editMessageCaption' or 'editMessageText',data)
end
local function finish(r,kind)
 if not r or r.final then return end
 if kind=='chilli' then
  local now=os.clock()
  if chilliNoticeAt[r.name] and now-chilliNoticeAt[r.name]<12 then
   -- Duplicate ActiveEggs IDs can refer to the same Chilli collection.
   r.state='chilli';r.final='✅ Chilli เก็บ '..r.name..' สำเร็จ';edit(r);return
  end
  chilliNoticeAt[r.name]=now
 end
 r.state=kind;r.final=true
 local msg
 if kind=='chilli' then msg='✅ Chilli เก็บ '..r.name..' สำเร็จ';r.final=msg
 elseif kind=='telegram' then msg='✅ กดเก็บ '..r.name..' สำเร็จ';r.final=msg
 elseif kind=='auto' then msg='✅ ระบบ AUTO เก็บ '..r.name..' สำเร็จ';r.final=msg
 elseif kind=='reset' then msg='❌ ไข่ถูกรีเซ็ต ไม่มีระบบไหนเก็บไปได้\n'..desc(r);r.final='❌ ไข่ถูกรีเซ็ต ไม่มีระบบไหนเก็บไปได้'
 else msg='⚠️ '..r.name..' หายจากข้อมูล ยังไม่ยืนยันว่าเก็บแล้ว';r.final='⚠️ ยังยืนยันการเก็บไม่ได้' end
 edit(r);send(msg)
end
local function announce(e,r)
 task.wait(2)
 if not alive() or not env.EggMonitorEnabled or not e.Parent or r.final then return end
 -- Give Chilli's UI a moment to populate EggWeight before sending.
 local weight='กำลังอัปเดต'
 for i=1,6 do
  if not alive() or r.final then return end
  weight=weightOf(r.name)
  if weight~='กำลังอัปเดต' then break end
  task.wait(1)
 end
 r.weight=weight
 local keyboard={inline_keyboard={{{text='🥚 เก็บไข่',callback_data='C'..r.id}}}}
 local function done(obj,photo)
  if not alive() then return end
  if obj and obj.result then
   r.messageId=obj.result.message_id;r.isPhoto=photo
   if r.final then edit(r) end
  elseif photo then
   enqueue('sendMessage',{chat_id=CHAT,text=caption(r),reply_markup=keyboard},function(other) done(other,false) end)
  end
 end
 -- Thumbnail lookup runs only in this independent task, never in the scan loop.
 local url=thumbnail(EGGS[r.name].asset)
 if url then
  enqueue('sendPhoto',{chat_id=CHAT,photo=url,caption=caption(r),reply_markup=keyboard},function(obj) done(obj,true) end)
 else
  enqueue('sendMessage',{chat_id=CHAT,text=caption(r),reply_markup=keyboard},function(obj) done(obj,false) end)
 end
end

-- Source attribution: only record success when we have a matching positive collection signal.
-- A missing ActiveEggs ID by itself never confirms collection.
local function confirmed(r,source)
 if r.final then return end
 if inBasket(r.name) then finish(r,source) end
end
local function collect(requestId,source)
 if busy or not alive() or not env.EggMonitorEnabled then return false end
 local chosen=Active:FindFirstChild(requestId)
 if not chosen or not EGGS[eggName(chosen)] then return false end
 local r=tracked[requestId]
 if not r or r.final or inBasket(r.name) then
  if r and not r.final then finish(r,'chilli') end
  return false
 end
 busy=true
 local changed={}
 local ok,err=pcall(function()
  -- Preserve original sequence: turn off 5 event switches, collect, turn on again.
  -- Never toggle Chilli's separate Auto Collect Eggs switch.
  local success,changedNow,why=setEventsOff()
  changed=changedNow
  if not success then error('ไม่สามารถปิด Event: '..tostring(why)) end
  task.wait(1)
  local selected={}
  for _,c in ipairs(cardCache) do
   if c.name==r.name and c.button.Parent then table.insert(selected,c) end
  end
  if #selected==0 then error('ไม่พบปุ่ม Open ของ '..r.name) end
  -- Two eggs max per attempt, as in original; one source owns each pending ID.
  local ids={}
  for _,e in ipairs(Active:GetChildren()) do
   if eggName(e)==r.name and tracked[e.Name] and not tracked[e.Name].final then table.insert(ids,e.Name) end
  end
  table.sort(ids,function(a,b) return a==requestId and b~=requestId end)
  local count=0
  for _,c in ipairs(selected) do
   if count>=2 or not alive() then break end
   local id=ids[count+1]
   if id and not pending[id] and press(c.button) then
    pending[id]={source=source,at=os.clock()}
    attempted[id]=true
    count=count+1
   end
   task.wait(.25)
  end
  if count==0 then error('กดปุ่ม Open ไม่สำเร็จ') end
  local start=os.clock()
  while alive() and os.clock()-start<12 do
   for id,p in pairs(pending) do
    if p.source==source and tracked[id] then confirmed(tracked[id],source) end
   end
   task.wait(.7)
  end
  for id,p in pairs(pending) do if p.source==source then pending[id]=nil end end
 end)
 -- Always restore the five switches after a complete initial toggle, even on error.
 -- If the first toggle was partial, never blindly toggle again.
 if alive() then restoreEvents(changed) end
 if not ok then warn('EggMonitor collect: '..tostring(err)) end
 busy=false
 return ok
end

-- Telegram commands and callback buttons: poll sparingly, never block scan loop.
local polling=false
local function processUpdates(obj)
 polling=false
 if not alive() or not obj then return end
 for _,u in ipairs(obj.result or {}) do
  offset=math.max(offset,u.update_id+1)
  local m=u.message
  if m and m.chat and tostring(m.chat.id)==tostring(CHAT) then
   local cmd=tostring(m.text or ''):lower():match('^%s*(.-)%s*$')
   if cmd=='auto' then
    env.RideEggAuto=true
    send('🤖 เปิด AUTO สำรองแล้ว: รอ 1 นาทีก่อนเช้า และเก็บเฉพาะไข่ที่ยังเหลือ')
   elseif cmd=='stop' then
    env.RideEggAuto=false
    send('🛑 ปิด AUTO สำรองแล้ว ระบบหลักและปุ่ม Telegram ยังทำงาน')
   end
  end
  local cb=u.callback_query
  if cb then
   enqueue('answerCallbackQuery',{callback_query_id=cb.id,text='รับคำสั่งแล้ว'},nil,true)
   if cb.message and cb.message.chat and tostring(cb.message.chat.id)==tostring(CHAT) and type(cb.data)=='string' and cb.data:sub(1,1)=='C' then
    local id=cb.data:sub(2)
    task.spawn(collect,id,'telegram')
   end
  end
 end
end
task.spawn(function()
 -- Ignore old updates from before this run.
 local initialized=false
 while alive() do
  if not polling then
   polling=true
   local data={timeout=0,limit=50,allowed_updates={'message','callback_query'}}
   if initialized then data.offset=offset end
   local queued=enqueue('getUpdates',data,function(obj)
    if not initialized and obj then
     for _,u in ipairs(obj.result or {}) do offset=math.max(offset,u.update_id+1) end
     initialized=true;polling=false
    else processUpdates(obj) end
   end)
   if not queued then polling=false end
  end
  task.wait(7)
 end
end)

-- One scan per second; never performs HTTP or deep GUI traversal.
task.spawn(function()
 send('🟢 Ride A Pet Egg Monitor เริ่มทำงาน')
 while alive() do
  if env.EggMonitorEnabled then
   local phase,seconds=readTime()
   local present={}
   for _,e in ipairs(Active:GetChildren()) do
    local name=eggName(e)
    if EGGS[name] then
     local id=e.Name;present[id]=true
     if not tracked[id] then
      local r={id=id,name=name,state='active',cycle=cycle}
      tracked[id]=r
      task.spawn(announce,e,r)
     end
    end
   end
   if lastPhase and phase and phase~=lastPhase then
    if lastPhase=='NIGHT' and phase=='DAY' then
     cycle=cycle+1
     for id,r in pairs(tracked) do
      if not r.final and not present[id] then
       if inBasket(r.name) then finish(r,pending[id] and pending[id].source or 'chilli')
       else finish(r,'reset') end
      end
     end
    end
    warned={DAY=false,NIGHT=false};attempted={};autoWindow=false
   elseif lastSeconds and seconds and seconds>lastSeconds+60 and phase then
    warned[phase]=false
   end
   if phase then lastPhase=phase;lastSeconds=seconds end
   if phase and seconds and seconds<=60 and not warned[phase] then
    local hasEgg=false
    for id,r in pairs(tracked) do if not r.final and present[id] then hasEgg=true;break end end
    if hasEgg then
     warned[phase]=true
     send(phase=='NIGHT' and '☀️ อีก 1 นาที จะเข้าสู่ตอนเช้า' or '🌙 อีก 1 นาที จะเข้าสู่กลางคืน')
    end
   end
   -- AUTO is the fallback. Wait until <=25s to give Chilli/Telegram first chance.
   -- If Chilli is actively collecting, it may still race; game exposes no reliable busy signal here.
   local window=(phase=='NIGHT' and seconds and seconds<=60)
   if window and not autoWindow then attempted={} end
   autoWindow=not not window
   if window and seconds<=25 and seconds>9 and env.RideEggAuto and not busy then
    for id,r in pairs(tracked) do
     if not r.final and present[id] and not pending[id] and not attempted[id] then
      attempted[id]=true
      task.spawn(collect,id,'auto')
      break
     end
    end
   end
   for id,r in pairs(tracked) do
    if not r.final then
     if present[id] then
      if inBasket(r.name) then finish(r,pending[id] and pending[id].source or 'chilli') end
     else
      if not r.missingAt then r.missingAt=os.clock() end
      if inBasket(r.name) then
       finish(r,pending[id] and pending[id].source or 'chilli')
      elseif phase=='NIGHT' and seconds and seconds<=60 then
       -- Never classify as collected during dawn reset window.
      elseif os.clock()-r.missingAt>15 then
       -- Not enough evidence to call Chilli successful. Wait for sunrise if possible.
       if phase=='DAY' and r.cycle<cycle then finish(r,'reset')
       elseif not r.warned then r.warned=true;send('⚠️ '..r.name..' หายจากข้อมูล ยังยืนยันการเก็บไม่ได้') end
      end
     end
    end
   end
  end
  task.wait(1)
 end
 if dragConnection then dragConnection:Disconnect() end
 if gui.Parent then gui:Destroy() end
end)
