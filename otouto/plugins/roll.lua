local roll = {}

roll.command = 'roll'

function roll:init(config)
	roll.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('roll', true).table
	roll.doc = [[*
]]..config.cmd_pat..[[roll*: Werfe einen Würfel]]
end

local canroll = {
    "1",
    "2",
    "3",
    "4",
    "5",
    "6"
}

function roll:roll_dice()
    local randomroll = math.random(6)
    return canroll[randomroll]
end

function roll:action(msg)
  utilities.send_reply(msg, 'Du hast eine *'..roll:roll_dice()..'* gewürfelt.', true)
end

return roll
