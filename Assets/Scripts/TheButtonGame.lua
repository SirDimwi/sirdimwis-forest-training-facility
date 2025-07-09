local buttonTimeout = os.clock() - 0.5
local bodyPressRadius = 0.5

-- Button Cooldown
local function canPressButtons() 
	if os.clock() - buttonTimeout >= 0.5 then
		buttonTimeout = os.clock()
		return true
	else
		return false
	end
end

-- fingertip offsets / rotations
fingerTipOffset = Vec3.new(0, 0.2, 0)
fingerTipRotL    = Quat.fromEuler(0,  10,  21)
fingerTipRotR    = Quat.fromEuler(0, -10, -21)

-- formatter: MM:SS.mmm
local function formatTime(t)
    local m  = math.floor(t/60)
    local s  = math.floor(t%60)
    local ms = math.floor((t%1)*1000)
    return string.format("%02d:%02d.%03d", m, s, ms)
end

-- fingertip world-pos helper
local function fingertipPos(handRot, handPos, fingerRot)
    local r   = handRot * fingerRot
    local off = Vec3.rotate(fingerTipOffset, r)
    return handPos + off
end

-- AABB hit-test
local function isPressed(obj)

	-- calculate fingertip positions
    local lp = fingertipPos(LocalPlayer.leftHandRotation,  LocalPlayer.leftHandPosition,  fingerTipRotL)
    local rp = fingertipPos(LocalPlayer.rightHandRotation, LocalPlayer.rightHandPosition, fingerTipRotR)
	
	-- AABB box bounds
    local minB = obj.position - obj.scale * 0.5
    local maxB = obj.position + obj.scale * 0.5
	
    local function inBox(p)
        return p.x >= minB.x and p.x <= maxB.x
           and p.y >= minB.y and p.y <= maxB.y
           and p.z >= minB.z and p.z <= maxB.z
    end
	
    if inBox(lp) or inBox(rp) then
        return true
    end
	
	-- BODY‐SPHERE check
    -- Grab the torso/center point, compute distance to button center
    local bp = LocalPlayer.bodyPosition
    local delta = bp - obj.position
	if delta:length() <= bodyPressRadius then
        return true
    end
	
	
    -- otherwise, not pressed
    return false
end


-- Declerations
local flatStartButton = GameObject.findGameObject("flatStartButton")
local flatTimerText   = GameObject.findGameObject("flatTimerText")
local flatTargets = {
    GameObject.findGameObject("targetButton1"),
    GameObject.findGameObject("targetButton2"),
    GameObject.findGameObject("targetButton3"),
    GameObject.findGameObject("targetButton4"),
    GameObject.findGameObject("targetButton5"),
}

local treeStartButton = GameObject.findGameObject("treeStartButton")
local treeTimerText   = GameObject.findGameObject("treeTimerText")
local treeTargets = {}
for i=1,12 do treeTargets[i] = GameObject.findGameObject("treeButton"..i) end

local tallStartButton = GameObject.findGameObject("tallestTreeStartButton")
local tallTimerText   = GameObject.findGameObject("tallestTreeTimerText")
local tallTargets = {}
for i=1,6 do tallTargets[i] = GameObject.findGameObject("tallestTargetButton"..i) end

local longStartButton = GameObject.findGameObject("longStartButton")
local longTimerText   = GameObject.findGameObject("longTimerText")
local longTargets = {}
for i=1,16 do longTargets[i] = GameObject.findGameObject("longTargetButton"..i) end



-- Sanity Checks
assert(flatStartButton, "flatStartButton not found")
assert(flatTimerText,   "flatTimerText not found")
for i, tb in ipairs(flatTargets) do assert(tb, ("targetButton%d not found"):format(i)) end

assert(treeStartButton, "treeStartButton not found")
assert(treeTimerText,   "treeTimerText not found")
for i, tb in ipairs(treeTargets) do assert(tb, ("treeButton%d not found"):format(i)) end

assert(tallStartButton, "tallestTreeStartButton not found")
assert(tallTimerText,   "tallestTreeTimerText not found")
for i, tb in ipairs(tallTargets) do assert(tb, ("tallestTargetButton%d not found"):format(i)) end

assert(longStartButton, "longStartButton not found")
assert(longTimerText,   "longTimerText not found")
for i, tb in ipairs(longTargets) do assert(tb, ("longTargetButton%d not found"):format(i)) end

-- Set Object States
flatStartButton:setCollision(false)
for _, tb in ipairs(flatTargets) do
    tb:setCollision(false)
    tb:setVisibility(false)
end
local flatStartPressed = false
local flatRunning      = false
local flatStartTime    = 0
local flatPressedTargets = {}

treeStartButton:setCollision(false)
for _, tb in ipairs(treeTargets) do
    tb:setCollision(false)
    tb:setVisibility(false)
end
local treeStartPressed = false
local treeRunning      = false
local treeStartTime    = 0
local treePressedTargets = {}

tallStartButton:setCollision(false)
for _, tb in ipairs(tallTargets) do
    tb:setCollision(false)
    tb:setVisibility(false)
end
local tallStartPressed = false
local tallRunning      = false
local tallStartTime    = 0
local tallPressedTargets = {}

longStartButton:setCollision(false)
for _, tb in ipairs(longTargets) do
    tb:setCollision(false)
    tb:setVisibility(false)
end
local longStartPressed = false
local longRunning      = false
local longStartTime    = 0
local longPressedTargets = {}

-- ---------- Main Loop ----------
function tick(dt)
    if not InRoom or LocalPlayer==nil then return end

    -- Flat Course Logic
    if not flatStartPressed and isPressed(flatStartButton) and canPressButtons() then
        flatStartPressed = true
        flatStartButton:setVisibility(false)
        playSound(0, flatStartButton.position, 1)
        if not flatRunning then
            flatRunning = true
            flatStartTime = os.clock()
            flatTimerText:setText(formatTime(0))
            for i=1,#flatTargets do 
				flatPressedTargets[i]=false; flatTargets[i]:setVisibility(true) 
			end
		else
			flatRunning = false
			for i=1,#flatTargets do
				flatTargets[i]:setVisibility(false)
			end
			for i=1,#flatPressedTargets do
				flatPressedTargets[i] = false
			end
			flatTimerText:setText(formatTime(0))
			flatStartButton:setVisibility(true)
        end
    elseif flatStartPressed and not isPressed(flatStartButton) then
        flatStartPressed = false
        flatStartButton:setVisibility(true)
    end
    if flatRunning then
        for i, tb in ipairs(flatTargets) do
            if not flatPressedTargets[i] and isPressed(tb) then
                flatPressedTargets[i]=true; tb:setVisibility(false); playSound(0, tb.position, 1)
            end
        end
        local now = os.clock() - flatStartTime; flatTimerText:setText(formatTime(now))
        local allPressed = true
        for i=1,#flatTargets do if not flatPressedTargets[i] then allPressed=false break end end
        if allPressed then 
			flatRunning=false
			flatTimerText:setText(formatTime(os.clock()-flatStartTime)) 
			flatStartButton:setVisibility(true)
			flatStartPressed = false
		end
    end

    -- Tree Course Logic
    if not treeStartPressed and isPressed(treeStartButton) and canPressButtons() then
        treeStartPressed = true
        treeStartButton:setVisibility(false)
        playSound(0, treeStartButton.position, 1)
        if not treeRunning then
            treeRunning = true
            treeStartTime = os.clock()
            treeTimerText:setText(formatTime(0))
            for i=1,#treeTargets do treePressedTargets[i]=false; treeTargets[i]:setVisibility(true) end
		else
			treeRunning = false
			for i=1,#treeTargets do
				treeTargets[i]:setVisibility(false)
			end
			for i=1,#treePressedTargets do
				treePressedTargets[i] = false
			end
			treeTimerText:setText(formatTime(0))
			treeStartButton:setVisibility(true)
        end
    elseif treeStartPressed and not isPressed(treeStartButton) then
        treeStartPressed = false
        treeStartButton:setVisibility(true)
    end
    if treeRunning then
        for i, tb in ipairs(treeTargets) do
            if not treePressedTargets[i] and isPressed(tb) then
                treePressedTargets[i]=true; tb:setVisibility(false); playSound(0, tb.position, 1)
            end
        end
        local now = os.clock() - treeStartTime; treeTimerText:setText(formatTime(now))
        local allPressed = true
        for i=1,#treeTargets do if not treePressedTargets[i] then allPressed=false break end end
        if allPressed then 
			treeRunning=false
			treeTimerText:setText(formatTime(os.clock()-treeStartTime))
			treeStartButton:setVisibility(true)
			treeStartPressed = false
		end
    end

    -- Tallest Tree Course Logic
    if not tallStartPressed and isPressed(tallStartButton) and canPressButtons() then
        tallStartPressed = true
        tallStartButton:setVisibility(false)
        playSound(0, tallStartButton.position, 1)
        if not tallRunning then
            tallRunning = true
            tallStartTime = os.clock()
            tallTimerText:setText(formatTime(0))
            for i=1,#tallTargets do tallPressedTargets[i]=false; tallTargets[i]:setVisibility(true) end
		else
			tallRunning = false
			for i=1,#tallTargets do
				tallTargets[i]:setVisibility(false)
			end
			for i=1,#tallPressedTargets do
				tallPressedTargets[i] = false
			end
			tallTimerText:setText(formatTime(0))
			tallStartButton:setVisibility(true)
        end
    elseif tallStartPressed and not isPressed(tallStartButton) then
        tallStartPressed = false
        tallStartButton:setVisibility(true)
    end
    if tallRunning then
        for i, tb in ipairs(tallTargets) do
            if not tallPressedTargets[i] and isPressed(tb) then
                tallPressedTargets[i]=true; tb:setVisibility(false); playSound(0, tb.position, 1)
            end
        end
        local now = os.clock() - tallStartTime; tallTimerText:setText(formatTime(now))
        local allPressed = true
        for i=1,#tallTargets do if not tallPressedTargets[i] then allPressed=false break end end
        if allPressed then
			tallRunning=false
			tallTimerText:setText(formatTime(os.clock()-tallStartTime))
			tallStartButton:setVisibility(true)
			tallStartPressed = false
		end
    end

    -- Long Course Logic
    if not longStartPressed and isPressed(longStartButton) and canPressButtons() then
        longStartPressed = true
        longStartButton:setVisibility(false)
        playSound(0, longStartButton.position, 1)
        if not longRunning then
            longRunning = true
            longStartTime = os.clock()
            longTimerText:setText(formatTime(0))
            for i=1,#longTargets do longPressedTargets[i]=false; longTargets[i]:setVisibility(true) end
		else
			longRunning = false
			for i=1,#longTargets do
				longTargets[i]:setVisibility(false)
			end
			for i=1,#longPressedTargets do
				longPressedTargets[i] = false
			end
			longTimerText:setText(formatTime(0))
			longStartButton:setVisibility(true)
        end
    elseif longStartPressed and not isPressed(longStartButton) then
        longStartPressed = false
        longStartButton:setVisibility(true)
    end
    if longRunning then
        for i, tb in ipairs(longTargets) do
            if not longPressedTargets[i] and isPressed(tb) then
                longPressedTargets[i]=true; tb:setVisibility(false); playSound(0, tb.position, 1)
            end
        end
        local now = os.clock() - longStartTime; longTimerText:setText(formatTime(now))
        local allPressed = true
        for i=1,#longTargets do if not longPressedTargets[i] then allPressed=false break end end
        if allPressed then
			longRunning=false
			longTimerText:setText(formatTime(os.clock()-longStartTime))
			longStartButton:setVisibility(true)
			longStartPressed = false
		end
    end
end