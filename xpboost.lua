local friendcodes = {
	"XXXXX-XXXX", -- Leader
	"XXXXX-XXXX", -- Player
}

local js = panorama.open()
local lobbyapi = js.LobbyAPI
local compapi = js.CompetitiveMatchAPI
local gameapi =  js.GameStateAPI
local partylistapi = js.PartyListAPI
local PartyBrowserAPI = js.PartyBrowserAPI
local friendsapi = js.FriendsListAPI
local Active = false
local Loop = true

local settings = {
	update = {
		Options = {
			action = "private",
		},
		Game =  {
			prime = 1,
			state = "lobby",
			ark = 10,
			mode = "cooperative",
			type ="cooperative",
			mapgroupname = "mg_dz_blacksite",
			questid = 1106,
			gamemodeflags = 0
		}
	}
}
local menu = {
	autoinvite = ui.new_checkbox("LUA","A","Auto invite player"),
	acceptinvite = ui.new_checkbox("LUA","A","Auto accept invite from leader"),
	autodisconnect = ui.new_checkbox("LUA","A","Auto disconnect"),
}

local function on_paint_ui(ctx)	
	if (ui.get(menu.acceptinvite)) then
		local hostID = friendsapi.GetXuidFromFriendCode(friendcodes[1])
		for i=1, PartyBrowserAPI.GetInvitesCount() do
			local lobby_id = PartyBrowserAPI.GetInviteXuidByIndex(i-1)
			if PartyBrowserAPI.GetPartyMemberXuid(lobby_id, 0) == hostID then
				PartyBrowserAPI.ActionJoinParty(lobby_id)
				break
			end
		end
	end
	if Active then
		if Loop then
			Loop = false
			client.delay_call(2.5, function() 
				if not (gameapi.IsConnectedOrConnectingToServer() == true) then
					if lobbyapi.GetMatchmakingStatusString() == "" then
						if not compapi.HasOngoingMatch() then		
							if not lobbyapi.IsSessionActive() then
								lobbyapi.CreateSession()
							end
							lobbyapi.UpdateSessionSettings( settings );
							if ui.get(menu.autoinvite) then
								local xuid = friendsapi.GetXuidFromFriendCode(friendcodes[2])
								friendsapi.ActionInviteFriend(xuid, '')
								if partylistapi.GetCount() == 2 then
									lobbyapi.StartMatchmaking("", "ct", "t", "")
								end
							else
								lobbyapi.StartMatchmaking("","ct","t","")
							end
						end
					end
				end
				Loop = true
			end)
		end
	end
end
client.set_event_callback("paint_ui", on_paint_ui)

local enable_button = ui.new_button("LUA", "A", "Start auto queue", function() Active = true
	client.log("Started")
end)

local function stop_auto_queue()
	client.delay_call(1, function() lobbyapi.StopMatchmaking() end)
	Active = false
end
local disable_button = ui.new_button("LUA", "A", "Stop auto queue", stop_auto_queue)

client.set_event_callback("cs_win_panel_match",  function()
    if ui.get(menu.autodisconnect) then
        print("Game ended. Disconnecting in 3s")
        client.delay_call(3, function()
            client.exec("disconnect")
        end)
    end
end)

client.set_event_callback("paint_ui", function(e)
    ui.set_visible(disable_button, Active)
    ui.set_visible(enable_button, not Active)
end)
