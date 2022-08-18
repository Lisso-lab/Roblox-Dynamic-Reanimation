--!strict
local run_service: RunService = game:GetService("RunService")
local starter_gui: StarterGui = game:GetService("StarterGui")

local plr: Player = game:GetService("Players").LocalPlayer

local char, _char: Model = plr.character or workspace[plr.Name]
local hum, _hum: Humanoid = char:FindFirstChildWhichIsA("Humanoid")

local bindable_event: BindableEvent --Used for hooking reset button.
local r_func_disconnecting: boolean = false
local debounce_tick: number = 0

local rs_connections = {} --RunService connections.

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
    ["Calculate RotVelocity"] = true, --[[Calculate RotVelocity: If RotVelocity is used correctly, it can
        Help with maintaining ownership, with no visual displeasures.(no jitter)
    ]]
    ["Move Hats Head"] = false, --Move Hats Head: Hats on head will or will not move as if head didn't have neck.
    ["Jump Velocity"] = true, --Jump Velocity: Adds jumping velocity to Velocity. Recommended
    ["Dummy Noclip"] = true,  --Dummy Noclip: makes you noclipped WHILE being reanimated.
    ["St Velocity"] = Vector3.new(0,50,0), --Stationary Velocity: Velocity when no movement.
    ["Dv Amplifier"] = 50,   --Dynamic Velocity amplifier: multiplies dynamic velocity. ?
    ["Dv Debounce"] = .05,   --Dynamic Velocity Debounce. Does dynamic velocity overtime until Tick() - Debounce > this.
    ["Rv Amplifier"] = 5     --RotVelocity Amplifier: multiplies Rotational Velocity
}

local net_functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lisso-lab/NetModule/main/main.lua"))()

--Defining done.
--Functions start.

local function reset_func()
    if r_func_disconnecting then return end
    r_func_disconnecting = true

    for i=1,#rs_connections do
        rs_connections[i]:Disconnect()
    end --Disconnects all connections

    plr.Character = char

    char:BreakJoints(); _char:BreakJoints()

    bindable_event:Destroy()

    char:Destroy(); _char:Destroy()

    starter_gui:SetCore("ResetButtonCallback", true)
end

local function process_pats(inst) --BasePart | Accessory doesnt work smh
    local real_inst = char[inst.Name] --BasePart | Accessory doesnt work smh

    if inst:IsA("Accessory") then
        inst = inst:FindFirstChildWhichIsA("BasePart")
        real_inst = real_inst:FindFirstChildWhichIsA("BasePart")
    end

    for _, desc in pairs(real_inst:GetChildren()) do
        if desc:IsA("Motor6D") and desc.Name ~= "Neck" then desc:Destroy() end

        if not desc:IsA("Weld") then continue end

        if settings["Move Hats Head"] then 
            desc:Destroy()
        else
            if not string.lower(desc.Part1.Name) == "head" then desc:Destroy() end
        end
    end

    for _, desc in pairs(inst:GetChildren()) do
        if desc:IsA("Texture") or desc:IsA("Decal") then desc.Transparency = 1 end
    end

    inst.Transparency = 1

    net_functions.part_tweaks(real_inst)

    rs_connections[#rs_connections+1],rs_connections[#rs_connections+2] =
    net_functions.stabilize(
        real_inst,
        inst,
        _hum,
        {
            st_vel = settings["St Velocity"],
            dv_debounde = settings["Dv Debounce"],
            dv_amplifier = settings["Dv Amplifier"],
            rv_amplifier = settings["Rv Amplifier"],
            dynamic_vel = settings["Dynamic Velocity"],
            calc_rotvel = settings["Calculate RotVelocity"]
        }
    )
end

--Functions done.
--Real coding start.

if settings["Physics Tweaks"] then net_functions.physics_tweaks(hum) end

char.Archivable = true --Character can"t be cloned otherwise.

for _, inst in pairs(char:GetDescendants()) do
    if inst:IsA("Shirt") or inst:IsA("Pants") or inst:IsA("CharacterMesh") or
       inst:IsA("SpecialMesh") or inst:IsA("ForceField") then
        inst.Archivable = false
    end
end

do local hat_names = {}

    for _,accessory in pairs(hum:GetAccessories()) do
        if hat_names[accessory.Name] then
            hat_names[accessory.Name][#hat_names[accessory.Name] + 1] = true

            accessory.Name = accessory.Name .. #hat_names[accessory.Name]
        else
            hat_names[accessory.Name] = {}
        end
    end
end --hat renaming function in lua numbers. <hat, hat1, hat2>

_char = char:Clone() --Clones real character, and makes Dummy.
_char:MoveTo(char:FindFirstChildWhichIsA("BasePart").Position)
_char.Parent = workspace

_hum = _char:FindFirstChildWhichIsA("Humanoid")

hum:ChangeState(Enum.HumanoidStateType.Physics)

for _, inst in pairs(_char:GetChildren()) do
    if inst:IsA("BasePart") or inst:IsA("Accessory") then process_pats(inst) end
end

for _,animation_track in pairs(hum:GetPlayingAnimationTracks()) do
    animation_track:Stop()
end

do local animate: LocalScript = char:FindFirstChild("Animate")
    if animate and animate:IsA("LocalScript") then animate.Disabled = true end
end --Disabled Animate LocalScript and disables animations real character is playing.

starter_gui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

plr.Character = _char

char.Parent = workspace.CurrentCamera

starter_gui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)

workspace.CurrentCamera.CameraSubject = _hum

bindable_event = Instance.new("BindableEvent")
bindable_event.Event:Connect(reset_func)

--Real coding end.
--RBXConnections

starter_gui:SetCore("ResetButtonCallback", bindable_event)

if settings["Legacy Net"] then 
    rs_connections[#rs_connections + 1] = net_functions.sim_rad(plr)
end
if settings["Dummy Noclip"] then
    rs_connections[#rs_connections + 1] = net_functions.disable_collisions_model(_char)
end

rs_connections[#rs_connections + 1] = net_functions.disable_collisions_model(char)
rs_connections[#rs_connections + 1] = plr.CharacterRemoving:Connect(reset_func)
rs_connections[#rs_connections + 1] = _hum.Died:Connect(reset_func)
