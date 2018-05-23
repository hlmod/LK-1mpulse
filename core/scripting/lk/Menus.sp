void LK_ShowMainMenu(int iClient)
{
	if(g_iClientInfo[iClient][Client_Cash] >= 0)
	{
		if(g_ItemsCount < 1)
		{
			if(GameCSGO) CGOPrintToChat(iClient, "%T %T", "Chat_Prefix", iClient, "No_Module", iClient);
			else CPrintToChat(iClient, "%T %T", "Chat_Prefix", iClient, "No_Module", iClient);
			return;
		}
		char ItemName[52], text[76];
		Menu hMenu = new Menu(ShowMainMenu_CallBack);
		hMenu.SetTitle("%T", "MainMenu_Title", iClient, g_iClientInfo[iClient][Client_Cash], "Currency", iClient);
		for(int i; i < g_ItemsCount; i++)
		{
			char sInfo[128];
			g_hItemName.GetString(i, ItemName, sizeof(ItemName));
			FormatEx(text, sizeof(text), "%T", ItemName, iClient);
			FormatEx(sInfo, sizeof(sInfo), "%i;%s", g_hItemID.Get(i, 0, false), ItemName);
			hMenu.AddItem(sInfo, text);
		}
		hMenu.Display(iClient, 0);
	}
	else
	{
		ClientCommand(iClient, "play *buttons/button11.wav");
		Panel hPanel = new Panel();
		hPanel.SetTitle("Информация:");
		hPanel.DrawText(" ");
		hPanel.DrawText("Вам необходимно привязать ваш SteamID");
		hPanel.DrawText("к аккаунту на нашем сайте.");
		hPanel.Send(iClient, MenuHandler_MyPanel, 30);
	}
}

public int MenuHandler_MyPanel(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	delete hMenu;
}

public int ShowMainMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
        {
			char sInfo[128], sBuffers[2][64];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ";", sBuffers, 2, 64);
			int index = -1;
			if((index = g_hFuncArray.FindString(sBuffers[1])) != -1)
			{
				DataPack hPack;
				hPack = g_hFuncArray.Get(index+1);
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();
				if(IsCallValid(hPlugin, fncCallback))
				{
					Call_StartFunction(hPlugin, fncCallback);
					Call_PushCell(iClient);
					Call_PushCell(StringToInt(sBuffers[0]));
					Call_PushString(sBuffers[1]);
					Call_Finish();
				}
			}
        }
	}
}