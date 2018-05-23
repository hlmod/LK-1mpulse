#pragma semicolon 1
#include <lk>

char g_sItemName[] = "info_menu";
Panel hPanel;

public Plugin myinfo =
{
	name = "[LK MODULE] Info Menu",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.0"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][Info Menu] Обновите ядро до последней версии");
	else LK_RegisterItem(g_sItemName, Info_Callback);
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);
}

public void OnMapStart()
{
	if(hPanel) delete hPanel;
	hPanel = new Panel();
	bool bAdded;
	char file[255];
	BuildPath(Path_SM, file, sizeof(file), "configs/lk/lk_module_info_menu.ini");
	File hFile = OpenFile(file, "r");
	if(hFile)
	{
		char info[752];
		while(!hFile.EndOfFile() && hFile.ReadLine(info, sizeof(info)))
		{
			if(info[0] != '/')
			{
				if(TrimString(info) > 0) hPanel.DrawText(info);
				else hPanel.DrawText(" ");
				bAdded = true;
			}
		}
		hPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		hPanel.DrawItem("Назад");
		delete hFile;
	}
	if (!bAdded)
	{
		delete hPanel;
		hPanel = null;
	}
}

public void Info_Callback(int iClient, int ItemID, const char[] ItemName)
{
	if(hPanel) hPanel.Send(iClient, MenuHandler_MyPanel, 30);
}

public int MenuHandler_MyPanel(Handle hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 1: LK_ShowMainMenu(iClient);
			}
		}
	}
}