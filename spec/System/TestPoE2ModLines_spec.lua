describe("TestPoE2ModLines", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function outputWith(customMods)
		build.configTab.input.customMods = customMods
		build.configTab:BuildModList()
		runCallback("OnFrame")
		return build.calcsTab.mainOutput
	end

	local function near(a, b)
		return math.abs(a - b) < 0.01
	end

	it("Adaptive Skin raises maximum resistances of elements you were hit with recently", function()
		build.configTab.input.conditionHitByFireDamageRecently = true
		local base = outputWith("+200% to Fire Resistance\n+200% to Cold Resistance")
		local output = outputWith("+200% to Fire Resistance\n+200% to Cold Resistance\n+1% to Maximum Resistances of each Elemental Damage Type you have been Hit with Recently")
		assert.are.equals(base.FireResist + 1, output.FireResist)
		assert.are.equals(base.ColdResist, output.ColdResist)
	end)

	it("Vaal Pact leeches Life 67% less quickly", function()
		local base = outputWith("").LifeLeechInstanceRate
		assert.True(base > 0)
		assert.True(near(outputWith("Leech Life 67% less quickly").LifeLeechInstanceRate, base * 0.33))
	end)

	it("parses Mana Leech slower", function()
		local base = outputWith("").ManaLeechInstanceRate
		assert.True(base > 0)
		assert.True(near(outputWith("Leech Mana 50% slower").ManaLeechInstanceRate, base * 0.5))
	end)

	it("grants Onslaught during a charm's effect", function()
		local base = outputWith("").Speed
		assert.True(outputWith("Grants Onslaught during effect").Speed > base)
	end)

	it("grants maximum Rage after using a Glory skill", function()
		local rage = "Gain 1 Rage when you kill an enemy\n"
		local line = "+15 maximum Rage if you've used a Skill that Requires Glory in the past 20 seconds"
		local base = outputWith(rage).MaximumRage
		assert.True(base > 0)
		assert.are.equals(base, outputWith(rage .. line).MaximumRage)
		build.configTab.input.conditionUsedGlorySkillRecently = true
		assert.are.equals(base + 15, outputWith(rage .. line).MaximumRage)
	end)

	it("parses Mana Cost Efficiency of Spells", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		local base = outputWith("").ManaCost
		assert.True(base > 0)
		assert.True(outputWith("50% increased Mana Cost Efficiency of Spells").ManaCost < base)
	end)

	it("parses Magnitudes of Non-Curse Auras", function()
		build.skillsTab:PasteSocketGroup("Discipline 20/0  1")
		build.mainSocketGroup = 1
		local base = outputWith("").EnergyShield
		assert.True(outputWith("50% increased Magnitudes of Non-Curse Auras from your Skills").EnergyShield > base)
	end)

	it("doubles the Totem limit with Ancestral Bond", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nMarauding Mace")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Shockwave Totem 20/0  1")
		local base = outputWith("").ActiveTotemLimit
		assert.True(base > 0)
		assert.are.equals(base * 2, outputWith("Your Totem Limit is doubled").ActiveTotemLimit)
	end)
end)
