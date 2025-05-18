--Services
local SPlayer = game:GetService("Players")
local Module = {}

local function GetPositionAtTime(t: number, origin: Vector3, initialVelocity: Vector3, acceleration: Vector3): Vector3
	local force = Vector3.new((acceleration.X * t^2) / 2,(acceleration.Y * t^2) / 2, (acceleration.Z * t^2) / 2)
	return origin + (initialVelocity * t) + force
end

function Module.ShowExpectedTrajectory(Acceleration, Velocity, Dir)
	-- Get the player and their character
	local player = SPlayer.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local mouse = player:GetMouse()

	local characterPos = character:WaitForChild("HumanoidRootPart").Position
	local mousePos = mouse.Hit.Position  

	local direction = Dir or (mousePos - characterPos).unit
	Velocity = direction * Velocity
	
	
	for i = 1, 30, 1 do
		local Position = GetPositionAtTime(i/10, characterPos, Velocity, Acceleration)
		local Part = nil
		local Interval = # workspace.TrajectoryPartsFolder:GetChildren()
		if Interval > 29 then --Change this when you change the density of parts
			Part = workspace.TrajectoryPartsFolder["Part"..i]
		end
		if not Part then 
			Part = Instance.new("Part")
			Part.Name = "Part"..i
			Part.Parent = workspace.TrajectoryPartsFolder
			Part.Position = Position
			Part.Size = Vector3.new(1,1,1)
			Part.CanCollide = false
			Part.Anchored = true
			Part.Color = Color3.fromRGB(255, 255, 255)
			Part.Material = Enum.Material.Neon
		else
			Part.Position = Position
		end
		
	end
	-- Clean up trajectory points after the flight time
end


return Module
