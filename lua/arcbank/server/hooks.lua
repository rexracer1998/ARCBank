-- hooks.lua - Hooks

-- This file is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- � Copyright 2014-2018 Aritz Beobide-Cardinal All rights reserved.
ARCBank.Loaded = false

hook.Add( "PlayerSpawn", "ARCBank UpdateName", function(ply)
	ARCBank.ChangeAccountName(ply,"",ply:Nick(),NULLFUNC)
end	)
hook.Add( "CanTool", "ARCBank Tool", function( ply, tr, tool )
	if IsValid(tr.Entity) then -- Overrides shitty FPP
		if tr.Entity.ARCBank_MapEntity then return false end 
		--[[
		for k, v in pairs(constraint.GetAllConstrainedEntities(tr.Entity)) do
			if v:GetClass() == "sent_arc_pinmachine" && v._Owner == ply then -- Overrides shitty FPP
				return true
			end
		end
		]]
	end
end)
--
hook.Add( "CanPlayerUnfreeze", "ARCBank BlockUnfreeze", function( ply, ent, phys )
	if ent.ARCBank_MapEntity then return false end 
end )
hook.Add( "CanProperty", "ARCBank BlockProperties", function( ply, property, ent )
	if ent.ARCBank_MapEntity then return false end 
end )
hook.Add( "PlayerCanPickupWeapon", "ARCBank HackerPickup", function( ply, wep ) 
	if ARCBank.Settings["atm_hack_allowed_use"] && wep:GetClass() == "weapon_arc_atmhack" then
		local canpickup = false
		for k,v in pairs(ARCBank.Settings["atm_hack_allowed"]) do
			if ply:Team() == _G[v] then
				canpickup = true
				break
			end
		end 
		return canpickup
	end
end)
hook.Add( "PhysgunPickup", "ARCBank NoPhys", function( ply, ent ) 
	if ent.ARCBank_MapEntity then return false end 
	if ent:GetClass() == "sent_arc_atmhack" && ent:GetPos():DistToSqr( ply:GetPos() ) < 9500 then ent:TakeDamage( 200, ply, ply:GetActiveWeapon() ) return true end 
	if ent:GetClass() == "sent_arc_pinmachine" && ent._Owner == ply then -- Overrides shitty FPP
		return true
	end
	for k, v in pairs(constraint.GetAllConstrainedEntities(ent)) do
		if v:GetClass() == "sent_arc_pinmachine" && v._Owner == ply then -- Overrides shitty FPP
			return true
		end
	end
end)
hook.Add("EntityTakeDamage","ARCBank DamageHaxor",function(ent,dmginfo)
	if ent:GetClass() == "sent_arc_atmhack" then return end
	local stuff = ents.FindInSphere(dmginfo:GetDamagePosition(),4)
	local damage = dmginfo:GetDamage() 
	if damage < 10 then
		damage = 30
	end
	for k,v in ipairs(stuff) do
		if v:GetClass() == "sent_arc_atmhack" then
			v:TakeDamage( damage, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
			return true
		end
	end
end)

--[[
-- There was some bug in a very old version of ARCBank that I thought needed this for a second. Now I have no idea what
hook.Add( "PlayerUse", "ARCBank NoUse", function( ply, ent ) 
	if ent != NULL && ent:IsValid() && !ent.IsAFuckingATM && table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
		ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.AtmUse )
		return false
	end 
	if ent.IsAFuckingATM then return true end 
end)
]]

hook.Add( "GravGunPunt", "ARCBank PuntHacker", function( ply, ent ) if ent:GetClass() == "sent_arc_atmhack" then ent:TakeDamage( 100, ply, ply:GetActiveWeapon() ) end end)
hook.Add( "ARCLib_OnPlayerFullyLoaded", "ARCBank PlyAuth", function( ply ) 
	if IsValid(ply) && ply:IsPlayer() then
		if table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
			ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard1 )
		end
		net.Start("arcbank_viewsettings")
		if ARCBank.Settings["atm_darkmode_default"] then
			net.WriteBool(not (not table.HasValue(ARCBank.Disk.EmoPlayers,ARCBank.GetPlayerID(ply)) and table.HasValue(ARCBank.Disk.BlindPlayers,ARCBank.GetPlayerID(ply))))
		else
			net.WriteBool(table.HasValue(ARCBank.Disk.EmoPlayers,ARCBank.GetPlayerID(ply)))
		end
		net.WriteBool(table.HasValue(ARCBank.Disk.OldPlayers,ARCBank.GetPlayerID(ply)))
		net.Send(ply)
		if ply:SteamID64() == "76561197997486016" then
			net.Start("arclib_thankyou")
			net.Send(ply)
		end
	end
	if ARCBank.Settings["card_weapon"] == "weapon_arc_atmcard" then
		timer.Simple(1,function()
			if IsValid(ply) && ply:IsPlayer() && table.HasValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply)) then
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..ARCBank.Msgs.UserMsgs.Eatcard2 )
				ply:Give("weapon_arc_atmcard")
				table.RemoveByValue(ARCBank.Disk.NommedCards,ARCBank.GetPlayerID(ply))
			end
		end)
	end
end)

			
hook.Add( "PlayerDeath", "ARCBank DeathTax", function( victim, inflictor, attacker )
	local amount = ARCBank.PlayerGetMoney(victim)
	if !isnumber(amount) then return end
	local dropped = math.ceil(amount * ARCBank.Settings["death_money_drop"] / 100)
	if dropped > 0 then
		local moneyprop = ents.Create( "sent_arc_cash" )
		moneyprop:SetPos(victim:GetPos()+Vector(0,0,16))
		moneyprop:SetAngles(AngleRand())
		moneyprop:Spawn()
		moneyprop:SetValue(dropped)
		ARCBank.PlayerAddMoney(victim,amount * ARCBank.Settings["death_money_remove"] / -100 )
	end
end)

hook.Add( "PlayerGetSalary", "ARCBank PaydayATM DRP2.4", function(ply, amount)
	if ARCBank.Settings["use_bank_for_payday"] && amount > 0 then
		local pay = ply.DarkRPVars["money"]
		timer.Simple(0.01,function()
			pay = ply.DarkRPVars["money"] - pay 
			if pay <= 0 then return end
			ARCBank.AddFromWallet(ply,"",pay,team.GetName( ply:Team() ),function(errcode)
				if errcode == 0 then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck.." ("..string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(pay) )..")","ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
				elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
				end
			end,ARCBANK_TRANSACTION_SALARY)
		end)
	end
end)

hook.Add( "playerGetSalary", "ARCBank PaydayATM", function(ply, amount)
	if ARCBank.Settings["use_bank_for_payday"] && amount > 0 then
		local pay = ply:getDarkRPVar("money")
		timer.Simple(0.01,function()
			pay = ply:getDarkRPVar("money") - pay 
			if pay <= 0 then return end
			
			
			ARCBank.AddFromWallet(ply,"",pay,team.GetName( ply:Team() ),function(errcode)
				if errcode == 0 then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.Paycheck.." ("..string.Replace( string.Replace( ARCBank.Settings["money_format"], "$", ARCBank.Settings.money_symbol ) , "0", tostring(pay) )..")","ARCBank",ARCBank.Settings.name),NOTIFY_HINT,4,false)
				elseif errcode != ARCBANK_ERROR_NIL_ACCOUNT then
					ARCLib.NotifyPlayer(ply,string.Replace(ARCBank.Msgs.UserMsgs.PaycheckFail,"ARCBank",ARCBank.Settings.name).." ("..ARCBANK_ERRORSTRINGS[errcode]..")",NOTIFY_ERROR,4,true)
				end
			end,ARCBANK_TRANSACTION_SALARY)
		end)
	end
end)

hook.Add( "playerBoughtCustomEntity", "ARCBank PinMachineOwner", function(ply, entTab, ent, price)
	if entTab.ent == "sent_arc_pinmachine" then
		timer.Simple(0.1,function()
			if !IsValid(ent) || !IsValid(ply) then return end
			ent:EmitSound("buttons/button18.wav",75,255)
			ent._Owner = ply
			ent:SetScreenMsg(ARCBank.Settings["name"],string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ))
			if CPPI then -- Prop protection addons
				timer.Simple(0.1,function()
					if IsValid(ent) && IsValid(ply) && ply:IsPlayer() then
						if ent:CPPISetOwner(ply) then
							ARCLib.NotifyPlayer(ply,string.Replace( ARCBank.Msgs.CardMsgs.Owner, "%PLAYER%", ply:Nick() ),NOTIFY_GENERIC,5,true)
						else
							ARCLib.NotifyPlayer(ply,"CPPI ERROR!",NOTIFY_ERROR,5,true)
						end
					end
				end)
				
			end
		end)
	end
end)


hook.Add( "PlayerInitialSpawn", "ARCBank RestoreArchivedAccount", function(ply)
	ARCBank.CapAccountRank(ply)
	if (not _G.nut) then
		ARCBank.ReadUnusedAccounts(ARCBank.GetPlayerID(ply),function(err,accounts)
			if (err ~= ARCBANK_ERROR_NONE) then
				ARCBank.Msg("Failed to restore "..ply:Nick().." ("..ply:SteamID()..") accounts "..ARCBANK_ERRORSTRINGS[err])
				return
			end
			ARCLib.ForEachAsync(accounts,function(k,v,callback)
				ARCBank.RestoreUnusedAccount(v,function(err)
					if (err ~= ARCBANK_ERROR_NONE) then
						ARCBank.Msg("Failed to restore "..ply:Nick().." ("..ply:SteamID()..") account "..v)
					end
					callback()
				end)
			end,NULLFUNC)
		end)
	end
end)
local function keepDeleting(ply,account)
	ARCBank.RemoveAccount(ply,account,"Nutscript Character deleted",function(errcode)
		if errcode == ARCBANK_ERROR_BUSY or errcode == ARCBANK_ERROR_NOT_LOADED then
			timer.Simple(1,function() keepDeleting(ply,account) end)
		end
	end)
end

local function keepRemoveGrouping(ply,account)
	ARCBank.GroupRemovePlayer("__SYSTEM", account, ply, "Nutscript Character deleted", function(errcode)
		if errcode == ARCBANK_ERROR_BUSY or errcode == ARCBANK_ERROR_NOT_LOADED then
			timer.Simple(1,function() keepRemoveGrouping(ply,account) end)
		end
	end)
end

hook.Add("CanPlayerUseChar","ARCBank NutScriptRestoreAccount",function(ply,char)
	local userid = ARCBank.PlayerIDPrefix..char:getID()
	ARCBank.ReadUnusedAccounts(userid,function(err,accounts)
		if (err ~= ARCBANK_ERROR_NONE) then
			ARCBank.Msg("Failed to restore "..userid.." ("..ply:SteamID()..") accounts "..ARCBANK_ERRORSTRINGS[err])
			return
		end
		ARCLib.ForEachAsync(accounts,function(k,v,callback)
			ARCBank.RestoreUnusedAccount(v,function(err)
				if (err ~= ARCBANK_ERROR_NONE) then
					ARCBank.Msg("Failed to restore "..userid.." ("..ply:SteamID()..") account "..v)
					return
				end
			end)
		end,NULLFUNC)
	end)
end)
	
hook.Add("OnCharDelete","ARCBank NutScriptDeleteAccount",function(ply,charid,currentchar)
	if (nut) then
		local userid = ARCBank.PlayerIDPrefix..charid
		keepDeleting(userid,"")
		ARCBank.GetOwnedAccounts(userid,function(errorcode,accounts)
			if errorcode == ARCBANK_ERROR_NONE then
				for k,v in ipairs(accounts) do
					keepDeleting(userid,v)
				end
			else
				ARCBank.Msg("Failed to get list of owned accounts for deleted character "..userid.." - "..ARCBANK_ERRORSTRINGS[errorcode])
			end
		end)
		ARCBank.GetGroupAccounts(ply, function(errorcode, accounts)
			if errorcode == ARCBANK_ERROR_NONE then
				for k,v in ipairs(accounts) do
					keepRemoveGrouping(userid,v)
				end
			else
				ARCBank.Msg("Failed to get list of group accounts for deleted character "..userid.." - "..ARCBANK_ERRORSTRINGS[errorcode])
			end
		end)
	end
end)

local bullshitStopTryingToBreakMyAddons = {
	sent_arc_atm = true,
	sent_arc_atmhack = true,
	sent_arc_atm_creator_prop = true,
	sent_arc_atm_rocket = true,
	sent_arc_cash = true
}
hook.Add( "canPocket", "ARCBank PocketATMs", function(ply,ent)
	if ent.ARCBank_MapEntity then return false end
	if (bullshitStopTryingToBreakMyAddons[ent:GetClass()]) then
		return false,DarkRP.getPhrase("cannot_pocket_x")
	end
end )

hook.Add( "InitPostEntity", "ARCBank SpawnATMs", function()
	ARCBank.SpawnATMs()
end )
hook.Add( "ShutDown", "ARCBank Shutdown", function()
	for _, oldatms in pairs( ents.FindByClass("sent_arc_atm") ) do
		oldatms.ARCBank_MapEntity = false
		--oldatms:Remove()
	end
	ARCBank.SaveDisk()
end)

hook.Add("ARCBank_OnHackBegin","ARCBank OnHackBegin",function(ply,hackent,hackedent,amount,stealth)
	ARCBank.Msg(ply:Nick().." ("..ply:SteamID()..") started hacking "..tostring(hackedent).." for "..amount..". Stealth: "..tostring(stealth))
end)
hook.Add("ARCBank_OnHackSuccess","ARCBank OnHackSuccess",function(ply,hackent,hackedent)
	local msg = ply:Nick().." ("..ply:SteamID()..") successfully hacked "..tostring(hackedent).."."
	if hackedent:GetClass() == "sent_arc_atm" then
		msg = msg.." find user1 == \"__UNKNOWN\" in the transaction logs to see the account that has been hacked."
	end
	ARCBank.Msg(msg)
end)
hook.Add("ARCBank_OnHackBroken","ARCBank OnHackBroken",function(ply,hackent,hero)
	local pNick = "[OFFLINE PLAYER]"
	local pID = "OFFLINE"
	if (IsValid(ply) and ply:IsPlayer()) then
		pNick = ply:Nick()
		pID = ply:SteamID()
	end
	local hNick = "[Invalid Entity]"
	local hID = "NULL"
	if IsValid(hero) then 
		if hero:IsPlayer() then
			hNick = hero:Nick()
			hID = hero:SteamID()
		elseif IsEntity(hero) then
			hID = hero:GetClass()
			hNick = tostring(hero.PrintName or hID)
		end
	end
	ARCBank.Msg(hNick.." ("..hID..") destroyed "..pNick.." ("..pID..")'s hacking device")
end)
hook.Add("ARCBank_OnHackEnd","ARCBank OnHackEnd",function(ply,hackent)
	local pNick = "[OFFLINE PLAYER]"
	local pID = "OFFLINE"
	if (IsValid(ply) and ply:IsPlayer()) then
		pNick = ply:Nick()
		pID = ply:SteamID()
	end
	ARCBank.Msg(pNick.." ("..pID..") stopped hacking.")
end)
--[[

ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT = 1 -- Withdraw/deposit
ARCBANK_TRANSACTION_TRANSFER = 2 -- Transfer
ARCBANK_TRANSACTION_INTEREST = 4 -- Interest
ARCBANK_TRANSACTION_UPGRADE = 8 -- Upgrade
ARCBANK_TRANSACTION_DOWNGRADE = 16 -- Downgrade
ARCBANK_TRANSACTION_GROUP_ADD = 32 -- Add member
ARCBANK_TRANSACTION_GROUP_REMOVE = 64 -- Remove member
ARCBANK_TRANSACTION_CREATE = 128 -- Create
ARCBANK_TRANSACTION_DELETE = 256 -- Delete
]]
hook.Add("ARCBank_OnTransaction","ARCBank OnHackEnd",function(transaction_type,account1,account2,user1,user2,money_difference,money,comment)
	if transaction_type == ARCBANK_TRANSACTION_WITHDRAW_OR_DEPOSIT then
		local msg = ARCBank.GetPlayerByID(user1):Nick().." ("..user1..")"
		if money_difference < 0 then
			msg = msg.." withdrew "..tostring(-money_difference).." from "
		else
			msg = msg.." deposited "..tostring(money_difference).." into "
		end
		ARCBank.Msg(msg..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_TRANSFER then
		ARCBank.Msg(ARCBank.GetPlayerByID(user2):Nick().." ("..user2..") transfered "..money_difference.." to "..ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") "..account2.." -> "..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_INTEREST then
		--We really don't need this
	elseif transaction_type == ARCBANK_TRANSACTION_UPGRADE then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") upgraded account "..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_DOWNGRADE then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") downgraded account "..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_GROUP_ADD then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") added "..ARCBank.GetPlayerByID(user2):Nick().." ("..user2..") to account "..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_GROUP_REMOVE then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") removed "..ARCBank.GetPlayerByID(user2):Nick().." ("..user2..") from account "..account1)
	elseif transaction_type == ARCBANK_TRANSACTION_CREATE then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") created "..account1.." with a starting balance of "..money_difference)
	elseif transaction_type == ARCBANK_TRANSACTION_DELETE then
		ARCBank.Msg(ARCBank.GetPlayerByID(user1):Nick().." ("..user1..") deleted "..account1)
	end
end)