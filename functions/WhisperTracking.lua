local MAX_RECENTS = 5

function DeckSuite_AddRecentWhisper(name, message)
	if not name or name == "" then return end

	local short = name:gsub("%-.+$", "")
	message = message or ""

	for i = 1, #NoxxDeckSuiteWhispers do
		if NoxxDeckSuiteWhispers[i].name == short then
			table.remove(NoxxDeckSuiteWhispers, i)
			break
		end
	end

	table.insert(NoxxDeckSuiteWhispers, 1, {name = short, message = message})

	while #NoxxDeckSuiteWhispers > MAX_RECENTS do
		table.remove(NoxxDeckSuiteWhispers)
	end

	if DeckSuiteReplyFrame and DeckSuiteReplyFrame:IsShown() and DeckSuiteReplyFrame.Update then
		DeckSuiteReplyFrame:Update()
	end
end
