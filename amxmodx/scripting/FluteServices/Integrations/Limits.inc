#include <amxmodx>
#include <ParamsController>
#include <FluteServices>

#tryinclude <VipM/Limits>

static bool:Integration_Limits_Ready = true;

bool:Integration_Limits_NativeFilter(const name[], const bool:trap) {
    #if defined __vipm_limits_included
        if (equal(name, "VipM_Limits_RegisterType")) {
            Integration_Limits_Ready = !!trap;
            return true;
        }
    #endif

    return false;
}

#if defined __vipm_limits_included
public VipM_Limits_OnInited() {
    if (Integration_Limits_Ready) {
        VipM_Limits_RegisterType(FLUTE_SERVICES_LIMIT_HAS_NAME, true);
        VipM_Limits_AddParamsEx(FLUTE_SERVICES_LIMIT_HAS_NAME,
            PCParam("Service", DEFAULT_PARAMS_SHORT_STR_NAME, true)
        );
        VipM_Limits_RegisterTypeEvent(FLUTE_SERVICES_LIMIT_HAS_NAME, Limit_OnCheck, "@Integration_Limits_Has_OnCheck");
    }
}

bool:@Integration_Limits_Has_OnCheck(const Trie:p, const playerIndex) {
    return Player_HasService(playerIndex, PCGet_iStr(p, "Service"));
}
#endif