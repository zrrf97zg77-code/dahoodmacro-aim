--!strict
-- Speed Glitch Macro - Velocity Push Method
-- Looks legit: requires Greet animation + forward movement, has ramp-up

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
	GlitchSpeed = 34,         -- target speed
	RampUpTime = 0.4,         -- seconds to reach full speed (looks natural)
	RequireGreet = true,      -- must play Greet animation
	RequireForward = true,    -- must be moving forward
	GreetAnimName = "Greet",
}

-- ============================================================
-- STATE
-- ============================================================
local speedGlitchOn = false
local currentSpeed = 16
local rampProgress = 0

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart

LocalPlayer.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid") :: Humanoid
	root = char:WaitForChild("HumanoidRootPart") :: BasePart
end)

-- ============================================================
-- GREET CHECK
-- ============================================================
local function isGreetPlaying(): boolean
	local animator = character:FindFirstChildOfClass("Animator")
	if not animator then return false end
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation and track.Animation.Name == CONFIG.GreetAnimName then
			return true
		end
	end
	return false
end

-- ============================================================
-- CONDITIONS
-- ============================================================
local function conditionsMet(): boolean
	if CONFIG.RequireGreet and not isGreetPlaying() then
		return false
	end
	if CONFIG.RequireForward then
		if humanoid.MoveDirection.Magnitude < 0.1 then
			return false
		end
	end
	return true
end

-- ============================================================
-- MAIN LOOP - velocity push with smooth ramp
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
	if not humanoid or humanoid.Health <= 0 then return end

	local active = speedGlitchOn and conditionsMet()

	-- Ramp up / down smoothly (looks natural, avoids anti-cheat spikes)
	if active then
		rampProgress = math.min(1, rampProgress + dt / CONFIG.RampUpTime)
	else
		rampProgress = math.max(0, rampProgress - dt / CONFIG.RampUpTime)
	end

	currentSpeed = 16 + (CONFIG.GlitchSpeed - 16) * rampProgress

	-- Keep WalkSpeed realistic (server won't flag a small value)
	humanoid.WalkSpeed = math.min(currentSpeed, 22)

	-- Apply velocity push (this is what actually moves you fast)
	if rampProgress > 0.05 then
		local moveDir = humanoid.MoveDirection
		if moveDir.Magnitude > 0.1 then
			local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
			root.AssemblyLinearVelocity = Vector3.new(
				horizontal.X * currentSpeed,
				root.AssemblyLinearVelocity.Y,
				horizontal.Z * currentSpeed
			)
		end
	end
end)
