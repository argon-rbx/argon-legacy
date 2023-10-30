local ChangeHistoryService = game:GetService('ChangeHistoryService')

local Config = require(script.Parent.Config)
local DataTypes = require(script.Parent.DataTypes)

local SEPARATOR = '|'
local UUID_PATTERN = 'xxxxxx'
local ARGON_UUID = 'ArgonUUID'
local DISABLE_PREFIX = '--disable'
local ARGON_IGNORE = 'ArgonIgnore'
local SCRIPT_TYPES = {
    Script = 'server',
    LocalScript = 'client',
    ModuleScript = ''
}

local currentInstances = {}

local fileHandler = {}

local function addWaypoint()
    ChangeHistoryService:SetWaypoint('ArgonSync')
end

-- Yep, I know that # exists, but this function is required for counting non-numeric arrays
local function len(array)
    local index = 0

    for _, _ in pairs(array) do
        index += 1
    end

    return index
end

local function generateUUID()
    return string.gsub(UUID_PATTERN, '[x]', function()
        return string.format('%x', math.random(0, 15))
    end)
end

local function parse(instance)
    local name, num = instance.Name:gsub('[%\\%/%:%*%?%"%<%>%|]', '')
    local className = ''

    if name:match('^/') or name:match('^\\') then
        name:sub(2)
    end

    if instance:IsA('LuaSourceContainer') then
        className = SEPARATOR..instance.ClassName
    end

    if Config.syncDuplicates then
        local uuid = instance:GetAttribute(ARGON_UUID)

        if not uuid then
            local duplicates = 0

            for _, v in ipairs(instance.Parent:GetChildren()) do
                if v.Name == instance.Name then
                    if duplicates == 0 then
                        duplicates += 1
                        continue
                    else
                        uuid = generateUUID()
                        instance:SetAttribute(ARGON_UUID, uuid)
                        name = name..'%'..uuid

                        break
                    end
                end
            end
        else
            name = name..'%'..uuid
        end
    end

    if num ~= 0 then
        warn('Argon: '..instance:GetFullName()..' contains invalid symbols! (fhP)')
    end

    return name..className
end

local function getParent(instance, root)
    local parent = {}

    if fileHandler.countChildren(instance) > 0 then
        parent = {forceSubScript = {}}
    end

    repeat
        parent = {[parse(instance)] = parent}
        instance = instance.Parent

        if instance:GetAttribute(ARGON_IGNORE) ~= nil then
            return
        end

        if Config.propertySyncing and not currentInstances[instance] and not instance:IsA('LuaSourceContainer') then
            currentInstances[instance] = fileHandler.getPath(instance)
        end

    until instance == root

    return parent
end

local function getChildren(dir)
    local children = {}

    if Config.onlyCode then
        for _, v in ipairs(dir:GetDescendants()) do
            if v:IsA('LuaSourceContainer') then
                if ((not Config.filteringMode and not table.find(Config.filteredClasses, v.ClassName)) or (Config.filteringMode and table.find(Config.filteredClasses, v.ClassName))) then
                    if v:GetAttribute(ARGON_IGNORE) == nil then
                        local parent = getParent(v, dir)

                        if parent then
                            table.insert(children, parent)
                        end
                    end
                end
            end
        end
    else
        for _, v in pairs(dir:GetChildren()) do
            if ((not Config.filteringMode and not table.find(Config.filteredClasses, v.ClassName)) or (Config.filteringMode and table.find(Config.filteredClasses, v.ClassName))) then
                if v:GetAttribute(ARGON_IGNORE) == nil then
                    if fileHandler.countChildren(v) > 0 then
                        children[parse(v)] = getChildren(v)
                    else
                        children[parse(v)] = {}
                    end

                    if Config.propertySyncing and not currentInstances[v] and not v:IsA('LuaSourceContainer') then
                        currentInstances[v] = fileHandler.getPath(v)
                    end
                end
            end
        end

        if Config.propertySyncing and not currentInstances[dir] and not dir:IsA('LuaSourceContainer') then
            currentInstances[dir] = fileHandler.getPath(dir)
        end
    end

    return children
end

local function getInstance(parent)
    parent = parent:split(SEPARATOR)
    local lastParent = game

    for _, v in ipairs(parent) do
        if lastParent == game then
            lastParent = game:GetService(v)
        else
            local didFind = false
            local uuid = nil

            if Config.syncDuplicates and v:find('%%') and v:len() - v:find('%%') == 6 then
                local temp = v
                v = temp:sub(1, temp:len() - 7)
                uuid = temp:sub(temp:len() - 5)
            end

            for _, w in ipairs(lastParent:GetChildren()) do
                if not uuid then
                    if w.Name == v then
                        lastParent = w
                        didFind = true
                        break
                    end
                else
                    if w.Name == v and w:GetAttribute(ARGON_UUID) == uuid then
                        lastParent = w
                        didFind = true
                        break
                    end
                end
            end

            if not didFind then
                return
            end
        end
    end

    return lastParent
end

function fileHandler.create(class, name, parent, delete)
    local success, response = pcall(function()
        parent = getInstance(parent)
        local object

        if delete and parent:FindFirstChild(name) then
            object = Instance.new(class)

            for _, v in ipairs(parent[name]:GetChildren()) do
                v.Parent = object
            end

            parent[name]:Destroy()
        elseif parent:FindFirstChild(name) then
            return
        end

        if not object then
            object = Instance.new(class)
        end

        object.Name = name
        object.Parent = parent
    end)

    if not success then
        warn('Argon: '..response..' (fhC)')
        print('Class: ', class, ', Name: ', name, ', Parent: ', parent, ', State: ', delete)
    end

    addWaypoint()
end

function fileHandler.update(object, source)
    local success, response = pcall(function()
        object = getInstance(object)

        if not object:IsA('ModuleScript') then
            if source:match('^'..DISABLE_PREFIX) then
                object.Enabled = false
                source = source:gsub(DISABLE_PREFIX..'\n', '')
            else
                object.Enabled = true
            end
        end

        object.Source = source
    end)

    if not success then
        warn('Argon: '..response..' (fhU)')
        print('Object: ', object)
    end

    addWaypoint()
end

function fileHandler.delete(object)
    local success, response = pcall(function()
        getInstance(object):Destroy()
    end)

    if not success then
        warn('Argon: '..response..' (fhD)')
        print('Object: ', object)
    end

    addWaypoint()
end

function fileHandler.rename(object, name)
    local success, response = pcall(function()
        getInstance(object).Name = name
    end)

    if not success then
        warn('Argon: '..response..' (fhR)')
        print('Object: ', object, ', Name: ', name)
    end

    addWaypoint()
end

function fileHandler.changeParent(object, parent)
    local success, response = pcall(function()
        getInstance(object).Parent = getInstance(parent)
    end)

    if not success then
        warn('Argon: '..response..' (fhCP)')
        print('Object: ', object, ', Parent: ', parent)
    end

    addWaypoint()
end

function fileHandler.changeType(object, class, name)
    local success, response = pcall(function()
        object = getInstance(object)

        local newObject = Instance.new(class, object.Parent)
        newObject.Name = name or object.Name

        for _, v in ipairs(object:GetChildren()) do
            v.Parent = newObject
        end

        if SCRIPT_TYPES[class] and object:IsA('LuaSourceContainer') then
            newObject.Source = object.Source
        end

        object:Destroy()
    end)

    if not success then
        warn('Argon: '..response..' (fhCT)')
        print('Object: ', object, ', Class: ', class, ', Name: ', name)
    end

    addWaypoint()
end

function fileHandler.setProperties(object, properties)
    local success, response = pcall(function()
        object = getInstance(object)

        if properties.Class and properties.Class ~= object.ClassName then
            local newObject = Instance.new(properties.Class, object.Parent)
            newObject.Name = object.Name

            for _, v in ipairs(object:GetChildren()) do
                v.Parent = newObject
            end

            object:Destroy()
            object = newObject
        end

        local attributes = object:GetAttributes()

        if len(attributes) > 0 and not properties.Attributes then
            for i, _ in pairs(attributes) do
                object:SetAttribute(i, nil)
            end
        end

        for i, v in pairs(properties) do
            if i ~= 'Class' then
                if i ~= 'Attributes' then
                    object[i] = DataTypes.cast(v, i, object)
                else
                    for j, w in pairs(v) do
                        object:SetAttribute(j, DataTypes.cast(w.Value, w.Type))
                    end
                end
            end
        end
    end)

    if not success then
        warn('Argon: '..response..' (fhSP)')
        print('Object: ', object, ', Properties: ', properties)
    end
end

function fileHandler.countChildren(instance)
    local count = 0

    if Config.onlyCode then
        for _, v in ipairs(instance:GetDescendants()) do
            if v:IsA('LuaSourceContainer') then
                count += 1
            end
        end
    else
        count = #instance:GetChildren()
    end

    return count
end

function fileHandler.getPath(instance, onlyCode, recursive)
    local parent = instance.Parent
    local dir = ''

    if instance.Parent ~= game then
        local name, uuid

        if instance:IsA('LuaSourceContainer') then
		    if not recursive then
                name = instance.Name

                if Config.onlyCode or onlyCode then
                    if fileHandler.countChildren(instance) == 0 then
                        if instance.ClassName ~= 'ModuleScript' then
                            if not Config.syncDuplicates then
                                name ..= '.'..SCRIPT_TYPES[instance.ClassName]
                            else
                                uuid = instance:GetAttribute(ARGON_UUID)

                                if uuid then
                                    name ..= '%'..uuid..'.'..SCRIPT_TYPES[instance.ClassName]
                                else
                                    name ..= '.'..SCRIPT_TYPES[instance.ClassName]
                                end
                            end
                        else
                            name = name
                        end
                    else
                        name = name
                    end
                else
                    if fileHandler.countChildren(instance) == 0 then
                        if instance.ClassName ~= 'ModuleScript' then
                            if not Config.syncDuplicates then
                                name ..= '.'..SCRIPT_TYPES[instance.ClassName]
                            else
                                uuid = instance:GetAttribute(ARGON_UUID)

                                if uuid then
                                    name ..= '%'..uuid..'.'..SCRIPT_TYPES[instance.ClassName]
                                else
                                    name ..= '.'..SCRIPT_TYPES[instance.ClassName]
                                end
                            end
                        else
                            name = name
                        end
                    else
                        name = name
                    end
                end
            else
                name = instance.Name
		    end
        else
            name = instance.Name
        end

        if Config.syncDuplicates and not uuid then
            uuid = instance:GetAttribute(ARGON_UUID)

            if uuid then
                name ..= '%'..uuid
            end
        end

        dir = fileHandler.getPath(parent, onlyCode, true)..Config.separator..name
    else
        dir = instance.ClassName
    end

    return dir
end

function fileHandler.portInstances()
    local instancesToSync = {}

    for i, v in pairs(Config.syncedDirectories) do
        if v then
            instancesToSync[i] = getChildren(game:GetService(i))
        end
    end

    for i, v in pairs(instancesToSync) do
        if len(v) == 0 then
            instancesToSync[i] = nil
        end
    end

    if instancesToSync['StarterPlayer'] then
        if instancesToSync['StarterPlayer']['StarterCharacterScripts'] then
            if len(instancesToSync['StarterPlayer']['StarterCharacterScripts']) == 0 then
                instancesToSync['StarterPlayer']['StarterCharacterScripts'] = nil
            end
        end

        if instancesToSync['StarterPlayer']['StarterPlayerScripts'] then
            if len(instancesToSync['StarterPlayer']['StarterPlayerScripts']) == 0 then
                instancesToSync['StarterPlayer']['StarterPlayerScripts'] = nil
            end
        end

        if len(instancesToSync['StarterPlayer']) == 0 then
            instancesToSync['StarterPlayer'] = nil
        end
    end

    return instancesToSync
end

function fileHandler.portScripts()
    local scriptsToSync = {}

    for i, v in pairs(Config.syncedDirectories) do
        if v then
            for _, w in ipairs(game:GetService(i):GetDescendants()) do
                if w:IsA('LuaSourceContainer') and w:GetAttribute(ARGON_IGNORE) == nil then
                    local source = w.Source

                    if not w:IsA('ModuleScript') and not w.Enabled and not source:match('^'..DISABLE_PREFIX) then
                        source = DISABLE_PREFIX..'\n'..source
                    end

                    table.insert(scriptsToSync, {Type = w.ClassName, Instance = fileHandler.getPath(w), Source = source})
                end
            end
        end
    end

    return scriptsToSync
end

function fileHandler.portProperties()
    local propertiesToSync = {}

    for i, v in pairs(currentInstances) do
        local properties = DataTypes.getProperties(i)

        if properties then
            propertiesToSync[v] = properties
        end
    end

    currentInstances = {}

    return propertiesToSync
end

function fileHandler.lockPackages()
    if game:GetService('ReplicatedStorage'):FindFirstChild('Packages') then
        game:GetService('ReplicatedStorage').Packages:SetAttribute(ARGON_IGNORE, true)
    end
end

function fileHandler.clear()
    currentInstances = {}
end

return fileHandler