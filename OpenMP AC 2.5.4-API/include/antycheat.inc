/*
	#########################
	#                       #
	# AntyCheat.inc v2.5.4  #
	#                       #
	#########################
*/

#if defined _antycheat_included
	#endinput
#endif
#define _antycheat_included

// -- Called when sobeit detected, IDs: 1, 11, ID: 18(Sobeit/RakNet serialization anomaly) --
forward OnPlayerSobeitDetected(playerid, cheatID);

// -- Called when mods detected, IDs: 2, 3, 4 | 5, 6 CLEO/MoonLoader | 7 CLEO / Modded client --
forward OnPlayerModsDetected(playerid, cheatID);

// -- Called when SilentPatch detected --
forward OnPlayerSPDetected(playerid);

// -- Called when SampFuncs detected --
forward OnPlayerSFDetected(playerid);

// -- Called when modified vorbisfile.dll detected --
forward OnPlayerMVFDetected(playerid);

// -- Called when WallHack detected --
forward OnPlayerWHDetected(playerid);

// -- Called when Silent Aim v8 detected --
forward OnPlayerAimDetected(playerid);

// -- Called when Improved Deagle detected --
forward OnPlayerIDeagleDetected(playerid);

// -- Called when StealthRemastered03DL.dll detected --
forward OnPlayerStealthDetected(playerid);

// -- Called when Sensfix.asi detected --
forward OnPlayerSensfixDetected(playerid);


/* ---- Some examples (you can put it to your gamemode) ----

public OnPlayerSobeitDetected(playerid, cheatID)
{
	if ( cheatID == 1 )
	{
	    SendClientMessage(playerid, -1, "Sobeit 1");
	}
	else if ( cheatID == 11 )
	{
	    SendClientMessage(playerid, -1, "Sobeit 2");
	}
	else if ( cheatID == 18 )
	{
	    SendClientMessage(playerid, -1, "Sobeit / RakNet serialization anomaly");
	}
	return 1;
}

public OnPlayerModsDetected(playerid, cheatID)
{
	if ( cheatID == 2 )
	{
	    SendClientMessage(playerid, -1, "CLEO, detection ID; 2");
	}
	else if ( cheatID == 3 )
	{
	    SendClientMessage(playerid, -1, "CLEO, detection ID; 3");
	}
	else if ( cheatID == 4 )
	{
	    SendClientMessage(playerid, -1, "CLEO, detection ID; 4");
	}
	else if ( cheatID == 5 )
	{
	    SendClientMessage(playerid, -1, "CLEO/MoonLoader, detection ID; 5");
	}
	else if ( cheatID == 6 )
	{
	    SendClientMessage(playerid, -1, "CLEO/MoonLoader, detection ID; 6");
	}
	else if ( cheatID == 7 )
	{
	    SendClientMessage(playerid, -1, "Modded client / CLEO, detection ID; 7");
	}
	return 1;
}

public OnPlayerMVFDetected(playerid)
{
	SendClientMessage(playerid, -1, "Modified vorbisfile.dll");
	return 1;
}

*/
