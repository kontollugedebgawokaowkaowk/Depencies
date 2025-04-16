repeat
	task.wait();
until game:IsLoaded() 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")

local Alive = Workspace:FindFirstChild("Alive")
local Aerodynamic = false
local Aerodynamic_Time = tick()
local Last_Input = UserInputService:GetLastInputType()
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Parry_Key = nil
local Remotes = {}
local revertedRemotes = {}
local originalMetatables = {}
local Parries = 0
local Connections_Manager = {}
local Animation = {storage = {}, current = nil, track = nil}

setfpscap(60)


local function isValidRemoteArgs(args)
    return #args == 7 and
           type(args[2]) == "string" and  
           type(args[3]) == "number" and 
           typeof(args[4]) == "CFrame" and 
           type(args[5]) == "table" and  
           type(args[6]) == "table" and 
           type(args[7]) == "boolean"
end
local function hookRemote(remote)
    if not revertedRemotes[remote] then
        if not originalMetatables[getmetatable(remote)] then
            originalMetatables[getmetatable(remote)] = true

            local meta = getrawmetatable(remote)
            setreadonly(meta, false)

            local oldIndex = meta.__index
            meta.__index = function(self, key)
                if (key == "FireServer" and self:IsA("RemoteEvent")) or (key == "InvokeServer" and self:IsA("RemoteFunction")) then
                    return function(_, ...)
                        local args = {...}
                        if isValidRemoteArgs(args) then
                            if not revertedRemotes[self] then
                                revertedRemotes[self] = args
                                
                                -- Copy remote name + args to clipboard
                                local remoteType = self:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction"
                                local remoteData = {
                                    RemoteName = self.Name,
                                    RemoteType = remoteType,
                                    Args = args
                                }
                                setclipboard(game:GetService("HttpService"):JSONEncode(remoteData))
                                
                                print("✅ Remote copied to clipboard!")
                                game.StarterGui:SetCore("SendNotification", {
                                    Title = "StarX",
                                    Text = "Remote copied to clipboard!",
                                    Duration = 5,
                                })
                            end
                        end
                        return oldIndex(self, key)(_, unpack(args))
                    end
                end
                return oldIndex(self, key)
            end

            setreadonly(meta, true)
        end
    end
end

local function restoreRemotes()
    for remote, _ in pairs(revertedRemotes) do
        if originalMetatables[getmetatable(remote)] then
            local meta = getrawmetatable(remote)
            setreadonly(meta, false)
            meta.__index = nil  -- Reset metatable behavior
            setreadonly(meta, true)
        end
    end
    revertedRemotes = {}  -- Clear captured remotes
    print("Remotes restored.")
end

for _, remote in pairs(game.ReplicatedStorage:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        hookRemote(remote)
    end
end

game.ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        hookRemote(child)
    end
end)

local function createAnimation(object, info, value)
	local animation = TweenService:Create(object, info, value);
	animation:Play();
	task.wait(info.Time);
	Debris:AddItem(animation, 0);
	animation:Destroy();
end
for _, animation in pairs(ReplicatedStorage.Misc.Emotes:GetChildren()) do
	if (animation:IsA("Animation") and animation:GetAttribute("EmoteName")) then
		local emoteName = animation:GetAttribute("EmoteName");
		Animation.storage[emoteName] = animation;
	end
end

local Key = Parry_Key;
local Auto_Parry = {};
Auto_Parry.Parry_Animation = function()
	local Parry_Animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry");
	local Current_Sword = LocalPlayer.Character:GetAttribute("CurrentlyEquippedSword");
	if (not Current_Sword or not Parry_Animation) then
		return;
	end
	local Sword_Data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword);
	if (not Sword_Data or not Sword_Data['AnimationType']) then
		return;
	end
	for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do
		if (object.Name == Sword_Data['AnimationType']) then
			local sword_animation_type = (object:FindFirstChild("GrabParry") and "GrabParry") or "Grab";
			Parry_Animation = object[sword_animation_type];
		end
	end
	Grab_Parry = LocalPlayer.Character.Humanoid.Animator:LoadAnimation(Parry_Animation);
	Grab_Parry:Play();
end;
Auto_Parry.Play_Animation = function(animationName)
	local Animations = Animation.storage[animationName];
	if not Animations then
		return false;
	end
	local Animator = LocalPlayer.Character.Humanoid.Animator;
	if (Animation.track and Animation.track:IsA("AnimationTrack")) then
		Animation.track:Stop();
	end
	Animation.track = Animator:LoadAnimation(Animations);
	if (Animation.track and Animation.track:IsA("AnimationTrack")) then
		Animation.track:Play();
	end
	Animation.current = animationName;
end;
Auto_Parry.Get_Balls = function()
	local Balls = {};
	for _, instance in pairs(Workspace.Balls:GetChildren()) do
		if instance:GetAttribute("realBall") then
			instance.CanCollide = false;
			table.insert(Balls, instance);
		end
	end
	return Balls;
end;
Auto_Parry.Get_Ball = function()
	for _, instance in pairs(Workspace.Balls:GetChildren()) do
		if instance:GetAttribute("realBall") then
			instance.CanCollide = false;
			return instance;
		end
	end
end;
Auto_Parry.Parry_Type = "Default" -- Default direction
local Parry_Directions = {
    "Default",    -- Normal camera direction
    "Straight",   -- Forward
    "Backwards",  -- Backward
    "Up",         -- Upward
    "Left",       -- Left
    "Right",      -- Right
    "Random"      -- Random direction
}

-- Modify the Parry_Data function
function Auto_Parry.Parry_Data()
    local Camera = workspace.CurrentCamera
    if not Camera then return {0, CFrame.new(), {}, {0, 0}} end

    if Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard then
        Vector2_Mouse_Location = {UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2}
    end

    -- Direction calculation based on selected type
    local directionCFrame
    if Auto_Parry.Parry_Type == "Straight" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.LookVector * 1000))
    elseif Auto_Parry.Parry_Type == "Backwards" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.LookVector * 1000))
    elseif Auto_Parry.Parry_Type == "Up" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.UpVector * 1000))
    elseif Auto_Parry.Parry_Type == "Left" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.RightVector * 1000))
    elseif Auto_Parry.Parry_Type == "Right" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.RightVector * 1000))
    elseif Auto_Parry.Parry_Type == "Random" then
        directionCFrame = CFrame.new(Camera.CFrame.Position, Vector3.new(
            math.random(-1000, 1000),
            math.random(-1000, 1000),
            math.random(-1000, 1000)
        ))
    else -- "Default"
        directionCFrame = Camera.CFrame
    end

    return {0, directionCFrame, {}, Vector2_Mouse_Location}
end
local FirstParryDone = false
Auto_Parry.Parry = function()
    local Parry_Data = Auto_Parry.Parry_Data()
    
    if not FirstParryDone then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        FirstParryDone = true
    else
        for remote, originalArgs in pairs(revertedRemotes) do
            -- Membuat salinan args dan memodifikasi CFrame (argumen ke-4)
            local modifiedArgs = {
                originalArgs[1],  -- Argumen 1 (int)
                originalArgs[2],  -- Argumen 2 (string)
                originalArgs[3],  -- Argumen 3 (number)
                Parry_Data[2],   -- CFrame baru dari Parry_Data
                originalArgs[5],  -- Argumen 5 (table)
                originalArgs[6],  -- Argumen 6 (table)
                originalArgs[7]   -- Argumen 7 (boolean)
            }
            
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(modifiedArgs))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(modifiedArgs))
            end
        end
    end

    if Parries > 7 then return false end
    Parries += 1
    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end
local Lerp_Radians = 0;
local Last_Warping = tick();
Auto_Parry.Linear_Interpolation = function(a, b, time_volume)
	return a + ((b - a) * time_volume);
end;
local Previous_Velocity = {};
local Curving = tick();
Auto_Parry.Is_Curved = function()
	local Ball = Auto_Parry.Get_Ball();
	if not Ball then
		return false;
	end
	local Zoomies = Ball:FindFirstChild("zoomies");
	if not Zoomies then
		return false;
	end
	local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue();
	local Velocity = Zoomies.VectorVelocity;
	local Ball_Direction = Velocity.Unit;
	local Direction = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Unit;
	local Dot = Direction:Dot(Ball_Direction);
	local Speed = Velocity.Magnitude;
	local Speed_Threshold = math.min(Speed / 100, 40);
	local Angle_Threshold = 40 * math.max(Dot, 0);
	local Direction_Difference = (Ball_Direction - Velocity).Unit;
	local Direction_Similarity = Direction:Dot(Direction_Difference);
	local Dot_Difference = Dot - Direction_Similarity;
	local Dot_Threshold = 0.5 - (Ping / 1000);
	local Distance = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Magnitude;
	local Reach_Time = (Distance / Speed) - (Ping / 1000);
	local Enough_Speed = Speed > 100;
	local Ball_Distance_Threshold = (15 - math.min(Distance / 1000, 15)) + Angle_Threshold + Speed_Threshold;
	table.insert(Previous_Velocity, Velocity);
	if (#Previous_Velocity > 4) then
		table.remove(Previous_Velocity, 1);
	end
	if (Enough_Speed and (Reach_Time > (Ping / 10))) then
		Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15);
	end
	if (Distance < Ball_Distance_Threshold) then
		return false;
	end
	if ((tick() - Curving) < (Reach_Time / 1.5)) then
		return true;
	end
	if (Dot_Difference < Dot_Threshold) then
		return true;
	end
	local Radians = math.asin(Dot);
	Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8);
	if (Lerp_Radians < 0.018) then
		Last_Warping = tick();
	end
	if ((tick() - Last_Warping) < (Reach_Time / 1.5)) then
		return true;
	end
	if (#Previous_Velocity == 4) then
		for i = 1, 2 do
			local Intended_Direction_Difference = (Ball_Direction - Previous_Velocity[i].Unit).Unit;
			local Intended_Dot = Direction:Dot(Intended_Direction_Difference);
			local Intended_Dot_Difference = Dot - Intended_Dot;
			if (Intended_Dot_Difference < Dot_Threshold) then
				return true;
			end
		end
	end
	return Dot < Dot_Threshold;
end;
Auto_Parry.Closest_Player = function()
	local Max_Distance = math.huge;
	Closest_Entity = nil;
	for _, Entity in pairs(Workspace.Alive:GetChildren()) do
		if ((tostring(Entity) ~= tostring(LocalPlayer)) and Entity.PrimaryPart) then
			local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position);
			if (Distance < Max_Distance) then
				Max_Distance = Distance;
				Closest_Entity = Entity;
			end
		end
	end
	return Closest_Entity;
end;
Auto_Parry.Get_Entity_Properties = function(self)
	Auto_Parry.Closest_Player();
	if not Closest_Entity then
		return false;
	end
	local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity;
	local Entity_Direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit;
	local Entity_Distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude;
	return {Velocity=Entity_Velocity,Direction=Entity_Direction,Distance=Entity_Distance};
end;
Auto_Parry.Get_Entity_Properties = function(self)
	Auto_Parry.Closest_Player();
	if not Closest_Entity then
		return false;
	end
	local entityVelocity = Closest_Entity.PrimaryPart.Velocity;
	local entityDirection = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit;
	local entityDistance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude;
	return {Velocity=entityVelocity,Direction=entityDirection,Distance=entityDistance};
end;
Auto_Parry.Get_Ball_Properties = function(self)
	local ball = Auto_Parry.Get_Ball();
	if not ball then
		return false;
	end
	local character = LocalPlayer.Character;
	if (not character or not character.PrimaryPart) then
		return false;
	end
	local ballVelocity = ball.AssemblyLinearVelocity;
	local ballDirection = (character.PrimaryPart.Position - ball.Position).Unit;
	local ballDistance = (character.PrimaryPart.Position - ball.Position).Magnitude;
	local ballDot = ballDirection:Dot(ballVelocity.Unit);
	return {Velocity=ballVelocity,Direction=ballDirection,Distance=ballDistance,Dot=ballDot};
end;
Auto_Parry.Spam_Service = function(self)
	local ball = Auto_Parry.Get_Ball();
	if not ball then
		return false;
	end
	Auto_Parry.Closest_Player();
	local spamDelay = 0;
	local spamAccuracy = 100;
	if not self.Spam_Sensitivity then
		self.Spam_Sensitivity = 50;
	end
	if not self.Ping_Based_Spam then
		self.Ping_Based_Spam = false;
	end
	local velocity = ball.AssemblyLinearVelocity;
	local speed = velocity.Magnitude;
	local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit;
	local dot = direction:Dot(velocity.Unit);
	local targetPosition = Closest_Entity.PrimaryPart.Position;
	local targetDistance = LocalPlayer:DistanceFromCharacter(targetPosition);
	local maximumSpamDistance = self.Ping + math.min(speed / 6.5, 95);
	maximumSpamDistance = maximumSpamDistance * self.Spam_Sensitivity;
	if self.Ping_Based_Spam then
		maximumSpamDistance = maximumSpamDistance + self.Ping;
	end
	if ((self.Entity_Properties.Distance > maximumSpamDistance) or (self.Ball_Properties.Distance > maximumSpamDistance) or (targetDistance > maximumSpamDistance)) then
		return spamAccuracy;
	end
	local maximumSpeed = 5 - math.min(speed / 5, 5);
	local maximumDot = math.clamp(dot, -1, 0) * maximumSpeed;
	spamAccuracy = maximumSpamDistance - maximumDot;
	task.wait(spamDelay);
	return spamAccuracy;
end;
local visualizerEnabled = false;
local function get_character()
	return LocalPlayer and LocalPlayer.Character;
end
local function get_primary_part()
	local char = get_character();
	return char and char.PrimaryPart;
end
local function get_ball()
	local ballContainer = Workspace:FindFirstChild("Balls");
	if ballContainer then
		for _, ball in ipairs(ballContainer:GetChildren()) do
			if not ball.Anchored then
				return ball;
			end
		end
	end
	return nil;
end
local function calculate_visualizer_radius()
	local ball = get_ball();
	if ball then
		local velocity = ball.Velocity.Magnitude;
		return math.clamp((velocity / 2.4) + 10, 15, 200);
	end
	return 15;
end
local visualizer = Instance.new("Part");
visualizer.Shape = Enum.PartType.Ball;
visualizer.Anchored = true;
visualizer.CanCollide = false;
visualizer.Material = Enum.Material.ForceField;
visualizer.Transparency = 0.5;
visualizer.Parent = Workspace;
visualizer.Size = Vector3.new(0, 0, 0);
local function toggle_visualizer(state)
	visualizerEnabled = state;
	if not state then
		visualizer.Size = Vector3.new(0, 0, 0);
	end
end
RunService.RenderStepped:Connect(function()
	if not visualizerEnabled then
		return;
	end
	local primaryPart = get_primary_part();
	local ball = get_ball();
	if (primaryPart and ball) then
		local radius = calculate_visualizer_radius();
		local isHighlighted = primaryPart:FindFirstChild("Highlight");
		visualizer.Size = Vector3.new(radius, radius, radius);
		visualizer.CFrame = primaryPart.CFrame;
		visualizer.Color = isHighlighted and Color3.fromRGB(255, 255, 255);
	else
		visualizer.Size = Vector3.new(0, 0, 0);
	end
end);


function ManualSpam()

    if MauaulSpam then
        MauaulSpam:Destroy()
        MauaulSpam = nil
        return
    end


    MauaulSpam = Instance.new("ScreenGui")
    MauaulSpam.Name = "MauaulSpam"
    MauaulSpam.Parent = game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MauaulSpam.ResetOnSpawn = false


    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = MauaulSpam
    Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0)
    Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0)

    local UICorner = Instance.new("UICorner")
    UICorner.Parent = Main


    local IndercantorBlahblah = Instance.new("Frame")
    IndercantorBlahblah.Name = "IndercantorBlahblah"
    IndercantorBlahblah.Parent = Main
    IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0)
    IndercantorBlahblah.BorderSizePixel = 0
    IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0)
    IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0)

    local UICorner_2 = Instance.new("UICorner")
    UICorner_2.CornerRadius = UDim.new(1, 0)
    UICorner_2.Parent = IndercantorBlahblah

    local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraint.Parent = IndercantorBlahblah


    local PC = Instance.new("TextLabel")
    PC.Name = "PC"
    PC.Parent = Main
    PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PC.BackgroundTransparency = 1
    PC.BorderColor3 = Color3.fromRGB(0, 0, 0)
    PC.BorderSizePixel = 0
    PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0)
    PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0)
    PC.Font = Enum.Font.Unknown
    PC.Text = "PC: E to spam"
    PC.TextColor3 = Color3.fromRGB(57, 57, 57)
    PC.TextScaled = true
    PC.TextSize = 16
    PC.TextWrapped = true

    local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
    UITextSizeConstraint.Parent = PC
    UITextSizeConstraint.MaxTextSize = 16

    local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraint_2.Parent = PC
    UIAspectRatioConstraint_2.AspectRatio = 4.346


    local IndercanotTextBlah = Instance.new("TextButton")
    IndercanotTextBlah.Name = "IndercanotTextBlah"
    IndercanotTextBlah.Parent = Main
    IndercanotTextBlah.Active = false
    IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    IndercanotTextBlah.BackgroundTransparency = 1
    IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0)
    IndercanotTextBlah.BorderSizePixel = 0
    IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0)
    IndercanotTextBlah.Selectable = false
    IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0)
    IndercanotTextBlah.Font = Enum.Font.GothamBold
    IndercanotTextBlah.Text = "Spam"
    IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255)
    IndercanotTextBlah.TextScaled = true
    IndercanotTextBlah.TextSize = 24
    IndercanotTextBlah.TextWrapped = true

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    UIGradient.Parent = IndercanotTextBlah

    local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
    UITextSizeConstraint_2.Parent = IndercanotTextBlah
    UITextSizeConstraint_2.MaxTextSize = 52

    local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraint_3.Parent = IndercanotTextBlah
    UIAspectRatioConstraint_3.AspectRatio = 3.212

    local UIAspectRatioConstraint_4 = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraint_4.Parent = Main
    UIAspectRatioConstraint_4.AspectRatio = 1.667


    local spamConnection
    local toggleManualSpam = false
    local manualSpamSpeed = 15
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local function toggleSpam()
        toggleManualSpam = not toggleManualSpam

        if spamConnection then
            spamConnection:Disconnect()
            spamConnection = nil
        end

        if toggleManualSpam then
            spamConnection = RunService.PreSimulation:Connect(function()
                for _ = 1, manualSpamSpeed do
                    if not toggleManualSpam then
                        break
                    end
                    local success, err = pcall(function()
                        Auto_Parry.Parry()
                    end)
                    if not success then
                        warn("Error in Auto_Parry.Parry:", err)
                    end
                    task.wait()
                end
            end)
        end
    end


    local button = IndercanotTextBlah
    local UIGredient = button.UIGradient
    local NeedToChange = IndercantorBlahblah

    local green_Color = {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }

    local red_Color = {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }

    local current_Color = red_Color
    local target_Color = green_Color
    local is_Green = false
    local transition = false
    local transition_Time = 1
    local start_Time

    local function startColorTransition()
        transition = true
        start_Time = tick()
    end

    RunService.Heartbeat:Connect(function()
        if transition then
            local elapsed = tick() - start_Time
            local alpha = math.clamp(elapsed / transition_Time, 0, 1)
            local new_Color = {}

            for i = 1, #current_Color do
                local start_Color = current_Color[i].Value
                local end_Color = target_Color[i].Value
                new_Color[i] = ColorSequenceKeypoint.new(current_Color[i].Time, start_Color:Lerp(end_Color, alpha))
            end

            UIGredient.Color = ColorSequence.new(new_Color)

            if alpha >= 1 then
                transition = false
                current_Color, target_Color = target_Color, current_Color
            end
        end
    end)

    local function toggleColor()
        if not transition then
            is_Green = not is_Green

            if is_Green then
                target_Color = green_Color
                NeedToChange.BackgroundColor3 = Color3.new(0, 1, 0)
                toggleSpam()
            else
                target_Color = red_Color
                NeedToChange.BackgroundColor3 = Color3.new(1, 0, 0)
                toggleSpam()
            end

            startColorTransition()
        end
    end

    button.MouseButton1Click:Connect(toggleColor)


    local keyConnection
    keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.E then
            toggleColor()
        end
    end)


    MauaulSpam.Destroying:Connect(function()
        if keyConnection then
            keyConnection:Disconnect()
        end
        if spamConnection then
            spamConnection:Disconnect()
        end
    end)


    local gui = Main
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )

        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(gui, tweenInfo, {Position = newPosition})
        tween:Play()
    end

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

ManualSpam()



local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/CodeE4X-dev/Library/refs/heads/main/FluentRemake.lua"))();
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))();
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))();
local Window = Fluent:CreateWindow({
    Title = "Blade Ball - StarX Hub V3 BETA",
    SubTitle = "by CodeE4X",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 500),
    Acrylic = false,
    Theme = "DarkPurple",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({Title = "Main", Icon = "swords"}),
    Abi = Window:AddTab({Title = "Ability", Icon = "zap"}),
    Visual = Window:AddTab({Title = "Visuals", Icon = "eye"}),
    AI = Window:AddTab({Title = "Ai Play", Icon = "bot"}),
    Far = Window:AddTab({Title = "Auto Farm", Icon = "leaf"}),
    Misc = Window:AddTab({Title = "Players", Icon = "box"}),
}
Window:SelectTab(1)




local AutoParry = Tabs.Main:AddToggle("AutoParry", {Title="Auto Parry",Default=true});
AutoParry:OnChanged(function(v)
	if v then
		Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
			local One_Ball = Auto_Parry.Get_Ball();
			local Balls = Auto_Parry.Get_Balls();
			if (not Balls or (#Balls == 0)) then
				return;
			end
			for _, Ball in pairs(Balls) do
				if not Ball then
					return;
				end
				local Zoomies = Ball:FindFirstChild("zoomies");
				if not Zoomies then
					return;
				end
				Ball:GetAttributeChangedSignal("target"):Once(function()
					Parried = false;
				end);
				if Parried then
					return;
				end
				local Ball_Target = Ball:GetAttribute("target");
				local One_Target = One_Ball and One_Ball:GetAttribute("target");
				local Velocity = Zoomies.VectorVelocity;
				local character = LocalPlayer.Character;
				if (not character or not character.PrimaryPart) then
					return;
				end
				local Distance = (character.PrimaryPart.Position - Ball.Position).Magnitude;
				local Speed = Velocity.Magnitude;
				local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10;
				local Parry_Accuracy = (Speed / 3.25) + Ping;
				local Curved = Auto_Parry.Is_Curved();
				if ((Ball_Target == tostring(LocalPlayer)) and Aerodynamic) then
					local Elapsed_Tornado = tick() - Aerodynamic_Time;
					if (Elapsed_Tornado > 0.6) then
						Aerodynamic_Time = tick();
						Aerodynamic = false;
					end
					return;
				end
				if ((One_Target == tostring(LocalPlayer)) and Curved) then
					return;
				end
				if ((Ball_Target == tostring(LocalPlayer)) and (Distance <= Parry_Accuracy)) then
					Auto_Parry.Parry();
					Parried = true;
				end
				local Last_Parrys = tick();
				while (tick() - Last_Parrys) < 1 do
					if not Parried then
						break;
					end
					task.wait();
				end
				Parried = false;
			end
		end);
	elseif Connections_Manager["Auto Parry"] then
		Connections_Manager["Auto Parry"]:Disconnect();
		Connections_Manager["Auto Parry"] = nil;
	end
end);
local AutoSpam = Tabs.Main:AddToggle("AutoSpam", {Title="Auto Spam",Default=true});
local autoSpamCoroutine = nil;
local targetPlayer = nil;
AutoSpam:OnChanged(function(v)
	if v then
		if autoSpamCoroutine then
			coroutine.resume(autoSpamCoroutine, "stop");
			autoSpamCoroutine = nil;
		end
		autoSpamCoroutine = coroutine.create(function(signal)
			while AutoSpam.Value and (signal ~= "stop") do
				local ball = Auto_Parry.Get_Ball();
				if (not ball or not ball:IsDescendantOf(workspace)) then
					task.wait();
					continue;
				end
				local zoomies = ball:FindFirstChild("zoomies");
				if not zoomies then
					task.wait();
					continue;
				end
				Auto_Parry.Closest_Player();
				targetPlayer = Closest_Entity;
				if (not targetPlayer or not targetPlayer.PrimaryPart or not targetPlayer:IsDescendantOf(workspace)) then
					task.wait();
					continue;
				end
				local playerDistance = LocalPlayer:DistanceFromCharacter(ball.Position);
				local targetPosition = targetPlayer.PrimaryPart.Position;
				local targetDistance = LocalPlayer:DistanceFromCharacter(targetPosition);
				if not targetPlayer.Parent then
					task.wait();
					continue;
				end
				if (not ball:IsDescendantOf(workspace) or (ball.Position.Magnitude < 1)) then
					local waitTime = 0;
					repeat
						task.wait(0.1);
						waitTime += 0.1
						ball = Auto_Parry.Get_Ball();
					until (ball and ball:IsDescendantOf(workspace) and (ball.Position.Magnitude > 1)) or (waitTime >= 2.5) 
					continue;
				end
				local ballVelocity = ball.Velocity.Magnitude;
				local ballSpeed = math.max(ballVelocity, 0);
				local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue();
				local pingThreshold = math.clamp(ping / 10, 10, 16);
				local ballProperties = Auto_Parry:Get_Ball_Properties();
				local entityProperties = Auto_Parry:Get_Entity_Properties();
				local spamAccuracy = Auto_Parry.Spam_Service({Ball_Properties=ballProperties,Entity_Properties=entityProperties,Ping=pingThreshold,Spam_Sensitivity=Auto_Parry.Spam_Sensitivity,Ping_Based_Spam=Auto_Parry.Ping_Based_Spam});
				if (zoomies and (zoomies.Parent == ball) and ((playerDistance <= 30) or (targetDistance <= 30)) and (Parries > 1)) then
						Auto_Parry.Parry();
				end
				task.wait();
			end
		end);
		coroutine.resume(autoSpamCoroutine);
	elseif autoSpamCoroutine then
		coroutine.resume(autoSpamCoroutine, "stop");
		autoSpamCoroutine = nil;
	end
end);

local Toggle = Tabs.Main:AddToggle("MyToggle", 
{
    Title = "Manual Spam", 
    Description = "Back up For Auto Spam",
    Default = false,
    Callback = function()
        ManualSpam()
    end 
})

local SpamSensitivitySlider = Tabs.Main:AddSlider("SpamSensitivity", {
    Title = "Spam Sensitivity",
    Description = "Adjust spam responsiveness",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Auto_Parry.Spam_Sensitivity = Value
    end
})


local DirectionDropdown = Tabs.Main:AddDropdown("DirectionDropdown", {
    Title = "Parry Direction",
    Values = Parry_Directions,
    Default = "Default",
    Multi = false,
    Callback = function(Value)
        Auto_Parry.Parry_Type = Value
    end
})

local CurveMethodDropdown = Tabs.Main:AddDropdown("CurveMethod", {
    Title = "Curve Detection Method",
    Values = {"Default", "Predictive", "Direct"},
    Default = "Default",
    Multi = false,
    Callback = function(Value)
        CurveMethod = Value
    end
})

local PredictiveSlider = Tabs.Main:AddSlider("PredictiveSlider", {
    Title = "Predictive Factor",
    Description = "Higher values = more aggressive prediction",
    Default = 50,
    Min = 10,
    Max = 90,
    Rounding = 0,
    Callback = function(Value)
        PredictiveFactor = Value/100
    end
})



local Section = Tabs.Abi:AddSection("Ability Detection")


Tabs.Abi:AddButton({
    Title = "Anti Slash Of Furry",
    Description = "Prevents Slash Of Furry",
    Callback = function()
        print("Anti Slash Of Furry")
    end
})

Tabs.Abi:AddButton({
    Title = "Anti Freeze",
    Description = "Prevents Freeze effect",
    Callback = function()
        print("Anti Freeze")
    end
})

Tabs.Abi:AddButton({
    Title = "Anti Phantom",
    Description = "Prevents Phantom attack",
    Callback = function()
        print("Anti Phantom")
    end
})

Tabs.Abi:AddButton({
    Title = "Anti Infinity",
    Description = "Prevents Infinity effects",
    Callback = function()
        print("Anti Infinity")
    end
})

Tabs.Abi:AddButton({
    Title = "Anti Hell Hooks",
    Description = "Prevents Hell Hooks ability",
    Callback = function()
        print("Anti Hell Hooks")
    end
})

local Section = Tabs.Visual:AddSection("Visual Section")

local originalLightingSettings = {}

local function optimize(state)
    if state then
        -- Save original settings
        local light = game:GetService("Lighting")
        originalLightingSettings = {
            GlobalShadows = light.GlobalShadows,
            FogEnd = light.FogEnd,
            Brightness = light.Brightness,
            OutdoorAmbient = light.OutdoorAmbient,
            EnvironmentDiffuseScale = light.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = light.EnvironmentSpecularScale,
            ShadowSoftness = light.ShadowSoftness
        } 
        local light = game:GetService("Lighting")
        light.GlobalShadows = false
        light.FogEnd = 100000
        light.Brightness = 1
        light.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        light.EnvironmentDiffuseScale = 0
        light.EnvironmentSpecularScale = 0
        light.ShadowSoftness = 1

        -- Terrain
        if game.Workspace:FindFirstChildOfClass("Terrain") then
            local terrain = game.Workspace:FindFirstChildOfClass("Terrain")
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decorations = false
        end

        -- Remove laggy instances
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("Explosion") or
               obj:IsA("Fire") or
               obj:IsA("Smoke") or
               obj:IsA("Sparkles") or
               obj:IsA("Trail") or
               obj:IsA("ParticleEmitter") or
               obj:IsA("Beam") then
                obj:Destroy()
            elseif obj:IsA("Texture") or
                   obj:IsA("Decal") or
                   obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("BlurEffect") or
                   obj:IsA("SunRaysEffect") or
                   obj:IsA("ColorCorrectionEffect") or
                   obj:IsA("BloomEffect") or
                   obj:IsA("DepthOfFieldEffect") then
                obj:Destroy()
            end
        end

        -- Disable Emitters (some may respawn)
        game:GetService("RunService").RenderStepped:Connect(function()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
        end)
        local light = game:GetService("Lighting")
        for setting, value in pairs(originalLightingSettings) do
            pcall(function()
                light[setting] = value
            end)
        end
        print("⚠️ Some settings may require game rejoin to fully restore")
    end
end

local Toggle = Tabs.Visual:AddToggle("MegaLagReducer", {
    Title = "Anti-Lag (Massive)",
    Description = "Disables everything that causes lag. One toggle to clean them all.",
    Default = false,
    Callback = function(state)
        optimize(state)
    end
})



local Section = Tabs.AI:AddSection("AI Play Settings")

-- AI State variables
local AIPlaying = false
local AICoroutine = nil
local AITarget = nil
local AILastActionTime = 0
local AICurrentMethod = "LegitNoob"

local LocalPlayer = game:GetService("Players").LocalPlayer


-- Utility function to safely get players
local function getValidPlayers()
    local players = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local primaryPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart
            if primaryPart and primaryPart.Position then
                table.insert(players, {
                    Player = player,
                    Character = player.Character,
                    PrimaryPart = primaryPart
                })
            end
        end
    end
    return players
end

-- Utility function to safely get ball
local function getSafeBall()
    local success, ball = pcall(function() return Auto_Parry.Get_Ball() end)
    if success and ball and ball.Parent and ball.Position then
        return ball
    end
    return nil
end

-- AI Methods
local AIMethods = {
    LegitNoob = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        local actions = {"Walk", "Jump", "Stand"}
        local action = actions[math.random(1, #actions)]
        
        if action == "Walk" then
            humanoid:MoveTo(primaryPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)))
        elseif action == "Jump" then
            humanoid.Jump = true
        end
    end,
    
    LegitPro = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        if math.random() > 0.5 then
            local targetPos
            
            -- Try to get ball first
            local ball = getSafeBall()
            if ball then
                targetPos = ball.Position
            else
                -- Fallback to players
                local validPlayers = getValidPlayers()
                if #validPlayers > 0 then
                    local target = validPlayers[math.random(1, #validPlayers)]
                    targetPos = target.PrimaryPart.Position
                end
            end
            
            -- Final fallback to random movement
            if targetPos then
                humanoid:MoveTo(targetPos)
            else
                humanoid:MoveTo(primaryPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)))
            end
        else
            humanoid.Jump = true
        end
    end,
    
    LegitEssex = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        if math.random() > 0.7 then
            local validPlayers = getValidPlayers()
            if #validPlayers > 0 then
                local target = validPlayers[math.random(1, #validPlayers)]
                local targetPos = target.PrimaryPart.Position - (target.PrimaryPart.CFrame.LookVector * 2)
                humanoid:MoveTo(targetPos)
            else
                AIMethods.LegitPro(character)
            end
        else
            AIMethods.LegitPro(character)
        end
    end,
    
    BlatantPro = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        if math.random() > 0.3 then
            local validPlayers = getValidPlayers()
            local closestTarget = nil
            local closestDistance = math.huge
            
            for _, target in ipairs(validPlayers) do
                local distance = (primaryPart.Position - target.PrimaryPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestTarget = target
                end
            end
            
            if closestTarget and closestDistance < 15 then
                local targetPos = closestTarget.PrimaryPart.Position + 
                               (closestTarget.PrimaryPart.CFrame.LookVector * 2)
                humanoid:MoveTo(targetPos)
            else
                AIMethods.LegitPro(character)
            end
        else
            AIMethods.LegitPro(character)
        end
    end,
    
    FollowBall = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end
        
        local ball = getSafeBall()
        if ball then
            local direction = (ball.Position - primaryPart.Position).Unit
            local targetPos = ball.Position - (direction * 20)
            humanoid:MoveTo(targetPos)
        else
            AIMethods.LegitPro(character)
        end
    end
}

-- AI Main Loop with robust error handling
local function runAI()
    while AIPlaying do
        local character = LocalPlayer.Character
        if character then
            local success, err = pcall(function()
                if AIMethods[AICurrentMethod] then
                    AIMethods[AICurrentMethod](character)
                end
            end)
            
            if not success then
                warn("AI Error in", AICurrentMethod, ":", err)
                -- Fallback to basic method if error occurs
                AICurrentMethod = "LegitNoob"
            end
        end
        
        -- Random delay with min-max range
        task.wait(math.random(5, 15) / 10)
    end
end

-- AI Toggle
local AIToggle = Tabs.AI:AddToggle("AIToggle", {
    Title = "Enable AI Play",
    Default = false,
    Callback = function(state)
        AIPlaying = state
        
        if AIPlaying then
            if AICoroutine then
                coroutine.resume(AICoroutine, "stop")
            end
            AICoroutine = coroutine.create(runAI)
            coroutine.resume(AICoroutine)
        elseif AICoroutine then
            coroutine.resume(AICoroutine, "stop")
            AICoroutine = nil
        end
    end
})

-- AI Method Dropdown
local AIMethodDropdown = Tabs.AI:AddDropdown("AIMethod", {
    Title = "AI Behavior",
    Values = {"LegitNoob", "LegitPro", "LegitEssex", "BlatantPro", "FollowBall"},
    Default = "LegitNoob",
    Multi = false,
    Callback = function(Value)
        AICurrentMethod = Value
    end
})

-- AI Aggressiveness Slider


-- AI Movement Speed Slider
local AIMovementSpeed = Tabs.AI:AddSlider("AIMovementSpeed", {
    Title = "Movement Speed",
    Description = "How fast the AI moves",
    Default = 32,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value
            end
        end
    end
})



local Section = Tabs.Far:AddSection("Farm Settings")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Direct Variables
local AutoFarm = false
local AutoFarmType = "UnderBall"
local AutoFarmOrbit = 5
local AutoFarmHeight = 10
local AutoFarmRadius = 10
local AutoFarmConnection = nil

-- Ball Functions
local function get_ball()
    local balls = workspace:FindFirstChild("Balls")
    if not balls then return nil end
    
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            return ball
        end
    end
    return nil
end

local function get_humanoid_root_part(player)
    if not player then return nil end
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

-- Auto Farm Logic
local function autofarm()
    local player = Players.LocalPlayer
    local ball = get_ball()
    local rootPart = get_humanoid_root_part(player)
    
    if not ball or not rootPart then return end
    
    local position = ball.Position
    
    if AutoFarmType == "UnderBall" then
        rootPart.CFrame = CFrame.new(position - Vector3.new(0, AutoFarmHeight, 0))
    elseif AutoFarmType == "X Orbit" then
        local angle = tick() * math.pi * 2 / (AutoFarmOrbit / 5)
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * AutoFarmRadius, 
            0, 
            math.sin(angle) * AutoFarmRadius
        ))
    elseif AutoFarmType == "Y Orbit" then
        local angle = tick() * math.pi * 2 / (AutoFarmOrbit / 5)
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            0, 
            math.sin(angle) * AutoFarmRadius, 
            math.cos(angle) * AutoFarmRadius
        ))
    end
end

-- Main Farm Loop
local function startAutoFarm()
    if AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
    
    AutoFarmConnection = RunService.Heartbeat:Connect(function()
        if AutoFarm then
            local success, err = pcall(autofarm)
            if not success then
                warn("AutoFarm Error:", err)
            end
        end
    end)
end

Tabs.Far:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Description = "Automatically farms balls and slaps the ball (requires Auto Parry)",
    Default = AutoFarm,
    Callback = function(state)
        AutoFarm = state
        if AutoFarm then
            startAutoFarm()
        elseif AutoFarmConnection then
            AutoFarmConnection:Disconnect()
            AutoFarmConnection = nil
        end
    end
})

Tabs.Far:AddDropdown("AutoFarmMode", {
    Title = "Farming Mode",
    Description = "Select farming Mode",
    Values = {"UnderBall", "X Orbit", "Y Orbit"},
    Default = AutoFarmType,
    Callback = function(value)
        AutoFarmType = value
    end
})

Tabs.Far:AddSlider("OrbitSpeedSlider", {
    Title = "Orbit Speed",
    Description = "Adjust orbit rotation speed",
    Default = AutoFarmOrbit,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        AutoFarmOrbit = value
    end
})

Tabs.Far:AddSlider("HeightSlider", {
    Title = "UnderBall Height",
    Description = "Adjust height below ball",
    Default = AutoFarmHeight,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        AutoFarmHeight = value
    end
})

Tabs.Far:AddSlider("RadiusSlider", {
    Title = "Orbit Radius",
    Description = "Adjust distance from ball",
    Default = AutoFarmRadius,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        AutoFarmRadius = value
    end
})
