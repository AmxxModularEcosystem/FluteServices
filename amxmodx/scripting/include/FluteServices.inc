#if defined __flute_services_included
    #endinput
#endif
#define __flute_services_included

stock const FLUTE_SERVICES_VERSION[] = "1.0.0";
stock const FLUTE_SERVICES_LEDGER_DRIVER[] = "givecore_services";

stock const FLUTE_SERVICES_LIMIT_HAS_NAME[] = "Flute-HasService"

#define FLUTE_SERVICES_KEY_MAX_LEN 64

// TODO: docs

forward Flute_Services_Init();

forward Flute_Services_PlayerUpdated(const playerIndex);

native bool:Flute_Services_Has(const playerIndex, const serviceKey[]);
