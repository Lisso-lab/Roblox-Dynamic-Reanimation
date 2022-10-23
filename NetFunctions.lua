--!strict
local run_service: RunService = game:GetService("RunService")

local debounce = {}

local function do_options(tabl, options)
	if type(tabl) ~= "table" then
		tabl = options
	else
		for index,_ in pairs(options) do
			local val do
				if type(tabl[index]) ~= "nil" then
					val = tabl[index]
				else
					val = options[index]
				end
			end

			tabl[index] = val
		end
	end

	return tabl
end

local net_module = {
	Version = "2.0.0"
}

net_module.sim_rad = function(plr: Player): RBXScriptConnection
	pcall(setscriptable, plr, "SimulationRadius", true)

	return run_service["Heartbeat"]:Connect(function()
		plr.SimulationRadius = 1e+10
		plr.MaximumSimulationRadius = 1e+10
		--Noticed that math.huge does interger overflow, so just in case I do 1e+10.
	end)
end

net_module.part_tweaks = function(part: BasePart, options, cuspp_options)
    options = do_options(options, {
        can_touch = false, --Cannot fire .Touched
        can_query = false, --Cannot be RayCasted
        cast_shadow = false, --If part casts shadow
        root_priority = 127 --Part priority as root
    })

    cuspp_options = do_options(options, {
        density = math.huge, --density
        friction = math.huge, --friction
        elasticity = 0, --elasticity
        friction_weight = math.huge, --friction weight
        elasticity_weight = 0 --elasticity weight
    })

    part.CanTouch = options.can_touch
	part.CanQuery = options.can_query
    part.CastShadow = options.cast_shadow
    part.RootPriority = options.root_priority

    part.CustomPhysicalProperties = PhysicalProperties.new(
		cuspp_options.density,
		cuspp_options.friction,
		cuspp_options.elasticity,
		cuspp_options.friction_weight,
		cuspp_options.elasticity_weight
	)

    pcall(sethiddenproperty, part, "NetworkOwnershipRule", Enum.NetworkOwnership.Manual)
end

---@diagnostic disable-next-line: undefined-type
net_module.physics_tweaks = function(hum: humanoid?)
    if hum then
        pcall(sethiddenproperty, "InternalBodyScale", Vector3.one * 9e99)
    end

    pcall(sethiddenproperty, workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Disabled)
    pcall(sethiddenproperty, workspace, "PhysicsSimulationRate", Enum.PhysicsSimulationRate.Fixed240Hz)
    pcall(sethiddenproperty, workspace, "PhysicsSteppingMethod", Enum.PhysicsSteppingMethod.Fixed)

    pcall(function()
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        settings().Physics.AllowSleep = false
        settings().Rendering.EagerBulkExecution = true
        settings().Physics.ForceCSGv2 = false
        settings().Physics.DisableCSGv2 = true
        settings().Physics.UseCSGv2 = false
    end)
end

net_module.set_hum_state = function(hum: Humanoid, state: Enum?)
    for _,v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
        if v == (state or Enum.HumanoidStateType.Physics) then continue end

        pcall(function() hum:SetStateEnabled(v, false) end)
    end

    hum:ChangeState(state or Enum.HumanoidStateType.Physics)
end

net_module.l_collision_disable_model = function(model: Model, options)
    options = do_options(options, {
        noclip_hats = true,
        do_gd = false,
    })

    local func do
        if options.do_gd then
            func = function()
                for _,v in pairs(model:GetDescendants()) do
                    if v.Parent:IsA("Accessory") and options.noclip_hats then
                        v.CanCollide = false
                    elseif v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        else
            func = function()
                for _,v in pairs(model:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    elseif v:IsA("Accessory") and options.noclip_hats then
                        local handle = v:FindFirstChildWhichIsA("BasePart")

                        if handle then handle.CanCollide = false end
                    end
                end
            end
        end
    end

    return run_service["Stepped"]:Connect(func)
end

net_module.calc_vel = function(part: BasePart, part_to: BasePart?, hum: Humanoid?, model: Model, options): Vector3
    options = do_options(options, {
        st_vel = Vector3.new(0,50,0), --Stational Velocity
        dv_multiplier = 50, --Dynamic Velocity multiplier
        dv_debounce = .1, --Dynamic Velocity debounce
        rv_multiplier = 5,  --Rotational Velocity multiplier
    })

    if not debounce[part.Name] then
        if part.Name == "Handle" then
            if not debounce[part.Parent.Name] then
                debounce[part.Name] = {0,Vector3.one}
            end
        else
            debounce[part.Name] = {0,Vector3.one}
        end
    end

    local vel, rotvel: Vector3 do
        local d_info do
            if debounce[part.Name] then
                d_info = debounce[part.Name]
            else
                d_info = debounce[part.Parent.Name]
            end
        end

        if not hum or hum.MoveDirection.Magnitude == 0 then
            if tick() - d_info[1] < options.dv_debounce then
                vel = d_info[2] + (model and Vector3.yAxis * (model.PrimaryPart.AssemblyLinearVelocity.Y + 26) or Vector3.one)
            else
                vel = options.st_vel + (model and Vector3.yAxis * model.PrimaryPart.AssemblyLinearVelocity.Y or Vector3.one)
            end
        else
            if tick() - d_info[1] < options.dv_debounce and hum.MoveDirection ~= d_info[2] then
                vel = hum.MoveDirection * options.dv_multiplier + (model and Vector3.yAxis * (model.PrimaryPart.AssemblyLinearVelocity.Y + 26) or Vector3.one)
            else
                vel = hum.MoveDirection * options.dv_multiplier + (model and Vector3.yAxis * model.PrimaryPart.AssemblyLinearVelocity.Y or Vector3.one)

                d_info[1] = tick()
                d_info[2] = hum.MoveDirection
            end
        end

        if part_to then
            rotvel = part_to.AssemblyAngularVelocity * options.rv_multiplier
        else
            rotvel = Vector3.zero
        end
    end

    return vel,rotvel
end

net_module.radless = function(part: BasePart, part_to: BasePart?, hum: Humanoid?, model: Model?, options): RBXScriptConnection
    options = do_options(options, {
        st_vel = Vector3.new(0,50,0), --Stational Velocity
        dv_multiplier = 50, --Dynamic Velocity multiplier
        dv_debounce = .05, --Dynamic Velocity debounce
        rv_multiplier = 5,  --Rotational Velocity multiplier
    })

    return run_service["Heartbeat"]:Connect(function()
        local vel, rotvel: Vector3 = net_module.calc_vel(
            part,
            part_to,
            hum,
            model, {
                st_vel = options.st_vel,
                dv_multiplier = options.dv_multiplier,
                dv_debounce = options.dv_debounce,
                rv_multiplier = options.rv_multiplier
            }
        )

        part:ApplyImpulse(vel)
        part:ApplyAngularImpulse(rotvel)

        part.AssemblyLinearVelocity = vel
        part.RotVelocity = rotvel
    end)
end

net_module.stabilize = function(part: BasePart, part_to: BasePart, hum: Humanoid?, model: Model?, options): RBXScriptConnection
    options = do_options(options, {
        apply_vel = true, --Apply velocity to stabilized part
        cf_offset = CFrame.new(0,0,0), --For offseting...
        st_vel = Vector3.new(0,50,0), --Static Velocity
        dv_debounce = .05, --Dynamic Velocity debounce
        dv_multiplier = 50, --Dynamic Velocity multiplier
        stabilize_method = "cframe", --Can use Position or CFrame
        calc_rotvel = part_to and true or false, --If rotvel calculation is enabled(otherwise 0,0,0)
        rv_multiplier = 5,  --Rotational Velocity multiplier
    })

    if options.stabilize_method == "position" then
        local pos: Vector3 = options.cf_offset.Position
        if pos == Vector3.zero then pos = Vector3.one end

        local X,Y,Z = options.cf_offset:ToOrientation()

        options.cf_offset = {
            options.cf_offset.Position,
            Vector3.new(math.deg(X),math.deg(Y),math.deg(Z))
        }
    end

    local rs_connection, hb_connection: RBXScriptConnection do
        rs_connection = run_service["RenderStepped"]:Connect(function()
            if options.stabilize_method == "position" then
				part.Position = part_to.Position + options.cf_offset[1]
				part.Orientation = part_to.Orientation + options.cf_offset[2]
            else
                part.CFrame = part_to.CFrame * options.cf_offset
            end
        end)

        hb_connection = run_service["Heartbeat"]:Connect(function()
            if options.stabilize_method == "position" then
				part.Position = part_to.Position + options.cf_offset[1]
				part.Orientation = part_to.Orientation + options.cf_offset[2]
            else
                part.CFrame = part_to.CFrame * options.cf_offset
            end

            if not options.apply_vel then return end

            local vel, rotvel: Vector3 = net_module.calc_vel(
                part,
                options.calc_rotvel and part_to or nil,
                hum,
                model, {
                    st_vel = options.st_vel,
                    dv_multiplier = options.dv_multiplier,
                    dv_debounce = options.dv_debounce,
                    rv_multiplier = options.rv_multiplier
                }
            )

            part:ApplyImpulse(vel)
            part:ApplyAngularImpulse(rotvel)
            --The order matters
            part.AssemblyLinearVelocity = vel
            part.RotVelocity = rotvel

            if options.stabilize_method == "position" then
				part.Position = part_to.Position + options.cf_offset[1]
				part.Orientation = part_to.Orientation + options.cf_offset[2]
            else
                part.CFrame = part_to.CFrame * options.cf_offset
            end
        end)
    end

    return rs_connection,hb_connection
end

return net_module -- This was made by Iss0, Iss0#2367 or SkiuulLPcz (and not modified by me in any way shape or form, all credit goes to Iss0)
