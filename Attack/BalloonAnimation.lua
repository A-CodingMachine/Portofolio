--Services
local RStorage = game:GetService("ReplicatedStorage")
local SPlayer = game:GetService("Players")
local SRun = game:GetService("RunService")

--Modules
local AnimationLoader = require(RStorage.QOL.AnimationLoader)

--Var
local LPlayer = SPlayer.LocalPlayer
local Character = LPlayer.Character
local Balloon = Character:WaitForChild("Balloon")


local BalloonInformation = {
	["1"] = {Balloon = Balloon:WaitForChild("Left_Balloon"), Anim = AnimationLoader.ReturnAnimation(AnimationLoader.Animations.Balloon.Left, Character.Humanoid.Animator)};
	["2"] = {Balloon = Balloon:WaitForChild("Middle_Balloon"), Anim = AnimationLoader.ReturnAnimation(AnimationLoader.Animations.Balloon.Middle, Character.Humanoid.Animator)};
	["3"] = {Balloon = Balloon:WaitForChild("Right_Balloon"), Anim = AnimationLoader.ReturnAnimation(AnimationLoader.Animations.Balloon.Right, Character.Humanoid.Animator)};
}

local BalloonAnimation = {}

function BalloonAnimation.Damaged()
	task.wait(1)
	for i,v in pairs(BalloonInformation) do
		print(v)
		v.Balloon:FindFirstChildOfClass("MeshPart"):GetAttributeChangedSignal("Health"):Connect(function()
			print("lost health")
			if v.Balloon:FindFirstChildOfClass("MeshPart"):GetAttribute("Health") == 0 then return end

			v.Anim:Play()
		end)
	end
end

return BalloonAnimation
