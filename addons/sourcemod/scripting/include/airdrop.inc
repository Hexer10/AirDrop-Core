/*
**
*/
#if defined _AirDropCore_included
#endinput
#endif
#define _AirDropCore_included


 /**
 * Call an AirDrop
 * 
 * @param	endpoint	EndPoint of the Box (The Hight is automatically calculated)
 * @param	bForward	Set to false, to negate the call of AirDrop_Called forward
 *
 * @return 				Box Entity Index or -1 if Entity were OutSide the world, -2 if the call was stopped by the AirDrop_Called forward
 */
native int AirDrop_Call(float endpoint[3], bool bForward = true);



 /**
 * Called when an AirDrop is beging to be spawnd
 * 
 * @param	iBoxEnt		Entity Index of the Box
 * @param	iParaEnt	Entity Index of the Parachute
 *
 * @return 				Plugin_Handle to stop the Call or Plugin_Continue to continue the execution
 */
forward Action AirDrop_Called(int iBoxEnt, int iParaEnt, float vBoxOrigin[3]);


 /**
 * Called when a Client have pressed '+use' on an "AirDrop" Box
 * 
 * @param	client		Client Index
 * @param	iParaEnt	Entity Index of the Box
 */
forward void AirDrop_BoxUsed(int client, int ent);


#if !defined REQUIRE_PLUGIN
public __pl_AirDropCore_SetNTVOptional()
{
	MarkNativeAsOptional("AirDrop_Call");
}
#endif


public SharedPlugin __pl_AirDropCore = 
{
	name = "AirDropCore", 
	file = "AirDropCore.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};
