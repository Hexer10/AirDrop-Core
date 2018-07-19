#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <n_arms_fix>
//#include <multicolors>
//#include <hexstocks>

#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"

#pragma newdecls required
#pragma semicolon 1

KeyValues kv;

Menu pointsMenu;

public Plugin myinfo = 
{
	name = "AirDrop Spawn points",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "github.com/Hexer10/AirDrop-Core"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_airdrops", Cmd_SetSpawn);


	//Cache points menu.
	pointsMenu = new Menu(Handler_MainMenu);
	pointsMenu.SetTitle("Choose you action");
	pointsMenu.AddItem("new", "Add new point");
	pointsMenu.AddItem("delete", "Remove existing point");
	pointsMenu.AddItem("list", "List current");
}

public Action Cmd_SetSpawn(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] In game only commmand!");
		return Plugin_Handled;
	}
	
	pointsMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void OnMapStart()
{
	PreparePropKv();
}

void PreparePropKv()
{
	char sPropPath[PLATFORM_MAX_PATH];
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	BuildPath(Path_SM, sPropPath, sizeof(sPropPath), "configs/%s.airdrops.txt", sMap); //Get the right "map" file
	
	if (kv != null)
		delete kv;
		
	kv = new KeyValues("AirDropPoints");
	
	if (!FileExists(sPropPath)) //Try to create kv file.
		if (!kv.ExportToFile(sPropPath))
			SetFailState(" - AirDrops Points - Unable to create file: %s", sPropPath);
	
	if (!kv.ImportFromFile(sPropPath)) //Import the kv file
		SetFailState("- AirDrops Points - Unable to import: %s", sPropPath);
}

//Menu Handlers
public int Handler_Main(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, "new"))
		{
			Menu newPointMenu = new Menu(Handler_NewPoint);
			newPointMenu.AddItem("Set to current position");
			newPointMenu.ExitBackButton = true;
			newPointMenu.Display(param1, MENU_TIME_FOREVER);
		}
		else if(StrEqual(info, "delete"))
		{

		}
		else if(StrEqual(info, "edit"))
		{

		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 1;
}
