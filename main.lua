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

    plr.Character  = char

    char:BreakJoints()
    _char:BreakJoints()

    bindable_event:Destroy()
    _char:Destroy()

    starter_gui:SetCore("ResetButtonCallback", true)
end

--Functions done.
--Real coding start.

if settings["Physics Tweaks"] then net_functions.physics_tweaks(hum) end

do local hat_names = {}

    for _,v in pairs(hum:GetAccessories()) do
        if hat_names[v.Name] then
            hat_names[v.Name][#hat_names[v.Name] + 1] = true

            v.Name = v.Name .. #hat_names[v.Name]
        else
            hat_names[v.Name] = {}
        end
    end
end --hat renaming function in lua numbers. <hat, hat1, hat2>

char.Archivable = true --Character can"t be cloned otherwise.

for _, inst in pairs(char:GetDescendants()) do
    if inst:IsA("Shirt") or inst:IsA("Pants") or
        inst:IsA("SpecialMesh") or inst:IsA("ForceField")
    then
        inst.Archivable = false
    end
end

_char = char:Clone() --Clones real character, and makes Dummy.
_char:MoveTo(char:FindFirstChildWhichIsA("BasePart").Position)
_char.Parent = workspace

_hum = _char:FindFirstChildWhichIsA("Humanoid")

net_functions.set_hum_state(hum) --Disabled any other humanoid state, and only keeps Physical state.(It is used for limbs collision)

for _,animation_track in pairs(hum:GetPlayingAnimationTracks()) do
    animation_track:Stop()
end

do local animate: LocalScript = char:FindFirstChild("Animate")
    if animate and animate:IsA("LocalScript") then animate.Disabled = true end
end --Disabled Animate LocalScript and disables animations real character is playing.

for _,accessory in pairs(_hum:GetAccessories()) do
    local real_accessory: Accessory = char[accessory.Name]

    local handle: BasePart = accessory:FindFirstChildWhichIsA("BasePart")
    local real_handle: BasePart = real_accessory:FindFirstChildWhichIsA("BasePart")

    if not (handle and real_handle) then accessory:Destroy(); continue end

    handle.Transparency = 1

    net_functions.part_tweaks(real_handle)

    local accessory_weld: Weld = real_handle:FindFirstChildWhichIsA("Weld")

    if accessory_weld then accessory_weld:Destroy() end

    rs_connections[#rs_connections+1],rs_connections[#rs_connections+2] =
    net_functions.stabilize(
        real_handle,
        handle,
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

    local special_mesh: SpecialMesh = handle:FindFirstChildWhichIsA("SpecialMesh")

    if special_mesh then special_mesh:Destroy() end --I just really wanna make sure that nothing errors.
end

for _, part in pairs(_char:GetChildren()) do
    if not (part:IsA("BasePart") and char:FindFirstChild(part.Name)) then continue end

    local real_part: BasePart = char[part.Name]

    for _, motors in pairs(real_part:GetChildren()) do
        if motors:IsA("Motor6D") and motors.Name ~= "Neck" then motors:Destroy() end
    end

    for _,inst in pairs(part:GetChildren()) do
        if inst:IsA("Texture") or inst:IsA("Decal") then inst.Transparency = 1 end
    end

    net_functions.part_tweaks(real_part)

    rs_connections[#rs_connections+1],rs_connections[#rs_connections+2] =
    net_functions.stabilize(
        real_part,
        part,
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

    part.Transparency = 1
end

starter_gui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

char.Parent = workspace.CurrentCamera
plr.Character = _char

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
