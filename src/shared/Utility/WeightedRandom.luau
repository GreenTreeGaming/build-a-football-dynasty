--!strict

local WeightedRandom = {}

function WeightedRandom.pickUnique(
	items: { any },
	count: number,
	getWeight: (any) -> number,
	randomGenerator: Random?
): { any }
	assert(count >= 0, "count must not be negative")

	local random = randomGenerator or Random.new()
	local pool = table.clone(items)
	local result = table.create(math.min(count, #pool))

	local amountToSelect = math.min(count, #pool)

	for _ = 1, amountToSelect do
		local totalWeight = 0

		for _, item in ipairs(pool) do
			local weight = getWeight(item)

			assert(
				typeof(weight) == "number"
					and weight > 0
					and weight == weight,
				"Every weighted item must have a positive finite weight"
			)

			totalWeight += weight
		end

		local target = random:NextNumber(0, totalWeight)
		local accumulatedWeight = 0
		local selectedIndex = #pool

		for index, item in ipairs(pool) do
			accumulatedWeight += getWeight(item)

			if target <= accumulatedWeight then
				selectedIndex = index
				break
			end
		end

		local selectedItem = table.remove(pool, selectedIndex)
		table.insert(result, selectedItem)
	end

	return result
end

return table.freeze(WeightedRandom)