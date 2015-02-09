module("extensions.hearthstone", package.seeall)

extension = sgs.Package("hearthstone", sgs.CardPack)

dofile "hearthstone/logic.lua"

--火焰冲击：造成1点伤害 
Fireblast = createHeroPower 
{
    name = "Fireblast",
    target_fixed = false,
    effect = function(self, source, target)
        source:damage(target, 1)
    end
}

createHero(extension, "jaina_proudmoore", "吉安娜·普罗德摩尔", Card.CLASS_MAGE, Fireblast, true)

--稳固射击： 对敌方英雄造成2点伤害
SteadyShot = createHeroPower 
{
    name = "SteadyShot",
    target_fixed = true,
    effect = function(self, source)
        source:damage(source:getOpponent(), 2)
    end
}

createHero(extension, "rexxar", "雷克萨", Card.CLASS_HUNTER, SteadyShot)

--白银新兵：召唤一个1/1的白银之手新兵
--Reinforce
createHero(extension, "uther_lightbringer", "乌瑟尔·光明使者", Card.CLASS_PALADIN, Reinforce)

--全副武装：获得2点护甲值
ArmorUp = createHeroPower 
{
    name = "ArmorUp",
    target_fixed = true,
    effect = function(self, source)
        source:addArmor(2)
    end
}

createHero(extension, "garrosh_hellscream", "加尔鲁什·地狱咆哮", Card.CLASS_WARRIOR, ArmorUp)

--变形术：本回合+1攻击力，+1护甲值
--Shapeshift
createHero(extension, "malfurion_stormrage", "玛法里奥·怒风", Card.CLASS_DRUID, Shapeshift)

--生命分流：抽一张牌并受到2点伤害 
LifeTap = createHeroPower 
{
    name = "LifeTap",
    target_fixed = true,
    effect = function(self, source)
        source:drawCards(1)
        source:loseHp(2)
    end
}

createHero(extension, "guldan", "古尔丹", Card.CLASS_WARLOCK, LifeTap)

--召唤图腾：随机召唤一个图腾 
--TotemicCall
createHero(extension, "thrall", "萨尔", Card.CLASS_SHAMAN, TotemicCall)

--次级治疗术：恢复2点生命值 
LesserHeal = createHeroPower 
{
    name = "LesserHeal",
    target_fixed = false,
    effect = function(self, source, target)
        target:recover(2)
    end
}

createHero(extension, "anduin_wrynn", "安杜因·乌瑞恩", Card.CLASS_PRIEST, LesserHeal)

--匕首精通：装备一把1/2的匕首
--DaggerMastery
createHero(extension, "valeera_sanguinar", "瓦莉拉·萨古纳尔", Card.CLASS_ROGUE, DaggerMastery, true)
