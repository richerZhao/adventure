require("config")
require("cocos.init")
require("framework.init")
GameState= require(cc.PACKAGE_NAME .. ".cc.utils.GameState")
scheduler = require("framework.scheduler")
import("app.utils.utils")
GameData={}

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
	local saveData
	GameState.init(function(param)
        local returnValue=nil
        if param.errorCode then
            dump(param.errorCode,"GameState.init:")
        else
            -- crypto
            if param.name=="save" then
                local str=json.encode(param.values)
                str=crypto.encryptXXTEA(str, "abcd")
                returnValue={data=str}
            elseif param.name=="load" then
                local str=crypto.decryptXXTEA(param.values.data, "abcd")
                returnValue=json.decode(str)
            end
        end
        return returnValue
    end, "src/data/userdata","1234")
    saveData=GameState.load()
    if saveData then
        GameData=saveData.data
    end
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    -- self:enterScene("MainScene")
    self:enterScene("WorldScene")
end

function saveData()
	local saveData = {data=GameData}
	GameState.save(saveData)
end

return MyApp
