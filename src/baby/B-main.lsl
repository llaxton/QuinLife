// B-main.lsl
// Version 2.0  26 October 2020

integer chan = 0;
list    mainMenuButtons = [];
key     toucher = NULL_KEY;

// multilingual
string TXT_CLOTHING = "Clothing";
string TXT_BIRTHDATE = "Birth date";
string TXT_MOVE = "Move";
string TXT_SELECT = "Please select option";
string TXT_CLOSE = "CLOSE";
string TXT_BACK = "BACK";
string TXT_ALREADY_THERE = "I'm already there!";
string TXT_HOLD_ON = "Hold on, heading there now!";
string TXT_PUT_DOWN = "Put down";
string TXT_ATTACH = "Attach";
string TXT_DETACH = "Detach";
//
// birth date items
string g_strMessage="was born on";
string g_strFilename="birth-date";
string myName ="";
string g_strDate;
//
// clothing items
key ownerID;
list wearableNames;    // list of inventory items to 'wear'
integer g_intMenuStart=0;
integer g_intMenuEnd=8;
string PREFIX = "clothing-";
//
// Movement (target) items
list targets = [];
string mainTarget = "";
string SF_PREFIX = "SF ";
string whereAmI = "";
integer useOS = FALSE;
integer attachPoint = ATTACH_BACK;


integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

integer startOffset=0;

multiPageMenu(key id, string message, list opt)
{
    integer l = llGetListLength(opt);
    if (l < 12)
    {
        llDialog(id, message, [TXT_BACK]+opt, chan);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(opt, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_BACK]+its+[">>"], chan);
}

doAttach()
{
    llOwnerSay(TXT_HOLD_ON);
    whereAmI = "";
    integer result = llListFindList(mainMenuButtons, [TXT_MOVE]);
    if (result != -1)  mainMenuButtons = llDeleteSubList(mainMenuButtons, result, result);
    if (llListFindList(mainMenuButtons, [TXT_DETACH]) == -1) mainMenuButtons += [TXT_DETACH];
    llAttachToAvatar(attachPoint);
}

default
{

    state_entry()
    {
        ownerID = llGetOwner();
        llRequestPermissions(ownerID, PERMISSION_ATTACH); //asks permission to attach/detach
        //
        // for birthdate function
        if (chan == 0) llMessageLinked(LINK_SET, 0, "get channel", NULL_KEY);
        mainMenuButtons = [TXT_CLOTHING, TXT_BIRTHDATE];
        if (llGetAttached() == 0) mainMenuButtons += [TXT_MOVE];
        mainMenuButtons += [TXT_CLOSE];
        //
        // for clothing function
        wearableNames = [];
        string symbol;
        string fullName;
        string shortName;
        integer index;
        integer count = llGetNumberOfPrims();
        for(index = 0; index < count; index++)
        {
            fullName = llList2String(llGetLinkPrimitiveParams(index, [PRIM_NAME]), 0);
            if (llGetSubString(fullName, 0, 8) == PREFIX)
            {
                // names are clothing- followed by descriptive name e.g. clothing-hat2
                shortName = llGetSubString(fullName, 9, -1);
                if (llList2Integer(llGetLinkPrimitiveParams(index, [PRIM_COLOR, ALL_SIDES]), 1) == 1) symbol = "-"; else symbol = "+";
                // store as +hat2   or -hat2 depending upon current alpha
                wearableNames  += symbol+shortName;
            }
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }

    link_message(integer sender_num, integer number, string message,key id)
    {
        list tk = llParseString2List(message, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "B_TARGETS")
        {
            if (llGetListLength(tk) >1)
            {
                SF_PREFIX = llList2String(tk,1) +" ";
                targets = llList2List(tk, 2, -1);
                mainTarget = llList2String(targets, 0);
                targets += [TXT_PUT_DOWN, TXT_ATTACH];
                useOS = number;
                integer result = llListFindList(mainMenuButtons, [TXT_DETACH]);
                if (useOS == TRUE)
                {
                    if (result == -1) mainMenuButtons += [TXT_DETACH];
                }
                else
                {
                    if (result != -1)  mainMenuButtons = llDeleteSubList(mainMenuButtons, result, result);
                }
            }
        }
        else if (cmd == "MY_LOCATION")
        {
            whereAmI = llList2String(tk, 1);
            if (whereAmI == "AM_DOWN") llMessageLinked(LINK_SET, 1, "MOVEMENT_SET", ""); else llMessageLinked(LINK_SET, 1, "MOVEMENT_SET", "");
        }
        else
        {
            if (message == TXT_ATTACH)
            {
                if (llGetPermissions() & PERMISSION_ATTACH)
                {
                    doAttach();
                }
                else
                {
                    llRequestPermissions(ownerID, PERMISSION_ATTACH);
                }
            }
            else if (message == TXT_PUT_DOWN)
            {
                llMessageLinked(LINK_SET, 1, "PUT_DOWN", "");
            }
            else if (llListFindList(targets, [message]) != -1)
            {
                // EXAMPLE   SF_PREFIX = "SF "    whereAmI = "SF Item Name"   message = "Item Name"
                if (SF_PREFIX+message == whereAmI)
                {
                    llRegionSayTo(ownerID, 0, TXT_ALREADY_THERE);
                }
                else
                {
                    llMessageLinked(LINK_SET, 1, "SEEK_SURFACE|"+SF_PREFIX +message, "");
                }
            }
            else
            {
                message = llToLower(message);
                //
                if (message == "set channel")
                {
                    chan = number;
                }
                else if (message == "reset")
                {
                    llResetScript();
                }
                else if (message == llToLower(TXT_CLOSE))
                {
                    //
                }
                else if (message == llToLower(TXT_DETACH))
                {
                    integer result = llListFindList(mainMenuButtons, [TXT_DETACH]);
                    if (result != -1)  mainMenuButtons = llDeleteSubList(mainMenuButtons, result, result);
                    if (llListFindList(mainMenuButtons, [TXT_MOVE]) == -1) mainMenuButtons += [TXT_MOVE];
                    osDropAttachment();
                    whereAmI = "AM_DOWN";
                    if (mainTarget != "") llMessageLinked(LINK_SET, 1, "SEEK_SURFACE|"+SF_PREFIX +mainTarget, "");
                }
                else if ((message == "dotouch") || (message == "interaction") || (message == llToLower(TXT_BACK)))
                {
                    llMessageLinked(LINK_SET, 0, "touch", id);
                    toucher = id;
                    llDialog(toucher, "\n" +TXT_SELECT, mainMenuButtons, chan);
                }
                else if (message == llToLower(TXT_BIRTHDATE))
                {
                    if (llGetInventoryType(g_strFilename) == INVENTORY_NOTECARD)
                    {
                        g_strDate = osGetNotecardLine(g_strFilename, 0);
                    }
                    else
                    {
                        g_strDate = "n/a";
                    }
                    //
                    if (llGetInventoryType("B-statusNC") == INVENTORY_NOTECARD)
                    {
                        list desc = llParseStringKeepNulls(osGetNotecardLine("B-statusNC", 0), [";"], []);
                        myName = llList2String(desc, 10);
                    }
                    llRegionSayTo(id, 0, myName +" " +g_strMessage +" " +g_strDate);
                    //
                    llMessageLinked(LINK_SET, 0, "touch", id);
                    toucher = id;
                    llDialog(toucher, "\n" +TXT_SELECT, mainMenuButtons, chan);
                }
                else if (message == llToLower(TXT_CLOTHING))
                {
                    //startOffset=0;
                    multiPageMenu(id, TXT_SELECT, wearableNames);
                }
                else if (message == llToLower(TXT_MOVE))
                {
                    startOffset += 0;
                    multiPageMenu(id, TXT_SELECT, targets);
                }
                else if (message ==">>")
                {
                    startOffset += 10;
                    multiPageMenu(id, TXT_SELECT, wearableNames);
                }
                else if (llListFindList(wearableNames, [message]) != -1)
                {
                    // -bib1|-dummy1b|-dummy1a|-hat1|-hairband1|-hat2|-ears1
                    string itemName = llGetSubString(message, 1, -1);
                    integer result = getLinkNum(PREFIX+itemName);
                    if (result != -1)
                    {
                        integer index = llListFindList(wearableNames, [message]);
                        if (llGetSubString(message, 0, 0) == "-")
                        {
                            llSetLinkAlpha(result, 0.0, ALL_SIDES);
                            wearableNames = llListReplaceList(wearableNames, ["+"+itemName], index, index);
                        }
                        else
                        {
                            llSetLinkAlpha(result, 1.0, ALL_SIDES);
                            wearableNames = llListReplaceList(wearableNames, ["-"+itemName], index, index);
                        }
                    }
                    multiPageMenu(id, TXT_SELECT, wearableNames);
                }
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_ATTACH)
        {
            doAttach();
        }
    }

}
