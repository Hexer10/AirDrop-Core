/*
**
*/
#if defined _hexstocks_included
#endinput
#endif
#define _hexstocks_included

#include <cstrike>

/*
INCLUDE MERGE OF MYSTOCKS(shanpu)teamgames-stocks/menu-stocks(KissLick) & some other!
*/

//Easy loops
#pragma deprecated Dont use macro loops
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
#pragma deprecated Dont use macro loops
#define LoopValidClients(%1,%2,%3) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1,%2,%3))

/*************************************** CLIENT ***************************/

/**
 * Check if for a valid client
 *
 *
 * @param client				Client Index
 * @param AllowBots				Allow Bots?
 * @param AllowDead				Allow Dead players?
 * @noreturn
 */
stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/**
 * Checks if user flags (Root is always true)
 *
 *
 * @param client			Client Index
 * @param flags				Flags to check, enter comma to separate flags.
 * @return					True if client has the flags, false otherwise.
 */
stock bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}

/**
 * Checks if user flags
 *
 *
 * @param client			Client Index
 * @param flags				Flags to check, enter comma to separate flags.
 * @return					True if client has the flags, false otherwise.
 */
stock bool CheckAdminFlagEx(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}






/**
 * Get the target client
 *
 * @param client			Client Index
 * @param argnum			Number of the arg
 * @return					Client Index or -1 on failure.
 */
stock int GetTarget(int client, int argnum)
{
	char sTarget[32];
	
	GetCmdArg(argnum, sTarget, sizeof(sTarget));
	return FindTarget(client, sTarget);
}


/** 
 * Get player count of a team
 *
 * @param team				Team (-1 for total)
 * @param alive				Count only alive players?
 * @return					Team Count
 */
stock int GetAliveTeamCount(int team = -1, bool alive = true)
{
	int number = 0;
	for (int i; i <= MaxClients; i++)if (IsPlayerAlive(i) || !alive) && (GetClientTeam(i) == team || team = -1)
		number++;
	return number;
}



/**
 * Get random player of a team
 *
 *
 * @param team				Team, -1 for any
 * @param True				True to include only alive players.
 * @noreturn
 */
stock int GetRandomPlayer(int team = -1, bool OnlyAlive = true)
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (team == -1 || GetClientTeam(i) == team) && (!OnlyAlive || !IsPlayerAlive(i)))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
	
}



/*********************************** NUMBERS *****************************/

/**
 * Checks if an number is even
 *
 *
 * @param num				Number to check
 * @return					True if number is even, false otherwise.
 */
stock bool IsEven(int num)
{
	return (num & 1) == 0;
}

/**
 * Checks if an number is odd
 *
 *
 * @param num				Number to check
 * @return					True if number is odd, false otherwise.
 */
stock bool IsOdd(int num)
{
	return (num & 1) == 1;
}

/********************************** WEAPONS ********************************/


/**
 * Strip All Weapons & the knife slot twice for taser
 *
 *
 * @param client				Client Index
 * @noreturn
 */
stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 4; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
		
	}
	
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1) // strip knife slot 2 times for taser
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}

/** 
 * Gives an Item to a client with custom ammos
 *
 * @param client			Client Index
 * @param weapon			Weapon Name
 * @param clip				Ammo ammount in the clip
 * @param ammo				Total ammo ammount
 * @return					Entity Index
 */
stock int GivePlayerItemAmmo(int client, const char[] weapon, int ammo = -1, int clip = -1)
{
	int weaponEnt = GivePlayerItem(client, weapon);
	
	SetPlayerWeaponAmmo(client, weaponEnt, clip, ammo);
	
	return weaponEnt;
}

/** 
 * Set ammo account for a weapon
 *
 * @param client			Client Index
 * @param weapon			Weapon Index
 * @param clip				Ammo ammount in the clip
 * @param ammo				Total ammo ammount
 * @noreturn
 */
stock void SetPlayerWeaponAmmo(int client, int weaponEnt, int clip = -1, int ammo = -1)
{
	if (clip != -1)
		SetEntProp(weaponEnt, Prop_Data, "m_iClip1", clip);
	if (ammo != -1)
	{
		SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		SetEntProp(weaponEnt, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);
	}
}


/** 
 * Gives an Item to a client removing the current weapon
 *
 * @param client			Client Index
 * @param weapon			
 * @return					Iteam Index
 */
stock int GivePlayerItemRemove(int client, int weapon, int slot)
{
	if ((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	return GivePlayerItem(client, weapon);
}

/****************************** COMMAND ARGS **************************/


/** 
 * Retrives a command argument given its index as int, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Int Value of Arg
 */
stock int GetCmdArgInt(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToInt(value);
}

/** 
 * Retrives a command argument given its index as float, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Float Value of Arg
 */
stock float GetCmdArgFloat(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToFloat(value);
}

/** 
 * Retrives a command argument given its index as bool, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Bool Value of Arg
 */
stock bool GetCmdArgBool(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return view_as<bool>(StringToInt(value));
}

/********************************** CVARS **************************************/

/**
 * Easy silent change of ConVars - Boolean
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
stock void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null)return;
	
	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
	
	SetConVarInt(IntCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}



/**
 * Easy silent change of ConVars - Floats
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
stock void SetCvarFloat(char cvarName[64], float value)
{
	Handle FloatCvar = FindConVar(cvarName);
	if (FloatCvar == INVALID_HANDLE)return;
	
	int flags = GetConVarFlags(FloatCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
	
	SetConVarFloat(FloatCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
}



/**
 * Easy silent change of ConVars - Strings
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
stock void SetCvarString(char cvarName[64], char[] value)
{
	Handle cvar = FindConVar(cvarName);
	SetConVarString(cvar, value, true);
}


/********************************************** ENTITIES *********************************************/


/** 
 * Sets an entity's speed
 *
 * @param entity			Entity Index
 * @param speed				Speed to set
 * @noreturn
 */
stock void SetEntitySpeed(int entity, float speed)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", speed);
}

/** 
 * Gets an entity's Speed
 *
 * @param entity			Entity Index
 * @return					Amount of Speed
 */
stock float GetEntitySpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue");
}



/********************************** MISC *********************************/

/** Reset client Render Color
 *
 * @param client				Client Index
 * @noreturn
 */
stock void ResetRenderColor(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
}


/**
 * Appends a new item to the end of a menu with a format.
 *
 * @param menu				Menu Handle.
 * @param info				Item information string.
 * @param display			Default item display string.
 * @param style				Drawing style flags.  Anything other than DEFAULT or 
 * @param format			Formatting rules
 * @param ...				Variable number of format parameters
 * @return					True on success, false on failure.
 * @error					Invalid Handle or item limit reached.
 */
stock bool AddMenuItemFormat(Handle menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any...)
{
	char display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return AddMenuItem(menu, info, display, style);
}


/**
 * 
 * @param LogFile		Buffer to store the path
 * @param FileName		File to write the log in
 * @param Dir 			Directory/Folder to write the logs in
 * @noreturn
 */
stock void SetLogFile(char LogFile[PLATFORM_MAX_PATH], char[] FileName, char[] Dir)
{
	char sDate[12];
	char sDir[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, LogFile, sizeof(LogFile), "logs/%s", Dir);
	CreateDirectoryEx(Dir);
	
	FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
	Format(LogFile, sizeof(LogFile), "logs/%s/%s-%s.log", Dir, FileName, sDate);
	
	BuildPath(Path_SM, LogFile, sizeof(LogFile), LogFile);
	
	
}


/**
 * Create File without overriding the existing one (if exist)
 *
 * @param file			File Path
 *
 */
stock void CreateFile(const char file[PLATFORM_MAX_PATH])
{
	if (!FileExists(file))
	{
		Handle hFile = OpenFile(file, "w");
		hFile.Close();
		
		if (FileExists(file))
		{
			LogMessage("Create file: %s", file);
		}
		else
		{
			LogError("Could not create: %s", file);
		}
	}
}


/**
 * Create a directory checking if already exist
 *
 * @param file			Directory Path
 *
 */
stock bool CreateDirectoryEx(const char dir[PLATFORM_MAX_PATH])
{
	if (!DirExists(dir))
	{
		CreateDirectory(dir, 511);
		
		if (DirExists(dir))
		{
			LogMessage("Created Directory: %s", dir);
		}
		else
		{
			LogError("Couldn't create folder! (%s)", szPath);
		}
	}
}



/**
 * Kills a Timer and reset its Handle to null
 *
 * @param timer		 Timer Handle to kill
 * @noreturn
 */
stock void StopTimer(Handle &timer)
{
	if (timer != INVALID_HANDLE)
	{
		timer.Close();
		timer = INVALID_HANDLE;
	}
}

/**
 * Get an entity origin
 *
 * @param entity		Entity index.
 * @param origin		Vector to store origin.
 * @noreturn
 */
stock void GetEntityOrigin(int entity, float origin[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
}








/** Prints a message to a specific client in the hud area. !WIP!
 * @param client			Client Index.
 * @param message			Message to send
 * @param holdtime			Number of seconds to hold the text.
 * @param x					x coordinatates from 0 to 1.	-1 is the center.
 * @param y					y coordinatates from 0 to 1.	-1 is the center.
 * @param red				Red color value
 * @param green				Green color value
 * @param blue				Blue color value
 * @param alpha				Alpha transparency value
 * @param fadeIn			Number of seconds to spedd fadingIn
 * @param fadeOut			Number of seconds to spend fadingOut
 * @param channel		A channel number.
 *						If -1, then a channel will automatically be selected 
 *						based on the least-recently-used channel.  If the 
 *						channel is any other number, it will be modulo'd with 
 *						the channel count to get a final channel number.
 * @param fxtime			Duration of the choosen effect(may not apply on all effects)
 * @param effect 		0/1 causes the text to fade in and fade out.
 *						2 causes the text to flash[?].		
 * @param ...
 *
 *
 */
stock int PrintToHud(int client, const char[] message, float holdtime = 5.0, float x = -1.0, float y = -1.0, int red = 255, int green = 255, int blue = 255, int alpha, float fadeIn = 0.2, float fadeOut = 0.1, int channel = -1, float fxTime = 6.0, int effect = 0, any...)
{
	SetHudTextParams(x, y, holdtime, red, green, blue, alpha, 0, fxTime, fadeIn, fadeOut);
	return ShowHudText(client, channel, message);
}


stock int PrintToHudEx(int client, const char[] message, float x = -1.0, float y = -1.0, float holdtime = 0.2, int color[4] =  { 255, 255, 255, 255 }, int channel = -1, any...)
{
	char buffer[256];
	int colors[4];
	VFormat(buffer, sizeof(buffer), message, 8);
	for (int i = 0; i <= 3; i++)
	{
		colors[i] = color[i];
	}
	PrintToHud(client, buffer, holdtime, x, y, colors[0], colors[1], colors[2], colors[3], 0.2, 0.1, channel);
}
