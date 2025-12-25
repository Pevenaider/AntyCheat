#define FILTERSCRIPT

// -- includes --
#include <open.mp>
#include <pawn.RakNet>
#include <antycheat>

// -- version --
#define VERS "2.5.4-API"

// -- colors --
#define C_GREEN 0x20DD6AFF
#define C_ERROR 0xA01616FF
#define C_RED 0xFF0000AA

// -- mobile gpci --
#define MOBILE_CLIENT "ED40ED0E8089CC44C08EE9580F4C8C44EE8EE990"

// -- script defines --
#define MAX_ALLOWED_CLIENTS (4) //0.3.7-R3 , 0.3.7-R4 , 0.3.7-R5, 0.3.DL-R1
#define MAX_MEMADDR (17)
#define MAX_CHEATS (18)

// ------------
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
    bool:oprsChecked,
    bool:pResponded,
    pCheat[MAX_CHEATS],
    pMemAddrs[MAX_MEMADDR],
    pClientAddrs[MAX_ALLOWED_CLIENTS],
    addChecks[2],
    checkSampAddr,
    checkTimes,
    pCheckSum
};

new AC_Player[MAX_PLAYERS][AC_PlayerData];

// ------------
new allowedClients[][24] = {
    "0.3.7-R3",
    "0.3.7-R4",
    "0.3.7-R5",
    "0.3.DL-R1"
};

new lastRetndata[MAX_PLAYERS][MAX_ALLOWED_CLIENTS]; // 4 client versions
new clientAddr[MAX_ALLOWED_CLIENTS] = { 0x3A9EB, 0x3AEB9, 0x3AD8D, 0x3A7F2 };

// ------------
enum cheatData
{
    memadr,
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
    { 0x242C52, 192, 14 },
    { 0x603C74, 200, 15 },
    { 0x004D58, 132, 16 }, 
    { 0x682252, 132, 17 }
};

new sampAddr[] = {
    0x41B04,  
    0x42044, 
    0x41FF4, 
    0x41904   
};

new gOffSet[2];

// -- Info --
main()
{
    print("--------------------------------------------------");
    print("\t");
    print("\t");
    print("  AntyCheat "VERS" by Pevenaider loaded           ");
    print("\t");
    print("\t");
    print("--------------------------------------------------");
}

// -- Callbacks --
public OnFilterScriptInit()
{
    // -- Reg Handler --
    PR_RegHandler(103, "OnClientCheckResponseHandler", PR_INCOMING_RPC);

    // -- offsets --
    new oMin, oMax;

    do
    {
        oMin = random(256);
        oMax = random(256);

        if (oMin > oMax)
        {
            new t = oMin;
            oMin = oMax;
            oMax = t;
        }
    }
    while (oMax - oMin < 32);

    gOffSet[0] = oMin & 0xFC;
    gOffSet[1] = oMax & 0xFC;

    if (gOffSet[1] <= gOffSet[0])
        gOffSet[1] = gOffSet[0] + 4;

    printf("[AC] Offset range: %d-%d", gOffSet[0], gOffSet[1]);
	return 1;
}

public OnPlayerConnect(playerid)
{
    new version[24], pAuth[43];

    // -- client version | gpci --
    GetPlayerVersion(playerid, version, sizeof(version));
    GPCI(playerid, pAuth, sizeof(pAuth));

    // -- reset variables --
	AC_Player[playerid][mobilePlayer] = false;
    AC_Player[playerid][pSuspicious] = false;
    AC_Player[playerid][oprsChecked] = false;
    AC_Player[playerid][pResponded] = false;
    AC_Player[playerid][checkSampAddr] = 0x0;
    AC_Player[playerid][checkTimes] = 0;
    AC_Player[playerid][addChecks][0] = 0;
    AC_Player[playerid][addChecks][1] = 0;

    // -- loops --
	for (new i = 0; i < MAX_ALLOWED_CLIENTS; i++) {
    	lastRetndata[playerid][i] = 0;
    	AC_Player[playerid][pClientAddrs][i] = 0x0;
	}
    for (new i = 0; i < MAX_CHEATS; i++) {
        AC_Player[playerid][pCheat][i] = -1;
    }
	for(new i = 0; i < MAX_MEMADDR; i++) {
    	AC_Player[playerid][pMemAddrs][i] = 0x0;
	}

	// -- mobile checker --
    if ( !strcmp ( MOBILE_CLIENT, pAuth, true ) )
    {
        if ( AC_Player[playerid][pCheckSum] == 0xBEEF )
        {
            AC_Player[playerid][mobilePlayer] = true;
            AC_Player[playerid][pResponded] = true;
        } else {
            SendClientMessage(playerid, C_ERROR, "[ERROR] There was a problem with the mobile version authentication, Your IP is temporarily blocked!");
            SetTimerEx("kickPlayer", 2500, false, "ii", playerid, 1);
        }
    }

    // -- SendClientCheck --
	for (new i = 0; i < MAX_MEMADDR; i++)
	{
		new baseAddr = rrAddress(memory[i][memadr]);
		new rOffset = setMemOffset();

	    AC_Player[playerid][pMemAddrs][i] = baseAddr - rOffset;

	    SendClientCheck(playerid, 0x5, AC_Player[playerid][pMemAddrs][i], rOffset, 0x4);
	}
	SendClientCheck(playerid, 0x5, 0x53EA05, 0x0, 0x4);

	for (new i = 0; i < MAX_ALLOWED_CLIENTS; i++)
	{
		AC_Player[playerid][pClientAddrs][i] = clientAddr[i];

		SendClientCheck(playerid, 0x45, AC_Player[playerid][pClientAddrs][i], 0x0, 0x4);
	}

    // --
    checkClientCheat(playerid, 1);

	// -- Check RPC --
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x47, 0xCECECE, 255);
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x48, 0xDEDEDE, 255);
	// --

    AC_Player[playerid][pCheckSum] = -1;
    SetTimerEx("checkPlayer", 2500, false, "i", playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
	if ( AC_Player[playerid][oprsChecked] == false )
  	{
  	    SetTimerEx("clientCheckTimer", 1700+random(500), false, "i", playerid);
		AC_Player[playerid][oprsChecked] = true;
	}
	return 1;
}

public OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    switch(actionid)
    {
        case 0x5:
        {
            if ( AC_Player[playerid][mobilePlayer] == false ) { AC_Player[playerid][pResponded] = true; }

		   	for (new i = 0; i < MAX_MEMADDR; i++)
		    {
	            if ( memaddr == AC_Player[playerid][pMemAddrs][i] )
	            {
	                if (retndata != memory[i][expectedValue])
	                {
	                    AC_Player[playerid][pCheat][i] = memory[i][cheatValue];
	                    break;
	                }
	            }
		    }
		}

        case 0x45:
        {
        	if ( memaddr == AC_Player[playerid][addChecks][0] && retndata != 128 ) { CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 7); }
         	if ( memaddr == AC_Player[playerid][addChecks][1] && retndata != 192 ) { CallRemoteFunction("OnPlayerSobeitDetected", "ii", playerid, 18); }

    		for(new i = 0; i < MAX_ALLOWED_CLIENTS; i++)
    		{
        		if ( memaddr == AC_Player[playerid][pClientAddrs][i] )
        		{
             		if ( lastRetndata[playerid][i] == 0 )
               		{
                 		lastRetndata[playerid][i] = retndata;
	                }
	                else if ( lastRetndata[playerid][i] != retndata )
	                {
                 		AC_Player[playerid][pCheat][17] = 18;
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

forward clientCheckTimer(playerid);
public clientCheckTimer(playerid)
{
    checkClientCheat(playerid, 2);
	return 1;
}

forward OnClientCheckResponseHandler(playerid, BitStream:bs);
public OnClientCheckResponseHandler(playerid, BitStream:bs)
{
	// --
	if ( AC_Player[playerid][checkTimes] >= 5 ) return 1;
	// --

	new actionid = 0x45, memaddr = AC_Player[playerid][checkSampAddr], retndata;

	// --
	BS_ReadValue(bs, PR_UINT8, actionid, PR_INT32, memaddr, PR_UINT8, retndata);
	// --

	if ( actionid == 0x45 && memaddr == AC_Player[playerid][checkSampAddr] )
	{
	    PR_SendRPC(bs, playerid, 103, PR_SYSTEM_PRIORITY, PR_UNRELIABLE);
	    //
 		BS_ResetReadPointer(BitStream:bs);
		BS_WriteValue(bs, PR_UINT8, actionid, PR_UINT32, memaddr, PR_UINT8, retndata);
		PR_SendRPC(bs, playerid, 103, PR_SYSTEM_PRIORITY, PR_RELIABLE);
		//
		BS_ReadValue(bs, PR_UINT8, actionid, PR_INT32, memaddr, PR_UINT8, retndata);

		// -- Check retndata --
	    if ( retndata != 192 ) { AC_Player[playerid][checkTimes] = 18; }

		if ( AC_Player[playerid][checkTimes] == 18 )
		{
			CallRemoteFunction("OnPlayerSobeitDetected", "ii", playerid, 18); // S0beit / RakNet serialization anomaly, cheatID: 18
			return 0;
		}
		AC_Player[playerid][checkTimes] ++;
	}
    return 1;
}

forward checkPlayer(playerid);
public checkPlayer(playerid)
{
    if ( !IsPlayerConnected(playerid) ) return 1;
    
	new version[24], pName[MAX_PLAYER_NAME+1];

 	GetPlayerVersion(playerid, version, sizeof(version));
	GetPlayerName(playerid, pName, sizeof(pName));

	// -- Check client version --
    new bool:isAllowed = false;
    for (new i = 0; i < MAX_ALLOWED_CLIENTS; i++)
    {
        if ( strcmp ( version, allowedClients[i], false ) == 0 )
        {
            isAllowed = true;
            break;
        }
    }

    if ( isAllowed == false && AC_Player[playerid][mobilePlayer] == false )
    {
        if ( IsPlayerConnected(playerid) )
        {
	        new versionList[90];

	        versionList[0] = '\0';
	        for (new i = 0; i < MAX_ALLOWED_CLIENTS; i++)
	        {
	            format(versionList, sizeof(versionList), "%s%s%s", versionList, (i > 0) ? ", " : "", allowedClients[i]);
	        }

	        AC_Player[playerid][pSuspicious] = false;

	        printf("[INFO] %s - disallowed client ver: %s, kicked", pName, version);

	        SendClientMessage(playerid, C_RED, "[ERROR] Your client version is: %s. Allowed client versions: {FFFFFF}%s", version, versionList);
	        return SetTimerEx("kickPlayer", 500, false, "ii", playerid, 0);
		}
	}

    // -- mobile player --
    if ( AC_Player[playerid][mobilePlayer] == true )
    {
        printf("[INFO] %s Mobile Player", pName);

        SendClientMessage(playerid, C_GREEN, "[SYSTEM] You’re currently playing the mobile version of SA-MP.");
    }

	// -- false 0x5 respond --
    if ( AC_Player[playerid][pResponded] == false )
    {
        printf("[INFO] %s False Respond", pName);

        AC_Player[playerid][pSuspicious] = false;
        SendClientMessage(playerid, C_ERROR, "[ERROR] System has detected that you are probably using some mods. If you think this is a mistake, please contact the Admin.");
        SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
    }

    // -- Check RPC --
    if ( AC_Player[playerid][pSuspicious] == true )
    {
        printf("[INFO] %s Suspicious", pName);

        SendClientMessage(playerid, C_ERROR, "[ERROR] System has detected that you are probably using some mods. If you think this is a mistake, please contact the Admin.");
        SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
    }

	// -- cheat detected --
	for (new i = 0; i < MAX_CHEATS; i++)
	{
    	switch ( AC_Player[playerid][pCheat][i] )
    	{
    	    case 1:CallRemoteFunction("OnPlayerSobeitDetected", "ii", playerid, 1); // S0beit, cheatID: 1

    	    case 2:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 2); // CLEO, cheatID: 2
    	    
    	    case 3:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 3); // CLEO, cheatID: 3
    	    
    	    case 4:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 4); // CLEO, cheatID: 4
    	    
    	    case 5:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 5); // CLEO / MoonLoader, cheatID: 5
    	    
    	    case 6:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 6); // CLEO / MoonLoader, cheatID: 6
    	    
    	    case 7:CallRemoteFunction("OnPlayerModsDetected", "ii", playerid, 7); // CLEO / Modded client, cheatID: 7

    	    case 8:CallRemoteFunction("OnPlayerSPDetected", "i", playerid); // SilentPatch
    	    
			case 9,10:CallRemoteFunction("OnPlayerSFDetected", "i", playerid); // SampFuncs
			
			case 11:CallRemoteFunction("OnPlayerSobeitDetected", "ii", playerid, 11); // S0beit, cheatID: 11
			
			case 12:CallRemoteFunction("OnPlayerMVFDetected", "i", playerid); // Modified vorbisfile
			
            case 13:CallRemoteFunction("OnPlayerWHDetected", "i", playerid); // Wallhack
            
			case 14:CallRemoteFunction("OnPlayerAimDetected", "i", playerid); // Silent aim v8
			
			case 15:CallRemoteFunction("OnPlayerIDeagleDetected", "i", playerid); // Improved Deagle
			
			case 16:CallRemoteFunction("OnPlayerStealthDetected", "i", playerid); // StealthRemastered03DL.dll
			
			case 17:CallRemoteFunction("OnPlayerSensfixDetected", "i", playerid); // Sensfix.asi
			
			case 18:CallRemoteFunction("OnPlayerSobeitDetected", "ii", playerid, 18); // S0beit, cheatID: 18
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

static checkClientCheat(playerid, type)
{
    new version[24], ver = 0, rSampAddr = 0;
    GetPlayerVersion(playerid, version, sizeof(version));

    if ( strcmp ( version, "0.3.DL-R1", true ) == 0 ) rSampAddr = sampAddr[0], ver = 1;
    else if ( strcmp ( version, "0.3.7-R5", true ) == 0 ) rSampAddr = sampAddr[1], ver = 2;
    else if ( strcmp ( version, "0.3.7-R4", true ) == 0 ) rSampAddr = sampAddr[2], ver = 3;
    else if ( strcmp ( version, "0.3.7-R3", true ) == 0 ) rSampAddr = sampAddr[3], ver = 4;

    switch ( type )
    {
        case 1:
        {
            AC_Player[playerid][checkSampAddr] = rSampAddr;

		    for (new i = 0; i < 3; i++)
		    {
		        SendClientCheck(playerid, 0x45, AC_Player[playerid][checkSampAddr], 0x0, 0x4);
		    }

            if ( !IsPlayerUsingOmp(playerid) )
            {
	            new addOffset = setMemOffset();

			    switch ( ver )
			    {
			        case 1: AC_Player[playerid][addChecks][0] = 0x6B4D + 0x33D53 - addOffset;

			        case 2: AC_Player[playerid][addChecks][0] = 0x247A + 0x38966 - addOffset;

			        case 3: AC_Player[playerid][addChecks][0] = 0x2B414 + 0xF97C - addOffset;

			        case 4: AC_Player[playerid][addChecks][0] = 0x62EB + 0x343B5 - addOffset;

			        default: { }
			    }
			    if ( ver != 0 ) SendClientCheck(playerid, 0x45, AC_Player[playerid][addChecks][0], addOffset, 0x4);
		    }
		}

		case 2:
		{
		    new addOffset = setMemOffset();

		    switch ( ver )
		    {
		        case 1: AC_Player[playerid][addChecks][1] = 0x75EA2 + 0x2782E - addOffset;

		        case 2: AC_Player[playerid][addChecks][1] = 0x3A65F + 0x63231 - addOffset;

				case 3: AC_Player[playerid][addChecks][1] = 0x74674 + 0x2924C - addOffset;

				case 4: AC_Player[playerid][addChecks][1] = 0x3AB43 + 0x6263D - addOffset;

				default: { }
			}
			if ( ver != 0 ) SendClientCheck(playerid, 0x45, AC_Player[playerid][addChecks][1], addOffset, 0x4);
		}
	}
    return 1;
}

// --
static setMemOffset()
{
    new off = (gOffSet[1] - gOffSet[0]) / 4 + 1;
    return (random(off) * 4) + gOffSet[0];
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
