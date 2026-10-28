/* Azeroth Forever | CoA classes with WoW: Forever-inspired default gameplay.
 * Copyright (C) 2016+ AzerothCore, GNU AGPL v3.
 * Keep original CoA class, trainer, quest and map functionality.
 */
#include "Config.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <array>

namespace
{
    // Ascension-only PvP ruleset auras. Standard WoW PvP flags and battlegrounds
    // are NOT disabled; the core owns that behavior in vanilla mode.
    constexpr std::array<uint32, 4> UnsupportedRulesetAuras = {
        1004019, // High Risk: do not retain the loot-loss ruleset on existing characters.
        1004119, // Ascension War Mode
        9931032, // Ascension PvE selection aura
        9930874  // Ascension Mercenary
    };

    // Ascension-only ruleset / corpse-shortcut selector spells; CoA class spells
    // and race/class-specific teleport abilities are deliberately untouched.
    constexpr std::array<uint32, 5> UnsupportedUtilitySpells = {
        84420, // Select War Mode
        84421, // Select High Risk
        84422, // Select Ascension PvE
        84423, // Resurrect in closest town
        84433  // Resurrect in closest capital
    };

    class AzerothForeverVanillaPlayerCleanup final : public PlayerScript
    {
    public:
        AzerothForeverVanillaPlayerCleanup()
            : PlayerScript("azeroth_forever_vanilla_player_cleanup", { PLAYERHOOK_ON_LOGIN }) { }

        void OnPlayerLogin(Player* player) override
        {
            if (!sConfigMgr->GetOption<bool>("AzerothForever.VanillaMode", true))
                return;

            for (uint32 spellId : UnsupportedRulesetAuras)
                player->RemoveAurasDueToSpell(spellId);

            for (uint32 spellId : UnsupportedUtilitySpells)
                if (player->HasSpell(spellId))
                    player->removeSpell(spellId, 0xFF, false);
        }
    };
}

void AddAzerothForeverVanillaCleanupScripts()
{
    new AzerothForeverVanillaPlayerCleanup();
}
