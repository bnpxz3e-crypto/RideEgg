getgenv().CherubTelegramToken = "8455689997:AAHwzIdo53Eo4v1IdaONYYkUhR8yGylUaCI"
getgenv().CherubTelegramChat = "1813392489"
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local VIM = game:GetService('VirtualInputManager')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
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
-- Chilli-inspired compact panel; all controls belong to our own GUI.
local gui=Instance.new('ScreenGui')
gui.Name='CherubComboPanel';gui.ResetOnSpawn=false;gui.DisplayOrder=995;gui.Parent=pg
local function corner(o,r) Instance.new('UICorner',o).CornerRadius=UDim.new(0,r or 3) end
local frame=Instance.new('Frame')
frame.Name='MainPanel'
frame.Size=UDim2.fromOffset(365,350)
frame.Position=UDim2.new(.5,-182,.25,0)
frame.BackgroundColor3=Color3.fromRGB(13,17,21)
frame.BorderSizePixel=0;frame.Active=true;frame.Draggable=true;frame.Parent=gui
local border=Instance.new('UIStroke',frame)
border.Color=Color3.fromRGB(65,67,69);border.Thickness=2
local header=Instance.new('Frame')
header.Size=UDim2.new(1,0,0,45);header.BackgroundColor3=Color3.fromRGB(218,42,29)
header.BorderSizePixel=0;header.Parent=frame
local hgrad=Instance.new('UIGradient',header)
hgrad.Color=ColorSequence.new(Color3.fromRGB(255,84,63),Color3.fromRGB(166,13,11))
hgrad.Rotation=90
local title=Instance.new('TextLabel')
title.Size=UDim2.new(1,-105,1,0);title.Position=UDim2.fromOffset(14,0)
title.BackgroundTransparency=1;title.Text='👼 Cherub Hub';title.TextColor3=Color3.new(1,1,1)
title.TextStrokeTransparency=.25;title.Font=Enum.Font.GothamBlack;title.TextSize=22
title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=header
local function btn(txt,x,y,w,h,color,parent)
 local b=Instance.new('TextButton');b.Text=txt;b.Size=UDim2.fromOffset(w,h);b.Position=UDim2.fromOffset(x,y)
 b.BackgroundColor3=color;b.BorderSizePixel=0;b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold;b.TextSize=15;b.Parent=parent or frame
 local stroke=Instance.new('UIStroke',b);stroke.Thickness=1.5;stroke.Color=Color3.fromRGB(80,85,92)
 return b
end
local close=btn('X',324,6,34,32,Color3.fromRGB(178,39,30),header)
local mini=btn('−',285,6,34,32,Color3.fromRGB(62,67,73),header)
local function label(text,y,h,size)
 local v=Instance.new('TextLabel');v.Size=UDim2.new(1,-24,0,h);v.Position=UDim2.fromOffset(12,y)
 v.BackgroundTransparency=1;v.Text=text;v.TextSize=size or 15;v.TextColor3=Color3.fromRGB(232,238,246)
 v.Font=Enum.Font.GothamBold;v.TextWrapped=true;v.TextXAlignment=Enum.TextXAlignment.Left
 v.Parent=frame;return v
end
local section=label('⌄  Farm Status',51,28,19)
section.TextColor3=Color3.fromRGB(184,217,250)
local status=label('พร้อมใช้งาน • ปิด Chilli Auto Collect ก่อนเปิด Route',85,49,14)
status.TextYAlignment=Enum.TextYAlignment.Center
status.BackgroundTransparency=.3;status.BackgroundColor3=Color3.fromRGB(26,31,35)
local routeHeading=label('⌄  Cherub Egg Route',139,28,19)
routeHeading.TextColor3=Color3.fromRGB(184,217,250)
local routeBtn=btn('',12,170,341,38,Color3.fromRGB(22,24,27))
local function makeSlideSwitch(row, caption)
 row.Text=''
 local name=Instance.new('TextLabel')
 name.BackgroundTransparency=1;name.Position=UDim2.fromOffset(12,0)
 name.Size=UDim2.new(1,-91,1,0);name.Text=caption
 name.TextColor3=Color3.new(1,1,1);name.TextStrokeTransparency=.25
 name.Font=Enum.Font.GothamBold;name.TextSize=16
 name.TextXAlignment=Enum.TextXAlignment.Left;name.Parent=row
 local track=Instance.new('Frame')
 track.Name='SwitchTrack';track.Size=UDim2.fromOffset(62,27)
 track.Position=UDim2.new(1,-68,.5,-13)
 track.BackgroundColor3=Color3.fromRGB(28,29,29)
 track.BorderSizePixel=0;track.Parent=row
 local outline=Instance.new('UIStroke',track)
 outline.Color=Color3.fromRGB(0,0,0);outline.Thickness=2
 local knob=Instance.new('Frame')
 knob.Name='Knob';knob.Size=UDim2.fromOffset(22,21)
 knob.Position=UDim2.fromOffset(3,3)
 knob.BackgroundColor3=Color3.fromRGB(245,245,245)
 knob.BorderSizePixel=0;knob.Parent=track
 local edge=Instance.new('UIStroke',knob)
 edge.Color=Color3.fromRGB(8,8,8);edge.Thickness=1.5
 local function update(on)
  TweenService:Create(track,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
   BackgroundColor3=on and Color3.fromRGB(16,182,39) or Color3.fromRGB(28,29,29)
  }):Play()
  TweenService:Create(knob,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
   Position=on and UDim2.fromOffset(37,3) or UDim2.fromOffset(3,3)
  }):Play()
 end
 return update
end
local updateRouteSwitch=makeSlideSwitch(routeBtn,'Cherub Egg Route')
local speedLabel=label('ความเร็วบิน (studs/s)',214,26,14)
local speedBox=Instance.new('TextBox')
speedBox.Size=UDim2.fromOffset(100,30);speedBox.Position=UDim2.fromOffset(250,212)
speedBox.Text='250';speedBox.PlaceholderText='50-1000';speedBox.TextSize=17;speedBox.ClearTextOnFocus=false
speedBox.TextColor3=Color3.new(1,1,1);speedBox.BackgroundColor3=Color3.fromRGB(49,55,62)
speedBox.Parent=frame
local speedStroke=Instance.new('UIStroke',speedBox);speedStroke.Color=Color3.fromRGB(100,110,120)
local monitorHeading=label('⌄  Egg Notifications',250,27,19)
monitorHeading.TextColor3=Color3.fromRGB(184,217,250)
local monitorBtn=btn('',12,279,341,38,Color3.fromRGB(22,24,27))
local updateMonitorSwitch=makeSlideSwitch(monitorBtn,'Egg Monitor')
local hint=label('จุด 4 ไม่มี E: ตรวจจุด 1 ใหม่ • กลับบ้านเมื่อมี E',322,24,11)
hint.TextColor3=Color3.fromRGB(165,174,188)
-- Independent launcher remains visible when the large panel is hidden.
local launcher=Instance.new('TextButton')
launcher.Name='OpenCherubHub';launcher.Size=UDim2.fromOffset(68,68)
launcher.Position=UDim2.new(.08,0,.28,0)
launcher.BackgroundColor3=Color3.fromRGB(24,36,51)
launcher.Text='👼';launcher.TextSize=36;launcher.TextColor3=Color3.new(1,1,1)
launcher.BorderSizePixel=0;launcher.Active=true;launcher.Parent=gui
Instance.new('UICorner',launcher).CornerRadius=UDim.new(1,0)
local ls=Instance.new('UIStroke',launcher);ls.Thickness=3;ls.Color=Color3.fromRGB(69,173,246)
-- Move the launcher without opening the panel when dragged.
local dragStart,launcherStart,dragging,moved=nil,nil,false,false
launcher.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true;dragStart=input.Position;launcherStart=launcher.Position;moved=false
 end
end)
launcher.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
local dragConnection=UIS.InputChanged:Connect(function(input)
 if dragging and dragStart and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=input.Position-dragStart
  if delta.Magnitude>8 then moved=true end
  launcher.Position=UDim2.new(launcherStart.X.Scale,launcherStart.X.Offset+delta.X,launcherStart.Y.Scale,launcherStart.Y.Offset+delta.Y)
 end
end)
launcher.Activated:Connect(function()
 if moved then moved=false;return end
 frame.Visible=not frame.Visible
end)

-- The uploaded Route is used as-is for flight, equipment, camera, E and station order.
-- Only its original panel and start button are replaced with this shared UI adapter.
local function setupOriginalRoute(status,gui)
-- Ride A Pet | Cherub Egg one-button route (Delta)
-- Skip points 1-3 if no nearby E ProximityPrompt; equip Cherub Egg only when prompt exists.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local VIM = game:GetService('VirtualInputManager')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local env = (getgenv and getgenv()) or _G
env.CherubRouteGeneration = (env.CherubRouteGeneration or 0) + 1
local generation = env.CherubRouteGeneration
local function alive() return env.CherubRouteGeneration == generation end
local DEST = {
    {label='จุดเริ่มต้น', pos=Vector3.new(-484.85,42429.79,907.94)},
    {label='จุดที่ 1', pos=Vector3.new(-459.16,42430.86,879.43), hold=3, equip=true},
    {label='จุดที่ 2', pos=Vector3.new(-516.71,42431.29,927.74), hold=3, equip=true},
    {label='จุดที่ 3', pos=Vector3.new(-539.43,42432.33,848.25), hold=3, equip=true},
    {label='จุดที่ 4', pos=Vector3.new(-496.58,42430.93,893.82), hold=2},
    {label='บ้าน', pos=Vector3.new(174.74,40316.42,1061.15)},
}
-- Exact camera CFrames measured by the player at each station.
local CAMERA_POINTS = {
 [1]=CFrame.new(-471.368866,42436.234375,907.315430)*CFrame.fromOrientation(-0.16520408,-0.11923753,0),
 [2]=CFrame.new(-490.110229,42437.496094,922.611450)*CFrame.fromOrientation(-0.19392118,1.49393189,0),
 [3]=CFrame.new(-519.581116,42439.113281,866.312988)*CFrame.fromOrientation(-0.20994413,0.72658545,0),
 [4]=CFrame.new(-481.348175,42436.113281,918.115417)*CFrame.fromOrientation(-0.15176621,0.58706641,0),
}
local SPEED=250
-- UI is supplied by the shared Cherub Hub panel.
local routeEvent=Instance.new('BindableEvent')
local start={Activated=routeEvent.Event,Text=''}
-- status and gui are passed from the shared UI.
local working=false
local actionSerial=0
local routeOutcome='idle' -- idle / running / retry / home / error
local retryFromPoint1=false
local held=false
local cameraLock=false
local savedCameraType=nil
local savedCameraSubject=nil
local cameraConn=nil
local function unlockCamera()
 cameraLock=false
 if cameraConn then cameraConn:Disconnect();cameraConn=nil end
 local cam=workspace.CurrentCamera
 if cam then
  cam.CameraType=savedCameraType or Enum.CameraType.Custom
  if savedCameraSubject then cam.CameraSubject=savedCameraSubject end
 end
 savedCameraType=nil;savedCameraSubject=nil
end
local function lockCameraAt(index)
 local cam=workspace.CurrentCamera
 if not cam or not CAMERA_POINTS[index] then return end
 if not cameraLock then
  savedCameraType=cam.CameraType
  savedCameraSubject=cam.CameraSubject
 end
 cameraLock=true
 cam.CameraType=Enum.CameraType.Scriptable
 if cameraConn then cameraConn:Disconnect();cameraConn=nil end
 local target=CAMERA_POINTS[index]
 cam.CFrame=target
 cameraConn=RunService.RenderStepped:Connect(function()
  if cameraLock and alive() and workspace.CurrentCamera==cam then
   cam.CFrame=target
  end
 end)
end
local function releaseE()
 if held then pcall(function() VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game) end);held=false end
end
local function stop()
 working=false
 actionSerial=actionSerial+1
 releaseE()
 unlockCamera()
end
-- Shared panel handles close/cleanup.
local function rootPart()
 local ch=player.Character
 return ch and ch:FindFirstChild('HumanoidRootPart')
end
local function fly(target,label)
 local root=rootPart()
 if not root then return false,'ไม่พบตัวละคร' end
 local stuck=0;local last=math.huge
 while working and alive() do
  local dt=RunService.Heartbeat:Wait()
  if not root.Parent then return false,'ตัวละครหายไป' end
  local delta=target-root.Position
  local dist=delta.Magnitude
  if dist<=4 then return true end
  local step=math.min(SPEED*math.min(dt,.12),dist)
  root.AssemblyLinearVelocity=Vector3.zero
  root.CFrame=CFrame.new(root.Position+delta.Unit*step)
  if dist>=last-.15 then stuck=stuck+dt else stuck=0 end
  last=dist
  status.Text=string.format('🚀 %s • เหลือ %.0f studs',label,dist)
  if stuck>4 then return false,'ตำแหน่งถูกดึงกลับ/ติดขัด' end
 end
 return false,'หยุดแล้ว'
end

-- NEW: Equip only one Cherub Egg from Backpack, without opening inventory UI.
local function equipCherub(label)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local backpack=player:FindFirstChildOfClass('Backpack')
 if not humanoid or not backpack then return false,'ไม่พบตัวละครหรือ Backpack' end
 -- Do not replace a Cherub Egg that is already equipped.
 for _,tool in ipairs(character:GetChildren()) do
  if tool:IsA('Tool') and tool.Name=='Cherub Egg' then
   status.Text='🥚 '..label..' • ถือ Cherub Egg อยู่แล้ว'
   return true
  end
 end
 local egg
 for _,tool in ipairs(backpack:GetChildren()) do
  if tool:IsA('Tool') and tool.Name=='Cherub Egg' then egg=tool;break end
 end
 if not egg then return false,'ไม่พบ Cherub Egg ใน Backpack' end
 status.Text='🥚 '..label..' • กำลังหยิบ Cherub Egg 1 ใบ'
 local ok,err=pcall(function() humanoid:EquipTool(egg) end)
 if not ok then return false,'หยิบไข่ไม่สำเร็จ: '..tostring(err) end
 local untilTime=os.clock()+2
 while working and alive() and os.clock()<untilTime do
  if egg.Parent==character then
   status.Text='✅ '..label..' • ถือ Cherub Egg ('..tostring(egg:GetAttribute('Weight') or '?')..' KG)'
   return true
  end
  task.wait(.1)
 end
 return false,'สั่งหยิบแล้ว แต่ไข่ยังไม่อยู่ในมือตัวละคร'
end

local function nearbyPrompt(root)
 local best,bestD=nil,math.huge
 -- Run once per interaction, not every frame.
 for _,obj in ipairs(workspace:GetDescendants()) do
  if obj:IsA('ProximityPrompt') and obj.Enabled then
   local par=obj.Parent
   local p=par and (par:IsA('BasePart') and par.Position or (par:IsA('Attachment') and par.WorldPosition))
   if p then
    local d=(p-root.Position).Magnitude
    if d<bestD and d<=math.max(14,obj.MaxActivationDistance+3) then best=obj;bestD=d end
   end
  end
 end
 return best
end
local function interact(point, selectedPrompt)
 local root=rootPart()
 if not root then return false,'ไม่พบตัวละคร' end
 local prompt=selectedPrompt or nearbyPrompt(root)
 local hold=point.hold
 if prompt then
  hold=math.max(hold,prompt.HoldDuration+.6)
  status.Text='🖐 '..point.label..' • กำลังกด E ค้าง'
  local triggered=false
  local conn=prompt.Triggered:Connect(function() triggered=true end)
  if type(fireproximityprompt)=='function' then
   pcall(function() fireproximityprompt(prompt,hold) end)
  else
   pcall(function() VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game);held=true end)
  end
  local t=os.clock()
  while working and alive() and os.clock()-t<hold+.8 and not triggered do task.wait(.1) end
  releaseE();conn:Disconnect()
  if not working or not alive() then return false,'หยุดแล้ว' end
  if triggered or not prompt.Parent or not prompt.Enabled then return true end
  return false,'ยังยืนยันการกด E ไม่ได้'
 else
  status.Text='🖐 '..point.label..' • ลองกด E ค้าง (ไม่พบ ProximityPrompt)'
  local ok=pcall(function() VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game);held=true end)
  if not ok then return false,'กด E ไม่ได้' end
  local t=os.clock()
  while working and alive() and os.clock()-t<hold do task.wait(.1) end
  releaseE()
  return false,'ไม่พบ Prompt เพื่อยืนยันการวาง/เก็บ'
 end
end
start.Activated:Connect(function()
 if working then
  stop(); status.Text='⏹ หยุดแล้ว'; start.Text='🚀 เริ่มทำงาน 1 ปุ่ม'; return
 end
 working=true; routeOutcome='running'; actionSerial=actionSerial+1
 local myAction=actionSerial
 start.Text='⏹ หยุดการทำงาน'
 task.spawn(function()
  for index,point in ipairs(DEST) do
   -- On a missing E at point 4, revisit points 1-4 without staging or home.
   if retryFromPoint1 and index==1 then continue end
   if not working or not alive() or myAction~=actionSerial then break end
   local ok,err=fly(point.pos,point.label)
   if not ok then status.Text='⚠️ '..tostring(err);break end
   local cameraIndex=({['จุดที่ 1']=1,['จุดที่ 2']=2,['จุดที่ 3']=3,['จุดที่ 4']=4})[point.label]
   if cameraIndex then
    lockCameraAt(cameraIndex)
    status.Text='📷 '..point.label..' • ตั้งกล้องตามมุมที่บันทึกไว้'
   end
   if point.equip then
    -- ต้องหยิบไข่ก่อน เกมจึงแสดงปุ่ม E
    ok,err=equipCherub(point.label)
    if not ok then status.Text='⚠️ '..point.label..': '..tostring(err);break end
    local prompt=nil
    local deadline=os.clock()+2.5
    status.Text='🔎 '..point.label..' • รอปุ่ม E หลังหยิบไข่'
    while working and alive() and myAction==actionSerial and os.clock()<deadline do
     local root=rootPart()
     if root then prompt=nearbyPrompt(root) end
     if prompt then break end
     task.wait(.3)
    end
    if not working or not alive() or myAction~=actionSerial then break end
    if not prompt then
     local ch=player.Character
     local hum=ch and ch:FindFirstChildOfClass('Humanoid')
     if hum then pcall(function() hum:UnequipTools() end) end
     status.Text='⏭ '..point.label..' • ไม่พบ Prompt → ข้าม'
     task.wait(.6)
    else
     ok,err=interact(point,prompt)
     if not ok then status.Text='⚠️ '..point.label..': '..tostring(err);break end
     status.Text='✅ '..point.label..' • กด E แล้ว'
     task.wait(.6)
    end
   elseif point.label=='จุดที่ 4' then
    status.Text='📷 จุดที่ 4 • กล้องมุมที่บันทึกไว้'
    task.wait(.4)
    -- Check for an actual nearby E ProximityPrompt BEFORE pressing E.
    -- If none is available, do not press E and do not fly home.
    local point4Prompt=nil
    local checkUntil=os.clock()+2.5
    while working and alive() and myAction==actionSerial and os.clock()<checkUntil do
     local root=rootPart()
     if root then point4Prompt=nearbyPrompt(root) end
     if point4Prompt then break end
     task.wait(.3)
    end
    if not working or not alive() or myAction~=actionSerial then break end
    if not point4Prompt then
     unlockCamera()
     local ch=player.Character
     local hum=ch and ch:FindFirstChildOfClass('Humanoid')
     if hum then pcall(function() hum:UnequipTools() end) end
     routeOutcome='retry'
     retryFromPoint1=true
     status.Text='🔁 จุดที่ 4 ไม่มี E → กลับไปตรวจจุด 1 ใหม่'
     break
    end
    local firstOk,firstErr=interact(point,point4Prompt)
    -- Restore normal camera immediately after first E attempt at point 4.
    unlockCamera()
    if not working or not alive() or myAction~=actionSerial then break end
    for seconds=5,1,-1 do
     if not working or not alive() or myAction~=actionSerial then break end
     status.Text='⏳ จุดที่ 4 • รอ '..seconds..' วินาที ก่อนกดรอบสอง'
     task.wait(1)
    end
    if not working or not alive() or myAction~=actionSerial then break end
    local secondOk,secondErr=interact(point)
    if not working or not alive() or myAction~=actionSerial then break end
    routeOutcome='home'
    retryFromPoint1=false
    if firstOk and secondOk then
     status.Text='✅ จุดที่ 4 • กด E สองรอบแล้ว'
    else
     status.Text='⚠️ จุดที่ 4 • กด E สองรอบแล้ว แต่ยังยืนยันผลไม่ได้'
    end
    task.wait(.6)
   elseif point.label=='บ้าน' then
    status.Text='🏠 กลับถึงบ้านแล้ว'
   else
    status.Text='✅ ถึงจุดเริ่มต้นแล้ว'
   end
  end
  if myAction==actionSerial then
   if routeOutcome=='running' then routeOutcome='error' end
   releaseE();unlockCamera();working=false
   if gui.Parent then start.Text='🚀 เริ่มทำงาน 1 ปุ่ม' end
  end
 end)
end)

return function() routeEvent:Fire() end, function() stop() end, function() return working end, function() return routeOutcome end
end
local routeStart,routeStop,routeWorking,routeResult=setupOriginalRoute(status,gui)
local routeOn=false
local routeSerial=0
routeBtn.Activated:Connect(function()
 if routeOn then
  routeOn=false
  routeSerial=routeSerial+1
  routeStop()
  status.Text='⏹ Route หยุดแล้ว'
  updateRouteSwitch(false)
  return
 end
 routeOn=true
 routeSerial=routeSerial+1
 local serial=routeSerial
 updateRouteSwitch(true)
 task.spawn(function()
  local lap=0
  while routeOn and alive() and serial==routeSerial do
   lap=lap+1
   status.Text='🔁 เริ่ม Cherub Route รอบ '..lap
   routeStart()
   task.wait(.15)
   while routeOn and alive() and serial==routeSerial and routeWorking() do task.wait(.25) end
   if not routeOn or not alive() or serial~=routeSerial then break end
   local result=routeResult()
   if result=='retry' then
    status.Text='🔁 จุดที่ 4 ไม่มี E • เริ่มตรวจจุด 1 ใหม่'
    task.wait(.5)
    -- Do not wait at home: the next pass skips staging and begins at point 1.
    continue
   end
   if result~='home' then break end
   for n=5,1,-1 do
    if not routeOn or not alive() or serial~=routeSerial then break end
    status.Text='⏳ เริ่มรอบใหม่ใน '..n..' วินาที'
    task.wait(1)
   end
  end
  if serial==routeSerial then
   routeOn=false
   routeStop()
   updateRouteSwitch(false)
  end
 end)
end)
mini.Activated:Connect(function() frame.Visible=false end)
-- The speed field remains visible for UI consistency but the uploaded Route
-- has fixed SPEED=250. Do not change its flight logic without authorization.
speedLabel.Text='ความเร็วบินของ Route ต้นฉบับ: 250'
speedBox.Text='250'
speedBox.TextEditable=false
speedBox.FocusLost:Connect(function() speedBox.Text='250' end)
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
 updateMonitorSwitch(env.EggMonitorEnabled)
end)
close.Activated:Connect(function()
 routeOn=false
 routeStop()
 env.EggMonitorEnabled=false
 env.RideEggRun=(env.RideEggRun or 0)+1
 env.CherubComboGen=env.CherubComboGen+1
 env.CherubRouteGeneration=(env.CherubRouteGeneration or 0)+1
 if dragConnection then dragConnection:Disconnect() end
 gui:Destroy()
end)
updateRouteSwitch(false)
updateMonitorSwitch(false)
