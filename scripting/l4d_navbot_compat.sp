#include <sourcemod>
#include <navbot>
#include <left4dhooks>

#pragma newdecls required
#pragma semicolon 1

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char gamefolder[128];
	GetGameFolderName(gamefolder, sizeof(gamefolder));

	if (strcmp(gamefolder, "left4dead") == 0 || strcmp(gamefolder, "left4dead2") == 0)
	{
		return APLRes_Success;
	}

	strcopy(error, err_max, "This plugin is for Left 4 Dead /2 only!");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "[L4D/2] NavBot Compatibility",
	author = "caxanga334",
	description = "Plugin to improve NavBot compatibility with Left 4 Dead games.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/navbot-plugins"
};

public void OnNavBotAdded(int bot)
{
	CreateTimer(1.0, Timer_TakeOverSurvivorBot, view_as<any>(GetClientSerial(bot)), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Searches for the next available survivor bot.
 * 
 * @return		Client index of a survivor bot. 0 on failure.
 */
int GetNextSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		// must be in-game, be a bot and be on the survivor team
		if (!IsClientInGame(client) || !IsFakeClient(client) || L4D_GetClientTeam(client) != L4DTeam_Survivor)
		{
			continue;
		}

		// skip existing navbots
		if (NavBotManager.IsNavBot(client))
		{
			continue;
		}

		// an idle player is assigned to this bot
		if (L4D_GetIdlePlayerOfBot(client) != -1)
		{
			continue;
		}

		return client;
	}

	return 0;
}

void Timer_TakeOverSurvivorBot(Handle timer, any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (!client)
	{
		return;
	}

	int bot = GetNextSurvivorBot();

	if (!bot)
	{
		LogError("Could not find a survivor bot for %L to take over!", client);
		return;
	}

	LogMessage("Trying to take over Survivor Bot %L for NavBot %L.", bot, client);
	L4D_ChangeClientTeam(client, L4DTeam_Unassigned);
	L4D_SetHumanSpec(bot, client);
	
	if (!L4D_TakeOverBot(client))
	{
		LogError("%L failed to take over %L!", client, bot);
	}
}