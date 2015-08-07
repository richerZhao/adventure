-- import("app.components.searchpath")
-- import("app.components.map")
dofile("src/app/components/map.lua")
monsterManager = {}
monsterManager.monsterCount = 0

function initMonsterManager(map)
	monsterManager.map_ = map
	local gm = require("app.components.Npc").create({textureName="player_f0006_walk_1_01.png",scale=0.4,flippedX = true,playerName="player_f0006"})
	gm.map_ = monsterManager.map_

	-- monsterManager.areasWithMonster = hashmap.new()
	-- monsterManager.areasNoMonster = hashmap.new()
	monsterManager.areasWithMonster = newHashMap()
	monsterManager.areasNoMonster = newHashMap()
	
	--注册怪物的出生点
	local monsterLayer = monsterManager.map_:getObjectGroup("monstergenerateLayer")
	for i=1,7 do
		local area = {}
		area.areaName = "monster_gen_area_"..i
		area.tiles = {}
		area.monsters = {}
		local prop = monsterLayer:getObject(area.areaName)
		local minTileX = math.modf(prop.x/monsterManager.map_:getTileSize().width) 
		local maxTileY = math.modf((monsterManager.map_:getMapSize().height * monsterManager.map_:getTileSize().height - prop.y)/monsterManager.map_:getTileSize().height)
		local maxTileX = math.modf((prop.x + prop.width)/monsterManager.map_:getTileSize().width) 
		local minTileY = math.modf((monsterManager.map_:getMapSize().height * monsterManager.map_:getTileSize().height - (prop.y + prop.height))/monsterManager.map_:getTileSize().height)
		area.minX = minTileX
		area.maxX = maxTileX
		area.minY = minTileY
		area.maxY = maxTileY
		for x=minTileX,maxTileX do
			for y=minTileY,maxTileY do
				if canReach(gm, cc.p(x,y)) then
					table.insert(area.tiles, cc.p(x,y))
				end
				
			end
		end

		monsterManager.areasNoMonster.add(area.areaName,area)
	end
	gm = nil
	print("monsterManager.areasNoMonster:size() = "..monsterManager.areasNoMonster.size())
	print("monsterManager.areasWithMonster:size() = "..monsterManager.areasWithMonster.size())

	-- 创建monster批渲染结点
    monsterManager.monsterNode = display.newBatchNode("player.png", 100000)
    monsterManager.map_:addChild(monsterManager.monsterNode,100,"monsterNode")
end

--取得一个有怪物的野怪区
function getMonsterAreaWithMonster(areaName)
	if areaName then
		return monsterManager.areasWithMonster.get(areaName)
	end
	if monsterManager.areasWithMonster.size() > 0 then
		return monsterManager.areasWithMonster.getElementByIndex(math.random(1,monsterManager.areasWithMonster.size()))
	end
	return monsterManager.areasNoMonster.getElementByIndex(math.random(1,monsterManager.areasNoMonster.size()))
end

function getMonsterAreaNoMonster()
	if monsterManager.areasNoMonster.size() > 0 then
		return monsterManager.areasNoMonster.getElementByIndex(math.random(1,monsterManager.areasNoMonster.size()))
	end
	return monsterManager.areasWithMonster.getElementByIndex(math.random(1,monsterManager.areasWithMonster.size()))
end

--在野区中增加一个怪物
function addMonster(monster)
	monster.type_ = npctype.MONSTER
	local area = getMonsterAreaNoMonster()
	addMonsterToArea_(monster,area)
	if table.getn(area.monsters) > 0 then
		monsterManager.areasWithMonster.add(area.areaName,area)
	end
	monsterManager.areasNoMonster.remove(area.areaName)
	monster:runAI(monsterManager.map_)
end

--在野区中增加一个怪物
function addMonsterToArea_(monster,area)
	local pos = convertTilePositionToMapPosition(monsterManager.map_,area.tiles[math.random(table.getn(area.tiles))])
	--TODO 播放怪物出现动画
	-- transition.execute(npc, action, {  
	--     onComplete = function(npc)
	-- 	    callback(npc)
	--     end,
	--     time = 1,
	-- })  

	monster.areaName = area.areaName
	monster:pos(pos.x, pos.y)
	table.insert(area.monsters, monster)
	monsterManager.monsterNode:addChild(monster, 100)
end

function removeMonster(monster)
	local area = monsterManager.areasWithMonster.get(monster.areaName)
	local index
	for i,v in ipairs(area.monsters) do
		if monster == v then
			index = i
			break
		end
	end

	if index then
		table.remove(area.monsters,index)
	end
	--TODO remove monster from layer
end

function getMonsterCount()
	local count = 0
	for i,v in ipairs(monsterManager.areasWithMonster.valueList()) do
		count = count + table.getn(v.monsters)
	end
	return count
end

function monsterAreaRun()
	local maxMonsterNum = getNpcCount("npc_gen_point_1")
	if getMonsterCount() < maxMonsterNum then
		addMonster(require("app.components.Monster").create({textureName="player_f0015_walk_1_01.png",scale=0.4,flippedX = true,playerName="player_f0015"}))
	end
end






