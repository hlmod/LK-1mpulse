#pragma semicolon 1
#include <lk>
#include <sourcemod>

enum enum_AGroups
{
	String:NameGroup[64],
	_:Price,
	_:Days,
	String:SrvGroup[64],
	_:Gid,
	_:Group_ID,
	_:Srv_Group_ID,
	String:Server_ID[64],
}

Database g_hDatabase;
KeyValues kfg;
int g_iAGroupsCount, g_AGroups[32][enum_AGroups], iClientSelect[MAXPLAYERS+1], g_iAdmins_AID[MAXPLAYERS+1];
char g_sItemName[] = "pokupka_admin";
char steamid[MAXPLAYERS + 1][32], cfg_sDefault_Password[128], cfg_sKickMessage[128];
bool cfg_bKick_buy;

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка Админок (REFORK)",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка Админок (REFORK)] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_pokupka_admin.phrases");
		Database.Connect(ConnectCallBack, "materialadmin");
		LK_RegisterItem(g_sItemName, BuyADMIN_Callback);
	}
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError);
		return;
	}
	g_hDatabase = hDatabase;
	g_hDatabase.SetCharset("utf8");
}

public void OnMapStart()
{
	KFG_load();
}

public void OnClientPutInServer(iClient)
{
	GetClientAuthId(iClient, AuthId_Steam2, steamid[iClient], 32, true);
	iClientSelect[iClient] = -1;
}

public void BuyADMIN_Callback(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	int ClientCash = LK_GetClientCash(iClient);
	char sTitle[256];
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.ExitBackButton = true;
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	hMenu.SetTitle(sTitle);
	for(int i = 0; i <= g_iAGroupsCount; i++)
	{
		char sText[128], sI[16];
		IntToString(i, sI, 16);
		if(g_AGroups[i][Days] == 0) FormatEx(sText, 128, "%s [навсегда] [%i руб.]", g_AGroups[i][NameGroup], g_AGroups[i][Price]);
		else FormatEx(sText, 128, "%s [%i дней] [%i руб.]", g_AGroups[i][NameGroup], g_AGroups[i][Days], g_AGroups[i][Price]);
		hMenu.AddItem(sI, sText, ClientCash >= g_AGroups[i][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
			hMenu.GetItem(iItem, szInfo, 16);
			int j = StringToInt(szInfo);
			iClientSelect[iClient] = j;
			if(GetUserFlagBits(iClient) & ADMFLAG_GENERIC) LK_PrintToChat(iClient, "%t", "Now_Admin");
			else
			{
				char szQuery[256];
				FormatEx(szQuery, sizeof(szQuery), "SELECT aid FROM sb_admins WHERE authid = '%s'", steamid[iClient]);
				g_hDatabase.Query(SQL_Callback_LoadPlayer, szQuery, GetClientUserId(iClient));
			}
		}
	}
}

InsertPlayerInDB(iClient)
{
	char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
	int iTime;
	int NowTime = GetTime();
	int DaysSeconds = g_AGroups[iClientSelect[iClient]][Days]*86400;
	if(DaysSeconds == 0) iTime = 0;
	else iTime = NowTime+DaysSeconds;
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));
		FormatEx(szQuery, sizeof(szQuery), "INSERT INTO sb_admins (user, authid, password, gid, srv_group, expired, email) VALUES ('%s', '%s', '%s', '%i', '%s', '%i', '1@1.ru')", szName, steamid[iClient], cfg_sDefault_Password, g_AGroups[iClientSelect[iClient]][Gid], g_AGroups[iClientSelect[iClient]][SrvGroup], iTime);
		g_hDatabase.Query(SQL_Callback_InsertPlayer, szQuery, GetClientUserId(iClient));
	}
}

public void SQL_Callback_LoadPlayer(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_LoadPlayer: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		int count;
		while (hResults.FetchRow())
		{	
			g_iAdmins_AID[iClient] = hResults.FetchInt(0);
			count++;
		}
		if(count) LK_PrintToChat(iClient, "%t", "Now_Admin_Servers");
		else InsertPlayerInDB(iClient);
	}
}

public void SQL_Callback_GetAidPlayer(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_GetAidPlayer: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	while(hResults.FetchRow()) g_iAdmins_AID[iClient] = hResults.FetchInt(0);
	if(iClient)
	{
		char ui[32][32], szQuery[256];
		int jl = ExplodeString(g_AGroups[iClientSelect[iClient]][Server_ID], ";", ui, 32, 32, false);
		for(int i = 0; i < jl; i++)
		{
			int server_new_id = StringToInt(ui[i]);
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO sb_admins_servers_groups (admin_id, group_id, srv_group_id, server_id) VALUES ('%i', '%i', '%i', '%i')", g_iAdmins_AID[iClient], g_AGroups[iClientSelect[iClient]][Group_ID], g_AGroups[iClientSelect[iClient]][Srv_Group_ID], server_new_id);
			g_hDatabase.Query(SQL_Callback_Default, szQuery, GetClientUserId(iClient));
		}
		LK_TakeClientCash(iClient, g_AGroups[iClientSelect[iClient]][Price]);
		if(g_AGroups[iClientSelect[iClient]][Days] == 0)
		{
			LK_PrintToChat(iClient, "%t", "Buy_Admin_Forever");
			LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %s навсегда", iClient, steamid[iClient], g_AGroups[iClientSelect[iClient]][NameGroup]);
		}
		else
		{
			LK_PrintToChat(iClient, "%t", "Buy_Admin", g_AGroups[iClientSelect[iClient]][Days]);
			LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %s на %i дней", iClient, steamid[iClient], g_AGroups[iClientSelect[iClient]][NameGroup], g_AGroups[iClientSelect[iClient]][Days]);
		}
		ServerCommand("ma_reload");
		ServerCommand("sm_rehash");
		ServerCommand("sm_reloadadmins");
		ServerCommand("ma_wb_rehashadm");
		if(cfg_bKick_buy) KickClient(iClient, cfg_sKickMessage);
		else LK_PrintToChat(iClient, "%t", "Buy_End");
	}
}

public void SQL_Callback_Default(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("Error: %s", sError);
		return;
	}
}

public void SQL_Callback_InsertPlayer(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_InsertPlayer: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{	
		char szQuery[256];
		FormatEx(szQuery, sizeof(szQuery), "SELECT aid FROM sb_admins WHERE authid = '%s'", steamid[iClient]);
		g_hDatabase.Query(SQL_Callback_GetAidPlayer, szQuery, GetClientUserId(iClient));
	}
}

KFG_load()
{
	if(kfg) delete kfg;
	kfg = new KeyValues("LK_MODULE");
	char path[128], g[64];
	BuildPath(Path_SM, path, 128, "configs/lk/lk_module_pokupka_admin.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[LK MODULE][Покупка Админки] - Файл конфигураций не найден");
	else
	{
		kfg.Rewind();
		if(kfg.JumpToKey("pokupka_admin", false))
		{
			cfg_bKick_buy = kfg.GetNum("kick_after", 1)?true:false;
			kfg.GetString("kick_message", cfg_sKickMessage, 128);
			kfg.GetString("default_password", cfg_sDefault_Password, 128);
			if(kfg.JumpToKey("admins_group", false))
			{
				if(kfg.GotoFirstSubKey(true))
				{
					g_iAGroupsCount = -1;
					do 
					{
						if(kfg.GetSectionName(g, 64))
						{
							g_iAGroupsCount += 1;
							strcopy(g_AGroups[g_iAGroupsCount][NameGroup], 64, g);
							g_AGroups[g_iAGroupsCount][Price] = kfg.GetNum("price");
							g_AGroups[g_iAGroupsCount][Days] = kfg.GetNum("days");
							kfg.GetString("srv_group", g_AGroups[g_iAGroupsCount][SrvGroup], 64);
							g_AGroups[g_iAGroupsCount][Gid] = kfg.GetNum("gid");
							g_AGroups[g_iAGroupsCount][Group_ID] = kfg.GetNum("group_id");
							g_AGroups[g_iAGroupsCount][Srv_Group_ID] = kfg.GetNum("srv_group_id");
							kfg.GetString("server_id", g_AGroups[g_iAGroupsCount][Server_ID], 64);
						}
					} while (kfg.GotoNextKey(true));
				}
			}
		} 
	}
}