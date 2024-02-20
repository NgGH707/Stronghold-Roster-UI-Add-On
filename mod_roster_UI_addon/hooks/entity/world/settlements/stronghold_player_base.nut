// add the situation so you can click on it 
::mods_hookExactClass("entity/world/settlements/stronghold_player_base", function(obj)
{
	local ws_onEnter = obj.onEnter;
	obj.onEnter = function()
	{
		local ret = ws_onEnter();

		if (!this.hasSituation("POKEBRO"))
		{
			local situation = this.new("scripts/entity/world/settlements/situations/pokebro_center_clickable_situation");
			situation.setInstanceID(this.World.EntityManager.getNextSituationID());
			this.m.Situations.insert(0, situation);
		}

		return ret;
	}

	local ws_onSerialize = obj.onSerialize;
	obj.onSerialize = function( _out )
	{
		foreach( i, e in this.m.Situations )
		{
			if (e.getID() == "POKEBRO")
			{
				this.m.Situations.remove(i);
				break;
			}
		}

		ws_onSerialize(_out);
	}
});