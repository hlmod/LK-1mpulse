#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>
#include <wcs>

#define MAX_ITEMS 32

enum enum_Credits
{
	String:Name[64],
	_:Credits,
	_:Price,
}

int g_iWcsGold, g_Credits[MAX_ITEMS][enum_Credits];
char g_sItemName[] = "wcs_lvl";

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка WCS LvL",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка WCS LvL] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_wcs_lvl.phrases");
		LK_RegisterItem(g_sItemName, WCSGold_Callback);
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

public void WCSGold_Callback(int iClient, int ItemID, const char[] ItemName)
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
	for(int i = 0; i < g_iWcsGold; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_Credits[i][Name], ClientCash >= g_Credits[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, 0);
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
			char szInfo[16], sAuth[32];
			GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			int i = StringToInt(szInfo);
			LK_TakeClientCash(iClient, g_Credits[i][Price]);
			WCS_GiveLBlvl(iClient, g_Credits[i][Credits]);
			LK_PrintToChat(iClient, "%T", "Buy_WCSLvL", iClient, g_Credits[i][Credits]);
			LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %i WCS LvL", iClient, sAuth, g_Credits[i][Credits]);
			ShowMenuModule(iClient);
		}
	}
}

void KFG_load()
{
	char sPath[128];
	KeyValues KV = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/lk/lk_module_wcs_lvl.ini");
	if(!KV.ImportFromFile(sPath)) SetFailState("[LK MODULE][Покупка WCS LvL] - Файл конфигураций не найден");
	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		g_iWcsGold = 0;
		do 
		{
			if(KV.GetSectionName(g_Credits[g_iWcsGold][Name], 64))
			{
				g_Credits[g_iWcsGold][Credits] = KV.GetNum("lvl");
				g_Credits[g_iWcsGold][Price] = KV.GetNum("price");
				if(g_Credits[g_iWcsGold][Credits] < 0) g_Credits[g_iWcsGold][Credits] = 0;
				if(g_Credits[g_iWcsGold][Price] < 0) g_Credits[g_iWcsGold][Price] = 0;
				g_iWcsGold += 1;
			}
		} while(KV.GotoNextKey(true));
	}
}