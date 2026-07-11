-- ==============================================================
-- command_deck.lua  (v2.0.0)
--
-- A single tabbed HUD hosting several tools in ONE window:
--
--   [ Boss ]   self-learning boss cast coach. Watches the current
--              target's cast bar and correlates each cast with your
--              health to teach ITSELF which skills are dangerous,
--              then pre-warns only on those. Persisted per boss+skill.
--   [ Vitals ] resource + buff sentinel: only the resources your class
--              uses (max learned by observation), CAPPED warnings, and
--              active statuses with countdowns.
--   [ Drops ]  target-aware drop table. Target a mob -> see exactly
--              what it drops and at what chance, colour-coded by rarity.
--   [ Craft ]  recipe browser. Search an item, see its ingredients,
--              and tick off what you've gathered (manual counts persist;
--              the game API exposes no inventory/bank to read).
--   [ Gear ]   rarity-based upgrade finder. Reads your worn equipment()
--              and, per slot, lists higher-rarity items plus how to get
--              each (craft job/level, or which mob drops it & where).
--
-- The Drops / Craft / Gear tabs are powered by an embedded copy of
-- FareverDB (items, units, crafts), the same dataset the community
-- item-finder ships. The data tables below are machine-generated;
-- do not edit them by hand.
--
-- Live tabs use only documented live API (farever.target/player/dps,
-- events, store, sound/toast, the imgui draw surface). Indices over
-- the static DB are built once at on_init, so per-frame cost is tiny.
-- ==============================================================

local DB_items = {
  ["ActivityLoot"]={n="ActivityLoot",r="Common",t="Misc",sell=1},
  ["Agate"]={n="Agate",r="Uncommon",t="CraftingComponent",sell=20},
  ["AlchemistEssence_Z1"]={n="Fresh Essence",r="Rare",t="CraftingComponent",sell=1},
  ["Alloy_Z1"]={n="Glittering Alloy",r="Rare",t="CraftingComponent",sell=1},
  ["Alloy_Z2"]={n="Shimmering Alloy",r="Rare",t="CraftingComponent",sell=1},
  ["Amber"]={n="Amber",r="Uncommon",t="CraftingComponent",sell=10},
  ["AncientThymePetal"]={n="Ancient Thyme Petal",r="Common",t="CraftingComponent",sell=7},
  ["AttunedCutBeryl"]={n="Attuned Cut Beryl",r="Uncommon",t="AugmentJeweller",sell=1},
  ["AttunedCutRuby"]={n="Attuned Cut Ruby",r="Uncommon",t="AugmentJeweller",sell=1},
  ["Axe_Boomerang"]={n="Cheese Moon",r="Rare",t="Axe",sell=1},
  ["Back_RBee_AssCle"]={n="Flight of the Rumblebee",r="Rare",t="Back",sell=1},
  ["Back_RBee_FigAss"]={n="Reflective Vest of the Hive Worker",r="Rare",t="Back",sell=1},
  ["Back_RBee_FigWiz_Craft"]={n="Beekeeper's Scarf",r="Rare",t="Back",sell=1},
  ["Back_RBee_Wiz"]={n="Back_RBee_Wiz",r="Rare",t="Back",sell=1},
  ["Back_RCrimson_AssCle_Craft"]={n="Cloak of Rising Twilight",r="Rare",t="Back",sell=1},
  ["Back_RCrimson_AssWiz"]={n="Diamond of the Order",r="Rare",t="Back",sell=1},
  ["Back_RCrimson_Fig"]={n="Crimson Wings",r="Rare",t="Back",sell=1},
  ["Back_RCrimson_WizCle"]={n="Sacrificial Cape",r="Rare",t="Back",sell=1},
  ["Back_RKobold_Ass"]={n="Reversible Bib of the Cheese Taster",r="Rare",t="Back",sell=1},
  ["Back_RKobold_Cle"]={n="Mystical Placemat of the Gourmet",r="Rare",t="Back",sell=1},
  ["Back_RKobold_FigWiz"]={n="Brie von de Cape",r="Rare",t="Back",sell=1},
  ["Back_RManfish_AssWiz"]={n="Cloak of the Third Wave Apostle",r="Rare",t="Back",sell=1},
  ["Back_RManfish_FigCle"]={n="Jenny Hanibal's Armored Cape",r="Rare",t="Back",sell=1},
  ["Back_RManfish_WizCle"]={n="Wings of the Prophet",r="Rare",t="Back",sell=1},
  ["Back_Shop"]={n="Farseeker Cloak",r="Epic",t="Back",sell=0},
  ["Back_Z1U1_Ass"]={n="Featherlight Capelet of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_AssCle"]={n="Ethereal Capelet of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_AssWiz"]={n="Infused Capelet of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_Cle"]={n="Sacred Scarf of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_Fig"]={n="Reinforced Neck Gaiter of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_FigAss"]={n="Condensed Neck Gaiter of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_FigCle"]={n="Blessed Neck Gaiter of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_FigWiz"]={n="Protected Neck Gaiter of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_Wiz"]={n="Spellbound Scarf of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U1_WizCle"]={n="Runic Scarf of the Exile",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_Ass"]={n="Featherlight Capelet of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_AssCle"]={n="Ethereal Capelet of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_AssWiz"]={n="Infused Capelet of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_Cle"]={n="Sacred Scarf of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_Fig"]={n="Reinforced Neck Gaiter of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_FigAss"]={n="Condensed Neck Gaiter of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_FigCle"]={n="Blessed Neck Gaiter of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_FigWiz"]={n="Protected Neck Gaiter of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_Wiz"]={n="Spellbound Scarf of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z1U2_WizCle"]={n="Runic Scarf of the Trespasser",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_Ass"]={n="Featherlight Capelet of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_AssCle"]={n="Ethereal Capelet of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_AssWiz"]={n="Infused Capelet of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_Cle"]={n="Sacred Scarf of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_Fig"]={n="Reinforced Neck Gaiter of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_FigAss"]={n="Condensed Neck Gaiter of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_FigCle"]={n="Blessed Neck Gaiter of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_FigWiz"]={n="Protected Neck Gaiter of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_Wiz"]={n="Spellbound Scarf of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U1_WizCle"]={n="Runic Scarf of the Adventurer",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_Ass"]={n="Featherlight Capelet of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_AssCle"]={n="Ethereal Capelet of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_AssWiz"]={n="Back_Z2U2_AssWiz",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_Cle"]={n="Sacred Scarf of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_Fig"]={n="Reinforced Neck Gaiter of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_FigAss"]={n="Condensed Neck Gaiter of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_FigCle"]={n="Blessed Neck Gaiter of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_FigWiz"]={n="Protected Neck Gaiter of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_Wiz"]={n="Spellbound Scarf of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Back_Z2U2_WizCle"]={n="Runic Scarf of the Nomad",r="Uncommon",t="Back",sell=1},
  ["Bag_Z2"]={n="Cotton Bag",r="Uncommon",t="Bag",sell=1},
  ["Beryl"]={n="Beryl",r="Uncommon",t="CraftingComponent",sell=10},
  ["Blood_Z1"]={n="Fresh Blood",r="Uncommon",t="CraftingComponent",sell=5},
  ["BoarMeat_Z1"]={n="Boar Meat",r="Common",t="Food",sell=2},
  ["Book_Start"]={n="Apprentice's Grimoire",r="Uncommon",t="Book",sell=1},
  ["Book_WaterOrbs"]={n="Book of Mi'Mizan",r="Rare",t="Book",sell=1},
  ["Bow_BigGame"]={n="Horns of the Wind",r="Rare",t="Bow",sell=1},
  ["Bow_Craft"]={n="Credence",r="Rare",t="Bow",sell=1},
  ["BrightVoidOrb"]={n="Bright Void Orb",r="Rare",t="CraftingComponent",sell=1},
  ["BronzeIngot"]={n="Bronze Ingot",r="Uncommon",t="CraftingComponent",sell=1},
  ["CP_Z1"]={n="Completed Package",r="Uncommon",t="CompletedPackage",sell=10},
  ["Cheese_Z1"]={n="Kobold Swiss",r="Common",t="Food",sell=3},
  ["Cheese_Z2"]={n="Ramburg Bleu",r="Common",t="Food",sell=5},
  ["Chest_C_BaseClothes"]={n="White Shirt",r="Common",t="Chest",sell=1},
  ["Chest_RBee_AssCle"]={n="Emblem of Radiant Nectar",r="Rare",t="Chest",sell=1},
  ["Chest_RBee_AssWiz_Craft"]={n="Splendid Wingsvest",r="Rare",t="Chest",sell=1},
  ["Chest_RBee_Fig"]={n="Whirring Gem of Apix",r="Rare",t="Chest",sell=1},
  ["Chest_RBee_WizCle"]={n="Casual Clothes of the Pollincess",r="Rare",t="Chest",sell=1},
  ["Chest_RCrimson_Ass"]={n="Gambeson of the Flying Ram",r="Rare",t="Chest",sell=1},
  ["Chest_RCrimson_FigCle"]={n="Breastplate of Recklessness",r="Rare",t="Chest",sell=1},
  ["Chest_RCrimson_Fig_Craft"]={n="Scarlet Breastplate",r="Rare",t="Chest",sell=1},
  ["Chest_RCrimson_Wiz"]={n="Krisomal's Golden Fleece",r="Rare",t="Chest",sell=1},
  ["Chest_RCrimson_WizCle_Craft"]={n="Sacrificial Vestments",r="Rare",t="Chest",sell=1},
  ["Chest_RKobold_AssWiz"]={n="Spirit of the Spelunker",r="Rare",t="Chest",sell=1},
  ["Chest_RKobold_Cle"]={n="Goldilock's Thrice Latched Jacket",r="Rare",t="Chest",sell=1},
  ["Chest_RKobold_FigAss"]={n="Cantal Goya's Breastplate",r="Rare",t="Chest",sell=1},
  ["Chest_RManfish_AssCle"]={n="Jacket of the Last Pirate",r="Rare",t="Chest",sell=1},
  ["Chest_RManfish_Cle"]={n="Charm of the Fisher King",r="Rare",t="Chest",sell=1},
  ["Chest_RManfish_FigWiz"]={n="Fin Armor",r="Rare",t="Chest",sell=1},
  ["Chest_Starter_Ass"]={n="Hoodlum's Doublet",r="Common",t="Chest",sell=1},
  ["Chest_Starter_Cle"]={n="Novitiate's Robe",r="Common",t="Chest",sell=1},
  ["Chest_Starter_Fig"]={n="Squire's Brigandine",r="Common",t="Chest",sell=1},
  ["Chest_Starter_Wiz"]={n="Apprentice's Tunic",r="Common",t="Chest",sell=1},
  ["Chest_Z1U1_Ass"]={n="Featherlight Doublet of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_AssCle"]={n="Ethereal Doublet of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_AssWiz"]={n="Infused Doublet of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_Cle"]={n="Sacred Robe of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_Fig"]={n="Reinforced Hauberk of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_FigAss"]={n="Condensed Hauberk of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_FigCle"]={n="Blessed Hauberk of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_FigWiz"]={n="Protected Hauberk of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_Wiz"]={n="Spellbound Robe of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U1_WizCle"]={n="Runic Robe of the Exile",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_Ass"]={n="Featherlight Doublet of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_AssCle"]={n="Ethereal Doublet of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_AssWiz"]={n="Infused Doublet of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_Cle"]={n="Sacred Robe of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_Fig"]={n="Reinforced Hauberk of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_FigAss"]={n="Condensed Hauberk of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_FigCle"]={n="Blessed Hauberk of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_FigWiz"]={n="Protected Hauberk of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_Wiz"]={n="Spellbound Robe of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z1U2_WizCle"]={n="Runic Robe of the Trespasser",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_Ass"]={n="Featherlight Jacket of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_AssCle"]={n="Ethereal Jacket of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_AssWiz"]={n="Infused Jacket of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_Cle"]={n="Sacred Vest of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_Fig"]={n="Reinforced Hauberk of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_FigAss"]={n="Condensed Hauberk of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_FigCle"]={n="Blessed Hauberk of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_FigWiz"]={n="Protected Hauberk of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_Wiz"]={n="Spellbound Vest of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U1_WizCle"]={n="Runic Vest of the Adventurer",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_Ass"]={n="Featherlight Jacket of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_AssCle"]={n="Ethereal Jacket of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_AssWiz"]={n="Infused Jacket of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_Cle"]={n="Sacred Vest of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_Fig"]={n="Reinforced Hauberk of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_FigAss"]={n="Condensed Hauberk of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_FigCle"]={n="Blessed Hauberk of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_FigWiz"]={n="Protected Hauberk of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_Wiz"]={n="Spellbound Vest of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["Chest_Z2U2_WizCle"]={n="Runic Vest of the Nomad",r="Uncommon",t="Chest",sell=1},
  ["ChippedTusk"]={n="Chipped Tusk",r="Uncommon",t="CraftingComponent",sell=7},
  ["Cloth_Z1"]={n="Linen Cloth",r="Common",t="Cloth",sell=3},
  ["Coal"]={n="Coal",r="Uncommon",t="CraftingComponent",sell=6},
  ["Cook_1"]={n="Wild Boar Stew",r="Common",t="Food",sell=1},
  ["Cook_10"]={n="Skover Root Soup",r="Common",t="Food",sell=1},
  ["Cook_11"]={n="Beggar's Garbure",r="Common",t="Food",sell=1},
  ["Cook_12"]={n="Pumpkin Pie",r="Common",t="Food",sell=1},
  ["Cook_13"]={n="Beehive Lozenge",r="Common",t="Food",sell=1},
  ["Cook_14"]={n="Ramburg Fondue",r="Common",t="Food",sell=1},
  ["Cook_15"]={n="Pike Cooked in Foil",r="Common",t="Food",sell=1},
  ["Cook_16"]={n="Sea Omelette",r="Common",t="Food",sell=1},
  ["Cook_2"]={n="Grilled Wolf Chops",r="Common",t="Food",sell=1},
  ["Cook_3"]={n="Crab Goulash",r="Common",t="Food",sell=1},
  ["Cook_4"]={n="Melted Herbed Cheese",r="Common",t="Food",sell=1},
  ["Cook_5"]={n="Grilled Mackerel",r="Common",t="Food",sell=1},
  ["Cook_6"]={n="Skunk Stew",r="Common",t="Food",sell=1},
  ["Cook_7"]={n="Flavored Candies",r="Common",t="Food",sell=1},
  ["Cook_8"]={n="Mixed Salad",r="Common",t="Food",sell=1},
  ["Cook_9"]={n="Smoked Coyote",r="Common",t="Food",sell=1},
  ["CopperIngot"]={n="Copper Ingot",r="Uncommon",t="CraftingComponent",sell=1},
  ["CopperOre"]={n="Copper Ore",r="Common",t="Ore",sell=3},
  ["CopperProspecting"]={n="Copper Prospecting",r="Common",t="Prospecting",sell=0},
  ["CopperSetting"]={n="Copper Setting",r="Uncommon",t="CraftingComponent",sell=1},
  ["CoyoteMeat"]={n="Coyote Meat",r="Common",t="Food",sell=5},
  ["CrabEgg"]={n="Crab Egg",r="Common",t="Food",sell=6},
  ["CrabMeat_Z1"]={n="Fleshy Claw",r="Common",t="Food",sell=2},
  ["CraftPoint"]={n="Craft point",r="Common",t="Currency",sell=1},
  ["Crescent_FlowerSpiral"]={n="Thornlace",r="Rare",t="Crescent",sell=1},
  ["Crystal_Z2"]={n="Glittering Essence",r="Epic",t="CraftingComponent",sell=1},
  ["CutAgate"]={n="Cut Agate",r="Uncommon",t="CraftingComponent",sell=1},
  ["CutAmber"]={n="Cut Amber",r="Uncommon",t="CraftingComponent",sell=1},
  ["CutBeryl"]={n="Cut Beryl",r="Uncommon",t="CraftingComponent",sell=1},
  ["CutMalachite"]={n="Cut Malachite",r="Rare",t="CraftingComponent",sell=1},
  ["CutRuby"]={n="Cut Ruby",r="Uncommon",t="CraftingComponent",sell=1},
  ["CutStone"]={n="Cracked Cut Stone",r="Uncommon",t="CraftingComponent",sell=1},
  ["DA_Water"]={n="Iron Fins of the Leviathan",r="Rare",t="DualAxes",sell=1},
  ["DM_Multispin"]={n="Twin Pillars of Justice",r="Rare",t="DualMaces",sell=1},
  ["DS_Z1RBee_AssWiz"]={n="Wingsabers",r="Rare",t="DualSwords",sell=1},
  ["Daggers_DuplicatePoison"]={n="Twin Fangs of Ratsar",r="Rare",t="Daggers",sell=1},
  ["Daggers_Start"]={n="Rusty Knives",r="Uncommon",t="Daggers",sell=1},
  ["DivinedCopperPlate"]={n="Divine Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["DivinedEmbroidery"]={n="Divine Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["DrippingDebris"]={n="Dripping Debris",r="Common",t="Usable",sell=1},
  ["ElixirOfAbundance"]={n="Elixir of Abundance",r="Common",t="Elixir",sell=1},
  ["ElixirOfArmor_Z2"]={n="Elixir of Armor",r="Common",t="Elixir",sell=1},
  ["ElixirOfDexterity_Z2"]={n="Elixir of Dexterity",r="Common",t="Elixir",sell=1},
  ["ElixirOfFaith_Z2"]={n="Elixir of Faith",r="Common",t="Elixir",sell=1},
  ["ElixirOfIntelligence_Z2"]={n="Elixir of Intelligence",r="Common",t="Elixir",sell=1},
  ["ElixirOfMinorDexterity"]={n="Elixir of Minor Dexterity",r="Common",t="Elixir",sell=1},
  ["ElixirOfMinorFaith"]={n="Elixir of Minor Faith",r="Common",t="Elixir",sell=1},
  ["ElixirOfMinorIntelligence"]={n="Elixir of Minor Intelligence",r="Common",t="Elixir",sell=1},
  ["ElixirOfMinorStrength"]={n="Elixir of Minor Strength",r="Common",t="Elixir",sell=1},
  ["ElixirOfStrength_Z2"]={n="Elixir of Strength",r="Common",t="Elixir",sell=1},
  ["ElixirofMinorArmor"]={n="Elixir of Minor Armor",r="Common",t="Elixir",sell=1},
  ["EnchantConcentrate_Z1"]={n="Bright Spark Concentrate",r="Rare",t="CraftingComponent",sell=1},
  ["EnchantPaper_Z1"]={n="Bright Enchanted Paper",r="Rare",t="CraftingComponent",sell=1},
  ["EnchantPowder_Z1"]={n="Purified Bright Powder",r="Uncommon",t="CraftingComponent",sell=1},
  ["Essence_Z2"]={n="Glittering Spark",r="Legendary",t="CraftingComponent",sell=1},
  ["Experience"]={n="Experience",r="Common",t="Currency",sell=0},
  ["Eye_Z1"]={n="Eyestalk",r="Common",t="CraftingComponent",sell=2},
  ["Fang_Z1"]={n="Small Fang",r="Common",t="CraftingComponent",sell=2},
  ["FastSwimPotion"]={n="Fast Swim Potion",r="Common",t="Potion",sell=1},
  ["Fat"]={n="Fat",r="Common",t="Food",sell=6},
  ["Feast"]={n="Plainswalker Feast",r="Rare",t="Food",sell=1},
  ["Feet_RBee_AssWiz"]={n="War Sabatons of Apix",r="Rare",t="Feet",sell=1},
  ["Feet_RBee_Cle"]={n="Cleo's Ethereal Blossoms",r="Rare",t="Feet",sell=1},
  ["Feet_RBee_Fig"]={n="Melain's Golden Greaves",r="Rare",t="Feet",sell=1},
  ["Feet_RBee_WizCle_Craft"]={n="Hiveriders",r="Rare",t="Feet",sell=1},
  ["Feet_RCrimson_Ass"]={n="Galoshes of Fortune",r="Rare",t="Feet",sell=1},
  ["Feet_RCrimson_FigCle"]={n="Rival Sabatons of Ironhorn",r="Rare",t="Feet",sell=1},
  ["Feet_RCrimson_Wiz"]={n="Curse of the Immortal",r="Rare",t="Feet",sell=1},
  ["Feet_RKobold_AssCle"]={n="Spelunking Shoes of Emmen Tunnel",r="Rare",t="Feet",sell=1},
  ["Feet_RKobold_FigAss"]={n="Buskins of Essential Emptiness",r="Rare",t="Feet",sell=1},
  ["Feet_RKobold_FigCle_Craft"]={n="Hot Cheesewalkers",r="Rare",t="Feet",sell=1},
  ["Feet_RKobold_WizCle"]={n="Gold Pouches",r="Rare",t="Feet",sell=1},
  ["Feet_RManfish_Ass"]={n="Bleak Shell's Knee Pads",r="Rare",t="Feet",sell=1},
  ["Feet_RManfish_AssWiz_Craft"]={n="Tidewalkers",r="Rare",t="Feet",sell=1},
  ["Feet_RManfish_FigWiz"]={n="Boots of Abyssal Essence",r="Rare",t="Feet",sell=1},
  ["Feet_RManfish_Wiz"]={n="Spare Sandals of Young Nephisto",r="Rare",t="Feet",sell=1},
  ["Feet_Starter_Ass"]={n="Hoodlum's Boots",r="Common",t="Feet",sell=1},
  ["Feet_Starter_Cle"]={n="Novitiate's Sandals",r="Common",t="Feet",sell=1},
  ["Feet_Starter_Fig"]={n="Squire's Shoes",r="Common",t="Feet",sell=1},
  ["Feet_Starter_Wiz"]={n="Apprentice's Shoes",r="Common",t="Feet",sell=1},
  ["Feet_Z1U1_Ass"]={n="Featherlight Boots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_AssCle"]={n="Ethereal Boots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_AssWiz"]={n="Infused Boots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_Cle"]={n="Sacred Sandals of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_Fig"]={n="Reinforced Warboots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_FigAss"]={n="Condensed Warboots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_FigCle"]={n="Blessed Warboots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_FigWiz"]={n="Protected Warboots of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_Wiz"]={n="Spellbound Sandals of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U1_WizCle"]={n="Runic Sandals of the Exile",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_Ass"]={n="Featherlight Boots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_AssCle"]={n="Ethereal Boots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_AssWiz"]={n="Infused Boots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_Cle"]={n="Sacred Sandals of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_Fig"]={n="Reinforced Warboots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_FigAss"]={n="Condensed Warboots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_FigCle"]={n="Blessed Warboots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_FigWiz"]={n="Protected Warboots of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_Wiz"]={n="Spellbound Sandals of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z1U2_WizCle"]={n="Runic Sandals of the Trespasser",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_Ass"]={n="Featherlight Boots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_AssCle"]={n="Ethereal Boots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_AssWiz"]={n="Infused Boots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_Cle"]={n="Sacred Buskins of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_Fig"]={n="Reinforced Warboots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_FigAss"]={n="Condensed Warboots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_FigCle"]={n="Blessed Warboots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_FigWiz"]={n="Protected Warboots of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_Wiz"]={n="Spellbound Buskins of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U1_WizCle"]={n="Runic Buskins of the Adventurer",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_Ass"]={n="Featherlight Boots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_AssCle"]={n="Ethereal Boots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_AssWiz"]={n="Infused Boots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_Cle"]={n="Sacred Buskins of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_Fig"]={n="Reinforced Warboots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_FigAss"]={n="Condensed Warboots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_FigWiz"]={n="Protected Warboots of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_Wiz"]={n="Spellbound Buskins of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Feet_Z2U2_WizCle"]={n="Runic Buskins of the Nomad",r="Uncommon",t="Feet",sell=1},
  ["Fin_Z1"]={n="Sticky Fin",r="Common",t="CraftingComponent",sell=2},
  ["Finger_Ap"]={n="Ring of Fracture",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Cri"]={n="Ring of Precision",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Fer"]={n="Ring of Zeal",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Mp"]={n="Ring of Clarity",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Z1RCraft_Ap"]={n="Circle of Fracture",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z1RCraft_Cri"]={n="Circle of Precision",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z1RCraft_Fer"]={n="Circle of Zeal",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z1RCraft_Mp"]={n="Circle of Clarity",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z1_Vit"]={n="Ring of Vitality",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Z2RCraft_CriAP"]={n="Signet of the Fighter",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z2RCraft_FerMP"]={n="Signet of the Wizard",r="Rare",t="GearFinger",sell=1},
  ["Finger_Z2_Ap"]={n="Ringlet of Fracture",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Z2_Cri"]={n="Ringlet of Precision",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Z2_Fer"]={n="Ringlet of Zeal",r="Uncommon",t="GearFinger",sell=1},
  ["Finger_Z2_Mp"]={n="Ringlet of Clarity",r="Uncommon",t="GearFinger",sell=1},
  ["FishermanSauce"]={n="Fisherman's Sauce",r="Uncommon",t="CraftingComponent",sell=1},
  ["Fists_LightMonk"]={n="Ramulus & Ramus",r="Rare",t="Fists",sell=1},
  ["Fists_WaterUppecut"]={n="Clawdius",r="Rare",t="Fists",sell=1},
  ["FormulaFeetArmorPen_Z2"]={n="Magic Formula: Armor Penetration",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetArmor_Z2"]={n="Magic Formula: Armor",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetCritical_Z2"]={n="Magic Formula: Critical Chance",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetFervor_Z2"]={n="Magic Formula: Fervor",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMagicPen_Z2"]={n="Magic Formula: Magic Penetration",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMinorArmor"]={n="Magic Formula: Minor Armor",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMinorArmorPen"]={n="Magic Formula: Minor Armor Penetration",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMinorCritical"]={n="Magic Formula: Minor Critical Chance",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMinorFervor"]={n="Magic Formula: Minor Fervor",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaFeetMinorMagicPen"]={n="Magic Formula: Minor Magic Penetration",r="Uncommon",t="AugmentEnchantFeet",sell=1},
  ["FormulaHandsDexterity_Z2"]={n="Magic Formula: Dexterity",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsFaith_Z2"]={n="Magic Formula: Faith",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsIntelligence_Z2"]={n="Magic Formula: Intelligence",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsMinorDexterity"]={n="Magic Formula: Minor Dexterity",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsMinorFaith"]={n="Magic Formula: Minor Faith",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsMinorIntelligence"]={n="Magic Formula: Minor Intelligence",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsMinorStrength"]={n="Magic Formula: Minor Strength",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsMinorVitality"]={n="Magic Formula: Minor Vitality",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsStrength_Z2"]={n="Magic Formula: Strength",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaHandsVitality_Z2"]={n="Magic Formula: Vitality",r="Uncommon",t="AugmentEnchantHands",sell=1},
  ["FormulaWeaponDevote"]={n="Magic Formula: Devote",r="Rare",t="AugmentEnchantWeapon",sell=1},
  ["FormulaWeaponFlamingWeapon"]={n="Magic Formula: Flaming Weapon",r="Rare",t="AugmentEnchantWeapon",sell=1},
  ["FormulaWeaponSparkHarvesting"]={n="Magic Formula: Spark Harvesting",r="Rare",t="AugmentEnchantWeapon",sell=1},
  ["FormulaWeaponZealot"]={n="Magic Formula: Zealot",r="Rare",t="AugmentEnchantWeapon",sell=1},
  ["FragmentOfAir"]={n="Fragment of Aoyl",r="Uncommon",t="CraftingComponent",sell=25},
  ["FragmentOfEarth"]={n="Fragment of Kyre",r="Uncommon",t="CraftingComponent",sell=25},
  ["FragmentOfFire"]={n="Fragment of Pyrh",r="Uncommon",t="CraftingComponent",sell=25},
  ["FragmentOfNature"]={n="Fragment of Mely",r="Uncommon",t="CraftingComponent",sell=25},
  ["FragmentOfWater"]={n="Fragment of Naya",r="Uncommon",t="CraftingComponent",sell=25},
  ["Fragments_Z1"]={n="Bright Fragments",r="Rare",t="CraftingComponent",sell=15},
  ["FreshFlowerPowder"]={n="Fresh Flower Powder",r="Uncommon",t="CraftingComponent",sell=1},
  ["GA_Craft"]={n="Judgement",r="Rare",t="GreatAxe",sell=1},
  ["GM_MassGrab"]={n="Pocket Hive",r="Rare",t="GreatMace",sell=1},
  ["GS_Z1Mines_Fig"]={n="Martyr of Enripit",r="Rare",t="GreatSword",sell=1},
  ["GildedCutBeryl"]={n="Gilded Cut Beryl",r="Uncommon",t="AugmentJeweller",sell=1},
  ["GildedCutRuby"]={n="Gilded Cut Ruby",r="Uncommon",t="AugmentJeweller",sell=1},
  ["Glider_Bat_BlackWhite"]={n="Navelian Bat",r="Epic",t="GearGlider",sell=500},
  ["Glider_Bat_Brown"]={n="Enripian Bat",r="Epic",t="GearGlider",sell=500},
  ["Glider_Bat_Burning"]={n="Incandescent Bat",r="Epic",t="GearGlider",sell=0},
  ["Glider_Bat_Demon"]={n="Niflelian Bat",r="Epic",t="GearGlider",sell=0},
  ["Glider_Bat_Grey"]={n="Skoverian Bat",r="Epic",t="GearGlider",sell=0},
  ["Glider_Bat_WhiteBlack"]={n="Krisomalese Bat",r="Epic",t="GearGlider",sell=500},
  ["Glider_Butterfly_Blue"]={n="Meropsian Moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_Demon"]={n="Niflelian Moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_EA_Spark"]={n="Sparkling Proto-moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_Green"]={n="Eksodean Moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_Orange"]={n="Antelimbian Moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_Pink"]={n="Pink Moth",r="Epic",t="GearGlider",sell=0},
  ["Glider_Butterfly_Yellow"]={n="Semeruian Moth",r="Epic",t="GearGlider",sell=500},
  ["Glider_Dragon_Blue"]={n="Meropsian Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Dragon_BlueGreen"]={n="Eksodean Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Dragon_Demon"]={n="Niflelian Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Dragon_Lava"]={n="Ebral Dragoon",r="Epic",t="GearGlider",sell=500},
  ["Glider_Dragon_Orange"]={n="Antelimbian Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Dragon_Pink"]={n="Pink Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Dragon_Yellow"]={n="Semeruian Dragoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Black"]={n="Navelian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Blue"]={n="Meropsian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Brown"]={n="Enripian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Green"]={n="Eksodean Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Grey"]={n="Skoverian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_Red"]={n="Egheretrian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_Falcon_White"]={n="Obralian Featherbeak",r="Epic",t="GearGlider",sell=0},
  ["Glider_FlyingFish_Acid"]={n="Acidic Wingfish",r="Epic",t="GearGlider",sell=500},
  ["Glider_FlyingFish_BlueGreen"]={n="Meropsian Wingfish",r="Epic",t="GearGlider",sell=500},
  ["Glider_FlyingFish_Demon"]={n="Niflelian Wingfish",r="Epic",t="GearGlider",sell=0},
  ["Glider_FlyingFish_Green"]={n="Skoverian Wingfish",r="Epic",t="GearGlider",sell=0},
  ["Glider_FlyingFish_Orange"]={n="Antelimbian Wingfish",r="Epic",t="GearGlider",sell=500},
  ["Glider_FlyingFish_Red"]={n="Egheretrian Wingfish",r="Epic",t="GearGlider",sell=0},
  ["Glider_Owl_BlackWarm"]={n="Krisomalese Owl",r="Epic",t="GearGlider",sell=0},
  ["Glider_Owl_BlueGrey"]={n="Zerzurian Owl",r="Epic",t="GearGlider",sell=500},
  ["Glider_Owl_Brown"]={n="Enripian Owl",r="Epic",t="GearGlider",sell=0},
  ["Glider_Owl_Brown02"]={n="Almazean Owl",r="Epic",t="GearGlider",sell=500},
  ["Glider_Owl_Grey"]={n="Azuramean Owl",r="Epic",t="GearGlider",sell=0},
  ["Glider_Owl_PurpleGrey"]={n="Ponogian Owl",r="Epic",t="GearGlider",sell=500},
  ["Glider_Raccoon_BlackBrown"]={n="Krisomalese Raccoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Raccoon_BlueGrey"]={n="Zerzurian Raccoon",r="Epic",t="GearGlider",sell=500},
  ["Glider_Raccoon_Brown01"]={n="Semeruian Raccoon",r="Epic",t="GearGlider",sell=500},
  ["Glider_Raccoon_Brown02"]={n="Enripian Raccoon",r="Epic",t="GearGlider",sell=500},
  ["Glider_Raccoon_Grey"]={n="Skoverial Raccoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Raccoon_Orange"]={n="Antelimbian Raccoon",r="Epic",t="GearGlider",sell=0},
  ["Glider_Sprout_Brown"]={n="Skoverian Seedbird",r="Epic",t="GearGlider",sell=0},
  ["Glider_Sprout_Green"]={n="Eksodean Seedbird",r="Epic",t="GearGlider",sell=500},
  ["Glider_Sprout_Orange"]={n="Antelimbian Seedbird",r="Epic",t="GearGlider",sell=0},
  ["Glider_Sprout_Red"]={n="Egheretrian Seedbird",r="Epic",t="GearGlider",sell=0},
  ["Glider_Sprout_WhitePink"]={n="Navelian Seedbird",r="Epic",t="GearGlider",sell=0},
  ["Glider_Sprout_Yellow"]={n="Semeruian Seedbird",r="Epic",t="GearGlider",sell=0},
  ["GlossyChitin"]={n="Glossy Chitin",r="Uncommon",t="CraftingComponent",sell=10},
  ["Gold"]={n="Gold",r="Common",t="Currency",sell=1},
  ["GracefulCopperPlate"]={n="Graceful Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["GracefulEmbroidery"]={n="Graceful Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["Halos_Demon"]={n="Halos_Demon",r="Rare",t="Halos",sell=1},
  ["Halos_Totem"]={n="Ghost Clams of the Low Tide",r="Rare",t="Halos",sell=1},
  ["Hammer"]={n="Worn Hammer",r="Common",t="ToolBlacksmith",sell=1},
  ["Hands_RBee_AssWiz"]={n="Vambraces of the Swarm",r="Rare",t="Hands",sell=1},
  ["Hands_RBee_Cle"]={n="Palmaryllis",r="Rare",t="Hands",sell=1},
  ["Hands_RBee_FigAss"]={n="Gauntlets of the Royal Guard",r="Rare",t="Hands",sell=1},
  ["Hands_RCrimson_Ass"]={n="Touch of Menas the Thaumaturge",r="Rare",t="Hands",sell=1},
  ["Hands_RCrimson_Fig"]={n="Unholy Crimson Gloves",r="Rare",t="Hands",sell=1},
  ["Hands_RCrimson_Wiz"]={n="Robin Hoof's Archery Gloves",r="Rare",t="Hands",sell=1},
  ["Hands_RKobold_AssCle"]={n="Gloves of Ninkilim the Envoy",r="Rare",t="Hands",sell=1},
  ["Hands_RKobold_Cle_Craft"]={n="Gloves of the Cheesomancer",r="Rare",t="Hands",sell=1},
  ["Hands_RKobold_FigWiz"]={n="Diskobold's Discus Throw Gloves",r="Rare",t="Hands",sell=1},
  ["Hands_RKobold_WizCle"]={n="Vows of Prosperity",r="Rare",t="Hands",sell=1},
  ["Hands_RManfish_Ass"]={n="Burden of the Abyss",r="Rare",t="Hands",sell=1},
  ["Hands_RManfish_FigAss_Craft"]={n="Handguards of the Deep Sea",r="Rare",t="Hands",sell=1},
  ["Hands_RManfish_FigCle"]={n="Palm of the Lagoon",r="Rare",t="Hands",sell=1},
  ["Hands_RManfish_Wiz"]={n="Ceremonial Siren Gloves",r="Rare",t="Hands",sell=1},
  ["Hands_Z1U1_Ass"]={n="Featherlight Hand Wraps of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_AssCle"]={n="Ethereal Hand Wraps of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_AssWiz"]={n="Infused Hand Wraps of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_Cle"]={n="Sacred Mittens of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_Fig"]={n="Reinforced Gauntlets of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_FigAss"]={n="Condensed Gauntlets of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_FigCle"]={n="Blessed Gauntlets of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_FigWiz"]={n="Protected Gauntlets of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_Wiz"]={n="Spellbound Mittens of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U1_WizCle"]={n="Runic Mittens of the Exile",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_Ass"]={n="Featherlight Hand Wraps of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_AssCle"]={n="Ethereal Hand Wraps of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_AssWiz"]={n="Infused Hand Wraps of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_Cle"]={n="Sacred Mittens of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_Fig"]={n="Reinforced Gauntlets of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_FigAss"]={n="Condensed Gauntlets of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_FigCle"]={n="Blessed Gauntlets of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_FigWiz"]={n="Protected Gauntlets of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_Wiz"]={n="Spellbound Mittens of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z1U2_WizCle"]={n="Runic Mittens of the Trespasser",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_Ass"]={n="Featherlight Armlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_AssCle"]={n="Ethereal Armlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_AssWiz"]={n="Infused Armlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_Cle"]={n="Sacred Wrists of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_Fig"]={n="Reinforced Gauntlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_FigAss"]={n="Condensed Gauntlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_FigCle"]={n="Blessed Gauntlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_FigWiz"]={n="Protected Gauntlets of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_Wiz"]={n="Spellbound Wrists of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U1_WizCle"]={n="Runic Wrists of the Adventurer",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_Ass"]={n="Featherlight Armlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_AssCle"]={n="Ethereal Armlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_AssWiz"]={n="Infused Armlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_Cle"]={n="Sacred Wrists of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_Fig"]={n="Reinforced Gauntlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_FigAss"]={n="Condensed Gauntlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_FigCle"]={n="Blessed Gauntlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_FigWiz"]={n="Protected Gauntlets of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_Wiz"]={n="Spellbound Wrists of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Hands_Z2U2_WizCle"]={n="Runic Wrists of the Nomad",r="Uncommon",t="Hands",sell=1},
  ["Head_RBee_AssWiz"]={n="Scout Antennae",r="Rare",t="Head",sell=1},
  ["Head_RBee_FigWiz"]={n="Royal Chamber Helmet",r="Rare",t="Head",sell=1},
  ["Head_RBee_WizCle"]={n="Vision of the Beekeeper",r="Rare",t="Head",sell=1},
  ["Head_RCrimson_AssCle"]={n="High-Ranking Official's Hat",r="Rare",t="Head",sell=1},
  ["Head_RCrimson_Cle"]={n="Clerical Veil",r="Rare",t="Head",sell=1},
  ["Head_RCrimson_FigAss"]={n="Ram Faceshield",r="Rare",t="Head",sell=1},
  ["Head_RKobold_AssWiz"]={n="Vision of the Cheeseslicer",r="Rare",t="Head",sell=1},
  ["Head_RKobold_FigCle"]={n="Armored Docker Cap",r="Rare",t="Head",sell=1},
  ["Head_RKobold_WizCle"]={n="Dust Scarf",r="Rare",t="Head",sell=1},
  ["Head_RManfish_Ass"]={n="Submarine Torpedo Helmet",r="Rare",t="Head",sell=1},
  ["Head_RManfish_Fig"]={n="Crown of the Sea",r="Rare",t="Head",sell=1},
  ["Head_RManfish_Wiz"]={n="Tides Hood",r="Rare",t="Head",sell=1},
  ["Head_Shop"]={n="Farseeker Goggles",r="Epic",t="Head",sell=0},
  ["Head_Z2U1_Ass"]={n="Featherlight Headband of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_AssCle"]={n="Ethereal Headband of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_AssWiz"]={n="Infused Headband of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_Cle"]={n="Sacred Circlet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_Fig"]={n="Reinforced Helmet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_FigAss"]={n="Condensed Helmet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_FigCle"]={n="Blessed Helmet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_FigWiz"]={n="Protected Helmet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_Wiz"]={n="Spellbound Circlet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U1_WizCle"]={n="Runic Circlet of the Adventurer",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_Ass"]={n="Featherlight Headband of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_AssCle"]={n="Ethereal Headband of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_AssWiz"]={n="Infused Headband of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_Cle"]={n="Sacred Circlet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_Fig"]={n="Reinforced Helmet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_FigAss"]={n="Condensed Helmet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_FigCle"]={n="Blessed Helmet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_FigWiz"]={n="Protected Helmet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_Wiz"]={n="Spellbound Circlet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["Head_Z2U2_WizCle"]={n="Runic Circlet of the Nomad",r="Uncommon",t="Head",sell=1},
  ["HealthPotion"]={n="Health Potion",r="Common",t="HealthPotion",sell=1},
  ["HideboundWeave"]={n="Soft Weave",r="Rare",t="CraftingComponent",sell=1},
  ["HonedCopperPlate"]={n="Honed Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["HonedEmbroidery"]={n="Honed Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["Honey_Z1"]={n="Honey",r="Common",t="Food",sell=3},
  ["HunterSauce"]={n="Hunter's Sauce",r="Uncommon",t="CraftingComponent",sell=1},
  ["InfusedTusk"]={n="Infused Tusk",r="Rare",t="GearTrinket",sell=1},
  ["InvisibilityPotion"]={n="Invisibility Potion",r="Common",t="Potion",sell=1},
  ["IronIngot"]={n="Iron Ingot",r="Uncommon",t="CraftingComponent",sell=1},
  ["IronOre"]={n="Iron Ore",r="Common",t="Ore",sell=9},
  ["Knife"]={n="Worn Knife",r="Common",t="ToolCook",sell=1},
  ["KoboldMetal"]={n="Piece of Perforated Metal",r="Uncommon",t="CraftingComponent",sell=10},
  ["LP_Z1_Bee"]={n="LP_Z1_Bee",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Boar"]={n="LP_Z1_Boar",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Copper"]={n="LP_Z1_Copper",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Crab"]={n="Lost Package",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Lavendula"]={n="LP_Z1_Lavendula",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Madrigold"]={n="LP_Z1_Madrigold",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Manfish"]={n="LP_Z1_Manfish",r="Uncommon",t="Package",sell=1},
  ["LP_Z1_Wolf"]={n="LP_Z1_Wolf",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Bee"]={n="LP_Z2_Bee",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Boar"]={n="LP_Z2_Boar",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Coyote"]={n="LP_Z2_Coyote",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Kobolds"]={n="LP_Z2_Kobolds",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Manfish"]={n="LP_Z2_Manfish",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Nature"]={n="LP_Z2_Nature",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Spirits"]={n="LP_Z2_Spirits",r="Uncommon",t="Package",sell=1},
  ["LP_Z2_Sprouts"]={n="LP_Z2_Sprouts",r="Uncommon",t="Package",sell=1},
  ["LavendulaPetal"]={n="Lavendula Petal",r="Common",t="CraftingComponent",sell=5},
  ["Leather_Z1"]={n="Light Leather Strap",r="Common",t="Leather",sell=1},
  ["Legs_RBee_Ass"]={n="Silhouette of Apix",r="Rare",t="Legs",sell=1},
  ["Legs_RBee_FigCle"]={n="Flying Trousers Prototype",r="Rare",t="Legs",sell=1},
  ["Legs_RBee_WizCle"]={n="Zenobee's Breeches",r="Rare",t="Legs",sell=1},
  ["Legs_RCrimson_AssCle"]={n="Ubu's Galligaskins",r="Rare",t="Legs",sell=1},
  ["Legs_RCrimson_Cle"]={n="Entommeure's Spiritual Breeches",r="Rare",t="Legs",sell=1},
  ["Legs_RCrimson_FigWiz"]={n="Crimson Pants",r="Rare",t="Legs",sell=1},
  ["Legs_RKobold_AssWiz"]={n="Garment of the Aurock Master",r="Rare",t="Legs",sell=1},
  ["Legs_RKobold_Fig"]={n="Wrong Trousers",r="Rare",t="Legs",sell=1},
  ["Legs_RKobold_Wiz"]={n="Rat-Vachol's Patched Up Pants",r="Rare",t="Legs",sell=1},
  ["Legs_RManfish_AssCle"]={n="Nepicur's Vacation Shorts",r="Rare",t="Legs",sell=1},
  ["Legs_RManfish_Cle"]={n="High-speed Clamdiggers",r="Rare",t="Legs",sell=1},
  ["Legs_RManfish_FigAss"]={n="Vesture of the Mussel Hunter",r="Rare",t="Legs",sell=1},
  ["Legs_Starter_Ass"]={n="Hoodlum's Pants",r="Common",t="Legs",sell=1},
  ["Legs_Starter_Cle"]={n="Novitiate's Breeches",r="Common",t="Legs",sell=1},
  ["Legs_Starter_Fig"]={n="Squire's Galligaskins",r="Common",t="Legs",sell=1},
  ["Legs_Starter_Wiz"]={n="Apprentice's Chausses",r="Common",t="Legs",sell=1},
  ["Legs_Z1U1_Ass"]={n="Featherlight Trousers of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_AssCle"]={n="Ethereal Trousers of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_AssWiz"]={n="Infused Trousers of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_Cle"]={n="Sacred Breeches of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_Fig"]={n="Reinforced Galligaskins of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_FigAss"]={n="Condensed Galligaskins of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_FigCle"]={n="Blessed Galligaskins of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_FigWiz"]={n="Protected Galligaskins of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_Wiz"]={n="Spellbound Breeches of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U1_WizCle"]={n="Runic Breeches of the Exile",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_Ass"]={n="Featherlight Trousers of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_AssCle"]={n="Ethereal Trousers of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_AssWiz"]={n="Infused Trousers of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_Cle"]={n="Sacred Breeches of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_Fig"]={n="Reinforced Galligaskins of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_FigAss"]={n="Condensed Galligaskins of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_FigCle"]={n="Blessed Galligaskins of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_FigWiz"]={n="Protected Galligaskins of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_Wiz"]={n="Spellbound Breeches of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z1U2_WizCle"]={n="Runic Breeches of the Trespasser",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_Ass"]={n="Featherlight Pants of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_AssCle"]={n="Ethereal Pants of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_AssWiz"]={n="Infused Pants of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_Cle"]={n="Sacred Breeches of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_Fig"]={n="Reinforced Galligaskins of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_FigAss"]={n="Condensed Galligaskins of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_FigCle"]={n="Blessed Galligaskins of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_FigWiz"]={n="Protected Galligaskins of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_Wiz"]={n="Spellbound Breeches of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U1_WizCle"]={n="Runic Breeches of the Adventurer",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_Ass"]={n="Featherlight Pants of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_AssCle"]={n="Ethereal Pants of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_AssWiz"]={n="Infused Pants of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_Cle"]={n="Sacred Breeches of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_Fig"]={n="Reinforced Galligaskins of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_FigAss"]={n="Condensed Galligaskins of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_FigCle"]={n="Blessed Galligaskins of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_FigWiz"]={n="Protected Galligaskins of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_Wiz"]={n="Spellbound Breeches of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["Legs_Z2U2_WizCle"]={n="Runic Breeches of the Nomad",r="Uncommon",t="Legs",sell=1},
  ["LinenBag"]={n="Linen Bag",r="Uncommon",t="Bag",sell=1},
  ["LinenBolt"]={n="Bolt of Linen Cloth",r="Uncommon",t="CraftingComponent",sell=1},
  ["LongBreathPotion"]={n="Long Breath Potion",r="Common",t="Potion",sell=1},
  ["Mace_Benediction"]={n="Amon Ram, the Creator",r="Rare",t="Mace",sell=1},
  ["Mackerel"]={n="Small Mackerel",r="Common",t="Food",sell=2},
  ["MadrigoldPetal"]={n="Madrigold Petal",r="Common",t="CraftingComponent",sell=3},
  ["Malachite"]={n="Malachite",r="Rare",t="CraftingComponent",sell=25},
  ["Mastery"]={n="Rune: ::ref_mastery::",r="Epic",t="Mastery",sell=100},
  ["MinorHealingPotion"]={n="Minor Healing Potion",r="Common",t="HealthPotion",sell=1},
  ["MinorShieldPotion"]={n="Minor Shield Potion",r="Common",t="Potion",sell=1},
  ["MinorVelocityPotion"]={n="Minor Velocity Potion",r="Common",t="Potion",sell=1},
  ["Mortar"]={n="Wooden Mortar",r="Common",t="ToolAlchemist",sell=1},
  ["MoteOfAir"]={n="Mote of Aoyl",r="Common",t="CraftingComponent",sell=5},
  ["MoteOfEarth"]={n="Mote of Kyre",r="Common",t="CraftingComponent",sell=5},
  ["MoteOfFire"]={n="Mote of Pyrh",r="Common",t="CraftingComponent",sell=5},
  ["MoteOfNature"]={n="Mote of Mely",r="Common",t="CraftingComponent",sell=5},
  ["MoteOfWater"]={n="Mote of Naya",r="Common",t="CraftingComponent",sell=5},
  ["Mount_Boar_01"]={n="Meridional Hog",r="Epic",t="Mount",sell=1000},
  ["Mount_Boar_02"]={n="Jodarian Hog",r="Epic",t="Mount",sell=0},
  ["Mount_Boar_03"]={n="Alandian Hog",r="Epic",t="Mount",sell=0},
  ["Mount_Boar_04"]={n="Irukalean Hog",r="Epic",t="Mount",sell=0},
  ["Mount_Boar_05"]={n="Veilantine Hog",r="Epic",t="Mount",sell=0},
  ["Mount_Boar_06"]={n="Niflelian Hog",r="Epic",t="Mount",sell=0},
  ["Mount_Crab_Blue"]={n="Meropsian Crab",r="Epic",t="Mount",sell=1000},
  ["Mount_Crab_BlueGrey"]={n="Zerzurian Crab",r="Epic",t="Mount",sell=0},
  ["Mount_Crab_Demonic"]={n="Niflelian Crab",r="Epic",t="Mount",sell=0},
  ["Mount_Crab_Purple"]={n="Ponogian Crab",r="Epic",t="Mount",sell=0},
  ["Mount_Crab_Red"]={n="Antelimbian Crab",r="Epic",t="Mount",sell=1000},
  ["Mount_Crab_Red02"]={n="Crimson Crab",r="Epic",t="Mount",sell=0},
  ["Mount_Crab_Yellow"]={n="Semeruian Crab",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_01"]={n="Eksodean Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_02"]={n="Ruleanese Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_03"]={n="Beltirian Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_04"]={n="Egheretrian Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_05"]={n="Atlanese Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Croco_06"]={n="Niflelian Crocoboar",r="Epic",t="Mount",sell=0},
  ["Mount_Goat_01"]={n="Ebralean Goat",r="Epic",t="Mount",sell=1000},
  ["Mount_Goat_02"]={n="Kondalese Goat",r="Epic",t="Mount",sell=1000},
  ["Mount_Goat_03"]={n="Opaline Goat",r="Epic",t="Mount",sell=1000},
  ["Mount_Goat_04"]={n="Crimson Goat",r="Epic",t="Mount",sell=0},
  ["Mount_Goat_05"]={n="Zerzurean Goat",r="Epic",t="Mount",sell=0},
  ["Mount_Goat_06"]={n="Niflelian Goat",r="Epic",t="Mount",sell=0},
  ["Mount_Hound_01"]={n="Fountrailian Hound",r="Epic",t="Mount",sell=1000},
  ["Mount_Hound_02"]={n="Skoverial Hound",r="Epic",t="Mount",sell=0},
  ["Mount_Hound_03"]={n="Antelimbian Hound",r="Epic",t="Mount",sell=0},
  ["Mount_Hound_04"]={n="Ramburgian Hound",r="Epic",t="Mount",sell=0},
  ["Mount_Hound_05"]={n="Lemian Hound",r="Epic",t="Mount",sell=0},
  ["Mount_Hound_06"]={n="Niflelian Hound",r="Epic",t="Mount",sell=0},
  ["Mount_Ladybug_Blue"]={n="Zerzurean Leggybug",r="Epic",t="Mount",sell=1000},
  ["Mount_Ladybug_DarkBlue"]={n="Alandian Leggybug",r="Epic",t="Mount",sell=0},
  ["Mount_Ladybug_Demonic"]={n="Niflelian Leggybug",r="Epic",t="Mount",sell=0},
  ["Mount_Ladybug_Green"]={n="Eksodean Leggybug",r="Epic",t="Mount",sell=0},
  ["Mount_Ladybug_Orange"]={n="Sforian Leggybug",r="Epic",t="Mount",sell=0},
  ["Mount_Ladybug_Purple"]={n="Ponogian Leggybug",r="Epic",t="Mount",sell=1000},
  ["Mount_Ladybug_Red"]={n="Nescentine Leggybug",r="Epic",t="Mount",sell=1000},
  ["Mount_Ladybug_Yellow"]={n="Antelimbian Leggybug",r="Epic",t="Mount",sell=0},
  ["Mount_Skunk_01"]={n="Primevallean Skunk",r="Epic",t="Mount",sell=1000},
  ["Mount_Skunk_02"]={n="Sperian Skunk",r="Epic",t="Mount",sell=0},
  ["Mount_Skunk_03"]={n="Crosselian Skunk",r="Epic",t="Mount",sell=0},
  ["Mount_Skunk_04"]={n="Rinuhrian Skunk",r="Epic",t="Mount",sell=1000},
  ["Mount_Skunk_05"]={n="Ponogian Skunk",r="Epic",t="Mount",sell=0},
  ["Mount_Skunk_06"]={n="Niflelian Skunk",r="Epic",t="Mount",sell=0},
  ["Mount_Wolf_01"]={n="Enripian Wolf",r="Epic",t="Mount",sell=1000},
  ["Mount_Wolf_02"]={n="Nescentine Wolf",r="Epic",t="Mount",sell=1000},
  ["Mount_Wolf_03"]={n="Krisomalese Wolf",r="Epic",t="Mount",sell=0},
  ["Mount_Wolf_04"]={n="Navelian Wolf",r="Epic",t="Mount",sell=1000},
  ["Mount_Wolf_05"]={n="Almazean Wolf",r="Epic",t="Mount",sell=1000},
  ["Mount_Wolf_06"]={n="Sforian Wolf",r="Epic",t="Mount",sell=0},
  ["MysticCopperPlate"]={n="Mystic Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["MysticEmbroidery"]={n="Mystic Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["Necklace_Z1RCraft"]={n="Pendant of Versatility",r="Rare",t="GearNeck",sell=1},
  ["Necklace_Z1_Ap"]={n="Amulet of Fracture",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z1_Cri"]={n="Amulet of Precision",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z1_Fer"]={n="Amulet of Zeal",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z1_Mp"]={n="Amulet of Clarity",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z1_Vit"]={n="Amulet of Vitality",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z2RCraft"]={n="Pendant of Adaptability",r="Rare",t="GearNeck",sell=1},
  ["Necklace_Z2_Ap"]={n="Necklace of Fracture",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z2_Cri"]={n="Necklace of Precision",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z2_Fer"]={n="Necklace of Zeal",r="Uncommon",t="GearNeck",sell=1},
  ["Necklace_Z2_Mp"]={n="Necklace of Clarity",r="Uncommon",t="GearNeck",sell=1},
  ["NepsidScale"]={n="Sharp Scale",r="Uncommon",t="CraftingComponent",sell=5},
  ["Net_Basic"]={n="Large Butterfly Net",r="Rare",t="CaptureNet",sell=150},
  ["Paper_Z1"]={n="Blank Page",r="Uncommon",t="CraftingComponent",sell=50},
  ["Particle_Z1"]={n="Bright Void Particles",r="Uncommon",t="CraftingComponent",sell=5},
  ["Pearl"]={n="Simple Pearl",r="Uncommon",t="CraftingComponent",sell=20},
  ["PhilosopherStone"]={n="Philosopher's Stone",r="Rare",t="GearTrinket",sell=1},
  ["Pickaxe"]={n="Worn Pickaxe",r="Common",t="GearPickaxe",sell=50},
  ["Pike"]={n="Pike",r="Common",t="Food",sell=5},
  ["Pliers"]={n="Worn Pliers",r="Common",t="ToolJeweller",sell=1},
  ["PrismaticFragment"]={n="Prismatic Fragment",r="Rare",t="CraftingComponent",sell=1},
  ["PrismaticPearl"]={n="Prismatic Pearl",r="Rare",t="GearTrinket",sell=1},
  ["Pumpkin"]={n="Pumpkin",r="Common",t="Food",sell=5},
  ["PurifiedHeart"]={n="Purified Heart",r="Rare",t="GearTrinket",sell=1},
  ["Ramgold"]={n="Ramgold",r="Rare",t="CraftingComponent",sell=25},
  ["RecipeGenerator"]={n="RecipeGenerator",r="Common",t="Misc",sell=1},
  ["Recipe_AttunedCutBeryl"]={n="Recipe_AttunedCutBeryl",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_AttunedCutRuby"]={n="Recipe_AttunedCutRuby",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_Cook_1"]={n="Recipe_Cook_1",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_13"]={n="Recipe_Cook_13",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_14"]={n="Recipe_Cook_14",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_15"]={n="Recipe_Cook_15",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_16"]={n="Recipe_Cook_16",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_2"]={n="Recipe_Cook_2",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_5"]={n="Recipe_Cook_5",r="Common",t="Recipe",sell=50},
  ["Recipe_Cook_7"]={n="Recipe_Cook_7",r="Common",t="Recipe",sell=50},
  ["Recipe_DivinedCopperPlate"]={n="Recipe_DivinedCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_DivinedEmbroidery"]={n="Recipe_DivinedEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_ElixirOfAbundance"]={n="Recipe_ElixirOfAbundance",r="Common",t="Recipe",sell=50},
  ["Recipe_ElixirOfArmor_Z2"]={n="Recipe_ElixirOfArmor_Z2",r="Common",t="Recipe",sell=100},
  ["Recipe_ElixirofMinorArmor"]={n="Recipe_ElixirofMinorArmor",r="Common",t="Recipe",sell=50},
  ["Recipe_FastSwimPotion"]={n="Recipe_FastSwimPotion",r="Common",t="Recipe",sell=50},
  ["Recipe_FormulaFeetArmorPen_Z2"]={n="Recipe_FormulaFeetArmorPen_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaFeetCritical_Z2"]={n="Recipe_FormulaFeetCritical_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaFeetFervor_Z2"]={n="Recipe_FormulaFeetFervor_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaFeetMagicPen_Z2"]={n="Recipe_FormulaFeetMagicPen_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaFeetMinorArmorPen"]={n="Recipe_FormulaFeetMinorArmorPen",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaFeetMinorCritical"]={n="Recipe_FormulaFeetMinorCritical",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaFeetMinorFervor"]={n="Recipe_FormulaFeetMinorFervor",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaFeetMinorMagicPen"]={n="Recipe_FormulaFeetMinorMagicPen",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaHandsDexterity_Z2"]={n="Recipe_FormulaHandsDexterity_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaHandsFaith_Z2"]={n="Recipe_FormulaHandsFaith_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaHandsIntelligence_Z2"]={n="Recipe_FormulaHandsIntelligence_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_FormulaHandsMinorDexterity"]={n="Recipe_FormulaHandsMinorDexterity",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaHandsMinorFaith"]={n="Recipe_FormulaHandsMinorFaith",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaHandsMinorIntelligence"]={n="Recipe_FormulaHandsMinorIntelligence",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaHandsMinorStrength"]={n="Recipe_FormulaHandsMinorStrength",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_FormulaHandsStrength_Z2"]={n="Recipe_FormulaHandsStrength_Z2",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_GildedCutBeryl"]={n="Recipe_GildedCutBeryl",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_GildedCutRuby"]={n="Recipe_GildedCutRuby",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_GracefulCopperPlate"]={n="Recipe_GracefulCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_GracefulEmbroidery"]={n="Recipe_GracefulEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_HonedCopperPlate"]={n="Recipe_HonedCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_HonedEmbroidery"]={n="Recipe_HonedEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_InvisibilityPotion"]={n="Recipe_InvisibilityPotion",r="Common",t="Recipe",sell=75},
  ["Recipe_LongBreathPotion"]={n="Recipe_LongBreathPotion",r="Common",t="Recipe",sell=50},
  ["Recipe_MinorShieldPotion"]={n="Recipe_MinorShieldPotion",r="Common",t="Recipe",sell=50},
  ["Recipe_MinorVelocityPotion"]={n="Recipe_MinorVelocityPotion",r="Common",t="Recipe",sell=50},
  ["Recipe_MysticCopperPlate"]={n="Recipe_MysticCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_MysticEmbroidery"]={n="Recipe_MysticEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_ResonantCutAgate"]={n="Recipe_ResonantCutAgate",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_ResonantCutAmber"]={n="Recipe_ResonantCutAmber",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_RunedCopperPlate"]={n="Recipe_RunedCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_RunedEmbroidery"]={n="Recipe_RunedEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_SanctifiedCopperPlate"]={n="Recipe_SanctifiedCopperPlate",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_SanctifiedEmbroidery"]={n="Recipe_SanctifiedEmbroidery",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_ShieldPotion_Z2"]={n="Recipe_ShieldPotion_Z2",r="Common",t="Recipe",sell=100},
  ["Recipe_SunderedCutAgate"]={n="Recipe_SunderedCutAgate",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_SunderedCutAmber"]={n="Recipe_SunderedCutAmber",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_SurgingCutAgate"]={n="Recipe_SurgingCutAgate",r="Uncommon",t="Recipe",sell=100},
  ["Recipe_SurgingCutAmber"]={n="Recipe_SurgingCutAmber",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_TemperedCutBeryl"]={n="Recipe_TemperedCutBeryl",r="Uncommon",t="Recipe",sell=50},
  ["Recipe_TemperedCutRuby"]={n="Recipe_TemperedCutRuby",r="Uncommon",t="Recipe",sell=100},
  ["RefillableFlask"]={n="Hess'tuss Flask",r="Common",t="HealthPotion",sell=1},
  ["ReinforcedCopperPlate"]={n="Reinforced Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["ReinforcedEmbroidery"]={n="Reinforced Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["Residues_Z1"]={n="Bright Residues",r="Uncommon",t="CraftingComponent",sell=2},
  ["ResonantCutAgate"]={n="Resonant Cut Agate",r="Uncommon",t="AugmentJeweller",sell=1},
  ["ResonantCutAmber"]={n="Resonant Cut Amber",r="Uncommon",t="AugmentJeweller",sell=1},
  ["Rock_Z1"]={n="Cracked Stone",r="Common",t="CraftingComponent",sell=3},
  ["RoyalJelly"]={n="Royal Jelly",r="Common",t="Food",sell=6},
  ["Ruby"]={n="Ruby",r="Uncommon",t="CraftingComponent",sell=20},
  ["RunedCopperPlate"]={n="Runed Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["RunedEmbroidery"]={n="Runed Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["SanctifiedCopperPlate"]={n="Sanctified Bronze Plate",r="Uncommon",t="AugmentBlacksmith",sell=1},
  ["SanctifiedEmbroidery"]={n="Sanctified Soft Embroidery",r="Uncommon",t="AugmentOutfitter",sell=1},
  ["Scepter_Flamie"]={n="Flame of Argol",r="Rare",t="Scepter",sell=1},
  ["Scepter_Start"]={n="Rehearsal Scepter",r="Uncommon",t="Scepter",sell=1},
  ["Scissors"]={n="Worn Scissors",r="Common",t="ToolOutfitter",sell=1},
  ["ScrollOfDexterity"]={n="Scroll Of Dexterity I",r="Common",t="Consumable",sell=1},
  ["ScrollOfFaith"]={n="Scroll Of Faith I",r="Common",t="Consumable",sell=1},
  ["ScrollOfIntelligence"]={n="Scroll Of Intelligence I",r="Common",t="Consumable",sell=1},
  ["ScrollOfStrength"]={n="Scroll Of Strength I",r="Common",t="Consumable",sell=1},
  ["ScrollOfVitality"]={n="Scroll Of Vitality I",r="Common",t="Consumable",sell=1},
  ["ShieldPotion_Z2"]={n="Shield Potion",r="Common",t="Potion",sell=1},
  ["Shield_Craft"]={n="Dominion",r="Rare",t="Shield",sell=1},
  ["Shield_Firebreath"]={n="Magma Mia",r="Rare",t="Shield",sell=1},
  ["Shield_OrbitWater"]={n="Crabgantua's Kneecap",r="Rare",t="Shield",sell=1},
  ["Shield_Start"]={n="Rough Shield",r="Uncommon",t="Shield",sell=1},
  ["ShopCurrency"]={n="ShopCurrency",r="Common",t="Currency",sell=1},
  ["Shoulders_RBee_Ass"]={n="Beewings",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RBee_FigCle"]={n="Queen Spikes",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RBee_Wiz"]={n="Hive Sprouts",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RCrimson_AssCle"]={n="Noble Mantle",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RCrimson_Cle"]={n="Judgment Spaulders",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RCrimson_FigWiz"]={n="Spaulders of Intangible Faith",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RKobold_Ass"]={n="Cheese-Covered Shoulderpads",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RKobold_Fig"]={n="Miner Ramparts",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RKobold_Wiz"]={n="Treasure Hunter's Straps",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RManfish_AssWiz"]={n="Fins of the First Fish",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RManfish_FigAss"]={n="Abyssal Shoulderplates",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_RManfish_WizCle"]={n="Delicate Marine Aiglets",r="Rare",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_Ass"]={n="Featherlight Straps of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_AssCle"]={n="Ethereal Straps of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_AssWiz"]={n="Infused Straps of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_Cle"]={n="Sacred Tippet of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_Fig"]={n="Reinforced Pauldrons of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_FigAss"]={n="Condensed Pauldrons of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_FigCle"]={n="Blessed Pauldrons of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_FigWiz"]={n="Protected Pauldrons of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_Wiz"]={n="Spellbound Tippet of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U1_WizCle"]={n="Runic Tippet of the Adventurer",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_Ass"]={n="Featherlight Straps of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_AssCle"]={n="Ethereal Straps of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_AssWiz"]={n="Infused Straps of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_Cle"]={n="Sacred Tippet of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_Fig"]={n="Reinforced Pauldrons of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_FigAss"]={n="Condensed Pauldrons of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_FigCle"]={n="Blessed Pauldrons of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_FigWiz"]={n="Protected Pauldrons of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_Wiz"]={n="Spellbound Tippet of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Shoulders_Z2U2_WizCle"]={n="Runic Tippet of the Nomad",r="Uncommon",t="Shoulders",sell=1},
  ["Sickle"]={n="Worn Sickle",r="Common",t="GearSickle",sell=50},
  ["SilverTray"]={n="Silver Tray",r="Common",t="CraftingComponent",sell=500},
  ["SimpleCauldron"]={n="Simple Cauldron",r="Common",t="CraftingComponent",sell=500},
  ["SkillPointBook_Red"]={n="Training Manual",r="Uncommon",t="SkillPointBook",sell=50},
  ["SkoverDriedHerbs"]={n="Mixed Herbs",r="Uncommon",t="CraftingComponent",sell=1},
  ["SkunkMeat_Z1"]={n="Skunk Meat",r="Common",t="Food",sell=2},
  ["SmallAlchemistCauldron"]={n="Minor Alchemist Cauldron",r="Rare",t="Potion",sell=1},
  ["SmallPouch"]={n="Small Pouch",r="Uncommon",t="Bag",sell=250},
  ["SoftFur"]={n="Soft Fur",r="Rare",t="CraftingComponent",sell=7},
  ["SparkHorse_01"]={n="Sparkling Horsean",r="Epic",t="Mount",sell=0},
  ["SparkSample"]={n="Spark Sample",r="Uncommon",t="CraftingComponent",sell=5},
  ["Spear_Eruption"]={n="Gorgon Ratsay’s Toothpick",r="Rare",t="Spear",sell=1},
  ["Spear_Goo"]={n="Lady Bee’s Ceremonial Stinger",r="Rare",t="Spear",sell=1},
  ["SpiritHeart_Z2"]={n="Ephemeral Heart",r="Common",t="CraftingComponent",sell=5},
  ["Staff_Craft"]={n="Radiance",r="Rare",t="Staff",sell=1},
  ["StaleBread"]={n="Stale Bread",r="Common",t="Food",sell=5},
  ["SteelIngot"]={n="Steel Ingot",r="Uncommon",t="CraftingComponent",sell=1},
  ["StoneOfCunning"]={n="Stone of Cunning",r="Rare",t="GearTrinket",sell=1},
  ["StoneOfPower"]={n="Stone of Power",r="Rare",t="GearTrinket",sell=1},
  ["StoneOfRighteousness"]={n="Stone of Rigtheousness",r="Rare",t="GearTrinket",sell=1},
  ["StoneOfWisdom"]={n="Stone of Wisdom",r="Rare",t="GearTrinket",sell=1},
  ["Stone_Ore_Z1"]={n="Glittering Stone",r="Rare",t="CraftingComponent",sell=15},
  ["StrangeSpores"]={n="Strange Spores",r="Rare",t="CraftingComponent",sell=15},
  ["StrongCutAgate"]={n="Strong Cut Agate",r="Uncommon",t="AugmentJeweller",sell=1},
  ["StrongCutAmber"]={n="Strong Cut Amber",r="Uncommon",t="AugmentJeweller",sell=1},
  ["SunderedCutAgate"]={n="Sundered Cut Agate",r="Uncommon",t="AugmentJeweller",sell=1},
  ["SunderedCutAmber"]={n="Sundered Cut Amber",r="Uncommon",t="AugmentJeweller",sell=1},
  ["SurgingCutAgate"]={n="Surging Cut Agate",r="Uncommon",t="AugmentJeweller",sell=1},
  ["SurgingCutAmber"]={n="Surging Cut Amber",r="Uncommon",t="AugmentJeweller",sell=1},
  ["SweetRoot"]={n="Sweet Root",r="Common",t="Food",sell=5},
  ["Sword_Craft"]={n="Glory",r="Rare",t="Sword",sell=1},
  ["Sword_Start"]={n="Light Practice Sword",r="Uncommon",t="Sword",sell=1},
  ["Sword_Swarm"]={n="Beefury, Blessed Blade of the Farseeker",r="Rare",t="Sword",sell=1},
  ["TPDeathStone"]={n="Death Stone",r="Uncommon",t="Consumable",sell=15},
  ["TannedLeather"]={n="Tanned Light Leather",r="Uncommon",t="CraftingComponent",sell=1},
  ["TeleportationStone"]={n="Sparkstone",r="Common",t="Usable",sell=1},
  ["TemperedCutBeryl"]={n="Tempered Cut Beryl",r="Uncommon",t="AugmentJeweller",sell=1},
  ["TemperedCutRuby"]={n="Tempered Cut Ruby",r="Uncommon",t="AugmentJeweller",sell=1},
  ["Thrown_Seeds"]={n="Ipheion, Star Blossom",r="Rare",t="Thrown",sell=1},
  ["TinOre"]={n="Tin Ore",r="Common",t="Ore",sell=5},
  ["TinProspecting"]={n="Tin Prospecting",r="Common",t="Prospecting",sell=0},
  ["Trinket_Bee"]={n="Eternal Flower Heart",r="Rare",t="GearTrinket",sell=1},
  ["Trinket_Crimson"]={n="Lost Relic Found",r="Rare",t="GearTrinket",sell=1},
  ["Trinket_Kobold"]={n="Raclette Pan",r="Rare",t="GearTrinket",sell=1},
  ["Trinket_Manfish"]={n="Poetrident",r="Rare",t="GearTrinket",sell=1},
  ["TungsteneIngot"]={n="Tungstene Ingot",r="Rare",t="CraftingComponent",sell=1},
  ["TungsteneOre"]={n="Tungstene Ore",r="Rare",t="Ore",sell=7},
  ["TungsteneProspecting"]={n="Tungstene Prospecting",r="Common",t="Prospecting",sell=0},
  ["UpgradeAll"]={n="Spark Dust",r="Uncommon",t="Misc",sell=2},
  ["UpgradeEpic"]={n="Spark Crystal",r="Epic",t="Misc",sell=15},
  ["UpgradeRare"]={n="Spark Shard",r="Rare",t="Misc",sell=7},
  ["Vial"]={n="Vial",r="Common",t="CraftingComponent",sell=30},
  ["Waist_RBee_AssCle"]={n="Propolis Heart of Apix",r="Rare",t="Waist",sell=1},
  ["Waist_RBee_FigWiz"]={n="Aura of the Honeycomb",r="Rare",t="Waist",sell=1},
  ["Waist_RBee_Wiz"]={n="Dancing Hivetree Belt",r="Rare",t="Waist",sell=1},
  ["Waist_RCrimson_AssWiz"]={n="Relic of Cernoros the Lost King",r="Rare",t="Waist",sell=1},
  ["Waist_RCrimson_FigAss"]={n="Forbidden Insignia of Silence",r="Rare",t="Waist",sell=1},
  ["Waist_RCrimson_WizCle"]={n="Curse of the Immortal",r="Rare",t="Waist",sell=1},
  ["Waist_RKobold_Ass"]={n="Relic of the Four Hundred",r="Rare",t="Waist",sell=1},
  ["Waist_RKobold_AssCle_Craft"]={n="Belt of the Great Fermentation",r="Rare",t="Waist",sell=1},
  ["Waist_RKobold_Cle"]={n="Knotr'Edam",r="Rare",t="Waist",sell=1},
  ["Waist_RKobold_FigCle"]={n="Unity of the Thirty Kingdoms",r="Rare",t="Waist",sell=1},
  ["Waist_RManfish_AssWiz"]={n="Emblem of the Third Wave",r="Rare",t="Waist",sell=1},
  ["Waist_RManfish_Fig"]={n="Caryapsid's Coccyx",r="Rare",t="Waist",sell=1},
  ["Waist_RManfish_WizCle"]={n="Ceremonial Nepsid Belt",r="Rare",t="Waist",sell=1},
  ["Waist_RManfish_Wiz_Craft"]={n="Barnacle Waistwrap",r="Rare",t="Waist",sell=1},
  ["Waist_Z1U1_Ass"]={n="Featherlight Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_AssCle"]={n="Ethereal Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_AssWiz"]={n="Infused Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_Cle"]={n="Sacred Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_Fig"]={n="Reinforced Pteruge of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_FigAss"]={n="Condensed Pteruge of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_FigCle"]={n="Blessed Pteruge of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_FigWiz"]={n="Protected Pteruge of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_Wiz"]={n="Spellbound Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U1_WizCle"]={n="Runic Belt of the Exile",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_Ass"]={n="Featherlight Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_AssCle"]={n="Ethereal Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_AssWiz"]={n="Infused Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_Cle"]={n="Sacred Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_Fig"]={n="Reinforced Pteruge of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_FigAss"]={n="Condensed Pteruge of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_FigCle"]={n="Blessed Pteruge of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_FigWiz"]={n="Protected Pteruge of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_Wiz"]={n="Spellbound Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z1U2_WizCle"]={n="Runic Belt of the Trespasser",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_Ass"]={n="Featherlight Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_AssCle"]={n="Ethereal Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_AssWiz"]={n="Infused Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_Cle"]={n="Sacred Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_Fig"]={n="Reinforced Pteruge of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_FigAss"]={n="Condensed Pteruge of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_FigCle"]={n="Blessed Pteruge of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_FigWiz"]={n="Protected Pteruge of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_Wiz"]={n="Spellbound Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U1_WizCle"]={n="Runic Belt of the Adventurer",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_Ass"]={n="Featherlight Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_AssCle"]={n="Ethereal Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_AssWiz"]={n="Infused Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_Cle"]={n="Sacred Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_Fig"]={n="Reinforced Pteruge of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_FigAss"]={n="Condensed Pteruge of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_FigCle"]={n="Waist_Z2U2_FigCle",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_Wiz"]={n="Spellbound Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Waist_Z2U2_WizCle"]={n="Runic Belt of the Nomad",r="Uncommon",t="Waist",sell=1},
  ["Wand"]={n="Wooden Wand",r="Common",t="ToolEnchanter",sell=1},
  ["Weightstone"]={n="Weightstone",r="Common",t="Consumable",sell=1},
  ["Wheat"]={n="Wheat",r="Common",t="Food",sell=4},
  ["Whetstone"]={n="Whetstone",r="Common",t="Consumable",sell=1},
  ["Wing_Z1"]={n="Diaphanous Wings",r="Common",t="CraftingComponent",sell=2},
  ["WolfMeat_Z1"]={n="Wolf Meat",r="Common",t="Food",sell=2},
  ["WorldLoot"]={n="WorldLoot",r="Common",t="Misc",sell=1},
  ["WorldLootWithAffinity"]={n="WorldLootWithAffinity",r="Common",t="Misc",sell=1},
  ["WorldRecipeWithJob"]={n="WorldRecipeWithJob",r="Common",t="Misc",sell=1},
  ["Z1_WeaponBundle"]={n="Mysterious Cache",r="Rare",t="LootableContainer",sell=1},
  ["ZealotusPetal"]={n="Zealotus Petal",r="Rare",t="CraftingComponent",sell=10},
}

local DB_units = {
  ["Bee_Z1D"]={n="Hivetree Harvester",lv=10,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1W"]={n="Apix Harvester",lv=3,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1W_2"]={n="Bibulous Apix Harvester",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1W_3"]={n="Tipsy Apix Harvester",lv=10,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1W_E"]={n="Beelial",lv=12,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1W_U"]={n="Sparkling Harvester",lv=3,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z1_FS"]={n="Bibulous Invoked Harvester",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z2W"]={n="Intoxicated Apix Harvester",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bee_Z2W_U"]={n="Sparkling Harvester",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Bees_Mokshi"]={n="Chamber Guardian",lv=13,tp="Bee",zn="",zname="",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Boar_Z1W"]={n="Boar",lv=11,tp="Boar",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z1W_E"]={n="Niels Boar",lv=6,tp="Boar",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z2W"]={n="Reclusive Boar",lv=13,tp="Boar",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z2W_2"]={n="Hermitic Boar",lv=17,tp="Boar",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z2W_E"]={n="Venerer's Hog",lv=20,tp="Boar",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z2W_U"]={n="Sparkling Boar",lv=14,tp="Boar",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Boar_Z4W_E"]={n="Boar Burnham",lv=10,tp="Boar",zn="Z4_Region",zname="Ramburg",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["CannonHoney"]={n="Honey Cannon",lv=0,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["CannonPlant"]={n="Cannon Plant",lv=0,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cannon_Mokshi"]={n="Honey Cannon",lv=0,tp="Bee",zn="",zname="",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cleodora"]={n="Queen Honeyzabeth",lv=20,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="GM_MassGrab",n="Pocket Hive",c=1},{i="DS_Z1RBee_AssWiz",n="Wingsabers",c=1}}},
  ["Cleodora_Champion"]={n="Prince Beelliams",lv=19,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cleodora_Champion2"]={n="Prince Beeter",lv=19,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cleodora_Champion3"]={n="Princess Beeatrice",lv=19,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cleodora_ChampionEgg"]={n="Champion's Chrysalid",lv=9,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Cleodora_Feeder"]={n="Feeder Bee",lv=19,tp="Bee",zn="",zname="",dg="R1_POI_CleodorasNest",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Crab_Crabgantua"]={n="Crab of the Lost City",lv=8,tp="Crab",zn="",zname="",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1D"]={n="Crab of the Lost City",lv=4,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W"]={n="Crab",lv=1,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_2"]={n="Fiddler Crab",lv=3,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_3"]={n="Snapping Crab",lv=7,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_5"]={n="Solist Crab",lv=10,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_E"]={n="Belzebubbles",lv=3,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_E_2"]={n="Kraba the Sorceress",lv=11,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_E_3"]={n="Fiddle Crabstro",lv=9,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_FS"]={n="Snapping Invoked Crab",lv=7,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_FS_1"]={n="Virtuoso Invoked Crab",lv=9,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z1W_U"]={n="Sparkling Crab",lv=11,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z2D_2"]={n="Abyssal Crab",lv=14,tp="Crab",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z2W"]={n="Ruins Crab",lv=14,tp="Crab",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crab_Z2W_E"]={n="Carcinos the Proud",lv=17,tp="Crab",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crabgantua"]={n="Crabgantua",lv=8,tp="Crab",zn="",zname="",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="Shield_OrbitWater",n="Crabgantua's Kneecap",c=1},{i="Fists_WaterUppecut",n="Clawdius",c=1}}},
  ["Crawler_Z1W_E"]={n="Krabby Jacob",lv=11,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Crimson_Base"]={n="Crimson_Base",lv=0,tp="Crimson",zn="",zname="",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z1W_Bow"]={n="Crimson Archer",lv=8,tp="Crimson",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z1W_Captain_E"]={n="Ram Page",lv=10,tp="Crimson",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z1W_Captain_U"]={n="Crimson Captain Agamemnon",lv=10,tp="Crimson",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z1W_Sword"]={n="Crimson Soldier",lv=8,tp="Crimson",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Beekeeper"]={n="Crimson Beekeeper",lv=13,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Beekeeper2"]={n="Beekept Crimson",lv=15,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Bow"]={n="Observant Crimson Archer",lv=15,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Bow_2"]={n="Sighted Crimson Archer",lv=17,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_E"]={n="Captain Ramshackle",lv=16,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_U"]={n="Crimson Captain Miranda",lv=16,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_U_2"]={n="Crimson Captain Sensabille",lv=16,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_U_3"]={n="Crimson Captain Clover",lv=18,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_U_4"]={n="Crimson Captain Carmine",lv=16,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Captain_U_6"]={n="Crimson Captain Ben",lv=20,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Monk"]={n="Crimson Preacher",lv=15,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Monk_2"]={n="Trained Crimson Preacher",lv=17,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Peasant"]={n="Crimson Farmhand",lv=13,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Peasant2"]={n="Bucolic Crimson Farmhand",lv=17,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Peasant_E"]={n="Celeryman Pumpkintaro",lv=15,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Peasant_FS"]={n="Invoked Crimson Farmhand",lv=18,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Sword"]={n="Devout Crimson Soldier",lv=15,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crimson_Z2W_Sword_2"]={n="Fervent Crimson Soldier",lv=17,tp="Crimson",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["Crocopork_Z1W"]={n="Crocoboar",lv=2,tp="Boar",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["Demon_Z3W_Claws"]={n="Nightling Slayer",lv=20,tp="Demon",zn="Z3_Region",zname="Ramburg",dg="",dr={}},
  ["Dog_Z2W_Azuram"]={n="Carmine Hound",lv=13,tp="Wolf",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["Dummy_FX"]={n="FXTest",lv=1,tp="Human",zn="",zname="",dg="",dr={}},
  ["Egglektra"]={n="Egglektra",lv=3,tp="Swarowl",zn="",zname="",dg="",dr={}},
  ["Elemental_Z1D_Earth"]={n="Sparkle of Estrone",lv=6,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="R1_POI_Dungeon_AbbandonedMines",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Elemental_Z1D_Lava"]={n="Gorgon's Hollow Sparkle",lv=16,tp="FireGolems",zn="Z1_Region",zname="Skover Island",dg="R1_POI_GorgonsHollow",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z1W_Earth"]={n="Sparkle",lv=7,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Elemental_Z1W_Earth_U"]={n="Sparkling Sparkle",lv=8,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Elemental_Z1W_Underwater"]={n="Naya Sparkle",lv=7,tp="WaterGolems",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfWater",n="Mote of Naya",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z1_FS_Earth"]={n="Invoked Sparkle",lv=7,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Elemental_Z1_FS_Underwater"]={n="Invoked Naya Sparkle",lv=9,tp="WaterGolems",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfWater",n="Mote of Naya",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2D_Underwater"]={n="New Atlaan Sparkle",lv=16,tp="WaterGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfWater",n="Mote of Naya",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W"]={n="Aoyl Sparkle",lv=14,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W_2"]={n="Lightweight Aoyl Sparkle",lv=19,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W_Lava"]={n="Pyrh Sparkle",lv=15,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W_Lava_2"]={n="Molten Pyrh Sparkle",lv=19,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W_Underwater"]={n="Naya Sparkle",lv=15,tp="WaterGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfWater",n="Mote of Naya",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2W_Underwater_U"]={n="Aquamarine Sparkle",lv=18,tp="WaterGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfWater",n="Mote of Naya",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2_FS"]={n="Invoked Aoyl Sparkle",lv=20,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2_FS_Lava"]={n="Pyrh Sparkle",lv=18,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Elemental_Z2_FS_Lava_2"]={n="Molten Invoked Pyrh Sparkle",lv=20,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["FaerieBee_Base"]={n="FaerieBee_Base",lv=0,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1D_Claws"]={n="Hivetree Watcher",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1D_GreatMace"]={n="Royal Guard of the Hivetree",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1D_Spear"]={n="Hivetree Builder",lv=10,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_Claws"]={n="Apix Watcher",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_Claws_E"]={n="Honey Mucha",lv=12,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_GreatMace"]={n="Apix Royal Guard",lv=12,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_GreatMace_E"]={n="Honey Zucca",lv=13,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_Spear"]={n="Apix Builder",lv=11,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_Spear_U"]={n="Sparkling Builder",lv=12,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1W_Tank"]={n="Apix Defender",lv=10,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z1_FS"]={n="Invoked Royal Guard",lv=12,tp="Bee",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_Champ_E"]={n="Notorious Bee",lv=20,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_Claws"]={n="Overzealous Apix Watcher",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_FS_Tank"]={n="Invoked Defender",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_GreatMace"]={n="Overqualified Apix Royal Guard",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_GreatMace_E"]={n="Bartlebee",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_GreatMace_U"]={n="Left Wing",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_GreatMace_U_2"]={n="Right Wing",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_Spear"]={n="Overworked Apix Builder",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_Spear_U"]={n="Sparkling Builder",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2W_Tank"]={n="Overprotective Apix Defender",lv=19,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["FaerieBee_Z2_FS_Tank_2"]={n="Overworked Invoked Builder",lv=18,tp="Bee",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["Gatsbee"]={n="Gatsbee",lv=12,tp="Bee",zn="",zname="",dg="R1_POI_MokshisHivetree",dr={{i="Crescent_FlowerSpiral",n="Thornlace",c=1},{i="Spear_Goo",n="Lady Bee’s Ceremonial Stinger",c=1}}},
  ["GiantCrab_Z1W_U"]={n="Sparkling Crustacean",lv=11,tp="Crab",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="CrabMeat_Z1",n="Fleshy Claw",c=40},{i="CrabEgg",n="Crab Egg",c=20},{i="Eye_Z1",n="Eyestalk",c=12},{i="Pearl",n="Simple Pearl",c=6},{i="Pearl",n="Simple Pearl",c=3},{i="MoteOfWater",n="Mote of Naya",c=0.05},{i="Mount_Crab_Blue",n="Meropsian Crab",c=0.10},{i="Mount_Crab_Red",n="Antelimbian Crab",c=0.10}}},
  ["Golcano"]={n="Golcano",lv=15,tp="Golem",zn="",zname="",dg="R1_POI_GorgonsHollow",dr={{i="Spear_Eruption",n="Gorgon Ratsay’s Toothpick",c=1},{i="Shield_Firebreath",n="Magma Mia",c=1}}},
  ["Golcano_Minion"]={n="Golcanito",lv=15,tp="Golem",zn="",zname="",dg="R1_POI_GorgonsHollow",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Base"]={n="Golem_Base",lv=0,tp="Golem",zn="",zname="",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1W_Earth1"]={n="Golem",lv=7,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1W_Earth_2"]={n="Solid  Golem",lv=10,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1W_Earth_E"]={n="Smeagolem",lv=8,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1W_Earth_E_2"]={n="Goledeneye",lv=12,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1_FS"]={n="Invoked Golem",lv=7,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z1_FS_2"]={n="Solid Invoked Golem",lv=11,tp="Golem",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z2D_FireExplosive"]={n="Gorgon's Hollow Golem",lv=15,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="R1_POI_GorgonsHollow",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2D_FireExplosive_2"]={n="Gorgon's Hollow Pyrh Golem",lv=15,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="R1_POI_GorgonsHollow",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_E"]={n="Golatea",lv=15,tp="Golem",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z2W_E_2"]={n="Jimmy Crater",lv=18,tp="Golem",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z2W_FireExplosive"]={n="Pyrh Golem",lv=15,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_FireExplosive_2"]={n="Incandescent Pyrh Golem",lv=19,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_FireExplosive_E"]={n="Blaze Rascal",lv=16,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_FireExplosive_E_2"]={n="Grill Arson",lv=20,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_U"]={n="Sparkling Amethyst Golem",lv=15,tp="Golem",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Golem_Z2W_Wind1"]={n="Aoyl Golem",lv=14,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2W_Wind2"]={n="Breezy Aoyl Golem",lv=19,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2_FS"]={n="Invoked Aoyl Golem",lv=16,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2_FS_2"]={n="Invoked Aoyl Golem",lv=20,tp="WindGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfAir",n="Mote of Aoyl",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2_FS_FireExplosive"]={n="Invoked Pyrh Golem",lv=16,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["Golem_Z2_FS_FireExplosive_2"]={n="Incandescent Invoked Pyrh Golem",lv=19,tp="FireGolems",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="CopperOre",n="Copper Ore",c=1},{i="Rock_Z1",n="Cracked Stone",c=0.50},{i="Coal",n="Coal",c=0.50},{i="TinOre",n="Tin Ore",c=0.38},{i="MoteOfFire",n="Mote of Pyrh",c=0.25},{i="TungsteneOre",n="Tungstene Ore",c=0.13}}},
  ["ImpDemon_GreyBlue"]={n="Nightling Shadow",lv=17,tp="Demon",zn="",zname="",dg="R1_POI_AmaymonGoulp",dr={}},
  ["ImpDemon_Red"]={n="Nightling Terror",lv=10,tp="Demon",zn="",zname="",dg="R1_POI_CrimsonSacristy",dr={}},
  ["Kobold_Ratsar_Caster"]={n="Ratsar Lighter",lv=10,tp="Kobold",zn="",zname="",dg="R1_POI_Boss_Ratsar",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1D_Daggers"]={n="Kobold Thief of Estrone",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="R1_POI_Dungeon_AbbandonedMines",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1D_FS_Caster"]={n="Invoked Overseer",lv=10,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1D_Mace"]={n="Kobold Miner of Estrone",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="R1_POI_Dungeon_AbbandonedMines",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Caster"]={n="Kobold Overseer",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Caster_2"]={n="Unpredictable Kobold Overseer",lv=10,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Daggers"]={n="Kobold Thief",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Daggers_2"]={n="Trustworthy Kobold Thief",lv=10,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Mace"]={n="Kobold Miner",lv=6,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Mace_2"]={n="Freelance Kobold Miner",lv=9,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z1W_Mace_U"]={n="Sparkling Miner",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z2D_Caster"]={n="Gorgon's Hollow Overseer",lv=14,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="R1_POI_GorgonsHollow",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z2D_Mace_2"]={n="Gorgon's Hollow Miner",lv=14,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="R1_POI_GorgonsHollow",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z2W_Caster"]={n="Lunatic Kobold Overseer",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z2W_Daggers"]={n="Cleanhanded Kobold Thief",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Kobold_Z2W_Mace"]={n="Senior Kobold Miner",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1D_Caster"]={n="Wavemonger of the Lost City",lv=5,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1D_Claws"]={n="Fighter of the Lost City",lv=5,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1D_FS_Healer"]={n="Invoked Oracle",lv=8,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1D_Spear"]={n="Runner of the Lost City",lv=5,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Caster"]={n="Nepsid Wavemonger",lv=4,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Caster_3"]={n="Educated Nepsid Wavemonger",lv=13,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Claws"]={n="Nepsid Fighter",lv=4,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Claws_2"]={n="Adept Nepsid Fighter",lv=9,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_E_Spear"]={n="Skuttle Goldengill",lv=4,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_FS"]={n="Invoked Wavemonger",lv=8,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Spear"]={n="Nepsid Runner",lv=4,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_Spear_3"]={n="Agile Nepsid Runner",lv=14,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z1W_U_Caster"]={n="Sparkling Wavemonger",lv=4,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2D_Caster"]={n="Wavemonger of New Atlaan",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2D_Healer"]={n="Oracle of New Atlaan",lv=15,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2D_Spear"]={n="Runner of New Atlaan",lv=15,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2D_Tank"]={n="Breakwater of New Atlaan",lv=15,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_Caster"]={n="Erudite Nepsid Wavemonger",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_Claws"]={n="Expert Nepsid Fighter",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_E_Spear_2"]={n="Scummy BlackGill",lv=15,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_FS_Tank"]={n="Confident Invoked Breakwater",lv=17,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_Healer"]={n="Nepsid Oracle",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_Spear"]={n="Acrobatic Nepsid Runner",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Manfish_Z2W_Sword"]={n="Nepsid Breakwater",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Mokshi"]={n="Lady Bee",lv=13,tp="Bee",zn="",zname="",dg="R1_POI_MokshisHivetree",dr={{i="Thrown_Seeds",n="Ipheion, Star Blossom",c=1},{i="Sword_Swarm",n="Beefury, Blessed Blade of the Farseeker",c=1}}},
  ["MunsterChuck"]={n="Munster Chuck",lv=19,tp="Kobold",zn="",zname="",dg="R1_POI_GorgonsHollow",dr={{i="DM_Multispin",n="Twin Pillars of Justice",c=1},{i="Mace_Benediction",n="Amon Ram, the Creator",c=1}}},
  ["Nepsilon"]={n="Nepsilon",lv=5,tp="Manfish",zn="",zname="",dg="R1_POI_Nepsid_Boss",dr={{i="Halos_Totem",n="Ghost Clams of the Low Tide",c=1},{i="DA_Water",n="Iron Fins of the Leviathan",c=1}}},
  ["OgreHuman_Z2W_Peasant"]={n="Crimson Plow Hauler",lv=17,tp="Ogre",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["OgreHuman_Z2W_Peasant_E"]={n="Gruffy",lv=17,tp="Ogre",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["OgreKobold_Z1D_Claws"]={n="Kobold Docker of Estrone",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="R1_POI_Dungeon_AbbandonedMines",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z1D_FS_Claws"]={n="Invoked Docker",lv=11,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z1W_Claws"]={n="Kobold Docker",lv=7,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z1W_Claws_3"]={n="Steady Kobold Docker",lv=9,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z1W_Claws_U"]={n="Sparkling Docker",lv=11,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z1W_E_Claws"]={n="Heraclette",lv=9,tp="Kobold",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z2D_Docker"]={n="Stationmaster",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z2W_Claws"]={n="Reliable Kobold Docker",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreKobold_Z2W_GM"]={n="Kobold Crusher",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z1D_Claws"]={n="Nepsid Whale of the Lost City",lv=5,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="Z1_POI_Dungeon_ManfishAbyss",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z1W_Claws"]={n="Nepsid Whale",lv=5,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z1W_Claws_U"]={n="Sparkling Whale",lv=8,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z1W_FS_Claws"]={n="Slippery Invoked Whale",lv=10,tp="Manfish",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z2D_Claws"]={n="Slick Nepsid Whale",lv=16,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z2W_Claws"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["OgreManfish_Z2W_FS_Claws"]={n="Slick Nepsid Whale",lv=18,tp="Manfish",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["Phrixes"]={n="Phrixes",lv=10,tp="Human",zn="",zname="",dg="R1_POI_CrimsonSacristy",dr={}},
  ["PhrixesP1"]={n="High Inquisitor Chakram",lv=10,tp="Crimson",zn="",zname="",dg="R1_POI_CrimsonSacristy",dr={{i="StaleBread",n="Stale Bread",c=25},{i="Pumpkin",n="Pumpkin",c=20},{i="Cheese_Z2",n="Ramburg Bleu",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Ramgold",n="Ramgold",c=10},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=1}}},
  ["R1KoboldBoss_Sparkling"]={n="Snack of Ratsar",lv=10,tp="Golem",zn="",zname="",dg="R1_POI_Boss_Ratsar",dr={{i="Glider_Dragon_Lava",n="Ebral Dragoon",c=0.10},{i="Glider_FlyingFish_Acid",n="Acidic Wingfish",c=0.10}}},
  ["Ratsar"]={n="King Ratsar",lv=10,tp="Kobold",zn="",zname="",dg="R1_POI_Boss_Ratsar",dr={{i="Daggers_DuplicatePoison",n="Twin Fangs of Ratsar",c=1},{i="GA_Craft",n="Judgement",c=1}}},
  ["Reblochonk"]={n="Reblochonk",lv=8,tp="Kobold",zn="",zname="",dg="R1_POI_Dungeon_AbbandonedMines",dr={{i="Scepter_Flamie",n="Flame of Argol",c=1},{i="Axe_Boomerang",n="Cheese Moon",c=1}}},
  ["Skunk_Z1W"]={n="Skunk",lv=6,tp="Skunk",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="SkunkMeat_Z1",n="Skunk Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Skunk_01",n="Primevallean Skunk",c=0.10}}},
  ["Skunk_Z1W_2"]={n="Unpopular Skunk",lv=10,tp="Skunk",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="SkunkMeat_Z1",n="Skunk Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Skunk_01",n="Primevallean Skunk",c=0.10}}},
  ["Skunk_Z1W_FS"]={n="Invoked Skunk",lv=7,tp="Skunk",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="SkunkMeat_Z1",n="Skunk Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Skunk_01",n="Primevallean Skunk",c=0.10}}},
  ["Skunk_Z1W_FS_2"]={n="Unpopular Invoked Skunk",lv=10,tp="Skunk",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="SkunkMeat_Z1",n="Skunk Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Skunk_01",n="Primevallean Skunk",c=0.10}}},
  ["Skunk_Z1W_U"]={n="Sparkling Skunk",lv=6,tp="Skunk",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="SkunkMeat_Z1",n="Skunk Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Skunk_01",n="Primevallean Skunk",c=0.10}}},
  ["Slime_Z1D_Honey"]={n="Honey Slime of the Hivetree",lv=10,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1D_Honey_NoXP"]={n="Honey Slime of the Hivetree",lv=10,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="R1_POI_MokshisHivetree",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1D_U"]={n="Royal Jelly Slime",lv=11,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W"]={n="Green Slime",lv=2,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_2"]={n="Sap Slime",lv=6,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_4"]={n="Barrel-aged Sap Slime",lv=9,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_E"]={n="Blob Dylan",lv=3,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_E_2"]={n="Jelly Lewis",lv=10,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_FS"]={n="Invoked Slime",lv=6,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_FS_2"]={n="Barrel-aged Invoked Slime",lv=9,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_Honey"]={n="Honey Slime",lv=10,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z1W_U"]={n="Sparkling Slime",lv=2,tp="Slime",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Slime_Z2W_FS"]={n="Ripe Invoked Slime",lv=17,tp="Slime",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["Spirit_Z2W_Claws"]={n="Spirit of Tiocha",lv=15,tp="Spirit",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Spirit_Z2W_Claws2"]={n="Spirit of Night",lv=17,tp="Spirit",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Spirit_Z2W_Claws_E"]={n="da'Lida",lv=18,tp="Spirit",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Spirit_Z2W_Claws_E2"]={n="da'Mascus",lv=17,tp="Spirit",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Spirit_Z2W_FS_Claws"]={n="Invoked Spirit of Tiocha",lv=17,tp="Spirit",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["SpongeBlob"]={n="Sponge Blob",lv=16,tp="Golem",zn="",zname="",dg="",dr={{i="Book_WaterOrbs",n="Book of Mi'Mizan",c=1},{i="Bow_BigGame",n="Horns of the Wind",c=1}}},
  ["Sprout_DarkRice_Z2W"]={n="Black Rice Seedling",lv=17,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Garlic_Z2W"]={n="Garlic Seedling",lv=13,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Garlic_Z2W_2"]={n="Fragrant Garlic Seedling",lv=17,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Onion_Z2W"]={n="Onion Seedling",lv=13,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Onion_Z2W_2"]={n="Controversial  Onion Seedling",lv=17,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Onion_Z2_FS"]={n="Invoked Onion Seedling",lv=15,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W"]={n="Rice Seedling",lv=13,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_E"]={n="Beet the Maul",lv=19,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore"]={n="Seed Barrett",lv=15,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore_2"]={n="Seed Vicious",lv=15,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore_3"]={n="Turnip Arker ",lv=16,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore_4"]={n="Garlic Hooper",lv=18,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore_5"]={n="Charles Cabbage",lv=18,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_Plantivore_6"]={n="Jared Lettuce",lv=18,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2W_U"]={n="Sparkling Rice Seedling",lv=15,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Rice_Z2_FS"]={n="Invoked Rice Seedling",lv=15,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Turnip_Z2W"]={n="Turnip Seedling",lv=13,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Sprout_Turnip_Z2W_2"]={n="Lucrative Turnip Seedling",lv=17,tp="Sprouts",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Swarowl_Bat"]={n="Blackbird Volture",lv=3,tp="Swarowl",zn="",zname="",dg="",dr={}},
  ["TODO_Crocopork_Spark"]={n="Crocoboar",lv=2,tp="Boar",zn="",zname="",dg="",dr={{i="BoarMeat_Z1",n="Boar Meat",c=55},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Fat",n="Fat",c=25},{i="Blood_Z1",n="Fresh Blood",c=20},{i="ChippedTusk",n="Chipped Tusk",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Boar_01",n="Meridional Hog",c=0.10}}},
  ["TODO_FaerieBee"]={n="Invoked Defender",lv=18,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["TODO_FaerieDemon_Blue"]={n="Blackbird Harpy",lv=11,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["TODO_FaerieDemon_Red"]={n="Blackbird Harpy",lv=11,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["TODO_FaerieDemon_Red02"]={n="Blackbird Harpy",lv=11,tp="Bee",zn="",zname="",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["TODO_FaerieSwarowl_Z3W_Claws"]={n="Blackbird Harpy",lv=11,tp="Bee",zn="Z3_Region",zname="Ramburg",dg="",dr={{i="Wing_Z1",n="Diaphanous Wings",c=35},{i="GlossyChitin",n="Glossy Chitin",c=20},{i="Honey_Z1",n="Honey",c=15},{i="RoyalJelly",n="Royal Jelly",c=15},{i="MoteOfNature",n="Mote of Mely",c=0.05},{i="Mount_Ladybug_Blue",n="Zerzurean Leggybug",c=0.10},{i="Mount_Ladybug_Purple",n="Ponogian Leggybug",c=0.10},{i="Mount_Ladybug_Red",n="Nescentine Leggybug",c=0.10}}},
  ["TODO_Kobold_Tank"]={n="Kobold Raider",lv=6,tp="Kobold",zn="",zname="",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_Kobold_Z2W_Tank"]={n="Nervous Kobold Raider",lv=19,tp="Kobold",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={{i="Fang_Z1",n="Small Fang",c=30},{i="StaleBread",n="Stale Bread",c=20},{i="KoboldMetal",n="Piece of Perforated Metal",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cheese_Z1",n="Kobold Swiss",c=12},{i="Cheese_Z2",n="Ramburg Bleu",c=12},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_Beige"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_BlueGrey"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_Brown"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_Brown02"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_DarkBlue"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_Grey"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_OgreBagon_Spark"]={n="Slick Nepsid Whale",lv=17,tp="Manfish",zn="",zname="",dg="",dr={{i="Fin_Z1",n="Sticky Fin",c=35},{i="Mackerel",n="Small Mackerel",c=25},{i="Pike",n="Pike",c=25},{i="NepsidScale",n="Sharp Scale",c=20},{i="Blood_Z1",n="Fresh Blood",c=15},{i="Cloth_Z1",n="Linen Cloth",c=8.80},{i="Pearl",n="Simple Pearl",c=8},{i="WorldLoot",n="WorldLoot",c=5}}},
  ["TODO_Slime_King"]={n="Slime King",lv=1,tp="Slime",zn="",zname="",dg="",dr={{i="Blood_Z1",n="Fresh Blood",c=3.80},{i="Cloth_Z1",n="Linen Cloth",c=2.20},{i="WorldRecipeWithJob",n="WorldRecipeWithJob",c=0.25},{i="ScrollOfStrength",n="Scroll Of Strength I",c=0.04},{i="ScrollOfDexterity",n="Scroll Of Dexterity I",c=0.04},{i="ScrollOfIntelligence",n="Scroll Of Intelligence I",c=0.04},{i="ScrollOfFaith",n="Scroll Of Faith I",c=0.04},{i="ScrollOfVitality",n="Scroll Of Vitality I",c=0.04}}},
  ["TODO_SnowPanther_Black"]={n="Cave Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_DarkBrown"]={n="Cliff Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_Grey"]={n="Rock Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_LightBrown"]={n="Volcano Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_Spark"]={n="Hill Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_White"]={n="Snow Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_SnowPanther_Yellow"]={n="Hill Leopard",lv=5,tp="Wolf",zn="",zname="",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["TODO_Sprout_Garlic_Spark"]={n="Fragrant Garlic Seedling",lv=17,tp="Sprouts",zn="",zname="",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["TODO_Sprout_Onion_Spark"]={n="Controversial  Onion Seedling",lv=17,tp="Sprouts",zn="",zname="",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["TODO_Sprout_Turnip_Spark"]={n="Lucrative Turnip Seedling",lv=17,tp="Sprouts",zn="",zname="",dg="",dr={{i="SweetRoot",n="Sweet Root",c=40},{i="Wheat",n="Wheat",c=25},{i="MoteOfNature",n="Mote of Mely",c=0.10},{i="Glider_Sprout_Green",n="Eksodean Seedbird",c=0.10}}},
  ["Ulserous"]={n="ul'Serous, Herald Avatar",lv=13,tp="Human",zn="",zname="",dg="R1_POI_AmaymonGoulp",dr={}},
  ["Wolf_Z1W"]={n="Wolf",lv=11,tp="Wolf",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["Wolf_Z1W_Alpha"]={n="Alpha Wolf",lv=11,tp="Wolf",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["Wolf_Z1W_E"]={n="Fangandog",lv=12,tp="Wolf",zn="Z1_Region",zname="Skover Island",dg="",dr={{i="WolfMeat_Z1",n="Wolf Meat",c=55},{i="Fang_Z1",n="Small Fang",c=35},{i="Leather_Z1",n="Light Leather Strap",c=28},{i="Blood_Z1",n="Fresh Blood",c=20},{i="SoftFur",n="Soft Fur",c=5.30},{i="Mount_Wolf_02",n="Nescentine Wolf",c=0.10}}},
  ["Wolf_Z2W"]={n="Coyote",lv=13,tp="Coyote",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Wolf_Z2W_2"]={n="Starving Coyote",lv=17,tp="Coyote",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
  ["Wolf_Z2W_U"]={n="Sparkling Coyote",lv=19,tp="Coyote",zn="Z2_Region",zname="Valley of Eternal Autumn",dg="",dr={}},
}

local DB_crafts = {
  ["AlchemistEssence_Z1"]={o="AlchemistEssence_Z1",j="Blacksmith",lv=3,inp={{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="ZealotusPetal",n="Zealotus Petal",q=1},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["Alloy_Z1"]={o="Alloy_Z1",j="Blacksmith",lv=4,inp={{i="BronzeIngot",n="Bronze Ingot",q=1},{i="Stone_Ore_Z1",n="Glittering Stone",q=3},{i="TungsteneIngot",n="Tungstene Ingot",q=1}}},
  ["AttunedCutBeryl"]={o="AttunedCutBeryl",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutBeryl",n="Cut Beryl",q=1}}},
  ["AttunedCutRuby"]={o="AttunedCutRuby",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutRuby",n="Cut Ruby",q=1}}},
  ["Back_RBee_FigWiz_Craft"]={o="Back_RBee_FigWiz_Craft",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=100},{i="CopperIngot",n="Copper Ingot",q=12},{i="SoftFur",n="Soft Fur",q=3},{i="Wing_Z1",n="Diaphanous Wings",q=20},{i="FragmentOfNature",n="Fragment of Mely",q=2}}},
  ["Back_RCrimson_AssCle_Craft"]={o="Back_RCrimson_AssCle_Craft",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=150},{i="TannedLeather",n="Tanned Light Leather",q=15},{i="SoftFur",n="Soft Fur",q=4},{i="Ramgold",n="Ramgold",q=4}}},
  ["Bag_Z2"]={o="Bag_Z2",j="Blacksmith",lv=3,inp={{i="LinenBolt",n="Bolt of Linen Cloth",q=5},{i="TannedLeather",n="Tanned Light Leather",q=5},{i="SoftFur",n="Soft Fur",q=3}}},
  ["BrightVoidOrb"]={o="BrightVoidOrb",j="Blacksmith",lv=5,inp={{i="Particle_Z1",n="Bright Void Particles",q=20},{i="SpiritHeart_Z2",n="Ephemeral Heart",q=10}}},
  ["BronzeIngot"]={o="BronzeIngot",j="Blacksmith",lv=3,inp={{i="TinOre",n="Tin Ore",q=5},{i="CopperIngot",n="Copper Ingot",q=1},{i="SparkSample",n="Spark Sample",q=1}}},
  ["Chest_RBee_AssWiz_Craft"]={o="Chest_RBee_AssWiz_Craft",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="TannedLeather",n="Tanned Light Leather",q=15},{i="GlossyChitin",n="Glossy Chitin",q=12},{i="SoftFur",n="Soft Fur",q=5},{i="FragmentOfNature",n="Fragment of Mely",q=2}}},
  ["Chest_RCrimson_Fig_Craft"]={o="Chest_RCrimson_Fig_Craft",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=150},{i="BronzeIngot",n="Bronze Ingot",q=18},{i="Ramgold",n="Ramgold",q=8}}},
  ["Chest_RCrimson_WizCle_Craft"]={o="Chest_RCrimson_WizCle_Craft",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=150},{i="Cloth_Z1",n="Linen Cloth",q=20},{i="SoftFur",n="Soft Fur",q=6},{i="Ramgold",n="Ramgold",q=8}}},
  ["Chest_RKobold_FigAss"]={o="Chest_RKobold_FigAss",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperIngot",n="Copper Ingot",q=10},{i="Fang_Z1",n="Small Fang",q=20},{i="FragmentOfEarth",n="Fragment of Kyre",q=1}}},
  ["Cook_1"]={o="Cook_1",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="BoarMeat_Z1",n="Boar Meat",q=6},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["Cook_10"]={o="Cook_10",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=30},{i="SweetRoot",n="Sweet Root",q=6},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_11"]={o="Cook_11",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=30},{i="StaleBread",n="Stale Bread",q=3},{i="Fat",n="Fat",q=3},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["Cook_12"]={o="Cook_12",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=30},{i="Wheat",n="Wheat",q=3},{i="Pumpkin",n="Pumpkin",q=3},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_13"]={o="Cook_13",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=30},{i="RoyalJelly",n="Royal Jelly",q=6},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_14"]={o="Cook_14",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=30},{i="Cheese_Z2",n="Ramburg Bleu",q=6},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["Cook_15"]={o="Cook_15",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=30},{i="Pike",n="Pike",q=6},{i="FishermanSauce",n="Fisherman's Sauce",q=1}}},
  ["Cook_16"]={o="Cook_16",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=30},{i="CrabEgg",n="Crab Egg",q=6},{i="FishermanSauce",n="Fisherman's Sauce",q=1}}},
  ["Cook_2"]={o="Cook_2",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="WolfMeat_Z1",n="Wolf Meat",q=6},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["Cook_3"]={o="Cook_3",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=15},{i="CrabMeat_Z1",n="Fleshy Claw",q=6},{i="FishermanSauce",n="Fisherman's Sauce",q=1}}},
  ["Cook_4"]={o="Cook_4",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="Cheese_Z1",n="Kobold Swiss",q=6},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_5"]={o="Cook_5",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="Mackerel",n="Small Mackerel",q=6},{i="FishermanSauce",n="Fisherman's Sauce",q=1}}},
  ["Cook_6"]={o="Cook_6",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=15},{i="SkunkMeat_Z1",n="Skunk Meat",q=6},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["Cook_7"]={o="Cook_7",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="Honey_Z1",n="Honey",q=6},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_8"]={o="Cook_8",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=15},{i="MadrigoldPetal",n="Madrigold Petal",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=2},{i="SkoverDriedHerbs",n="Mixed Herbs",q=1}}},
  ["Cook_9"]={o="Cook_9",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=30},{i="CoyoteMeat",n="Coyote Meat",q=6},{i="HunterSauce",n="Hunter's Sauce",q=1}}},
  ["CopperIngot"]={o="CopperIngot",j="Blacksmith",lv=1,inp={{i="CopperOre",n="Copper Ore",q=5},{i="SparkSample",n="Spark Sample",q=1}}},
  ["CopperProspecting"]={o="CopperProspecting",j="Blacksmith",lv=1,inp={{i="CopperOre",n="Copper Ore",q=10},{i="SparkSample",n="Spark Sample",q=1}}},
  ["CopperSetting"]={o="CopperSetting",j="Blacksmith",lv=1,inp={{i="CopperOre",n="Copper Ore",q=10}}},
  ["CutAgate"]={o="CutAgate",j="Blacksmith",lv=4,inp={{i="Agate",n="Agate",q=1},{i="CutStone",n="Cracked Cut Stone",q=3}}},
  ["CutAmber"]={o="CutAmber",j="Blacksmith",lv=2,inp={{i="Amber",n="Amber",q=1},{i="CutStone",n="Cracked Cut Stone",q=3}}},
  ["CutBeryl"]={o="CutBeryl",j="Blacksmith",lv=2,inp={{i="Beryl",n="Beryl",q=1},{i="CutStone",n="Cracked Cut Stone",q=3}}},
  ["CutMalachite"]={o="CutMalachite",j="Blacksmith",lv=3,inp={{i="Malachite",n="Malachite",q=1},{i="CutStone",n="Cracked Cut Stone",q=3}}},
  ["CutRuby"]={o="CutRuby",j="Blacksmith",lv=4,inp={{i="Ruby",n="Ruby",q=1},{i="CutStone",n="Cracked Cut Stone",q=3}}},
  ["CutStone"]={o="CutStone",j="Blacksmith",lv=2,inp={{i="Rock_Z1",n="Cracked Stone",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["DivinedCopperPlate"]={o="DivinedCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["DivinedEmbroidery"]={o="DivinedEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["ElixirOfAbundance"]={o="ElixirOfAbundance",j="Blacksmith",lv=2,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=2},{i="Leather_Z1",n="Light Leather Strap",q=2},{i="CopperOre",n="Copper Ore",q=2}}},
  ["ElixirOfArmor_Z2"]={o="ElixirOfArmor_Z2",j="Blacksmith",lv=5,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=1},{i="StrangeSpores",n="Strange Spores",q=2}}},
  ["ElixirOfDexterity_Z2"]={o="ElixirOfDexterity_Z2",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="GlossyChitin",n="Glossy Chitin",q=2},{i="StrangeSpores",n="Strange Spores",q=2}}},
  ["ElixirOfFaith_Z2"]={o="ElixirOfFaith_Z2",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="SpiritHeart_Z2",n="Ephemeral Heart",q=2},{i="StrangeSpores",n="Strange Spores",q=2}}},
  ["ElixirOfIntelligence_Z2"]={o="ElixirOfIntelligence_Z2",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="NepsidScale",n="Sharp Scale",q=2},{i="StrangeSpores",n="Strange Spores",q=2}}},
  ["ElixirOfMinorDexterity"]={o="ElixirOfMinorDexterity",j="Blacksmith",lv=1,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=3},{i="Wing_Z1",n="Diaphanous Wings",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["ElixirOfMinorFaith"]={o="ElixirOfMinorFaith",j="Blacksmith",lv=1,inp={{i="Vial",n="Vial",q=1},{i="LavendulaPetal",n="Lavendula Petal",q=3},{i="Eye_Z1",n="Eyestalk",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["ElixirOfMinorIntelligence"]={o="ElixirOfMinorIntelligence",j="Blacksmith",lv=1,inp={{i="Vial",n="Vial",q=1},{i="LavendulaPetal",n="Lavendula Petal",q=3},{i="Fin_Z1",n="Sticky Fin",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["ElixirOfMinorStrength"]={o="ElixirOfMinorStrength",j="Blacksmith",lv=1,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=3},{i="Fang_Z1",n="Small Fang",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["ElixirOfStrength_Z2"]={o="ElixirOfStrength_Z2",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="Fang_Z1",n="Small Fang",q=3},{i="StrangeSpores",n="Strange Spores",q=2}}},
  ["ElixirofMinorArmor"]={o="ElixirofMinorArmor",j="Blacksmith",lv=2,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=2},{i="Rock_Z1",n="Cracked Stone",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["EnchantConcentrate_Z1"]={o="EnchantConcentrate_Z1",j="Blacksmith",lv=5,inp={{i="EnchantPowder_Z1",n="Purified Bright Powder",q=1},{i="Fragments_Z1",n="Bright Fragments",q=5},{i="SparkSample",n="Spark Sample",q=1}}},
  ["EnchantPaper_Z1"]={o="EnchantPaper_Z1",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="Fragments_Z1",n="Bright Fragments",q=3}}},
  ["EnchantPowder_Z1"]={o="EnchantPowder_Z1",j="Blacksmith",lv=1,inp={{i="Residues_Z1",n="Bright Residues",q=5},{i="SparkSample",n="Spark Sample",q=1}}},
  ["FastSwimPotion"]={o="FastSwimPotion",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="NepsidScale",n="Sharp Scale",q=1},{i="Fin_Z1",n="Sticky Fin",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["Feast"]={o="Feast",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=30},{i="SilverTray",n="Silver Tray",q=1},{i="Cook_9",n="Smoked Coyote",q=1},{i="Cook_10",n="Skover Root Soup",q=1},{i="Cook_11",n="Beggar's Garbure",q=1}}},
  ["Feet_RBee_WizCle_Craft"]={o="Feet_RBee_WizCle_Craft",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="Cloth_Z1",n="Linen Cloth",q=12},{i="SoftFur",n="Soft Fur",q=3},{i="GlossyChitin",n="Glossy Chitin",q=10},{i="FragmentOfNature",n="Fragment of Mely",q=2}}},
  ["Feet_RCrimson_FigCle"]={o="Feet_RCrimson_FigCle",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=150},{i="BronzeIngot",n="Bronze Ingot",q=12},{i="Ramgold",n="Ramgold",q=5}}},
  ["Feet_RKobold_FigCle_Craft"]={o="Feet_RKobold_FigCle_Craft",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="BronzeIngot",n="Bronze Ingot",q=8},{i="Fang_Z1",n="Small Fang",q=15},{i="KoboldMetal",n="Piece of Perforated Metal",q=5},{i="FragmentOfEarth",n="Fragment of Kyre",q=2}}},
  ["Feet_RManfish_AssWiz_Craft"]={o="Feet_RManfish_AssWiz_Craft",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="TannedLeather",n="Tanned Light Leather",q=8},{i="Fin_Z1",n="Sticky Fin",q=15},{i="FragmentOfWater",n="Fragment of Naya",q=1}}},
  ["Finger_Z1RCraft_Ap"]={o="Finger_Z1RCraft_Ap",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="Amber",n="Amber",q=3}}},
  ["Finger_Z1RCraft_Cri"]={o="Finger_Z1RCraft_Cri",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="Amber",n="Amber",q=3}}},
  ["Finger_Z1RCraft_Fer"]={o="Finger_Z1RCraft_Fer",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="Beryl",n="Beryl",q=3}}},
  ["Finger_Z1RCraft_Mp"]={o="Finger_Z1RCraft_Mp",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="Beryl",n="Beryl",q=3}}},
  ["Finger_Z2RCraft_CriAP"]={o="Finger_Z2RCraft_CriAP",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=3},{i="Agate",n="Agate",q=3}}},
  ["Finger_Z2RCraft_FerMP"]={o="Finger_Z2RCraft_FerMP",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="CopperSetting",n="Copper Setting",q=2},{i="Stone_Ore_Z1",n="Glittering Stone",q=3},{i="Ruby",n="Ruby",q=3}}},
  ["FishermanSauce"]={o="FishermanSauce",j="Blacksmith",lv=1,inp={{i="Blood_Z1",n="Fresh Blood",q=5},{i="CrabMeat_Z1",n="Fleshy Claw",q=1},{i="SparkSample",n="Spark Sample",q=1}}},
  ["FormulaFeetArmorPen_Z2"]={o="FormulaFeetArmorPen_Z2",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=8},{i="Particle_Z1",n="Bright Void Particles",q=5},{i="FragmentOfEarth",n="Fragment of Kyre",q=2}}},
  ["FormulaFeetArmor_Z2"]={o="FormulaFeetArmor_Z2",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=8},{i="Particle_Z1",n="Bright Void Particles",q=5},{i="Coal",n="Coal",q=5}}},
  ["FormulaFeetCritical_Z2"]={o="FormulaFeetCritical_Z2",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=8},{i="Particle_Z1",n="Bright Void Particles",q=5},{i="FragmentOfEarth",n="Fragment of Kyre",q=2}}},
  ["FormulaFeetFervor_Z2"]={o="FormulaFeetFervor_Z2",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=8},{i="Particle_Z1",n="Bright Void Particles",q=5},{i="FragmentOfWater",n="Fragment of Naya",q=2}}},
  ["FormulaFeetMagicPen_Z2"]={o="FormulaFeetMagicPen_Z2",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=8},{i="Particle_Z1",n="Bright Void Particles",q=5},{i="FragmentOfWater",n="Fragment of Naya",q=2}}},
  ["FormulaFeetMinorArmor"]={o="FormulaFeetMinorArmor",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=4},{i="Stone_Ore_Z1",n="Glittering Stone",q=3}}},
  ["FormulaFeetMinorArmorPen"]={o="FormulaFeetMinorArmorPen",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=4},{i="FragmentOfEarth",n="Fragment of Kyre",q=1}}},
  ["FormulaFeetMinorCritical"]={o="FormulaFeetMinorCritical",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=4},{i="FragmentOfEarth",n="Fragment of Kyre",q=1}}},
  ["FormulaFeetMinorFervor"]={o="FormulaFeetMinorFervor",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=4},{i="FragmentOfWater",n="Fragment of Naya",q=1}}},
  ["FormulaFeetMinorMagicPen"]={o="FormulaFeetMinorMagicPen",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="Residues_Z1",n="Bright Residues",q=4},{i="FragmentOfWater",n="Fragment of Naya",q=1}}},
  ["FormulaHandsDexterity_Z2"]={o="FormulaHandsDexterity_Z2",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=10},{i="Particle_Z1",n="Bright Void Particles",q=8},{i="GlossyChitin",n="Glossy Chitin",q=5}}},
  ["FormulaHandsFaith_Z2"]={o="FormulaHandsFaith_Z2",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=10},{i="Particle_Z1",n="Bright Void Particles",q=8},{i="Ramgold",n="Ramgold",q=1}}},
  ["FormulaHandsIntelligence_Z2"]={o="FormulaHandsIntelligence_Z2",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=10},{i="Particle_Z1",n="Bright Void Particles",q=8},{i="NepsidScale",n="Sharp Scale",q=5}}},
  ["FormulaHandsMinorDexterity"]={o="FormulaHandsMinorDexterity",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=6},{i="Wing_Z1",n="Diaphanous Wings",q=5}}},
  ["FormulaHandsMinorFaith"]={o="FormulaHandsMinorFaith",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=6},{i="Eye_Z1",n="Eyestalk",q=5}}},
  ["FormulaHandsMinorIntelligence"]={o="FormulaHandsMinorIntelligence",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=6},{i="Fin_Z1",n="Sticky Fin",q=5}}},
  ["FormulaHandsMinorStrength"]={o="FormulaHandsMinorStrength",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=6},{i="Fang_Z1",n="Small Fang",q=5}}},
  ["FormulaHandsMinorVitality"]={o="FormulaHandsMinorVitality",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=30},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=6},{i="Blood_Z1",n="Fresh Blood",q=5}}},
  ["FormulaHandsStrength_Z2"]={o="FormulaHandsStrength_Z2",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=10},{i="Particle_Z1",n="Bright Void Particles",q=8},{i="KoboldMetal",n="Piece of Perforated Metal",q=5}}},
  ["FormulaHandsVitality_Z2"]={o="FormulaHandsVitality_Z2",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=10},{i="Particle_Z1",n="Bright Void Particles",q=8},{i="Blood_Z1",n="Fresh Blood",q=5}}},
  ["FormulaWeaponDevote"]={o="FormulaWeaponDevote",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=100},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantConcentrate_Z1",n="Bright Spark Concentrate",q=10},{i="BrightVoidOrb",n="Bright Void Orb",q=1},{i="Ramgold",n="Ramgold",q=5}}},
  ["FormulaWeaponFlamingWeapon"]={o="FormulaWeaponFlamingWeapon",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=100},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantConcentrate_Z1",n="Bright Spark Concentrate",q=10},{i="BrightVoidOrb",n="Bright Void Orb",q=1},{i="FragmentOfFire",n="Fragment of Pyrh",q=3}}},
  ["FormulaWeaponSparkHarvesting"]={o="FormulaWeaponSparkHarvesting",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=100},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantConcentrate_Z1",n="Bright Spark Concentrate",q=10},{i="BrightVoidOrb",n="Bright Void Orb",q=1},{i="FragmentOfNature",n="Fragment of Mely",q=3}}},
  ["FormulaWeaponZealot"]={o="FormulaWeaponZealot",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=100},{i="EnchantPaper_Z1",n="Bright Enchanted Paper",q=1},{i="EnchantConcentrate_Z1",n="Bright Spark Concentrate",q=10},{i="BrightVoidOrb",n="Bright Void Orb",q=1},{i="Ramgold",n="Ramgold",q=5}}},
  ["FreshFlowerPowder"]={o="FreshFlowerPowder",j="Blacksmith",lv=3,inp={{i="MadrigoldPetal",n="Madrigold Petal",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=2},{i="AncientThymePetal",n="Ancient Thyme Petal",q=2},{i="SparkSample",n="Spark Sample",q=1}}},
  ["GildedCutBeryl"]={o="GildedCutBeryl",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutBeryl",n="Cut Beryl",q=1}}},
  ["GildedCutRuby"]={o="GildedCutRuby",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutRuby",n="Cut Ruby",q=1}}},
  ["GracefulCopperPlate"]={o="GracefulCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["GracefulEmbroidery"]={o="GracefulEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["Hands_RKobold_Cle_Craft"]={o="Hands_RKobold_Cle_Craft",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="LinenBolt",n="Bolt of Linen Cloth",q=8},{i="Fang_Z1",n="Small Fang",q=15},{i="FragmentOfEarth",n="Fragment of Kyre",q=1}}},
  ["Hands_RManfish_FigAss_Craft"]={o="Hands_RManfish_FigAss_Craft",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=100},{i="CopperIngot",n="Copper Ingot",q=15},{i="Fin_Z1",n="Sticky Fin",q=20},{i="FragmentOfWater",n="Fragment of Naya",q=1},{i="Pearl",n="Simple Pearl",q=1}}},
  ["HideboundWeave"]={o="HideboundWeave",j="Blacksmith",lv=4,inp={{i="SoftFur",n="Soft Fur",q=2},{i="TannedLeather",n="Tanned Light Leather",q=1},{i="LinenBolt",n="Bolt of Linen Cloth",q=1}}},
  ["HonedCopperPlate"]={o="HonedCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["HonedEmbroidery"]={o="HonedEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["HunterSauce"]={o="HunterSauce",j="Blacksmith",lv=1,inp={{i="Blood_Z1",n="Fresh Blood",q=5},{i="Fang_Z1",n="Small Fang",q=1},{i="SparkSample",n="Spark Sample",q=1}}},
  ["InfusedTusk"]={o="InfusedTusk",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="ChippedTusk",n="Chipped Tusk",q=1},{i="AlchemistEssence_Z1",n="Fresh Essence",q=5},{i="Ramgold",n="Ramgold",q=5},{i="PrismaticFragment",n="Prismatic Fragment",q=1}}},
  ["InvisibilityPotion"]={o="InvisibilityPotion",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="FragmentOfNature",n="Fragment of Mely",q=1},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["LinenBag"]={o="LinenBag",j="Blacksmith",lv=1,inp={{i="LinenBolt",n="Bolt of Linen Cloth",q=3},{i="TannedLeather",n="Tanned Light Leather",q=3}}},
  ["LinenBolt"]={o="LinenBolt",j="Blacksmith",lv=1,inp={{i="Cloth_Z1",n="Linen Cloth",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["LongBreathPotion"]={o="LongBreathPotion",j="Blacksmith",lv=2,inp={{i="Vial",n="Vial",q=1},{i="LavendulaPetal",n="Lavendula Petal",q=3},{i="Fin_Z1",n="Sticky Fin",q=6},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["MinorHealingPotion"]={o="MinorHealingPotion",j="Blacksmith",lv=1,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=1},{i="LavendulaPetal",n="Lavendula Petal",q=1},{i="Blood_Z1",n="Fresh Blood",q=3},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["MinorShieldPotion"]={o="MinorShieldPotion",j="Blacksmith",lv=2,inp={{i="Vial",n="Vial",q=1},{i="MadrigoldPetal",n="Madrigold Petal",q=1},{i="Stone_Ore_Z1",n="Glittering Stone",q=2},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["MinorVelocityPotion"]={o="MinorVelocityPotion",j="Blacksmith",lv=4,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="FragmentOfAir",n="Fragment of Aoyl",q=1},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["MoteOfAir"]={o="MoteOfAir",j="Blacksmith",lv=3,inp={{i="GlossyChitin",n="Glossy Chitin",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["MoteOfEarth"]={o="MoteOfEarth",j="Blacksmith",lv=1,inp={{i="Rock_Z1",n="Cracked Stone",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["MoteOfFire"]={o="MoteOfFire",j="Blacksmith",lv=3,inp={{i="Coal",n="Coal",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["MoteOfNature"]={o="MoteOfNature",j="Blacksmith",lv=1,inp={{i="Blood_Z1",n="Fresh Blood",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["MoteOfWater"]={o="MoteOfWater",j="Blacksmith",lv=1,inp={{i="Fin_Z1",n="Sticky Fin",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["MysticCopperPlate"]={o="MysticCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["MysticEmbroidery"]={o="MysticEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["Necklace_Z1RCraft"]={o="Necklace_Z1RCraft",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=100},{i="CopperSetting",n="Copper Setting",q=4},{i="Stone_Ore_Z1",n="Glittering Stone",q=3},{i="Pearl",n="Simple Pearl",q=1}}},
  ["Necklace_Z2RCraft"]={o="Necklace_Z2RCraft",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=150},{i="CopperSetting",n="Copper Setting",q=4},{i="Ramgold",n="Ramgold",q=5},{i="Amber",n="Amber",q=1},{i="Beryl",n="Beryl",q=1}}},
  ["PhilosopherStone"]={o="PhilosopherStone",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=100},{i="TungsteneOre",n="Tungstene Ore",q=5},{i="Pearl",n="Simple Pearl",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=1},{i="FragmentOfNature",n="Fragment of Mely",q=1}}},
  ["PrismaticFragment"]={o="PrismaticFragment",j="Blacksmith",lv=3,inp={{i="FragmentOfFire",n="Fragment of Pyrh",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=1},{i="FragmentOfNature",n="Fragment of Mely",q=1},{i="FragmentOfAir",n="Fragment of Aoyl",q=1},{i="FragmentOfWater",n="Fragment of Naya",q=1}}},
  ["PrismaticPearl"]={o="PrismaticPearl",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=150},{i="Pearl",n="Simple Pearl",q=1},{i="AlchemistEssence_Z1",n="Fresh Essence",q=5},{i="Ramgold",n="Ramgold",q=5},{i="PrismaticFragment",n="Prismatic Fragment",q=1}}},
  ["PurifiedHeart"]={o="PurifiedHeart",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=150},{i="SpiritHeart_Z2",n="Ephemeral Heart",q=5},{i="AlchemistEssence_Z1",n="Fresh Essence",q=5},{i="Ramgold",n="Ramgold",q=5},{i="PrismaticFragment",n="Prismatic Fragment",q=1}}},
  ["ReinforcedCopperPlate"]={o="ReinforcedCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["ReinforcedEmbroidery"]={o="ReinforcedEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["ResonantCutAgate"]={o="ResonantCutAgate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAgate",n="Cut Agate",q=1}}},
  ["ResonantCutAmber"]={o="ResonantCutAmber",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAmber",n="Cut Amber",q=1}}},
  ["RunedCopperPlate"]={o="RunedCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["RunedEmbroidery"]={o="RunedEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["SanctifiedCopperPlate"]={o="SanctifiedCopperPlate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="Alloy_Z1",n="Glittering Alloy",q=3}}},
  ["SanctifiedEmbroidery"]={o="SanctifiedEmbroidery",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="HideboundWeave",n="Soft Weave",q=3}}},
  ["ScrollOfDexterity"]={o="ScrollOfDexterity",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=2},{i="Wing_Z1",n="Diaphanous Wings",q=3}}},
  ["ScrollOfFaith"]={o="ScrollOfFaith",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=2},{i="Eye_Z1",n="Eyestalk",q=3}}},
  ["ScrollOfIntelligence"]={o="ScrollOfIntelligence",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=2},{i="Fin_Z1",n="Sticky Fin",q=3}}},
  ["ScrollOfStrength"]={o="ScrollOfStrength",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=2},{i="Fang_Z1",n="Small Fang",q=3}}},
  ["ScrollOfVitality"]={o="ScrollOfVitality",j="Blacksmith",lv=1,inp={{i="Paper_Z1",n="Blank Page",q=1},{i="EnchantPowder_Z1",n="Purified Bright Powder",q=2},{i="Blood_Z1",n="Fresh Blood",q=3}}},
  ["ShieldPotion_Z2"]={o="ShieldPotion_Z2",j="Blacksmith",lv=5,inp={{i="Vial",n="Vial",q=1},{i="FreshFlowerPowder",n="Fresh Flower Powder",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=1},{i="StrangeSpores",n="Strange Spores",q=1}}},
  ["SkoverDriedHerbs"]={o="SkoverDriedHerbs",j="Blacksmith",lv=2,inp={{i="MadrigoldPetal",n="Madrigold Petal",q=3},{i="LavendulaPetal",n="Lavendula Petal",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["SmallAlchemistCauldron"]={o="SmallAlchemistCauldron",j="Blacksmith",lv=5,inp={{i="CraftPoint",n="Craft point",q=50},{i="SimpleCauldron",n="Simple Cauldron",q=1},{i="ElixirOfStrength_Z2",n="Elixir of Strength",q=1},{i="ElixirOfDexterity_Z2",n="Elixir of Dexterity",q=1},{i="ElixirOfIntelligence_Z2",n="Elixir of Intelligence",q=1}}},
  ["StoneOfCunning"]={o="StoneOfCunning",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="FragmentOfNature",n="Fragment of Mely",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=15}}},
  ["StoneOfPower"]={o="StoneOfPower",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=2},{i="MadrigoldPetal",n="Madrigold Petal",q=15}}},
  ["StoneOfRighteousness"]={o="StoneOfRighteousness",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="FragmentOfEarth",n="Fragment of Kyre",q=2},{i="LavendulaPetal",n="Lavendula Petal",q=10}}},
  ["StoneOfWisdom"]={o="StoneOfWisdom",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="FragmentOfWater",n="Fragment of Naya",q=2},{i="MadrigoldPetal",n="Madrigold Petal",q=15}}},
  ["StrongCutAgate"]={o="StrongCutAgate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAgate",n="Cut Agate",q=1}}},
  ["StrongCutAmber"]={o="StrongCutAmber",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAmber",n="Cut Amber",q=1}}},
  ["SunderedCutAgate"]={o="SunderedCutAgate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAgate",n="Cut Agate",q=1}}},
  ["SunderedCutAmber"]={o="SunderedCutAmber",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAmber",n="Cut Amber",q=1}}},
  ["SurgingCutAgate"]={o="SurgingCutAgate",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAgate",n="Cut Agate",q=1}}},
  ["SurgingCutAmber"]={o="SurgingCutAmber",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutAmber",n="Cut Amber",q=1}}},
  ["TannedLeather"]={o="TannedLeather",j="Blacksmith",lv=1,inp={{i="Leather_Z1",n="Light Leather Strap",q=3},{i="SparkSample",n="Spark Sample",q=1}}},
  ["TemperedCutBeryl"]={o="TemperedCutBeryl",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutBeryl",n="Cut Beryl",q=1}}},
  ["TemperedCutRuby"]={o="TemperedCutRuby",j="Blacksmith",lv=4,inp={{i="CraftPoint",n="Craft point",q=50},{i="CutRuby",n="Cut Ruby",q=1}}},
  ["TinProspecting"]={o="TinProspecting",j="Blacksmith",lv=3,inp={{i="TinOre",n="Tin Ore",q=10},{i="SparkSample",n="Spark Sample",q=1}}},
  ["TungsteneIngot"]={o="TungsteneIngot",j="Blacksmith",lv=2,inp={{i="TungsteneOre",n="Tungstene Ore",q=5},{i="SparkSample",n="Spark Sample",q=1}}},
  ["TungsteneProspecting"]={o="TungsteneProspecting",j="Blacksmith",lv=1,inp={{i="TungsteneOre",n="Tungstene Ore",q=10},{i="SparkSample",n="Spark Sample",q=1}}},
  ["Waist_RBee_FigWiz"]={o="Waist_RBee_FigWiz",j="Blacksmith",lv=3,inp={{i="CraftPoint",n="Craft point",q=125},{i="BronzeIngot",n="Bronze Ingot",q=8},{i="Wing_Z1",n="Diaphanous Wings",q=15},{i="GlossyChitin",n="Glossy Chitin",q=5},{i="FragmentOfNature",n="Fragment of Mely",q=2}}},
  ["Waist_RKobold_AssCle_Craft"]={o="Waist_RKobold_AssCle_Craft",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=100},{i="TannedLeather",n="Tanned Light Leather",q=12},{i="SoftFur",n="Soft Fur",q=2},{i="Fang_Z1",n="Small Fang",q=10},{i="FragmentOfEarth",n="Fragment of Kyre",q=2}}},
  ["Waist_RManfish_Fig"]={o="Waist_RManfish_Fig",j="Blacksmith",lv=1,inp={{i="CraftPoint",n="Craft point",q=75},{i="CopperIngot",n="Copper Ingot",q=8},{i="Fin_Z1",n="Sticky Fin",q=15},{i="FragmentOfWater",n="Fragment of Naya",q=1}}},
  ["Waist_RManfish_Wiz_Craft"]={o="Waist_RManfish_Wiz_Craft",j="Blacksmith",lv=2,inp={{i="CraftPoint",n="Craft point",q=100},{i="LinenBolt",n="Bolt of Linen Cloth",q=12},{i="Fin_Z1",n="Sticky Fin",q=20},{i="FragmentOfWater",n="Fragment of Naya",q=2}}},
  ["Weightstone"]={o="Weightstone",j="Blacksmith",lv=1,inp={{i="Rock_Z1",n="Cracked Stone",q=5},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="SparkSample",n="Spark Sample",q=1}}},
  ["Whetstone"]={o="Whetstone",j="Blacksmith",lv=1,inp={{i="Rock_Z1",n="Cracked Stone",q=5},{i="Stone_Ore_Z1",n="Glittering Stone",q=1},{i="SparkSample",n="Spark Sample",q=1}}},
}
-- ════════════════════════════════════════════════════════════════
--  LOGIC  (assembled after the embedded FareverDB tables above)
-- ════════════════════════════════════════════════════════════════

local PLUGIN_VERSION = "2.0.0"

-- ── layout ────────────────────────────────────────────────────────
local PANEL_W    = 300
local RING_BOX   = 150
local DB_KEY     = "boss_threat_db"
local SAVE_EVERY = 4.0
local DANGER_HI  = 0.12
local DANGER_MD  = 0.04

-- ── tabs (3 per row in the bar) ───────────────────────────────────
local TABS = { "Boss", "Vitals", "Drops", "Craft", "Gear" }
local tab  = 1

-- ── boss-coach runtime ────────────────────────────────────────────
local threat_db   = {}
local active_cast = nil
local last_save   = -1e9
local db_dirty    = false

-- ── vitals runtime ────────────────────────────────────────────────
local observed_max = {}

-- ── armory runtime ────────────────────────────────────────────────
local idx_built     = false
local dropped_by    = {}   -- item id -> { {unit,n,lv,zn,c}, ... }
local items_by_slot = {}   -- slot   -> { {id,it}, ... } rarity-sorted
local craft_query   = ""
local craft_sel     = nil  -- selected craft output id

-- ── rarity ────────────────────────────────────────────────────────
local RARITY_RANK = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6 }
local RARITY_RGB  = {
    Common    = { 0.78, 0.78, 0.78 },
    Uncommon  = { 0.45, 0.90, 0.45 },
    Rare      = { 0.40, 0.65, 1.00 },
    Epic      = { 0.80, 0.45, 1.00 },
    Legendary = { 1.00, 0.65, 0.20 },
    Mythic    = { 1.00, 0.40, 0.50 },
}
local function rrank(r) return RARITY_RANK[r or ""] or 0 end
local function rrgb(r)
    local c = RARITY_RGB[r or ""]
    if c then return c[1], c[2], c[3] end
    return 0.7, 0.7, 0.7
end

-- ── gear slots we treat as "equipment" ────────────────────────────
local GEAR_SLOTS = {
    Head=1, Shoulders=1, Chest=1, Hands=1, Waist=1, Legs=1, Feet=1, Back=1,
    GearNeck=1, GearFinger=1, GearTrinket=1, Shield=1,
    Sword=1, GreatSword=1, Axe=1, GreatAxe=1, Mace=1, GreatMace=1, Spear=1,
    Staff=1, Scepter=1, Bow=1, Daggers=1, DualSwords=1, DualMaces=1,
    DualAxes=1, Fists=1, Crescent=1, Thrown=1, Book=1,
}
local SLOT_LABEL = { GearNeck="Neck", GearFinger="Finger", GearTrinket="Trinket" }
local function slot_label(t) return SLOT_LABEL[t] or t end

-- ── safe readers ──────────────────────────────────────────────────
local function pget(name)
    local f = farever.player and farever.player[name]
    if f then local ok, v = pcall(f); if ok and type(v) == "number" then return v end end
    return 0
end
local function tget(name)
    local f = farever.target and farever.target[name]
    if f then local ok, v = pcall(f); if ok then return v end end
    return nil
end

-- ── threat DB (de)serialization ───────────────────────────────────
local function db_encode(db)
    local parts = {}
    for k, v in pairs(db) do
        parts[#parts + 1] = string.format("%s\t%d\t%.5f", k, v.seen, v.dmg)
    end
    return table.concat(parts, "\n")
end
local function db_decode(s)
    local db = {}
    if type(s) ~= "string" then return db end
    for line in s:gmatch("[^\n]+") do
        local k, seen, dmg = line:match("^(.-)\t(%d+)\t([%d%.]+)$")
        if k then db[k] = { seen = tonumber(seen), dmg = tonumber(dmg) } end
    end
    return db
end
local function db_save(force)
    if not db_dirty then return end
    local now = farever.now()
    if not force and (now - last_save) < SAVE_EVERY then return end
    farever.store.set(DB_KEY, db_encode(threat_db))
    last_save, db_dirty = now, false
end
local function threat_of(boss, skill)
    local e = threat_db[(boss or "") .. "|" .. (skill or "")]
    if not e or e.seen == 0 then return 0, 0 end
    return e.dmg / e.seen, e.seen
end
local function danger_rgb(avg, seen)
    if seen == 0 then return 0.55, 0.6, 0.7 end
    if avg >= DANGER_HI then return 1.0, 0.30, 0.30 end
    if avg >= DANGER_MD then return 1.0, 0.80, 0.30 end
    return 0.45, 0.85, 0.55
end
local function nice(id)
    if not id or id == "" then return "?" end
    return (id:gsub("_", " "))
end

-- ── armory index build (once) ─────────────────────────────────────
local function build_indices()
    if idx_built then return end
    for uid, u in pairs(DB_units) do
        if u.dr then
            for _, d in ipairs(u.dr) do
                local t = dropped_by[d.i]
                if not t then t = {}; dropped_by[d.i] = t end
                t[#t + 1] = { unit = uid, n = u.n, lv = u.lv or 0, zn = u.zname or "", c = d.c or 0 }
            end
        end
    end
    for id, it in pairs(DB_items) do
        if GEAR_SLOTS[it.t] then
            local s = items_by_slot[it.t]
            if not s then s = {}; items_by_slot[it.t] = s end
            s[#s + 1] = { id = id, it = it }
        end
    end
    for _, s in pairs(items_by_slot) do
        table.sort(s, function(a, b)
            local ra, rb = rrank(a.it.r), rrank(b.it.r)
            if ra ~= rb then return ra > rb end
            return (a.it.n or a.id) < (b.it.n or b.id)
        end)
    end
    idx_built = true
end

local function fmt_chance(c)
    c = c or 0
    if c > 0 and c < 1 then return string.format("%.2f%%", c) end
    return string.format("%.0f%%", c)
end

local function item_rar_safe(id)
    local it = DB_items[id]
    return it and it.r or nil
end

-- one-line "how do I get this item" hint
local function source_line(id)
    local c = DB_crafts[id]
    if c then return string.format("craft @ %s lv%d", c.j or "?", c.lv or 0) end
    local d = dropped_by[id]
    if d and #d > 0 then
        local best = d[1]
        for _, e in ipairs(d) do if e.c > best.c then best = e end end
        return string.format("%s %s, %s", best.n, fmt_chance(best.c), best.zn ~= "" and best.zn or "?")
    end
    return "source unknown"
end

-- ── arc helper for the cast ring ──────────────────────────────────
local function draw_arc(cx, cy, rad, frac, r, g, b, a, thick)
    frac = math.max(0, math.min(frac, 1))
    if frac <= 0 then return end
    local segs = math.max(2, math.floor(56 * frac))
    local a0 = -math.pi / 2
    local px, py = cx + math.cos(a0) * rad, cy + math.sin(a0) * rad
    for i = 1, segs do
        local t = a0 + (2 * math.pi * frac) * (i / segs)
        local x, y = cx + math.cos(t) * rad, cy + math.sin(t) * rad
        imgui.draw_line(px, py, x, y, r, g, b, a, thick)
        px, py = x, y
    end
end

-- ══════════════════════════════════════════════════════════════════
--  EVENTS
-- ══════════════════════════════════════════════════════════════════

function on_event(name, data)
    if name == "cast_start" then
        local boss = tget("name") or ""
        active_cast = {
            boss   = boss,
            skill  = (data and data.skill) or tget("cast_skill") or "",
            hp0    = pget("health_pct"),
            warned = false,
        }
        local avg, seen = threat_of(active_cast.boss, active_cast.skill)
        if seen > 0 and avg >= DANGER_HI then
            farever.sound("alert")
            farever.toast("DODGE: " .. nice(active_cast.skill), 1.5)
            active_cast.warned = true
        end

    elseif name == "cast_end" then
        if active_cast then
            local skill = (data and data.skill) or active_cast.skill
            if skill == active_cast.skill then
                local drop = active_cast.hp0 - pget("health_pct")
                local key  = active_cast.boss .. "|" .. active_cast.skill
                local e    = threat_db[key] or { seen = 0, dmg = 0 }
                e.seen = e.seen + 1
                if drop > 0 then e.dmg = e.dmg + drop end
                threat_db[key] = e
                db_dirty = true
                db_save(false)
            end
            active_cast = nil
        end

    elseif name == "target_changed" then
        active_cast = nil

    elseif name == "hero_locked" then
        active_cast = nil
        db_save(true)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  BOSS TAB
-- ══════════════════════════════════════════════════════════════════

local function render_boss()
    if not tget("exists") then
        imgui.text_colored(0.6, 0.6, 0.6, 1.0, "No target.")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "Target a boss; the coach learns its")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "dangerous casts as you fight.")
        return
    end

    local boss = tget("name") or ""
    imgui.text_colored(0.85, 0.9, 1.0, 1.0, nice(boss))
    imgui.progress(tget("hp_pct") or 0, string.format("HP %.0f%%", (tget("hp_pct") or 0) * 100))

    local ox, oy = imgui.cursor_pos()
    local cx, cy = ox + PANEL_W * 0.5, oy + RING_BOX * 0.5
    local R = RING_BOX * 0.5 - 18

    if tget("is_casting") then
        local skill = tget("cast_skill") or ""
        local prog  = tget("cast_progress") or 0
        local rem   = tget("cast_remaining_sec") or 0
        local total = tget("cast_total_sec") or 0
        local avg, seen = threat_of(boss, skill)
        local r, g, b = danger_rgb(avg, seen)

        if seen > 0 and avg >= DANGER_HI and active_cast and not active_cast.warned then
            farever.sound("alert"); active_cast.warned = true
        end

        imgui.draw_circle(cx, cy, R, 0.25, 0.27, 0.35, 0.8, 2.0, 48)
        if total > 0 then
            draw_arc(cx, cy, R, prog, r, g, b, 1.0, 4.0)
        else
            draw_arc(cx, cy, R, 0.18, r, g, b, 1.0, 4.0)
            imgui.draw_circle(cx, cy, R - 6, r, g, b,
                0.25 + 0.2 * math.sin(farever.now() * 6), 2.0, 32)
        end
        local pulse = (avg >= DANGER_HI) and (0.7 + 0.3 * math.sin(farever.now() * 10)) or 1.0
        imgui.draw_text(cx - 26, cy - 10, r, g, b, pulse,
            (total > 0) and string.format("%.1fs", rem) or "??")
        imgui.dummy(PANEL_W, RING_BOX)

        imgui.font_scale(1.3)
        imgui.text_colored(r, g, b, 1.0, nice(skill))
        imgui.font_scale(1.0)
        if seen == 0 then
            imgui.text_colored(0.6, 0.6, 0.7, 1.0, "new skill - learning...")
        elseif avg >= DANGER_HI then
            imgui.text_colored(r, g, b, 1.0, string.format("DANGER  avg -%.0f%% HP  (x%d)", avg * 100, seen))
        elseif avg >= DANGER_MD then
            imgui.text_colored(r, g, b, 1.0, string.format("caution  avg -%.0f%% HP  (x%d)", avg * 100, seen))
        else
            imgui.text_colored(r, g, b, 1.0, string.format("harmless  (x%d)", seen))
        end
    else
        imgui.draw_circle(cx, cy, R, 0.2, 0.22, 0.3, 0.5, 1.5, 48)
        imgui.draw_text(cx - 34, cy - 7, 0.5, 0.55, 0.65, 0.9, "no cast")
        imgui.dummy(PANEL_W, RING_BOX)
    end

    imgui.separator()
    imgui.text_colored(0.7, 0.75, 0.85, 1.0, "Known skills:")
    local rows, prefix = {}, boss .. "|"
    for k, v in pairs(threat_db) do
        if k:sub(1, #prefix) == prefix and v.seen > 0 then
            rows[#rows + 1] = { skill = k:sub(#prefix + 1), avg = v.dmg / v.seen, seen = v.seen }
        end
    end
    table.sort(rows, function(a, b) return a.avg > b.avg end)
    if #rows == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (nothing learned yet)")
    else
        for i = 1, math.min(#rows, 6) do
            local row = rows[i]
            local r, g, b = danger_rgb(row.avg, row.seen)
            imgui.text_colored(r, g, b, 1.0, string.format(
                "  %-16s -%2.0f%%  x%d", nice(row.skill):sub(1, 16), row.avg * 100, row.seen))
        end
    end
    if imgui.button("Forget this boss") then
        for k in pairs(threat_db) do
            if k:sub(1, #prefix) == prefix then threat_db[k] = nil end
        end
        db_dirty = true; db_save(true)
        farever.toast("Cleared threat data for " .. nice(boss), 1.5)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  VITALS TAB
-- ══════════════════════════════════════════════════════════════════

local RESOURCES = {
    { "Energy", "energy", "energy_regen", 0.40, 0.80, 1.00 },
    { "Rage",   "rage",   "rage_regen",   1.00, 0.45, 0.40 },
    { "Spark",  "spark",  "spark_regen",  1.00, 0.85, 0.35 },
    { "Focus",  "focus",  nil,            0.65, 0.55, 1.00 },
    { "Combo",  "combo_point", nil,       1.00, 0.60, 0.85 },
    { "Poise",  "poise",  "poise_regen",  0.60, 0.80, 0.70 },
    { "Oxygen", "oxygen", nil,            0.45, 0.90, 0.95 },
    { "Shield", "shield", nil,            0.80, 0.80, 0.90 },
    { "Fervor", "fervor", nil,            1.00, 0.70, 0.45 },
    { "Faith",  "faith",  nil,            0.95, 0.95, 0.70 },
}

local function render_vitals()
    if not farever.player.locked() then
        imgui.text_colored(1.0, 0.6, 0.2, 1.0, "Waiting for player lock...")
        return
    end

    local hp, hpmax = pget("health"), pget("max_health")
    local hp_pct = (hpmax > 0) and (hp / hpmax) or pget("health_pct")
    imgui.font_scale(1.2)
    imgui.text_colored(0.6, 1.0, 0.55, 1.0, "Health")
    imgui.font_scale(1.0)
    imgui.progress(hp_pct, string.format("%.0f / %.0f", hp, hpmax))
    local hregen = pget("health_regen")
    if hregen ~= 0 then imgui.same_line(); imgui.text(string.format("  +%.0f/s", hregen)) end

    imgui.separator()
    local shown = 0
    for _, res in ipairs(RESOURCES) do
        local field, regen_field = res[2], res[3]
        local cur = pget(field)
        local regen = regen_field and pget(regen_field) or 0
        local mx = observed_max[field] or 0
        if cur > mx then mx = cur; observed_max[field] = mx end
        if mx > 0 or regen ~= 0 then
            shown = shown + 1
            local frac = (mx > 0) and (cur / mx) or 0
            local capped = (mx > 0 and cur >= mx - 1e-6 and regen ~= 0)
            if capped then
                local p = 0.6 + 0.4 * math.sin(farever.now() * 8)
                imgui.text_colored(1.0, 0.5, 0.3, p, string.format("%s  CAPPED", res[1]))
            else
                imgui.text_colored(res[4], res[5], res[6], 1.0, res[1])
            end
            imgui.progress(frac, string.format("%.0f / %.0f%s", cur, mx,
                (regen ~= 0) and string.format("  (+%.1f/s)", regen) or ""))
        end
    end
    if shown == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "No class resources detected.")
    end

    imgui.separator()
    imgui.text_colored(0.7, 0.75, 0.85, 1.0, "Active statuses:")
    local statuses = farever.player.statuses and farever.player.statuses() or nil
    if not statuses or #statuses == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (none)")
    else
        for i = 1, math.min(#statuses, 8) do
            local s = statuses[i]
            local dur = tonumber(s.duration) or 0
            local stacks = tonumber(s.stacks) or 0
            local label = nice(s.kind or "?"):sub(1, 18)
            if stacks > 1 then label = label .. " x" .. stacks end
            local low = dur > 0 and dur < 4
            local r, g, b = low and 1.0 or 0.7, low and 0.5 or 0.85, low and 0.3 or 0.6
            imgui.text_colored(r, g, b, 1.0, string.format("  %-20s %s", label,
                (dur > 0) and string.format("%.0fs", dur) or ""))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
--  DROPS TAB  (target-aware)
-- ══════════════════════════════════════════════════════════════════

local function render_drops()
    build_indices()
    if not tget("exists") then
        imgui.text_colored(0.6, 0.6, 0.6, 1.0, "Target a mob to see its drop table.")
        return
    end
    local id = tget("name") or ""
    local u = DB_units[id]
    imgui.font_scale(1.3)
    imgui.text_colored(0.95, 0.85, 0.55, 1.0, u and u.n or nice(id))
    imgui.font_scale(1.0)
    if not u then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "No drop data for: " .. id)
        return
    end
    imgui.text(string.format("Lv %d   %s", u.lv or 0, u.zname or "?"))
    if u.dg and u.dg ~= "" then imgui.text_colored(0.7, 0.6, 0.9, 1.0, "Dungeon: " .. nice(u.dg)) end
    imgui.separator()

    local dr = u.dr or {}
    if #dr == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (no drops listed)")
        return
    end
    local sorted = {}
    for _, d in ipairs(dr) do sorted[#sorted + 1] = d end
    table.sort(sorted, function(a, b) return (a.c or 0) > (b.c or 0) end)
    for _, d in ipairs(sorted) do
        local it = DB_items[d.i]
        local r, g, b = rrgb(it and it.r)
        imgui.text_colored(r, g, b, 1.0, string.format("  %-22s %s",
            (d.n or (it and it.n) or d.i):sub(1, 22), fmt_chance(d.c)))
    end
end

-- ══════════════════════════════════════════════════════════════════
--  CRAFT TAB  (search a recipe, track ingredients with manual counts)
-- ══════════════════════════════════════════════════════════════════

local function render_recipe(out_id)
    local c = DB_crafts[out_id]
    if not c then craft_sel = nil; return end
    if imgui.button("< back") then craft_sel = nil; return end
    local oit = DB_items[out_id]
    local r, g, b = rrgb(oit and oit.r)
    imgui.font_scale(1.3)
    imgui.text_colored(r, g, b, 1.0, (oit and oit.n) or nice(out_id))
    imgui.font_scale(1.0)
    imgui.text(string.format("%s, job level %d", c.j or "?", c.lv or 0))
    imgui.separator()
    imgui.text_colored(0.7, 0.75, 0.85, 1.0, "Ingredients (tap +/- as you gather):")

    local inp = c.inp or {}
    local all_done = true
    for i, ing in ipairs(inp) do
        local key = "have_" .. ing.i
        local have = farever.store.get(key, 0)
        local need = ing.q or 1
        local done = have >= need
        if not done then all_done = false end
        local r2, g2, b2 = rrgb(item_rar_safe(ing.i))
        imgui.text_colored(done and 0.5 or r2, done and 0.8 or g2, done and 0.5 or b2,
            1.0, string.format("%s  %d/%d", (ing.n or ing.i):sub(1, 18), have, need))
        imgui.same_line()
        if imgui.button("-##h" .. i) then
            farever.store.set(key, math.max(0, have - 1))
        end
        imgui.same_line()
        if imgui.button("+##h" .. i) then
            farever.store.set(key, have + 1)
        end
        if not done then
            imgui.text_colored(0.55, 0.6, 0.7, 1.0, "    " .. source_line(ing.i))
        end
    end
    imgui.separator()
    if all_done then
        imgui.text_colored(0.4, 1.0, 0.5, 1.0, "All ingredients gathered!")
    end
    if imgui.button("Reset counts") then
        for _, ing in ipairs(inp) do farever.store.set("have_" .. ing.i, 0) end
    end
end

local craft_list_cache = nil
local function render_craft()
    build_indices()
    if craft_sel then render_recipe(craft_sel); return end

    local q, changed = imgui.input_text("Search", craft_query)
    if changed then craft_query = q end
    imgui.text_colored(0.55, 0.6, 0.7, 1.0, "Pick something to craft:")

    if not craft_list_cache then
        craft_list_cache = {}
        for out_id in pairs(DB_crafts) do
            local it = DB_items[out_id]
            craft_list_cache[#craft_list_cache + 1] =
                { id = out_id, name = (it and it.n) or out_id, rar = it and it.r }
        end
        table.sort(craft_list_cache, function(a, b) return a.name < b.name end)
    end

    local needle = craft_query:lower()
    local shown = 0
    for _, e in ipairs(craft_list_cache) do
        if needle == "" or e.name:lower():find(needle, 1, true) then
            shown = shown + 1
            if shown <= 18 then
                local r, g, b = rrgb(e.rar)
                imgui.text_colored(r, g, b, 1.0, " ")
                imgui.same_line()
                if imgui.button(e.name:sub(1, 26) .. "##c" .. e.id) then
                    craft_sel = e.id
                end
            end
        end
    end
    if shown == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (no craftable item matches)")
    elseif shown > 18 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, string.format("  ...and %d more, refine search", shown - 18))
    end
end

-- ══════════════════════════════════════════════════════════════════
--  GEAR TAB  (rarity-based upgrade finder from worn equipment)
-- ══════════════════════════════════════════════════════════════════

local function render_gear()
    build_indices()
    if not farever.player.locked() then
        imgui.text_colored(1.0, 0.6, 0.2, 1.0, "Waiting for player lock...")
        return
    end
    local plvl = pget("level")
    imgui.text(string.format("Character level %d", plvl))
    imgui.text_colored(0.5, 0.55, 0.65, 1.0, "Upgrades ranked by rarity (no stats in data).")
    imgui.separator()

    local items = farever.player.equipment and farever.player.equipment() or nil
    if not items or #items == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "No equipment data.")
        return
    end

    local any = false
    for _, worn in ipairs(items) do
        local kind = worn.kind
        local di = kind and DB_items[kind]
        local slot = di and di.t
        if slot and GEAR_SLOTS[slot] then
            any = true
            local r, g, b = rrgb(di.r)
            imgui.text_colored(0.7, 0.75, 0.85, 1.0, slot_label(slot) .. ":")
            imgui.same_line()
            imgui.text_colored(r, g, b, 1.0, string.format("%s [%s]", (di.n or kind):sub(1, 20), di.r or "?"))

            local pool = items_by_slot[slot] or {}
            local listed, cur_rank = 0, rrank(di.r)
            for _, cand in ipairs(pool) do
                if rrank(cand.it.r) > cur_rank and cand.id ~= kind then
                    listed = listed + 1
                    if listed <= 3 then
                        local cr, cg, cb = rrgb(cand.it.r)
                        imgui.text_colored(cr, cg, cb, 1.0,
                            "   + " .. (cand.it.n or cand.id):sub(1, 22))
                        imgui.text_colored(0.55, 0.6, 0.7, 1.0, "      " .. source_line(cand.id))
                    end
                end
            end
            if listed == 0 then
                imgui.text_colored(0.5, 0.6, 0.5, 1.0, "   best known rarity for this slot")
            elseif listed > 3 then
                imgui.text_colored(0.5, 0.5, 0.5, 1.0, string.format("   ...+%d more", listed - 3))
            end
        end
    end
    if not any then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "No recognised gear equipped.")
    end
end

-- ══════════════════════════════════════════════════════════════════
--  SHELL
-- ══════════════════════════════════════════════════════════════════

function on_init()
    threat_db    = db_decode(farever.store.get(DB_KEY, ""))
    tab          = farever.store.get("deck_tab", 1)
    if tab < 1 or tab > #TABS then tab = 1 end
    observed_max = {}
    active_cast  = nil
    db_dirty     = false
    last_save    = farever.now()
    craft_sel    = nil
    craft_query  = ""
    build_indices()
    farever.log.info("command_deck v" .. PLUGIN_VERSION .. " loaded (" .. #TABS .. " tabs)")
end

function on_render()
    imgui.dummy(PANEL_W, 0)

    for i, label in ipairs(TABS) do
        if i > 1 and ((i - 1) % 3) ~= 0 then imgui.same_line() end
        local mark = (i == tab) and ("[" .. label .. "]") or (" " .. label .. " ")
        if imgui.button(mark .. "##tab" .. i) then
            tab = i; farever.store.set("deck_tab", tab)
        end
    end
    imgui.separator()

    if     tab == 1 then render_boss()
    elseif tab == 2 then render_vitals()
    elseif tab == 3 then render_drops()
    elseif tab == 4 then render_craft()
    elseif tab == 5 then render_gear() end

    db_save(false)
end
