local scripts={
    [6931042565]="Volleyball_Legends",
    [6331902150]="Forsaken"
}

local game_script=scripts[game.GameId]
if game_script then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RimuruOnDiscord/Halcyon/refs/heads/main/"..game_script..".lua"))()
else
    game:GetService"Players".LocalPlayer:Kick("This game is not supported by Halcyon.")
end
