#pragma semicolon 1
#include <sourcemod>
#include <lk>

enum Bet
{
	String:Amount[512],
	String:Name[512],
}

int		BetsCount, iPercent, iTransfer[MAXPLAYERS+1], Bets[64][Bet];
char 	steamid[MAXPLAYERS+1][32];
char 	g_sItemName[] = "transfer_rub";

public Plugin myinfo =
{
	name = "[LK MODULE] Перевод Денег",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Перевод Денег] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_transfer_rub.phrases");
		LK_RegisterItem(g_sItemName, TransferCallBack);
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

public void OnClientPutInServer(iClient)
{
	GetClientAuthId(iClient, AuthId_Steam2, steamid[iClient], 32, true);
}

public void TransferCallBack(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuTransfer(iClient);
}

void ShowMenuTransfer(int iClient)
{
	int ClientCash = LK_GetClientCash(iClient);
	char sTitle[256];
	Menu hMenu = new Menu(MenuHandler_MenuTransfer);
	hMenu.ExitBackButton = true;
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	FormatEx(sTitle, sizeof(sTitle), "%s\nВыберите сумму:\n ",sTitle);
	hMenu.SetTitle(sTitle);
	for (int i = 0; i < BetsCount; i++)
	{
		hMenu.AddItem(Bets[i][Amount], Bets[i][Name], ClientCash < StringToInt(Bets[i][Amount]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	hMenu.Display(iClient, 0);
}

public int MenuHandler_MenuTransfer(Menu hMenu, MenuAction action, int iClient, int iItem)
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
			iTransfer[iClient] = StringToInt(szInfo);
			ShowMenuTarget(iClient);
		}
	}
}

void ShowMenuTarget(int iClient)
{
	char userid[15], name[64];
	int iClientid = GetClientUserId(iClient);
	Menu hMenu = new Menu(MenuHandler_Select_PL);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Выберите Игрока:\n \n");
	int players;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(iClientid != GetClientUserId(i))
			{
				IntToString(GetClientUserId(i), userid, 15);
				GetClientName(i, name, 64);
				hMenu.AddItem(userid, name);
				players++;
			}
		}
	}
	if(players == 0) hMenu.AddItem("", "Игроков нет", ITEMDRAW_DISABLED);
	hMenu.Display(iClient, 0);
}

public int MenuHandler_Select_PL(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) ShowMenuTransfer(iClient);
        }
		case MenuAction_Select:
		{
			char userid[15];
			hMenu.GetItem(iItem, userid, 15);
			int u = StringToInt(userid);
			int target = GetClientOfUserId(u);
			if(target)
			{
				int Itogo;
				if(iPercent > 0) Itogo = (iTransfer[iClient]/100)*(100+iPercent);
				else Itogo = iTransfer[iClient];
				Menu hMenu2 = new Menu(MenuHandler_EndTransfer);
				hMenu2.SetTitle("Вы хотите перевести игроку %N\nСумма: %i\nКомиссия: %i%%\nИтого: %i\n ", target, iTransfer[iClient], iPercent, Itogo);
				hMenu2.AddItem(userid, "Выполнить перевод");
				hMenu2.Display(iClient, 0);
			}
			else LK_PrintToChat(iClient, "%t", "Player_Disconnect");
		}
	}
}

public int MenuHandler_EndTransfer(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char userid[15];
			hMenu.GetItem(iItem, userid, 15);
			int u = StringToInt(userid);
			int target = GetClientOfUserId(u);
			if(target)
			{
				int ClientCash = LK_GetClientCash(iClient);
				int Itogo;
				if(iPercent > 0) Itogo = (iTransfer[iClient]/100)*(100+iPercent);
				else Itogo = iTransfer[iClient];
				if(ClientCash >= Itogo)
				{
					LK_TakeClientCash(iClient, Itogo);
					LK_AddClientCash(target, iTransfer[iClient]);
					LK_PrintToChat(iClient, "%t", "Transfer_from", target, iTransfer[iClient]);
					LK_PrintToChat(target, "%t", "Transfer_to", iClient, iTransfer[iClient]);
					LK_LogMessage("[Личный Кабинет] Игрок %N (%s) перевел игроку %N (%s) сумму %i, заплатив %i", iClient, steamid[iClient], target, steamid[target], iTransfer[iClient], Itogo);
					iTransfer[iClient] = 0;
				}
				else LK_PrintToChat(iClient, "%t", "No_Money");
			}
			else LK_PrintToChat(iClient, "%t", "Player_Disconnect");
		}
	}
}

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, path, 128, "configs/lk/lk_module_transfer_rub.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[LK MODULE][Перевод Денег] - Файл конфигураций не найден");
	
	iPercent = kfg.GetNum("percent", 0);
	if(kfg.JumpToKey("transfer", false) && kfg.GotoFirstSubKey(false))
	{
		char amount[64], name[64];
		BetsCount = -1;
		do 
		{
			if(kfg.GetSectionName(amount, sizeof(amount)))
			{
				kfg.GetString(NULL_STRING, name, sizeof(name));
				if(amount[0])
				{
					BetsCount+=1;
					strcopy(Bets[BetsCount][Amount], 64, amount);
					strcopy(Bets[BetsCount][Name], 64, name);
				}
			}
		} while (kfg.GotoNextKey(false));
	}
	delete kfg;
}