#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <lk>
#include <old_vip_core>

#define MAX_GROUPS 16
#define MAX_TIMES 16

enum enum_Groups
{
	String:GroupName[64],
	String:VIPGroup[64],
	_:TimesCount,
}

enum enum_Times
{
	String:TimesName[64],
	_:Days,
	_:Price,
}

int g_iGroups;
char g_sItemName[] = "pokupka_vip_r1ko";
int g_Groups[MAX_GROUPS][enum_Groups], g_Times[MAX_GROUPS][MAX_TIMES][enum_Times];

public Plugin myinfo =
{
	name = "[LK MODULE] Покупка VIP (VIP R1KO)",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Покупка VIP (VIP R1KO)] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_pokupka_vip_r1ko.phrases");
		LK_RegisterItem(g_sItemName, BuyVIP_Callback);
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

public void BuyVIP_Callback(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	char sTitle[256];
	LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle(sTitle);
	for(int i = 0; i < g_iGroups; i++)
	{
		char szBuffer[16];
		IntToString(i, szBuffer, sizeof(szBuffer));
		hMenu.AddItem(szBuffer, g_Groups[i][GroupName]);
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
			char szInfo[16], sTitle[256];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			int i = StringToInt(szInfo);
			int ClientCash = LK_GetClientCash(iClient);
			LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
			Menu hMenu2 = new Menu(MenuHandler_MainMenu2);
			hMenu2.ExitBackButton = true;
			hMenu2.SetTitle(sTitle);
			for(int j = 0; j < g_Groups[i][TimesCount]; j++)
			{
				char szBuffer[16];
				FormatEx(szBuffer, sizeof(szBuffer), "%i|%i", i, j);
				hMenu2.AddItem(szBuffer, g_Times[i][j][TimesName], ClientCash >= g_Times[i][j][Price] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			}
			hMenu2.Display(iClient, 0);
        }
    }
}

public int MenuHandler_MainMenu2(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) ShowMenuModule(iClient);
		}
		case MenuAction_Select:
        {
			char szInfo[16], sBuffers[2][16], sAuth[32];
			GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			ExplodeString(szInfo, "|", sBuffers, 2, 16);
			int i = StringToInt(sBuffers[0]);
			int j = StringToInt(sBuffers[1]);
			if(VIP_IsClientVIP(iClient))
			{
				int VIPTIME = VIP_GetClientAccessTime(iClient);
				if(VIPTIME)
				{
					char szBuffer[64];
					VIP_GetClientVIPGroup(iClient, szBuffer, sizeof(szBuffer));
					if(StrEqual(g_Groups[i][VIPGroup], szBuffer, true))
					{
						if(g_Times[i][j][Days] != 0)
						{
							int OldVIPTime = VIP_GetClientAccessTime(iClient);
							int OldSeconds = VIP_TimeToSeconds(OldVIPTime);
							int AddVIPTime = g_Times[i][j][Days]*86400;
							int NewSeconds = AddVIPTime+OldSeconds;
							int NewSetTime = VIP_SecondsToTime(NewSeconds);
							VIP_SetClientAccessTime(iClient, NewSetTime, true);
							LK_TakeClientCash(iClient, g_Times[i][j][Price]);
							LK_PrintToChat(iClient, "%T", "VIP_AddTime", iClient, g_Groups[i][VIPGroup], g_Times[i][j][Days]);
							LK_LogMessage("[Личный кабинет] Игрок %N (%s) продлил %s на %i дней.", iClient, sAuth, g_Groups[i][VIPGroup], g_Times[i][j][Days]);
						}
						else LK_PrintToChat(iClient, "%T", "No_Buy_Forever", iClient);
					}
					else LK_PrintToChat(iClient, "%T", "No_Buy", iClient);
				}
				else LK_PrintToChat(iClient, "%T", "Already_Forever", iClient);
			}
			else
			{
				int SetTime = g_Times[i][j][Days]*86400;
				VIP_SetClientVIP(iClient, SetTime, AUTH_STEAM, g_Groups[i][VIPGroup], true);
				LK_TakeClientCash(iClient, g_Times[i][j][Price]);
				if(g_Times[i][j][Days] == 0)
				{
					LK_PrintToChat(iClient, "%T", "Buy_Forever", iClient, g_Groups[i][VIPGroup]);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %s навсегда.", iClient, sAuth, g_Groups[i][VIPGroup]);
				}
				else
				{
					LK_PrintToChat(iClient, "%T", "Buy_Time", iClient, g_Groups[i][VIPGroup], g_Times[i][j][Days]);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) купил %s на %i дней.", iClient, sAuth, g_Groups[i][VIPGroup], g_Times[i][j][Days]);
				}
			}
		}
	}
}

void KFG_load()
{
	char sPath[128];
	KeyValues KV = new KeyValues("LK_MODULE");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/lk/lk_module_pokupka_vip_r1ko.ini");
	if(!KV.ImportFromFile(sPath)) SetFailState("[LK MODULE][Покупка VIP R1KO] - Файл конфигураций не найден");
	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		g_iGroups = 0;
		do 
		{
			if(KV.GetSectionName(g_Groups[g_iGroups][GroupName], 64))
			{
				KV.GetString("groups", g_Groups[g_iGroups][VIPGroup], 64);
				if(KV.JumpToKey("times", false))
				{
					if(KV.GotoFirstSubKey(true))
					{
						g_Groups[g_iGroups][TimesCount] = 0;
						do 
						{
							if(KV.GetSectionName(g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][TimesName], 64))
							{
								g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Days] = KV.GetNum("days");
								if(g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Days] < 0) g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Days] = 0;
								g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Price] = KV.GetNum("price");
								if(g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Price] < 0) g_Times[g_iGroups][g_Groups[g_iGroups][TimesCount]][Price] = 0;
								g_Groups[g_iGroups][TimesCount] += 1;
							}
						} while(KV.GotoNextKey(true));
						KV.GoBack();
					}
					KV.GoBack();
				}
				g_iGroups += 1;
			}
		} while(KV.GotoNextKey(true));
	}
}