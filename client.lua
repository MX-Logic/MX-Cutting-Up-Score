local isEnabled = false
local score, multiplier, combo = 0, 1.0, 0
local lastHealth = 1000.0
local lastSpeed = 0.0
local lastActiveTime = 0
local sessionStartTime = 0
local isTimerRunning = false
local scoredVehicles = {} 

local function ResetEverything()
    -- Reset all logic variables immediately
    score = 0
    multiplier = 1.0
    combo = 0
    lastActiveTime = 0
    isTimerRunning = false
    sessionStartTime = 0
    scoredVehicles = {} 
    
    -- Tell UI to clear numbers instantly
    SendNUIMessage({ action = "score_wipe" })
end

RegisterCommand("nohesi", function()
    isEnabled = not isEnabled
    if not isEnabled then 
        ResetEverything() 
        SendNUIMessage({ action = "hide" })
    else 
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then 
            lastHealth = GetVehicleBodyHealth(veh)
            lastSpeed = (GetEntitySpeed(veh) * 2.236936)
            SendNUIMessage({ action = "show" }) 
        else
            isEnabled = false
        end 
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if isEnabled then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                sleep = 50 
                local currentHealth = GetVehicleBodyHealth(veh)
                local currentSpeed = (GetEntitySpeed(veh) * 2.236936)
                local pCoords = GetEntityCoords(veh)

                -- INSTANT CRASH DETECTION
                if (currentHealth < lastHealth - 0.5) or (lastSpeed > 20.0 and (lastSpeed - currentSpeed) > 15.0) then
                    ResetEverything()
                end
                lastHealth = currentHealth
                lastSpeed = currentSpeed

                -- TIMER
                if isTimerRunning then
                    local timeLeft = (Config.SessionLimit * 60 * 1000) - (GetGameTimer() - sessionStartTime)
                    if timeLeft <= 0 then 
                        ResetEverything() 
                    else 
                        SendNUIMessage({ action = "timer", time = math.floor(timeLeft / 1000) }) 
                    end
                end

                -- SCORING logic remains the same
                if currentSpeed > Config.MinSpeed then
                    local vehicles = GetGamePool('CVehicle')
                    local inRange = false
                    
                    for i=1, #vehicles do
                        local target = vehicles[i]
                        if target ~= veh then
                            local dist = #(pCoords - GetEntityCoords(target))
                            if scoredVehicles[target] and dist > 50.0 then scoredVehicles[target] = nil end
                            if dist < Config.Proximity and not scoredVehicles[target] then
                                inRange = true
                                scoredVehicles[target] = true
                                break 
                            end
                        end
                    end

                    if inRange then
                        if not isTimerRunning then isTimerRunning = true sessionStartTime = GetGameTimer() end
                        combo = combo + 1
                        multiplier = math.min(Config.MaxMultiplier, multiplier + Config.MultiplierStep)
                        score = score + math.floor((currentSpeed * multiplier) * (currentSpeed / Config.SpeedDivider))
                        lastActiveTime = GetGameTimer()

                        SendNUIMessage({ 
                            action = "update", 
                            score = score, 
                            multiplier = string.format("%.1f", multiplier), 
                            speedMulti = string.format("+%.2fx", currentSpeed / Config.SpeedDivider), 
                            combo = combo, 
                            active = true 
                        })
                        Citizen.Wait(300)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)