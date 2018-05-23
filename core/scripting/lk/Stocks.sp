stock bool IsValidPlayer(int iClient)
{
	return (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient));
}

stock bool ItemNameAlreadyExist(const char[] ItemName)
{
	return g_hItemName.FindString(ItemName) > -1;
}

stock void UnRegisterItem(const char[] ItemName)
{
	int index = g_hItemName.FindString(ItemName);
	if(index < 0) return;
	g_ItemsCount -= 1;
	g_hItemName.Erase(index);
	g_hItemID.Erase(index);
	RestartSortTimer();
}

stock int RegisterItem(const char[] ItemName)
{
	if(ItemNameAlreadyExist(ItemName)) return -1;
	int ItemID = CreateItemID();
	g_hItemName.PushString(ItemName);
	g_hItemID.Push(ItemID);
	g_ItemsCount += 1;
	RestartSortTimer();
	return ItemID;
}

stock int CreateItemID()
{
	static int id = 1;
	id += 1;
	return id;
}

stock void CreateArrays()
{
	g_hItemName = new ArrayList(ByteCountToCells(50));
	g_hItemID = new ArrayList(ByteCountToCells(1));
	g_hFuncArray = new ArrayList(ByteCountToCells(64));
}

stock void ClearArrays()
{
	g_hItemName.Clear();
	g_hItemID.Clear();
	
	int iSize = g_hFuncArray.Length;
	for(int i = 1; i < iSize; i+=2)
	{
		CloseHandle(view_as<Handle>(g_hFuncArray.Get(i)));
	}
	g_hFuncArray.Clear();
}

stock void RemoveKey(const char[] key, int iClient)
{
	char szQuery[176];
	Format(szQuery, sizeof(szQuery), "DELETE FROM `lk_keys` WHERE `key` = '%s'", key);
	g_hDatabase.Query(SQL_Callback_CheckError, szQuery, _, DBPrio_High);
	Call_StartForward(hLK_OnKeyWasUsed);
	Call_PushCell(iClient);
	Call_PushString(g_SteamID[iClient]);
	Call_PushString(key);
	Call_Finish();
}

stock void GetRandomKey(char[] key, int maxlength, int key_symbols)
{
	static char s[62][16] =
	{
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0",
		"q",
		"w",
		"e",
		"r",
		"t",
		"y",
		"u",
		"i",
		"o",
		"p",
		"a",
		"s",
		"d",
		"f",
		"g",
		"h",
		"j",
		"k",
		"l",
		"z",
		"x",
		"c",
		"v",
		"b",
		"n",
		"m",
		"Q",
		"W",
		"E",
		"R",
		"T",
		"Y",
		"U",
		"I",
		"O",
		"P",
		"A",
		"S",
		"D",
		"F",
		"G",
		"H",
		"J",
		"K",
		"L",
		"Z",
		"X",
		"C",
		"V",
		"B",
		"N",
		"M"
	};
	Format(key, maxlength, "");
	for(int i = 1; i <= key_symbols; i++)
	{
		if(key[0]) Format(key, maxlength, "%s%s", key, s[GetRandomInt(0, 61)]);
		else strcopy(key, maxlength, s[GetRandomInt(0, 61)]);
	}
}

stock bool IsValidKeySyntax(const char[] info)
{
	int symbols = strlen(info);
	for(int i; i < symbols; i++)
	{
		if(!IsCharNumeric(info[i]) && !IsCharAlpha(info[i])) return false;
	}
	return true;
}

stock Handle CreateFile(const char[] path, const char[] mode = "w+")
{
	char dir[8][PLATFORM_MAX_PATH];
	int count = ExplodeString(path, "/", dir, 8, sizeof(dir[]));
	for(int i = 0; i < count-1; i++)
	{
		if(i > 0)
			Format(dir[i], sizeof(dir[]), "%s/%s", dir[i-1], dir[i]);
			
		if(!DirExists(dir[i]))
			CreateDirectory(dir[i], 511);
	}
	
	return OpenFile(path, mode);
}

stock bool CmdFlood(int iClient)
{
	static int last_time[MAXPLAYERS + 1];
	int curr_time = GetTime();
	if((curr_time - last_time[iClient]) < 5)
	{
		PrintToConsole(iClient, "Подождите...");
		return true;
	}
	last_time[iClient] = curr_time;
	return false;
}

stock void RestartSortTimer()
{
	if(hSortTimer) KillTimer(hSortTimer, false);
	hSortTimer = CreateTimer(2.0, SortTimer_CallBack, _);
}

public Action SortTimer_CallBack(Handle hTimer)
{
	hSortTimer = null;
	ArrayList hName = new ArrayList(ByteCountToCells(50));
	ArrayList hItemID = new ArrayList(ByteCountToCells(1));
	hName = g_hItemName.Clone();
	hItemID = g_hItemID.Clone();
	int ItemsCount = hName.Length;
	if(ItemsCount < 1) return Plugin_Stop;
	char file[255];
	BuildPath(Path_SM, file, sizeof(file), "configs/lk/core_sort.ini");
	if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
	File hFile = OpenFile(file, "r");
	if(hFile)
	{
		int index;
		char ItemName[52];
		ArrayList hNewItemName = new ArrayList(ByteCountToCells(50));
		ArrayList hNewItemID = new ArrayList(ByteCountToCells(1));
		while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, 50))
		{
			if(TrimString(ItemName) > 0 && hNewItemName.FindString(ItemName) < 0 && (index = hName.FindString(ItemName)) > -1)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hItemID.Get(index, 0, false));
			}
		}
		for(int i = 0; i < ItemsCount; i++)
		{
			hName.GetString(i, ItemName, 50);
			if(hNewItemName.FindString(ItemName) < 0)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hItemID.Get(i, 0, false));
			}
		}
		g_hItemName = hNewItemName.Clone();
		g_hItemID = hNewItemID.Clone();
		g_ItemsCount = g_hItemName.Length;
		delete hFile;
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

stock bool IsCallValid(Handle hPlugin, Function ptrFunction) 
{
	return (ptrFunction != INVALID_FUNCTION && IsPluginValid(hPlugin));
}

stock bool IsPluginValid(Handle hPlugin)
{
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;
	
	while(MorePlugins(hIterator))
	{
		if(hPlugin == ReadPlugin(hIterator))
		{
			bIsValid = (GetPluginStatus(hPlugin) == Plugin_Running);
			break;
		}
	}
	
	delete hIterator;
	return bIsValid;
}