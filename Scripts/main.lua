-- CustomPosters — Debug mount paths + material texture references
-- Press J near a poster

local UEHelpers = require("UEHelpers")
print("[CustomPosters] Debug mount paths — press J\n")

local function findPosterMesh()
    local controller = UEHelpers:GetPlayerController()
    local pawn = controller.Pawn
    local playerLoc = pawn:K2_GetActorLocation()
    local nearest, nearestDist = nil, 999999
    local allActors = FindAllOf("Actor")
    if allActors then
        for _, actor in ipairs(allActors) do
            if actor:IsValid() then
                local ok, cn = pcall(function() return actor:GetClass():GetFName():ToString() end)
                if ok and cn and string.find(string.lower(cn), "poster", 1, true) then
                    local ok2, loc = pcall(function() return actor:K2_GetActorLocation() end)
                    if ok2 then
                        local dx = loc.X - playerLoc.X
                        local dy = loc.Y - playerLoc.Y
                        local dz = loc.Z - playerLoc.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz) / 100
                        if dist < nearestDist then nearestDist = dist; nearest = actor end
                    end
                end
            end
        end
    end
    if not nearest then return nil end
    local mesh = nil
    for _, prop in ipairs({"StaticMesh", "BaseMesh", "Mesh"}) do
        local ok, m = pcall(function() return nearest[prop] end)
        if ok and m and m:IsValid() then mesh = m; break end
    end
    return mesh
end

RegisterKeyBind(Key.J, function()
    ExecuteInGameThread(function()
        print("\n[CustomPosters] === MOUNT PATH DEBUG ===\n")

        -- Try every possible path for our material
        local paths = {
            "/Game/M_CustomerPoster.M_CustomerPoster",
            "/Game/Content/M_CustomerPoster.M_CustomerPoster",
            "/CustomerPosterMat/Content/M_CustomerPoster.M_CustomerPoster",
            "/CustomerPosterMat/M_CustomerPoster.M_CustomerPoster",
            "/Content/M_CustomerPoster.M_CustomerPoster",
            "/M_CustomerPoster.M_CustomerPoster",
        }
        local customMat = nil
        for _, path in ipairs(paths) do
            local mat = StaticFindObject(path)
            if mat then
                print(string.format("[CustomPosters] FOUND at: %s -> %s\n", path, mat:GetFullName()))
                customMat = mat
            else
                print(string.format("[CustomPosters] NOT at: %s\n", path))
            end
        end

        -- Try finding the texture too
        print("[CustomPosters] --- Texture search ---\n")
        local texPaths = {
            "/Game/main.main",
            "/Game/Content/main.main",
            "/CustomerPosterMat/Content/main.main",
            "/CustomerPosterMat/main.main",
            "/Content/main.main",
        }
        for _, path in ipairs(texPaths) do
            local t = StaticFindObject(path)
            if t then
                print(string.format("[CustomPosters] TEX FOUND at: %s -> %s\n", path, t:GetFullName()))
            else
                print(string.format("[CustomPosters] TEX NOT at: %s\n", path))
            end
        end

        -- If we found the material, inspect its texture references
        if customMat then
            print("[CustomPosters] --- Material texture references ---\n")
            local ok, tpv = pcall(function() return customMat.TextureParameterValues end)
            if ok and tpv then
                local ok2, len = pcall(function() return #tpv end)
                if ok2 and len then
                    print(string.format("[CustomPosters] TextureParamValues: %d\n", len))
                    for i = 1, len do
                        pcall(function()
                            local entry = tpv[i]
                            local pname = ""
                            pcall(function() pname = entry.ParameterInfo.Name:ToString() end)
                            local tname = "nil"
                            local texRef = entry.ParameterValue
                            if texRef then
                                local ok3, fn = pcall(function() return texRef:GetFullName() end)
                                if ok3 then tname = fn end
                                local ok4, valid = pcall(function() return texRef:IsValid() end)
                                print(string.format("[CustomPosters]   [%d] '%s' -> %s (valid=%s)\n",
                                    i, pname, tname, tostring(ok4 and valid)))
                            else
                                print(string.format("[CustomPosters]   [%d] '%s' -> NULL\n", i, pname))
                            end
                        end)
                    end
                end
            else
                print("[CustomPosters] No TextureParameterValues on material\n")
            end

            -- Apply it to poster
            local mesh = findPosterMesh()
            if mesh then
                pcall(function() mesh:SetMaterial(3, customMat) end)
                print("[CustomPosters] Applied material to poster\n")
            end
        end

        print("[CustomPosters] === DONE ===\n\n")
    end)
end)
