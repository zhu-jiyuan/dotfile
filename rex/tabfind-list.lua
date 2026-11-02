-- Print the tabs for tabfind.sh, grouped: pinned first, then this session, then
-- the others, each group under a heading row and the tabs that need you first.
-- Fields, split by tabs:
--    1 kind: h for a heading, t for a tab
--    2 heading text          3 tab text
--    4 session_id            5 window_id (a heading gets an id of its own)
--    6 block to preview      7 title
--    8 session label         9 directory as shown
--   10 status word          11 directory
--   12 preview label
-- fzf shows fields 2 and 3 and searches only 3, so headings drop out of a search.
-- A script for `rex do`: only scripts can attach to other sessions, so this
-- can't be part of the action in tabfind.lua.

local TERMINAL = "com.superlogical.terminal"
local PANEL_LABEL = "tabfind" -- Set on the floating pane by tabfind.lua.
local current_session = os.getenv("REX_SESSION")
local origin_block = os.getenv("TABFIND_ORIGIN_BLOCK")
local home = os.getenv("HOME") or ""
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local PINS = state_home .. "/rex/tabfind-pins"
-- Columns the list has for a row, set by tabfind.sh from the panel's size.
local WIDTH = tonumber(os.getenv("TABFIND_LIST_COLS") or "") or 60
-- fzf turns the tab before a tab row's text into this many spaces (--tabstop).
local INDENT = 2

-- Colours are exact rather than the theme's, so they stay readable on the
-- list's own ground.
local DARK = (os.getenv("TABFIND_DARK") or "") ~= ""
local function rgb(light, dark)
	local c = DARK and dark or light
	return string.format("38;2;%d;%d;%d", c[1], c[2], c[3])
end
local DIM = rgb({ 79, 99, 105 }, { 163, 166, 172 })
local RULE = rgb({ 207, 198, 174 }, { 85, 88, 94 })
local ORANGE = rgb({ 168, 60, 12 }, { 255, 160, 110 })
local GREEN = rgb({ 86, 99, 0 }, { 190, 210, 90 })
local AMBER = rgb({ 111, 84, 0 }, { 230, 195, 90 })
local ACCENT = rgb({ 11, 95, 152 }, { 124, 192, 238 })

-- Program status mapped to its mark, word and place in a group.
local STATES = {
	blocked = { glyph = "●", word = "waiting", color = ORANGE, rank = 1 },
	error = { glyph = "✗", word = "failed", color = ORANGE, rank = 2 },
	done = { glyph = "✓", word = "done", color = GREEN, rank = 3 },
	working = { glyph = "◐", word = "working", color = AMBER, rank = 4 },
}
local PLAIN_RANK = 5
local PIN_GLYPH = "󰐃" -- Nerd Font pin, one column wide in a Mono font.
local RIGHT = 7 -- The status column, or the session in the pinned group.

local function paint(color, text, bold)
	return "\27[" .. (bold and "1;" or "") .. color .. "m" .. text .. "\27[0m"
end

-- Each character with the columns it takes, 2 for CJK and other wide ones.
-- Lua 5.1 has no utf8 library, so the decoding is by hand.
local function char_width(cp)
	if (cp >= 0x300 and cp <= 0x36F) or (cp >= 0x200B and cp <= 0x200F) or (cp >= 0xFE00 and cp <= 0xFE0F) then
		return 0
	end
	if
		(cp >= 0x1100 and cp <= 0x115F)
		or (cp >= 0x2E80 and cp <= 0xA4CF)
		or (cp >= 0xAC00 and cp <= 0xD7A3)
		or (cp >= 0xF900 and cp <= 0xFAFF)
		or (cp >= 0xFE30 and cp <= 0xFE4F)
		or (cp >= 0xFF00 and cp <= 0xFF60)
		or (cp >= 0xFFE0 and cp <= 0xFFE6)
		or (cp >= 0x1F300 and cp <= 0x1F64F)
		or (cp >= 0x1F900 and cp <= 0x1F9FF)
		or (cp >= 0x20000 and cp <= 0x3FFFD)
	then
		return 2
	end
	return 1
end

local function chars(text)
	local list, i = {}, 1
	while i <= #text do
		local c = text:byte(i)
		local len = (c < 0xC0 and 1) or (c < 0xE0 and 2) or (c < 0xF0 and 3) or 4
		local cp = len == 1 and c or c % (2 ^ (7 - len))
		for k = 1, len - 1 do
			cp = cp * 64 + (text:byte(i + k) or 128) % 64
		end
		list[#list + 1] = { text:sub(i, i + len - 1), char_width(cp) }
		i = i + len
	end
	return list
end

local function width_of(text)
	local w = 0
	for _, c in ipairs(chars(text)) do
		w = w + c[2]
	end
	return w
end

-- Exactly w columns: padded, or cut with an ellipsis. from_end keeps the end,
-- the part of a path that tells directories apart.
local function fit(text, w, from_end)
	if w <= 0 then
		return ""
	end
	local list = chars(text)
	local total = 0
	for _, c in ipairs(list) do
		total = total + c[2]
	end
	if total <= w then
		return text .. string.rep(" ", w - total)
	end
	local kept, used = {}, 0
	local first, last, step = 1, #list, 1
	if from_end then
		first, last, step = #list, 1, -1
	end
	for i = first, last, step do
		if used + list[i][2] > w - 1 then
			break
		end
		table.insert(kept, from_end and 1 or #kept + 1, list[i][1])
		used = used + list[i][2]
	end
	local body = table.concat(kept)
	return (from_end and ("…" .. body) or (body .. "…")) .. string.rep(" ", w - used - 1)
end

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
			if block.creator_name == TERMINAL and block.label ~= PANEL_LABEL then
				blocks[#blocks + 1] = block.block_id
			end
		end
	end
	return blocks
end

-- The pane the panel was opened from, else the focused pane. In the panel's own
-- tab focus is on the panel, so only the first of those can find the right pane.
local function preview_block(window, blocks)
	local focused
	for _, id in ipairs(blocks) do
		if id == origin_block then
			return id
		end
		if id == window.focused_block_id then
			focused = id
		end
	end
	return focused or blocks[1]
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

local function unescape_url(path)
	return (path:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

-- Where the pane is: what its shell reported (OSC 7), else where its foreground
-- program runs, since many shells never report.
local function directory(session_id, block_id)
	if block_id == nil then
		return ""
	end
	local args = { session_id = session_id, block_id = block_id }
	local r = rex.block.call(TERMINAL, "pwd", args)
	local dir = r and r.pwd
	if dir then
		dir = unescape_url((dir:gsub("^file://[^/]*", "")))
	else
		local p = rex.block.call(TERMINAL, "process", args)
		dir = p and ((p.foreground and p.foreground.cwd) or (p.ancestors and p.ancestors[1] and p.ancestors[1].cwd))
	end
	return clean(dir or "")
end

local function short_dir(dir)
	if home ~= "" and dir:sub(1, #home) == home and (#dir == #home or dir:sub(#home + 1, #home + 1) == "/") then
		return "~" .. dir:sub(#home + 1)
	end
	return dir
end

-- Rex names unlabelled tabs "Window <id>", which is no use to search on.
local function tab_title(window, titles)
	local label = clean(window.label or "")
	if label ~= "" and not label:match("^Window %x+$") then
		return label
	end
	return titles ~= "" and titles or "shell"
end

-- One session's tabs. A session closing while this runs just has no tabs.
local function session_windows(s)
	if s.session_id ~= current_session and select(2, rex.session.attach({ session_id = s.session_id })) ~= nil then
		return {}
	end
	local view = rex.session.view({ session_id = s.session_id })
	return view and view.windows or {}
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
local tabs = {}
for _, s in ipairs(sessions) do
	local session_label = clean(s.label or "")
	for _, w in ipairs(session_windows(s)) do
		local blocks = terminals(w)
		local block = preview_block(w, blocks)
		tabs[#tabs + 1] = {
			session = s,
			session_label = session_label,
			window = w,
			block = block,
			title = tab_title(w, pane_titles(s.session_id, blocks)),
			state = tab_state(s.session_id, blocks),
			pinned = pins[w.window_id],
			dir = directory(s.session_id, block),
			order = #tabs,
		}
	end
end

-- The columns of a tab row, after its indent.
local row_width = WIDTH - INDENT
local dir_width = math.min(20, math.floor(row_width * 0.25))
local title_width = row_width - 2 - 2 - dir_width - 2 - RIGHT
if title_width < 12 then
	title_width = title_width + dir_width + 2
	dir_width = 0
end

local function tab_line(t, in_pinned)
	local state = t.state
	local glyph = " "
	if state then
		glyph = paint(state.color, state.glyph, true)
	elseif t.pinned then
		glyph = paint(ACCENT, PIN_GLYPH, true)
	end
	local right
	if in_pinned then
		right = paint(DIM, fit(t.session_label, RIGHT))
	elseif state then
		right = paint(state.color, string.rep(" ", RIGHT - #state.word) .. state.word)
	else
		right = string.rep(" ", RIGHT)
	end
	local shown_dir = short_dir(t.dir)
	local parts = { glyph, " ", fit(t.title, title_width), "  " }
	if dir_width > 0 then
		parts[#parts + 1] = paint(DIM, fit(shown_dir, dir_width, true))
		parts[#parts + 1] = "  "
	end
	parts[#parts + 1] = right

	local label = " " .. t.title .. " · " .. t.session_label .. (shown_dir ~= "" and (" · " .. shown_dir) or "") .. " "
	return table.concat({
		"t",
		"",
		table.concat(parts),
		t.session.session_id,
		t.window.window_id,
		t.block or "none",
		t.title,
		t.session_label,
		shown_dir,
		state and state.word or "",
		t.dir,
		label,
	}, "\t")
end

local function heading_line(id, name, tag, count)
	local text = paint(DIM, name, true) .. (tag ~= "" and paint(DIM, tag) or "")
	local count_text = tostring(count)
	local fill = WIDTH - width_of(name .. tag) - 2 - #count_text
	return table.concat({
		"h",
		text .. " " .. paint(RULE, string.rep("┈", math.max(fill, 1))) .. " " .. paint(DIM, count_text),
		"",
		"-",
		id,
		"-",
		"",
		"",
		"",
		"",
		"",
		"",
	}, "\t")
end

local function by_urgency(a, b)
	local ra = a.state and a.state.rank or PLAIN_RANK
	local rb = b.state and b.state.rank or PLAIN_RANK
	if ra ~= rb then
		return ra < rb
	end
	return a.order < b.order
end

local function emit_group(id, name, tag, members, in_pinned)
	if #members == 0 then
		return
	end
	table.sort(members, by_urgency)
	io.write(heading_line(id, name, tag, #members), "\n")
	for _, t in ipairs(members) do
		io.write(tab_line(t, in_pinned), "\n")
	end
end

local pinned = {}
for _, t in ipairs(tabs) do
	if t.pinned then
		pinned[#pinned + 1] = t
	end
end
emit_group("group:pinned", "pinned", "", pinned, true)

for _, s in ipairs(sessions) do
	local members = {}
	for _, t in ipairs(tabs) do
		if t.session == s and not t.pinned then
			members[#members + 1] = t
		end
	end
	local tag = s.session_id == current_session and " · this session" or ""
	emit_group("group:" .. s.session_id, clean(s.label or s.session_id), tag, members, false)
end
