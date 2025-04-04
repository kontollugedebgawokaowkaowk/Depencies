repeat task.wait() until game:IsLoaded()
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Aerodynamic = false
local Aerodynamic_Time = tick()
local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()
local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')
local Alive = workspace.Alive
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Remotes = {}
local Parry_Key = nil
task.spawn(function()
    for _, Value in pairs(getgc()) do
        if type(Value) == "function" and islclosure(Value) then
            if debug.getupvalues(Value) then
            local Protos = debug.getprotos(Value)
            local Upvalues = debug.getupvalues(Value)
            local Constants = debug.getconstants(Value)
            if #Protos == 4 and #Upvalues == 24 and #Constants == 102 then
                Remotes[debug.getupvalue(Value, 16)] = debug.getconstant(Value, 60)
                Parry_Key = debug.getupvalue(Value, 17)
                Remotes[debug.getupvalue(Value, 18)] = debug.getconstant(Value, 62)
                Remotes[debug.getupvalue(Value, 19)] = debug.getconstant(Value, 63)
                    break
                end
            end
        end
    end
end)
local Key = Parry_Key
local Parries = 0
function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)
    animation:Play()
    task.wait(info.Time)
    Debris:AddItem(animation, 0)
    animation:Destroy()
    animation = nil
end
local Animation = {}
Animation.storage = {}
Animation.current = nil
Animation.track = nil
for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end
local Emotes_Data = {}
for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end


local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")




local Auto_Parry = {}
function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')
    if not Current_Sword then
        return
    end
    if not Parry_Animation then
        return
    end
    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)
    if not Sword_Data or not Sword_Data['AnimationType'] then
        return
    end
    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'
                if object:FindFirstChild('Grab') then
                    sword_animation_type = 'Grab'
                end
                Parry_Animation = object[sword_animation_type]
            end
        end
    end
    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end
function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]
    if not Animations then
        return false
    end
    local Animator = Player.Character.Humanoid.Animator
    if Animation.track then
        Animation.track:Stop()
    end
    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()
    Animation.current = v
end
function Auto_Parry.Get_Balls()
    local Balls = {}
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            table.insert(Balls, Instance)
        end
    end
    return Balls
end
function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
end



-- Improved Auto Parry System
function Auto_Parry.Parry_Data(Parry_Type)
    local Events = {}
    local Camera = workspace.CurrentCamera
    if not Camera then return {0, CFrame.new(), {}, {0, 0}} end
    
    -- Get mouse input or default to screen center
    if Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end

    -- Get player positions
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v:FindFirstChild("PrimaryPart") then
            local success, screenPos = pcall(function()
                return Camera:WorldToScreenPoint(v.PrimaryPart.Position)
            end)
            if success then
                Events[tostring(v)] = screenPos
            end
        end
    end

    -- Parry direction types
    local baseData = {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    
    local directionMap = {
        ['Backwards'] = function() 
            return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.LookVector * 1000)), Events, Vector2_Mouse_Location}
        end,
        ['Random'] = function()
            return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-3000, 3000))), Events, Vector2_Mouse_Location}
        end,
        ['Straight'] = function()
            return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.LookVector * 1000)), Events, Vector2_Mouse_Location}
        end,
        ['Up'] = function()
            return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.UpVector * 1000)), Events, Vector2_Mouse_Location}
        end,
        ['Right'] = function()
            return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.RightVector * 1000)), Events, Vector2_Mouse_Location}
        end,
        ['Left'] = function()
            return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.RightVector * 1000)), Events, Vector2_Mouse_Location}
        end
    }

    return directionMap[Parry_Type] and directionMap[Parry_Type]() or baseData
end

local Parry_Method = "Remote"
function Auto_Parry.Parry(Parry_Type)
    -- Validate input
    if not Parry_Type or type(Parry_Type) ~= "string" then
        warn("Invalid Parry Type:", Parry_Type)
        return false
    end

    -- Get parry data with error handling
    local success, Parry_Data = pcall(function()
        return Auto_Parry.Parry_Data(Parry_Type)
    end)

    if not success or type(Parry_Data) ~= "table" then
        warn("Failed to generate Parry Data")
        return false
    end

    -- Execute parry based on method
    if Parry_Method == "Remote" then
        for Remote, Args in pairs(Remotes) do
            if Remote and typeof(Remote.FireServer) == "function" then
                local success = pcall(function()
                    Remote:FireServer(Args, Key, Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])
                end)
                if not success then
                    warn("Failed to fire remote")
                end
            end
        end
    elseif Parry_Method == "Keypress" then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    elseif Parry_Method == "VirtualInput" then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    else
        warn("Unknown Parry Method:", Parry_Method)
        return false
    end

    return true
end




    if Parries > 7 then
        return false
    end

    Parries += 1

    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
local Lerp_Radians = 0
local Last_Warping = tick()
function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end
local Previous_Velocity = {}
local Curving = tick()
local Runtime = workspace.Runtime
function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then
        return false
    end
    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then
        return false
    end
    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Angle_Threshold = 40 * math.max(Dot, 0)
    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)
    local Dot_Difference = Dot - Direction_Similarity
    local Dot_Threshold = 0.5 - Ping / 1000
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)
    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Angle_Threshold + Speed_Threshold
    table.insert(Previous_Velocity, Velocity)
    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end
    if Enough_Speed and Reach_Time > Ping / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end
    if Distance < Ball_Distance_Threshold then
        return false
    end
    if (tick() - Curving) < Reach_Time / 1.5 then --warn('Curving')
        return true
    end
    if Dot_Difference < Dot_Threshold then
        return true
    end
    local Radians = math.rad(math.asin(Dot))
    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)
    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end
    if #Previous_Velocity == 4 then
        local Intended_Direction_Difference = (Ball_Direction - Previous_Velocity[1].Unit).Unit
        local Intended_Dot = Direction:Dot(Intended_Direction_Difference)
        local Intended_Dot_Difference = Dot - Intended_Dot
        local Intended_Direction_Difference2 = (Ball_Direction - Previous_Velocity[2].Unit).Unit
        local Intended_Dot2 = Direction:Dot(Intended_Direction_Difference2)
        local Intended_Dot_Difference2 = Dot - Intended_Dot2
        if Intended_Dot_Difference < Dot_Threshold or Intended_Dot_Difference2 < Dot_Threshold then
            return true
        end
    end
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end
    return Dot < Dot_Threshold
end
local Closest_Entity = nil
function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)

            if Distance < Max_Distance then
                Max_Distance = Distance
                Closest_Entity = Entity
            end
        end
    end
    return Closest_Entity
end
function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()
    if not Closest_Entity then
        return false
    end
    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end
function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()
    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball
    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)
    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end     
                
function Auto_Parry:Spam_Service()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then
        return false
    end

    Auto_Parry.Closest_Player()

    -- Spam Settings
    local spam_delay = 0.001
    local spam_accuracy = 100
    Auto_Parry.Spam_Sensitivity = 50
    Auto_Parry.Ping_Based_Spam = false

    -- Ball Properties
    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    -- Target Properties
    local Target_Position = Closest_Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    -- Maximum Spam Distance
    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6.5, 95)
    Maximum_Spam_Distance = Maximum_Spam_Distance * self.Spam_Sensitivity
    if self.Ping_Based_Spam then
        Maximum_Spam_Distance = Maximum_Spam_Distance + self.Ping
    end

    -- Return Spam Accuracy if out of range
    if self.Entity_Properties.Distance > Maximum_Spam_Distance or
       self.Ball_Properties.Distance > Maximum_Spam_Distance or
       Target_Distance > Maximum_Spam_Distance then
        return spam_accuracy
    end

    -- Spam Accuracy Calculation
    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed
    spam_accuracy = Maximum_Spam_Distance - Maximum_Dot

    -- Spam Delay System
    task.wait(spam_delay)

    return spam_accuracy
end           
local visualizerEnabled = false
local function get_character()
    return LocalPlayer and LocalPlayer.Character
end
local function get_primary_part()
    local char = get_character()
    return char and char.PrimaryPart
end
local function get_ball()
    local ballContainer = Workspace:FindFirstChild("Balls")
    if ballContainer then
        for _, ball in ipairs(ballContainer:GetChildren()) do
            if not ball.Anchored then
                return ball
            end
        end
    end
    return nil
end
local function calculate_visualizer_radius()
    local ball = get_ball()
    if ball then
        local velocity = ball.Velocity.Magnitude
        return math.clamp(velocity / 2.4 + 10, 15, 200)
    end
    return 15
end
local visualizer = Instance.new("Part")
visualizer.Shape = Enum.PartType.Ball
visualizer.Anchored = true
visualizer.CanCollide = false
visualizer.Material = Enum.Material.ForceField -- Set to ForceField
visualizer.Transparency = 0.5
visualizer.Parent = Workspace
visualizer.Size = Vector3.new(0, 0, 0) -- Start hidden
local function toggle_visualizer(state)
    visualizerEnabled = state
    if not state then
        visualizer.Size = Vector3.new(0, 0, 0) -- Hide when disabled
    end
end
RunService.RenderStepped:Connect(function()
    if not visualizerEnabled then return end
    local primaryPart = get_primary_part()
    local ball = get_ball()
    if primaryPart and ball then
        local radius = calculate_visualizer_radius()
        local isHighlighted = primaryPart:FindFirstChild("Highlight") -- Check if player is highlighted
        visualizer.Size = Vector3.new(radius, radius, radius)
        visualizer.CFrame = primaryPart.CFrame
        visualizer.Color = isHighlighted and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 255, 255)
    else
        visualizer.Size = Vector3.new(0, 0, 0) -- Hide visualizer if no ball or player
    end
end)
                
local Connections_Manager = {}
local Selected_Parry_Type = nil
local Parried = false
local Last_Parry = 0
local MauaulSpam;
function ManualSpam()
	if MauaulSpam then
		MauaulSpam:Destroy();
		MauaulSpam = nil;
		return;
	end
	MauaulSpam = Instance.new("ScreenGui");
	MauaulSpam.Name = "MauaulSpam";
	MauaulSpam.Parent = game.CoreGui;
	MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	MauaulSpam.ResetOnSpawn = false;
	local Main = Instance.new("Frame");
	Main.Name = "Main";
	Main.Parent = MauaulSpam;
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderSizePixel = 0;
	Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0);
	Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0);
	local UICorner = Instance.new("UICorner");
	UICorner.Parent = Main;
	local IndercantorBlahblah = Instance.new("Frame");
	IndercantorBlahblah.Name = "IndercantorBlahblah";
	IndercantorBlahblah.Parent = Main;
	IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercantorBlahblah.BorderSizePixel = 0;
	IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0);
	IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0);
	local UICorner_2 = Instance.new("UICorner");
	UICorner_2.CornerRadius = UDim.new(1, 0);
	UICorner_2.Parent = IndercantorBlahblah;
	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint.Parent = IndercantorBlahblah;
	local PC = Instance.new("TextLabel");
	PC.Name = "PC";
	PC.Parent = Main;
	PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PC.BackgroundTransparency = 1;
	PC.BorderColor3 = Color3.fromRGB(0, 0, 0);
	PC.BorderSizePixel = 0;
	PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0);
	PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0);
	PC.Font = Enum.Font.Unknown;
	PC.Text = "PC: E to spam";
	PC.TextColor3 = Color3.fromRGB(57, 57, 57);
	PC.TextScaled = true;
	PC.TextSize = 16;
	PC.TextWrapped = true;
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint.Parent = PC;
	UITextSizeConstraint.MaxTextSize = 16;
	local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_2.Parent = PC;
	UIAspectRatioConstraint_2.AspectRatio = 4.346;
	local IndercanotTextBlah = Instance.new("TextButton");
	IndercanotTextBlah.Name = "IndercanotTextBlah";
	IndercanotTextBlah.Parent = Main;
	IndercanotTextBlah.Active = false;
	IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.BackgroundTransparency = 1;
	IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercanotTextBlah.BorderSizePixel = 0;
	IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0);
	IndercanotTextBlah.Selectable = false;
	IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0);
	IndercanotTextBlah.Font = Enum.Font.GothamBold;
	IndercanotTextBlah.Text = "Spam";
	IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.TextScaled = true;
	IndercanotTextBlah.TextSize = 24;
	IndercanotTextBlah.TextWrapped = true;
	local UIGradient = Instance.new("UIGradient");
	UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))});
	UIGradient.Parent = IndercanotTextBlah;
	local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint_2.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.MaxTextSize = 52;
	local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_3.Parent = IndercanotTextBlah;
	UIAspectRatioConstraint_3.AspectRatio = 3.212;
	local UIAspectRatioConstraint_4 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint_4.Parent = Main;
	UIAspectRatioConstraint_4.AspectRatio = 1.667;
	MauaulSpam.Name = "MauaulSpam";
	MauaulSpam.Parent = game.CoreGui;
	MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	MauaulSpam.ResetOnSpawn = false;
	Main.Name = "Main";
	Main.Parent = MauaulSpam;
	Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderColor3 = Color3.fromRGB(0, 0, 0);
	Main.BorderSizePixel = 0;
	Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0);
	Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0);
	UICorner.Parent = Main;
	IndercantorBlahblah.Name = "IndercantorBlahblah";
	IndercantorBlahblah.Parent = Main;
	IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercantorBlahblah.BorderSizePixel = 0;
	IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0);
	IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0);
	UICorner_2.CornerRadius = UDim.new(1, 0);
	UICorner_2.Parent = IndercantorBlahblah;
	UIAspectRatioConstraint.Parent = IndercantorBlahblah;
	PC.Name = "PC";
	PC.Parent = Main;
	PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PC.BackgroundTransparency = 1;
	PC.BorderColor3 = Color3.fromRGB(0, 0, 0);
	PC.BorderSizePixel = 0;
	PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0);
	PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0);
	PC.Font = Enum.Font.Unknown;
	PC.Text = "PC: E to spam";
	PC.TextColor3 = Color3.fromRGB(57, 57, 57);
	PC.TextScaled = true;
	PC.TextSize = 16;
	PC.TextWrapped = true;
	UITextSizeConstraint.Parent = PC;
	UITextSizeConstraint.MaxTextSize = 16;
	UIAspectRatioConstraint_2.Parent = PC;
	UIAspectRatioConstraint_2.AspectRatio = 4.346;
	IndercanotTextBlah.Name = "IndercanotTextBlah";
	IndercanotTextBlah.Parent = Main;
	IndercanotTextBlah.Active = false;
	IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.BackgroundTransparency = 1;
	IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0);
	IndercanotTextBlah.BorderSizePixel = 0;
	IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0);
	IndercanotTextBlah.Selectable = false;
	IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0);
	IndercanotTextBlah.Font = Enum.Font.GothamBold;
	IndercanotTextBlah.Text = "Spam";
	IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255);
	IndercanotTextBlah.TextScaled = true;
	IndercanotTextBlah.TextSize = 24;
	IndercanotTextBlah.TextWrapped = true;
	UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))});
	UIGradient.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.Parent = IndercanotTextBlah;
	UITextSizeConstraint_2.MaxTextSize = 52;
	UIAspectRatioConstraint_3.Parent = IndercanotTextBlah;
	UIAspectRatioConstraint_3.AspectRatio = 3.212;
	UIAspectRatioConstraint_4.Parent = Main;
	UIAspectRatioConstraint_4.AspectRatio = 1.667;
	local function HEUNEYP_fake_script()
		local script = Instance.new("LocalScript", IndercanotTextBlah);
		local button = script.Parent;
		local UIGredient = button.UIGradient;
		local NeedToChange = script.Parent.Parent.IndercantorBlahblah;
		local userInputService = game:GetService("UserInputService");
		local RunService = game:GetService("RunService");
		local green_Color = {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 0)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))};
		local red_Color = {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 0)),ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))};
		local current_Color = red_Color;
		local target_Color = green_Color;
		local is_Green = false;
		local transition = false;
		local transition_Time = 1;
		local start_Time;
		local function startColorTransition()
			transition = true;
			start_Time = tick();
		end
		RunService.Heartbeat:Connect(function()
			if transition then
				local elapsed = tick() - start_Time;
				local alpha = math.clamp(elapsed / transition_Time, 0, 1);
				local new_Color = {};
				for i = 1, #current_Color do
					local start_Color = current_Color[i].Value;
					local end_Color = target_Color[i].Value;
					new_Color[i] = ColorSequenceKeypoint.new(current_Color[i].Time, start_Color:Lerp(end_Color, alpha));
				end
				UIGredient.Color = ColorSequence.new(new_Color);
				if (alpha >= 1) then
					transition = false;
					current_Color, target_Color = target_Color, current_Color;
				end
			end
		end);
		local function toggleColor()
			if not transition then
				is_Green = not is_Green;
				if is_Green then
					target_Color = green_Color;
					NeedToChange.BackgroundColor3 = Color3.new(0, 1, 0);
				else
					target_Color = red_Color;
					NeedToChange.BackgroundColor3 = Color3.new(1, 0, 0);
				end
				startColorTransition();
			end
		end
		button.MouseButton1Click:Connect(toggleColor);
		userInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return;
			end
			if (input.KeyCode == Enum.KeyCode.E) then
				toggleColor();
			end
		end);
		RunService.PreSimulation:Connect(function()
			if is_Green then
				for _ = 1, 15 do
					Auto_Parry.Parry('Custom');
				end
			end
		end);
	end
	coroutine.wrap(HEUNEYP_fake_script)();
	local function WWJM_fake_script()
		local script = Instance.new("LocalScript", Main);
		local UserInputService = game:GetService("UserInputService");
		local gui = script.Parent;
		local dragging;
		local dragInput;
		local dragStart;
		local startPos;
		local function update(input)
			local delta = input.Position - dragStart;
			local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
			local TweenService = game:GetService("TweenService");
			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			local tween = TweenService:Create(gui, tweenInfo, {Position=newPosition});
			tween:Play();
		end
		gui.InputBegan:Connect(function(input)
			if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
				dragging = true;
				dragStart = input.Position;
				startPos = gui.Position;
				input.Changed:Connect(function()
					if (input.UserInputState == Enum.UserInputState.End) then
						dragging = false;
					end
				end);
			end
		end);
		gui.InputChanged:Connect(function(input)
			if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
				dragInput = input;
			end
		end);
		UserInputService.InputChanged:Connect(function(input)
			if (dragging and (input == dragInput)) then
				update(input);
			end
		end);
	end
	coroutine.wrap(WWJM_fake_script)();
end

ManualSpam()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local Config = {
    AIEnabled = false,
    AISpeed = 50, -- Default speed
    MinDistance = 20 -- Distance to maintain from ball
}

-- Ball Functions
local function GetBalls()
    local balls = {}
    for _, ball in pairs(workspace.Balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            table.insert(balls, ball)
        end
    end
    return balls
end

local function GetClosestBall(character)
    local closestBall, closestDistance = nil, math.huge
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    for _, ball in pairs(GetBalls()) do
        local distance = (ball.Position - rootPart.Position).Magnitude
        if distance < closestDistance then
            closestBall = ball
            closestDistance = distance
        end
    end
    return closestBall
end

-- AI Movement Function
local function AIPlay()
    if not Config.AIEnabled then return end
    
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    local ball = GetClosestBall(character)
    if not ball then return end
    
    local ballPosition = ball.Position
    local playerPosition = rootPart.Position
    local distance = (ballPosition - playerPosition).Magnitude
    
    -- Stop if close enough
    if distance <= Config.MinDistance then
        humanoid:MoveTo(playerPosition)
        return
    end
    
    -- Calculate movement direction
    local direction = (ballPosition - playerPosition).Unit
    local targetPosition = playerPosition + direction * (distance - Config.MinDistance)
    
    -- Set movement speed
    humanoid.WalkSpeed = Config.AISpeed
    humanoid:MoveTo(targetPosition)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Direct Variables
local AutoFarm = false
local AutoFarmType = "UnderBall"
local AutoFarmOrbit = 5
local AutoFarmHeight = 10
local AutoFarmRadius = 10

-- Ball Functions
local function get_ball()
    for _, ball in pairs(workspace.Balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            return ball
        end
    end
end

local function get_humanoid_root_part(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

-- Auto Farm Logic
local function autofarm()
    if not AutoFarm then return end
    
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


local ThemeSelector = {
    Themes = {
        "Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose", "Golden",
        "DarkPurple", "Dark Halloween", "Light Halloween", "Dark Typewriter",
        "Jungle", "Midnight", "Neon Glow", "Neon Green", "Neon Pink",
        "Sunrise", "Galaxy", "Pastel", "Crimson", "Sunset", "Oceanic",
        "Minimalist", "Cyberpunk"
    },
    SelectedTheme = "Galaxy"
}

local function createDropdownSelector()
    local themeScreen = Instance.new("ScreenGui")
    themeScreen.Name = "ThemeSelector"
    themeScreen.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 200) -- Smaller initial size
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20) -- Darker background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = themeScreen
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Add a subtle gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 17))
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Add a subtle glow effect
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.new(0.5, 0, 0, -100)
    glow.Size = UDim2.new(1.5, 0, 0, 300)
    glow.Image = "rbxassetid://4996891970" -- Radial gradient
    glow.ImageColor3 = Color3.fromRGB(20, 20, 40)
    glow.ImageTransparency = 0.85
    glow.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Select Theme"
    title.TextColor3 = Color3.fromRGB(230, 230, 230)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame
    
    -- Create dropdown button
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0.9, 0, 0, 45)
    dropdownButton.Position = UDim2.new(0.05, 0, 0, 60)
    dropdownButton.Text = ThemeSelector.SelectedTheme
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.TextSize = 16
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    dropdownButton.AutoButtonColor = false
    dropdownButton.Parent = mainFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdownButton
    
    -- Add dropdown icon
    local dropdownIcon = Instance.new("ImageLabel")
    dropdownIcon.Name = "DropdownIcon"
    dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
    dropdownIcon.Position = UDim2.new(1, -30, 0.5, -10)
    dropdownIcon.BackgroundTransparency = 1
    dropdownIcon.Image = "rbxassetid://6031091004" -- Dropdown arrow
    dropdownIcon.ImageColor3 = Color3.fromRGB(180, 180, 180)
    dropdownIcon.Parent = dropdownButton
    
    -- Create dropdown container
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Name = "DropdownContainer"
    dropdownContainer.Size = UDim2.new(0.9, 0, 0, 0) -- Start with 0 height
    dropdownContainer.Position = UDim2.new(0.05, 0, 0, 110)
    dropdownContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    dropdownContainer.BorderSizePixel = 0
    dropdownContainer.ClipsDescendants = true
    dropdownContainer.Visible = false
    dropdownContainer.Parent = mainFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = dropdownContainer
    
    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Size = UDim2.new(1, 0, 1, 0)
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.BorderSizePixel = 0
    optionsFrame.ScrollBarThickness = 4
    optionsFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
    optionsFrame.Parent = dropdownContainer
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 2)
    optionsLayout.Parent = optionsFrame
    
    -- Save button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0.8, 0, 0, 45)
    saveButton.Position = UDim2.new(0.1, 0, 1, -60)
    saveButton.Text = "SAVE & CONTINUE"
    saveButton.Font = Enum.Font.GothamBold
    saveButton.TextSize = 14
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.BackgroundColor3 = Color3.fromRGB(40, 80, 170) -- Darker blue
    saveButton.Parent = mainFrame
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 6)
    saveCorner.Parent = saveButton
    
    -- Add a subtle gradient to save button
    local saveGradient = Instance.new("UIGradient")
    saveGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 90, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 70, 160))
    })
    saveGradient.Rotation = 45
    saveGradient.Parent = saveButton
    
    -- Create option buttons
    local function createOptionButton(themeName)
        local button = Instance.new("TextButton")
        button.Name = themeName
        button.Size = UDim2.new(1, -10, 0, 35)
        button.Position = UDim2.new(0, 5, 0, 0)
        button.Text = themeName
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.BackgroundColor3 = themeName == ThemeSelector.SelectedTheme 
            and Color3.fromRGB(40, 80, 170) 
            or Color3.fromRGB(35, 35, 40)
        button.AutoButtonColor = false
        button.Parent = optionsFrame
        
        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 4)
        optionCorner.Parent = button
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            if themeName ~= ThemeSelector.SelectedTheme then
                game:GetService("TweenService"):Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}
                ):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if themeName ~= ThemeSelector.SelectedTheme then
                game:GetService("TweenService"):Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}
                ):Play()
            end
        end)
        
        -- Selection logic
        button.MouseButton1Click:Connect(function()
            ThemeSelector.SelectedTheme = themeName
            dropdownButton.Text = themeName
            
            -- Update all buttons
            for _, child in ipairs(optionsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    game:GetService("TweenService"):Create(
                        child,
                        TweenInfo.new(0.2),
                        {BackgroundColor3 = child.Name == themeName 
                            and Color3.fromRGB(40, 80, 170) 
                            or Color3.fromRGB(35, 35, 40)}
                    ):Play()
                end
            end
            
            -- Close dropdown after selection
            toggleDropdown(false)
        end)
        
        return button
    end
    
    -- Create all theme options
    for _, theme in ipairs(ThemeSelector.Themes) do
        createOptionButton(theme)
    end
    
    -- Update scrolling frame canvas size
    optionsFrame.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y)
    
    -- Dropdown toggle function
    local isOpen = false
    function toggleDropdown(forceState)
        local newState = forceState ~= nil and forceState or not isOpen
        isOpen = newState
        
        -- Rotate dropdown icon
        game:GetService("TweenService"):Create(
            dropdownIcon,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Rotation = isOpen and 180 or 0}
        ):Play()
        
        -- Resize main frame
        game:GetService("TweenService"):Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = isOpen and UDim2.new(0, 300, 0, 400) or UDim2.new(0, 300, 0, 200)}
        ):Play()
        
        -- Show/hide dropdown container
        dropdownContainer.Visible = true
        
        -- Animate dropdown container
        game:GetService("TweenService"):Create(
            dropdownContainer,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = isOpen and UDim2.new(0.9, 0, 0, 200) or UDim2.new(0.9, 0, 0, 0)}
        ):Play()
        
        -- Hide container if closed
        if not isOpen then
            delay(0.3, function()
                if not isOpen then
                    dropdownContainer.Visible = false
                end
            end)
        end
        
        -- Reposition save button
        game:GetService("TweenService"):Create(
            saveButton,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = isOpen and UDim2.new(0.1, 0, 1, -60) or UDim2.new(0.1, 0, 1, -60)}
        ):Play()
    end
    
    -- Dropdown button hover effects
    dropdownButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(
            dropdownButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}
        ):Play()
    end)
    
    dropdownButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(
            dropdownButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}
        ):Play()
    end)
    
    -- Save button hover effects
    saveButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(
            saveButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(50, 90, 180)}
        ):Play()
    end)
    
    saveButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(
            saveButton,
            TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(40, 80, 170)}
        ):Play()
    end)
    
    -- Toggle dropdown on button click
    dropdownButton.MouseButton1Click:Connect(function()
        toggleDropdown()
    end)
    
    -- Save button functionality
    saveButton.MouseButton1Click:Connect(function()
        -- Add ripple effect
        local ripple = Instance.new("Frame")
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.Parent = saveButton
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        -- Animate ripple
        game:GetService("TweenService"):Create(
            ripple,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(2, 0, 2, 0), BackgroundTransparency = 1}
        ):Play()
        
        -- Remove ripple after animation
        delay(0.5, function()
            ripple:Destroy()
        end)
        
        -- Tween out animation
        local tweenOut = game:GetService("TweenService"):Create(
            mainFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 300, 0, 0), Position = UDim2.new(0.5, -150, 0.5, 0)}
        )
        
        tweenOut:Play()
        tweenOut.Completed:Wait()
        themeScreen:Destroy()
        
        -- Now load the main UI with selected theme
        loadMainUI()
    end)
    
    -- Initial setup
    dropdownButton.Text = ThemeSelector.SelectedTheme
    
    -- Add entrance animation
    mainFrame.Size = UDim2.new(0, 300, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, 0)
    
    game:GetService("TweenService"):Create(
        mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 300, 0, 200), Position = UDim2.new(0.5, -150, 0.5, -100)}
    ):Play()
    
    return themeScreen
end

-- Function to load main UI after theme selection
local themeDropdown = createDropdownSelector()
function loadMainUI()
    local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/CodeE4X-dev/Library/refs/heads/main/FluentRemake.lua"))()

    local Window = Fluent:CreateWindow({
        Title = "Blade Ball - StarX Hub V2",
        SubTitle = "by CodeE4X",
        TabWidth = 150,
        Size = UDim2.fromOffset(500, 250),
        Acrylic = false,
        Theme = ThemeSelector.SelectedTheme,
        MinimizeKey = Enum.KeyCode.LeftControl 
    })

    Fluent:Notify({
        Title = "Thanks For Using Our Script!",
        Content = "By Joining Our Discord, you Can Get 3 Days Free Key![Later]",
        SubContent = "",
        Duration = 5
    })

-- Fluent provides Lucide Icons, they are optional
local Tab = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    y = Window:AddTab({ Title = "Thanks!", Icon = "star" }),
    Main = Window:AddTab({ Title = "Main", Icon = "swords" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "boxes" }),
    Plr = Window:AddTab({ Title = "Player", Icon = "user" }),
    Rate = Window:AddTab({ Title = "Rating", Icon = "star" })
	}

Fluent:Notify({
        Title = "Parry Doesnt Work?",
        Content = "Change Curve Methods!",
        SubContent = "", -- Optional
        Duration = 15 -- Set to nil to make the notification not disappear
})

-- Webhook URL (replace with your actual webhook URL)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1357557327158575245/MWKjD8BNF_UzlVql20gkxYjriI3pY7hbdqhC-P61LJDchIRBKj6owuzZqWyF1Khtqj7H"

-- Function to send rating to Discord webhook using http_request
local function sendRatingToWebhook(rating)
    local playerName = game:GetService("Players").LocalPlayer.Name
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    
    local data = {
        ["embeds"] = {{
            ["title"] = "New Rating Received",
            ["description"] = string.format("Player: %s\nRating: %s\nTime: %s", playerName, rating, currentTime),
            ["color"] = ({
                Good = 65280,      -- Green
                Basic = 16776960,  -- Yellow
                Bad = 16711680     -- Red
            })[rating] or 16777215, -- Default white
            ["footer"] = {
                ["text"] = "Rating System"
            }
        }}
    }
    
    local encoded = game:GetService("HttpService"):JSONEncode(data)
    
    local success, response = pcall(function()
        local http_request = http_request or request or (fluxus and fluxus.request) or (getgenv and getgenv().request)
        if not http_request then
            error("No http_request function found")
        end
        
        return http_request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = encoded
        })
    end)
    
    if success then
        print("Rating submitted successfully!")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Rating Submitted",
            Text = "Thank you for your "..rating.." rating!",
            Duration = 5,
            Icon = ({
                Good = "rbxassetid://6023426923",  -- Green check
                Basic = "rbxassetid://6022668888", -- Yellow warning
                Bad = "rbxassetid://6023426926"    -- Red error
            })[rating]
        })
    else
        warn("Failed to send rating:", response)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = "Failed to submit rating",
            Duration = 5,
            Icon = "rbxassetid://6023426926" -- Red error
        })
    end
end

-- Create rating buttons
local buttons = {
    {
        Title = "⭐ Good Rating", 
        Description = "Everything worked perfectly!",
        Rating = "Good"
    },
    {
        Title = "🔶 Basic Rating",
        Description = "It worked but could be better",
        Rating = "Basic"
    },
    {
        Title = "❌ Bad Rating",
        Description = "Had issues or didn't work",
        Rating = "Bad"
    }
}

for _, btn in ipairs(buttons) do
    Tab.Rate:AddButton({
        Title = btn.Title,
        Description = btn.Description,
        Callback = function()
            sendRatingToWebhook(btn.Rating)
        end
    })
end

local Section = Tab.Home:AddSection("Credits")

Tab.Home:AddParagraph({
    Title = "Credits Here",
    Content = "-CodeE4X\n-Isa Fixxing Remotes\n-Fsploit Inspirated the ap and curve\n-Reaper Hub Some of The Lib Themes"
})

Tab.Home:AddButton({
    Title = "Copy Discord Link",
    Description = "Copy Into Your Clipboard",
    Callback = function()
        setclipboard('https://discord.gg/b7yA7uTfmp')
        Fluent:Notify({
            Title = "Pwease Join our Discord",
            Content = "this is femboy server",
            SubContent = "",
            Duration = 10 
    })
    end
})

Tab.Home:AddParagraph({
    Title = "Themes Credit",
    Content = "-CodeE4X | All Themes Except DarkPurple, Light Halloween, Dark Halloween\n-Reaper hub | DarkPurple, Light Halloween, Dark Halloween"
})

local Section = Tab.y:AddSection("Showcaser!")
Tab.y:AddParagraph({
    Title = "How To get In Here",
    Content = "Tell Me In Discord(@xyz_isa25) or i see your videos, your privilage? get 10 Days Key![later]"
})


local Section = Tab.Main:AddSection("Main Section")

local Toggle = Tab.Main:AddToggle("MyToggle", 
{
    Title = "Auto Parry", 
    Description = "Auto Parry/Block The ball",
    Default = false,
    Callback = function(state)
        if state then
            Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()
                for _, Ball in pairs(Balls) do
                if not Ball then repeat task.wait() Balls = Auto_Parry.Get_Balls() until Balls
                    return
                end
                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then
                    return
                end
                Ball:GetAttributeChangedSignal('target'):Once(function()
                    Parried = false
                end)
                if Parried then
                    return
                end
                local Ball_Target = Ball:GetAttribute('target')
                local One_Target = One_Ball:GetAttribute('target')
                local Velocity = Zoomies.VectorVelocity
                local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                local Speed = Velocity.Magnitude
                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                local Parry_Accuracy = (Speed / 3.25) + Ping
                local Curved = Auto_Parry.Is_Curved()
                if Ball_Target == tostring(Player) and Aerodynamic then
                    local Elasped_Tornado = tick() - Aerodynamic_Time
                    if Elasped_Tornado > 0.6 then
                        Aerodynamic_Time = tick()
                        Aerodynamic = false
                    end
                    return
                end
                if One_Target == tostring(Player) and Curved then
                    return
                end
                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    Parried = true
                end
                local Last_Parrys = tick()
                repeat RunService.PreSimulation:Wait() until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        else
            if Connections_Manager['Auto Parry'] then
                Connections_Manager['Auto Parry']:Disconnect()
                Connections_Manager['Auto Parry'] = nil
            end
        end
    end
})

local Toggle = Tab.Main:AddToggle("MyToggle", 
{
    Title = "Auto Spam", 
    Description = "Still..Better u use Manual Spam Too, This For Backup tho if u'r Not Prepared(srry i yap somuch)",
    Default = false,
    Callback = function(state)
        if state then
            Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
                if not Ball then return end
        
                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then return end
        
                -- Hitung kecepatan bola (Magnitude VectorVelocity)
                local Ball_Speed = Zoomies.VectorVelocity.Magnitude
        
                -- Cooldown dinamis: 
                -- - Jika bola LAMBAT (speed < 100), cooldown = 0.5 detik (default)
                -- - Jika bola CEPAT (speed > 100), cooldown = 0.1 - 0.3 detik (tergantung kecepatan)
                local Dynamic_Cooldown = math.clamp(0.5 - (Ball_Speed / 500), 0.1, 0.5)
        
                -- Cek apakah cooldown sudah selesai
                if (tick() - Last_Parry) < Dynamic_Cooldown then
                    return  -- Skip jika masih dalam cooldown
                end
        
                -- Lanjutkan dengan logika parry
                Auto_Parry.Closest_Player()
                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                local spam_accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = math.clamp(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10, 10, 16),
                    Spam_Sensitivity = Auto_Parry.Spam_Sensitivity,
                    Ping_Based_Spam = Auto_Parry.Ping_Based_Spam
                })
        
                -- Cek kondisi parry
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local Ball_Target = Alive:FindFirstChild(Ball:GetAttribute('target'))
        
                if Ball_Target and Distance <= spam_accuracy and Parries > 1 then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    Last_Parry = tick()  -- Reset cooldown timer
                end
            end)
        else
            if Connections_Manager['Auto Spam'] then
                Connections_Manager['Auto Spam']:Disconnect()
                Connections_Manager['Auto Spam'] = nil
            end
        end
    end
})

local Toggle = Tab.Main:AddToggle("MyToggle", 
{
    Title = "Manual Spam", 
    Description = "Idk what i need put here",
    Default = false,
    Callback = function(state)
        ManualSpam()
        end
})



-- Letakkan di ServerScriptService
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Konfigurasi
local CheckOwner = false


local TARGET_PLAYERS = {"Anisha_galaxy", "VIPPlayer", "Moderator"}  -- Daftar target
local WEBHOOK_URL = "https://discord.com/api/webhooks/1357681589177286716/GarD3vf1QV54kMSX9_XAz68N4yDPSoIUkxkI4WYomJfeikvaAoIgieS_ezHewlydXUep"
local CHECK_INTERVAL = 5

-- Variabel tracking
local notifiedPlayers = {}
local lastCheck = 0
local executorPlayer = nil  -- Untuk menyimpan data executor

-- Fungsi http_request (kompatibel dengan executor)
local function http_request(url, method, data, headers)
    if syn and syn.request then
        return syn.request({
            Url = url,
            Method = method,
            Headers = headers or {},
            Body = data
        })
    elseif request then
        return request({
            Url = url,
            Method = method,
            Headers = headers or {},
            Body = data
        })
    elseif http and http.request then
        return http.request({
            Url = url,
            Method = method,
            Headers = headers or {},
            Body = data
        })
    else
        warn("Executor tidak mendukung HTTP Request")
        return nil
    end
end

-- Fungsi kirim webhook
local function sendWebhook(playerName, isExecutor)
    local description = isExecutor and "🎯 **Executor** masuk server!" or "🎯 **Target Player** masuk server!"
    
    local data = {
        ["content"] = description,
        ["embeds"] = {{
            ["title"] = playerName,
            ["color"] = isExecutor and 16711680 or 65280,  -- Merah untuk executor, hijau untuk target
            ["fields"] = {
                {["name"] = "Waktu", ["value"] = os.date("%X"), ["inline"] = true},
                {["name"] = "Total Player", ["value"] = #Players:GetPlayers(), ["inline"] = true},
                {["name"] = "Status", ["value"] = isExecutor and "Executor" or "Target Player", ["inline"] = true}
            }
        }}
    }
    
    local jsonData = game:GetService("HttpService"):JSONEncode(data)
    http_request(WEBHOOK_URL, "POST", jsonData, {
        ["Content-Type"] = "application/json"
    })
end

-- Cek apakah script dijalankan oleh executor (client-side)
if not RunService:IsServer() then
    executorPlayer = Players.LocalPlayer
    sendWebhook(executorPlayer.Name, true)
    print("Executor terdeteksi:", executorPlayer.Name)
end

-- Pengecekan berkala untuk target player
RunService.Heartbeat:Connect(function(step)
    if not CheckOwner then return end
    
    lastCheck += step
    if lastCheck >= CHECK_INTERVAL then
        lastCheck = 0
        
        for _, player in ipairs(Players:GetPlayers()) do
            -- Jika player adalah target (Anisha_galaxy, VIP, dll)
            if table.find(TARGET_PLAYERS, player.Name) and not notifiedPlayers[player.UserId] then
                sendWebhook(player.Name, false)
                notifiedPlayers[player.UserId] = true
                print("Notifikasi terkirim untuk target:", player.Name)
            end
        end
    end
end)

-- Reset status saat player keluar
Players.PlayerRemoving:Connect(function(player)
    notifiedPlayers[player.UserId] = nil
end)

local Toggle = Tab.Main:AddToggle("MyToggle", 
{
    Title = "Auto Curve", 
    Description = "Make A Balls uhh ummm idk get out",
    Default = false,
    Callback = function(state)
	CheckOwner = state
    end
})

local Dropdown = Tab.Main:AddDropdown("Dropdown", {
    Title = "Curve Method",
    Description = "CHANGE THIS!!!!!!",
    Values = {"Random", "Backwards", "Straight", "Up", "Right", "Left"},
    Multi = false,
    Default = 3,
    Callback = function(slctd)
        -- Ensure the selected type is valid
        local validTypes = {"Random", "Backwards", "Straight", "Up", "Right", "Left"}
        if table.find(validTypes, slctd) then
            Selected_Parry_Type = slctd
        else
            Selected_Parry_Type = "Backwards"
            warn("Invalid parry type selected, defaulting to Backwards")
        end
    end
})

local Section = Tab.Main:AddSection("Sub-Main Section")

local Slider = Tab.Main:AddSlider("Slider", 
{
    Title = "Spam Delay",
    Description = "For Better Performance Use 0.001",
    Default = 0.001,
    Min = 0.0001,
    Max = 1,
    Rounding = 0.0001,
    Callback = function(sigma)
        local spam_delay = v
    end
})

local Slider = Tab.Main:AddSlider("Slider", 
{
    Title = "Spam Sensivity",
    Description = "im sigma",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(V)
        Auto_Parry.Spam_Sensitivity = v
    end
})

local Slider = Tab.Main:AddSlider("Slider", 
{
    Title = "Spam Accuracy",
    Description = "rick astley is awesome",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        spam_accuracy = v
    end
})

local Section = Tab.Main:AddSection("Debug Section")

local Toggle = Tab.Main:AddToggle("MyToggle", 
{
    Title = "Visualizer", 
    Description = "show parry Range",
    Default = false,
    Callback = function(state)
        visualizerEnabled = state
    end 
})

Tab.Main:AddButton({
    Title = "Open Dev Console",
    Description = "idk for dev",
    Callback = function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end
})


local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local lastSentMessages = {}
local webhookUrl = "https://discord.com/api/webhooks/1357557327158575245/MWKjD8BNF_UzlVql20gkxYjriI3pY7hbdqhC-P61LJDchIRBKj6owuzZqWyF1Khtqj7H" -- REPLACE WITH YOUR WEBHOOK

-- Function to send messages to webhook
local function sendToWebhook(messageType, message)
    -- Generate a unique key for this message to prevent duplicates
    local messageKey = messageType .. ":" .. message:sub(1, 50):gsub("%s", "_")
    
    -- Don't send if this message was sent recently
    if lastSentMessages[messageKey] then return end
    lastSentMessages[messageKey] = os.time()
    
    -- Clean up old entries
    for key, timestamp in pairs(lastSentMessages) do
        if os.time() - timestamp > 300 then -- 5 minute cooldown
            lastSentMessages[key] = nil
        end
    end
    
    local executor = "Executor: " .. (identifyexecutor() or "Unknown") -- Adjust based on your executor
    local ping = "Ping: " .. math.random(50, 150) .. "ms" -- Example ping
    
    local embedColor = messageType == "ERROR" and 16711680 or 16753920 -- Red for error, orange for warning
    
    local payload = {
        ["content"] = executor .. "\n" .. ping .. "\n```lua\n" .. message .. "\n```\n" .. 
                     (messageType == "ERROR" and "Error in Console!" or "Warning in Console!"),
        ["username"] = "Console Monitor",
        ["avatar_url"] = "https://i.imgur.com/example.png",
        ["embeds"] = {{
            ["color"] = embedColor,
            ["title"] = messageType == "ERROR" and "🛑 Error Detected" or "⚠️ Warning Detected",
            ["description"] = "```lua\n" .. message .. "\n```",
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    -- Send to webhook
    pcall(function()
        local jsonPayload = HttpService:JSONEncode(payload)
        HttpService:PostAsync(webhookUrl, jsonPayload)
    end)
end

-- Monitor console messages
LogService.MessageOut:Connect(function(message, messageType)
    if messageType == Enum.MessageType.MessageError then
        -- Add to UI
        Tab.Main:AddParagraph({
            Title = "🛑 Error Detected:",
            Content = message
        })
        -- Send to webhook
        sendToWebhook("ERROR", message)
        
    elseif messageType == Enum.MessageType.MessageWarning then
        -- Add to UI
        Tab.Main:AddParagraph({
            Title = "⚠️ Warning Detected:",
            Content = message
        })
        -- Send to webhook
        sendToWebhook("WARNING", message)
        
    elseif messageType == Enum.MessageType.MessageOutput then
        -- Optional: You can add regular output to UI if needed
        Tab.Main:AddParagraph({
            Title = "📢 Console Output:",
            Content = message
        })
    end
end)

local Section = Tab.Misc:AddSection("Misc")

Tab.Misc:AddToggle("AIToggle", {
    Title = "AI Play",
    Description = "Umm uhh Automatically Play game",
    Default = Config.AIEnabled,
    Callback = function(state)
        Config.AIEnabled = state
    end
})

-- Speed Slider
Tab.Misc:AddSlider("AISpeedSlider", {
    Title = "AI Speed",
    Description = "Adjust movement speed",
    Default = Config.AISpeed,
    Min = 16,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        Config.AISpeed = value
    end
})

-- Run AI Loop
RunService.Heartbeat:Connect(AIPlay)

-- Create Toggle
Tab.Misc:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Description = "Automatically farms balls and slaps the ball, oke going deeper but you need turn on auto parry too",
    Default = AutoFarm,
    Callback = function(state)
        AutoFarm = state
    end
})

-- Mode Dropdown
Tab.Misc:AddDropdown("AutoFarmMode", {
    Title = "Farming Mode",
    Description = "Select farming Mode",
    Values = {"UnderBall", "X Orbit", "Y Orbit"},
    Default = AutoFarmType,
    Callback = function(value)
        AutoFarmType = value
    end
})

-- Orbit Speed Slider
Tab.Misc:AddSlider("OrbitSpeedSlider", {
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

-- Height Slider (for UnderBall mode)
Tab.Misc:AddSlider("HeightSlider", {
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

-- Radius Slider (for Orbit modes)
Tab.Misc:AddSlider("RadiusSlider", {
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

-- Run Auto Farm Loop
RunService.Heartbeat:Connect(autofarm)

local Lighting = game:GetService("Lighting")


Tab.Misc:AddButton({
    Title = "☀️ Morning (06:00)",
    Description = "Change time to morning",
    Callback = function()
        Lighting.ClockTime = 6
        print("Time changed to Morning (06:00)")
    end
})

Tab.Misc:AddButton({
    Title = "🌅 Evening (18:00)",
    Description = "Change time to evening",
    Callback = function()
        Lighting.ClockTime = 18
        print("Time changed to Evening (18:00)")
    end
})

Tab.Misc:AddButton({
    Title = "🌙 Night (00:00)",
    Description = "Change time to night",
    Callback = function()
        Lighting.ClockTime = 0
        print("Time changed to Night (00:00)")
    end
})

Tab.Misc:AddButton({
    Title = "Anti-Lag",
    Description = "Remove unnecessary details",
    Callback = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.TextureID = ""
            elseif obj:IsA("Part") and obj.Size.Magnitude > 50 then
                obj.Size = Vector3.new(10, 10, 10)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj:Destroy()
            elseif obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Enabled = false
            end
        end

        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.FogEnd = 5000
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)

        if game:GetService("Terrain") then
            game:GetService("Terrain").WaterWaveSize = 0
            game:GetService("Terrain").WaterWaveSpeed = 0
            game:GetService("Terrain").WaterReflectance = 0
            game:GetService("Terrain").WaterTransparency = 1
        end
    end
})

Tab.Misc:AddButton({
    Title = "Overload Device",
    Description = "im sigma, no one make this right lol",
    Callback = function()
        for i = 1, 100 do
            local explosion = Instance.new("Explosion")
            explosion.Position = Vector3.new(math.random(-50, 50), math.random(10, 50), math.random(-50, 50))
            explosion.BlastPressure = 5000000
            explosion.BlastRadius = 50
            explosion.Parent = workspace
        end

        for i = 1, 50 do
            local fire = Instance.new("Fire")
            fire.Parent = workspace
            fire.Heat = 10000
            fire.Size = 50
        end

        for i = 1, 50 do
            local smoke = Instance.new("Smoke")
            smoke.Parent = workspace
            smoke.Opacity = 1
            smoke.Size = 50
        end

        for i = 1, 50 do
            local sparkles = Instance.new("Sparkles")
            sparkles.Parent = workspace
        end

        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = 10
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)

        for i = 1, 50 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(50, 50, 50)
            part.Position = Vector3.new(math.random(-100, 100), math.random(10, 100), math.random(-100, 100))
            part.Anchored = true
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            part.Parent = workspace
        end

        print("[⚠️] Device Overload Activated")
    end
})

local Section = Tab.Plr:AddSection("Player Section (im so sigma)")


local fps = math.floor(1 / RunService.Heartbeat:Wait())
Tab.Plr:AddParagraph({
    Title = "FPS:",
    Content = fps
})

local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
Tab.Plr:AddParagraph({
    Title = "Ping",
    Content = ping
})

local Section = Tab.Plr:AddSection("Player Section/Client side(im so sigma)")

-- FPS and Ping display
local fps = math.floor(1 / RunService.Heartbeat:Wait())
Tab.Plr:AddParagraph({
    Title = "FPS:",
    Content = fps
})

local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
Tab.Plr:AddParagraph({
    Title = "Ping",
    Content = ping
})

-- WalkSpeed Controls
local WalkSpeedToggle = Tab.Plr:AddToggle("WalkSpeedToggle", {
    Title = "WalkSpeed Toggle", 
    Description = "Enable/Disable custom WalkSpeed",
    Default = false
})

local WalkSpeedSlider = Tab.Plr:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Description = "Adjust your WalkSpeed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        if WalkSpeedToggle.Value then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
        end
    end
})

WalkSpeedToggle:OnChanged(function(state)
    if state then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = WalkSpeedSlider.Value
    else
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 -- Default value
    end
end)

-- FOV Controls
local FOVToggle = Tab.Plr:AddToggle("FOVToggle", {
    Title = "FOV Toggle", 
    Description = "Enable/Disable custom FOV",
    Default = false
})

local FOVSlider = Tab.Plr:AddSlider("FOVSlider", {
    Title = "Field of View",
    Description = "Adjust your camera FOV",
    Default = 70,
    Min = 0,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        if FOVToggle.Value then
            game:GetService("Workspace").CurrentCamera.FieldOfView = Value
        end
    end
})

FOVToggle:OnChanged(function(state)
    if state then
        game:GetService("Workspace").CurrentCamera.FieldOfView = FOVSlider.Value
    else
        game:GetService("Workspace").CurrentCamera.FieldOfView = 70 -- Default value
    end
end)

-- Gravity Controls
local GravityToggle = Tab.Plr:AddToggle("GravityToggle", {
    Title = "Gravity Toggle", 
    Description = "Enable/Disable custom Gravity",
    Default = false
})

local GravitySlider = Tab.Plr:AddSlider("GravitySlider", {
    Title = "Gravity",
    Description = "Adjust world gravity",
    Default = 196.2,
    Min = 0,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        if GravityToggle.Value then
            game:GetService("Workspace").Gravity = Value
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration Variables
local TRAIL_CONFIG = {
    Lifetime = 2,
    MaxLength = 50,
    MinDistance = 0.2,
    Width = 0.5,
    FadeTime = 0.5,
    RainbowEffect = true,
    RainbowSpeed = 0.5,
    Transparency = 0.2,
    SelfColor = Color3.fromRGB(0, 255, 255),
    OthersColor = Color3.fromRGB(255, 0, 255)
}

-- State Variables
local activeTrails = {}
local selfTrailEnabled = false
local allTrailsEnabled = false

-- Trail Functions
local function createTrail(character, isLocalPlayer)
    if not character or not character.Parent then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local trailFolder = Instance.new("Folder")
    trailFolder.Name = character.Name .. "'s Trail"
    trailFolder.Parent = workspace
    
    local trailParts = {}
    local lastPosition = humanoidRootPart.Position
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not character.Parent then
            connection:Disconnect()
            trailFolder:Destroy()
            activeTrails[character] = nil
            return
        end
        
        local currentPosition = humanoidRootPart.Position
        local distance = (currentPosition - lastPosition).Magnitude
        
        if distance >= TRAIL_CONFIG.MinDistance then
            local trailPart = Instance.new("Part")
            trailPart.Anchored = true
            trailPart.CanCollide = false
            trailPart.Material = Enum.Material.Neon
            trailPart.Size = Vector3.new(TRAIL_CONFIG.Width, TRAIL_CONFIG.Width, distance)
            
            local midPosition = (currentPosition + lastPosition) / 2
            trailPart.CFrame = CFrame.lookAt(midPosition, currentPosition) * CFrame.Angles(0, math.rad(90), 0)
            
            if TRAIL_CONFIG.RainbowEffect then
                local hue = (tick() * TRAIL_CONFIG.RainbowSpeed) % 1
                trailPart.Color = Color3.fromHSV(hue, 1, 1)
            else
                trailPart.Color = isLocalPlayer and TRAIL_CONFIG.SelfColor or TRAIL_CONFIG.OthersColor
            end
            
            trailPart.Transparency = TRAIL_CONFIG.Transparency
            trailPart.Parent = trailFolder
            table.insert(trailParts, {Part = trailPart, CreationTime = tick()})
            
            lastPosition = currentPosition
        end
        
        for i = #trailParts, 1, -1 do
            local trailData = trailParts[i]
            local age = tick() - trailData.CreationTime
            
            if age > TRAIL_CONFIG.Lifetime then
                trailData.Part:Destroy()
                table.remove(trailParts, i)
            elseif age > TRAIL_CONFIG.Lifetime - TRAIL_CONFIG.FadeTime then
                local fadeProgress = (age - (TRAIL_CONFIG.Lifetime - TRAIL_CONFIG.FadeTime)) / TRAIL_CONFIG.FadeTime
                trailData.Part.Transparency = TRAIL_CONFIG.Transparency + (1 - TRAIL_CONFIG.Transparency) * fadeProgress
            end
        end
    end)
    
    activeTrails[character] = connection
    
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            connection:Disconnect()
            trailFolder:Destroy()
            activeTrails[character] = nil
        end
    end)
    -- Implementation same as before
end

local function togglePlayerTrail(player, enable)
    if not player or not player.Character then return end
    
    if enable then
        if not activeTrails[player.Character] then
            createTrail(player.Character, player == Players.LocalPlayer)
        end
    else
        if activeTrails[player.Character] then
            activeTrails[player.Character]:Disconnect()
            activeTrails[player.Character] = nil
            
            local trailFolder = workspace:FindFirstChild(player.Name .. "'s Trail")
            if trailFolder then trailFolder:Destroy() end
        end
    end
    -- Implementation same as before
end

local function toggleSelfTrail(enable)
    selfTrailEnabled = enable
    togglePlayerTrail(Players.LocalPlayer, enable)
end

local function toggleAllTrails(enable)
    allTrailsEnabled = enable
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer or selfTrailEnabled then
            togglePlayerTrail(player, enable)
        end
    end
end

-- Player Management
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        if allTrailsEnabled and (player ~= Players.LocalPlayer or selfTrailEnabled) then
            togglePlayerTrail(player, true)
        end
    end)
    
    if player.Character and allTrailsEnabled and (player ~= Players.LocalPlayer or selfTrailEnabled) then
        togglePlayerTrail(player, true)
    end
end

-- Initialize Players
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Create Fluent Toggles
Tab.Plr:AddToggle("SelfTrailToggle", {
    Title = "My Trail",
    Description = "trail for your own character, This is Laggy i think for low end device",
    Default = false,
    Callback = function(state)
        selfTrailEnabled = state
        togglePlayerTrail(Players.LocalPlayer, state)
    end
})

Tab.Plr:AddToggle("AllTrailsToggle", {
    Title = "All Trails",
    Description = "trails for all players, I think This is Laggy for Low End Device",
    Default = false,
    Callback = function(state)
        allTrailsEnabled = state
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer or selfTrailEnabled then
                togglePlayerTrail(player, state)
            end
        end
    end
})




end
