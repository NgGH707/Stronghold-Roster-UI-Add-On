// load the hooks
foreach (file in ::IO.enumerateFiles("mod_roster_UI_addon/hooks"))
{
	::include(file);
}

// register JS and CSS files
::mods_registerCSS("mod_stronghold_pokebro_pc_dialog_module.css");
::mods_registerJS("mod_stronghold_pokebro_pc_dialog_module.js");

if (::Pokebro.LegendExists)
	::mods_registerCSS("mod_additional_dialog.css");