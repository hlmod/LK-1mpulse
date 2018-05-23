#pragma semicolon 1
#include <lk>//Подключаем библиотеку ЛК

Database g_hDatabase;
char g_sItemName[] = "top10";//Создаем переменную с нашим ключем, "top10" уникальный ключ, повторений ключей быть не должно

public Plugin myinfo =
{
	name = "[LK MODULE] ТОП10 Донатеров",
	author = "1mpulse (skype:potapovdima1)",
	version = "4.0.1"
};

public void LK_OnLoaded()
{
	if(LK_GetVersion() < 400) LogError("[LK MODULE][ТОП10 Донатеров] Обновите ядро до последней версии");//Проверяем чтобы ядро ЛК было актуальной версии, на inc который мы пишем модуль, так как inc постоянно пополняется новыми нативами, чтобы не было конфликтов с более старом ядре.
	else
	{
		if(!LK_GameCMS_Mode())//Проверяем что ЛК работает не в режиме GameCMS
		{
			LoadTranslations("lk.phrases");
			LK_RegisterItem(g_sItemName, TOP10Callback);//Регестрируем наш ключ. Регистрация модулей(итемов) только в 'public void LK_OnLoaded()'
		}
		else LogError("[LK MODULE][ТОП10 Донатеров] Данный модуль не совместим с ядром в режиме GameCMS");
	}
}

public void OnPluginEnd()
{
	LK_UnRegisterItem(g_sItemName);//Удалям ключ(итем) из меню ЛК. Чтобы после того как делаем reload модуля или отключаем его принудительно он убрался из меню ЛК, иначе ошибки.
}

public void TOP10Callback(int iClient, int iItemID, const char[] iItemName)//Вызывается наш Callback, когда игрок нажимает в меню, на наш ключ(итем)
{
	TopDonatorSelect(iClient);//Далее создаем меню.
}

void TopDonatorSelect(iClient)
{
	g_hDatabase = LK_GetDatabase();//Получаем Clone базы данных, которая используется ядром ЛК.
	char szQuery[256];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `name`, `all_cash` FROM `lk` ORDER BY `all_cash` DESC LIMIT 10");
	g_hDatabase.Query(GetTop10Donators, szQuery, GetClientUserId(iClient), DBPrio_High);
}

public void GetTop10Donators(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{ 
	if(sError[0])
	{
		LogError("Could not load top10, reason: %s", sError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		int iCount = hResults.RowCount;
		if (iCount > 10) iCount = 10;
		else if (!iCount)
		{
			LK_ShowMainMenu(iClient);
			return;
		}
		
		int all_cash;
		char sBuffer[128], Display[128], name[MAX_NAME_LENGTH+1];
		Panel hPanel = new Panel();
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "top10", iClient);
		hPanel.SetTitle(sBuffer);
		hPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		for (int i = 1; i <= iCount; i++)
		{
			hResults.FetchRow();
			hResults.FetchString(0, name, sizeof(name));
			all_cash = hResults.FetchInt(1);
			FormatEx(Display, sizeof(Display), "%i) %s [%d %T]", i, name, all_cash, "Currency", iClient);
			hPanel.DrawText(Display);
		}
		hPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		hPanel.DrawItem("Назад");
		hPanel.Send(iClient, MenuHandler_MyPanel, 30);
		delete hPanel;
	}
	delete g_hDatabase;//Удаляем Clone базы, который получили выше.
}

public int MenuHandler_MyPanel(Handle hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 1: LK_ShowMainMenu(iClient);//Если игрок нажмет кнопку 'Назад', то ему откроется главное меню ЛК.
			}
		}
	}
}