local isEnabled = false
local score, multiplier, combo = 0, 1.0, 0
local lastHealth = 1000.0
local lastSpeed = 0.0
local lastActiveTime = 0
local sessionStartTime = 0
local isTimerRunning = false
local scoredVehicles = {} 
local isResetting = false

-- Full Reset Function
local function ResetEverything()
    score = 0
    multiplier = 1.0
    combo = 0
    lastActiveTime = 0
    isTimerRunning = false
    sessionStartTime = 0
    scoredVehicles = {} 
    
    SendNUIMessage({ action = "score_wipe" })
end

-- Command to Toggle Script
RegisterCommand("nohesi", function()
    isEnabled = not isEnabled
    if not isEnabled then 
        ResetEverything() 
        SendNUIMessage({ action = "hide" })
    else 
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then 
            lastHealth = GetVehicleBodyHealth(veh)
            lastSpeed = (GetEntitySpeed(veh) * 2.236936)
            SendNUIMessage({ action = "show" }) 
        else
            isEnabled = false
            -- Optional: lib.notify({title = 'MX PROJECT', description = 'You must be driving!', type = 'error'})
        end 
    end
end)

-- Main Logic Loop
Citizen.CreateThread(function()
    while true do
        local sleep = 1000 
        if isEnabled then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local isDriver = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped)

            if not isDriver then
                -- Player exited or moved seats: Force Hide and Reset
                if score > 0 or isTimerRunning then
                    ResetEverything()
                end
                SendNUIMessage({ action = "hide" })
                sleep = 1000
            else
                -- Player is Driving: Active Logic
                sleep = 50 
                local currentHealth = GetVehicleBodyHealth(veh)
                local currentSpeed = (GetEntitySpeed(veh) * 2.236936)
                local pCoords = GetEntityCoords(veh)

                -- 1. INSTANT CRASH DETECTION
                if (currentHealth < lastHealth - 0.5) or (lastSpeed > 20.0 and (lastSpeed - currentSpeed) > 15.0) then
                    ResetEverything()
                end
                lastHealth = currentHealth
                lastSpeed = currentSpeed

                -- 2. TIMER LOGIC
                if isTimerRunning then
                    local timeLeft = (Config.SessionLimit * 60 * 1000) - (GetGameTimer() - sessionStartTime)
                    if timeLeft <= 0 then 
                        ResetEverything() 
                    else 
                        SendNUIMessage({ action = "timer", time = math.floor(timeLeft / 1000) }) 
                    end
                end

                -- 3. SCORING LOGIC
                if currentSpeed > Config.MinSpeed then
                    local vehicles = GetGamePool('CVehicle')
                    local inRange, foundNewCar = false, false
                    
                    for i=1, #vehicles do
                        local target = vehicles[i]
                        if target ~= veh then
                            local tCoords = GetEntityCoords(target)
                            local dist = #(pCoords - tCoords)
                            
                            -- Allow car to be scored again if player moves 50m away
                            if scoredVehicles[target] and dist > 50.0 then
                                scoredVehicles[target] = nil
                            end

                            -- Check for new "cut"
                            if dist < Config.Proximity and not scoredVehicles[target] then
                                inRange = true
                                foundNewCar = true
                                scoredVehicles[target] = true
                                break 
                            end
                        end
                    end

                    if inRange and foundNewCar then
                        if not isTimerRunning then 
                            isTimerRunning = true 
                            sessionStartTime = GetGameTimer() 
                            SendNUIMessage({ action = "show" })
                        end

                        combo = combo + 1
                        multiplier = math.min(Config.MaxMultiplier, multiplier + Config.MultiplierStep)
                        local speedFactor = currentSpeed / Config.SpeedDivider
                        score = score + math.floor((currentSpeed * multiplier) * speedFactor)

                        SendNUIMessage({ 
                            action = "update", 
                            score = score, 
                            multiplier = string.format("%.1f", multiplier), 
                            speedMulti = string.format("+%.2fx", speedFactor), 
                            combo = combo
                        })
                        Citizen.Wait(300) -- Tick rate for scoring
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)