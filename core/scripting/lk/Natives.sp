public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("LK_GetDatabase", LK_GetDatabase_);
	CreateNative("LK_RegisterItem", LK_RegisterItem_);
	CreateNative("LK_UnRegisterItem", LK_UnRegisterItem_);
	CreateNative("LK_ShowMainMenu", LK_ShowMainMenu_);
	CreateNative("LK_GetClientCash", LK_GetClientCash_);
	CreateNative("LK_SetClientCash", LK_SetClientCash_);
	CreateNative("LK_AddClientCash", LK_AddClientCash_);
	CreateNative("LK_TakeClientCash", LK_TakeClientCash_);
	CreateNative("LK_ResetClientCash", LK_ResetClientCash_);
	CreateNative("LK_GetClientAllCash", LK_GetClientAllCash_);
	CreateNative("LK_AddClientAllCash", LK_AddClientAllCash_);
	CreateNative("LK_ResetClientAllCash", LK_ResetClientAllCash_);
	CreateNative("LK_LogMessage", LK_LogMessage_);
	CreateNative("LK_PrintToChat", LK_PrintToChat_);
	CreateNative("LK_PrintToChatAll", LK_PrintToChatAll_);
	CreateNative("LK_GameCMS_Mode", LK_GameCMS_Mode_);
	CreateNative("LK_GetVersion", LK_GetVersion_);
	CreateNative("LK_GetMainMenuTitle", LK_GetMainMenuTitle_);
	CreateNative("LK_GetCurrency", LK_GetCurrency_);
	RegPluginLibrary("lk");
	return APLRes_Success;
}

public int LK_GetDatabase_(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int LK_RegisterItem_(Handle hPlugin, int iNumParams)
{
	char szItemName[64];
	GetNativeString(1, szItemName, sizeof(szItemName));
	Function fncCallback = GetNativeFunction(2);
	int iItemID = RegisterItem(szItemName);
	if(iItemID != -1)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(hPlugin);
		hPack.WriteFunction(fncCallback);
		
		g_hFuncArray.PushString(szItemName);
		g_hFuncArray.Push(hPack);
	}
	else LogError("LK_RegisterItem ошибка: Ключ '%s' уже занят", szItemName);
}

public int LK_UnRegisterItem_(Handle hPlugin, int iNumParams)
{
	int index = -1;
	char szItemName[64];
	if(GetNativeString(1, szItemName, sizeof(szItemName))) return;
	UnRegisterItem(szItemName);
	if((index = g_hFuncArray.FindString(szItemName)) != -1)
	{
		g_hFuncArray.Erase(index+1);
		g_hFuncArray.Erase(index);
	}
}

public int LK_ShowMainMenu_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidPlayer(iClient)) LK_ShowMainMenu(iClient);
	else LogError("LK_ShowMainMenu ошибка: Игрок не найден");
}

public int LK_GetClientCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidPlayer(iClient)) return g_iClientInfo[iClient][Client_Cash];
	else
	{
		LogError("LK_GetClientCash ошибка: Игрок не найден");
		return -1;
	}
}

public int LK_SetClientCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int amount = GetNativeCell(2);
	if(!IsValidPlayer(iClient)) LogError("LK_SetClientCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_Cash] = amount;
		SavePlayer(iClient);
	}
}

public int LK_AddClientCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int amount = GetNativeCell(2);
	if(!IsValidPlayer(iClient)) LogError("LK_AddClientCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_Cash] += amount;
		SavePlayer(iClient);
	}
}

public int LK_TakeClientCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int amount = GetNativeCell(2);
	if(!IsValidPlayer(iClient)) LogError("LK_TakeClientCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_Cash] -= amount;
		if(g_iClientInfo[iClient][Client_Cash] < 0) g_iClientInfo[iClient][Client_Cash] = 0;
		SavePlayer(iClient);
	}
}

public int LK_ResetClientCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(!IsValidPlayer(iClient)) LogError("LK_ResetClientCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_Cash] = 0;
		SavePlayer(iClient);
	}
}

public int LK_GetClientAllCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidPlayer(iClient)) return g_iClientInfo[iClient][Client_AllCash];
	else
	{
		LogError("LK_GetClientAllCash ошибка: Игрок не найден");
		return -1;
	}
}

public int LK_AddClientAllCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int amount = GetNativeCell(2);
	if(!IsValidPlayer(iClient)) LogError("LK_AddClientAllCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_AllCash] += amount;
		SavePlayer(iClient);
	}
}

public int LK_ResetClientAllCash_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(!IsValidPlayer(iClient)) LogError("LK_ResetClientAllCash ошибка: Игрок не найден");
	else
	{
		g_iClientInfo[iClient][Client_AllCash] = 0;
		SavePlayer(iClient);
	}
}

public int LK_LogMessage_(Handle hPlugin, int iNumParams)
{
	if(cfg_bLogs)
	{
		char sMessage[512];
		SetGlobalTransTarget(LANG_SERVER);
		FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
		LogToFile(logFile, sMessage);
	}
}

public int LK_PrintToChat_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	char sMessage[512];
	SetGlobalTransTarget(LANG_SERVER);
	FormatNativeString(0, 2, 3, sizeof(sMessage), _, sMessage);
	if(GameCSGO) CGOPrintToChat(iClient, "%T %s", "Chat_Prefix", iClient, sMessage);
	else CPrintToChat(iClient, "%T %s", "Chat_Prefix", iClient, sMessage);
}

public int LK_PrintToChatAll_(Handle hPlugin, int iNumParams)
{
	char sMessage[512];
	SetGlobalTransTarget(LANG_SERVER);
	FormatNativeString(0, 1, 2, sizeof(sMessage), _, sMessage);
	if(GameCSGO) CGOPrintToChatAll("%t %s", "Chat_Prefix", sMessage);
	else CPrintToChatAll("%t %s", "Chat_Prefix", sMessage);
}

public int LK_GameCMS_Mode_(Handle hPlugin, int iNumParams)
{
	return cfg_bGameCMS;
}

public int LK_GetVersion_(Handle hPlugin, int iNumParams)
{
	char sVersion[32];
	strcopy(sVersion, sizeof(sVersion), VERSION_PLUGIN);
	ReplaceString(sVersion, sizeof(sVersion), ".", "");
	return StringToInt(sVersion);
}

public int LK_GetMainMenuTitle_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidPlayer(iClient))
	{
		char sTitle[256];
		sTitle[0] = 0;
		FormatEx(sTitle, sizeof(sTitle), "%T", "MainMenu_Title", iClient, g_iClientInfo[iClient][Client_Cash], "Currency", iClient);
		SetNativeString(2, sTitle, GetNativeCell(3), true);
		return true;
	}
	SetNativeString(2, NULL_STRING, GetNativeCell(3), true);
	return false;
}

public int LK_GetCurrency_(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidPlayer(iClient))
	{
		char sTitle[256];
		sTitle[0] = 0;
		FormatEx(sTitle, sizeof(sTitle), "%T", "Currency", iClient);
		SetNativeString(2, sTitle, GetNativeCell(3), true);
		return true;
	}
	SetNativeString(2, NULL_STRING, GetNativeCell(3), true);
	return false;
}