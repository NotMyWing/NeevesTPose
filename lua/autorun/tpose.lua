hook.Add("Initialize", "T-Pose Init", function()
	MsgC(Color( 255, 0, 0 ), "[Neeve's TTT T-Pose]", Color(255, 255, 255), "Thanks for installing Neeve's TTT T-Pose!\n")

	local WEAPON_CLASS = "weapon_ttt_unarmed"
	if not weapons.Get("weapon_ttt_unarmed") then
		return
	end

	if SERVER then
		hook.Add("Think", "T-Pose Think", function()
			for _, ply in pairs(player.GetAll()) do
				local weap = ply:GetActiveWeapon()
	
				if (not IsValid(weap) or (weap:GetClass() ~= WEAPON_CLASS)) and ply:GetNWBool("T-Posing") then
					ply:SetNWBool("T-Posing", false)
				end
			end
		end)
	
		hook.Add("KeyPress", "T-Pose KeyPress", function(ply, key)
			local weap = ply:GetActiveWeapon()
	
			if IsValid(weap) and (weap:GetClass() == WEAPON_CLASS) and (key == IN_ATTACK2) then
				timer.Simple(0, function()
					ply:SetNWBool("T-Posing", not ply:GetNWBool("T-Posing"))
					ply:SetNWFloat("T-Pose Start", CurTime())
				end)
			end
		end)
	else
		local pow = math.pow
		local sCurve = function(x, p, s)
			if p == nil then
				p = 0.5
			end
	
			if s == nil then
				s = 0.75
			end
	
			local c = (2 / (1 - s)) - 1
			if (x <= p) then
				return pow(x, c) / pow(p, c - 1)
			else
				return 1 - (pow(1 - x, c) / pow(1 - p, c - 1))
			end
		end
	
		hook.Add("PrePlayerDraw", "T-Pose Player Translucency", function(ply)
			if (ply ~= LocalPlayer()) then
				return
			end
	
			if ply.__tPoseLerp and ply.__tPoseLerp ~= 0 then
				local blend = sCurve(ply.__tPoseLerp, 0.5, 0.5)
				if blend > 0.95 then
					blend = 1
				end
				render.SetBlend(blend) 
			end
		end)
		
		hook.Add("CalcView", "T-Pose CalcView", function (ply, pos, angles, fov)
			if (ply ~= LocalPlayer()) then
				return
			end
	
			if ply:GetNWBool("T-Posing") and (ply.__tPoseLerp or 0) < 1 then
				ply.__tPoseLerp = math.min(1, (ply.__tPoseLerp or 0) + FrameTime() * 2)
			elseif not ply:GetNWBool("T-Posing") and (ply.__tPoseLerp or 0) > 0 then
				ply.__tPoseLerp = math.max(0, (ply.__tPoseLerp or 0) - FrameTime() * 2)
			end
	
			if ply.__tPoseLerp and ply.__tPoseLerp ~= 0 then
				local view = {}
			
				view.origin = pos - (angles:Forward() * sCurve(ply.__tPoseLerp, 0.5, 0.5) * 80)
				view.angles = angles
				view.fov = fov
				view.drawviewer = true
			
				return view
			end
		end)
	
		local removeHUDHelp = function()
			local ply = LocalPlayer()
	
			if IsValid(ply) then
				local weap = ply:GetActiveWeapon()
				if ply:GetNWBool("T-Posing") and IsValid(weap) and (weap:GetClass() == WEAPON_CLASS) then
					weap.HUDHelp = nil
	
					timer.Remove("T-Pose AddHUDHelp")
				end
			end
		end
	
		timer.Create("T-Pose AddHUDHelp", 1, 0, function()
			local ply = LocalPlayer()
	
			if IsValid(ply) then
				local weap = ply:GetActiveWeapon()
				if IsValid(weap) and (weap:GetClass() == WEAPON_CLASS) then
					if weap.AddHUDHelp and not weap.HUDHelp then
						timer.Create("T-Pose AddHUDHelp", 1, 0, removeHUDHelp)
	
						weap:AddHUDHelp("tpose_switch", nil, true)
					end
				end
			end
		end)
	end
	
	hook.Add("CalcMainActivity", "T-Pose Anim", function(ply)
		if ply:GetNWBool("T-Posing") and (CurTime() - ply:GetNWFloat("T-Pose Start")) > 0.15 then
			return ACT_INVALID, ACT_INVALID    
		end
	end)
	
	hook.Add("SetupMove", "T-Pose No Crouch", function(ply, mvd, cmd)
		if ply:GetNWBool("T-Posing") and mvd:KeyDown(IN_DUCK) then
			mvd:SetButtons(bit.band(mvd:GetButtons(), bit.bnot(IN_DUCK)))
		end
	end)	
end)