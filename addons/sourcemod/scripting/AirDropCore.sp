#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <hexstocks>
#include <airdrop>

#pragma semicolon 1
#pragma newdecls required


ConVar cv_sBoxPath;
ConVar cv_sParaPath;
ConVar cv_fMaxDistance;
ConVar cv_fLandDistance;
ConVar cv_sLandBeam;
ConVar cv_bCheckSolid;
ConVar cv_fSpeedMult;

ArrayList Array_BoxEnt;
ArrayList Array_BoxRunningEnt;
ArrayList Array_BoxRunningEntZ;

Handle gF_OnAirDropCalled;
Handle gF_OnBoxUsed;

int iBeamSprite;
int iHaloSprite;

char sBoxPath[PLATFORM_MAX_PATH];
char sParaPath[PLATFORM_MAX_PATH];
char sLandBeam[64];


#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "<TAG>"

public Plugin myinfo = 
{
	name = "AirDropCore", 
	author = PLUGIN_AUTHOR, 
	description = "API For developers to call AirDrops", 
	version = PLUGIN_VERSION, 
	url = "github.com/Hexer10/AirDrop-Core"
};

/***************************	STARTUP	**********************************/


public void OnPluginStart()
{
	//Create Array
	Array_BoxEnt = new ArrayList(64);
	Array_BoxRunningEnt = new ArrayList(64);
	Array_BoxRunningEntZ = new ArrayList(64);
	//HookEvents
	HookEvent("round_start", Event_RoundStart);
	
	//Prepare AutoExecConfig
	AutoExecConfig(true);
	
	cv_sBoxPath = CreateConVar("sm_airdrop_box", "models/props_crates/static_crate_40.mdl", "Path of the box in the airdrop");
	cv_sParaPath = CreateConVar("sm_airdrop_parachute", "models/parachute/parachute_ark.mdl", "Path of the paracute in the airdrop");
	cv_fMaxDistance = CreateConVar("sm_airdrop_max_distance", "350.0", "The max distance that a box can be pressed", _, true, 0.0);
	cv_fLandDistance = CreateConVar("sm_airdrop_landing_zone", "75.0", "N - Prevent player going into the Box Landing Zone to avoid them to compenetrait when the box. 0 - Disable", _, true, 0.0);
	cv_sLandBeam = CreateConVar("sm_airdrop_landing_beam", "1", "1 - Make a random colored beam in the landind zone. 0 - Disabled. R,G,B - Colors (Es: 255, 0, 255)");
	cv_bCheckSolid = CreateConVar("sm_airdrop_check_solid", "1", "1 - If a box is going to compenerate with the floor stop it. 0 - Allow the box to go thru the floor");
	cv_fSpeedMult = CreateConVar("sm_airdrop_speed_mul", "1", "AirDrop fall speed multiplier");
	
	//Get CvarString Values
	cv_sBoxPath.GetString(sBoxPath, sizeof(sBoxPath));
	cv_sParaPath.GetString(sParaPath, sizeof(sParaPath));
	cv_sLandBeam.GetString(sLandBeam, sizeof(sLandBeam));
	
	//AddChangeHook for Cvars
	cv_sBoxPath.AddChangeHook(OnCvarChange);
	cv_sParaPath.AddChangeHook(OnCvarChange);
	cv_sLandBeam.AddChangeHook(OnCvarChange);
}

public void OnCvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cv_sBoxPath)
	{
		strcopy(sBoxPath, sizeof(sBoxPath), newValue);
		if (IsModelPrecached(sBoxPath))
			PrecacheModel(sBoxPath);
	}
	else if (convar == cv_sParaPath)
	{
		strcopy(sParaPath, sizeof(sParaPath), newValue);
		if (IsModelPrecached(sParaPath))
			PrecacheModel(sParaPath);
	}
	else if (convar == cv_sLandBeam)
	{
		strcopy(sLandBeam, sizeof(sLandBeam), newValue);
	}
}

public void OnMapStart()
{
	PrecacheModel(sBoxPath);
	PrecacheModel(sParaPath);
	
	iBeamSprite = PrecacheModel("sprites/laserbeam.vmt");
	iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
}

/***************************	EVENTS	**********************************/
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Array_BoxEnt.Clear();
	Array_BoxRunningEnt.Clear();
	Array_BoxRunningEntZ.Clear();
}

/***************************	API 	**********************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("AirDropCore");
	
	CreateNative("AirDrop_Call", Native_CallAirDrop);
	
	gF_OnAirDropCalled = CreateGlobalForward("AirDrop_Called", ET_Event, Param_Cell, Param_Cell, Param_Array);
	gF_OnBoxUsed = CreateGlobalForward("AirDrop_BoxUsed", ET_Ignore, Param_Cell, Param_Cell);
}

public int Native_CallAirDrop(Handle plugin, int args)
{
	float vBoxOrigin[3];
	
	GetNativeArray(1, vBoxOrigin, sizeof(vBoxOrigin));
	bool bCallForward = view_as<bool>(GetNativeCell(2));
	
	return CallAirDrop(vBoxOrigin, bCallForward);
}

public int CallAirDrop(float vBoxOrigin[3], bool bCallForward)
{
	if (TR_PointOutsideWorld(vBoxOrigin))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[AirDrop - API] Point out of the world! (Preventing crash!)");
		return -1;
	}
	
	float pEndPoint[3];
	pEndPoint[2] = vBoxOrigin[2];
	
	vBoxOrigin[2] += 3000.0;
	
	//This needs to be check it's useless atm
	while (TR_PointOutsideWorld(vBoxOrigin))
	{
		vBoxOrigin[2] -= 5.0;
	}
	
	int iBoxEnt = SpawnBox(vBoxOrigin);
	
	vBoxOrigin[2] -= 30.0;
	
	int iParaEnt = SpawnParachute(vBoxOrigin);
	
	if (bCallForward)
	{
		Action res = Plugin_Continue;
		
		Call_StartForward(gF_OnAirDropCalled);
		Call_PushCell(iBoxEnt);
		Call_PushCell(iParaEnt);
		Call_PushArray(vBoxOrigin, sizeof(vBoxOrigin));
		Call_Finish(res);
		
		if (res >= Plugin_Handled)
		{
			AcceptEntityInput(iBoxEnt, "kill");
			AcceptEntityInput(iParaEnt, "kill");
			return -2;
		}
	}
	
	if (cv_bCheckSolid.BoolValue)
	{
		float vAng[3];
		
		vAng[0] = 89.0;
		vAng[1] = 0.0;
		vAng[2] = 0.0;
		
		
		TR_TraceRayFilter(vBoxOrigin, vAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, iBoxEnt);
		TR_GetEndPosition(pEndPoint);
	}
	
	Handle BeamTimer = null;
	if (!StrEqual(sLandBeam, "0"))
	{
		float vEndPoint[3];
		int iColors[4];
		
		vEndPoint[0] = vBoxOrigin[0];
		vEndPoint[1] = vBoxOrigin[1];
		vEndPoint[2] = pEndPoint[2];
		
		iColors[3] = 255;
		
		if (StrEqual(sLandBeam, "1"))
		{
			for (int i = 0; i <= 2; i++)
			{
				iColors[i] = GetRandomInt(0, 255);
			}
		}
		else
		{
			char sColorsL[3][16];
			
			ExplodeString(sLandBeam, ",", sColorsL, sizeof(sColorsL[]), sizeof(sColorsL));
			
			for (int i = 0; i <= 2; i++)
			{
				iColors[i] = StringToInt(sLandBeam[i]);
			}
		}
		
		
		ArrayList DataArray = new ArrayList(4);
		TE_SetupBeamPoints(vBoxOrigin, vEndPoint, iBeamSprite, iHaloSprite, 0, 100, 0.1, 1.0, 5.0, 1, 5.0, iColors, 1);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(vBoxOrigin, cv_fLandDistance.FloatValue + 200.0, cv_fLandDistance.FloatValue + 200.1, iBeamSprite, iHaloSprite, 0, 30, 0.1, 1.0, 1.0, iColors, 1, 0);
		TE_SendToAll();
		
		vEndPoint[2] += 5.0;
		TE_SetupBeamRingPoint(vEndPoint, cv_fLandDistance.FloatValue + 25.0, cv_fLandDistance.FloatValue + 25.1, iBeamSprite, iHaloSprite, 0, 30, 0.1, 1.0, 1.0, iColors, 1, 0);
		TE_SendToAll();
		vEndPoint[2] -= 5.0;
		
		DataArray.Push(vBoxOrigin[2]);
		DataArray.Push(vEndPoint[2]);
		DataArray.PushArray(iColors);
		DataArray.Push(EntIndexToEntRef(iBoxEnt));
		
		BeamTimer = CreateTimer(0.1, Timer_DrawBeam, DataArray, TIMER_REPEAT);
	}
	
	ArrayList DataArray = new ArrayList(4);
	
	DataArray.Push(EntIndexToEntRef(iBoxEnt));
	DataArray.Push(EntIndexToEntRef(iParaEnt));
	DataArray.Push(pEndPoint[2]);
	DataArray.Push(BeamTimer);
	
	Array_BoxRunningEnt.Push(EntIndexToEntRef(iBoxEnt));
	Array_BoxRunningEntZ.Push(pEndPoint[2]);
	RequestFrame(OnReqFrame, DataArray);
	return iBoxEnt;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if (entity == data)
		return false;
	return true;
}



public void OnReqFrame(ArrayList DataArray)
{
	int iBoxEnt = EntRefToEntIndex(DataArray.Get(0));
	int iParaEnt = EntRefToEntIndex(DataArray.Get(1));
	float pEndPoint = view_as<float>(DataArray.Get(2));
	Handle BeamTimer = DataArray.Get(3);
	
	if (iBoxEnt == INVALID_ENT_REFERENCE || iParaEnt == INVALID_ENT_REFERENCE)
		return;
	
	float vPos[3];
	GetEntityOrigin(iBoxEnt, vPos);
	
	if (pEndPoint >= vPos[2])
	{
		if (BeamTimer != null)
		{
			BeamTimer.Close();
			BeamTimer = null;
		}
		int iIndex = Array_BoxRunningEnt.FindValue(DataArray.Get(0));
		Array_BoxRunningEnt.Erase(iIndex);
		Array_BoxRunningEntZ.Erase(iIndex);
		Array_BoxEnt.Push(EntIndexToEntRef(iBoxEnt));
		AcceptEntityInput(iParaEnt, "kill");
		return;
	}
	
	vPos[2] -= 0.5 * cv_fSpeedMult.FloatValue;
	TeleportEntity(iBoxEnt, vPos, NULL_VECTOR, NULL_VECTOR);
	vPos[2] -= 30.0 * cv_fSpeedMult.FloatValue;
	TeleportEntity(iParaEnt, vPos, NULL_VECTOR, NULL_VECTOR);
	
	RequestFrame(OnReqFrame, DataArray);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	CheckDistance();
	
	if (IsPlayerAlive(client) && (buttons & IN_USE) && GetArraySize(Array_BoxEnt) != 0)
	{
		int iEnt = GetClientAimTarget(client, false);
		
		if (IsValidEdict(iEnt) && (iEnt < 0))
			return Plugin_Continue;
		
		bool bFound;
		
		for (int i = 0; i <= GetArraySize(Array_BoxEnt) - 1; i++)
		{
			int iBoxEnt = EntRefToEntIndex(Array_BoxEnt.Get(i));
			if (iBoxEnt == INVALID_ENT_REFERENCE)
			{
				Array_BoxEnt.Erase(i);
				continue;
			}
			if (iBoxEnt == iEnt)
			{
				bFound = true;
				break;
			}
		}
		
		
		if (!bFound)
			return Plugin_Continue;
		
		
		float vClientOrigin[3];
		float vBoxOrigin[3];
		
		GetClientAbsOrigin(client, vClientOrigin);
		GetEntityOrigin(iEnt, vBoxOrigin);
		
		
		if ((GetVectorDistance(vClientOrigin, vBoxOrigin) > cv_fMaxDistance.FloatValue) || !cv_fMaxDistance.IntValue)
			return Plugin_Continue;
		
		
		Call_StartForward(gF_OnBoxUsed);
		Call_PushCell(client);
		Call_PushCell(iEnt);
		Call_Finish();
		
		
		return Plugin_Continue;
		
	}
	return Plugin_Continue;
}




void CheckDistance()
{
	if (!GetArraySize(Array_BoxRunningEnt))
		return;
	
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		float vClientPos[3];
		float vBoxPos[3];
		
		GetClientAbsOrigin(i, vClientPos);
		
		
		for (int j = 0; j <= GetArraySize(Array_BoxRunningEnt) - 1; j++)
		{
			int iEnt = EntRefToEntIndex(Array_BoxRunningEnt.Get(j));
			
			if (iEnt == INVALID_ENT_REFERENCE)
			{
				Array_BoxRunningEnt.Erase(j);
				Array_BoxRunningEntZ.Erase(j);
				continue;
			}
			
			
			GetEntityOrigin(iEnt, vBoxPos);
			
			vBoxPos[2] = Array_BoxRunningEntZ.Get(j);
			
			float fDistance = GetVectorDistance(vClientPos, vBoxPos);
			
			if ((fDistance < cv_fLandDistance.FloatValue) || !cv_fLandDistance.IntValue)
			{
				KnockbackSetVelocity(i, vBoxPos, vClientPos, 300.0);
			}
		}
	}
}

/***************************	TIMERS 	**********************************/


public Action Timer_DrawBeam(Handle timer, ArrayList DataArray)
{
	int iColors[4];
	float pBoxStart = DataArray.Get(0);
	float pBoxEnd = DataArray.Get(1);
	int iEnt = EntRefToEntIndex(DataArray.Get(3));
	DataArray.GetArray(2, iColors);
	
	if (iEnt == INVALID_ENT_REFERENCE)
	{
		timer = null;
		return Plugin_Stop;
	}
	float vBoxStart[3];
	float vBoxEnd[3];
	
	GetEntityOrigin(iEnt, vBoxStart);
	GetEntityOrigin(iEnt, vBoxEnd);
	
	vBoxStart[2] = pBoxStart;
	vBoxEnd[2] = pBoxEnd;
	
	
	TE_SetupBeamPoints(vBoxStart, vBoxEnd, iBeamSprite, iHaloSprite, 0, 100, 0.1, 5.0, 5.0, 1, 5.0, iColors, 1);
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(vBoxStart, cv_fLandDistance.FloatValue + 200, cv_fLandDistance.FloatValue + 200.1, iBeamSprite, iHaloSprite, 0, 30, 0.1, 1.0, 1.0, iColors, 1, 0);
	TE_SendToAll();
	
	vBoxEnd[2] += 5.0;
	TE_SetupBeamRingPoint(vBoxEnd, cv_fLandDistance.FloatValue + 25.0, cv_fLandDistance.FloatValue + 25.1, iBeamSprite, iHaloSprite, 0, 30, 0.1, 1.0, 1.0, iColors, 1, 0);
	TE_SendToAll();
	vBoxEnd[2] -= 5.0;
	return Plugin_Continue;
}






















/***************************	STOCKS 	**********************************/
int SpawnBox(float pos[3])
{
	int iEnt = CreateEntityByName("prop_dynamic");
	
	TeleportEntity(iEnt, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityModel(iEnt, sBoxPath);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6);
	return iEnt;
}


int SpawnParachute(float pos[3])
{
	int iEnt = CreateEntityByName("prop_dynamic");
	
	TeleportEntity(iEnt, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityModel(iEnt, sParaPath);
	return iEnt;
}




//Forked from Franc1sco franug (dev_zones)
void KnockbackSetVelocity(int client, const float startpoint[3], const float endpoint[3], float magnitude)
{
	// Create vector from the given starting and ending points.
	float vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);
	
	// Normalize the vector (equal magnitude at varying distances).
	NormalizeVector(vector, vector);
	
	// Apply the magnitude by scaling the vector (multiplying each of its components).
	ScaleVector(vector, magnitude);
	
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
} 