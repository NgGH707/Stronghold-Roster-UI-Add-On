::Pokebro <- {
	ID = "mod_roster_UI_addon",
	Name = "Stronghold Roster UI Addon",
	Version = "1.0.1",
	LegendExists = false,
};

::mods_registerMod("mod_pokebro_pc_for_stronghold", 1.0);

::mods_registerMod(::Pokebro.ID, ::Pokebro.Version, ::Pokebro.Name);
::mods_queue(::Pokebro.ID, "mod_msu(>=1.2.4), mod_stronghold", function()
{
	// define mod class of this mod
	::Pokebro.Mod <- ::MSU.Class.Mod(::Pokebro.ID, ::Pokebro.Version, ::Pokebro.Name);
	::Pokebro.LegendExists <- ::mods_getRegisteredMod("mod_legends") != null;

	// add GitHub mod source
	//::Pokebro.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/...");
	//::Pokebro.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);

	// add NexusMods mod source (for an easy link)
	::Pokebro.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.NexusMods, "https://www.nexusmods.com/battlebrothers/mods/207");
	// nexus api is closed, so can't really check update from it
	//::Pokebro.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.NexusMods);

	// load hook files
	::include("mod_roster_UI_addon/load.nut");
});





