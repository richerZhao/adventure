function newHashMap()
	local self = {}
	self.__keyList = {}
	self.__valueList = {}

	--add 方法
	local add = function (key,value)
		local index = self.__keyList[key]
		if index then
			table.remove(self.__valueList,index)
			table.insert(self.__valueList,index, value)
		else
			table.insert(self.__valueList, value)
			self.__keyList[key] = table.getn(self.__valueList)
		end
	end

	--get 方法
	local get = function ( key )
		local index = self.__keyList[key]
		if index then
			return self.__valueList[index]
		end
		return nil
	end

	--remove方法
	local remove = function ( key )
		local index = self.__keyList[key]
		if index then
			self.__keyList[key] = nil
			table.remove(self.__valueList,index)
		end
	end

	--clear方法
	local clear = function ( )
		self.__keyList = {}
		self.__valueList = {}
	end

	--size方法
	local size = function ( )
		return table.getn(self.__valueList)
	end

	--getElementByIndex方法
	local getElementByIndex = function ( index )
		return self.__valueList[index]
	end

	--valueList方法
	local valueList = function ( )
		return self.__valueList
	end

	return {add=add,get=get,remove=remove,clear=clear,size=size,getElementByIndex=getElementByIndex,valueList=valueList}
end


