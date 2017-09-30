#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <hexstocks>
#include <airdrop>

//Compiler options
#pragma semicolon 1
#pragma newdecls required

//Arrays
ArrayList Array_BoxEnt;

//Booleans
bool bPressed[MAXPLAYERS + 1];

#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"

//Plugin invos
public Plugin myinfo = 
{
	name = "CallAirDrop with Decoy", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "csitajb.it"
};

public void OnPluginStart()
{
	//Create Array
	Array_BoxEnt = new ArrayList(64);
	
	//Hook Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("decoy_detonate", Event_DecoyStarted);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Clear BoxEnt Array every round start
	Array_BoxEnt.Clear();
}
public void Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
	//Get the BoxOrigin
	float vBoxOrigin[3];
	vBoxOrigin[0] = event.GetFloat("x");
	vBoxOrigin[1] = event.GetFloat("y");
	vBoxOrigin[2] = event.GetFloat("z");
	
	int iBoxEnt = AirDrop_Call(vBoxOrigin); //Call AirDrop
	
	Array_BoxEnt.Push(iBoxEnt); //Push the BoxEnt to our Array (Yse EntRef to be safe)
}

public void AirDrop_BoxUsed(int client, int iEnt) //Called when pressing +use on the AirDropBox
{
	if (GetArraySize(Array_BoxEnt) == 0) //Check for not void array
		return;
	
	for (int i = 0; i <= GetArraySize(Array_BoxEnt) - 1; i++)
	{
		int iBoxEnt = Array_BoxEnt.Get(i); //Get BoxEnt (Convert EntRef to Index)
		
		if (iBoxEnt == INVALID_ENT_REFERENCE) //Check for valid ent
		{
			Array_BoxEnt.Erase(i); //Remove Invalid EntRef from the array
			return;
		}
		
		if (iBoxEnt == iEnt) //Check if BoxEnt is the 'pressed' Ent
		{
			if (bPressed[client])
				return;
			
			if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1) //Check if the client doesnt have already a weapon
				return;
			
			GivePlayerItem(client, "weapon_deagle");
			
			bPressed[client] = true;
			
			CreateTimer(2.0, Timer_Pressed, GetClientUserId(client)); //Create Timer to avoid spamming
		}
	}
}

public Action Timer_Pressed(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!client) //Client disconnected
		return;
	
	bPressed[client] = false;
} 