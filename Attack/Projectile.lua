--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SRun = game:GetService("RunService")

--Modules
local FastCast = require(RStorage.QOL.FastCastRedux)
local Peripherals = require("./Peripherals")
local AnimationLoader = require(RStorage.QOL.AnimationLoader)

--Var
local LPlayer = SPlayer.LocalPlayer
local Character = LPlayer.Character


--Animations
local Throw = AnimationLoader.ReturnAnimation(AnimationLoader.Animations[LPlayer.Weapon.Value].Throw, Character.Humanoid.Animator)


--FastCastSettings
local Caster = FastCast.new()
local Behavior = FastCast.newBehavior()

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude
Params.FilterDescendantsInstances = {LPlayer.Character}

Behavior.RaycastParams = Params
Behavior.Acceleration = Vector3.new(0,-50,0)
Behavior.CosmeticBulletTemplate = RStorage.Bullet
Behavior.CosmeticBulletContainer = workspace

local Main = {}
--Settings
Main._HoldLength = 0
Main.Direction = nil
Main.TrajectoryConnection = nil
Main.LastProjectile = tick() - 10
Main.ProjectileCooldown = 2

function Main.CreateProjectile(StartPosition, Dir, Velocity, Object, Creator)
	if Creator == LPlayer then print('Same as chaaracter'); return end
	Caster = FastCast.new()
	Behavior = FastCast.newBehavior()

	Behavior.CosmeticBulletTemplate = Object
	Behavior.CosmeticBulletContainer = workspace
	Behavior.Acceleration = Vector3.new(0,-50,0)


	local Bullet = nil
	local PreviousPoint = StartPosition

	Caster:Fire(StartPosition, Dir,Velocity, Behavior)


	Caster.LengthChanged:Connect(function(casterThatFired, lastPoint, rayDir, displacement, segmentVelocity, cosmeticBulletObject)
		cosmeticBulletObject.PrimaryPart.CFrame = CFrame.lookAt(lastPoint + (rayDir * displacement), 
			lastPoint + (rayDir * displacement) + (lastPoint + (rayDir * displacement) - PreviousPoint) )
		PreviousPoint = lastPoint + (rayDir * displacement)

		--You can see how the projectile moves with this block of code
		--workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		--workspace.CurrentCamera.CFrame = CFrame.lookAt(lastPoint + (rayDir * displacement) + Vector3.new(-4,0,0), lastPoint + (rayDir * displacement))


		if not Bullet then Bullet = cosmeticBulletObject end
	end)
	Caster.RayHit:Connect(function( casterThatFired,  result,  segmentVelocity,  cosmeticBulletObject)
		print(result)
	end)

	Caster.CastTerminating:Connect(function()
		print("Cast Terminating")
		Bullet:Destroy()
	end)
end


function Main.Projectile(isMobile, UpdateProjectileTrajectory)  --Can't require script 
	if not (tick() - Main.LastProjectile > Main.ProjectileCooldown + 0.5) then return end 
	Main._HoldLength = tick()

	if Main.TrajectoryConnection then 
		Main.TrajectoryConnection:Disconnect(); Main.TrajectoryConnection = nil

		for i,v in workspace.TrajectoryPartsFolder:GetChildren() do
			if v:IsA("BasePart") then v:Destroy() end
		end
	end	
	
	Main.Direction = nil
	Main.TrajectoryConnection = SRun.Heartbeat:Connect(function()	
		if isMobile then Main.Direction = UpdateProjectileTrajectory() or Main.Direction end
		
		Peripherals.ShowExpectedTrajectory(Vector3.new(0,-50,0), 15 + math.clamp(tick() - Main._HoldLength, 0, 1.5)/1.5 * 70, Main.Direction)
	end)
	
end

function Main.FireProjectile()
	if not Main.TrajectoryConnection then return end
	Throw:Play()
	task.wait(Throw.Length - 0.1)
	
	Main.LastProjectile = tick()
	Main.TrajectoryConnection:Disconnect(); Main.TrajectoryConnection = nil

	for i,v in workspace.TrajectoryPartsFolder:GetChildren() do
		if v:IsA("BasePart") then v:Destroy() end
	end


	local Mouse = LPlayer:GetMouse().Hit.Position
	local Dir = Main.Direction or (Mouse - Character["Right Arm"].Projectile.WorldPosition).Unit

	task.spawn(Main.CreateProjectile, Character["Right Arm"].Projectile.WorldPosition, Dir, 15 + math.clamp(tick()-Main._HoldLength, 0, 1.5)/1.5 * 70, RStorage.Bullet)

	RStorage.Remotes.ShootRemote:FireServer(math.clamp(tick()-Main._HoldLength, 0, 1.5), LPlayer:GetMouse().Hit.Position)
end

return Main
