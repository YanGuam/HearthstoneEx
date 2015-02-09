local HearthstoneHeros = {}
local HearthstoneCards = {}

local class = require "middleclass"

AllMinions = {}

local player1, player2

function createHeroSkill(skill)
    local card = sgs.CreateSkillCard
    {
        name = skill.name .. "Card",
        target_fixed = skill.target_fixed,
        filter = skill.filter,
        on_use = skill.on_use
    }
    
    local vsSkill = sgs.CreateZeroCardViewAsSkill
    {
        name = skill.name,
        enabled_at_play = function(self, player)
            return not player:hasUsed(("#%sCard"):format(skill.name))
        end,
        view_as = function()
            local cd = card:clone()
            cd:setSkillName(skill.name)
            return cd
        end
    }
    
    return vsSkill
end

Card = class("Card")

Card.static.RARITY_NON = -1
Card.static.RARITY_FREE = 0
Card.static.RARITY_COMMON = 1
Card.static.RARITY_RARE = 2
Card.static.RARITY_EPIC = 3
Card.static.RARITY_LEGENDARY = 4

Card.static.CARDTYPE_MINION = 0
Card.static.CARDTYPE_SPELL = 1
Card.static.CARDTYPE_WEAPON = 2

Card.static.CLASS_NEUTRAL = 0
Card.static.CLASS_MAGE = 1
Card.static.CLASS_HUNTER = 2
Card.static.CLASS_PALADIN = 3
Card.static.CLASS_WARRIOR = 4
Card.static.CLASS_DRUID = 5
Card.static.CLASS_WARLOCK = 6
Card.static.CLASS_SHAMAN = 7
Card.static.CLASS_PRIEST = 8
Card.static.CLASS_ROGUE = 9

AllCards = {}

function Card:initialize(name, chinese, cardType, heroType, rarity, num)
    self.name = name
    self._firstId = sgs.Sanguosha:getCardCount()
    self.rarity = rarity or Card.RARITY_FREE
    self.heroType = heroType or Card.CLASS_NEUTRAL
    self.cardType = cardType
    self.num = num or 4
    self.chinese = chinese
    
    sgs.CreateTranslationTable {
        [name] = chinese
    }
    
    AllCards[chinese] = {}
    for i = 0, num - 1 do
        table.insert(AllCards[chinese], self._firstId + i)
    end
        
    HearthstoneCards[chinese] = name
end

function Card:addToDeck(owner)
    table.insert(owner.deck, AllCards[self.chinese][1])
    table.remove(AllCards[self.chinese], 1)
end

MinionCard = class("MinionCard", Card)

function MinionCard:initialize(nm, heroType, rarity, num)
    Card:initialize(nm, Card.CARDTYPE_MINION, heroType, rarity, num)
    self.card = sgs.CreateBasicCard {
        name = nm,
        subtype = "MinionCard",
        target_fixed = false
    }
}

Unit = class("Unit")

Units = {}

function UnitOf(player)
    if type(player) == "string" then
        return Units[player]
    else
        return Units[player:objectName()]
    end
end

function Unit:initialize(player)
    self.player = player
    self._room = player:getRoom()
    self.attack = 0
    self.health = 0
    Units[player:objectName()] = self
end

function Unit:getAttack()
    return self.player:getMark("@Attack")
end

function Unit:attack(target)
    if self:getAttack() == 0 then return end
    self:damage(target, self:getAttack())
    target:attack(self)
end

function Unit:_onDamaged(target, point, card)
    self._room:damage(sgs.DamageStruct(card, self.player, target.player, point))
end

function Unit:damage(target, point, card)
    self:_onDamaged(target, point, card)
end

function Unit:onKilled() end 

HPlayer = class("HPlayer", Unit)

function HPlayer:initialize(player)
    Unit:initialize(player)
    self.health = 30
    self.deck = {}
    player:getRoom():setPlayerMark(player, "@DeckCards", 30)
    self.shield = 0
end

function HPlayer:drawCards(num)
    for i = 1, num do
        if #self.deck > 0 then
            local index = math.random(1, #self.deck)
            local id = self.deck[index]
            self._room:obtainCard(self.player, id, false)
            table.remove(self.deck, index)
        else
            self._room:damage(sgs.DamageStruct("HearthstoneNoCard", nil, self.player))
        end
    end
end

function HPlayer:_setShield(point)
    self.shield = math.max(point, 0)
    self._room:setPlayerMark(self.player, "@shield", self.shield)
end

function HPlayer:_onDamaged(target, point, card)
    point = point - self.shield
    self._setShield(self.shield - point)
    if point > 0 then
        Unit:_onDamaged(target, point, card)
    end
end

function HPlayer:_onKilled()
    self._room:gameOver(self == player1 and player2:objectName() or player1:objectName())
end

Minion = class("Minion", Unit)

function Minion:initialize(player)
    Unit:initialize(player)
    self._room:changeHero(self.player, "minion", false)
end

function Minion:setMinion(name)
    self._minion = AllMinions[name]
    self._room:setPlayerProperty(self.player, "maxHp", sgs.QVariant(self._minion.maxHp))
    self._room:changeHero(self.player, name, true)
end

function Minion:_onKilled()
    self:setMinion("minion")
end

HearthstoneExchangeCard = sgs.CreateSkillCard
{
	name = "HearthstoneExchangeCard",
	target_fixed = true,
	will_throw = false
}

HearthstoneExchange = sgs.CreateViewAsSkill
{
	name = "HearthstoneExchange",
    response_pattern = "@@HearthstoneExchange",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = HearthstoneExchange:clone()
			for _, cd in pairs(cards) do
				card:addSubcard(cd)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end
}

function HPlayer:askForExchange()
    local card = self._room:askForCard(self.player, "@@HearthstoneExchange", "@HearthstoneExchange", sgs.QVariant(), sgs.Card_MethodNone)
    if card then
        for _, id in sgs.qlist(card:getSubcards()) do
            sgs.Sanguosha:getCard(id):addToDeck(self)
        end
        room:moveCardTo(card, nil, sgs.Player_DrawPile)
    end
end

function HPlayer:obtainTheCoin()
    local coin = AllCards["幸运币"][1]
    self._room:obtainCard(self.player, id)
end

local Player1Cards = {}
local Player2Cards = {}

function createHero(extension, name, chinese, title, skill, female)
    HearthstoneHeros[chinese] = name
    sgs.CreateTranslationTable {
        [name] = chinese,
        ["&" .. name] = title,
        ["#" .. name] = title,
        
        ["designer:" .. name] = "炉石传说",
        ["illustrator:" .. name] = "炉石传说",
        ["cv:" .. name] = "炉石传说"
    }
    
    local hero = sgs.General(extension, name, "wei", 30, not female)
    hero:addSkill(skill)
end

function hasHero(chinese)
    return HearthstoneHeros[chinese] and true or false
end

function englishHero(chinese)
    return HearthstoneHeros[chinese]
end

function hasCard(chinese)
    return HearthstoneCards[chinese] and true or false
end

function getCard(chinese)
    return AllCards[chinese][1]
end

HearthstoneCard = sgs.CreateSkillCard
{
    name = "HearthstoneCard",
    target_fixed = true,
    
    on_use = function(self, room, source)
        local str = self:getUserString()
        source:setTag("HearthstoneSetup", sgs.QVariant(str))
    end
}

HearthstoneVS = sgs.CreateZeroCardViewAsSkill
{
    name = "Hearthstone",
    response_pattern = "@@Hearthstone",
    
    view_as = function()
        io.input("hearthstone/cards.txt")
        local strs = {}
        for _, l in io.lines() do
            table.insert(strs, l)
        end
        assert(#strs >= 16 and #strs <= 31)
        local card = HearthstoneCard:clone()
        card:setUserString(table.concat(strs, ":"))
        return card
    end
}

Hearthstone = sgs.CreateTriggerSkill
{
	name = "Hearthstone",
	events = {sgs.GameStart, sgs.DrawInitialCards, sgs.AfterDrawInitialCards, sgs.DrawNCards, sgs.PostHpReduced},
	frequency = sgs.Skill_Compulsory,
    global = true,
    humans = {},
    
	can_trigger = function(self, target)
		return target:getRoom():getTag("HearthstoneMode"):toBool()
	end,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawInitialCards then
            data:setValue(0)
        elseif event == sgs.AfterDrawInitialCards then
            if room:getTag("HearthstoneStarted"):toBool() then return false end
            local function getPlayerBySeat(seat)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getSeat() == seat then
                        return p
                    end
                end
            end
            
            if math.random(2) == 2 then
                humans[1], humans[2] = humans[2], humans[1]
            end
            
            humans[1]:setNext(humans[2])
            player1, player2 = HPlayer(humans[1]), HPlayer(humans[2])
            
            local msg = sgs.LogMessage()
            msg.from = humans[1]
            msg.type = "#HearthstoneLord"
            room:sendLog(msg)
            
            if humans[1]:getSeat() ~= 1 then
                room:swapSeat(humans[1], getPlayerBySeat(1))
            end
            
            if humans[2]:getSeat() ~= 6 then
                room:swapSeat(humans[2], getPlayerBySeat(6))
            end
            
            local function changeRole(p, role)
                room:setPlayerProperty(p, "role", sgs.QVariant(role))
            end
            
            changeRole(humans[1], sgs.Player_Lord)
            changeRole(humans[2], sgs.Player_Renegade)
            
            for i = 2, 10 do
                if i == 6 then continue end
                if i > 3 and i < 9 then
                    changeRole(getPlayerBySeat(i), sgs.Player_Loyalist)
                else
                    changeRole(getPlayerBySeat(i), sgs.Player_Rebel)
                end
            end
            
            player1:drawCards(3)
            player2:drawCards(4)
            
            player1:askForExchange()
            player2:askForExchange()
            
            player2:obtainTheCoin()
            
            room:setTag("HearthstoneStarted", sgs.QVariant(true))
        elseif event == sgs.DrawNCards then
            data:setValue(0)
            getPlayer(player):drawCards(1)
        elseif event == sgs.PostHpReduced and player:getHp() < 1 then
            UnitOf(player).onKilled()
            return true
        else
        
            if room:getMode() ~= "10p" then return false end
            local bans = sgs.Sanguosha:getBanPackages()
            local ban = 0
            for _, b in ipairs(bans) do
                if b == "standard_cards" or b == "standard_ex_cards" or b == "maneuvering" or b == "sp_cards" or b == "nostalgia" then
                    ban = ban + 1
                end
            end
            if ban ~= 5 then return false end
            
            local players = room:getAlivePlayers()
            
            for _,p in sgs.qlist(players) do
                if p:getState() ~= "robot" then table.insert(humans, p) end
            end
            
            if #humans > 2 then
                return false
            elseif #humans == 1 then
                table.insert(humans, players:at(players:at(0):getState() == "robot" and 0 or 1))
            end
            
            room:setTag("HearthstoneMode", sgs.QVariant(true))
            
            Player1Cards = {}
            Player2Cards = {}
            humans = {}
            
            for _, p in ipairs(humans) do
                local success = false
                local hero
                repeat
                    local card = room:askForUseCard(p, "@@Hearthstone", "@Hearthstone")
                    if card then
                        local str = p:getTag("HearthstoneSetup"):toString()
                        local strs = str:split(":")
                        hero = strs[1]
                        if not hasHero(hero) then error("Failed to parse the setup file!") end
                        table.remove(strs, 1)
                        
                        for _, s in ipairs(strs) do
                            local card
                            local num = 1
                            if (s:endsWith("*2")) then
                                card = string.sub(s, 1, -3)
                                num = 2
                            else
                                card = s
                            end
                            if not hasCard(card) then error("Failed to parse the setup file!") end
                            
                            local t = #Player1Cards > 0 and Player2Cards or Player1Cards
                            for i = 1, num do
                                table.insert(t, HearthstoneCards[card])
                            end
                            
                            if #t ~= 30 then error("Failed to parse the setup file!") end
                        end
                        success = true
                    end
                until success
                room:changeHero(p, englishHero(hero), true)
            end
            
        end
    end
}

if not sgs.Sanguosha:getSkill("Hearthstone") then
    local skills = sgs.SkillList()
    skills:append(Hearthstone)
    sgs.Sanguosha:addSkills(skills)
end

HearthstoneMax = sgs.CreateMaxCardsSkill
{
    name = "#HearthstoneMax",
    extra_func = function(self, target)
        if target:hasSkill(self:objectName()) then
            return 1000
        else
            return 0
        end
    end
}
                