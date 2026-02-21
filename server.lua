local leaderboard = {}

RegisterNetEvent('nohesi:submitScore', function(score)
    local _source = source
    local name = GetPlayerName(_source)

    table.insert(leaderboard, {name = name, score = score})
    
    -- Sort: Highest to Lowest
    table.sort(leaderboard, function(a, b) return a.score > b.score end)

    -- Keep only top 10
    if #leaderboard > 10 then table.remove(leaderboard) end
end)