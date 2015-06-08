-- This code is under copyright, and is bound to the agreement stated in the EULA.
-- Any 3rd party content has been used as either public domain or with permission.
-- © Copyright 2014 Aritz Beobide-Cardinal All rights reserved.

--ENUMS FOR ARC BANKING SYSTEM!
--137164355

-- Remind me to say when I'm busy --
ARCLib = ARCLib or {}
function ARCLib.RecursiveTableMerge(overwrite,tab)
	if !overwrite then overwrite = {} end
	for k,v in pairs(tab) do
		if istable(v) then
			overwrite[k] = ARCLib.RecursiveTableMerge(overwrite[k],v)
		else
			overwrite[k] = v
		end
	end
	return overwrite
end
function ARCLib.ExpTransition(min,inp,max) -- Picks a random number in an exponential-curve-like way.
	min = min - 1
	local relativemax = max - min
	local relativein = inp - min
	local result = math.Round(2^(relativein/(relativemax*0.30102999566398119521373889472449))*(relativemax/10))
	if result < 1 then
		result = 1
	end
	return result + min
end
function ARCLib.GetPlayerBySteamID(steamid) -- Gets a player by their SteamID
	local ply = {}
	if !isstring(steamid) then return NULL end
	for _, v in pairs( player.GetHumans() ) do
		if v:SteamID() == steamid then
			ply = v
		end
	end
	if !IsValid(ply) then
		function ply:SteamID() return steamid end
		function ply:Nick() return "[Player Offline]" end
		function ply:IsPlayer() return false end
		function ply:IsValid() return false end
	end
	return ply
end

function ARCLib.GetPlayerByUserID(steamid) -- Gets a player by their SteamID
	local ply = {}
	if !isstring(steamid) then return {} end
	for _, v in pairs( player.GetHumans() ) do
		if ARCLib.GetUserID(v) == steamid then
			ply = v;
		end
	end
	if !IsValid(ply) then
		function ply:SteamID() return "STEAM_0:0:0" end
		ply._ARCFakeUserID = steamid
		function ply:Nick() return "[Player Offline]" end
		function ply:IsPlayer() return false end
		function ply:IsValid() return false end
	end
	return ply
end

function ARCBankMsg(msg)
	if ARCBank && ARCBank.Settings && ARCBank.Settings.name then
		Msg(ARCBank.Settings.name..": "..tostring(msg).."\n")
	else
		Msg("ARCBank: "..tostring(msg).."\n")
	end
	if !ARCBank then return end
	if ARCBank.LogFileWritten then
		file.Append(ARCBank.LogFile, os.date("%d-%m-%Y %H:%M:%S").." > "..tostring(msg).."\r\n")
	end
end

ARCBankMsg("Running...\n ____ ____ _ ___ ___     ____ ____ ____ ____ _  _ ____ ____    ___  ____ _  _ _  _ _ _  _ ____ \n |__| |__/ |  |    /     |    |__/ |__| |    |_/  |___ |__/    |__] |__| |\\ | |_/  | |\\ | | __ \n |  | |  \\ |  |   /__    |___ |  \\ |  | |___ | \\_ |___ |  \\    |__] |  | | \\| | \\_ | | \\| |__] \n")
ARCBankMsg(table.Random({"I am emberrased to say that there was a bug since v1.0 that made arguably one of the most important settings useless...","I technically have the biggest back-door in the history of GMod","Super fukin' Sexy edition!","The most realistic ATM system you'll ever see!","Wohoo! Automatic updates!","...I can never get a vacation...","I love you.","Isn't this amazing?","That's one fiiiine addon you got there!","Update, Update, Update!","You can ACTUALLY use an ATM!","Fixin' Bugs!"}))
ARCBankMsg("© Copyright 2014,2015 Aritz Beobide-Cardinal (ARitz Cracker) All rights reserved.")

ARCBank = ARCBank or {}

ARCBank.Update = "May 28th 2015"
ARCBank.Version = "1.3.2"

ARCBank.About = [[      
             *** ARitz Cracker Bank ***
    © Copyright Aritz Beobide-Cardinal 2014,2015
                All rights reserved.
				
				
If you're having any trouble, please visit:
www.aritzcracker.ca
	
Coding, Models, and Custom textures by:
 *    Aritz Beobide-Cardinal (ARitz Cracker) (STEAM_0:0:18610144)
	
ATM Model by:
 *    [Whatever his name is this week] (STEAM_0:1:34654275)

Translations:
 *    n00bmobile + Gm Matsilagi - Brazilian Portuguese
 *    I'm juicy :D + DiaZzZy - French
 *    MindEyes + deinemudda32 - German
 *    (Anonymous) - Spanish
 *    EpicGamesFeed - Russian
 
ALPHA Testers:
 *    Noddy (Senior Crayfish)
 *    Dr Fetus
 *    Quinn50
 *    Toogit
 *    Pookie
 *    Shadow
 *    HomelessGoomba
 *    Foohy
 *    Teh Neon
 *    Gm Matsilagi
 *    Ryuken Ishida
 *    Drew dawg 2000
 *    Slashll
 *    UTNerd24
	
Special Thanks:
 *    Everyone who participated in the public BETA by buying ARCBank before March 31st 2014.
 *    All my great customers, and my future customers.
 *    Noddy (Senior Crayfish) - For inspiring me to create this and place this on CoderHire.
 *    My family - For supporting me.
 *    Snow Lou - Being a great friend, being an amazing girlfriend, believing in me, and for being the best girl a man could ever hope to have.
 *    You - For supporting me by using this addon
	
Originally made for:
Vortex Gaming

]]

--TRANSACTION ERRORS
ARCBANK_ERRORSTRINGS = {}
ARCBANK_ERROR_DOWNLOADING = -2
ARCBANK_ERROR_ABORTED = -1
ARCBANK_ERROR_NONE = 0
ARCBANK_NO_ERROR = 0
ARCBANK_ERROR_NIL_ACCOUNT = 1
ARCBANK_ERROR_NO_ACCESS = 2
ARCBANK_ERROR_NO_CASH = 3
ARCBANK_ERROR_NO_CASH_PLAYER = 4
ARCBANK_ERROR_PLAYER_FOREVER_ALONE = 5
ARCBANK_ERROR_NIL_PLAYER = 6
ARCBANK_ERROR_DUPE_PLAYER = 7
ARCBANK_ERROR_TOO_MUCH_CASH = 8
ARCBANK_ERROR_DEBT = 9
ARCBANK_ERROR_BUSY = 10
ARCBANK_ERROR_TIMEOUT = 11
ARCBANK_ERROR_READ_FAILURE = 12
ARCBANK_ERROR_INVALID_PIN = 13
ARCBANK_ERROR_CHUNK_MISMATCH = 14
ARCBANK_ERROR_CHUNK_TIMEOUT = 15
ARCBANK_ERROR_WRITE_FAILURE = 16
ARCBANK_ERROR_EXPLOIT = 17
ARCBANK_ERROR_DOWNLOAD_FAILED = 18
--CREATION ERRORS
ARCBANK_ERROR_NAME_DUPE = 32
ARCBANK_ERROR_NAME_TOO_LONG = 33
ARCBANK_ERROR_INVALID_NAME = 34
ARCBANK_ERROR_UNDERLING = 35
ARCBANK_ERROR_INVALID_RANK = 36
ARCBANK_ERROR_TOO_MANY_ACCOUNTS = 37
ARCBANK_ERROR_TOO_MANY_PLAYERS = 38
ARCBANK_ERROR_DELETE_REFUSED = 39

--OTHER ERRORS
ARCBANK_ERROR_NOT_LOADED = -127
ARCBANK_ERROR_UNKNOWN = -128

ARCBANK_ERRORBITRATE = 8


--ACCOUNTS
ARCBANK_ACCOUNTSTRINGS = {}
ARCBANK_PERSONALACCOUNTS_ = 0
ARCBANK_ACCOUNTSTRINGS[0] = "invalid" --These are internally handled by the ARCBank system, do not edit these.
ARCBANK_PERSONALACCOUNTS_STANDARD = 1
ARCBANK_ACCOUNTSTRINGS[1] = "standard"
ARCBANK_PERSONALACCOUNTS_BRONZE = 2
ARCBANK_ACCOUNTSTRINGS[2] = "bronze"
ARCBANK_PERSONALACCOUNTS_SILVER = 3
ARCBANK_ACCOUNTSTRINGS[3] = "silver"
ARCBANK_PERSONALACCOUNTS_GOLD = 4
ARCBANK_ACCOUNTSTRINGS[4] = "gold"
ARCBANK_GROUPACCOUNTS_ = 5
ARCBANK_ACCOUNTSTRINGS[5] = "group_invalid"
ARCBANK_GROUPACCOUNTS_STANDARD = 6
ARCBANK_ACCOUNTSTRINGS[6] = "group_standard"
ARCBANK_GROUPACCOUNTS_PREMIUM = 7
ARCBANK_ACCOUNTSTRINGS[7] = "group_premium"
ARCBANK_ACCOUNTBITRATE = 4
ARCBankMsg("Version: "..ARCBank.Version)
ARCBankMsg("Updated on: "..ARCBank.Update)
if SERVER then


	function ARCBankMsgCL(ply,msg)
		--net.Start( "ARCBank_Msg" )
		--net.WriteString( msg )
		if !ply || !ply:IsPlayer() then
			ARCBankMsg(tostring(msg))
		else
			if ARCBank.Settings && ARCBank.Settings.name then
				ply:PrintMessage( HUD_PRINTTALK, ARCBank.Settings.name..": "..tostring(msg))
			else
				ply:PrintMessage( HUD_PRINTTALK, "ARCBank: "..tostring(msg))
			end
			--net.Send(ply)
		end
	end


	hook.Add( "ARCLoad_OnLoaded", "ARCBank Load", function(loaded) ARCBank.Load() end )

end
ARCBankMsg("Loading virtual Lua files...")
