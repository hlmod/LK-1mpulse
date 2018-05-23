void CreateForwardss()
{
	hLK_OnLoaded = CreateGlobalForward("LK_OnLoaded", ET_Ignore);
	hLK_OnKeyWasUsed = CreateGlobalForward("LK_OnKeyWasUsed", ET_Ignore, Param_Cell, Param_String, Param_String);
}

