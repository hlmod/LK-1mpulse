#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>
#include <tbc_stats>

#define MAX_ITEMS 32

enum enum_Credits
{
	String:Name[64],
	_:Credits,
	_:Price,
}

int g_iTBCItem, g_Points[MAX_ITEMS][enum_Credits];
char g_sItemName[] = "tbc_stats";

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка TBC поинтов",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка TBC поинтов] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_tbc_stats.phrases");
		LK_RegisterItem(g_sItemName, TBC_Callback);
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

public void TBC_Callback(int iClient, int ItemID, const char[] ItemName)
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
	for(int i = 0; i < g_iTBCItem; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_Points[i][Name], ClientCash >= g_Points[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
			LK_TakeClientCash(iClient, g_Points[i][Price]);
			TBC_Stats_GiveXP(iClient, g_Points[i][Credits]);
			LK_PrintToChat(iClient, "%T", "Buy_Points", iClient, g_Points[i][Credits]);
			LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %i TBC поинтов", iClient, sAuth, g_Points[i][Credits]);
			ShowMenuModule(iClient);
		}
	}
}

void KFG_load()
{
	char sPath[128];
	KeyValues KV = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/lk/lk_module_tbc_stats.ini");
	if(!KV.ImportFromFile(sPath)) SetFailState("[LK MODULE][Покупка TBC поинтов] - Файл конфигураций не найден");
	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		g_iTBCItem = 0;
		do 
		{
			if(KV.GetSectionName(g_Points[g_iTBCItem][Name], 64))
			{
				g_Points[g_iTBCItem][Credits] = KV.GetNum("points");
				g_Points[g_iTBCItem][Price] = KV.GetNum("price");
				if(g_Points[g_iTBCItem][Credits] < 0) g_Points[g_iTBCItem][Credits] = 0;
				if(g_Points[g_iTBCItem][Price] < 0) g_Points[g_iTBCItem][Price] = 0;
				g_iTBCItem += 1;
			}
		} while(KV.GotoNextKey(true));
	}
}