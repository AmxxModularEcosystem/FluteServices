#if defined __flute_services_included
    #endinput
#endif
#define __flute_services_included

stock const FLUTE_SERVICES_VERSION[] = "1.0.0";
stock const FLUTE_SERVICES_LEDGER_DRIVER[] = "givecore_services";

stock const FLUTE_SERVICES_LIMIT_HAS_NAME[] = "Flute-HasService"

#define FLUTE_SERVICES_KEY_MAX_LEN 64

/**
 * Вызывается после инициализации плагина (plugin_precache).
 *
 * @note Пока что негде использовать.
 * 
 * @noreturn
 */
forward Flute_Services_Init();

/**
 * Вызывается после обновления приобретённых услуг игрока.
 *
 * @param playerIndex Индекс игрока.
 *
 * @noreturn
 */
forward Flute_Services_PlayerUpdated(const playerIndex);

/**
 * Проверяет наличие у игрока услуги.
 *
 * @param playerIndex Индекс игрока.
 * @param serviceKey Ключ услуги из настройки драйвера "Услуги GiveCore" в товаре.
 *
 * @return true, если игрок имеет услугу, иначе false.
 */
native bool:Flute_Services_Has(const playerIndex, const serviceKey[]);
