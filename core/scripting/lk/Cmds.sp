void RegAllCmds()
{
	RegConsoleCmd("sm_lkkey", sm_lkkey, "sm_lkkey <ключ>");
	RegAdminCmd("sm_lkhelp", sm_lkhelp, ADMFLAG_ROOT);
	RegAdminCmd("sm_lkkeysadd", sm_lkkeysadd, ADMFLAG_ROOT, "sm_lkkeysadd <кол-во 1-100> <руб> - добавить/создать LK ключи");
	RegAdminCmd("sm_lkkeysdel", sm_lkkeysdel, ADMFLAG_ROOT, "sm_lkkeysdel [ключ]");
	RegAdminCmd("sm_lkkeysdump", sm_lkkeysdump, ADMFLAG_ROOT);
	RegAdminCmd("sm_lkrub", sm_lkrub, ADMFLAG_ROOT, "sm_lkrub <add/take/set> <#userid> <руб>");
}

public Action sm_lk(int iClient, int iArgs)
{
	LoadPlayerMenu(iClient);
	return Plugin_Handled;
}

public Action sm_lkhelp(int iAdmin, int iArgs)
{
	if(CmdFlood(iAdmin)) return Plugin_Handled;
	PrintToConsole(iAdmin, "sm_lkkey <ключ> - Активировать ключ");
	PrintToConsole(iAdmin, "sm_lkkeysadd <кол-во 1-100> <руб> - добавить/создать LK ключи");
	PrintToConsole(iAdmin, "sm_lkkeysdel [key] - удалить все LK ключи или только 1");
	PrintToConsole(iAdmin, "sm_lkrub <add/take/set> <#userid> <руб>");
	PrintToConsole(iAdmin, "sm_lkkeysdump - информация о всех LK ключах в configs/lk/keys/lkkeys_dump.txt");
	return Plugin_Handled;
}

public Action sm_lkrub(int iAdmin, int iArgs) 
{
	if(CmdFlood(iAdmin)) return Plugin_Handled;
	if(iArgs < 3 && iAdmin > 0)
	{
		PrintToConsole(iAdmin, "Use: sm_lkrub <add/take/set> <#userid> <руб>");
		return Plugin_Handled;
	}
	
	char sBuffer[64];
	GetCmdArg(2, sBuffer, 64);
	if((StrContains(sBuffer, "#", false) < 0) && iAdmin > 0)
	{
		PrintToConsole(iAdmin, "Use: sm_lkrub <add/take/set> <#userid> <руб>");
		return Plugin_Handled;
	}
	ReplaceString(sBuffer, 64, "#", "", false);
	int userid = StringToInt(sBuffer);
	int iClient = GetClientOfUserId(userid);
	
	char buffer[MAX_TARGET_LENGTH];
	int mode = -1;
	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrEqual(buffer, "add", false))
		mode = 0;
	else if(StrEqual(buffer, "take", false))
		mode = 1;
	else if(StrEqual(buffer, "set", false))
		mode = 2;
	else
	{
		if(iAdmin > 0) PrintToConsole(iAdmin, "Use: sm_lkrub <add/take/set> <#userid> <руб>");
		return Plugin_Handled;
	}
	
	GetCmdArg(3, buffer, sizeof(buffer));
	int amount = StringToInt(buffer);
	switch(mode)
	{
		case 0:
		{
			g_iClientInfo[iClient][Client_Cash]+=amount;
			SavePlayer(iClient);
			if(iAdmin > 0) 
			{
				if(GameCSGO) CGOPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Add", iAdmin, iClient, amount, "Currency", iAdmin);
				else CPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Add", iAdmin, iClient, amount, "Currency", iAdmin);
			}
			if(cfg_bLogs) LogToFile(logFile, "[Личный кабинет] Админ %N пополнил счет игроку %N на %d руб.", iAdmin, iClient, amount);
		}
		case 1:
		{
			g_iClientInfo[iClient][Client_Cash]-=amount;
			if(g_iClientInfo[iClient][Client_Cash] < 0) g_iClientInfo[iClient][Client_Cash] = 0;
			SavePlayer(iClient);
			if(iAdmin > 0) 
			{
				if(GameCSGO) CGOPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Take", iAdmin, iClient, amount, "Currency", iAdmin);
				else CPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Take", iAdmin, iClient, amount, "Currency", iAdmin);
			}
			if(cfg_bLogs) LogToFile(logFile, "[Личный кабинет] Админ %N забрал со счета игрока %N %d руб.", iAdmin, iClient, amount);
		}
		case 2:
		{
			g_iClientInfo[iClient][Client_Cash]=amount;
			SavePlayer(iClient);
			if(iAdmin > 0) 
			{
				if(GameCSGO) CGOPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Set", iAdmin, iClient, amount, "Currency", iAdmin);
				else CPrintToChat(iAdmin, "%T %T", "Chat_Prefix", iAdmin, "Balance_Set", iAdmin, iClient, amount, "Currency", iAdmin);
			}
			if(cfg_bLogs) LogToFile(logFile, "[Личный кабинет] Админ %N установил счет игрока %N на %d руб.", iAdmin, iClient, amount);
		}
	}
	return Plugin_Handled;
}

public Action sm_lkkeysadd(int iAdmin, int iArgs)
{
	if(CmdFlood(iAdmin)) return Plugin_Handled;
	if(iArgs != 2)
	{
		PrintToConsole(iAdmin, "sm_lkkeysadd <кол-во 1-100> <руб>");
		return Plugin_Handled;
	}
	char info[52];
	GetCmdArg(1, info, 50);
	int count = StringToInt(info);
	if(count < 1 || count > 100)
	{
		PrintToConsole(iAdmin, "sm_lkkeysadd <кол-во 1-100> <руб>");
		return Plugin_Handled;
	}
	GetCmdArg(2, info, 50);
	int key_cash = -1;
	if((key_cash = StringToInt(info)) < 0)
	{
		PrintToConsole(iAdmin, "<руб> должен быть > 0");
		return Plugin_Handled;
	}
	char key[28], szQuery[352];
	DataPack hPack;
	if(iAdmin > 0) iAdmin = GetClientUserId(iAdmin);
	else iAdmin = 0;
	while(count > 0)
	{
		GetRandomKey(key, 25, 20);
		hPack = new DataPack();
		hPack.WriteCell(iAdmin);
		hPack.WriteString(key);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `lk_keys` (`key`, `key_cash`) VALUES ('%s', '%d')", key, key_cash);
		g_hDatabase.Query(sm_lkkeysadd_SqlCallBack, szQuery, hPack, DBPrio_High);
		count--;
	}
	return Plugin_Handled;
}

public void sm_lkkeysadd_SqlCallBack(Database hDatabase, DBResultSet results, const char[] szError, any hDataPack)
{
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	int iAdmin = hPack.ReadCell();
	if(iAdmin > 0 && (iAdmin = GetClientOfUserId(iAdmin)) < 1) iAdmin = 0;
	if(results)
	{
		if(results.AffectedRows > 0)
		{
			char key[28];
			hPack.ReadString(key, sizeof(key));
			PrintToConsole(iAdmin, key);
			if(iAdmin < 1)
			{
				char sFile[PLATFORM_MAX_PATH], thetime[85];
				FormatTime(thetime, sizeof(thetime), "%Y%m%d", GetTime());
				BuildPath(Path_SM, sFile, sizeof(sFile), "configs/lk/keys/keys_log_%s.log", thetime);
				LogToFileEx(sFile, "\nKey created: %s\n", key);
			}
		}
	}
	else
	{
		PrintToConsole(iAdmin, szError);
		LogError(szError);
	}
	delete hPack;
}

public Action sm_lkkeysdel(int iAdmin, int iArgs)
{
	if(CmdFlood(iAdmin)) return Plugin_Handled;
	if(iArgs < 1)
	{
		if(iAdmin > 0) iAdmin = GetClientUserId(iAdmin);
		else iAdmin = 0;
		g_hDatabase.Query(sm_lkkeysdel_SqlCallBack, "DELETE FROM `lk_keys`", iAdmin, DBPrio_High);
	}
	else
	{
		char key[28];
		GetCmdArg(1, key, 25);
		if(IsValidKeySyntax(key))
		{
			char szQuery[176];
			Format(szQuery, sizeof(szQuery), "DELETE FROM `lk_keys` WHERE `key` = '%s'", key);
			if(iAdmin > 0) iAdmin = GetClientUserId(iAdmin);
			else iAdmin = 0;
			g_hDatabase.Query(sm_lkkeysdel_SqlCallBack, szQuery, iAdmin, DBPrio_High);
		}
		else PrintToConsole(iAdmin, "Неверный ключ");
	}
	return Plugin_Handled;
}

public void sm_lkkeysdel_SqlCallBack(Database hDatabase, DBResultSet results, const char[] szError, any iAdmin)
{
	if(iAdmin > 0 && (iAdmin = GetClientOfUserId(iAdmin)) < 1) iAdmin = 0;
	if(results) PrintToConsole(iAdmin, "Ключей удалено: %d", results.AffectedRows);
	else
	{
		PrintToConsole(iAdmin, szError);
		LogError(szError);
	}
}

public Action sm_lkkeysdump(int iAdmin, int iArgs)
{
	if(CmdFlood(iAdmin)) return Plugin_Handled;
	if(iAdmin > 0) iAdmin = GetClientUserId(iAdmin);
	else iAdmin = 0;
	g_hDatabase.Query(sm_lkkeysdump_SqlCallBack, "SELECT `key`, `key_cash` FROM `lk_keys`", iAdmin, DBPrio_High);
	return Plugin_Handled;
}

public void sm_lkkeysdump_SqlCallBack(Database hDatabase, DBResultSet results, const char[] szError, any iAdmin)
{
	if(iAdmin > 0 && (iAdmin = GetClientOfUserId(iAdmin)) < 1) iAdmin = 0;
	if(results)
	{
		char sFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sFile, sizeof(sFile), "configs/lk/keys/lkkeys_dump.txt");
		File hFile = OpenFile(sFile, "w");
		if(hFile)
		{
			int x, key_cash;
			char key[28];
			while(results.FetchRow())
			{
				x++;
				results.FetchString(0, key, sizeof(key));
				key_cash = results.FetchInt(1);
				if(key_cash > -1)
				{
					hFile.WriteLine("%i) %s # %i руб.", x, key, key_cash);
					PrintToConsole(iAdmin, "%i) %s # %i руб.", x, key, key_cash);
				}
			}
			if(x < 1)
			{
				hFile.WriteLine("Database empty # База Данных пуста");
				PrintToConsole(iAdmin, "Database empty # База Данных пуста");
			}
			delete hFile;
		}
		else
		{
			PrintToConsole(iAdmin, "OpenFile error: configs/lk/keys/lkkeys_dump.txt");
			LogError("OpenFile error: configs/lk/keys/lkkeys_dump.txt");
		}
	}
	else
	{
		PrintToConsole(iAdmin, szError);
		LogError(szError);
	}
}

public Action sm_lkkey(int iClient, int iArgs)
{
	if(CmdFlood(iClient)) return Plugin_Handled;
	if(iClient < 0 || IsFakeClient(iClient)) return Plugin_Handled;
	if(iArgs != 1)
	{
		PrintToConsole(iClient, "sm_lkkey <ключ>");
		return Plugin_Handled;
	}
	char key[28];
	GetCmdArg(1, key, 25);
	if(!IsValidKeySyntax(key))
	{
		PrintToConsole(iClient, "Неверный ключ");
		return Plugin_Handled;
	}
	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(iClient));
	hPack.WriteString(key);
	char szQuery[252];
	Format(szQuery, sizeof(szQuery), "SELECT `key_cash` FROM `lk_keys` WHERE `key` = '%s'", key);
	g_hDatabase.Query(sm_lkkey_SqlCallBack, szQuery, hPack, DBPrio_High);
	return Plugin_Handled;
}

public void sm_lkkey_SqlCallBack(Database hDatabase, DBResultSet results, const char[] szError, any hDataPack)
{
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	int client_id = hPack.ReadCell();
	int iClient = GetClientOfUserId(client_id);
	char key[28];
	hPack.ReadString(key, sizeof(key));
	delete hPack;
	if(results || szError[0])
	{
		if(!results.FetchRow()) PrintToConsole(iClient, "Неверный ключ");
		else
		{
			int key_cash;
			key_cash = results.FetchInt(0);
			g_iClientInfo[iClient][Client_Cash] += key_cash;
			g_iClientInfo[iClient][Client_AllCash] += key_cash;
			SavePlayer(iClient);
			RemoveKey(key, iClient);
			PrintToConsole(iClient, "Ключ активирован");
			if(GameCSGO) CGOPrintToChat(iClient, "%T %T", "Chat_Prefix", iClient, "Success_Key_Activated", iClient, key, key_cash, "Currency", iClient);
			else CPrintToChat(iClient, "%T %T", "Chat_Prefix", iClient, "Success_Key_Activated", iClient, key, key_cash, "Currency", iClient);
			if(cfg_bLogs) LogToFile(logFile, "Игрок %N (%s) успешно пополнил свой баланс ключем ( %s ) на %i руб.", iClient, g_SteamID[iClient], key, key_cash);
		}
	}
	else
	{
		PrintToConsole(iClient, szError);
		LogError(szError);
	}
}