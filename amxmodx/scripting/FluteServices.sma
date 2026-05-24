#include <amxmodx>
#include <json>
#include <easy_http>
#include <FluteServices>
#include <ParamsController>
#include <VipModular>

#include "FluteServices/Utils"
#include "FluteServices/Forwards"

#define ADMIN_ACCESS_FLAGS ADMIN_RCON

// TODO: Support additional params
// TODO: Give services

new ApiAccessToken[64];
new ApiBaseUrl[256];

new Trie:PlayerServices[MAX_PLAYERS + 1] = {Invalid_Trie, ...};

public plugin_precache() {
    register_plugin("[Flute] Services", FLUTE_SERVICES_VERSION, "ArKaNeMaN");
    Forwards_Init();
    ParamsController_Init();

    LoadConfig();

    register_clcmd("flute_services_test_has", "@ClCmd_Test_Has");
    register_concmd("flute_services_refresh", "@ConCmd_Refresh");

    Forwards_RegP("Flute_Services_PlayerUpdated", ET_IGNORE, FP_CELL);
    Forwards_RegAndCall("Flute_Services_Init", ET_IGNORE);
}

@ConCmd_Refresh(const playerIndex) {
    if (playerIndex != 0 && !(get_user_flags(playerIndex) & ADMIN_ACCESS_FLAGS)) {
        return PLUGIN_HANDLED;
    }
    
    if (read_argc() > 1) {
        static steamid[MAX_AUTHID_LENGTH];
        read_argv(1, steamid, charsmax(steamid));

        new playerIndex = FindOnlinePlayerBySteamId(steamid);

        if (playerIndex > 0) {
            Http_UpdatePlayer(playerIndex);
        }
    } else {
        for (new i = 1; i <= MAX_PLAYERS; ++i) {
            if (is_user_connected(i)) {
                Http_UpdatePlayer(i);
            }
        }
    }

    return PLUGIN_HANDLED;
}

@ClCmd_Test_Has(const playerIndex) {
    new serviceKey[FLUTE_SERVICES_KEY_MAX_LEN];
    read_argv(1, serviceKey, charsmax(serviceKey));

    if (PlayerServices[playerIndex] == Invalid_Trie) {
        client_print(playerIndex, print_console, "You have no this service (1).");
        return PLUGIN_HANDLED;
    }
    
    if (!TrieKeyExists(PlayerServices[playerIndex], serviceKey)) {
        client_print(playerIndex, print_console, "You have no this service (2).");
        return PLUGIN_HANDLED;
    }

    client_print(playerIndex, print_console, "You have this service.");
    return PLUGIN_HANDLED;
}

LoadConfig() {
    new JSON:cfgJson = PCJson_ParseFile(PCPath_iMakePath("Flute/API.json"));

    PCSingle_ObjString(cfgJson, "BaseUrl", ApiBaseUrl, charsmax(ApiBaseUrl), .orFail = true);
    PCSingle_ObjShortString(cfgJson, "AccessToken", ApiAccessToken, charsmax(ApiAccessToken), .orFail = true);

    PCJson_Free(cfgJson);
}

public client_putinserver(playerIndex) {
    InitPlayerServices(playerIndex);
    Http_UpdatePlayer(playerIndex);
}

public client_disconnected(playerIndex) {
    InitPlayerServices(playerIndex);
}

bool:Player_HasService(const playerIndex, const serviceKey[]) {
    if (PlayerServices[playerIndex] == Invalid_Trie) {
        return false;
    }
    
    return TrieKeyExists(PlayerServices[playerIndex], serviceKey);
}

Http_UpdatePlayer(const playerIndex) {
    if (is_user_bot(playerIndex)) {
        return;
    }

    new steamid[MAX_AUTHID_LENGTH];
    get_user_authid(playerIndex, steamid, charsmax(steamid));

    Http_Request(fmt("/api/givecore/services?steamid=%s", steamid), "@OnResponse_PlayerUpdated");
}

@OnResponse_PlayerUpdated(const EzHttpRequest:req) {
    Http_HandleError(req);

    new EzJSON:bodyJson = ezhttp_parse_json_response(req);

    static steamid64[MAX_AUTHID_LENGTH];
    ezjson_object_get_string(bodyJson, "steamid64", steamid64, charsmax(steamid64));

    static steamid[MAX_AUTHID_LENGTH];
    SteamID64_to_SteamID32(steamid64, steamid, charsmax(steamid));

    new playerIndex = FindOnlinePlayerBySteamId(steamid);
    if (playerIndex < 1) {
        ezjson_free(bodyJson);
        return;
    }

    InitPlayerServices(playerIndex);

    new EzJSON:servicesJson = ezjson_object_get_value(bodyJson, "services");
    for (new i = 0, ii = ezjson_array_get_count(servicesJson); i < ii; ++i) {
        new EzJSON:serviceJson = ezjson_array_get_value(servicesJson, i);

        if (!ezjson_object_get_bool(serviceJson, "active")) {
            continue;
        }

        static serviceKey[FLUTE_SERVICES_KEY_MAX_LEN];
        ezjson_object_get_string(serviceJson, "key", serviceKey, charsmax(serviceKey));

        new expiresAt = ezjson_object_get_number(serviceJson, "expires_at");

        TrieSetCell(PlayerServices[playerIndex], serviceKey, expiresAt);

        ezjson_free(serviceJson);
    }

    ezjson_free(servicesJson);
    ezjson_free(bodyJson);

    Forwards_CallP("Flute_Services_PlayerUpdated", playerIndex);
    Integration_OnPlayerUpdated(playerIndex);
    log_amx("Flute Services: Player %n has %d services.", playerIndex, TrieGetSize(PlayerServices[playerIndex]));
}

Http_HandleError(const EzHttpRequest:req) {
    if (ezhttp_get_http_code(req) == 200) {
        return;
    }

    static url[1024];
    ezhttp_get_url(req, url, charsmax(url));

    abort(0, "[HTTP ERROR] %s: %d", url, ezhttp_get_http_code(req));
}

EzHttpRequest:Http_Request(
    const path[], const callback[],
    &EzHttpOptions:options = EzHttpOptions:0,
    const EzJSON:bodyJson = EzInvalid_JSON,
    const bool:post = false
) {
    if (options == EzHttpOptions:0) {
        options = ezhttp_create_options();
    }
    
    ezhttp_option_set_header(options, "X-API-Key", ApiAccessToken);
    if (bodyJson != EzInvalid_JSON) {
        ezhttp_option_set_body_from_json(options, bodyJson);
    }

    static url[1024];
    formatex(url, charsmax(url), "%s%s", ApiBaseUrl, path);

    if (post) {
        return ezhttp_post(url, callback, options);
    } else {
        return ezhttp_get(url, callback, options);
    }
}

InitPlayerServices(const playerIndex) {
    if (PlayerServices[playerIndex] == Invalid_Trie) {
        PlayerServices[playerIndex] = TrieCreate();
    }
    
    TrieClear(PlayerServices[playerIndex]);
}

FindOnlinePlayerBySteamId(const steamid[]) {
    for (new i = 1; i <= MAX_PLAYERS; ++i) {
        if (!is_user_connected(i)) {
            continue;
        }

        new playerSteamid[MAX_AUTHID_LENGTH];
        get_user_authid(i, playerSteamid, charsmax(playerSteamid));

        if (!equali(steamid, playerSteamid)) {
            continue;
        }

        return i;
    }

    return 0;
}

#include "FluteServices/Integrations/Limits"
#include "FluteServices/Integrations/VipM"

public plugin_natives() {
    set_native_filter("@NativeFilter");

    register_native("Flute_Services_Has", "@Flute_Services_Has");
}

@NativeFilter(const name[], const index, const bool:trap) {
    new handled = false;

    if (Integration_Limits_NativeFilter(name, trap)) {
        handled = true;
    }

    if (Integration_VipM_NativeFilter(name, trap)) {
        handled = true;
    }

    // TODO: ItemsController (require give services)

    return handled ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

Integration_OnPlayerUpdated(const playerIndex) {
    Integration_VipM_PlayerUpdated(playerIndex);
}

bool:@Flute_Services_Has() {
    enum {Arg_PlayerIndex = 1, Arg_ServiceKey};

    new playerIndex = get_param(Arg_PlayerIndex);
    new serviceKey[FLUTE_SERVICES_KEY_MAX_LEN];
    get_string(Arg_ServiceKey, serviceKey, charsmax(serviceKey));

    return Player_HasService(playerIndex, serviceKey);
}
