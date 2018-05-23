#pragma semicolon 1

#include <sourcemod>
#include <csgo_colors>
#include <colors>
#include <sdktools>

#define VERSION_PLUGIN "4.0.1"

public Plugin myinfo =
{
	name = "[Личный Кабинет] Core [PRIVATE]",
	author = "1mpulse (skype:potapovdima1)",
	version = VERSION_PLUGIN,
	url = "https://plugins.thebestcsgo.ru"
};

#include "lk/Global.sp"
#include "lk/Database.sp"
#include "lk/Configs.sp"
#include "lk/Stocks.sp"
#include "lk/Cmds.sp"
#include "lk/Menus.sp"
#include "lk/Natives.sp"
#include "lk/Forwards.sp"

public void OnPluginStart()
{
	pDatabase();
	Load_KFG();
	LoadTranslations("lk.phrases");
	CreateArrays();
	CreateForwardss();
	RegAllCmds();
	
	switch(GetEngineVersion())
	{
		case Engine_CSGO: GameCSGO = true;
		case Engine_CSS: GameCSGO = false;
	}
}

public void OnMapStart()
{
	g_ItemsCount = -1;
	ClearArrays();
	if(cfg_bLogs)
	{
		char mapname[125];
		GetCurrentMap(mapname, 125);
		LogToFile(logFile, "-------- [LK CORE] Loaded Successfull... On Map %s --------", mapname);
	}
	Call_StartForward(hLK_OnLoaded);
	Call_Finish();
}

public void OnClientPutInServer(iClient)
{
	GetClientAuthId(iClient, AuthId_Steam2, g_SteamID[iClient], 32, true);
}

public void OnClientPostAdminCheck(int iClient)
{
	LoadPlayer(iClient);
}