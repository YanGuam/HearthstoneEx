module("extensions.hearthstone", package.seeall)

extension = sgs.Package("hearthstone", sgs.CardPack)

dofile "hearthstone/logic.lua"

Fireblast = createHeroPower 
{
    name = "Fireblast",
    target_fixed = false,
    effect = function(self, source, target)
        source:damage(target, 1)
    end
}