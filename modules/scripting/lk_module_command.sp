#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>

#define MAX_ITEMS 32

enum enum_Command
{
	String:Name[64],
	_:Price,
	String:Command[128],
}

int g_iCommand, g_Command[MAX_ITEMS][enum_Command];
char g_sItemName[] = "command_module";

public Plugin myinfo =
{
	name = "[LK MODULE] Command Module",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Command Module] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_command.phrases");
		LK_RegisterItem(g_sItemName, Command_Callback);
	}
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);
}

public void OnMapStart()
{
	KFG_load();
}

public void Command_Callback(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	char sTitle[256];
	int ClientCash = LK_GetClientCash(iClient);
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle(sTitle);
	for(int i = 0; i < g_iCommand; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_Command[i][Name], ClientCash >= g_Command[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) LK_ShowMainMenu(iClient);
		}
		case MenuAction_Select:
        {
			char szInfo[16];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			int i = StringToInt(szInfo);
			if(IsPlayerAlive(iClient))
			{
				char sAuth[32], sName[64], sUserID[16];
				IntToString(GetClientUserId(iClient), sUserID, sizeof(sUserID));
				GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
				GetClientName(iClient, sName, sizeof(sName));
				if(StrContains(g_Command[i][Command], "{STEAMID}", true) > 0) ReplaceString(g_Command[i][Command], 128, "{STEAMID}", sAuth);
				if(StrContains(g_Command[i][Command], "{USERID}", true) > 0) ReplaceString(g_Command[i][Command], 128, "{USERID}", sUserID);
				if(StrContains(g_Command[i][Command], "{NAME}", true) > 0) ReplaceString(g_Command[i][Command], 128, "{NAME}", sName);
				LK_TakeClientCash(iClient, g_Command[i][Price]);
				ServerCommand(g_Command[i][Command]);
				LK_PrintToChat(iClient, "%T", "Succes_Buy", iClient, g_Command[i][Price]);
				ShowMenuModule(iClient);
			}
			else
			{
				LK_PrintToChat(iClient, "%T", "U_Die", iClient);
				ShowMenuModule(iClient);
			}
		}
	}
}

void KFG_load()
{
	char sPath[128];
	KeyValues KV = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/lk/lk_module_command.ini");
	if(!KV.ImportFromFile(sPath)) SetFailState("[LK MODULE][Command Module] - Файл конфигураций не найден");
	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		g_iCommand = 0;
		do 
		{
			if(KV.GetSectionName(g_Command[g_iCommand][Name], 64))
			{
				g_Command[g_iCommand][Price] = KV.GetNum("price");
				if(g_Command[g_iCommand][Price] < 0) g_Command[g_iCommand][Price] = 0;
				KV.GetString("command", g_Command[g_iCommand][Command], 128);
				g_iCommand += 1;
			}
		} while(KV.GotoNextKey(true));
	}
}