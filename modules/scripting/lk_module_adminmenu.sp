#pragma semicolon 1
#include <lk>
#include <adminmenu>

char steamid[MAXPLAYERS + 1][32];
int cl[MAXPLAYERS+1];
Menu Menu2, Menu3, Menu4;
TopMenu g_hAdminMenu = null;

public Plugin myinfo =
{
	name = "[LK MODULE] Админ Меню",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void OnPluginStart()
{
	LoadTranslations("lk_module_adminmenu.phrases");
	Create_Menu();
	TopMenu hTopMenu;
	if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
}

Create_Menu()
{
	Menu2 = new Menu(Menu2Handler);
	Menu2.ExitBackButton = true;
	Menu2.AddItem("", "Добавить на счет");
	Menu2.AddItem("", "Забрать со счета");
	Menu2.AddItem("", "Обнулить счет игрока");

	Menu3 = new Menu(Menu3Handler);
	Menu3.ExitBackButton = true;
	Menu3.AddItem("1", "1");
	Menu3.AddItem("10", "10");
	Menu3.AddItem("50", "50");
	Menu3.AddItem("100", "100");
	Menu3.AddItem("200", "200");
	Menu3.AddItem("500", "500");
	
	Menu4 = new Menu(Menu4Handler);
	Menu4.ExitBackButton = true;
	Menu4.AddItem("1", "1");
	Menu4.AddItem("10", "10");
	Menu4.AddItem("50", "50");
	Menu4.AddItem("100", "100");
	Menu4.AddItem("200", "200");
	Menu4.AddItem("500", "500");
}

public void OnClientPutInServer(iClient)
{
	GetClientAuthId(iClient, AuthId_Steam2, steamid[iClient], 32, true);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (hTopMenu == g_hAdminMenu) return;
	g_hAdminMenu = hTopMenu;
	TopMenuObject hMyCategory = g_hAdminMenu.AddCategory("sm_lk_root_category", TopMenuCallBack, "sm_lk_root", ADMFLAG_ROOT, "Управление Личным Кабинетом");
	if (hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hAdminMenu.AddItem("sm_lk_upr_menu_item", MenuCallBack1, hMyCategory, "sm_lk_upr_menu", ADMFLAG_ROOT, "Управление игроками");
		g_hAdminMenu.AddItem("sm_lk_player_balance_menu_item", MenuCallBack2, hMyCategory, "sm_lk_player_balance_menu", ADMFLAG_ROOT, "Баланс ЛК игроков онлайн");
	}
}

public void TopMenuCallBack(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Управление Личным Кабинетом");
		case TopMenuAction_DisplayTitle: FormatEx(sBuffer, maxlength, "Управление Личным Кабинетом");
	}
}

public void MenuCallBack1(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Управление игроками");
		case TopMenuAction_SelectOption: Select_PL_MENU(iClient);
	}
}

public void MenuCallBack2(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Баланс ЛК игроков онлайн");
		case TopMenuAction_SelectOption: ADMINTab(iClient);
	}
}

void ADMINTab(int iClient)
{
	if (!(0 < iClient <= MaxClients)) return;
	char name[64], CashINFO[64], menuINFO[64];
	Menu hMenu = new Menu(MenuHandler_ADMINTab);
	hMenu.SetTitle("Баланс ЛК игроков онлайн:\n \n");
	hMenu.ExitBackButton = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, name, sizeof(name));
			int targetindex = FindTarget(iClient, name);
			int TargetCash = LK_GetClientCash(targetindex);
			FormatEx(CashINFO, 64, "[%i руб.]", TargetCash);
			FormatEx(menuINFO, 64, "%s %s", name, CashINFO);
			hMenu.AddItem("", menuINFO, ITEMDRAW_DISABLED);
		}
	}
	hMenu.Display(iClient, 0);
}

public int MenuHandler_ADMINTab(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);	
        }
	}
}

void Select_PL_MENU(int iClient)
{
	char userid[15], name[64];
	Menu hMenu = new Menu(MenuHandler_Select_PL);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Выберите Игрока:");
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), userid, 15);
			GetClientName(i, name, 64);
			hMenu.AddItem(userid, name);
		}
	}
	hMenu.Display(iClient, 0);
}

public int MenuHandler_Select_PL(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
        }
		case MenuAction_Select:
		{
			char userid[15];
			hMenu.GetItem(iItem, userid, 15);
			int u = StringToInt(userid);
			int target = GetClientOfUserId(u);
			if(target)
			{
				cl[iClient] = u;
				int TargetCash = LK_GetClientCash(target);
				Menu2.SetTitle("Управление %N - %i руб.", target, TargetCash);
				Menu2.Display(iClient, 0);
			}
			else 
			{
				LK_PrintToChat(iClient, "%t", "Player_Disconnect");
				g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
			}
		}
	}
}

public int Menu2Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) Select_PL_MENU(iClient);
		}
		case MenuAction_Select:
		{
			int ch = GetClientOfUserId(cl[iClient]);
			if(ch)
			{
				switch(iItem)
				{
					case 0:
					{
						int chCash = LK_GetClientCash(ch);
						Menu3.SetTitle("Добавить на счет %N - %i руб.", ch, chCash);
						Menu3.Display(iClient, 0);
					}
					case 1:
					{
						int chCash = LK_GetClientCash(ch);
						Menu4.SetTitle("Забрать со счета %N - %i руб.", ch, chCash);
						Menu4.Display(iClient, 0);
					}
					case 2:
					{
						LK_ResetClientCash(ch);
						LK_LogMessage("[Личный кабинет] Админ %N (%s) обнулил счет игроку %N (%s)", iClient, steamid[iClient], ch, steamid[ch]);
						LK_PrintToChat(iClient, "%t", "Reset_Print_To_Admin", ch);
						LK_PrintToChat(ch, "%t", "Reset_Print_To_Client", iClient);
						int chCash = LK_GetClientCash(ch);
						Menu2.SetTitle("Управление %N - %i руб.", ch, chCash);
						Menu2.Display(iClient, 0);
					}
				}
			}
			else
			{
				LK_PrintToChat(iClient, "%t", "Player_Disconnect");
				g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
			}
		}
	}
}

public int Menu3Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				int ch = GetClientOfUserId(cl[iClient]);
				if(ch)
				{
					int chCash = LK_GetClientCash(ch);
					Menu2.SetTitle("Управление %N - %i руб.", ch, chCash);
					Menu2.Display(iClient, 0);
				}
				else
				{
					LK_PrintToChat(iClient, "%t", "Player_Disconnect");
					g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
				}
			}
		}
		case MenuAction_Select:
		{
			int ch = GetClientOfUserId(cl[iClient]);
			if(ch)
			{
				char h[15];
				hMenu.GetItem(iItem, h, 15);
				int u = StringToInt(h);
				LK_LogMessage("[Личный кабинет] Админ %N (%s) пополнил счет игроку %N (%s) на %d руб.", iClient, steamid[iClient], ch, steamid[ch], u);
				LK_AddClientCash(ch, u);
				LK_AddClientAllCash(ch, u);
				LK_PrintToChat(iClient, "%t", "Give_Print_To_Admin", ch, u);
				LK_PrintToChat(ch, "%t", "Give_Print_To_Client", iClient, u);
				int chCash = LK_GetClientCash(ch);
				Menu3.SetTitle("Добавить на счет %N - %i руб.", ch, chCash);
				Menu3.Display(iClient, 0);
			}
			else
			{
				LK_PrintToChat(iClient, "%t", "Player_Disconnect");
				g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
			}
		}
	}
}

public int Menu4Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				int ch = GetClientOfUserId(cl[iClient]);
				if(ch)
				{
					int chCash = LK_GetClientCash(ch);
					Menu2.SetTitle("Управление %N - %i руб.", ch, chCash);
					Menu2.Display(iClient, 0);
				}
				else
				{
					LK_PrintToChat(iClient, "%t", "Player_Disconnect");
					g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
				}
			}
		}
		case MenuAction_Select:
		{
			int ch = GetClientOfUserId(cl[iClient]);
			if(ch)
			{
				char h[15];
				hMenu.GetItem(iItem, h, 15);
				int u = StringToInt(h);
				int chCash = LK_GetClientCash(ch);
				if(chCash > 0) 
				{
					LK_TakeClientCash(ch, u);
					LK_LogMessage("[Личный кабинет] Админ %N (%s) забрал со счета игрока %N (%s) %d руб.", iClient, steamid[iClient], ch, steamid[ch], u);
				}
				int chCash2 = LK_GetClientCash(ch);
				if(chCash2 < 0) LK_ResetClientCash(iClient);
				LK_PrintToChat(iClient, "%t", "Take_Print_To_Client", ch, u);
				LK_PrintToChat(ch, "%t", "Take_Print_To_Admin", iClient, u);
				Menu4.SetTitle("Забрать со счета %N - %i руб.", ch, chCash);
				Menu4.Display(iClient, 0);
			}
			else
			{
				LK_PrintToChat(iClient, "%t", "Player_Disconnect");
				g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
			}
		}
	}
}