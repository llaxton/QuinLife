// rezzer.lsl
// Rez animals and also update the animal.lsl script in them
// Objexct changes size/rotation tso you can rez it or wear it.

// This is used to check if updates available from Quintonia product update server
float VERSION = 5.4;    // 25 October 2020
string NAME = "SF Animal Rezzer - Quintonia";
//
integer DEBUGMODE = FALSE;    // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}
//
// config notecard can overide the following:
integer VER=-1;                 // read from config notecard - is the version of the animal script. Use -1 to force sending script with no version checking e.g. downgrades
integer sexToggle = 0;
vector  rezzPosition = <0.0, 0.0, 0.5>;     // REZ_POSITION

string  languageCode = "en-GB";      // use defaults below unless language config notecard present
//
// Multilingual support
string TXT_CLOSE="CLOSE";
string TXT_UPGRADE_ALL="UPGRADING all";
string TXT_ALL="ALL";
string TXT_SELECT="Select";
string TXT_REZ_ANIMAL="Rez an animal";
string TXT_REZZING="Rezzing";
string TXT_REZ="Rez...";
string TXT_UPGRADE="Upgrade...";
string TXT_SET_RANGE="Set Range...";
string TXT_ENTER_RADIUS="Enter upgrade radius in m (1 to 96)";
string TXT_CURRENT_VALUE="Current value is a";
string TXT_RANGE_SET="Upgrade range set to";
string TXT_CHOOSE_ANIMAL="Choose animal to upgrade";
string TXT_WARNING_A="WARNING: All animals within a";
string TXT_RADIUS="radius";
string TXT_WARNING_B="will be upgraded!";
string TXT_TRYING="Trying";
string TXT_SENDING="sending items..";
string TXT_SEX="Sex";
string TXT_RANDOM="Random";
string TXT_TOGGLE="Toggle";
string TXT_ANIMAL_VERSION="Animal Version:";
string TXT_WAIT="Please allow a few seconds for the animal to initialize...";
string TXT_CANT_UPGRADE="Item can't be upgraded";
string TXT_UPGRADED="Upgraded ";
string TXT_NOT_REQUIRED="Upgrade not required for";
string TXT_NOT_FOUND="not found";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "R1";
string  PASSWORD="*";
string  mode;
integer attachedTo;     // Flags if being run as a HUD rather than rezzed as an object
integer face;
integer scanRange = 96;
string  status;
list    animals;
string  senseFor;
integer nextSex = 1;    // 1=Female, -1 = Male
string  productScript = "product";
string  birthCertNC = "birth-date";

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

integer listener=-1;
integer listenTs;

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
             if (cmd == "VER")           VER = (integer)val;
        else if (cmd == "SEX_ALTERNATE") sexToggle = (integer)val;
        else if (cmd == "REZ_POSITION")  rezzPosition = (vector)val;
        else if (cmd == "LANG")          languageCode = val;
    }
}

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
    // Load lang if stored in description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "LANG") languageCode = llList2String(desc, 1);
}


loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang"+SUFFIX;
    if (llGetInventoryType(languageNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(languageNC), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    // Remove start and end " marks
                    val = llGetSubString(val, 1, -2);
                    // Now check for language translations
                         if (cmd == "TXT_CLOSE")  TXT_CLOSE = val;
                    else if (cmd == "TXT_UPGRADE_ALL") TXT_UPGRADE_ALL = val;
                    else if (cmd == "TXT_ALL") TXT_ALL = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_SEX") TXT_SEX = val;
                    else if (cmd == "TXT_RANDOM") TXT_RANDOM = val;
                    else if (cmd == "TXT_TOGGLE") TXT_TOGGLE = val;
                    else if (cmd == "TXT_REZ_ANIMAL") TXT_REZ_ANIMAL = val;
                    else if (cmd == "TXT_REZZING") TXT_REZZING = val;
                    else if (cmd == "TXT_REZ") TXT_REZ = val;
                    else if (cmd == "TXT_UPGRADE") TXT_UPGRADE = val;
                    else if (cmd == "TXT_SET_RANGE") TXT_SET_RANGE = val;
                    else if (cmd == "TXT_ENTER_RADIUS") TXT_ENTER_RADIUS = val;
                    else if (cmd == "TXT_CURRENT_VALUE") TXT_CURRENT_VALUE = val;
                    else if (cmd == "TXT_RANGE_SET") TXT_RANGE_SET = val;
                    else if (cmd == "TXT_CHOOSE_ANIMAL") TXT_CHOOSE_ANIMAL = val;
                    else if (cmd == "TXT_WARNING_A") TXT_WARNING_A = val;
                    else if (cmd == "TXT_RADIUS") TXT_RADIUS = val;
                    else if (cmd == "TXT_WARNING_B") TXT_WARNING_B = val;
                    else if (cmd == "TXT_TRYING") TXT_TRYING = val;
                    else if (cmd == "TXT_SENDING") TXT_SENDING = val;
                    else if (cmd == "TXT_ANIMAL_VERSION") TXT_ANIMAL_VERSION = val;
                    else if (cmd == "TXT_WAIT") TXT_WAIT = val;
                    else if (cmd == "TXT_CANT_UPGRADE") TXT_CANT_UPGRADE = val;
                    else if (cmd == "TXT_UPGRADED") TXT_UPGRADED = val;
                    else if (cmd == "TXT_NOT_REQUIRED") TXT_NOT_REQUIRED = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
    else
    {
        llSetObjectDesc("");
        llResetScript();
    }
}

psys(key k)
{

     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,

                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 30,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);

}

integer startOffset=0;

multiPageMenu(key id, string message, list opt)
{
    integer l = llGetListLength(opt);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, opt+[TXT_CLOSE], ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(opt, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}


startUpgrading(string m)
{
    llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, face, 1, 1, 0, TWO_PI, 2.0);
    m = "SF " + m;
    llSleep(1.);
    llSay(0, TXT_UPGRADE_ALL +" '"+m+"' " +TXT_RANGE_SET+" "  +(string)(llRound(scanRange))+" " +TXT_RADIUS);
    senseFor=m;
    llSensor(m, "", SCRIPTED, scanRange, PI);
}

showMainMenu(key userID)
{
    string tmpStr = "";
    animals = [];
    integer i;
    for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
    {
        // Remove the "SF " bit for the buttons
        tmpStr = llGetInventoryName(INVENTORY_OBJECT, i);
        tmpStr = llGetSubString(tmpStr, 3, llStringLength(tmpStr));
        animals += tmpStr;
    }
    if (llToUpper(llGetScriptName()) != "B-REZZER")
    {
        tmpStr = "\n \n" + TXT_SEX +": ";
        if (sexToggle == 0) tmpStr += TXT_RANDOM; else tmpStr += TXT_TOGGLE;
    }
    mode = "";
    startListen();
    if (llToUpper(llGetScriptName()) != "B-REZZER") multiPageMenu(userID, TXT_SELECT+tmpStr, [TXT_SET_RANGE, TXT_SEX, TXT_LANGUAGE, TXT_REZ, TXT_UPGRADE]);
        else multiPageMenu(userID, TXT_SELECT, [TXT_SET_RANGE, TXT_UPGRADE, TXT_LANGUAGE, TXT_REZ]);
    llSetTimerEvent(1000);
}

default
{

    listen(integer c, string nm, key id, string m)
    {
        if (m == TXT_CLOSE)
        {
            mode = "";
        }
        else if (m ==">>")
        {
            startOffset += 10;
            multiPageMenu(id, TXT_REZ_ANIMAL, animals);
        }
        else if (m ==TXT_SET_RANGE)
        {
            mode = "waitRange";
            llTextBox(id, "\n" + TXT_ENTER_RADIUS+"\n" +TXT_CURRENT_VALUE+" "  +(string)(llRound(scanRange)) + " m " +TXT_RADIUS, chan(llGetKey()));
        }
        else if  (m == TXT_UPGRADE)
        {
            mode = "Upgrading";
            multiPageMenu(id, "\n " +TXT_CHOOSE_ANIMAL+"\n\n" +TXT_WARNING_A+" " +(string)(llRound(scanRange)) + "m " +TXT_RADIUS + " " + TXT_WARNING_B +"\n \n", [TXT_ALL]+animals);
        }
        else if (m == TXT_REZ)
        {
            string tmpStr = "\n \n";
            if (llToUpper(llGetScriptName()) != "B-REZZER")
            {
                tmpStr += TXT_SEX +": ";
                if (sexToggle == 0)
                {
                    tmpStr += TXT_RANDOM;
                }
                else
                {
                    if (nextSex == -1) tmpStr += "♂ m"; else tmpStr += "♀ f";
                }
            }
            mode = "Rezzing";
            multiPageMenu(id, "\n" +TXT_REZ_ANIMAL +tmpStr, animals);
        }
        else if (m == TXT_ALL && mode == "Upgrading")
        {
            integer i;
            for (i=0; i < llGetListLength(animals); i++)
            {
                startUpgrading(llList2String(animals,i));
            }
        }
        else if (m == TXT_SEX)
        {
            sexToggle = !sexToggle;
            mode = "";
            showMainMenu(id);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
            mode = "";
        }
        else if (mode == "waitRange")
        {
            mode = "";
            integer tmpVal = (integer)m;
            if (tmpVal >96) scanRange = 96;
            else if (tmpVal <1) scanRange = 1; else scanRange = tmpVal;
            llRegionSayTo(id, 0, TXT_RANGE_SET+" " + scanRange + "m " +TXT_RADIUS);
        }
        else if (mode == "Upgrading")
        {
            llOwnerSay(TXT_ANIMAL_VERSION+": " +(string)VER);
            startUpgrading(m);
        }
        else  if (mode == "Rezzing")
        {
            m = "SF " + m;
            llSay(0, TXT_REZZING+" "+m+". "+TXT_WAIT);
            llSetText(TXT_REZZING+" "+m+"\n"+TXT_WAIT +"\n ", <1.000, 0.522, 0.106>,1.0);
            llSetColor(<1.000, 0.522, 0.106>, 4);
            vector pos;

            if (attachedTo == 0)
            {
                pos = llGetPos() + <1.0, 0.0, 0.2>*llGetRot();
            }
            else
            {
                key    owner = llGetOwner();
                vector agent = llGetAgentSize(owner);
                pos = llList2Vector(llGetObjectDetails(owner, [OBJECT_POS]), 0);
                //  "pos" needs to be adjusted to not rez at head height.
                pos.z = pos.z - (agent.z / 2) + 0.25;
                //  makes sure it found the owner, a zero vector evaluates as false
                 // if(agent)
                // llSetPos(pos);
            }
            //llRezObject(m, pos, <0,0,0>, ZERO_ROTATION, nextSex);
            llMessageLinked(LINK_SET, -1, "REZ_PRODUCT|" +PASSWORD +"|" +(string)id +"|" +m, NULL_KEY);
        }
        else
        {
            // ERROR!
        }
    }

    timer()
    {
        checkListen();
        if (mode != "")
        {
            llSetTimerEvent(0);
            mode = "";
            llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        }
    }

    touch_start(integer n)
    {
        if (llGetOwner() != llDetectedKey(0)) return; else showMainMenu(llDetectedKey(0));
    }

    state_entry()
    {
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        if (languageCode != "") loadLanguage(languageCode);
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (i=0; i<count; i++)
        {
            if (llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 6) == "product") productScript = llGetInventoryName(INVENTORY_SCRIPT, i);
        }
        llSetText(TXT_REZ_ANIMAL + "\n OR \n" +TXT_CHOOSE_ANIMAL +"\n \n", <1,1,1>,1.0);
        if (llToUpper(llGetScriptName()) != "B-REZZER")
        {
            attachedTo =  llGetAttached();
            if (attachedTo == 0)
            {
                face = 0;
                vector pos = llGetPos();
                pos.z += 0.5;
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, <0.5, 0.5, 0.5>,
                                                          PRIM_POSITION, pos,
                                                          PRIM_ROTATION, ZERO_ROTATION ]);
            }
            else
            {
                face = 5;
                rotation rot = llEuler2Rot(<0, 45, 0>*DEG_TO_RAD);
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, <0.15, 0.10, 0.15>,
                                                          PRIM_ROTATION, rot ]);
            }
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(2.0);
        llGiveInventory(id, llKey2Name(id));
        llGiveInventory(id , "sfp");
        string ncName;
        string ncSuffix;
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
        // For baby rezzer need to give them the B1 and B2 language notecards
        if (llToUpper(llGetScriptName()) == "B-REZZER")
        {
            debug("giving: B1 & B2 languages");
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                ncSuffix = llGetSubString(ncName, 5, 11);
                if (ncSuffix == "-langB1" || ncSuffix == "-langB2") llGiveInventory(id, ncName);
            }
        }
        else
        {
            // For animals just need to give the A1 language notecards
            debug("giving: A1 languages");
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                if (llGetSubString(ncName, 5, 11) == "-langA1") llGiveInventory(id, ncName);
            }
        }
        debug("giving script: language_plugin");
        llRemoteLoadScriptPin(id, "language_plugin", 999, TRUE, 1);
        debug("giving: angel texture");
        llGiveInventory(id, "angel");
        debug("giving script: animal-heaven");
        llRemoteLoadScriptPin(id, "animal-heaven", 999, TRUE, 1);
        debug("giving script: prod-rez_plugin");
        llRemoteLoadScriptPin(id, "prod-rez_plugin", 999, TRUE, 1);
        // If this is the baby rezzer give them a birth certificate
        if( llToUpper(llGetScriptName()) == "B-REZZER")
        {
            debug("giving: birth certificate");
            // Give them birth certificate
            if (llGetInventoryType(birthCertNC) == INVENTORY_NOTECARD) llRemoveInventory(birthCertNC);
            osMakeNotecard(birthCertNC, llGetDate());
            llGiveInventory(id, birthCertNC);
            debug("giving script: hud-main");
            llRemoteLoadScriptPin(id, "hud-main", 999, TRUE, 1);
        }
        debug("giving script: "+productScript);
        //llGiveInventory(id, "product");
        llGiveInventory(id, productScript);
        if (sexToggle == TRUE)
        {
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, nextSex);
            if (nextSex == -1) nextSex = 1; else nextSex = -1;
        }
        else
        {
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, 0);
        }
        llSetColor(<1.0, 1.0, 1.0>, 4);
        llSetText(TXT_REZ_ANIMAL + "\n OR \n" +TXT_CHOOSE_ANIMAL +"\n \n", <1,1,1>,1.0);
    }

    sensor(integer n)
    {
        if (mode == "Upgrading")
        {
            integer i;
            for (i=0; i < n; i++)
            {
                key u = llDetectedKey(i);
                list desc = llParseString2List(llList2String(llGetObjectDetails(u, [OBJECT_DESC]) , 0) , [";"], []);
                if (llList2String(desc, 0) == "A")
                {
                    llSay(0, TXT_TRYING +" '"+llList2String(desc, 10)+"'");
                    osMessageObject(u, "VERSION-CHECK|"+PASSWORD+"|"+(string)llGetKey());
                    llSleep(2);
                }
                else
                {
                    // llOwnerSay(llKey2Name(u) +" ("+(string)u+") " +TXT_CANT_UPGRADE);
                }
            }
        }
        else llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
    }

    no_sensor()
    {
        llSay(0, senseFor+" " +TXT_NOT_FOUND);
        llSetTimerEvent(15);
    }

    dataserver(key id, string m)
    {
        list tk = llParseString2List(m, ["|"], []);
        if (llList2String(tk,1) == PASSWORD)
        {
            string cmd = llList2String(tk, 0);
            key kobject = llList2Key(tk, 2);

            if (cmd == "VERSION-REPLY")
            {
                //  Versions before 4.1 can't be upgraded
                if (llList2Integer(tk, 3) <41)
                {
                    //
                }
                else if ((llList2Integer(tk, 3) < VER) || (VER == -1))
                {
                    string ncName;
                    string langNCs = ",";
                    integer i;
                    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
                    for (i=0; i<count; i+=1)
                    {
                        ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                        if (llGetSubString(ncName, 5, 11) == "-langA1") langNCs = langNCs + ncName +",";
                    }
                    osMessageObject(id, "DO-UPDATE|" +PASSWORD+"|" +(string)llGetKey() +"|animal,setpin,language_plugin,prod-rez_plugin,product,animal 1,animal-heaven,angel" + langNCs);
                }
                else
                {
                    llOwnerSay(TXT_NOT_REQUIRED +": " +llKey2Name(id) +"\n" + (string)id);
                }
                llSetTimerEvent(15);
            }
            else if (cmd == "DO-UPDATE-REPLY")
            {
                integer ipin = llList2Integer(tk, 3);
                llOwnerSay("PIN="+(string)ipin+", " +TXT_SENDING +"...");
                string ncName;
                string ncSuffix;
                integer i;
                integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
                // For baby rezzer need to give them the B1 and B2 language notecards
                if (llToUpper(llGetScriptName()) == "B-REZZER")
                {
                    for (i=0; i<count; i+=1)
                    {
                        ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                        ncSuffix = llGetSubString(ncName, 5, 11);
                        if (ncSuffix == "-langB1" || ncSuffix == "-langB2") llGiveInventory(id, ncName);
                    }
                }
                else
                {
                    // For animals just need to give the A1 language notecards
                    for (i=0; i<count; i+=1)
                    {
                        ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                        if (llGetSubString(ncName, 5, 11) == "-langA1") llGiveInventory(id, ncName);
                    }
                }
                llRemoteLoadScriptPin(kobject, "language_plugin", ipin, TRUE, 0);
                llGiveInventory(id, "angel");
                llRemoteLoadScriptPin(kobject, "animal-heaven", ipin, TRUE, 0);
                llRemoteLoadScriptPin(kobject, "prod-rez_plugin", ipin, TRUE, 0);
                llGiveInventory(kobject, "product");
                llRemoteLoadScriptPin(kobject, "animal", ipin, TRUE, 0);
                list desc = llParseString2List(llList2String(llGetObjectDetails(kobject, [OBJECT_DESC]) , 0) , [";"], []);
                llSay(0, TXT_UPGRADED +" "+ llList2String(desc,10)+ " (" +llKey2Name(kobject)+")");
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "VERSION-REQUEST")
        {
            llMessageLinked(LINK_SET, (integer)(10*VERSION), "VERSION-REPLY", (key)NAME);
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetText(TXT_REZ_ANIMAL, <1,1,1>,1.0);
            llSetObjectDesc("LANG;"+languageCode);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
