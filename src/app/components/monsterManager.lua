monsterManeger = {}
monsterManeger.areasWithMonster = {}
monsterManeger.areasNoMonster = {}
monsterManeger.monsterCount = 0

--取得一个有怪物的野怪区
function getMonsterAreaWithMonster()
	if table.getn(monsterManeger.areasWithMonster) > 0 then
		return monsterManeger.areasWithMonster[math.random([1,table.getn(monsterManeger.areasWithMonster)])]
	end
	return monsterManeger.areasNoMonster[math.random([1,table.getn(monsterManeger.areasNoMonster)])]
end

function addMonsterArea(area)
	monsterManeger.areasNoMonster[area.areaName] = area
end

function addMonster(monster,areaName)
	local area = monsterManeger.areasWithMonster[areaName]
	if not area then
		area = monsterManeger.areasNoMonster[areaName]
	end

	

end

