this.mod_stronghold_pokebro_pc_dialog_module <- ::inherit("scripts/ui/screens/ui_module", {
	m = {
		Title = "Stronghold Roster",
		Description = "A convenient place for you to store/retrieve your brothers with minimum effort"
		PopupDialogVisible = false,
		ItemsContainerToTransfer = null,
		ItemsToTransfer = [],

		// a row can hold 11 slots so with this you have a maximum of 9 rows in the screen
		// change to 9999 so you can feel like the roster size is endless lol
		SlotNumPerRow = 11,
		StrongholdRosterLimit = 253, 
	},
	function create()
	{
		this.m.ID = "StrongholdPokebroPcDialogModule";
		this.m.PopupDialogVisible = false;
		this.m.ItemsContainerToTransfer = null;
		this.m.ItemsToTransfer = [];
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
		this.m.ItemsContainerToTransfer = null;
		this.m.ItemsToTransfer = [];
	}

	function onModuleHidden()
	{
		this.ui_module.onModuleShown();
		this.m.PopupDialogVisible = false;
		this.m.ItemsContainerToTransfer = null;
		this.m.ItemsToTransfer = [];
	}

	function destroy()
	{
		this.ui_module.destroy();
	}

	function isUsingSimplifiedRosterTooltip()
	{
		return ::World.Flags.get("SimplifiedRosterTooltip");
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
			return ::World.getPlayerRoster();
		else
			return this.getStrongholdRoster();
	}

	function getBroWithTagAndID( _id, _tag )
	{
		local bro = ::Tactical.getEntityByID(_id);

		if (bro != null)
			return bro;

		foreach ( b in this.getRosterWithTag(_tag).getAll() )
		{
			if (b.getID() != _id)
				continue;

			return b;
		}

		::logError(format("Can\'t find the brother with \'ID = %s\' in the given \'Roster Tag = %s\'", "" + _id + "", _tag));
		return null;
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
			this.queryPlayerRosterInformation(result);
		else
			this.queryStrongholdRosterInformation(result);

		this.m.JSHandle.asyncCall("loadFromData", result);
	}

	function queryStrongholdRosterInformation( _result )
	{
		local num = 0, roster = [];
		local brothers = this.getStrongholdRoster().getAll();

		foreach (i, b in brothers)
		{
			b.setPlaceInFormation(i);
			roster.push(::UIDataHelper.convertEntityToUIData(b, null));

			if (roster.len() == this.m.StrongholdRosterLimit)
				break;
		}
		 
		while (num < roster.len())
		{
			num += this.m.SlotNumPerRow;
		}

		// for now i limit the max stronghold roster size to be 253 (was 165) which is 23 roster rows, should i expand it?
		// make it so that the stronghold roster formation automatically resize on the screen and there is always at least 33 spare spots in stronghold
		num = ::Math.min(this.m.StrongholdRosterLimit, num + 33);
		
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
		local roster = ::World.Assets.getFormation();

		for( local i = 0; i != roster.len(); ++i )
		{
			if (roster[i] == null)
				continue;

			roster[i] = ::UIDataHelper.convertEntityToUIData(roster[i], null);
		}

		_result.Player <- roster;
		_result.BrothersMaxInCombat <- ::World.Assets.getBrothersMaxInCombat();
		_result.BrothersMax <- ::World.Assets.getBrothersMax();

		if ("Assets" in _result)
		{
			_result.Assets.Brothers <- ::World.getPlayerRoster().getSize();
			_result.Assets.BrothersMax <- _result.BrothersMax;
		}
	}

	// only ask for the data i need
	function queryAssetsInformation( _assets )
	{
		_assets.Brothers <- ::World.getPlayerRoster().getSize();
		_assets.BrothersMax <- ::World.Assets.getBrothersMax();
		_assets.StrongholdBrothers <- this.getStrongholdRoster().getSize();
		_assets.StrongholdBrothersMax <- this.m.StrongholdRosterLimit;
	}

	function onUpdateRosterPosition( _data )
	{
		foreach ( bro in ::World.getPlayerRoster().getAll())
		{
		 	if (bro.getID() != _data[0])
		 		continue;

		 	bro.setPlaceInFormation(_data[1]);
		 	return;
		}

		foreach ( bro in this.getStrongholdRoster().getAll())
		{
		 	if (bro.getID() != _data[0])
		 		continue;
		 	
		 	bro.setPlaceInFormation(_data[1]);
		 	return;
		}
	}

	function MoveAtoB( _data )
	{
		local isMovingToPlayerRoster = ::Pokebro.LegendExists && _data[3] == "roster.player";
		local rosterA = this.getRosterWithTag(_data[1]);
		local rosterB = this.getRosterWithTag(_data[3]);

		foreach(i, bro in rosterA.getAll())
		{
			if (bro.getID() != _data[0])
				continue;

			rosterB.add(bro);
			rosterA.remove(bro);

			if (isMovingToPlayerRoster && ::World.State.getBrothersInFrontline() > ::World.Assets.getBrothersMaxInCombat())
				bro.setInReserves(true);
			
			bro.setPlaceInFormation(_data[2]);
			break;
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
			bro.getSkills().onDismiss();
			::World.Statistics.getFlags().increment("BrosDismissed");

			if (bro.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury) && (bro.getBackground().getID() != "background.slave" || ::World.Assets.getOrigin().getID() == "scenario.sato_escaped_slaves"))
				::World.Statistics.getFlags().increment("BrosWithPermanentInjuryDismissed");

			if (payCompensation)
			{
				::World.Assets.addMoney(-10 * ::Math.max(1, bro.getDaysWithCompany()));

				if (bro.getBackground().getID() == "background.slave")
				{
					local playerRoster = ::World.getPlayerRoster().getAll();

					foreach( other in playerRoster )
					{
						if (bro.getID() == other.getID())
							continue;

						if (other.getBackground().getID() == "background.slave")
							other.improveMood(::Const.MoodChange.SlaveCompensated, "Glad to see " + bro.getName() + " get reparations for his time");
					}
				}
			}
			else if (bro.getBackground().getID() == "background.slave")
			{
			}
			else if (bro.getLevel() >= 11 && !::World.Statistics.hasNews("dismiss_legend") && ::World.getPlayerRoster().getSize() > 1)
			{
				local news = ::World.Statistics.createNews();
				news.set("Name", bro.getName());
				::World.Statistics.addNews("dismiss_legend", news);
			}
			else if (bro.getDaysWithCompany() >= 50 && !::World.Statistics.hasNews("dismiss_veteran") && ::World.getPlayerRoster().getSize() > 1 && ::Math.rand(1, 100) <= 33)
			{
				local news = ::World.Statistics.createNews();
				news.set("Name", bro.getName());
				::World.Statistics.addNews("dismiss_veteran", news);
			}
			else if (bro.getLevel() >= 3 && bro.getSkills().hasSkillOfType(::Const.SkillType.PermanentInjury) && !::World.Statistics.hasNews("dismiss_injured") && ::World.getPlayerRoster().getSize() > 1 && ::Math.rand(1, 100) <= 33)
			{
				local news = ::World.Statistics.createNews();
				news.set("Name", bro.getName());
				::World.Statistics.addNews("dismiss_injured", news);
			}
			else if (bro.getDaysWithCompany() >= 7)
			{
				local playerRoster = ::World.getPlayerRoster().getAll();

				foreach( other in playerRoster )
				{
					if (bro.getID() == other.getID())
						continue;

					if (bro.getDaysWithCompany() >= 50)
						other.worsenMood(::Const.MoodChange.VeteranDismissed, "Dismissed " + bro.getName());
					else
						other.worsenMood(::Const.MoodChange.BrotherDismissed, "Dismissed " + bro.getName());
				}
			}

			bro.getItems().transferToStash(::World.Assets.getStash());
			roster.remove(bro);

			if (::Pokebro.LegendExists)
				::World.State.getPlayer().calculateModifiers();
			
			this.loadRosterWithTag(_data[2]);
		}
	}

	function onUpdateNameAndTitle( _data )
	{
		local bro = this.getBroWithTagAndID(_data[0], _data[3]);

		if (bro == null)
		{
			::logError("Can\'t find the brother to change Name and Title");
			return null;
		}
		
		if (_data[1].len() >= 1)
			bro.setName(_data[1]);

		bro.setTitle(_data[2]);
		return ::UIDataHelper.convertEntityToUIData(bro, null);
	}

	function onCheckCanTransferItems( _data )
	{
		local bro = this.getBroWithTagAndID(_data[0], _data[2]);

		if (bro == null)
		{
			::logError("Can\'t find the brother to Check Transfer Items");
			return null;
		}

		local find = [], items = bro.getItems(), freeSlots = ::World.Assets.getStash().getNumberOfEmptySlots();

		switch(_data[1])
		{
		case "all":
			find.extend(items.getAllItems());
			break;

		case "weapon":
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Mainhand));
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Offhand));
			break;

		case "armor":
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Head));
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Body));
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Accessory));
			break;

		case "bag":
			find.extend(items.getAllItemsAtSlot(::Const.ItemSlot.Bag));
			break;

		default:
			return {
				Result = false,
				NoItem = true,
			};
		}

		if (find.len() == 0)
			return {
				Result = false,
				NoItem = true,
			};
		
		this.m.ItemsToTransfer = [];
		this.m.ItemsToTransfer.extend(find);
		this.m.ItemsContainerToTransfer = typeof items == "instance" ? items : ::WeakTableRef(items);
		return {
			ID = bro.getID(),
			Tag = _data[2],
			ItemsNum = find.len(),
			StashNum = freeSlots,
			Result = find.len() <= freeSlots
		};
	}

	function onTransferItems()
	{
		local toTransfer = [];
		local stash = ::World.Assets.getStash();
		local bro = this.m.ItemsContainerToTransfer.getActor();

		foreach( item in this.m.ItemsToTransfer)
		{
			if (item.isEquipped())
				this.m.ItemsContainerToTransfer.unequip(item);
			else
				this.m.ItemsContainerToTransfer.removeFromBag(item);

			toTransfer.push(item);
		}

		foreach( item in toTransfer )
		{
			if (stash.add(item) != null)
				continue;

			// stop the transfering when there is no space to store the item
			break;
		}

		if (typeof bro == "instance")
			bro = bro.get();
		
		this.m.ItemsToTransfer = [];
		this.m.ItemsContainerToTransfer = null;
		this.m.JSHandle.asyncCall("updateSelectedBrother", ::UIDataHelper.convertEntityToUIData(bro, null));
	}

	function pushUIMenuStack()
	{
		::World.State.getMenuStack().push(function() {
			::World.State.getTownScreen().showMainDialog();
		}, function() {
			return !::World.State.getTownScreen().isAnimating();
		});
	}

	function onTooltipButtonPressed( _data )
	{
		::World.Flags.set("SimplifiedRosterTooltip", _data[0]);
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
