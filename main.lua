--!strict
local run_service: RunService = game:GetService("RunService")

local plr: Player = game:GetService("Players").LocalPlayer

local char, _char: Model = plr.Character or workspace[plr.Name]
local hum, _hum: Humanoid = char:FindFirstChildWhichIsA("Humanoid")
local bindable_event: BindableEvent --Used for hooking reset button.
--Making locals _char and _hum here so that they can be used in any local function.

local connected_loops = {} --RunService connections.

local settings = {
    ["Legacy Net"] = true, --[[Legacy net: Setting Simulation radius to massive number.
        While simulation radius gets locked to 1k on server, setting high number has >possible< local improvements.
    ]]
    ["Physics Tweaks"] = true, --[[Physics Tweaks: Various game Physics tweaks
        Such as disabling NetworkSleeping, etc. Recommended to use, but the option is here :)
    ]]
    ["Dynamic Velocity"] = true, --[[Dynamic Velocity: Applies velocity in the direction you are moving
        to eliminate Jittering.
    ]]
    ["Apply RotVelocity"] = true, --[[Apply RotVelocity: If RotVelocity is used correctly, it can
        Help with maintaining ownership, with no visual displeasures.(no jitter)
    ]]
    ["Jump Velocity"] = true, --Jump Velocity: Adds jumping velocity to Velocity. Recommended
    ["Dummy Noclip"] = true, --Dummy Noclip: makes you noclipped WHILE being reanimated.
    ["St Velocity"] = Vector3.new(100,100,100), --Stationary Velocity: Velocity when no movement.
    ["Dv Amplifier"] = 15, --Dynamic Velocity amplifier: multiplies dynamic velocity. ? Minimum? To test!
    ["Rv Amplifier"] = 3 --RotVelocity Amplifier: multiplies Rotational Velocity. Small number recommended!
}

--[[
Defining done.
Functions start.
--]]

local function movedir_calculation(move_direction): Vector3
    if not ((move_direction * settings["Dv Amplifier"]).Magnitude > 30) then
        --[[If multiplied MoveDirection doesn't reach minimal velocity which
            can maintain parts and hats, this check passes. (26 is absolute minimum but thats too much)
        ]]

        if fixing_dv_amplifier then return move_direction * settings["Dv Amplifier"] end

        fixing_dv_amplifier = true
        --Makes global so that this fix doesn't run multiple times(RunService loop)

        while task.wait() do
            settings["Dv Amplifier"] += 4

            if (move_direction * settings["Dv Amplifier"]).Magnitude > 30 then
                warn("Dv Amplifier wasnt set high enough to maitain parts. Dv Amplifier was set to: ", settings["Dv Amplifier"])

                break
            end
        end
        --adds 4 to Dynamic Velocity Amplifier every iteration of this loop. if check doesnt passes, it repeats.

        fixing_dv_amplifier = false
        return move_direction
    end

    return (move_direction * settings["Dv Amplifier"])
    --This doesnt run, if the check is triggered.
end

local function rotvel_calculation(rot_velocity): Vector3
    return rot_velocity * settings["Rv Amplifier"]
end

local function stabilize(part, part_to, cframe)
    connected_loops[#connected_loops + 1] =
    run_service["RenderStepped"]:Connect(function()
        part.CFrame = part_to.CFrame

        part.CFrame = cframe and part_to.CFrame * cframe or part_to.CFrame
        --This is tenary. If you don't know tenary, you should check tenary out ^^.
    end)
    --Using RenderStepped because it is rendered before camera. Which is what we want.

    connected_loops[#connected_loops + 1] =
    run_service["Heartbeat"]:Connect(function()
        part.CFrame = part_to.CFrame

        part.CFrame = cframe and part_to.CFrame * cframe or part_to.CFrame

        local velocity,rot_vel: Vector3 do 
            local st_vel: Vector3 = settings["St Velocity"]
            local jump_vel do
                if settings["Jump Velocity"] then
                    if _char:FindFirstChild("HumanoidRootPart") then 
                        jump_vel = true 
                    else
                        settings["Jump Velocity"] = false
                    end
                end
            end
            --This is done just in case Dummy looses HumanoidRootPart by any way.

            if _hum.MoveDirection.Magnitude == 0 or not settings["Dynamic Velocity"] then
                velocity = Vector3.new(
                    st_vel.X,
                    st_vel.Y + (jump_vel and  _char:FindFirstChild("HumanoidRootPart").Velocity.Y or 0),
                    st_vel.Z
                )
            else
                velocity = movedir_calculation(_hum.MoveDirection) + Vector3.new(0,15,0)
            end

            if settings["Apply RotVelocity"] then
                rot_vel = rotvel_calculation(part_to.RotVelocity)
            else
                rot_vel = Vector3.zero
            end
        end

        part:ApplyImpulse(velocity)
        part.AssemblyLinearVelocity = velocity

        part:ApplyAngularImpulse(rot_vel)
        part.RotVelocity = rot_vel
    end)
    --[[Heartbeat loop is used because it runs right after physics. 
        Therefore any set velocity by game gets immediately replaced.
    ]]

    print(string.format("Stabilizing: " ..part_to.Name))
end

local function part_tweaks(part)
    part.CanTouch = false --Cannot fire .Touched
    part.CanQuery = false --Cannot be RayCasted
    part.RootPriority = 127

    part.CustomPhysicalProperties = PhysicalProperties.new(
        math.huge, --density
        math.huge, --friction
        0,         --elasticity
        math.huge, --friction weight
        0          --elasticity weight
    )
    --some of these factors should in theory help with not loosing network ownership.

    sethiddenproperty(
        part,
        "NetworkOwnershipRule",
        Enum.NetworkOwnership.Manual
    )
end

local function collision()
        for _,v in pairs(char:GetChildren()) do
        if not v:IsA("BasePart") then continue end

        v.CanCollide = false
    end
    --Disables collisions on real character

    hum:ChangeState(Enum.HumanoidStateType.Physics)
    --Included here because it affects server-sided collision of limbs.

    if not settings["Dummy Noclip"] then return end
    --Checks if we want to have collisions disabled on dummy.

    for _,v in pairs(_char:GetChildren()) do
        if not v:IsA("BasePart") then continue end

        v.CanCollide = false
    end
    --Disables collisions on dummy
end

local function reset_func()
    if reset_func_disconnecting then return end
    --We must have this check, becuase .CharacterRemoving fires alot of times after death.

    reset_func_disconnecting = true

    for i=1,#connected_loops do
        connected_loops[i]:Disconnect()
    end
    --Disconnects all loops

    plr.Character  = char

    char:BreakJoints()

    bindable_event:Destroy()
    _char:Destroy()

    print("Disconnected: ", #connected_loops, " loops.")

    game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)
    --this sets button so that we can reset normally.

    wait(1)
    reset_func_disconnecting = false
    --We must make sure that .CharacterRemoving stops sending death threats.

    print("Reset function completed.")
end

local legacy_net do
    if settings["Legacy Net"] then
        setscriptable(plr, "SimulationRadius", true)
        setscriptable(plr, "MaximumSimulationRadius", true)
        --Why use sethiddenproperties when you can use setscriptable? Aha!

        function legacy_net()
            plr.SimulationRadius = 1e+10
            plr.MaximumSimulationRadius = 1e+10
            --Noticed that math.huge does interger overflow, so just in case I do 1e+10.
        end

    end
end

--This is done so that it only creates function if its enabled... Overkill I know.

--[[
Functions done.
Real coding start.
--]]

if settings["Physics Tweaks"] then
    sethiddenproperty(workspace,
        "HumanoidOnlySetCollisionsOnStateChange", 
        Enum.HumanoidOnlySetCollisionsOnStateChange.Disabled
    )

    sethiddenproperty(workspace,
        "InterpolationThrottling", 
        Enum.InterpolationThrottlingMode.Disabled
    )

    sethiddenproperty(hum,
        "InternalBodyScale",
        Vector3.new(9e99, 9e99, 9e99)
    )
    --While I was searching for hiddenproperties I found these. I tested them and they do help with network ownership.

    pcall(function()
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        settings().Physics.AllowSleep = false
        settings().Rendering.EagerBulkExecution = true
        settings().Physics.ForceCSGv2 = false
        settings().Physics.DisableCSGv2 = true
        settings().Physics.UseCSGv2 = false
    end)
    --Typical Physics tweaks. They are in pcall, because synapse x sometimes gives error. No idea why.

    plr.ReplicationFocus = workspace
end

char.Archivable = true
--Character can"t be cloned otherwise.

do
    local hat_names = {}

    for _,v in pairs(hum:GetAccessories()) do
        if hat_names[v.Name] then
            hat_names[v.Name][#hat_names[v.Name] + 1] = v
            --Adds 1 to table UNDER hat_names that is called the hat name.

            v.Name = v.Name .. #hat_names[v.Name]

        else
            hat_names[v.Name] = {}
            --If it doesnt find the hat in hat_names it creates entry for it.
        end
    end
end
--hat renaming function in lua numbers. <hat, hat1, hat2>
--<do end> scope is used so that tables like hat_names gets garbage collected.

_char = char:Clone()
_char.Parent = workspace
_char:MoveTo(char.Head.Position)
--Clones real character, and makes Dummy.

_hum = _char:FindFirstChildWhichIsA("Humanoid")

for _,v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
    if v == Enum.HumanoidStateType.Physics then continue end

    pcall(function()
        hum:SetStateEnabled(v, false)
    end)
end
--Disabled any other humanoid state, and only keeps Physical state.(It is used for limbs collision)

for _,v in pairs(hum:GetPlayingAnimationTracks()) do
    v:Stop()
end

do
    local animate: LocalScript = char:FindFirstChild("Animate")

    if animate then animate.Disabled = true end
end
--Disabled Animate LocalScript and disables animations real character is playing.

for _,accessory in pairs(_hum:GetAccessories()) do
    local real_accessory: Accessory = char:FindFirstChild(accessory.Name)

    if not real_accessory then accessory:Destroy() end

    local handle: BasePart = accessory:FindFirstChildWhichIsA("BasePart")
    local real_handle: BasePart = real_accessory:FindFirstChildWhichIsA("BasePart")

    if not handle or not real_handle then continue end

    handle.Transparency = 1

    local accessory_weld: Weld = real_handle:FindFirstChildWhichIsA("Weld")

    if not accessory_weld then continue end
    
    accessory_weld:Destroy()

    stabilize(real_handle,handle)

    local special_mesh: SpecialMesh = handle:FindFirstChildWhichIsA("SpecialMesh")

    if not special_mesh then continue end

    special_mesh:Destroy()
    --I just really wanna make sure that nothing errors.
end
--Done to hide meshses.

for _,v in pairs(_char:GetChildren()) do
    if v:IsA("ForceField") then
        v:Destroy()
    end
    --Sometimes forcefield stays in character, and then is copied to Dummy.

    if not v:IsA("BasePart") or not char:FindFirstChild(v.Name) then continue end

    local real_part: BasePart = char[v.Name]

    for _,v1 in pairs(real_part:GetChildren()) do
        if not v1:IsA("Motor6D") or v1.Name == "Neck" then continue end

        print("Destroying Motor:", v1)

        v1:Destroy()
        --Removes any Motor6D's from every part in real character except Neck.
    end

    for _,v1 in pairs(v:GetChildren()) do
        if v1:IsA("Texture") or v1:IsA("Decal") then
            v1.Transparency = 1
            --Makes things transparent like face.
        end
    end

    part_tweaks(real_part)

    stabilize(real_part, v)
    --This is where it does the thing!

    v.Transparency = 1
end

--[[
Cleaning, Stabilizing done.
Finalizing start.
--]]

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
--Disabling health is  done just for visual pleasure.

char.Parent = workspace.CurrentCamera
plr.Character = _char

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)

workspace.CurrentCamera.CameraSubject = _hum

bindable_event = Instance.new("BindableEvent")
bindable_event.Event:Connect(reset_func)

--[[
Finalizing done.
Connections Start.
--]]

game:GetService("StarterGui"):SetCore("ResetButtonCallback", bindable_event)

connected_loops[#connected_loops + 1] = plr.CharacterRemoving:Connect(reset_func)
connected_loops[#connected_loops + 1] = run_service["Stepped"]:Connect(collision)
connected_loops[#connected_loops + 1] = run_service["Heartbeat"]:Connect(legacy_net)
