# AirDrop - Core
A simple API to "call" an airdrop easly

## ConVars
`sm_airdrop_box` Default Value: `models/props_crates/static_crate_40.mdl` Desc: `CVar to set the model of the box in the AirDrop`
`sm_airdrop_parachute` Default Value: `models/parachute/parachute_ark.mdl` Desc: `Cvar to set the model of the parachute in the AirDrop`
`sm_airdrop_max_distance` Default Value: `350.0` Desc: `Max distance that a Box can be pressed`
`sm_airdrop_landing_zone` Default Value: `70.0` Desc: `Landing zone radius in which the player can't enter while the box in falling( To avoid the player compenetrates with the Box - 0.0 To disable)`
`sm_airdrop_landing_beam` Default Value: `1` Desc: `Make a beam from where the AirDrop is coming`
`sm_airdrop_check_solid` Default Value: `1` Desc: `Check if the AirDrop was called underground (of with a place where is a ceiling), and try to spawn above it`

## Infos
Get more parachute models [here](https://gamebanana.com/skins/cats/11622) 

## ToDo
1. Add Native: `AirDrop_CallEx` To get the Parachute EntIndex too.
2. You suggestions!


# Develepers Infos

## Natives
`AirDrop_Call(float endpoint[3], bool bForward = true;)`
Use this to call an airdrop, using only an endpoint (The height is automatically calculated)
It returns the EntIndex of the box, -1 if the entity was spawned outside of the world, or -2 if the event was Stopped by the forward

## Forwards
`AirDrop_Called(int iBoxEnt, int iParaEnt, float vBoxOrigin[3])`
Called when an AirDrop is begining to be called, return Plugin_Handled or greater to stop, or Plugin_Continue to continue with the normal call.

`AirDrop_BoxUsed(int client, int ent)`
Called when a client press +use on an "AirDrop Box".

## Example

You can see an example of this here: [Call an airdrop when throwing a decoy](https://github.com/Hexer10/AirDrop-Core/blob/master/scripting/Examples/AirDropCaller_Decoy.sp)


