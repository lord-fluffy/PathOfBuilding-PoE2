describe("TestMetaEnergy", function()
	before_each(function()
		newBuild()
		-- a skill that Critically Hits, outside the meta gem, to build Energy
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nMarauding Mace")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Boneshatter 20/0  1")
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function triggered(group, customMods)
		build.skillsTab:PasteSocketGroup(group)
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.skillsTab.socketGroupList[build.mainSocketGroup].mainActiveSkill = 2
		build.configTab.input.customMods = customMods or ""
		build.configTab:BuildModList()
		runCallback("OnFrame")
		return build.calcsTab.mainOutput
	end

	it("gives Cast on Critical 1 maximum Energy per 10 ms of its Spells' base cast time", function()
		assert.are.equals(120, triggered("Cast on Critical 20/0  1\nFireball 20/0  1").MetaMaximumEnergy)    -- 1.2 s
		newBuild()
		assert.are.equals(120 + 80, triggered("Cast on Critical 20/0  1\nFireball 20/0  1\nFrostbolt 20/0  1").MetaMaximumEnergy)
	end)

	it("triggers socketed Spells at the rate Critical Hits fill Energy, not at cast speed", function()
		local output = triggered("Cast on Critical 20/0  1\nFireball 20/0  1", "+100% to Critical Hit Chance")
		assert.True(output.MetaSourceCritRate > 0)
		assert.True(output.MetaEnergyPerCrit > 0)
		assert.are.equals(math.ceil(output.MetaMaximumEnergy / output.MetaEnergyPerCrit), output.MetaCritsToTrigger)
		assert.True(math.abs(output.MetaTriggerRate - output.MetaSourceCritRate / output.MetaCritsToTrigger) < 1e-9)
		assert.True(math.abs(output.Speed - output.MetaTriggerRate) < 1e-9)
	end)

	it("scales Energy gained with increased Energy, including the tree's Meta Skill lines", function()
		local base = triggered("Cast on Critical 20/0  1\nFireball 20/0  1", "+100% to Critical Hit Chance").MetaEnergyPerCrit
		local more = triggered("Cast on Critical 20/0  1\nFireball 20/0  1", "+100% to Critical Hit Chance\nMeta Skills gain 100% increased Energy").MetaEnergyPerCrit
		assert.True(math.abs(more - base * 2) <= 0.01)
	end)

	it("does not trigger without a skill that Critically Hits", function()
		newBuild()
		local output = triggered("Cast on Critical 20/0  1\nFireball 20/0  1")
		assert.are.equals(0, output.MetaTriggerRate)
		assert.are.equals(0, output.TotalDPS)
	end)
end)
