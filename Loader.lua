local scripts={
    [73956553001240]="Volleyball_Legends",
    [18687417158]="Forsaken"
}

local game_script=scripts[game.GameId]
if game_script then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RimuruOnDiscord/Halcyon/refs/heads/main/"..game_script..".lua"))()
else
    game:GetService"Players".LocalPlayer:Kick("This game is not supported by Halcyon.")
end
