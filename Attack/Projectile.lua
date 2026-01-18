--// Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SRun = game:GetService("RunService")
local STween = game:GetService("TweenService")

--// Modules
local FastCast = require(RStorage.QOL.FastCastRedux)
local Peripherals = require("./Peripherals")
local AnimationLoader = require(RStorage.QOL.AnimationLoader)
local ProjectileInfo = require(RStorage.Info.ProjectileInfo)
local CameraShaker = require(RStorage.QOL.CameraShaker)

--// Vars
local LPlayer = SPlayer.LocalPlayer
local Character = LPlayer.Character
local Camera = workspace.Camera

--//BodyParts
local torso = Character:WaitForChild("Torso")
local shoulder = torso:WaitForChild("Right Shoulder") 

--// Gui
local ChargeBar = RStorage.GUI.ChargeBar

--// Animations
local Throw = AnimationLoader.ReturnAnimation(
	AnimationLoader.Animations.Pin.Throw,
	Character.Humanoid.Animator
)

--// FastCast Settings
local Caster = FastCast.new()
local Behavior = FastCast.newBehavior()

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude
Params.FilterDescendantsInstances = { LPlayer.Character }

Behavior.RaycastParams = Params
Behavior.Acceleration = Vector3.new(0, -40, 0)
Behavior.CosmeticBulletTemplate = RStorage.KITS.Projectiles.Bullet
Behavior.CosmeticBulletContainer = workspace

--// Main Module
local Main = {}

-- Settings
Main._HoldLength = 0
Main._OriginalC0 = 0
Main._Direction = nil
Main._TrajectoryConnection = nil
Main._LastProjectile = tick() - 10
Main._NewShake = nil
Main._Settings = ProjectileInfo.Default


Main.ProjectileCooldown = 2
Main.MaximumHold = 4
Main.MaxArmRotationAngle = math.rad(230)

--// 

function Main.CreateProjectile(startPos, dir, velocity, object, creator)
	if creator == LPlayer then
		print("Same as character")
		return
	end

	Caster = FastCast.new()
	Behavior = FastCast.newBehavior()

	Behavior.CosmeticBulletTemplate = object
	Behavior.CosmeticBulletContainer = workspace
	Behavior.Acceleration = Vector3.new(0, -90, 0)
	print(velocity)

	local bullet = nil
	local prevPoint = startPos

	Caster:Fire(startPos, dir, velocity, Behavior)

	Caster.LengthChanged:Connect(function(_, lastPoint, rayDir, displacement, _, cosmeticBullet)
		local newPos = lastPoint + (rayDir * displacement)
		
		if not cosmeticBullet then return end
		
		cosmeticBullet.PrimaryPart.CFrame = CFrame.lookAt(
			newPos,
			newPos + (newPos - prevPoint)
		)
		prevPoint = newPos

		if not bullet then
			bullet = cosmeticBullet
		end
	end)
	
	print("Important BUULLET", bullet)

	Caster.RayHit:Connect(function(_, result)
		print(result)
		if bullet then
			bullet:Destroy()
		end
	end)

	Caster.CastTerminating:Connect(function()
		print("Cast Terminating")
		if bullet then
			bullet:Destroy()
		end
	end)
end

function Main.ChargeBar()
	if not Character.HumanoidRootPart:FindFirstChild("ChargeBar") then
		local clone = ChargeBar:Clone()
		clone.Parent = Character.HumanoidRootPart
		clone.Adornee = Character.HumanoidRootPart
	end

	local mainFrame = Character.HumanoidRootPart.ChargeBar.Top
	local y = math.clamp(Main._HoldLength, 0, Main.MaximumHold) / Main.MaximumHold
	local tween = STween:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart),
		{ Size = UDim2.fromScale(1, y) }
	)
	tween:Play()
end

function Main.Projectile(isMobile, updateTrajectory)
	if not (tick() - Main._LastProjectile > Main.ProjectileCooldown + 0.5) then
		return false
	end
	
	--// Starting Shake Procedure
	Main._NewShake = CameraShaker.new(2, function(newcf)
		Camera.CFrame = Camera.CFrame * newcf
	end)
	Main._NewShake:Start()
	Main._NewShake:StartShake(0.5, 12, 1.5)

	if Character:GetAttribute("AbilityEnabled") and ProjectileInfo[LPlayer.Balloon.Value] then
		Main._Settings = ProjectileInfo[LPlayer.Balloon.Value]
	else
		Main._Settings = ProjectileInfo.Default
	end
	
	--// Destroying Trajectory Parts
	if Main._TrajectoryConnection then
		Main._TrajectoryConnection:Disconnect()
		Main._TrajectoryConnection = nil

		for _, v in workspace.TrajectoryPartsFolder:GetChildren() do
			if v:IsA("BasePart") then
				v:Destroy()
			end
		end
	end
	

	--// Creating a new Trajectory Connection
	Main._OriginalC0 = shoulder.C0
	print(Main._OriginalC0)
	
	Main._Direction = nil
	Main._HoldLength = 0
	Main._TrajectoryConnection = SRun.PostSimulation:Connect(function(deltaTime)
		if isMobile then
			Main._Direction = updateTrajectory(deltaTime) or Main._Direction
		end
		
		Main._HoldLength = deltaTime + Main._HoldLength
		local percentage = math.clamp(
			Main._HoldLength,
			0,
			Main.MaximumHold
		) / Main.MaximumHold

		Main.ChargeBar()

		Peripherals.ShowExpectedTrajectory(
			Vector3.new(0, -90, 0),
			15 + percentage * Main._Settings.MaximumVelocity,
			Main._Direction
		)
	end)

	return true
end

function Main.FireProjectile(isMobile)
	if not Main._TrajectoryConnection then
		return
	elseif Main._TrajectoryConnection and isMobile then
		Main._TrajectoryConnection:Disconnect()
	end
	
 --	torso.TemporaryMotor:Destroy()
	--shoulder.Enabled = true
	
	local Bullet = RStorage.KITS.Projectiles.Bullet

	
	Throw:Play()
	task.wait(Throw.Length - 0.1)

	Character.HumanoidRootPart.ChargeBar:Destroy()
	if Main._TrajectoryConnection then
		Main._TrajectoryConnection:Disconnect()
	end
	
	Main._NewShake:Stop()
	Main._LastProjectile = tick()
	Main._TrajectoryConnection = nil

	for _, v in workspace.TrajectoryPartsFolder:GetChildren() do
		if v:IsA("BasePart") then
			v:Destroy()
		end
	end

	local mousePos = LPlayer:GetMouse().Hit.Position
	local dir = Main._Direction or (mousePos - Character["Right Arm"].Projectile.WorldPosition).Unit
	
	if Character:GetAttribute("AbilityEnabled") and LPlayer.Balloon.Value == "Monkey" then
		Bullet = RStorage.KITS.Projectiles.Monkey
	end

	task.spawn(
		Main.CreateProjectile,
		Character["Right Arm"].Projectile.WorldPosition,
		dir,
		15 + math.clamp(Main._HoldLength, 0, 1.5) / 1.5 * Main._Settings.MaximumVelocity,
		Bullet
	)

	RStorage.Remotes.ShootRemote:FireServer(
		math.clamp(Main._HoldLength, 0, 1.5),
		dir
	)
end

function Main.Cleanup()
	if Main._TrajectoryConnection then
		Main._TrajectoryConnection:Disconnect()
	end
	
	if Main._NewShake then Main._NewShake:Stop() end
	Main._LastProjectile = tick()
	Main._TrajectoryConnection = nil

	for _, v in workspace.TrajectoryPartsFolder:GetChildren() do
		if v:IsA("BasePart") then
			v:Destroy()
		end
	end
	
end

return Main
