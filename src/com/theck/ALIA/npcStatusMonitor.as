/**
 * ...
 * @author theck
 */
import com.GameInterface.Game.Character;
import com.theck.Utils.Debugger;
import com.Utils.Signal;
import com.Utils.LDBFormat;

class com.theck.ALIA.npcStatusMonitor
{
	// toggle debug messages
	static var debugMode = false;
	
	public var char:Character;
	public var state:Number;
	
	static var gaiaRose:Number = 7945521; // 7945521: "Gaia Incarnate - Rose",
	static var gaiaAlex:Number = 7945522; // 7945522: "Gaia Incarnate - Alex",
	static var gaiaMei:Number = 7945523; // 7945523: "Gaia Incarnate - Mei Ling",
	static var gaiaZuberi:Number = 7970992; // 7970992: "XX_Zuberi Fluff" - invisible. TODO: Check if this is what triggers on E17
	static var podded:Number = 7854429; // 7854429: "From Beneath You, It Devours", this one seems to coincide with pod being killed
										// 		  :  also seen: 7970812 (SM - E10, falls off ~1-2s after gain) and 8934432 (E10)
	static var podIncoming:Number = 8907521; // 8907521": "Inevitable Doom",
	static var knockedDown:Number = 7863490; // 7863490: "Knocked Down", this happens when a fist hits them, but doesn't disable anything
	static var incapped:Number = 8907542;
	// other interesting casts:
	// 9124231 - Digestive Slime
	
	public var StatusChanged:Signal;
	
	public function npcStatusMonitor(_char:Character) 
	{
		char = _char;
		state = 0;
        StatusChanged = new Signal();
        char.SignalBuffAdded.Connect(UpdateStatus, this);
		char.SignalInvisibleBuffAdded.Connect(UpdateStatus, this);
		char.SignalBuffRemoved.Connect(UpdateStatus, this);
		char.SignalInvisibleBuffUpdated.Connect(UpdateStatus, this);
		
		if debugMode {
			char.SignalBuffAdded.Connect(DebugAnnounceBuffAdded, this);
			char.SignalInvisibleBuffAdded.Connect(DebugAnnounceInvisibleBuffAdded, this);
			char.SignalBuffRemoved.Connect(DebugAnnounceBuffRemoved, this);
			char.SignalInvisibleBuffUpdated.Connect(DebugAnnounceInvisibleBuffUpdated, this);
		}
		
		// on creation, check current buffs to find status in case of /reloadui
		UpdateStatus();
    }
        
	private function UpdateStatus() {
		if char.m_BuffList[podded] {
			state = 4;
			StatusChanged.Emit();
		}
		else if char.m_BuffList[podIncoming] {
			state = 3;
			StatusChanged.Emit();
		}
		else if char.m_BuffList[incapped] {
			state = 2;
			StatusChanged.Emit();
		}
		else if ( char.m_BuffList[gaiaRose] || char.m_BuffList[gaiaAlex] || char.m_BuffList[gaiaMei] || char.m_InvisibleBuffList[gaiaZuberi] ) {
			state = 1;
			StatusChanged.Emit();
		}
		else { 
			state = 0;
			StatusChanged.Emit();
		}
		Debugger.DebugText("NSM.UpdateStatus(): " + char.GetName() + " is in state " + state, debugMode);
	}
	
	public function GetStatus():Number {
		return state;
	}
	
	//// DEBUGGING //////
	
	private function DebugAnnounceBuffAdded(buffId:Number) {
		Debugger.DebugText("NSM: " + char.GetName() + " has gained buff " + LDBFormat.LDBGetText(50210, buffId) + " (" + buffId + ")", debugMode);
	}
	
	private function DebugAnnounceInvisibleBuffAdded(buffId:Number) {
		Debugger.DebugText("NSM: " + char.GetName() + " has gained invisible buff " + LDBFormat.LDBGetText(50210, buffId) + " (" + buffId + ")", debugMode);
	}
	
	private function DebugAnnounceBuffRemoved(buffId:Number) {
		Debugger.DebugText("NSM: " + char.GetName() + " has lost buff " + LDBFormat.LDBGetText(50210, buffId) + " (" + buffId + ")", debugMode);
	}
	
	private function DebugAnnounceInvisibleBuffUpdated(buffId:Number) {
		Debugger.DebugText("NSM: " + char.GetName() + " has updated invisible buff " + LDBFormat.LDBGetText(50210, buffId) + " (" + buffId + ")", debugMode);
	}
	
}