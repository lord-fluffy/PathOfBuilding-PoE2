describe("TestFistsOfStone", function()
	local STONEFIST = 39595

	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function equip(raw)
		build.itemsTab:CreateDisplayItemFromRaw(raw)
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
	end

	local function allocateStonefist()
		local node = build.spec.nodes[STONEFIST]
		build.spec.allocNodes[STONEFIST] = node
		build.buildFlag = true
		runCallback("OnFrame")
	end

	local function wornLines()
		local lines = { }
		for _, modLine in ipairs(build.calcsTab.mainEnv.player.itemList["Gloves"].explicitModLines) do
			lines[modLine.line] = true
		end
		return lines
	end

	it("reads the passive's lines", function()
		local node = build.spec.nodes[STONEFIST]
		assert.are.equals("Way of the Stonefist", node.dn)
		for _, mod in ipairs(node.mods) do
			assert.is_nil(mod.extra)
		end
		assert.is_true(node.modList:Flag(nil, "GlovesBecomeFistsOfStone"))
	end)

	it("leaves gloves alone without the passive", function()
		equip("Rarity: RARE\nTest\nStocky Mitts\n+50 to maximum Life")
		assert.are.equals("Stocky Mitts", build.calcsTab.mainEnv.player.itemList["Gloves"].baseName)
	end)

	it("swaps the base and turns a modifier into its twin", function()
		equip("Rarity: RARE\nTest\nStocky Mitts\n+50 to maximum Life")
		local life = build.calcsTab.mainEnv.modDB:Sum("BASE", nil, "Life")
		allocateStonefist()
		local worn = build.calcsTab.mainEnv.player.itemList["Gloves"]
		assert.are.equals("Fists of Stone", worn.baseName)
		assert.are.equals(life - 50, build.calcsTab.mainEnv.modDB:Sum("BASE", nil, "Life"))
		assert.is_true(worn.armourData.EvasionPerLevel > 0)
		-- the stored item is untouched: it reverts when taken off
		assert.are.equals("Stocky Mitts", build.itemsTab.items[build.itemsTab.slots["Gloves"].selItemId].baseName)
	end)

	it("carries the roll over and keeps the tier", function()
		-- IncreasedLife1 is +(10-19): 10 is the bottom of its range, and its twin has one value
		equip("Rarity: RARE\nTest\nStocky Mitts\n+10 to maximum Life")
		allocateStonefist()
		assert.is_true(wornLines()["5% less damage taken while on Low Life"])
	end)

	it("reads a hybrid modifier as one", function()
		equip("Rarity: RARE\nTest\nStocky Mitts\n10% increased Armour\n+10 to maximum Life")
		allocateStonefist()
		local lines = wornLines()
		assert.is_true(lines["3% of Damage Taken Recouped as Life, Mana and Energy Shield"])
		assert.is_nil(lines["10% increased Armour"])
		assert.is_nil(lines["+10 to maximum Life"])
	end)

	it("keeps lines that have no twin", function()
		equip("Rarity: RARE\nTest\nStocky Mitts\nNot a modifier of this game")
		allocateStonefist()
		assert.is_true(wornLines()["Not a modifier of this game"])
	end)

	it("converts a unique by its own modifiers", function()
		equip("Rarity: UNIQUE\nGrip of Winter\nFirm Bracers\nAttacks Gain 5% of Damage as Extra Cold Damage\n120% increased Armour and Evasion")
		allocateStonefist()
		local worn = build.calcsTab.mainEnv.player.itemList["Gloves"]
		assert.are.equals("Fists of Stone", worn.baseName)
		assert.are.equals("Grip of Winter", worn.title)
	end)

	it("removes modifiers whose twin has no stats", function()
		equip("Rarity: UNIQUE\nPainter's Servant\nTorn Gloves\n33% of Elemental Damage Converted to Cold Damage\n33% of Elemental Damage Converted to Fire Damage\n33% of Elemental Damage Converted to Lightning Damage")
		allocateStonefist()
		local lines = wornLines()
		assert.is_nil(lines["33% of Elemental Damage Converted to Cold Damage"])
		assert.is_nil(lines["33% of Elemental Damage Converted to Lightning Damage"])
		assert.is_true(lines["Physical damage from Hits Contributes to Flammability and"])
	end)

	it("doesn't touch gloves that already read Fists of Stone", function()
		equip("Rarity: RARE\nTest\nFists of Stone\n+10% to Quality of all Skills")
		local item = build.itemsTab.items[build.itemsTab.slots["Gloves"].selItemId]
		assert.are.equals(item, itemLib.fistsOfStone(item))
	end)
end)
