npcManager = {}
npcManager.npcGenerateAreas = {}
npcManager.npcCount = 0

function initNpcManager( map )
	npcManager.map_ = map
	local gm = require("app.components.Npc").create({textureName="player_f0006_walk_1_01.png",scale=0.4,flippedX = true,playerName="player_f0006"})
	gm.map_ = npcManager.map_

	local objectLayer = npcManager.map_:getObjectGroup("npcgenerateLayer")
	for i=1,1 do
		local area = {}
		area.areaName = "npc_gen_point_"..i
		area.npcs = {}
		area.tiles = {}
		local prop = objectLayer:getObject(area.areaName)
		local minTileX = math.modf(prop.x/npcManager.map_:getTileSize().width) 
		local maxTileY = math.modf((npcManager.map_:getMapSize().height * npcManager.map_:getTileSize().height - prop.y)/npcManager.map_:getTileSize().height)
		local maxTileX = math.modf((prop.x + prop.width)/npcManager.map_:getTileSize().width) 
		local minTileY = math.modf((npcManager.map_:getMapSize().height * npcManager.map_:getTileSize().height - (prop.y + prop.height))/npcManager.map_:getTileSize().height)
		for x=minTileX,maxTileX do
			for y=minTileY,maxTileY do
				if canReach(gm, cc.p(x,y)) then
					table.insert(area.tiles, cc.p(x,y))
				end
				
			end
		end
		npcManager.npcGenerateAreas[area.areaName] = area
	end
	gm = nil

	-- 创建player批渲染结点
    npcManager.playerNode = display.newBatchNode("player.png", 100000)
    npcManager.map_:addChild(npcManager.playerNode,100,"playerNode")
end

--在野区中增加一个NPC
function addNpc(npc,areaName)
	local area = npcManager.npcGenerateAreas[areaName]
	local tileIndex = math.random(1,table.getn(area.tiles))
	local pos = convertTilePositionToMapPosition(npcManager.map_,area.tiles[tileIndex])
    npc:pos(pos.x,pos.y)
    table.insert(area.npcs, npc)
    npcManager.playerNode:addChild(npc, 100)
    npc:runAI(npcManager.map_)
end

function getNpcCount(areaName)
	local area = npcManager.npcGenerateAreas[areaName]
	return table.getn(area.npcs)
end