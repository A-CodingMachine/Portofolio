--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SRun = game:GetService("RunService")

--Modules
local AnimationLoader = require(RStorage.QOL.AnimationLoader)
local HitDetector = require(RStorage.QOL.HitDetector)

--Var
local LPlayer = SPlayer.LocalPlayer
local Character = LPlayer.Character

--Events
local AttackEvent = RStorage.Remotes.AttackRemote

--Animations
local Attack = AnimationLoader.ReturnAnimation(AnimationLoader.Animations[LPlayer.Weapon.Value].Attack, Character.Humanoid.Animator)

--Settings
local LastAttack = tick() - 3

local M1Module = {}

function M1Module.Attack()
	if not (tick() - LastAttack > Attack.Length + 0.2) then return end
	LastAttack = tick()
	
	Attack:Play()

	RStorage.Remotes.ReplicationEvent:FireServer(true)

	local Hit = nil
	local T = tick()
	while tick() - T < Attack.Length - 0.1 do

		Hit = HitDetector.DetectObject(Character.HumanoidRootPart.CFrame, Character, "Balloon", Vector3.new(10,10,10), true, true)

		if Hit then
			break
		end

		task.wait()
	end

	Attack.Stopped:Wait()


	RStorage.Remotes.ReplicationEvent:FireServer(false)


	if Hit then
		AttackEvent:FireServer(Hit)
	end
end

return M1Module
