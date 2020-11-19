// setpin.lsl

default
{
    state_entry()
    {
        llSetText("", ZERO_VECTOR, 0.0);
    }

    on_rez(integer n)
    {
        llSetRemoteScriptAccessPin(999);
    }

}
