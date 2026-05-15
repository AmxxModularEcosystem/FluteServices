#if defined _flute_service_src_utils_included
    #endinput
#endif
#define _flute_service_src_utils_included

stock SteamID64_to_SteamID32(const steamid64[], output[], len)
{
    // База: 76561197960265728 = 0x0110000100000000
    // base_lo = 0x00000000 = 0  <- нижние 32 бита равны нулю!
    // base_hi = 0x01100001 = 17825793
    
    // Поэтому steamid32_raw = steamid64 mod 2^32
    // Естественное 32-битное переполнение PAWN даёт нам mod 2^32 бесплатно
    
    new lo = 0
    for (new i = 0; i < strlen(steamid64); i++)
    {
        new digit = steamid64[i] - '0'
        if (digit < 0 || digit > 9)
            continue
        lo = lo * 10 + digit  // переполнение = mod 2^32, именно что нужно
    }
    
    new Y = lo & 1          // последний бит (0 или 1)
    new accountid = lo >>> 1  // unsigned right shift

    formatex(output, len, "STEAM_0:%d:%d", Y, accountid)
}
