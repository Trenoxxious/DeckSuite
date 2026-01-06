local MAX_RECENTS = 5

function DeckSuite_AddRecentWhisper(name, message)
	if not name or name == "" then return end

	local short = name:gsub("%-.+$", "")
	message = message or ""

	for i = 1, #DeckSuiteWhispers do
		if DeckSuiteWhispers[i].name == short then
			table.remove(DeckSuiteWhispers, i)
			break
		end
	end

	table.insert(DeckSuiteWhispers, 1, {name = short, message = message})

	while #DeckSuiteWhispers > MAX_RECENTS do
		table.remove(DeckSuiteWhispers)
	end

	if DeckSuiteReplyFrame and DeckSuiteReplyFrame:IsShown() and DeckSuiteReplyFrame.Update then
		DeckSuiteReplyFrame:Update()
	end
end
