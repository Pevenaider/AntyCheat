#define FILTERSCRIPT

// -- includes --
#include <open.mp>
#include <pawn.RakNet>

// -- version --
#define VERS "2.5.3"

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
    bool:oprcChecked,
    bool:pResponded,
    pCheat[MAX_CHEATS],
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

new rMemAddr[MAX_MEMADDR];
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

new memOffsets[9] = {
    0x0, 0x2, 0x4,
    0x6, 0x8, 0xA,
    0xC, 0xE, 0x10
};

new sampAddr[] = {
    0x41B04,
    0x42044,  
    0x41FF4,  
    0x41904  
};

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
    
    // -- Reg Handler --
    PR_RegHandler(103, "OnClientCheckResponseHandler", PR_INCOMING_RPC);
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
    AC_Player[playerid][oprcChecked] = false;
    AC_Player[playerid][pResponded] = false;
    AC_Player[playerid][checkSampAddr] = 0x0;
    AC_Player[playerid][checkTimes] = 0;
    
    // -- loops --
	for (new i = 0; i < MAX_ALLOWED_CLIENTS; i++) {
    	lastRetndata[playerid][i] = 0;
	}
    for (new i = 0; i < MAX_CHEATS; i++) {
        AC_Player[playerid][pCheat][i] = -1;
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
    	//if ( IsPlayerUsingOmp(playerid) )
    SendClientCheck(playerid, 0x45, 0x3A9EB, 0, 0x4); //0.3.DL
    SendClientCheck(playerid, 0x45, 0x3AEB9, 0, 0x4); //0.3.7-R5
    SendClientCheck(playerid, 0x45, 0x3AD8D, 0, 0x4); //0.3.7-R4
    SendClientCheck(playerid, 0x45, 0x3A7F2, 0, 0x4); //0.3.7-R3

	for (new i = 0; i < MAX_MEMADDR; i++)
	{
	    new baseAddr = rrAddress(memory[i][memadr]);
	    new randIndex = random(sizeof(memOffsets));
	    new rOffset = memOffsets[randIndex];

		rMemAddr[i] = baseAddr - rOffset;

	    SendClientCheck(playerid, 0x5, rMemAddr[i], rOffset, 0x4);
	}
	SendClientCheck(playerid, 0x5, 0x53EA05, 0x0, 0x4);
    
    // --
    checkClientCheat(playerid);
    
	// -- Check RPC --
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x47, 0xCECECE, 255);
    CallLocalFunction("OnClientCheckResponse", "iiii", playerid, 0x48, 0xDEDEDE, 255);
	// --
	
    AC_Player[playerid][pCheckSum] = -1;
    SetTimerEx("checkPlayer", 2900, false, "i", playerid);
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
  	if ( AC_Player[playerid][oprcChecked] == false )
  	{
	    //if ( IsPlayerUsingOmp(playerid) )

		SendClientCheck(playerid, 0x45, 0x3A9EB, 0, 0x4); //0.3.DL
	 	SendClientCheck(playerid, 0x45, 0x3AEB9, 0, 0x4); //0.3.7-R5
	  	SendClientCheck(playerid, 0x45, 0x3AD8D, 0, 0x4); //0.3.7-R4
	  	SendClientCheck(playerid, 0x45, 0x3A7F2, 0, 0x4); //0.3.7-R3

  //
  	    AC_Player[playerid][oprcChecked] = true;
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
	            if ( memaddr == rMemAddr[i] )
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
        	for(new i = 0; i < sizeof(clientAddr); i++)
	        {
         		if ( memaddr == clientAddr[i] )
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
			cheatDetected(playerid, "[3] S0beit SobFox Launcher", 2);
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

	// -- cheat detected; cheatDetected(playerid, "cheatName", allow) - disallowed by default --
	for (new i = 0; i < MAX_CHEATS; i++)
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
			case 8:cheatDetected(playerid, "SilentPatch", 1);
			case 9:cheatDetected(playerid, "SampFuncs", 0);
			case 10:cheatDetected(playerid, "[2] SampFuncs", 0);
			case 11:cheatDetected(playerid, "[2] S0beit", 0);
			case 12:cheatDetected(playerid, "Modified VorbisFile.dll", 1);
			case 13:cheatDetected(playerid, "UltraWH", 0);
			case 14:cheatDetected(playerid, "Silent Aim", 0);
			case 15:cheatDetected(playerid, "Improved Deagle", 0);
			case 16:cheatDetected(playerid, "StealthRemastered", 0);
			case 17:cheatDetected(playerid, "Sensfix.asi", 0);
			case 18:cheatDetected(playerid, "[3] S0beit", 0);
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
	new pName[MAX_PLAYER_NAME+1];

	GetPlayerName(playerid, pName, sizeof(pName));

	// -- allow; 0 = kick , 1 allow to play , 2 crash+kick --
	switch ( allow )
	{
	    case 0:
		{
		    printf("[DETECTION] Player %s using %s - Kicked", pName, cName);
			// -
			AC_Player[playerid][pSuspicious] = false;
			// -
		    SendClientMessage(playerid, C_GREEN, "---------------------------------------------------");
			SendClientMessage(playerid, C_ERROR, "[ERROR] System has detected that you are using %s. Remove it and return to the server!", cName);
			// -
			SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
		}
		
		case 1: printf("[DETECTION] Player %s using %s - Allowed", pName, cName);
		
		case 2: // Crash + Kick
		{
		    new Float:playersPos[3];

		    printf("[DETECTION] Player %s using %s - Crashed", pName, cName);

			// -
			AC_Player[playerid][pSuspicious] = false;
			// -

   			GetPlayerPos(playerid, playersPos[0], playersPos[1], playersPos[2]);
			GameTextForPlayer(playerid, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
			GameTextForPlayer(playerid, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
			GameTextForPlayer(playerid, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);
   			CreatePlayerObject(playerid, 385, playersPos[0], playersPos[1], playersPos[2], 0.0, 0.0, 0.0);
   			SetTimerEx("kickPlayer", 1500, false, "ii", playerid, 0);
		}
	}
    return 1;
}

static checkClientCheat(playerid)
{
    new version[24], rSampAddr;
    GetPlayerVersion(playerid, version, sizeof(version));

    if ( strcmp ( version, "0.3.DL-R1", true ) == 0 ) rSampAddr = sampAddr[0];

    if ( strcmp ( version, "0.3.7-R5", true ) == 0 ) rSampAddr = sampAddr[1];

    if ( strcmp ( version, "0.3.7-R4", true ) == 0 ) rSampAddr = sampAddr[2];

   	if ( strcmp ( version, "0.3.7-R3", true ) == 0 ) rSampAddr = sampAddr[3];

    for (new i = 0; i < 3; i++)
    {
    	SendClientCheck(playerid, 0x45, rSampAddr, 0x0, 0x4);
    }
    AC_Player[playerid][checkSampAddr] = rSampAddr;
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
