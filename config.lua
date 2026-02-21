Config = {}

Config.MinSpeed = 50.0               -- Speed required to start scoring
Config.Proximity = 5.0               -- Distance to other cars to get points
Config.NearMissDist = 2.0            -- Distance for Near Miss bonus
Config.SessionLimit = 15             -- Timer duration in MINUTES

Config.MultiplierStep = 0.05         
Config.MaxMultiplier = 5.0           
Config.SpeedDivider = 60.0 

Config.Ranks = {
    {minMult = 5.0, label = "NO HESI GOD"},
    {minMult = 4.0, label = "TRAFFIC MENACE"},
    {minMult = 3.0, label = "ELITE CUTTER"},
    {minMult = 2.0, label = "STREET RACER"},
    {minMult = 0.0, label = "ROOKIE"}
}