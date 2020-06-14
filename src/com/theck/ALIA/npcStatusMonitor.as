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
	static var debugMode = false;
	
	public var char:Character;
	public var state:Number;
	
	static var gaiaRose:Number = 7945521;
	static var gaiaAlex:Number = 7945522;
	static var gaiaMei:Number = 7945523;
	static var podded:Number = 7854429; // also 7970812 (SM - E10) and 8934432 (E10), but this one seems to work
	static var podIncoming:Number = 8907521;
	static var knockedDown:Number = 7863490;
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
			char.SignalBuffAdded.Connect(DebugAnnounceBuffs, this);
			char.SignalInvisibleBuffAdded.Connect(DebugAnnounceBuffs, this);
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
		else if ( char.m_BuffList[incapped] || char.m_BuffList[knockedDown] ) {
			state = 2;
			StatusChanged.Emit();
		}
		else if ( char.m_BuffList[gaiaRose] || char.m_BuffList[gaiaAlex] || char.m_BuffList[gaiaMei] ) {
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
	
	private function DebugAnnounceBuffs(buffId:Number) {
		Debugger.DebugText("NSM: " + char.GetName() + " has gained buff " + LDBFormat.LDBGetText(50210, buffId) + " (" + buffId + ")", debugMode);
	}
	
}