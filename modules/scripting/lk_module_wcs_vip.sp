#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>
#include <wcs>

#define MAX_GROUPS 16

enum enum_Item
{
	String:sItemName[64],
	String:WcsVIPGroup[64],
	Days,
	Price,
};

int g_iCountVIP, g_Item[MAX_GROUPS][enum_Item];
char g_sItemName[] = "wcs_vip", sPath[128];

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка WCS VIP",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0 [PRIVATE]"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка WCS VIP] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_wcs_vip.phrases");
		BuildPath(Path_SM, sPath, sizeof(sPath), "data/wcs/wcs_vip.ini");
		LK_RegisterItem(g_sItemName, WCSVIP_CallBack);
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

public void WCSVIP_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	char sTitle[256];
	int ClientCash = LK_GetClientCash(iClient);
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.SetTitle(sTitle);
	hMenu.ExitBackButton = true;
	for(int i = 0; i < g_iCountVIP; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_Item[i][sItemName], ClientCash >= g_Item[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
			char sInfo[16], sAuth[32], sName[64], sTime[64];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			int i = StringToInt(sInfo);
			GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
			GetClientName(iClient, sName, sizeof(sName));
			if(!WCS_GetVip(iClient))
			{
				KeyValues KV = new KeyValues("Vip");
				if(!KV.ImportFromFile(sPath)) SetFailState("[WCS] - Файл wcs_vip.ini не найден");
				int iExpire = GetTime()+(g_Item[i][Days]*86400);
				FormatTime(sTime, sizeof(sTime), "%d.%m.%Y", iExpire);
				KV.JumpToKey(sAuth, true);
				KV.SetString("group", g_Item[i][WcsVIPGroup]);
				KV.SetString("name", sName);
				KV.SetString("expire", sTime);
				KV.Rewind();
				KV.ExportToFile(sPath);
				delete KV;
				LK_TakeClientCash(iClient, g_Item[i][Price]);
				LK_PrintToChat(iClient, "%T", "Buy_WCSVIP", iClient, g_Item[i][sItemName], sTime);
				LK_LogMessage("[Личный кабинет] Игрок %s (%s) купил - %s", sName, sAuth, g_Item[i][sItemName]);
				KickClient(iClient, "WCS VIP активирован! Перезайдите на сервер.");
			}
			else LK_PrintToChat(iClient, "%T", "NoBuy_WCSVIP", iClient);
			ShowMenuModule(iClient);
		}
	}
}


void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, path, sizeof(path), "configs/lk/lk_module_wcs_vip.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[LK MODULE][Покупка WCS VIP] - Файл конфигураций не найден");
	kfg.Rewind();
	if(kfg.GotoFirstSubKey(true))
	{
		g_iCountVIP = 0;
		do 
		{
			if(kfg.GetSectionName(g_Item[g_iCountVIP][sItemName], 64))
			{
				kfg.GetString("wcs_vip_group", g_Item[g_iCountVIP][WcsVIPGroup], 64);
				g_Item[g_iCountVIP][Days] = kfg.GetNum("days");
				g_Item[g_iCountVIP][Price] = kfg.GetNum("price");
				g_iCountVIP += 1;
			}
		} while (kfg.GotoNextKey(true));
	}
}