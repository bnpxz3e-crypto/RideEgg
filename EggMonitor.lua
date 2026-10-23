-- Ride A Pet | Telegram + Egg Collect
local TOKEN = "8828641953:AAHP58nmC9bklzUxhRmHiU0hEslHvPp2cRk"
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
