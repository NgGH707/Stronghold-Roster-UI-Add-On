// just a situation with pratically nothing in it acts as the button to open the roster screen
this.pokebro_center_clickable_situation <- this.inherit("scripts/entity/world/settlements/situations/situation", {
	m = {},
	function create()
	{
		this.situation.create();
		this.m.ID = "POKEBRO";
		this.m.Name = "Stronghold Roster";
		this.m.Description = "Show the roster of your stronghold. Letting you transfer brothers between your and stronghold roster with ease.";
		this.m.Icon = "ui/settlement_status/pokebro_center_clickable_situation.png";
		this.m.IsStacking = false;
	}

	function getTooltip()
	{
		local ret = this.situation.getTooltip();

		ret.push({
			id = 1,
			type = "hint",
			icon = "ui/icons/mouse_left_button.png",
			text = "Open Stronghold Roster Screen"
		});

		return ret;
	}

	function isValid()
	{
		return true;
	}

	function getValidUntil()
	{
		return 100;
	}

});

