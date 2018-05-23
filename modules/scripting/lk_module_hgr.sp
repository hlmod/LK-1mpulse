#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>
#include <hgr>
#include <adminmenu>

#define MAX_HGR 32

enum enum_HGR
{
	String:Name[64],
	_:Time,
	_:Price,
}

int g_iHGR, g_HGR[MAX_HGR][enum_HGR], g_iClientHGR[MAXPLAYERS+1];
char g_sItemName[] = "hgr";
bool g_bClientHGR[MAXPLAYERS+1];
Database g_hDatabase;
TopMenu g_hAdminMenu = null;

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка HGR",
	author = "1mpulse (skype:potapovdima1)",
	version = "1.2.0 [PRIVATE]"
};

public void OnPluginStart()
{
	Database.Connect(ConnectCallBack, "lk");
	HookEvent("player_spawn", Event_Spawn);
	TopMenu hTopMenu;
	if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
}

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка HGR] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_hgr.phrases");
		LK_RegisterItem(g_sItemName, HGRCallBack);
	}
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);
}

public void OnClientPostAdminCheck(int iClient)
{
	LoadPlayer(iClient);
}

public void OnClientPutInServer(iClient)
{
	g_bClientHGR[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	g_bClientHGR[iClient] = false;
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		if(g_iClientHGR[iClient] > -1)
		{
			if(!g_bClientHGR[iClient])
			{
				HGR_ClientAccess(iClient, 0, 0);
				g_bClientHGR[iClient] = true;
			}
			if(g_iClientHGR[iClient] != 0)
			{
				if((g_iClientHGR[iClient] - GetTime()) < 0)
				{
					g_iClientHGR[iClient] = -1;
					HGR_ClientAccess(iClient, 1, 0);
					LK_PrintToChat(iClient, "%T", "Time_is_up", iClient);
					SavePlayer(iClient);
				}
			}
		}
		else
		{
			if(!g_bClientHGR[iClient])
			{
				HGR_ClientAccess(iClient, 1, 0);
				g_bClientHGR[iClient] = true;
			}
		}
	}
}

public void OnMapStart()
{
	KFG_load();
}

public void HGRCallBack(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	char sTitle[256];
	int ClientCash = LK_GetClientCash(iClient);
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	if(g_iClientHGR[iClient] > -1)
	{
		if(g_iClientHGR[iClient] != 0)
		{
			int TIME = g_iClientHGR[iClient]-GetTime();
			FormatEx(sTitle, sizeof(sTitle), "%s\nПаутинка: [%dд %dч %dм]\n ", sTitle, TIME/3600/24, TIME/3600%24, TIME/60%60);
		}
		else FormatEx(sTitle, sizeof(sTitle), "%s\nПаутинка: [навсегда]\n ", sTitle);
	}
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle(sTitle);
	for(int i = 0; i < g_iHGR; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_HGR[i][Name], ClientCash >= g_HGR[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
			char szInfo[16];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			int i = StringToInt(szInfo);
			char sAuth[32];
			GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
			LK_TakeClientCash(iClient, g_HGR[i][Price]);
			
			if(g_iClientHGR[iClient] != 0)
			{
				if(g_iClientHGR[iClient] > -1 && g_HGR[i][Time] != 0)
				{
					g_iClientHGR[iClient] += (g_HGR[i][Time]*60);
					LK_PrintToChat(iClient, "%T", "Buy_Extended", iClient);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) продлил доступ к паунтике на %i минут", iClient, sAuth, g_HGR[i][Time]);
				}
				else if(g_HGR[i][Time] != 0)
				{
					g_iClientHGR[iClient] = GetTime()+(g_HGR[i][Time]*60);
					LK_PrintToChat(iClient, "%T", "Buy_Time", iClient);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил доступ к паунтике на %i минут", iClient, sAuth, g_HGR[i][Time]);
				}
				else
				{
					g_iClientHGR[iClient] = 0;
					LK_PrintToChat(iClient, "%T", "Buy_Forever", iClient);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил доступ к паунтике навсегда", iClient, sAuth);
				}
				
				HGR_ClientAccess(iClient, 0, 0);
				g_bClientHGR[iClient] = true;
			}
			else LK_PrintToChat(iClient, "%T", "Alredy_Buy_Forever", iClient);
			
			SavePlayer(iClient);
			ShowMenuModule(iClient);
		}
	}
}

void KFG_load()
{
	char sPath[128];
	KeyValues KV = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/lk/lk_module_hgr.ini");
	if(!KV.ImportFromFile(sPath)) SetFailState("[LK MODULE][Покупка HGR] - Файл конфигураций не найден");
	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		g_iHGR = 0;
		do 
		{
			if(KV.GetSectionName(g_HGR[g_iHGR][Name], 64))
			{
				g_HGR[g_iHGR][Time] = KV.GetNum("time");
				g_HGR[g_iHGR][Price] = KV.GetNum("price");
				g_iHGR += 1;
			}
		} while(KV.GotoNextKey(true));
	}
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0]) LogError("SQL_Callback_CheckError: %s", szError);
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if(hDatabase == null)
	{
		SetFailState("Could not connect to database, reason: %s", sError);
		return;
	}
	g_hDatabase = hDatabase;
	SQL_LockDatabase(g_hDatabase);
	char szQuery[1024];
	FormatEx(szQuery, sizeof(szQuery), "CREATE TABLE IF NOT EXISTS `lk_hgr` (`auth` VARCHAR(%d) NOT NULL PRIMARY KEY, `name` VARCHAR(%d) NOT NULL, `expire` INTEGER(%d) DEFAULT -1)",32,64,8);
	g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.SetCharset("utf8");
}

void LoadPlayer(int iClient) 
{
	if(IsValidPlayer(iClient))
	{
		char szQuery[256], szAuth[32];
		GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof(szAuth), true);
		FormatEx(szQuery, sizeof(szQuery), "SELECT `expire` FROM `lk_hgr` WHERE `auth` = '%s'", szAuth);
		g_hDatabase.Query(SQL_Callback_LoadClient, szQuery, GetClientUserId(iClient), DBPrio_High);
	}
}

public void SQL_Callback_LoadClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("Could not load the player, reason: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		if(hResults.FetchRow())
		{
			g_iClientHGR[iClient] = hResults.FetchInt(0);
		}
		else
		{
			char szQuery[512], szName[MAX_NAME_LENGTH*2+1], szAuth[32];
			GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
			GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof(szAuth), true);
			g_hDatabase.Escape(szQuery, szName, sizeof(szName));
			g_iClientHGR[iClient] = -1;
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `lk_hgr` (`auth`, `name`, `expire`) VALUES ('%s', '%s', '%i')", szAuth, szName, -1);
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
		}
	}
}

void SavePlayer(int iClient)
{
	if(IsValidPlayer(iClient))
	{
		char szQuery[512], szName[MAX_NAME_LENGTH*2+1], szAuth[32];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof(szAuth), true);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `lk_hgr` SET `expire` = '%i', `name` = '%s' WHERE `auth` = '%s'", g_iClientHGR[iClient], szName, szAuth);
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
	}
}

stock bool IsValidPlayer(int iClient)
{
	if(IsClientInGame(iClient) && !IsFakeClient(iClient)) return true;
	else return false;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (hTopMenu == g_hAdminMenu) return;
	g_hAdminMenu = hTopMenu;
	TopMenuObject hMyCategory = g_hAdminMenu.FindCategory("sm_lk_root_category");
	if(hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hAdminMenu.AddItem("sm_lk_hgr_item", MenuCallBack1, hMyCategory, "sm_lk_hgr_menu", ADMFLAG_ROOT, "Забрать паутинку");
	}
}

public void MenuCallBack1(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Забрать паутинку");
		case TopMenuAction_SelectOption: Select_PL_MENU(iClient);
	}
}

void Select_PL_MENU(int iClient)
{
	char userid[15], name[128];
	Menu hMenu = new Menu(Select_PL);
	hMenu.SetTitle("Выберите Игрока:");
	hMenu.ExitBackButton = true;
	bool add = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && g_iClientHGR[i] > -1)
		{
			int TIME = g_iClientHGR[i]-GetTime();
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			GetClientName(i, name, sizeof(name));
			if(g_iClientHGR[i] != 0) FormatEx(name, sizeof(name), "%s [%dд %dч %dм]", name, TIME/3600/24, TIME/3600%24, TIME/60%60);
			else FormatEx(name, sizeof(name), "%s [навсегда]", name);
			hMenu.AddItem(userid, name);
			add = true;
		}
	}
	if(!add) hMenu.AddItem("", "Игроков не найдено.", ITEMDRAW_DISABLED);
	
	hMenu.Display(iClient, 0);
}

public int Select_PL(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);	
        }
		case MenuAction_Select:
		{
			int u, target;
			char userid[15];
			hMenu.GetItem(iItem, userid, sizeof(userid));
			u = StringToInt(userid);
			target = GetClientOfUserId(u);
			if(target)
			{
				g_iClientHGR[target] = -1;
				HGR_ClientAccess(target, 1, 0);
				SavePlayer(target);
				LK_PrintToChat(iClient, "%T", "Take_HGR_Admin", iClient, target);
			}
		}
	}
}