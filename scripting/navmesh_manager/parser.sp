
SMCResult PlaceDBParser_EndSection(SMCParser smc)
{
	if (g_isparsingincludes)
	{
		g_isparsingincludes = false;
	}

	return SMCParse_Continue;
}

SMCResult PlaceDBParser_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	if (strcmp(name, "Settings", false) == 0)
	{
		g_isparsingincludes = true;
	}

	return SMCParse_Continue;
}

SMCResult PlaceDBParser_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (g_isparsingincludes)
	{
		if (strcmp(key, "Include", false) == 0)
		{
			g_placeIncludes.PushString(value);
		}
	}

	return SMCParse_Continue;
}

void PlaceDBParser_Start(SMCParser smc)
{
	g_isparsingincludes = false;
}