#include <amxmodx>
#include <ParamsController>
#include <FluteServices>

#tryinclude <VipModular>

static bool:Integration_VipM_Ready = true;

bool:Integration_VipM_NativeFilter(const name[], const bool:trap) {
    #if defined _vipmodular_included
        if (equal(name, "VipM_UserUpdate")) {
            Integration_VipM_Ready = !!trap;
            return true;
        }
    #endif

    return false;
}

Integration_VipM_PlayerUpdated(const playerIndex) {
    #if defined _vipmodular_included
        if (!Integration_VipM_Ready) {
            return;
        }
    
        VipM_UserUpdate(playerIndex);
    #endif
}