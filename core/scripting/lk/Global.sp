enum Client_Parametrs
{
	_:Client_Cash,
	_:Client_AllCash,
}

int g_iClientInfo[MAXPLAYERS+1][Client_Parametrs], g_ItemsCount;
char g_SteamID[MAXPLAYERS+1][32], logFile[512];
bool cfg_bLogs, cfg_bGameCMS, GameCSGO;
Handle hLK_OnKeyWasUsed, hLK_OnLoaded, hSortTimer;
Database g_hDatabase;
ArrayList g_hItemName, g_hItemID, g_hFuncArray;