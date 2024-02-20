// add new module to world_town_screen
::mods_hookNewObject("ui/screens/world/world_town_screen", function(obj)
{
	obj.m.PokebroPcDialogModule <- null;
	obj.m.PokebroPcDialogModule = this.new("scripts/ui/screens/world/modules/world_town_screen/mod_stronghold_pokebro_pc_dialog_module");
	obj.m.PokebroPcDialogModule.setParent(obj);
	obj.m.PokebroPcDialogModule.connectUI(obj.m.JSHandle);

	local ws_isAnimating = obj.isAnimating;
	obj.isAnimating = function()
	{
		local ret = ws_isAnimating();

		if (!ret && this.m.PokebroPcDialogModule != null)
			return this.m.PokebroPcDialogModule.isAnimating();
		
		return ret;
	};

	obj.getPokebroPcDialogModule <- function()
	{
		return this.m.PokebroPcDialogModule;
	};

	local ws_destroy = obj.destroy;
	obj.destroy = function()
	{
		this.m.PokebroPcDialogModule.destroy();
		this.m.PokebroPcDialogModule = null;
		ws_destroy();
	};

	local ws_clear = obj.clear;
	obj.clear = function()
	{
		ws_clear();
		this.m.PokebroPcDialogModule.clear();
	};

	local ws_showLastActiveDialog = obj.showLastActiveDialog;
	obj.showLastActiveDialog = function()
	{
		if (this.m.LastActiveModule == this.m.PokebroPcDialogModule)
			this.showPokebroPcDialog();
		else
			ws_showLastActiveDialog();
	};


	// using a simple hack to open the screen 
	local ws_onContractClicked = obj.onContractClicked;
	obj.onContractClicked = function( _data )
	{
		if (this.isAnimating())
			return;

		if (typeof _data == "string" && _data == "POKEBRO")
			showPokebroPcDialog();
		else
			ws_onContractClicked(_data);
	}

	obj.showPokebroPcDialog <- function()
	{
		if (this.m.JSHandle != null && this.isVisible())
		{
			this.World.Assets.updateFormation();
			this.m.LastActiveModule = this.m.PokebroPcDialogModule;
			this.Tooltip.hide();
			this.m.JSHandle.asyncCall("showPokebroPcDialog", this.m.PokebroPcDialogModule.queryLoad());
			this.m.PokebroPcDialogModule.pushUIMenuStack(); //make sure when you press Esc, you will return to the town main screen
		}
	};
});