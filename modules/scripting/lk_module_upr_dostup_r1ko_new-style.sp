#pragma semicolon 1
#include <lk>
#include <vip_core>

char g_sItemName[] = "upr_dostup_r1ko";

public Plugin myinfo =
{
	name = "[LK MODULE] Управление доступом (VIP R1KO)",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Управление доступом (VIP R1KO)] Обновите ядро до последней версии");
	else
	{
		LoadTranslations("lk_module_upr_dostup_r1ko.phrases");
		LK_RegisterItem(g_sItemName, DostupCallback);
	}
}

public void DostupCallback(int iClient, int iItemID, const char[] sItemName)
{
	ShowMenuModule(iClient);
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);
}

void ShowMenuModule(int iClient)
{
	if(VIP_IsClientVIP(iClient))
	{
		char group[65], sExpTime[100], sTitle[256];
		int TIME = VIP_GetClientAccessTime(iClient);
		FormatTime(sExpTime, 100, "%d/%m/%Y - %H:%M", TIME);
		VIP_GetClientVIPGroup(iClient, group, 65);
		Menu hMenu = new Menu(MenuHandler_MainMenu);
		hMenu.ExitBackButton = true;
		LK_GetMainMenuTitle(iClient, sTitle, sizeof(sTitle));
		if(TIME) FormatEx(sTitle, sizeof(sTitle), "%s\nВаша группа: %s\nИстекает: [%s]\n--------------------------------", sTitle, group, sExpTime);
		else FormatEx(sTitle, sizeof(sTitle), "%s\nВаша группа: %s\nИстекает: НИКОГДА\n--------------------------------", sTitle, group);
		hMenu.SetTitle(sTitle);
		hMenu.AddItem("", "Отказатся от доступа");
		hMenu.Display(iClient, 0);
	}
	else
	{
		ClientCommand(iClient, "play *buttons/button11.wav");
		Panel hPanel = new Panel();
		hPanel.SetTitle("У вас нет VIP доступа.");
		hPanel.Send(iClient, MenuHandler_MyPanel, 30);
		delete hPanel;
	}
}

public int MenuHandler_MyPanel(Handle hMenu, MenuAction action, int iClient, int iItem)
{
}

public int MenuHandler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					Menu hMenu2 = new Menu(MenuHandler_MainMenu2);
					hMenu2.ExitButton = false;
					hMenu2.SetTitle("Вы уверены, что хотите отказатся от своего доступа?\nВернуть его невозможно.");
					hMenu2.AddItem("", "Да");
					hMenu2.AddItem("", "Нет");
					hMenu2.Display(iClient, 0);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) LK_ShowMainMenu(iClient);
		}
		case MenuAction_End: delete hMenu;
	}
}

public int MenuHandler_MainMenu2(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					char group[65], steamid[32];
					GetClientAuthId(iClient, AuthId_Steam2, steamid, 32, true);
					VIP_GetClientVIPGroup(iClient, group, 65);
					VIP_RemoveClientVIP2(0, iClient, true, true);
					LK_LogMessage("[Личный кабинет] Игрок %N (%s) удалил свой %s доступ.", iClient, steamid, group);
					LK_PrintToChat(iClient, "%t", "Remove_Client_VIP");
				}
				case 1: LK_PrintToChat(iClient, "%t", "Cancel_Remove_Client_VIP");
			}
		}
		case MenuAction_End: delete hMenu;
	}
}