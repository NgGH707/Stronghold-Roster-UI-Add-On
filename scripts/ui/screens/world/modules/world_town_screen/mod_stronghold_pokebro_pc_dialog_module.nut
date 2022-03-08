this.mod_stronghold_pokebro_pc_dialog_module <- this.inherit("scripts/ui/screens/ui_module", {
	m = {
		Title = "Stronghold Roster",
		Description = "A convenient place for you to store/retrieve your brother with minimum effort"
		PopupDialogVisible = false,
		ItemsToTransfer = [],
		ItemsContainerToTransfer = null,

		// a row can hold 11 slots so with this you have a maximum of 9 rows in the screen
		// change to 9999 so you can feel like the roster size is endless lol
		StrongholdRosterLimit = 165, 
	},
	function create()
	{
		this.m.ID = "StrongholdPokebroPcDialogModule";
		this.m.PopupDialogVisible = false;
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		this.ui_module.create();
	}

	function isAnimating()
	{
		return this.ui_module.isAnimating() || this.m.PopupDialogVisible != null && this.m.PopupDialogVisible == true;
	}

	function onModuleShown()
	{
		this.ui_module.onModuleShown();
		this.m.PopupDialogVisible = false;
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
	}

	function onModuleHidden()
	{
		this.ui_module.onModuleShown();
		this.m.PopupDialogVisible = false;
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
	}

	function destroy()
	{
		this.ui_module.destroy();
	}

	function isUsingSimplifiedRosterTooltip()
	{
		return this.World.Flags.get("SimplifiedRosterTooltip");
	}

	function getStrongholdRosterSeed()
	{
		return this.m.Parent.getTown().getFlags().get("RosterSeed");
	}

	function getStrongholdRoster()
	{
		return this.m.Parent.getTown().getLocalRoster();
	}

	function getRosterWithTag( _tag )
	{
		if (_tag == "roster.player")
		{
			return this.World.getPlayerRoster();
		}
		else
		{
			return this.getStrongholdRoster();
		}
	}

	function getBroWithTagAndID( _id, _tag )
	{
		local bro = this.Tactical.getEntityByID(_id);

		if (bro == null)
		{
			foreach ( b in this.getRosterWithTag(_tag).getAll() )
			{
				if (b.getID() == _id)
				{
					bro = b;
					break;
				}
			}

			if (bro == null)
			{
				this.logError("Can\'t find the brother in the given roster");
				return null;
			}
		}

		return bro;
	}

	function queryLoad()
	{
		local result = {
			Title = this.m.Title,
			SubTitle = this.m.Description,
			SimpleTooltip = this.isUsingSimplifiedRosterTooltip(),
			Assets = {},
		};
		this.queryPlayerRosterInformation(result);
		this.queryStrongholdRosterInformation(result);
		return result;
	}

	function loadRosterWithTag( _tag )
	{
		local result = {};
		result.Assets <- {};
		result.Assets.No <- true;

		if (_tag == "roster.player")
		{
			this.queryPlayerRosterInformation(result);
		}
		else
		{
			this.queryStrongholdRosterInformation(result);
		}

		this.m.JSHandle.asyncCall("loadFromData", result);
	}

	function queryStrongholdRosterInformation( _result )
	{
		local num = 11;
		local roster = [];
		local brothers = this.getStrongholdRoster().getAll();

		foreach (i, b in brothers)
		{
			b.setPlaceInFormation(i);
			roster.push(this.UIDataHelper.convertEntityToUIData(b, null));

			if (roster.len() == this.m.StrongholdRosterLimit)
			{
				break;
			}
		}
		 
		while (num < roster.len())
		{
			num += 11;
		}

		// for now i limit the max stronghold roster size to be 165 (was 99) which is 15 roster rows, should i expand it?
		// make it so that the stronghold roster formation automatically resize on the screen and there is always at least 33 spare spots in stronghold
		num = this.Math.min(this.m.StrongholdRosterLimit, num + 33);
		
		// fill the empty space
		while (roster.len() < num)
		{
			roster.push(null);
		}

		_result.Stronghold <- roster;
		_result.BrothersMaxInStronghold <- num;

		if ("Assets" in _result)
		{
			_result.Assets.StrongholdBrothers <- brothers.len();
			_result.Assets.StrongholdBrothersMax <- num;
		}
	}

	function queryPlayerRosterInformation( _result )
	{
		local roster = this.World.Assets.getFormation();

		for( local i = 0; i != roster.len(); i = ++i )
		{
			if (roster[i] != null)
			{
				roster[i] = this.UIDataHelper.convertEntityToUIData(roster[i], null);
			}
		}

		_result.PLayer <- roster;
		_result.BrothersMaxInCombat <- this.World.Assets.getBrothersMaxInCombat();
		_result.BrothersMax <- this.World.Assets.getBrothersMax();

		if ("Assets" in _result)
		{
			_result.Assets.Brothers <- this.World.getPlayerRoster().getSize();
			_result.Assets.BrothersMax <- _result.BrothersMax;
		}
	}

	// only ask for the data i need
	function queryAssetsInformation( _assets )
	{
		_assets.Brothers <- this.World.getPlayerRoster().getSize();
		_assets.BrothersMax <- this.World.Assets.getBrothersMax();
		_assets.StrongholdBrothers <- this.getStrongholdRoster().getSize();
		_assets.StrongholdBrothersMax <- this.m.StrongholdRosterLimit;
	}

	function onUpdateRosterPosition( _data )
	{
		foreach ( bro in this.World.getPlayerRoster().getAll())
		{
		 	if (bro.getID() == _data[0])
		 	{
		 		bro.setPlaceInFormation(_data[1]);
		 		return;
		 	}
		}

		foreach ( bro in this.getStrongholdRoster().getAll())
		{
		 	if (bro.getID() == _data[0])
		 	{
		 		bro.setPlaceInFormation(_data[1]);
		 		return;
		 	}
		}
	}

	function MoveAtoB( _data )
	{
		local isMovingToPlayerRoster = this.Pokebro.LegendExists && _data[3] == "roster.player";
		local rosterA = this.getRosterWithTag(_data[1]);
		local rosterB = this.getRosterWithTag(_data[3]);

		foreach(i, bro in rosterA.getAll())
		{
			if (bro.getID() == _data[0])
			{
				rosterB.add(bro);
				rosterA.remove(bro);

				if (isMovingToPlayerRoster && this.World.State.getBrothersInFrontline() > this.World.Assets.getBrothersMaxInCombat())
				{
					bro.setInReserves(true);
				}
				
				bro.setPlaceInFormation(_data[2]);
				break;
			}
		}
		
		local ret = {};
		this.queryAssetsInformation(ret);
		this.m.JSHandle.asyncCall("updateAssets", ret);
	}

	function onDismissCharacter( _data )
	{
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		local payCompensation = _data[1];
		local bro = this.getBroWithTagAndID(_data[0], _data[2]);
		local roster = this.getRosterWithTag(_data[2]);

		if (bro != null)
		{
			this.World.Statistics.getFlags().increment("BrosDismissed");

			if (bro.getSkills().hasSkillOfType(this.Const.SkillType.PermanentInjury) && (bro.getBackground().getID() != "background.slave" || this.World.Assets.getOrigin().getID() == "scenario.sato_escaped_slaves"))
			{
				this.World.Statistics.getFlags().increment("BrosWithPermanentInjuryDismissed");
			}

			if (payCompensation)
			{
				this.World.Assets.addMoney(-10 * this.Math.max(1, bro.getDaysWithCompany()));

				if (bro.getBackground().getID() == "background.slave")
				{
					local playerRoster = this.World.getPlayerRoster().getAll();

					foreach( other in playerRoster )
					{
						if (bro.getID() == other.getID())
						{
							continue;
						}

						if (other.getBackground().getID() == "background.slave")
						{
							other.improveMood(this.Const.MoodChange.SlaveCompensated, "Glad to see " + bro.getName() + " get reparations for his time");
						}
					}
				}
			}
			else if (bro.getBackground().getID() == "background.slave")
			{
			}
			else if (bro.getLevel() >= 11 && !this.World.Statistics.hasNews("dismiss_legend") && this.World.getPlayerRoster().getSize() > 1)
			{
				local news = this.World.Statistics.createNews();
				news.set("Name", bro.getName());
				this.World.Statistics.addNews("dismiss_legend", news);
			}
			else if (bro.getDaysWithCompany() >= 50 && !this.World.Statistics.hasNews("dismiss_veteran") && this.World.getPlayerRoster().getSize() > 1 && this.Math.rand(1, 100) <= 33)
			{
				local news = this.World.Statistics.createNews();
				news.set("Name", bro.getName());
				this.World.Statistics.addNews("dismiss_veteran", news);
			}
			else if (bro.getLevel() >= 3 && bro.getSkills().hasSkillOfType(this.Const.SkillType.PermanentInjury) && !this.World.Statistics.hasNews("dismiss_injured") && this.World.getPlayerRoster().getSize() > 1 && this.Math.rand(1, 100) <= 33)
			{
				local news = this.World.Statistics.createNews();
				news.set("Name", bro.getName());
				this.World.Statistics.addNews("dismiss_injured", news);
			}
			else if (bro.getDaysWithCompany() >= 7)
			{
				local playerRoster = this.World.getPlayerRoster().getAll();

				foreach( other in playerRoster )
				{
					if (bro.getID() == other.getID())
					{
						continue;
					}

					if (bro.getDaysWithCompany() >= 50)
					{
						other.worsenMood(this.Const.MoodChange.VeteranDismissed, "Dismissed " + bro.getName());
					}
					else
					{
						other.worsenMood(this.Const.MoodChange.BrotherDismissed, "Dismissed " + bro.getName());
					}
				}
			}
			bro.getItems().transferToStash(this.World.Assets.getStash());
			roster.remove(bro);

			if (this.Pokebro.LegendExists)
			{
				this.World.State.getPlayer().calculateModifiers();
			}
			
			this.loadRosterWithTag(_data[2]);
		}
	}

	function onUpdateNameAndTitle( _data )
	{
		local bro = this.getBroWithTagAndID(_data[0], _data[3]);

		if (bro == null)
		{
			this.logError("Can\'t find the brother to chance Name and Title");
			return null;
		}
		
		if (_data[1].len() >= 1)
		{
			bro.setName(_data[1]);
		}

		bro.setTitle(_data[2]);
		return this.UIDataHelper.convertEntityToUIData(bro, null);
	}

	function onCheckCanTransferItems( _data )
	{
		local bro = this.getBroWithTagAndID(_data[0], _data[2]);

		if (bro == null)
		{
			this.logError("Can\'t find the brother to Check Transfer Items");
			return null;
		}

		local items = bro.getItems();
		local find = [];

		switch(_data[1])
		{
		case "all":
			find.extend(items.getAllItems());
			break;

		case "weapon":
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Mainhand));
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Offhand));
			break;

		case "armor":
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Head));
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Body));
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Accessory));
			break;

		case "bag":
			find.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Bag));
			break;

		default:
			return {
				Result = false,
				NoItem = true,
			};
		}

		if (find.len() == 0)
		{
			return {
				Result = false,
				NoItem = true,
			}
		}

		local stash = this.World.Assets.getStash();
		local freeSlots = stash.getNumberOfEmptySlots();
		local ret = {
			ID = bro.getID(),
			Tag = _data[2],
			ItemsNum = find.len(),
			StashNum = freeSlots,
			Result = find.len() <= freeSlots
		};

		this.m.ItemsToTransfer = [];
		this.m.ItemsToTransfer.extend(find);
		this.m.ItemsContainerToTransfer = null;
		this.m.ItemsContainerToTransfer = items;
		return ret;
	}

	function onTransferItems()
	{
		local toTransfer = [];
		local stash = this.World.Assets.getStash();
		local bro = this.m.ItemsContainerToTransfer.getActor();

		foreach( item in this.m.ItemsToTransfer)
		{
			if (item.isEquipped())
			{
				this.m.ItemsContainerToTransfer.unequip(item);
			}
			else
			{
				this.m.ItemsContainerToTransfer.removeFromBag(item);
			}

			toTransfer.push(item);
		}

		foreach( item in toTransfer )
		{
			if (stash.add(item) == null)
			{
				break;
			}
		}

		if (typeof bro == "instance")
		{
			bro = bro.get();
		}
		
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		this.m.JSHandle.asyncCall("updateSelectedBrother", this.UIDataHelper.convertEntityToUIData(bro, null));
	}

	function pushUIMenuStack()
	{
		this.World.State.getMenuStack().push(function ()
		{
			this.World.State.getTownScreen().showMainDialog();
		}, function ()
		{
			return !this.World.State.getTownScreen().isAnimating();
		});
	}

	function onTooltipButtonPressed( _data )
	{
		this.World.Flags.set("SimplifiedRosterTooltip", _data[0]);
	}

	function onPopupDialogIsVisible( _data )
	{
		this.m.PopupDialogVisible = _data[0];
	}

	function onLeaveButtonPressed()
	{
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		this.m.Parent.onModuleClosed();
	}

	function onBrothersButtonPressed()
	{
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		this.m.Parent.onBrothersButtonPressed();
	}

});
