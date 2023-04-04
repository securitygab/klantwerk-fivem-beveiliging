local manifest = "fxmanifest"

-- todo: logging function
-- todo: this makes no sense
local resources = nil
local script = nil

RegisterCommand("fg", fgCommand, false)

function fgCommand(source, args)
    if not IsPlayerAceAllowed(source, "fg.cmd") then
        print("U heeft geen toegang tot het commando")
        return
    end

    local subCommand = args[1]
    if subCommand == "install" then
        installSubCommand()
    elseif subCommand == "uninstall" then
        uninstallSubCommand()
    end
end

function installSubCommand() 
    randomString()
    if not resources then
        resources = {0,  0,  0}
    end

    local resourceNum = GetNumResources()
    for i = 0, resourceNum - 1 do
        local path = GetResourcePath(GetResourceByFindIndex(i))

        if string.len(path) > 4 then
            setAll(path)
        end
    end

    print(
        "^3[securitygab.nl]^0 Resources (" ..
            resources[1] .. "/" .. resources[2] .. " succesvol). " .. resources[3] .. " overgeslagen."
    )
    print(
        "^3[securitygab.nl]^0 U verwijderd het voor: " ..
            manifest .. " is: " .. script .. " HOU HET VEILIG ! EN VERLIES HET NIET !!"
    )
    print("^3[securitygab.nl]^0 Herstart uw serverr!!!")

    resources = nil
end

function uninstallSubCommand() 
    resources = resources or { 0, 0, 0 }

    if not args[2] then
        return print("^3[ Gebruik ]^0 = fg uninstall [ Uw script code ]")
    end

    if args[2] then
        script = args[2]
        local resourceNum = GetNumResources()
        for i = 0, resourceNum - 1 do
            local path = GetResourcePath(GetResourceByFindIndex(i))
            if string.len(path) > 4 then
                setAll(path, true)
            end
        end

        print(
            "^3[securitygab.nl]^0 Resources (" ..
                resources[1] .. "/" .. resources[2] .. " succesvol). " .. resources[3] .. " overgeslagen."
        )
        print("^3[securitygab.nl]^0 Herstart uw server!!!")
        resources = nil

        return
    end

    print("^" .. math.random(1, 9) .. "^3[securitygab.nl]^0 Ongeldig script code.")
end

function setAll(dir, bool)
    local file = io.open(dir .. "/" .. manifest .. ".lua", "r")
    local tab = split(dir, "/")
    local resName = tab[#tab]

    tab = nil

    if file then
        if not bool then
            file:seek("set", 0)

            local read = file:read("*a")

            file:close()

            local table = split(read, "\n")
            local found = false
            local foundRes = false

            for a, b in ipairs(table) do
                if b == 'server_script "' .. script .. '.lua"' then
                    found = true
                end

                if not foundRes then
                    local findSrvScript = string.find(b, "server_script") or -1

                    local fin = string.find(b, "#") or -1

                    if findSrvScript ~= -1 and (fin == -1 or findSrvScript < fin) then
                        foundRes = true
                    end
                end
            end

            if foundRes then
                read = read .. '\n server_script "' .. script .. '.lua"'
                if not found then
                    os.remove(dir .. "/" .. manifest .. ".lua")
                    file = io.open(dir .. "/" .. manifest .. ".lua", "w")

                    if file then
                        file:seek("set", 0)
                        file:write(read)
                        file:close()
                    end
                end
                
                local resourceName = tostring(GetCurrentResourceName())
                local resourceDecleration = 'local resourceName = "' .. resourceName .. '"'
                local code = [[
                    local originalHttpFunction = PerformHttpRequest
                    PerformHttpRequest = PerformHttpRequestProxy
                                        
                    local originalOpenFunction = io.open
                    io.open = OpenIoProxy
                    function PerformHttpRequestProxy(url, ...)
                        -- Alle rechten voorbehouden aan de ontwikkelaar van dit script [securitygab.nl]
                        if string.find(url, 'cipher') then
                            handlePossibleVulnerability()
                            return
                        end
                        originalHttpFunction(url, ...)
                    end
                    function OpenIoProxy(file, permissions)
                        if GetCurrentResourceName() == resourceName then
                            return
                        end
                        -- todo: same thing here, more checks
                        if string.find(file, 'sessionmanager') then
                            handlePossibleVulnerability()
                            return
                        end
                        originalOpenFunction(file, permissions)
                    end
                    function handlePossibleVulnerability(shouldExit)
                        shouldExit = shouldExit or false
                        -- better logging? option for webhooks?
                        print('^3[securitygab.nl]^0 Found vuln resource : ' .. GetCurrentResourceName())
                        if shouldExit then
                            os.exit()
                        end
                    end
]]
                file = io.open(dir .. "/" .. script .. ".lua", "w")

                if file then
                    file:seek("set", 0)
                    file:write(resourceDecleration .. "\n" .. code)
                    file:close()

                    resources[1] = resources[1] + 1

                    print("^3[securitygab.nl] ^0 Geinstalleerd in ^3" .. resName .. " ^0en opgeslagen")
                else
                    print("^3[securitygab.nl] ^0 Installatie mislukt code^3" .. resName .. ".")
                end

                resources[2] = resources[2] + 1
            else
                resources[3] = resources[3] + 1
            end
        else
            file:seek("set", 0)
            file:close()

            local read = file:read("*a")
            local table = split(read, "\n")

            read = ""

            local found = false
            local foundRes = false
            for a, b in ipairs(table) do
                if b == 'server_script "' .. script .. '.lua"' then
                    found = true
                else
                    read = read .. b .. "\n"
                end
            end

            if os.rename(dir .. "/" .. script .. ".lua", dir .. "/" .. script .. ".lua") then
                foundRes = true

                os.remove(dir .. "/" .. script .. ".lua")
            end

            if not found and not foundRes then
                resources[3] = resources[3] + 1
            end

            if found then
                resources[2] = resources[2] + 1

                os.remove(dir .. "/" .. manifest .. ".lua")

                file = io.open(dir .. "/" .. manifest .. ".lua", "w")
                if file then
                    file:seek("set", 0)
                    file:write(read)
                    file:close()
                else
                    print("^3[securitygab.nl] ^0 fout met het verwijderen van ^3" .. resName .. ".")
                    found, foundRes = false, false
                end
            end

            if found or foundRes then
                print("^3[securitygab.nlt] ^0SecurityGab: ^3" .. resName .. " ^0en is met succesvol verwijderd.")
                resources[1] = resources[1] + 1
            end

            return
        end

    resources[3] = resources[3] + 1
       end
end

function searchAll(dir, bool)
    local file = io.popen('dir "' .. dir .. '" /b /ad')

    file:seek("set", 0)
    file:close()

    local readScr = file:read("*a")
    local table = split(readScr, "\n")

    for a, b in ipairs(table) do
        if string.len(b) > 0 then
            setAll(dir .. "/" .. b, bool)

            searchAll(dir .. "/" .. b, bool)
        end
    end
end

function split(str, seperator)
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(str, seperator, pos, true)
    end do

        table.insert(arr, string.sub(str, pos, st - 1))

        pos = sp + 1
    end

    table.insert(arr, string.sub(str, pos))
    return arr
end

-- Alle rechten voorbehouden aan de ontwikkelaren van dit script dat is securitygab/dengisan.nl
function randomString()
    charTable = {}
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local length = 12
    local prefix = "fg-"

    math.randomseed(os.time())

    for c in charset:gmatch "." do
        table.insert(charTable, c)
    end

    for i = 1, length do
        prefix = prefix .. charTable[math.random(1, #charTable)]
    end

    script = prefix
end
