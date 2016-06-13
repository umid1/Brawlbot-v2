-- utilities.lua
-- Functions shared among plugins.

local utilities = {}

local HTTP = require('socket.http')
local ltn12 = require('ltn12')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local serpent = require("serpent")
local bindings = require('otouto.bindings')
local redis = (loadfile "./otouto/redis.lua")()
local mimetype = (loadfile "./otouto/mimetype.lua")()

 -- For the sake of ease to new contributors and familiarity to old contributors,
 -- we'll provide a couple of aliases to real bindings here.
function utilities:send_message(chat_id, text, disable_web_page_preview, reply_to_message_id, use_markdown)
	return bindings.request(self, 'sendMessage', {
		chat_id = chat_id,
		text = text,
		disable_web_page_preview = disable_web_page_preview,
		reply_to_message_id = reply_to_message_id,
		parse_mode = use_markdown and 'Markdown' or nil
	} )
end

function utilities:send_reply(old_msg, text, use_markdown)
	return bindings.request(self, 'sendMessage', {
		chat_id = old_msg.chat.id,
		text = text,
		disable_web_page_preview = true,
		reply_to_message_id = old_msg.message_id,
		parse_mode = use_markdown and 'Markdown' or nil
	} )
end

-- NOTE: Telegram currently only allows file uploads up to 50 MB
-- https://core.telegram.org/bots/api#sendphoto
function utilities:send_photo(chat_id, file, text, reply_to_message_id)
	local output = bindings.request(self, 'sendPhoto', {
		chat_id = chat_id,
		caption = text or nil,
		reply_to_message_id = reply_to_message_id
	}, {photo = file} )
	os.remove(file)
	print("Deleted: "..file)
	return output
end

-- https://core.telegram.org/bots/api#sendaudio
function utilities:send_audio(chat_id, file, text, reply_to_message_id, duration, performer, title)
	local output = bindings.request(self, 'sendAudio', {
		chat_id = chat_id,
		caption = text or nil,
		duration = duration or nil,
		performer = performer or nil,
		title = title or nil,
		reply_to_message_id = reply_to_message_id
	}, {audio = file} )
	os.remove(file)
	print("Deleted: "..file)
	return output
end

-- https://core.telegram.org/bots/api#senddocument
function utilities:send_document(chat_id, file, text, reply_to_message_id)
	local output = bindings.request(self, 'sendDocument', {
		chat_id = chat_id,
		caption = text or nil,
		reply_to_message_id = reply_to_message_id
	}, {document = file} )
	os.remove(file)
	print("Deleted: "..file)
	return output
end

-- https://core.telegram.org/bots/api#sendvideo
function utilities:send_video(chat_id, file, text, reply_to_message_id, duration, width, height)
	local output = bindings.request(self, 'sendVideo', {
		chat_id = chat_id,
		caption = text or nil,
		duration = duration or nil,
		width = width or nil,
		height = height or nil,
		reply_to_message_id = reply_to_message_id
	}, {video = file} )
	os.remove(file)
	print("Deleted: "..file)
	return output
end

-- NOTE: Voice messages are .ogg files encoded with OPUS
-- https://core.telegram.org/bots/api#sendvoice
function utilities:send_voice(chat_id, file, text, reply_to_message_id, duration)
	local output = bindings.request(self, 'sendVoice', {
		chat_id = chat_id,
		duration = duration or nil,
		reply_to_message_id = reply_to_message_id
	}, {voice = file} )
	os.remove(file)
	print("Deleted: "..file)
	return output
end

-- https://core.telegram.org/bots/api#sendlocation
function utilities:send_location(chat_id, latitude, longitude, reply_to_message_id)
	return bindings.request(self, 'sendLocation', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		reply_to_message_id = reply_to_message_id
	} )
end

-- NOTE: Venue is different from location: it shows information, such as the street adress or
-- title of the location with it.
-- https://core.telegram.org/bots/api#sendvenue
function utilities:send_venue(chat_id, latitude, longitude, reply_to_message_id, title, address)
	return bindings.request(self, 'sendVenue', {
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude,
		title = title,
		address = address,
		reply_to_message_id = reply_to_message_id
	} )
end

-- https://core.telegram.org/bots/api#sendchataction
function utilities:send_typing(chat_id, action)
	return bindings.request(self, 'sendChatAction', {
		chat_id = chat_id,
		action = action
	} )
end

 -- get the indexed word in a string
function utilities.get_word(s, i)
	s = s or ''
	i = i or 1
	local t = {}
	for w in s:gmatch('%g+') do
		table.insert(t, w)
	end
	return t[i] or false
end

 -- Like get_word(), but better.
 -- Returns the actual index.
function utilities.index(s)
	local t = {}
	for w in s:gmatch('%g+') do
		table.insert(t, w)
	end
	return t
end

 -- Returns the string after the first space.
function utilities.input(s)
	if not s:find(' ') then
		return false
	end
	return s:sub(s:find(' ')+1)
end

-- Calculates the length of the given string as UTF-8 characters
function utilities.utf8_len(s)
    local chars = 0
    for i = 1, string.len(s) do
        local b = string.byte(s, i)
        if b < 128 or b >= 192 then
            chars = chars + 1
        end
    end
    return chars
end

 -- I swear, I copied this from PIL, not yago! :)
function utilities.trim(str) -- Trims whitespace from a string.
	local s = str:gsub('^%s*(.-)%s*$', '%1')
	return s
end

local lc_list = {
-- Latin = 'Cyrillic'
	['A'] = 'А',
	['B'] = 'В',
	['C'] = 'С',
	['E'] = 'Е',
	['I'] = 'І',
	['J'] = 'Ј',
	['K'] = 'К',
	['M'] = 'М',
	['H'] = 'Н',
	['O'] = 'О',
	['P'] = 'Р',
	['S'] = 'Ѕ',
	['T'] = 'Т',
	['X'] = 'Х',
	['Y'] = 'Ү',
	['a'] = 'а',
	['c'] = 'с',
	['e'] = 'е',
	['i'] = 'і',
	['j'] = 'ј',
	['o'] = 'о',
	['s'] = 'ѕ',
	['x'] = 'х',
	['y'] = 'у',
	['!'] = 'ǃ'
}

-- http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
function run_command(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

function string.starts(String, Start)
   return Start == string.sub(String,1,string.len(Start))
end

function get_http_file_name(url, headers)
  -- Eg: fooo.var
  local file_name = url:match("[^%w]+([%.%w]+)$")
  -- Any delimited aphanumeric on the url
  file_name = file_name or url:match("[^%w]+(%w+)[^%w]+$")
  -- Random name, hope content-type works
  file_name = file_name or str:random(5)

  local content_type = headers["content-type"] 
  
  local extension = nil
  if content_type then
    extension = mimetype.get_mime_extension(content_type) 
  end

  if extension then
    file_name = file_name.."."..extension
  end
  
  local disposition = headers["content-disposition"]
  if disposition then
    -- attachment; filename=CodeCogsEqn.png
    file_name = disposition:match('filename=([^;]+)') or file_name
	file_name = string.gsub(file_name, "\"", "")
  end
  
  return file_name
end

-- Saves file to $HOME/tmp/. If file_name isn't provided,
-- will get the text after the last "/" for filename
-- and content-type for extension
function download_to_file(url, file_name)
  print("url to download: "..url)

  local respbody = {}
  local options = {
    url = url,
    sink = ltn12.sink.table(respbody),
    redirect = true
 }

  -- nil, code, headers, status
  local response = nil

  if string.starts(url, 'https') then
    options.redirect = false
    response = {HTTPS.request(options)}
  else
    response = {HTTP.request(options)}
  end

  local code = response[2]
  local headers = response[3]
  local status = response[4]

  if code ~= 200 then return nil end

  file_name = file_name or get_http_file_name(url, headers)

 local file_path = "/home/anditest/tmp/telegram-bot/"..file_name
 print("Saved to: "..file_path)
 
  file = io.open(file_path, "w+")
  file:write(table.concat(respbody))
  file:close()

  return file_path
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

 -- Replaces letters with corresponding Cyrillic characters.
function utilities.latcyr(str)
	for k,v in pairs(lc_list) do
		str = str:gsub(k, v)
	end
	return str
end

 -- Loads a JSON file as a table.
function utilities.load_data(filename)
	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)
	return data
end

 -- Saves a table to a JSON file.
function utilities.save_data(filename, data)
	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()
end

 -- Gets coordinates for a location. Used by gMaps.lua, time.lua, weather.lua.
function utilities.get_coords(input, config)

	local url = 'http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input)

	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		return config.errors.connection
	end

	local jdat = JSON.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		return config.errors.results
	end

	return {
		lat = jdat.results[1].geometry.location.lat,
		lon = jdat.results[1].geometry.location.lng
	}

end

 -- Get the number of values in a key/value table.
function utilities.table_size(tab)
	local i = 0
	for _,_ in pairs(tab) do
		i = i + 1
	end
	return i
end

 -- Just an easy way to get a user's full name.
 -- Alternatively, abuse it to concat two strings like I do.
function utilities.build_name(first, last)
	if last then
		return first .. ' ' .. last
	else
		return first
	end
end

function utilities:resolve_username(input)
	input = input:gsub('^@', '')
	for _,v in pairs(self.database.users) do
		if v.username and v.username:lower() == input:lower() then
			return v
		end
	end
end

function utilities:user_from_message(msg, no_extra)

	local input = utilities.input(msg.text_lower)
	local target = {}
	if msg.reply_to_message then
		for k,v in pairs(self.database.users[msg.reply_to_message.from.id_str]) do
			target[k] = v
		end
	elseif input and tonumber(input) then
		target.id = tonumber(input)
		if self.database.users[input] then
			for k,v in pairs(self.database.users[input]) do
				target[k] = v
			end
		end
	elseif input and input:match('^@') then
		local uname = input:gsub('^@', '')
		for _,v in pairs(self.database.users) do
			if v.username and uname == v.username:lower() then
				for key, val in pairs(v) do
					target[key] = val
				end
			end
		end
		if not target.id then
			target.err = 'Sorry, I don\'t recognize that username.'
		end
	else
		target.err = 'Please specify a user via reply, ID, or username.'
	end

	if not no_extra then
		if target.id then
			target.id_str = tostring(target.id)
		end
		if not target.first_name then
			target.first_name = 'User'
		end
		target.name = utilities.build_name(target.first_name, target.last_name)
	end

	return target

end

function utilities:handle_exception(err, message, config)

	if not err then err = '' end

	local output = '\n[' .. os.date('%F %T', os.time()) .. ']\n' .. self.info.username .. ': ' .. err .. '\n' .. message .. '\n'

	if config.log_chat then
		output = '```' .. output .. '```'
		utilities.send_message(self, config.log_chat, output, true, nil, true)
	else
		print(output)
	end

end

function utilities.download_file(url, filename)
	if not filename then
		filename = url:match('.+/(.-)$') or os.time()
		filename = '/tmp/' .. filename
	end
	local body = {}
	local doer = HTTP
	local do_redir = true
	if url:match('^https') then
		doer = HTTPS
		do_redir = false
	end
	local _, res = doer.request{
		url = url,
		sink = ltn12.sink.table(body),
		redirect = do_redir
	}
	if res ~= 200 then return false end
	local file = io.open(filename, 'w+')
	file:write(table.concat(body))
	file:close()
	return filename
end

function utilities.markdown_escape(text)
	text = text:gsub('_', '\\_')
	text = text:gsub('%[', '\\[')
	text = text:gsub('%]', '\\]')
	text = text:gsub('%*', '\\*')
	text = text:gsub('`', '\\`')
	return text
end

utilities.md_escape = utilities.markdown_escape

utilities.triggers_meta = {}
utilities.triggers_meta.__index = utilities.triggers_meta
function utilities.triggers_meta:t(pattern, has_args)
	local username = self.username:lower()
	table.insert(self.table, '^'..self.cmd_pat..pattern..'$')
	table.insert(self.table, '^'..self.cmd_pat..pattern..'@'..username..'$')
	if has_args then
		table.insert(self.table, '^'..self.cmd_pat..pattern..'%s+[^%s]*')
		table.insert(self.table, '^'..self.cmd_pat..pattern..'@'..username..'%s+[^%s]*')
	end
	return self
end

function utilities.triggers(username, cmd_pat, trigger_table)
	local self = setmetatable({}, utilities.triggers_meta)
	self.username = username
	self.cmd_pat = cmd_pat
	self.table = trigger_table or {}
	return self
end

function utilities.with_http_timeout(timeout, fun)
	local original = HTTP.TIMEOUT
	HTTP.TIMEOUT = timeout
	fun()
	HTTP.TIMEOUT = original
end

function utilities.enrich_user(user)
	user.id_str = tostring(user.id)
	user.name = utilities.build_name(user.first_name, user.last_name)
	return user
end

function utilities.enrich_message(msg)
	if not msg.text then msg.text = msg.caption or '' end
	msg.text_lower = msg.text:lower()
	msg.from = utilities.enrich_user(msg.from)
	msg.chat.id_str = tostring(msg.chat.id)
	if msg.reply_to_message then
		if not msg.reply_to_message.text then
			msg.reply_to_message.text = msg.reply_to_message.caption or ''
		end
		msg.reply_to_message.text_lower = msg.reply_to_message.text:lower()
		msg.reply_to_message.from = utilities.enrich_user(msg.reply_to_message.from)
		msg.reply_to_message.chat.id_str = tostring(msg.reply_to_message.chat.id)
	end
	if msg.forward_from then
		msg.forward_from = utilities.enrich_user(msg.forward_from)
	end
	if msg.new_chat_participant then
		msg.new_chat_participant = utilities.enrich_user(msg.new_chat_participant)
	end
	if msg.left_chat_participant then
		msg.left_chat_participant = utilities.enrich_user(msg.left_chat_participant)
	end
	return msg
end

function utilities.pretty_float(x)
	if x % 1 == 0 then
		return tostring(math.floor(x))
	else
		return tostring(x)
	end
end

function utilities:create_user_entry(user)
	local id = tostring(user.id)
	-- Clear things that may no longer exist, or create a user entry.
	if self.database.users[id] then
		self.database.users[id].username = nil
		self.database.users[id].last_name = nil
	else
		self.database.users[id] = {}
	end
	-- Add all the user info to the entry.
	for k,v in pairs(user) do
		self.database.users[id][k] = v
	end
end

 -- This table will store unsavory characters that are not properly displayed,
 -- or are just not fun to type.
utilities.char = {
	zwnj = '‌',
	arabic = '[\216-\219][\128-\191]',
	rtl_override = '‮',
	rtl_mark = '‏',
	em_dash = '—'
}

-- Returns a table with matches or nil
--function match_pattern(pattern, text, lower_case)
function match_pattern(pattern, text)
  if text then
    local matches = { string.match(text, pattern) }
    if next(matches) then
      return matches
	end
  end
  -- nil
end

function get_redis_hash(msg, var)
  if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
    return 'chat:'..msg.chat.id..':'..var
  end
  if msg.chat.type == 'private' then
    return 'user:'..msg.from.id..':'..var
  end
end

-- remove whitespace
function all_trim(s)
  return s:match( "^%s*(.-)%s*$" )
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function comma_value(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
    if (k==0) then
      break
    end
  end
  return formatted
end


function string.ends(str, fin)
  return fin=='' or string.sub(str,-string.len(fin)) == fin
end

function cache_data(plugin, query, data, timeout, typ)
  -- How to: cache_data(pluginname, query_name, data_to_cache, expire_in_seconds)
  local hash = 'telegram:cache:'..plugin..':'..query
  if timeout then
    print('Caching "'..query..'" from plugin '..plugin..' (expires in '..timeout..' seconds)')
  else
    print('Caching "'..query..'" from plugin '..plugin..' (expires never)')
  end
  if typ == 'key' then
    redis:set(hash, data)
  elseif typ == 'set' then
    -- make sure that you convert your data into a table:
	-- {"foo", "bar", "baz"} instead of
	-- {"bar" = "foo", "foo" = "bar", "bar" = "baz"}
	-- because other formats are not supported by redis (or I haven't found a way to store them)
    for _,str in pairs(data) do
	  redis:sadd(hash, str)
	end
  else
    redis:hmset(hash, data)
  end
  if timeout then
    redis:expire(hash, timeout)
  end
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.
-- http://lua-users.org/wiki/SortedIteration
]]

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

-- converts total amount of seconds (e.g. 65 seconds) to human redable time (e.g. 1:05 minutes)
function makeHumanTime(totalseconds)
  local seconds = totalseconds % 60
  local minutes = math.floor(totalseconds / 60)
  local minutes = minutes % 60
  local hours = math.floor(totalseconds / 3600)
  if minutes == 00 and hours == 00 then
    return seconds..' Sekunden'
  elseif hours == 00 and minutes ~= 00 then
    return string.format("%02d:%02d", minutes, seconds)..' Minuten'
  elseif hours ~= 00 then
    return string.format("%02d:%02d:%02d", hours,  minutes, seconds)..' Stunden'
  end
end

function is_blacklisted(msg)
  _blacklist = redis:smembers("telegram:img_blacklist")
  local var = false
  for v,word in pairs(_blacklist) do
    if string.find(string.lower(msg), string.lower(word)) then
      print("Wort steht auf der Blacklist!")
      var = true
      break
    end
  end
  return var
end

function unescape(str)
  str = string.gsub( str, '&lt;', '<' )
  str = string.gsub( str, '&gt;', '>' )
  str = string.gsub( str, '&quot;', '"' )
  str = string.gsub( str, '&apos;', "'" )
  str = string.gsub( str, "&Auml;", "Ä")
  str = string.gsub( str, "&auml;", "ä")
  str = string.gsub( str, "&Ouml;", "Ö")
  str = string.gsub( str, "&ouml;", "ö")
  str = string.gsub( str, "Uuml;", "Ü")
  str = string.gsub( str, "&uuml;", "ü")
  str = string.gsub( str, "&szlig;", "ß")
  str = string.gsub( str, '&#(%d+);', function(n) return string.char(n) end )
  str = string.gsub( str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end )
  str = string.gsub( str, '&amp;', '&' ) -- Be sure to do this after all others
  return str
end

return utilities
