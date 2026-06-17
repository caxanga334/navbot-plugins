#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <navbot>

#pragma newdecls required
#pragma semicolon 1

ConVar cvar_footsteps_enabled = null;
ConVar sv_footsteps = null;

enum struct Settings
{
	float footstep_min_speed; // players must be moving at least this fast to emit footstep sounds
	float footstep_radius;
	float footstep_radius_when_crouched;
}

Settings g_Settings;

public Plugin myinfo =
{
	name = "NavBot Hearing Module",
	author = "caxanga334",
	description = "Implements sound events for NavBots.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/navbot-plugins"
};

public void OnPluginStart()
{
	cvar_footsteps_enabled = CreateConVar("sm_nbhm_footsteps_enabled", "1", "Enables/Disables footsteps sound events.");
	InitSettingsDefault();

	if (!ParseGamedataFile())
	{
		SetFailState("Failed to parse gamedata file!");
		return;
	}

	AutoExecConfig(true, "plugin.navbot_hearing_module");
}

void InitSettingsDefault()
{
	g_Settings.footstep_min_speed = 150.0;
	g_Settings.footstep_radius = 1024.0;
	g_Settings.footstep_radius_when_crouched = 350.0;
}

bool ParseGamedataFile()
{
	GameData gd = new GameData("navbot.plugin.hearing.games");

	if (gd == null) { return false; }

	char buffer[512];

	if (gd.GetKeyValue("PlayerFootstepMinSpeed", buffer, sizeof(buffer)))
	{
		g_Settings.footstep_min_speed = StringToFloat(buffer);
	}

	if (gd.GetKeyValue("PlayerFootstepRadius", buffer, sizeof(buffer)))
	{
		g_Settings.footstep_radius = StringToFloat(buffer);
	}

	if (gd.GetKeyValue("PlayerFootstepRadiusWhenCrouched", buffer, sizeof(buffer)))
	{
		g_Settings.footstep_radius_when_crouched = StringToFloat(buffer);
	}

	return true;
}

public void OnMapStart()
{
	if (sv_footsteps == null)
	{
		sv_footsteps = FindConVar("sv_footsteps");
	}

	if (cvar_footsteps_enabled.BoolValue && g_Settings.footstep_min_speed >= 1.0 && g_Settings.footstep_radius >= 1.0)
	{
		bool starttimer = true;

		if (sv_footsteps != null)
		{
			starttimer = sv_footsteps.BoolValue;
		}

		if (starttimer)
		{
			// start the global think timer
			CreateTimer(0.5, Timer_Think, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

void Timer_Think(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
		{
			continue;
		}

		UpdateFootsteps(client);
	}
}

void GetEntityVelocity(int entity, float velocity[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", velocity);
}

void UpdateFootsteps(int client)
{
	int groundent = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");

	// must be on ground to make sound
	if (groundent == INVALID_ENT_REFERENCE) { return; }

	float velocity[3];
	GetEntityVelocity(client, velocity);
	velocity[2] = 0.0; // use 2D speed
	bool iscrouched = GetEntProp(client, Prop_Send, "m_bDucked") != 0;

	// is moving fast enough?
	if (GetVectorLength(velocity) >= g_Settings.footstep_min_speed)
	{
		float radius = iscrouched ? g_Settings.footstep_radius_when_crouched : g_Settings.footstep_radius;

		if (radius < 1.0) { return; }

		float origin[3];
		GetClientAbsOrigin(client, origin);
		FireNavBotSoundEvent(client, origin, NAVBOT_SOUND_FOOTSTEP, radius);
	}
}