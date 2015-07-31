local openTable = {}
table.insert(openTable, {x=1,y=1})
table.insert(openTable,1, {x=2,y=2})
table.insert(openTable, {x=3,y=3})

for i,v in ipairs(openTable) do
	print("table ["..i.."] {x="..v.x..",y="..v.y.."}\n")

end

local rm = table.remove(openTable,2)

print("rm:{x="..rm.x..",y="..rm.y.."}\n")


for i,v in ipairs(openTable) do
	print("table ["..i.."] {x="..v.x..",y="..v.y.."}\n")

end