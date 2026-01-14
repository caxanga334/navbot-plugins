#include <sourcemod>
#include <sdktools>
#include <navbot>
#include <smlib>

#pragma newdecls required
#pragma semicolon 1

#define MIN_PLAYERS_TO_BALANCE 2

ConVar c_difference = null;

public Plugin myinfo =
{
	name = "Simple NavBot Auto Balancer",
	author = "caxanga334",
	description = "Automatically move navbots to teams with less players.",
	version = "1.0.1",
	url = "https://github.com/caxanga334/navbot-plugins"
};

public void OnPluginStart()
{
	c_difference = CreateConVar("sm_navbot_autobalance_team_diff", "2", 
	"If the difference in player count is greater than this, try to auto balance navbots. \nSet to 0 to disable.", FCVAR_NONE);

	AutoExecConfig();
}

public void OnMapStart()
{
	CreateTimer(2.0, Timer_Think, .flags = TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

bool IsThereAnyHumans()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) > TEAM_SPECTATOR)
		{
			return true;
		}
	}

	return false;
}

int SelectRandomNavBotFromTeam(int team, bool priorizeDead = true)
{
	int[] bots = new int[MaxClients];
	int n = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team && NavBotManager.IsNavBot(client))
		{
			// If priorizing dead bots, return the first found.
			if (priorizeDead && !IsPlayerAlive(client))
			{
				return client;
			}

			bots[n] = client;
			n++;
		}
	}

	if (n == 0)
	{
		return 0;
	}

	if (n == 1)
	{
		return bots[0];
	}

	return bots[Math_GetRandomInt(0, n - 1)];
}

void MoveNavBotFromTo(int fromTeam, int toTeam)
{
	int client = SelectRandomNavBotFromTeam(fromTeam);

	if (client <= 0)
	{
		return;
	}

	LogMessage("NavBot %L was auto balanced from team %i to team %i.", client, fromTeam, toTeam);
	ChangeClientTeam(client, toTeam);
}

void Timer_Think(Handle timer)
{
	int maxdiff = c_difference.IntValue;

	if (maxdiff <= 0 || !IsThereAnyHumans())
	{
		return;
	}

	int team1c;
	int team2c;

	Team_GetClientCounts(team1c, team2c, CLIENTFILTER_INGAME);

	int diff = Math_Abs(team1c - team2c);

	// Difference must be at least 2 to balance teams.
	if (diff < maxdiff || diff < MIN_PLAYERS_TO_BALANCE)
	{
		return;
	}

	if (team1c > team2c)
	{
		MoveNavBotFromTo(TEAM_ONE, TEAM_TWO);
	}
	else
	{
		MoveNavBotFromTo(TEAM_TWO, TEAM_ONE);
	}
}