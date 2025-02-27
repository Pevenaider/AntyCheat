#define FILTERSCRIPT

#include <a_samp>
#include <pawn.RakNet>

// -
#define VERS "2.4.2"

#define C_GREEN 0x20DD6AFF
#define C_ERROR 0xA01616FF

#define MOBILE_CLIENT "ED40ED0E8089CC44C08EE9580F4C8C44EE8EE990"

#define MAX_MEMADDR (14)

// -
native SendClientCheck(playerid, type, arg, offsetMem, size);
native gpci(playerid, serial[], maxlen);

// -
enum PR_JoinData
{
    PR_iVersion,
    PR_byteMod,
    PR_byteNicknameLen,
    PR_NickName[24],
    PR_uiClientChallengeResponse,
    PR_byteAuthKeyLen,
    PR_auth_key[50],
    PR_iClientVerLen,
    PR_ClientVersion[30]
};

enum AC_PlayerData {
	bool:mobilePlayer,
	bool:pSuspicious,
	bool:pResponded,
	pCheat[MAX_MEMADDR],
	pCheckSum
};

new AC_Player[MAX_PLAYERS][AC_PlayerData];

// ------------
enum cheatData
{
    opcode,
    expectedValue,
    cheatValue
}

new memory[MAX_MEMADDR][cheatData] =
{
    { 0x06865E, 192, 1 },
    { 0xA88774, 72, 2 },
    { 0xDB6746, 192, 3 },
    { 0xFDB957, 68, 4 },
    { 0x52D558, 196, 5 },
    { 0xE4FC58, 64, 6 },
    { 0x1BA246, 8, 7 },
    { 0xB0C56F, 200, 8 },
    { 0xF9855E, 200, 9 },
    { 0x910152, 204, 10 },
    { 0xC7FB6E, 196, 11 },
    { 0xF4C853, 132, 12 },
    { 0xB47E74, 132, 13 },
    { 0x242C52, 192, 14 }
};

new rMemAddr[MAX_MEMADDR];

// -- Callbacks --
public OnFilterScriptInit()
{
    print("--------------------------------------------------");
    print("\t");
    print("\t");
    print("  AntyCheat "VERS" by Pevenaider loaded           ");
    print("\t");
    print("\t");
    print("--------------------------------------------------");
    return 1;
}

public OnPlayerConnect(playerid)
{
    new version[24], pAuth[43];

    // --
    for (new i = 0; i < MAX_MEMADDR; i++){
        AC_Player[playerid][pCheat][i] = -1;
    }
    AC_Player[playerid][mobilePlayer] = false;
    AC_Player[playerid][pSuspicious] = false;
    AC_Player[playerid][pResponded] = false;

    // -- Client version | GPCI --
    GetPlayerVersion(playerid, version, sizeof(version));
    gpci(playerid, pAuth, sizeof(pAuth));

    if ( !strcmp ( MOBILE_CLIENT, pAuth, true ) )
    {
        if ( AC_Player[playerid][pCheckSum] == 0xBEEF )
        {
            AC_Player[playerid][mobilePlayer] = true;
            AC_Player[playerid][pResponded] = true;
        } else {
            SendClientMessage(playerid, C_ERROR, "[ERROR] There was a problem with the mobile version authentication, Your IP is temporarily blocked!");
			SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 1);
        }
    }

	if ( strcmp ( version, "0.3.7" ) == 0 && AC_Player[playerid][mobilePlayer] == false )
    {
        SendClientMessage(playerid, C_ERROR, "[ERROR] The server requires a client version newer than 0.3.7 R1!");
        SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
    }
    
    // --
	SendClientCheck(playerid, 0x47, 0, 0, 0x4);
    SendClientCheck(playerid, 0x48, 0, 0, 0x4);
    // --
    
	for (new i = 0; i < MAX_MEMADDR; i++)
	{
    	rMemAddr[i] = rrAddress(memory[i][opcode]);
    	SendClientCheck(playerid, 0x5, rMemAddr[i], 0x0, 0x4);
	}

    // -- Check RPC --
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x47, 0xCECECE, 255);
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x48, 0xDEDEDE, 255);
    // -
    
    AC_Player[playerid][pCheckSum] = -1;
    SetTimerEx("checkPlayer", 2900, false, "i", playerid);
    return 1;
}

forward OnClientCheckResponse(playerid, actionid, memaddr, retndata);
public OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    switch(actionid)
    {
        case 0x5:
        {
            if ( AC_Player[playerid][mobilePlayer] == false ) { AC_Player[playerid][pResponded] = true; }

		   	for (new i = 0; i < MAX_MEMADDR; i++)
		    {
	            if (memaddr == rMemAddr[i])
	            {
	                if (retndata != memory[i][expectedValue])
	                {
	                    AC_Player[playerid][pCheat][i] = memory[i][cheatValue];
	                    break;
	                }
	            }
		    }
		}
        
        case 0x47:
        {
            if ( AC_Player[playerid][mobilePlayer] == false )
            {
                if ( memaddr == 0xCECECE && retndata == 255 )
                {
                	AC_Player[playerid][pSuspicious] = true;
                	// -
                	SendClientCheck(playerid, 0x47, 0, 0, 0x4);
                }
				else
				{
                    AC_Player[playerid][pSuspicious] = false;
                }
            }
        }

        case 0x48:
        {
            if ( AC_Player[playerid][mobilePlayer] == false )
            {
                if ( memaddr == 0xDEDEDE && retndata == 255 )
                {
                	AC_Player[playerid][pSuspicious] = true;
                	// -
                	SendClientCheck(playerid, 0x48, 0, 0, 0x4);
                }
				else
				{
                    AC_Player[playerid][pSuspicious] = false;
                }
            }
        }
    }
	return 1;
}

forward checkPlayer(playerid);
public checkPlayer(playerid)
{
    if ( AC_Player[playerid][mobilePlayer] == true )
    {
        SendClientMessage(playerid, C_GREEN, "You’re currently playing the mobile version of SA-MP.");
    }
    
    // --
    if ( AC_Player[playerid][pSuspicious] == true )
    {
        SendClientMessage(playerid, C_ERROR, "[ERROR] System has detected that you are probably using some mods. If you think this is a mistake, please contact the Admin.");
        SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
    }
    if ( AC_Player[playerid][pResponded] == false )
    {
        SendClientMessage(playerid, C_ERROR, "[ERROR] System has detected that you are probably using some mods. If you think this is a mistake, please contact the Admin.");
        SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
    }
    // --
    
	for (new i = 0; i < MAX_MEMADDR; i++)
	{
    	switch ( AC_Player[playerid][pCheat][i] )
    	{
		    case 1:cheatDetected(playerid, "[1] S0beit", 0);
		    case 2:cheatDetected(playerid, "[2] CLEO", 0);
		    case 3:cheatDetected(playerid, "[3] CLEO", 0);
		    case 4:cheatDetected(playerid, "[4] CLEO", 0);
			case 5:cheatDetected(playerid, "[5] CLEO / MoonLoader", 0);
			case 6:cheatDetected(playerid, "[6] CLEO / MoonLoader", 0);
			case 7:cheatDetected(playerid, "[7] CLEO", 0);
			case 8:cheatDetected(playerid, "SilentPatch", 0);
			case 9:cheatDetected(playerid, "SampFuncs", 0);
			case 10:cheatDetected(playerid, "[2] SampFuncs", 0);
			case 11:cheatDetected(playerid, "[2] S0beit", 0);
			case 12:cheatDetected(playerid, "Modified VorbisFile.dll", 0);
			case 13:cheatDetected(playerid, "UltraWH", 0);
			case 14:cheatDetected(playerid, "Silent Aim", 0);
		}
	}
    return 1;
}

forward OnIncomingRPC(playerid, rpcid, BitStream:bs);
public OnIncomingRPC(playerid, rpcid, BitStream:bs)
{
    switch ( rpcid )
    {
        case 25:
        {
            new data[PR_JoinData];

    		BS_ReadValue( bs, PR_INT32, data[PR_iVersion], PR_UINT8, data[PR_byteMod], PR_UINT8, data[PR_byteNicknameLen], PR_STRING, data[PR_NickName], data[PR_byteNicknameLen],
        		PR_UINT32, data[PR_uiClientChallengeResponse],
        		PR_UINT8, data[PR_byteAuthKeyLen],
        		PR_STRING, data[PR_auth_key], data[PR_byteAuthKeyLen],
        		PR_UINT8, data[PR_iClientVerLen]
    		);
    		
    		BS_ReadValue( bs, PR_STRING, data[PR_ClientVersion], (data[PR_iClientVerLen] >= 30 ? 30:data[PR_iClientVerLen]) );
    		// -
            BS_ReadUint16(bs, AC_Player[playerid][pCheckSum]);
        }
    }
    return 1;
}

forward kickPlayer(playerid, action);
public kickPlayer(playerid, action)
{
	switch ( action )
	{
		case 0:Kick(playerid);
		case 1:
		{
  			new pIP[16+1];

        	GetPlayerIp(playerid, pIP, sizeof(pIP));
			BlockIpAddress(pIP, 60 * 3000);
		}
	}
	return 1;
}

// --
static cheatDetected(playerid, const cName[], allow)
{
	new pName[MAX_PLAYER_NAME+1], string[128];

	GetPlayerName(playerid, pName, sizeof(pName));

	// -
	switch ( allow )
	{
	    case 0:
		{
		    printf("[DETECTION] Player %s using %s - Kicked", pName, cName);

		    SendClientMessage(playerid, C_GREEN, "---------------------------------------------------");
		    format(string, 128, "[ERROR] System has detected that you are using %s. Remove it and return to the server!", cName);
			SendClientMessage(playerid, C_ERROR, string);
			// -
			SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
		}
		case 1: printf("[DETECTION] Player %s using %s - Allowed", pName, cName);
	}
    return 1;
}

static rrAddress(input)
{
    new result;

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF
    #emit AND
    #emit CONST.alt 16
    #emit SHL
    #emit STOR.S.pri result

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF00
    #emit AND
    #emit LOAD.S.alt result
    #emit ADD
    #emit STOR.S.pri result

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF0000
    #emit AND
    #emit CONST.alt 16
    #emit SHR
    #emit LOAD.S.alt result
    #emit ADD
    #emit STOR.S.pri result

    return result;
}
