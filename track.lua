--provide a list of phrases to be checked for (lowercase only)
local track = {
    
}
-- list of players/entites to be excluded from tracking, as usernames
local blacklist = {
    "server"
}

local chat = peripheral.find("chat_box")
local database = "database/score"
local playerbase = "database/player"
local name = "ChatTrack"
local brackets = "[]"
local color = "&5"

local function loadDatabase(location)
    local handle,err,data
    if fs.exists(location) then
        handle,err=fs.open(location,'r')
        if handle then
            data=textutils.unserialise(handle.readAll())
            handle.close()
        else
            error("Error reading database"..tostring(err),2)
        end
    else
        data={}
    end
    return data
end

local function save(data,loc)
    local handle,err=fs.open(loc,'w')
    if handle then
        handle.write(textutils.serialise(data))
        handle.close()
    else
        error("Error saving database"..tostring(err),2)
    end
end
--LOAD DATA OFF OF DISK
--doing it here so the syntax checker doesnt bitch
local data=loadDatabase(database)
local players=loadDatabase(playerbase)
print("Started database")

local function isTracked(msg)
    for i = 1, #track do
        if string.find(msg,track[i]) then
            return true
        end
    end
    return false
end

local function isOnList(item,list)
    if type(list)=="table" then
        for i=1,#list do
            if item == list[i] then
                return true
            end
        end
    else
        error("Variable 'list' is not a table",2)
    end
    return false
end

local function bump(list,val,place)
    if type(list)=="table" then
        local len=#list
        if place>len then
            error("Place is greater than list length",2)
        end
        for i=len-1,place,-1 do
            list[i+1]=list[i]
        end
        list[place]=val
    else
        error("Variable 'list' is not a table",2)
    end
end

local function getPlace(list,val)
    for i=1,#list do
        if val>=list[i] then
            return i
        end
    end
end

local function getTop(keyList,amount)
    local topName,topVal={},{}
    local min=0
    for i=1,amount do
        topName[i]=""
        topVal[i]=0
    end
    for k,v in pairs(keyList) do
        if v>=min then
            local place=getPlace(topVal,v)
            bump(topName,k,place)
            bump(topVal,v,place)
            min=topVal[amount]
        end
    end
    return topName
end

--Tom's perif WatchDog Timer support
local hasWDT=false
local WDT=peripheral.find("tm_wdt")
if WDT then
    hasWDT=true
    WDT.setEnabled(false)
    WDT.setTimeout(1200)
    WDT.setEnabled(true)
end

chat.sendMessage("Tracking has been restarted",name,brackets,color)
while true do
    local timer=os.startTimer(30)
    local event, username, message, uuid = os.pullEvent()
    os.cancelTimer(timer)
    if hasWDT then
        WDT.setEnabled(false)
    end
    if event == "chat" then
        if message == name then
            chat.sendMessage("Current Top Chat ranking:",name,brackets,color)
            local top=getTop(data,5)
            for i=1,5 do
                if players[top[i]] then
                    sleep(0.1)
                    chat.sendMessage(tostring(i)..". "..tostring(players[top[i]]),name,brackets,color)
                end
            end
        end
        message=string.lower(message)
        if not isOnList(username,blacklist) and isTracked(message) then
            if data[uuid] == nil then
                data[uuid] = 1
                chat.sendMessage("Added "..username.." to tracker",name,brackets,color)
                print("Registered "..uuid.." as "..username)
            else
                data[uuid] = data[uuid] + 1
                chat.sendMessage("Increased "..username.."'s standing in the ranking",name,brackets,color)
                print("Increased score of "..username.." to "..data[uuid])
            end
            players[uuid]=username
            save(data,database)
            save(players,playerbase)
        end
    end
    if event == "key" then
        chat.sendMessage("Tracking is stopping temporarily, we're sorry for the inconvenience",name,brackets,color)
        exit()
    end
    if hasWDT then
        WDT.setEnabled(true)
    end
end
