local ObjPlacer = {}
local PlacingObject = false
local tempObj = nil

local Keys = {
    ["Q"] = 44, ["E"] = 38, ["ENTER"] = 18, ["X"] = 73
}

local function RotationToDirection(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestSweptSphere(cameraCoord.x, cameraCoord.y, cameraCoord.z,
        destination.x, destination.y, destination.z, 0.2, 339, PlayerPedId(), 4))
    return b, c, e
end

function ObjPlacer.placePed(data)
    local model = type(data.model) == 'string' and joaat(data.model) or data.model
    if PlacingObject then return end
    local playerCoords = GetEntityCoords(cache.ped)
    lib.requestModel(model)
    local heading = 0.0
    tempObj = CreatePed(0, model, playerCoords.x, playerCoords.y, playerCoords.z, heading, false, false)
    SetPedDesiredHeading(tempObj, heading)
    SetEntityAlpha(tempObj, 150)
    SetEntityCollision(tempObj, false, false)

    PlacingObject = true
    local rackCoords = nil
    local inRange = false

    local function deleteObj()
        PlacingObject = false
        SetEntityDrawOutline(tempObj, false)
        DeleteEntity(tempObj)
        tempObj = nil
        lib.hideTextUI()
    end

    lib.showTextUI(
        '**[Q/E]**   -   Rotate  \n' ..
        '**[ENTER]**   -   Place Ped  \n' ..
        '**[X]**   -   Abandon  \n'
    )

    CreateThread(function()
        while PlacingObject do
            local hit, coords, entity = RayCastGamePlayCamera(20.0)
            rackCoords = coords
            DisableControlAction(0, Keys["Q"], true) -- cover
            DisableControlAction(0, Keys["E"], true) -- cover

            if hit then
                SetEntityCoords(tempObj, coords.x, coords.y, coords.z)
                PlaceObjectOnGroundProperly(tempObj)
                SetEntityDrawOutline(tempObj, true)
            end

            if #(rackCoords - GetEntityCoords(cache.ped)) < 2.0 then
                SetEntityDrawOutlineColor(2, 241, 181, 255)
                inRange = true
            else --not in range
                inRange = false
                SetEntityDrawOutlineColor(244, 68, 46, 255)
            end

            if IsControlPressed(0, Keys["X"]) then
                deleteObj()
                PlacingObject = false
            end

            if IsDisabledControlPressed(0, Keys["Q"]) then
                heading = heading + 2
                if heading > 360 then heading = 0.0 end
            end

            if IsDisabledControlPressed(0, Keys["E"]) then
                heading = heading - 2
                if heading < 0 then heading = 360.0 end
            end

            SetEntityHeading(tempObj, heading)
            if IsControlJustPressed(0, Keys["ENTER"]) then
                local objRot = GetEntityHeading(tempObj)
                local objPos = GetEntityCoords(tempObj)
                deleteObj()
                if data.onFinish then
                    data.onFinish({ pos = vec4(objPos.x, objPos.y, objPos.z, objRot) })
                end
            end
            Wait(0)
        end
    end)
end

return ObjPlacer
