#include <sourcemod>
#include <sdktools>
#include <navbot>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "ZPS NavBot Nav Blocker Module",
	author = "caxanga334",
	description = "Implements Nav Auto Blockers for ZPS.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/navbot-plugins"
};

enum ZPSTeam
{
	ZPS_TEAM_UNASSIGNED = 0,
	ZPS_TEAM_SPECTATOR,
	ZPS_TEAM_SURVIVORS,
	ZPS_TEAM_ZOMBIES,

	MAX_ZPS_TEAMS
};

Handle g_RoundRestartTimer = null;

public void OnPluginStart()
{
	HookEvent("clientsound", OnEvent_CientSound);
}

void StartTimer(bool force = false)
{
	if (g_RoundRestartTimer != null)
	{
		if (!force)
		{
			return;
		}

		delete g_RoundRestartTimer;
		g_RoundRestartTimer = null;
	}

	g_RoundRestartTimer = CreateTimer(12.0, Timer_OnRoundRestarted, _, TIMER_FLAG_NO_MAPCHANGE);
}

void OnEvent_CientSound(Event event, const char[] name, bool dontBroadcast)
{
	char sound[64];
	event.GetString("sound", sound, sizeof(sound));

	if (strcmp(sound, "Round_Starting", false) == 0)
	{
		StartTimer(true);
	}
}

// For when the nav mesh gets reloaded (IE: When being edited)
public void OnNavBotNavMeshLoaded()
{
	StartTimer(false);
}

public void OnMapStart()
{
	g_RoundRestartTimer = null;
	StartTimer(false);
}

void Timer_OnRoundRestarted(Handle timer, any data)
{
	g_RoundRestartTimer = null;
	OnRoundRestart();
}

void OnRoundRestart()
{
	SetupTeamBlockers();
}

void HumanClipBlocker_Init(NavBotNavBlocker blocker)
{
	int entity = blocker.Entity;

	if (entity == INVALID_ENT_REFERENCE)
	{
		delete blocker;
		return;
	}

	NavBotNavAreaVector vec = NavBotNavMesh.CollectAreasTouchingEntity(entity);

	if (vec.IsEmpty())
	{
		delete blocker;
		delete vec;
		return;
	}

	blocker.AddAreas(vec);
	blocker.UpdateBlockedStatus(view_as<int>(ZPS_TEAM_SURVIVORS), true);
	delete vec;
}

void ZombieClipBlocker_Init(NavBotNavBlocker blocker)
{
	int entity = blocker.Entity;

	if (entity == INVALID_ENT_REFERENCE)
	{
		delete blocker;
		return;
	}

	NavBotNavAreaVector vec = NavBotNavMesh.CollectAreasTouchingEntity(entity);

	if (vec.IsEmpty())
	{
		delete blocker;
		delete vec;
		return;
	}

	blocker.AddAreas(vec);
	blocker.UpdateBlockedStatus(view_as<int>(ZPS_TEAM_ZOMBIES), true);
	delete vec;
}

void TeamClipShared_Update(NavBotNavBlocker blocker)
{
	int entity = blocker.Entity;

	if (entity == INVALID_ENT_REFERENCE)
	{
		delete blocker;
		return;
	}
}

void TeamClipShared_OnRoundRestart(NavBotNavBlocker blocker)
{
	StartTimer(false); // nav mesh onroundrestar events may come from nav mesh reloads
	delete blocker;
}

void SetupTeamBlockers()
{
	int entity = INVALID_ENT_REFERENCE;

	while ((entity = FindEntityByClassname(entity, "func_humanclip")) != INVALID_ENT_REFERENCE)
	{
		NavBotNavBlocker blocker = new NavBotNavBlocker(HumanClipBlocker_Init, TeamClipShared_Update, "HumanClipBlocker");
		blocker.Entity = entity;
		blocker.OnRoundRestart = TeamClipShared_OnRoundRestart;
	}

	entity = INVALID_ENT_REFERENCE;

	while ((entity = FindEntityByClassname(entity, "func_zombieclip")) != INVALID_ENT_REFERENCE)
	{
		NavBotNavBlocker blocker = new NavBotNavBlocker(ZombieClipBlocker_Init, TeamClipShared_Update, "ZombieClipBlocker");
		blocker.Entity = entity;
		blocker.OnRoundRestart = TeamClipShared_OnRoundRestart;
	}
}