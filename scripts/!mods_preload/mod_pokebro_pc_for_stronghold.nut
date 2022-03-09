::mods_registerMod("mod_pokebro_pc_for_stronghold", 1.0);
::mods_registerCSS("mod_stronghold_pokebro_pc_dialog_module.css");
::mods_registerJS("mod_stronghold_pokebro_pc_dialog_module.js");
::mods_queue("mod_pokebro_pc_for_stronghold", "mod_stronghold", function()
{
	if (::mods_getRegisteredMod("mod_legends") != null)
	{
		::mods_registerCSS("mod_additional_dialog.css");
	}
	
	local gt = this.getroottable();
	gt.Pokebro <- {};
	gt.Pokebro.LegendExists <- ::mods_getRegisteredMod("mod_legends") != null;

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


	// add new tooltips
	::mods_hookNewObjectOnce("ui/screens/tooltip/tooltip_events", function( obj ) 
	{
		obj.pushSectionToTooltip <- function( _tooltip, _items, _title, _startID, _prependIcon = "", _stackInOneLine = false )
		{
			if (!_items)
			{
				return;
			}

			local stacks = {};
			local stackEffects = function( _effects )
			{
				local _stacks = {};

				foreach( _, _e in _effects )
				{
					local name = _e.getName();

					if (name in _stacks)
					{
						_stacks[name] += 1;
					}
					else
					{
						_stacks[name] <- 1;
					}
				}

				return _stacks;
			};
			local pushSectionName = function ( _tooltip, _items, _title, _startID )
			{
				if (_items.len() && _title)
				{
					_tooltip.push({
						id = _startID,
						type = "text",
						text = "[u][size=14]" + _title + "[/size][/u]"
					});
				}
			};

			if (_stackInOneLine)
			{
				stacks = stackEffects(_items);
				local newItems = [];
				local added = {};

				foreach( i, item in _items )
				{
					local name = item.getName();

					if (!(name in added))
					{
						newItems.push(item);
						added[name] <- 1;
					}
				}

				_items = newItems;
			}

			pushSectionName(_tooltip, _items, _title, _startID);
			_startID = _startID + 1;

			foreach( i, item in _items )
			{
				local name = item.getName();
				local text = name;

				if (_stackInOneLine && stacks[name] > 1)
				{
					text = text + (" [color=" + this.Const.UI.Color.NegativeValue + "]" + "x" + stacks[name] + "[/color]");
				}

				_tooltip.push({
					id = _startID + i,
					type = "text",
					icon = _prependIcon + item.getIcon(),
					text = text
				});
			}
		};

		local ws_general_queryUIElementTooltipData = obj.general_queryUIElementTooltipData;
	 	obj.general_queryUIElementTooltipData = function(_entityId, _elementId, _elementOwner)
	 	{
	 		local entity;

			if (_entityId != null)
			{
				entity = this.Tactical.getEntityByID(_entityId);
			}

	 		if (_elementId == "pokebro.roster" && entity != null)
	 		{
	 			local tooltip = [
					{
						id = 1,
						type = "title",
						text = entity.getName()
					}
				];

				local time = entity.getDaysWithCompany();
				local stats = entity.getLifetimeStats();
				local background = entity.getBackground();
				local text;
				
				if (background != null && background.getID() == "background.companion")
				{
					text = "With the company from the very beginning.";
				}
				else if (time > 1)
				{
					text = "With the company for " + time + " days.";
				}
				else
				{
					text = "Has just joined the company.";
				}

				if (stats.Battles != 0)
				{
					if (stats.Battles == 1)
					{
						text = text + (" Took part in " + stats.Battles + " battle");
					}
					else
					{
						text = text + (" Took part in " + stats.Battles + " battles");
					}

					if (stats.Kills == 1)
					{
						text = text + (" and has " + stats.Kills + " kill.");
					}
					else if (stats.Kills > 1)
					{
						text = text + (" and has " + stats.Kills + " kills.");
					}
					else
					{
						text = text + ".";
					}

					if (stats.MostPowerfulVanquished != "")
					{
						text = text + (" The most powerful opponent he vanquished was " + stats.MostPowerfulVanquished + ".");
					}
				}

				tooltip.push({
					id = 2,
					type = "description",
					text = text
				});

				if (entity.getFlags().get("IsPlayerCharacter"))
				{
					tooltip.push({
						id = 5,
						type = "text",
						icon = "ui/traits/trait_icon_63.png",
						text = "[color=#ffd700]PLayer Character[/color]"
					});
				}

				if (entity.getDailyCost() != 0)
				{
					tooltip.push({
						id = 3,
						type = "text",
						icon = "ui/icons/asset_daily_money.png",
						text = "Paid [img]gfx/ui/tooltips/money.png[/img]" + entity.getDailyCost() + " daily"
					});
				}

				tooltip.push({
					id = 5,
					type = "text",
					icon = "ui/icons/level.png",
					text = "Level " + entity.getLevel()
				});

				local xp = entity.getXPDataForProgessBar();

				tooltip.push({
					id = 4,
					type = "progressbar",
					icon = "ui/icons/xp_received.png",
					value = xp.Current,
					valueMax = xp.Max,
					text = "" + entity.getXP() + " / " + entity.getXPForNextLevel() + "",
					style = "action-points-slim"
				});

				if (entity.getArmorMax(this.Const.BodyPart.Head) > 0)
				{
					tooltip.push({
						id = 5,
						type = "progressbar",
						icon = "ui/icons/armor_head.png",
						value = entity.getArmor(this.Const.BodyPart.Head),
						valueMax = entity.getArmorMax(this.Const.BodyPart.Head),
						text = "" + entity.getArmor(this.Const.BodyPart.Head) + " / " + entity.getArmorMax(this.Const.BodyPart.Head) + "",
						style = "armor-head-slim"
					});
				}

				if (entity.getArmorMax(this.Const.BodyPart.Body) > 0)
				{
					tooltip.push({
						id = 4,
						type = "progressbar",
						icon = "ui/icons/armor_body.png",
						value = entity.getArmor(this.Const.BodyPart.Body),
						valueMax = entity.getArmorMax(this.Const.BodyPart.Body),
						text = "" + entity.getArmor(this.Const.BodyPart.Body) + " / " + entity.getArmorMax(this.Const.BodyPart.Body) + "",
						style = "armor-body-slim"
					});
				}

				tooltip.push({
					id = 4,
					type = "text",
					icon = this.Const.MoodStateIcon[entity.getMoodState()],
					text = this.Const.MoodStateName[entity.getMoodState()]
				});

				local injuries = entity.getSkills().query(this.Const.SkillType.Injury | this.Const.SkillType.SemiInjury);

				foreach( injury in injuries )
				{
					if (injury.isType(this.Const.SkillType.TemporaryInjury))
					{
						tooltip.push({
							id = 90,
							type = "text",
							icon = injury.getIcon(),
							text = injury.getName()
						});
					}
				}

				if (entity.getHitpoints() < entity.getHitpointsMax())
				{
					tooltip.push({
						id = 133,
						type = "text",
						icon = "ui/icons/days_wounded.png",
						text = "Light Wounds"
					});
				}

				if (!this.World.Flags.get("SimplifiedRosterTooltip"))
				{
					local items = entity.getItems();
					local equipment = items.getAllItemsAtSlot(this.Const.ItemSlot.Head);
					equipment.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Body));
					equipment.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Mainhand));
					equipment.extend(items.getAllItemsAtSlot(this.Const.ItemSlot.Offhand));
					this.pushSectionToTooltip(tooltip, equipment, "Equipment", 300, "ui/items/");
					local accessories = items.getAllItemsAtSlot(this.Const.ItemSlot.Accessory);
					this.pushSectionToTooltip(tooltip, accessories, "Accessory", 400, "ui/items/");
					local ammos = items.getAllItemsAtSlot(this.Const.ItemSlot.Ammo);
					this.pushSectionToTooltip(tooltip, ammos, "Ammo", 500, "ui/items/");
					local items = items.getAllItemsAtSlot(this.Const.ItemSlot.Bag);
					local itemsTitle = "Item(s) in bags";
					this.pushSectionToTooltip(tooltip, items, itemsTitle, 600, "ui/items/", true);
				}

				tooltip.extend([
					{
						id = 10,
						type = "hint",
						icon = "ui/icons/mouse_right_button.png",
						text = "Transfer brother"
					},
					{
						id = 12,
						type = "hint",
						icon = "ui/icons/mouse_left_button_alt.png",
						text = "View brother\'s perk tree"
					}
					{
						id = 11,
						type = "hint",
						icon = "ui/icons/mouse_left_button_ctrl.png",
						text = "Dismiss brother"
					}
				]);

	 			return tooltip;
	 		}

	 		switch (_elementId)
	 		{
	 		case "assets.BrothersInStronghold":
				return [
					{
						id = 1,
						type = "title",
						text = "Stronghold Roster"
					},
					{
						id = 2,
						type = "description",
						text = "Show the roster stored inside your stronghold."
					}
				];

			case "pokebro.strippingnaked":
				return [
					{
						id = 1,
						type = "title",
						text = "Strip Naked"
					},
					{
						id = 2,
						type = "description",
						text = "Transfer all items on selected brother to your company stash."
					}
				];

			case "pokebro.strippingweapon":
				return [
					{
						id = 1,
						type = "title",
						text = "Take Weapon"
					},
					{
						id = 2,
						type = "description",
						text = "Transfer any item in main hand and off hand on selected brother to your company stash."
					}
				];

			case "pokebro.strippingarmor":
				return [
					{
						id = 1,
						type = "title",
						text = "Take Armor"
					},
					{
						id = 2,
						type = "description",
						text = "Transfer any helmet or armor on selected brother to your company stash."
					}
				];

			case "pokebro.strippingbag":
				return [
					{
						id = 1,
						type = "title",
						text = "Take Bag Items"
					},
					{
						id = 2,
						type = "description",
						text = "Transfer all items in bag of selected brother to your company stash."
					}
				];

			case "pokebro.simplerostertooltip":
				return [
					{
						id = 1,
						type = "title",
						text = this.World.Flags.get("SimplifiedRosterTooltip") ? "Turn [color=" + this.Const.UI.Color.NegativeValue + "]OFF[/color] Simple Roster Tooltip" : "Turn [color=" + this.Const.UI.Color.PositiveValue + "]ON[/color] Simple Roster Tooltip"
					},
					{
						id = 2,
						type = "description",
						text = "Let you decide whether you want to see a simplified roster tooltip so it doesn\'t obstruct your view."
					}
				];
	 		}

	 		return ws_general_queryUIElementTooltipData(_entityId, _elementId, _elementOwner);
		}
	});
	

	// add new screen to world_town_screen
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
			{
				return this.m.PokebroPcDialogModule.isAnimating();
			}
			else
			{
				return ret;
			}
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
			{
				this.showPokebroPcDialog();
			}
			else
			{
				ws_showLastActiveDialog();
			}
		};


		// using a simple hack to open the screen 
		local ws_onContractClicked = obj.onContractClicked;
		obj.onContractClicked = function( _data )
		{
			if (this.isAnimating())
			{
				return;
			}

			if (typeof _data == "string" && _data == "POKEBRO")
			{
				showPokebroPcDialog();
			}
			else
			{
				ws_onContractClicked(_data);
			}
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
});




