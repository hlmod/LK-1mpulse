void pDatabase()
{
	char szError[256];
	g_hDatabase = SQL_Connect("lk", false, szError, sizeof(szError));
	if(!g_hDatabase)
	{
		g_hDatabase = SQLite_UseDatabase("lk_sqlite", szError, sizeof(szError));
		if(!g_hDatabase) SetFailState("Database failure: %s", szError);
	}
	
	SQL_LockDatabase(g_hDatabase);
	if(!cfg_bGameCMS)
	{
		g_hDatabase.Query(SQL_Callback_CheckError,	"CREATE TABLE IF NOT EXISTS `lk` (\
															`auth` VARCHAR(32) NOT NULL PRIMARY KEY,\
															`name` VARCHAR(64) NOT NULL default 'unknown',\
															`cash` INTEGER NOT NULL default '0',\
															`all_cash` INTEGER NOT NULL default '0');");
	}
	g_hDatabase.Query(SQL_Callback_CheckError,	"CREATE TABLE IF NOT EXISTS `lk_keys` (\
															`key` VARCHAR(32) NOT NULL PRIMARY KEY,\
															`key_cash` INTEGER NOT NULL default '0');");
	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.SetCharset("utf8");
}

void LoadPlayer(int iClient) 
{
	if(IsValidPlayer(iClient))
	{
		if(cfg_bGameCMS)
		{
			char szQuery[256];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `shilings` FROM `users` WHERE `steam_id` = '%s'", g_SteamID[iClient]);
			g_hDatabase.Query(SQL_Callback_LoadPlayer, szQuery, GetClientUserId(iClient), DBPrio_High);
		}
		else
		{
			char szQuery[256];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `cash`, `all_cash` FROM `lk` WHERE `auth` = '%s'", g_SteamID[iClient]);
			g_hDatabase.Query(SQL_Callback_LoadPlayer, szQuery, GetClientUserId(iClient), DBPrio_High);
		}
	}
}

public void SQL_Callback_LoadPlayer(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("Could not load the player, reason: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		if(cfg_bGameCMS)
		{
			if(hResults.FetchRow())
			{
				g_iClientInfo[iClient][Client_Cash] = hResults.FetchInt(0);
				g_iClientInfo[iClient][Client_AllCash] = 0;
			}
			else
			{
				g_iClientInfo[iClient][Client_Cash] = -1;
				g_iClientInfo[iClient][Client_AllCash] = 0;
			}
		}
		else
		{
			char szQuery[512], szName[MAX_NAME_LENGTH*2+1];
			GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
			g_hDatabase.Escape(szQuery, szName, sizeof(szName));
			if(hResults.FetchRow())
			{
				g_iClientInfo[iClient][Client_Cash] = hResults.FetchInt(0);
				g_iClientInfo[iClient][Client_AllCash] = hResults.FetchInt(1);
			}
			else
			{
				g_iClientInfo[iClient][Client_Cash] = 0;
				g_iClientInfo[iClient][Client_AllCash] = 0;
				FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `lk` (`auth`, `name`, `cash`, `all_cash`) VALUES ('%s', '%s', '%i', '%i')", g_SteamID[iClient], szName, g_iClientInfo[iClient][Client_Cash], g_iClientInfo[iClient][Client_AllCash]);
				g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
			}
		}
	}
}

void SavePlayer(int iClient)
{
	if(IsValidPlayer(iClient))
	{
		if(cfg_bGameCMS)
		{
			if(g_iClientInfo[iClient][Client_Cash] >= 0)
			{
				char szQuery[512];
				FormatEx(szQuery, sizeof(szQuery), "UPDATE `users` SET `shilings` = '%i' WHERE `steam_id` = '%s'", g_iClientInfo[iClient][Client_Cash], g_SteamID[iClient]);
				g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
			}
		}
		else
		{
			char szQuery[512], szName[MAX_NAME_LENGTH*2+1];
			GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
			g_hDatabase.Escape(szQuery, szName, sizeof(szName));
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `lk` SET `cash` = '%i', `all_cash` = '%i', `name` = '%s' WHERE `auth` = '%s'", g_iClientInfo[iClient][Client_Cash], g_iClientInfo[iClient][Client_AllCash], szName, g_SteamID[iClient]);
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
		}
	}
}

void LoadPlayerMenu(int iClient) 
{
	if(IsValidPlayer(iClient))
	{
		if(cfg_bGameCMS)
		{
			char szQuery[256];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `shilings` FROM `users` WHERE `steam_id` = '%s'", g_SteamID[iClient]);
			g_hDatabase.Query(SQL_Callback_LoadPlayerMenu, szQuery, GetClientUserId(iClient), DBPrio_High);
		}
		else
		{
			char szQuery[256];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `cash`, `all_cash` FROM `lk` WHERE `auth` = '%s'", g_SteamID[iClient]);
			g_hDatabase.Query(SQL_Callback_LoadPlayerMenu, szQuery, GetClientUserId(iClient), DBPrio_High);
		}
	}
}

public void SQL_Callback_LoadPlayerMenu(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("Could not load the player, reason: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		if(cfg_bGameCMS)
		{
			if(hResults.FetchRow())
			{
				g_iClientInfo[iClient][Client_Cash] = hResults.FetchInt(0);
				g_iClientInfo[iClient][Client_AllCash] = 0;
			}
			else
			{
				g_iClientInfo[iClient][Client_Cash] = -1;
				g_iClientInfo[iClient][Client_AllCash] = 0;
			}
		}
		else
		{
			char szQuery[512], szName[MAX_NAME_LENGTH*2+1];
			GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
			g_hDatabase.Escape(szQuery, szName, sizeof(szName));
			if(hResults.FetchRow())
			{
				g_iClientInfo[iClient][Client_Cash] = hResults.FetchInt(0);
				g_iClientInfo[iClient][Client_AllCash] = hResults.FetchInt(1);
			}
			else
			{
				g_iClientInfo[iClient][Client_Cash] = 0;
				g_iClientInfo[iClient][Client_AllCash] = 0;
				FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `lk` (`auth`, `name`, `cash`, `all_cash`) VALUES ('%s', '%s', '%i', '%i')", g_SteamID[iClient], szName, g_iClientInfo[iClient][Client_Cash], g_iClientInfo[iClient][Client_AllCash]);
				g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
			}
		}
		LK_ShowMainMenu(iClient);
	}
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0]) LogError("SQL_Callback_CheckError: %s", szError);
}