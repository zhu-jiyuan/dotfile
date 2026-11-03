-- Print the tabs for tabfind.sh, pinned first, then whatever needs you.
-- Fields, split by tabs: session_id, window_id, block_id, title, session,
-- state, plain title. block_id is the pane to preview.
-- A script for `rex do`: only scripts can attach to other sessions, so this
-- can't be part of the action in tabfind.lua.

local TERMINAL = "com.superlogical.terminal"
local current_session = os.getenv("REX_SESSION")
local own_block = os.getenv("REX_BLOCK")
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local PINS = state_home .. "/rex/tabfind-pins"

-- Program status mapped to its word and place in the list. Colours are exact
-- rather than the theme's, so they stay readable on the search area's own ground.
local DARK = (os.getenv("TABFIND_DARK") or "") ~= ""
local function rgb(light, dark)
	local c = DARK and dark or light
	return string.format("38;2;%d;%d;%d", c[1], c[2], c[3])
end
local ORANGE = rgb({ 168, 60, 12 }, { 255, 160, 110 })
local GREEN = rgb({ 86, 99, 0 }, { 190, 210, 90 })
local AMBER = rgb({ 111, 84, 0 }, { 230, 195, 90 })
local STATES = {
	blocked = { word = "waiting", color = ORANGE, rank = 1 },
	error = { word = "failed", color = ORANGE, rank = 2 },
	done = { word = "done", color = GREEN, rank = 3 },
	working = { word = "working", color = AMBER, rank = 4 },
}
local PINNED_RANK = 0
local PLAIN_RANK = 5

local function read_pins()
	local pins = {}
	local f = io.open(PINS, "r")
	if f ~= nil then
		for id in f:lines() do
			pins[id] = true
		end
		f:close()
	end
	return pins
end

-- Control characters would break the fields or the list's colours.
local function clean(text)
	return (text:gsub("%c", " "))
end

-- A tab's terminals, leaving out the floating pane this script runs in.
local function terminals(window)
	local blocks = {}
	for _, layer in ipairs(window.layers or {}) do
		for _, block in ipairs(layer.blocks or {}) do
			if block.creator_name == TERMINAL and block.block_id ~= own_block then
				blocks[#blocks + 1] = block.block_id
			end
		end
	end
	return blocks
end

-- The focused pane, or another one when focus is on the floating pane itself.
local function preview_block(window, blocks)
	for _, id in ipairs(blocks) do
		if id == window.focused_block_id then
			return id
		end
	end
	return blocks[1] or "none"
end

-- Each terminal's title, without repeats, so any pane in a tab can be searched.
local function pane_titles(session_id, blocks)
	local seen, titles = {}, {}
	for _, id in ipairs(blocks) do
		local r = rex.block.call(TERMINAL, "title", { session_id = session_id, block_id = id })
		local title = r and r.title
		if title and title ~= "" and not seen[title] then
			seen[title] = true
			titles[#titles + 1] = clean(title)
		end
	end
	return table.concat(titles, " | ")
end

-- The most urgent status across every pane in the tab.
local function tab_state(session_id, blocks)
	local best
	for _, id in ipairs(blocks) do
		local r = rex.block.call(TERMINAL, "program_status", { session_id = session_id, block_id = id })
		for _, record in ipairs(r and r.records or {}) do
			local state = STATES[record.state]
			if state and (best == nil or state.rank < best.rank) then
				best = state
			end
		end
	end
	return best
end

-- Rex names unlabelled tabs "Window <id>", which is no use to search on.
local function tab_title(window, titles)
	local label = clean(window.label or "")
	if label ~= "" and not label:match("^Window %x+$") then
		return label
	end
	return titles ~= "" and titles or "shell"
end

local listed, err = rex.call("session.list")
if listed == nil then
	error(err, 0)
end

local sessions = {}
for _, s in ipairs(listed.sessions) do
	table.insert(sessions, s.session_id == current_session and 1 or #sessions + 1, s)
end

local pins = read_pins()
local rows = {}
for _, s in ipairs(sessions) do
	if s.session_id ~= current_session then
		local _, attach_err = rex.session.attach({ session_id = s.session_id })
		if attach_err ~= nil then
			error(attach_err, 0)
		end
	end
	local view, view_err = rex.session.view({ session_id = s.session_id })
	if view == nil then
		error(view_err, 0)
	end
	for _, w in ipairs(view.windows) do
		local blocks = terminals(w)
		local title = tab_title(w, pane_titles(s.session_id, blocks))
		local state = tab_state(s.session_id, blocks)
		local pinned = pins[w.window_id]

		local words = {}
		if pinned then
			words[#words + 1] = "\27[1mpinned\27[0m"
		end
		if state then
			words[#words + 1] = "\27[1;" .. state.color .. "m" .. state.word .. "\27[0m"
		end

		rows[#rows + 1] = {
			rank = pinned and PINNED_RANK or (state and state.rank or PLAIN_RANK),
			order = #rows,
			line = table.concat({
				s.session_id,
				w.window_id,
				preview_block(w, blocks),
				"\27[1m" .. title .. "\27[0m",
				clean(s.label or ""),
				table.concat(words, "  "),
				title,
			}, "\t"),
		}
	end
end

table.sort(rows, function(a, b)
	if a.rank ~= b.rank then
		return a.rank < b.rank
	end
	return a.order < b.order
end)

for _, row in ipairs(rows) do
	io.write(row.line, "\n")
end
