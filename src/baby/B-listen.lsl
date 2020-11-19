// B-listen.lsl
// Version 2.0  24 October 2020

integer g_intListenkey;
float g_fltTimer = 300.00;
integer g_intChannel = -1;
float g_fltMaxchannel = 9000.00;

integer randomchannel()
{
    integer intRandom;
    do
    {
        intRandom=(integer)llFrand(g_fltMaxchannel);
    }while(intRandom==0);
    intRandom = intRandom * -1;
    llMessageLinked(LINK_SET, intRandom, "set channel", NULL_KEY);
    return intRandom;
}

touched(key id)
{
    if (g_intListenkey != -1)
    {
        g_intListenkey = llListen(g_intChannel, "" ,NULL_KEY, "");
        llSetTimerEvent(g_fltTimer);
    }
}


default
{
    on_rez(integer start_param)
    {
        g_intChannel = randomchannel();
    }

    state_entry()
    {
        if (g_intChannel == -1)
        {
            g_intChannel = randomchannel();
        }
    }

    link_message(integer sender_num, integer number, string message,key id)
    {
        message=llToLower(message);

        if (message == "reset")
        {
            llResetScript();
        }
        else if (message == "get channel")
        {
            llMessageLinked(sender_num, g_intChannel, "set channel", id);
        }
        else if (message == "touch")
        {
            touched(id);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        llMessageLinked(LINK_SET,0,message,id);
        llSetTimerEvent(0.1);
    }

    timer()
    {
        if (g_intListenkey == -1)
        {
            llListenRemove(g_intListenkey);
            g_intListenkey = -1;
        }
        llSetTimerEvent(0);
    }
}
