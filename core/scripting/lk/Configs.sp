void Load_KFG()
{
	char sDirectory[64], sDirectoryKeys[64];
	BuildPath(Path_SM, sDirectory, sizeof(sDirectory), "logs/lk");
	BuildPath(Path_SM, sDirectoryKeys, sizeof(sDirectoryKeys), "configs/lk/keys");
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/lk/lk.log");
	if(!DirExists(sDirectory)) CreateDirectory(sDirectory, 511);
	if(!DirExists(sDirectoryKeys)) CreateDirectory(sDirectoryKeys, 511);
	if(!FileExists(logFile)) CloseHandle(CreateFile(logFile, "a"));
	
	char szBuffer[PLATFORM_MAX_PATH];
	KeyValues hKV = new KeyValues("LK_CORE");
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/lk/lk_core.ini");
	if(!hKV.ImportFromFile(szBuffer)) LogError("[LK CORE] - Файл конфигураций не найден");
	hKV.Rewind();
	cfg_bGameCMS = hKV.GetNum("GameCMS", 0)?true:false;
	cfg_bLogs = hKV.GetNum("logs", 1)?true:false;
	char uo[512];
	hKV.GetString("commands_open_menu", uo, sizeof(uo), "sm_lk");
	int iPos;
	while(iPos != -1) 
	{
		iPos = FindCharInString(uo, ';', true);
		RegConsoleCmd(uo[iPos+1], sm_lk);
		if(iPos != -1) uo[iPos] = 0;
    }
}