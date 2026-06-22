#include <sourcemod>
#include <sdktools>
#include <navbot>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "SpawnPoint Checker Tool",
	author = "caxanga334",
	description = "Checks if player spawnpoints contains a nav area nearby.",
	version = "1.1.0",
	url = "https://github.com/caxanga334/navbot-plugins"
};

ConVar cvar_auto_test = null;
ConVar cvar_search_radius = null;
float g_Radius;
char g_map[128];
char g_logfile[PLATFORM_MAX_PATH];
char g_spawnpointnames[16][64];
int g_maxNames;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	GameData gd = new GameData("spawnpoint_checker.games");

	if (gd == null)
	{
		strcopy(error, err_max, "Failed to open spawnpoint_checker.games.txt gamedata file!");
		return APLRes_Failure;
	}

	char buffer[2048];

	if (!gd.GetKeyValue("SpawnPointClassnames", buffer, sizeof(buffer)))
	{
		strcopy(error, err_max, "Could not read \"SpawnPointClassnames\" key from gamedata file!");
		return APLRes_Failure;
	}

	g_maxNames = ExplodeString(buffer, ",", g_spawnpointnames, sizeof(g_spawnpointnames), sizeof(g_spawnpointnames[]));

	delete gd;
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvar_auto_test = CreateConVar("sm_spchecker_auto", "0", "Checks spawnpoints automatically on map start.");
	cvar_search_radius = CreateConVar("sm_spchecker_radius", "128", "Radius to search for a nearby nav area.");
	AutoExecConfig();

	RegAdminCmd("sm_check_spawnpoints", Command_CheckSpawnPoints, ADMFLAG_RCON, "Runs the spawnpoint check.");
}

void BuildMap()
{
	char buffer[128];
	GetCurrentMap(buffer, sizeof(buffer));

	if (!GetMapDisplayName(buffer, g_map, sizeof(g_map)))
	{
		strcopy(g_map, sizeof(g_map), buffer);
	}
}

void BuildLogFilePath()
{
	char time[64];
	FormatTime(time, sizeof(time), "%Y-%m-%d");
	BuildPath(Path_SM, g_logfile, sizeof(g_logfile), "logs/spchecker_%s_%s.log", g_map, time);
}

public void OnMapStart()
{
	BuildMap();
	BuildLogFilePath();

	if (cvar_auto_test.BoolValue)
	{
		RunChecks();
	}
}

Action Command_CheckSpawnPoints(int client, int args)
{
	ReplyToCommand(client, "Running checks.");
	RunChecks();
	return Plugin_Handled;	
}

void RunChecks()
{
	if (!NavBotNavMesh.IsLoaded())
	{
		PrintToServer("Skipping checks: No nav mesh!");
		return;
	}

	g_Radius = cvar_search_radius.FloatValue;

	if (g_Radius < 64.0)
	{
		g_Radius = 64.0;
	}

	PrintToServer("Starting spawnpoint checks.");
	int n = 0;
	int f = 0;

	// TO-DO: Add an entity list via gamedata

	for (int i = 0; i < g_maxNames; i++)
	{
		int entity = INVALID_ENT_REFERENCE;

		while ((entity = FindEntityByClassname(entity, g_spawnpointnames[i])) != INVALID_ENT_REFERENCE)
		{
			if (!CheckEntity(entity))
			{
				f++;
			}

			n++;
		}
	}

	PrintToServer("Checks ended. Tested %i entities with %i failures.", n, f);
}

bool CheckEntity(int entity)
{
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
	Address area = NavBotNavMesh.GetNearestNavArea(origin, g_Radius, false, true, NAVBOT_NAV_TEAM_ANY);

	if (area == Address_Null)
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		LogToFile(g_logfile, "Spawnpoint without nav area nearby! %s \"setpos %3.2f %3.2f %3.2f\"", classname, origin[0], origin[1], origin[2]);
		return false;
	}

	return true;
}