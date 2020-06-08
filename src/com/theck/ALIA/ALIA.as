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
	// toggle debug messages and enable addon outisde of NYR
	static var debugMode:Boolean = false;
	
	static var lurkerLocked:Boolean;
	static var lurkerNameLocal:String = LDBFormat.LDBGetText(51000, 32030);
	static var stringShadowOutOfTime:String = LDBFormat.LDBGetText(50210, 8934410); //"Shadow Out Of Time";
	static var stringPersonalSpace:String = LDBFormat.LDBGetText(50210, 8934415); //"Personal Space";
	static var stringFinalResort:String = LDBFormat.LDBGetText(50210, 7963851); //"Final Resort";
	static var textDecayTime:Number = 10;
	
	private var m_player:Character;
	private var lurker:Character;
	private var controller:TextFieldController;
	
	// GUI stuff
	private var m_swfRoot:MovieClip;
    private var AnnounceText:TextField;
	private var m_pos:flash.geom.Point;
	static var imminentColor:Number = 0xFF0000;
	
	// announcement flags
	private var Ann_SB1:Array = new Array(true, true, true, true); // order: incomingCheck, imminentCheck, healthCheck, castCheck
	private var Ann_FR:Array = new Array(true, true, true, true);
	private var Ann_PS1:Array = new Array(true, true, true); // order: incomingCheck, imminentCheck, healthCheck
	private var Ann_PS2:Array = new Array(true, true, true);
	private var Ann_PS3:Array = new Array(true, true, true);
	
	public function ALIA(swfRoot:MovieClip){
        m_swfRoot = swfRoot;
    }

	public function Load(){
		Debugger.PrintText("Loaded");
		if (debugMode) {Debugger.DebugText("Debug mode enabled");}
		
		m_player = Character.GetClientCharacter();	//can probably eliminate m_player eventually	
		lurkerLocked = false; // set locked flag to false
		
		// check for E10
		if IsNYR(m_player.GetPlayfieldID()) {
			ConnectTargetChangedSignal()
		}
		
		// Connect to PlayfieldChanged signal for hooking/unhooking TargetChanged
		WaypointInterface.SignalPlayfieldChanged.Connect(PlayfieldChanged, this);
		
		//create text field
		CreateTextField();
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		
		
		
		// debugging text strings
		Debugger.DebugText("~~~Text String testing~~", debugMode);
		Debugger.DebugText("shadow: " + stringShadowOutOfTime, debugMode);
		Debugger.DebugText("ps: " + stringPersonalSpace, debugMode);
		Debugger.DebugText("shadow: " + stringFinalResort, debugMode);
		// these all give "The Unutterable Lurker"
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode);
		Debugger.DebugText("51000,32433 is " + LDBFormat.LDBGetText(51000, 32433),debugMode);
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode); 
		Debugger.DebugText("~~~~~~~~~~~~~~~~~~~~~~~", debugMode);
		
	}

	public function Unload(){		
		// disconnect all signals
		ResetLurker();
		DisconnectTargetChangedSignal();
	}
	
	public function Activate(config:Archive){
		Debugger.DebugText("Activated", debugMode);
		
		// Move text to desired position
		//m_pos = config.FindEntry("ALIA_textPosition"), new Point(650, 650));
		m_pos = config.FindEntry("ALIA_textPosition");
		Debugger.DebugText("x: " + m_pos.x + "  y: " + m_pos.y, debugMode);
		controller.setPos(m_pos);
		
		// update visibility based on zone
		controller.setVisible(IsNYR(m_player.GetPlayfieldID()));
	}

	public function Deactivate():Archive{
		Debugger.DebugText("Deactivated", debugMode);
		
		// save the current position in the config
		var config = new Archive();
		Debugger.DebugText("x: " + m_pos.x + "  y: " + m_pos.y, debugMode);
		config.AddEntry("ALIA_textPosition", m_pos);
		return config
	}
	
	static function IsNYR10(zone)
	{
		return (debugMode || zone == 5715); // E10 is 5715, SM, E1, and E5 are all 5710
	}
	static function IsNYR(zone)
	{
		return (debugMode || IsNYR10(zone) || zone == 5710); // E10 is 5715, SM, E1, and E5 are all 5710
	}
		
	public function PlayfieldChanged(zone)
	{
		// update text visibility
		controller.setVisible(IsNYR10(zone));
		controller.stopBlink();
		
		// if we're in NYR10, connect target changed signal for Lurker Locking
		if (IsNYR(zone))
		{
			Debugger.DebugText("You have entered E10 NYR", debugMode);	
			ConnectTargetChangedSignal();
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
				lurker.SignalCommandStarted.Connect(LurkerCasting, this);
				
				//Connect deat/wipe signals to a function that resets signal connections 
				lurker.SignalCharacterDied.Connect(ResetLurker, this);
				lurker.SignalCharacterDestructed.Connect(ResetLurker, this);
				
				// lock on lurker so that we don't continue to check targets anymore
				lurkerLocked = true;
				Debugger.DebugText("Lurker Locked!!", debugMode)
				
				//set flags for announcements to true
				ResetAnnounceFlags();
			}
		}
	}
	
	public function ResetAnnounceFlags()
	{
		Ann_SB1 = [true, true, true, true];
		Ann_PS1 = [true, true, true];
		Ann_PS2 = [true, true, true];
		Ann_PS3 = [true, true, true];
		Ann_FR = [true, true, true, true];
	}
	
	public function LurkerStatChanged(stat)
	{
		//Debugger.DebugText("Lurker's Stats Changed",debugMode);
		
		if (stat == 27) {
		
			// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
			var currentHP = lurker.GetStat(27, 1);
			var maxHP = lurker.GetStat(1, 1);
			var pct = currentHP / maxHP;
			//dDebugger.DebugText("Health % is " + pct * 100 + "%", debugMode);
			
			// Shadow Incoming at 26369244 (75%)
			if (Ann_SB1[2]) 
			{
				if (pct < 0.749 ) {
					Ann_SB1[2] = false;
					Ann_SB1[1] = false;
					Ann_SB1[0] = false;
				}
				else if (Ann_SB1[1] && pct < 0.955 ) {
					UpdateBlink("Shadow Imminent! (75%)"); 
					Ann_SB1[1] = false;
					Ann_SB1[0] = false;
				}
				else if (Ann_SB1[0] && pct < 0.98 ) {
					UpdateText("Shadow Incoming (75%)");
					Ann_SB1[0] = false;
				}
			}
			
			// First Personal Space at 23556525 (67%)
			if ( Ann_PS1[2] && IsNYR10(m_player.GetPlayfieldID()) ) 
			{
				if (pct < 0.67 ) {
					Ann_PS1[2] = false;
					Ann_PS1[1] = false;
					Ann_PS1[0] = false;
				}
				else if (Ann_PS1[1] && pct < 0.68 ) {
					UpdateBlink("Personal Space 1 Imminent! (67%)"); 
					Ann_PS1[1] = false;
					Ann_PS1[0] = false;
				}
				else if (Ann_PS1[0] && pct < 0.70 ) {
					UpdateText("Personal Space 1 Incoming (67%)");	
					Ann_PS1[0] = false;
				}
			}
			
			// Second Personal Space at 15821546 (45%)
			if (Ann_PS2[2] && IsNYR10(m_player.GetPlayfieldID())) 
			{
				if (pct < 0.45 ) {
					Ann_PS2[2] = false;
					Ann_PS2[1] = false;
					Ann_PS2[0] = false;
				}
				else if (Ann_PS2[1] && pct < 0.46 ) {
					UpdateBlink("Personal Space 2 Imminent! (45%)"); 
					Ann_PS2[1] = false;
					Ann_PS2[0] = false;
				}
				else if (Ann_PS2[0] && pct < 0.48 ) {
					UpdateText("Personal Space 2 Incoming (45%)");	
					Ann_PS2[0] = false;
				}
			}
			
			// Third Personal Space at 8789478 (25%)
			if (Ann_PS3[2] && IsNYR10(m_player.GetPlayfieldID())) 
			{
				if (pct < 0.25 ) {
					Ann_PS3[2] = false;
					Ann_PS3[1] = false;
					Ann_PS3[0] = false;			
				}
				else if (Ann_PS3[1] && pct < 0.26 ) {
					UpdateBlink("Personal Space 3 Imminent! (25%)");
					Ann_PS3[1] = false;
					Ann_PS3[0] = false;			
				}
				else if (Ann_PS3[0] && pct < 0.28 ) {
					UpdateText("Personal Space 3 Incoming (25%)");	
					Ann_PS3[0] = false;			
				}
			}
			
			// Final Resort at 1757950 (5%)
			if (Ann_FR[2]) 
			{
				if (pct < 0.04 ) {
					Ann_FR[2] = false;
					Ann_FR[1] = false;
					Ann_FR[0] = false;				
				}
				else if (Ann_FR[1] && pct < 0.055 ) {
					UpdateBlink("Final Resort Imminent! (5%)"); 
					Ann_FR[1] = false;
					Ann_FR[0] = false;				
				}
				else if (Ann_FR[0] && pct < 0.07 ) {
					UpdateText("Final Resort Incoming (5%)");
					Ann_FR[0] = false;				
				}
			}
		}
	}
	
	public function LurkerCasting(spell)
	{
		Debugger.DebugText("Lurker is casting " + spell, debugMode);
		if (spell == stringShadowOutOfTime)
		{	
			// only decay on the first shadow
			if (Ann_SB1[3]) {
				Ann_SB1[3] = false;
				controller.decayText(3);
			}
		}
		if (spell == stringPersonalSpace)
		{
			controller.decayText(3);			
		}
		if (spell == stringFinalResort)
		{
			controller.decayText(3);
			controller.stopBlink();
			controller.setTextColor(0xFF0000);
		}		
	}
	
	private function UpdateText(text:String)
	{
		// print text to chat and update the text field
		com.GameInterface.UtilsBase.PrintChatText(text);
		controller.stopBlink();
		controller.UpdateText(text);
	}
	
	private function UpdateDecay(text:String)
	{
		// print text to chat and update the text field
		com.GameInterface.UtilsBase.PrintChatText(text);
		controller.UpdateText(text);		
		controller.decayText(textDecayTime);
	}
	
	private function UpdateBlink(text:String)
	{
		// print text to chat and update the text field
		com.GameInterface.UtilsBase.PrintChatText(text);
		controller.setTextColor( imminentColor );
		controller.UpdateText(text);		
		controller.blinkText(); 
	}
	
	public function ResetLurker()
	{
		Debugger.DebugText("Lurker signals disconnected, lurker unlocked", debugMode)
		
		// Disconnect all of the lurker-specific signals
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(ResetLurker, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker, this);
		
		// unlock targeting
		lurkerLocked = false;
		
		// disable blinking
		controller.stopBlink();
	}
	
	public function ConnectTargetChangedSignal()
	{
		Debugger.DebugText("TargetChanged connected", debugMode)
		
		// connects to targetchanged signal to search for lurker
		m_player.SignalOffensiveTargetChanged.Connect(TargetChanged, this);
		
	}
	
	
	public function DisconnectTargetChangedSignal()
	{
		Debugger.DebugText("TargetChanged disconnected", debugMode)
		
		// disconnect targetchanged signal (usually called only when leaving NYR)
		m_player.SignalOffensiveTargetChanged.Disconnect(TargetChanged, this);
	}
	
	
	// GUI stuff
	
	public function CreateTextField()
	{
		Debugger.DebugText("Announcement GUI Created", debugMode);
		
		// if a text field doesn't already exist, create one
		if !controller {
			controller = new TextFieldController(m_swfRoot);
			Debugger.DebugText("New controller created", debugMode);
		}
		
		// Set default text
        controller.UpdateText("A Lurker Is Announced");
		controller.decayText(textDecayTime);
		
		// Call a GuiEdit to update visibility and such
        GuiEdit();
    }
    
    public function StartDrag(){
		Debugger.DebugText("StartDrag called", debugMode);
        controller.clip.startDrag();
    }

    public function StopDrag(){
		Debugger.DebugText("StopDrag called", debugMode);
        controller.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        m_pos = Common.getOnScreen(controller.clip); // this seems to break randomly on reloadui or zoning? Almost as if it were grabbing the coordinates relative to where it started?
		//m_pos.x += controller.clip._width / 2;
		//m_pos = controller.getPos(); //this didn't work
		Debugger.DebugText("StopDrag: x: " + m_pos.x + "  y: " + m_pos.y, debugMode);
    }

    public function GuiEdit(state:Boolean){
		//Debugger.DebugText("GuiEdit called", debugMode);
		controller.setVisible(IsNYR(m_player.GetPlayfieldID()));
		
		//only editable in NYR
		if IsNYR(m_player.GetPlayfieldID()) 
		{
			if (state) {
				Debugger.DebugText("GuiEdit: state true", debugMode);
				controller.clip.onPress = Delegate.create(this, StartDrag);
				controller.clip.onRelease = Delegate.create(this, StopDrag);
				controller.UpdateText("~~~~~ Move Me!! ~~~~~");
				controller.setVisible(true);
				controller.toggleBackground(true);
				controller.enableHitTest();
				controller.stopBlink();
				
				
			} else {
				Debugger.DebugText("GuiEdit: state false", debugMode);
				controller.clip.stopDrag();
				controller.clip.onPress = undefined;
				controller.clip.onRelease = undefined;
				controller.UpdateText("A Lurker Is Announced");
				controller.decayText(textDecayTime);
				controller.toggleBackground(false);
				controller.disableHitTest();
				controller.stopBlink();
			}
		}
    }
	
}