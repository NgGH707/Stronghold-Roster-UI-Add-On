// just for displaying the xp progress bar
::mods_hookExactClass("entity/tactical/player", function(obj)
{
	obj.getXPDataForProgessBar <- function()
	{
		if (this.m.Level >= 7 && ("State" in this.World) && this.World.State != null && this.World.Assets.getOrigin().getID() == "scenario.manhunters" && this.getBackground().getID() == "background.slave")
		{
			return {
				Current = this.Const.LevelXP[6],
				Max = this.Const.LevelXP[6]
			};
		}
		else
		{
			local CurrentLevelXp = this.m.Level < this.Const.LevelXP.len() ? this.m.Level : this.Const.LevelXP.len() - 1;

			return {
				Current = this.getXP() - this.Const.LevelXP[CurrentLevelXp - 1],
				Max = this.Const.LevelXP[CurrentLevelXp] - this.Const.LevelXP[CurrentLevelXp - 1]
			};
		}
	}
});