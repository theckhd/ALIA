/*
* ...
* @author theck
*/

import com.GameInterface.Game.Character;
import com.GameInterface.Playfield;
import com.Utils.ID32;
//import com.GameInterface.Targeting;
import com.GameInterface.UtilsBase;
import com.GameInterface.WaypointInterface;
import com.GameInterface.Game;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.Utils.GlobalSignal;
import com.theck.Utils.Common;
import com.theck.Utils.Debugger;
import gui.theck.TextFieldController;
import mx.utils.Delegate;
import flash.geom.Point;


class com.theck.ALIA.ALIA 
{
	static var lurkerLocked:Boolean;
	static var debugMode:Boolean = true;
	static var lurkerNameLocal:String = LDBFormat.LDBGetText(51000, 32030);
	private var m_player:Character;
	private var lurker:Character;
	private var controller:TextFieldController;
	
	// GUI stuff
	private var m_swfRoot:MovieClip;
    private var AnnounceText:TextField;
	private var pos:flash.geom.Point;
	
	// announcement flags
	private var Announce_Shadow1:Boolean;
	private var Announce_PS1:Boolean;
	private var Announce_PS2:Boolean;
	private var Announce_PS3:Boolean;
	private var Announce_FR:Boolean;
	
	public function ALIA(swfRoot:MovieClip){
        m_swfRoot = swfRoot;
    }
/*	
	public function ALIA(){
	
	}
*/
	public function Load(){
		Debugger.PrintText("ALIA loaded");
		
		m_player = Character.GetClientCharacter();	//can probably eliminate m_player eventually	
		lurkerLocked = false; // set locked flag to false
		
		// check for E10
		if IsNYR10(m_player.GetPlayfieldID()) {
			ConnectTargetChangedSignal()
		}
		
		// for debugging only
		/*if  IsNYRSM(m_player.GetPlayfieldID()) {
			ConnectTargetChangedSignal()
		}*/
		
		// Connect to PlayfieldChanged signal for hooking/unhooking TargetChanged
		WaypointInterface.SignalPlayfieldChanged.Connect(PlayfieldChanged, this);
	}

	public function Unload(){		
		// disconnect all signals
		ResetLurker();
		DisconnectTargetChangedSignal();
	}
	
	public function Activate(config:Archive){
		pos = Point(config.FindEntry("GUIPos", new Point(650, 0)));
		Debugger.DebugText("ALIA activated", debugMode);
	}

	public function Deactivate():Archive{
		var config = new Archive();
		config.AddEntry("GUIPos", pos);
		return config
	}
	
	static function IsNYR10(zone)
	{
		return (debugMode || zone == 5715); // E10 is 5715
	}
	
	static function IsNYRSM(zone)
	{
		return zone == 5710; //SM, E1, and E5 are all 5710
	}
	
	public function PlayfieldChanged(zone)
	{
		if (IsNYR10(zone))
		{
			Debugger.DebugText("You have entered E10 NYR", debugMode);	
			ConnectTargetChangedSignal()
		}
		else
		{		
			// disconnect all signals
			ResetLurker();
			DisconnectTargetChangedSignal();
		}
	}
		
	public function TargetChanged(id:ID32)
	{	
		//Debugger.DebugText("TargetChanged id passed is " + id,debugMode);
		
		/*
		// these all give "The Unutterable Lurker"
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode);
		Debugger.DebugText("51000,32433 is " + LDBFormat.LDBGetText(51000, 32433),debugMode);
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode); 
		*/
		
		// If we haven't yet locked on to lurker and this id is useful
		if (!lurkerLocked && !id.IsNull()) {
			
			// update current target variable
			var currentTarget = Character.GetCharacter(id);
			Debugger.DebugText("currentTarget GetName is " + currentTarget.GetName(), debugMode); //dump name for testing
		
			/*
			// this just checks for the condition we're using in the logic below
			Debugger.DebugText(currentTarget.GetName() == LDBFormat.LDBGetText(51000, 32030),debugMode);
			*/
			
			
			// if the current target's name is "The Unutterable Lurker" (32030, 32433, 32030 should all work here)
			if (currentTarget.GetName() == lurkerNameLocal ) {
				
				Debugger.DebugText("Your Target is E10 Lurker!!", debugMode);
				
				// store lurker variable, connect to statchanged signal
				lurker = currentTarget;
				lurker.SignalStatChanged.Connect(LurkerStatChanged, this);
				
				//Connect deat/wipe signals to a function that resets signal connections 
				lurker.SignalCharacterDied.Connect(ResetLurker, this);
				lurker.SignalCharacterDestructed.Connect(ResetLurker, this);
				
				// lock on lurker so that we don't continue to check targets anymore
				lurkerLocked = true;
				Debugger.DebugText("Lurker Locked!!", debugMode)
				
				//set flags for announcements to true
				Announce_Shadow1 = true;
				Announce_PS1 = true;
				Announce_PS2 = true;
				Announce_PS3 = true;
				Announce_FR = true;
			}
		}
	}
	
	public function LurkerStatChanged(stat)
	{
		//Debugger.DebugText("Lurker's Stats Changed",debugMode);
		
		if (stat == 27) {
		
			// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
			var currentHP = lurker.GetStat(27, 1);
			var maxHP = lurker.GetStat(1, 1);
			
			// Shadow Incoming at 26369244 (75%)
			if (currentHP < maxHP * 0.78 && Announce_Shadow1) {
				com.GameInterface.UtilsBase.PrintChatText("Shadow Incoming");
				Debugger.ShowFifo("Shadow Incoming");
				Announce_Shadow1 = false;
			}
			
			// First Personal Space at 23556525 (67%)
			else if (currentHP < maxHP * 0.70 && Announce_PS1) {
				com.GameInterface.UtilsBase.PrintChatText("PS 1 incoming");
				Debugger.ShowFifo("PS 1 Incoming");
				Announce_PS1 = false;
			}
			
			// Second Personal Space at 15821546 (45%)
			else if (currentHP < maxHP * 0.48 && Announce_PS2) {
				com.GameInterface.UtilsBase.PrintChatText("PS 2 incoming");
				Debugger.ShowFifo("PS 2 Incoming");
				Announce_PS2 = false;
			}
			
			// Third Personal Space at 8789478 (25%)
			else if (currentHP < maxHP * 0.28 && Announce_PS3) {
				com.GameInterface.UtilsBase.PrintChatText("PS 3 incoming");
				Debugger.ShowFifo("PS 3 Incoming");
				Announce_PS3 = false;
			}
			
			// Final Resort at 1757950 (5%)
			else if (currentHP < maxHP * 0.08 && Announce_FR) {
				com.GameInterface.UtilsBase.PrintChatText("Final Resort incoming");
				Debugger.ShowFifo("Final Resort Incoming");
				Announce_FR = false;
			}
		}
	}
	
	public function ResetLurker()
	{
		Debugger.DebugText("Lurker signals disconnected, lurker unlocked", debugMode)
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(ResetLurker, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker, this);
		lurkerLocked = false;
	}
	
	public function ConnectTargetChangedSignal()
	{
		m_player.SignalOffensiveTargetChanged.Connect(TargetChanged, this);
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		CreateAnnouncement();
		Debugger.DebugText("TargetChanged connected", debugMode)
		
	}
	
	
	public function DisconnectTargetChangedSignal()
	{
		m_player.SignalOffensiveTargetChanged.Disconnect(TargetChanged, this);
		Debugger.DebugText("TargetChanged disconnected", debugMode)
	}
	
	
	// GUI stuff
	
	public function CreateAnnouncement(){
        controller = new TextFieldController(m_swfRoot);
        controller.UpdateText("Final resort incoming");
        GuiEdit();
		Debugger.DebugText("Announcement GUI Created");
    }
    
    public function StartDrag(){
        controller.clip.startDrag();
    }

    public function StopDrag(){
        controller.clip.stopDrag();
        pos = Common.getOnScreen(controller.clip);
        //store the pos in config when deactivating
    }

    public function GuiEdit(state:Boolean){
		if (state) {
			controller.clip.onPress = Delegate.create(this, StartDrag);
			controller.clip.onRelease = Delegate.create(this, StopDrag);
			
		} else {
			controller.clip.stopDrag();
			controller.clip.onPress = undefined;
			controller.clip.onRelease = undefined;
		}
    }
	
}