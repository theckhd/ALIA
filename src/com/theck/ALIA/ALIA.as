/*
* ...
* @author theck
*/

import com.GameInterface.Game.Character;
import com.Utils.ID32;
//import com.GameInterface.WaypointInterface;
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
	
	// basic settings and text strings
	static var lurkerNameLocalized:String = LDBFormat.LDBGetText(51000, 32030);
	static var stringShadowOutOfTime:String = LDBFormat.LDBGetText(50210, 8934410); //"Shadow Out Of Time";
	static var stringPersonalSpace:String = LDBFormat.LDBGetText(50210, 8934415); //"Personal Space";
	static var stringFinalResort:String = LDBFormat.LDBGetText(50210, 7963851); //"Final Resort";
	static var textDecayTime:Number = 10;
	static var nowColor:Number = 0xFF0000;
	
	// character variables
	public var m_player:Character;
	private var lurker:Character;
	
	// GUI stuff
	private var m_swfRoot:MovieClip;
    private var AnnounceText:TextField;
	private var m_pos:flash.geom.Point;
	private var h_pos:flash.geom.Point;
	private var warningController:TextFieldController;
	private var healthController:TextFieldController;
	private var updateHealthDisplay:Boolean;
	
	// logic flags
	private var lurkerLocked:Boolean;
	private var Ann_SB1_Soon:Boolean;
	private var Ann_SB1_Now:Boolean;;
	private var SB1_Cast:Boolean;
	private var Ann_PS1_Soon:Boolean;
	private var Ann_PS1_Now:Boolean;
	private var Ann_PS2_Soon:Boolean;
	private var Ann_PS2_Now:Boolean;
	private var Ann_PS3_Soon:Boolean;
	private var Ann_PS3_Now:Boolean;
	private var Ann_FR_Soon:Boolean;
	private var Ann_FR_Now:Boolean;
	
	// percentages
	private var pct_SB1_Soon:Number;
	private var pct_SB1_Now:Number;
	private var pct_PS1_Soon:Number;
	private var pct_PS1_Now:Number;
	private var pct_PS2_Soon:Number;
	private var pct_PS2_Now:Number;
	private var pct_PS3_Soon:Number;
	private var pct_PS3_Now:Number;
	private var pct_FR_Soon:Number;
	private var pct_FR_Now:Number;
	
	
	////// Addon Management //////
	
	public function ALIA(swfRoot:MovieClip){
        m_swfRoot = swfRoot;
    }

	public function Load(){
		com.GameInterface.UtilsBase.PrintChatText("A Lurker Is Loaded");
		Debugger.DebugText("Debug mode enabled", debugMode);
		
		// grab character
		m_player = Character.GetClientCharacter();	
		lurkerLocked = false;		
		
		//create text field, connect to GuiEdit
		CreateTextFields();
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		
		// Check for TargetChanged signal connection
		CheckForSignalHookup();
			
		// debugging text strings
		Debugger.DebugText("~~~Text String testing~~", debugMode);
		Debugger.DebugText("shadow: " + stringShadowOutOfTime, debugMode);
		Debugger.DebugText("ps: " + stringPersonalSpace, debugMode);
		Debugger.DebugText("fr: " + stringFinalResort, debugMode);
		// these all give "The Unutterable Lurker"
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode);
		Debugger.DebugText("51000,32433 is " + LDBFormat.LDBGetText(51000, 32433),debugMode);
		Debugger.DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode); 
		Debugger.DebugText("~~~~~~~~~~~~~~~~~~~~~~~", debugMode);
	}

	public function Unload(){		
		Debugger.DebugText("Unload()");
		
		// disconnect all signals
		ResetLurker();
		DisconnectTargetChangedSignal();
	}
	
	public function Activate(config:Archive){
		Debugger.DebugText("Activate()", debugMode);
		
		// Move text to desired position
		m_pos = config.FindEntry("alia_warnPosition", new Point(600, 600));		
		Debugger.DebugText("Activate warning Position: x= " + m_pos.x + "  y= " + m_pos.y, debugMode);
		warningController.setPos(m_pos);
		
		h_pos = config.FindEntry("alia_healthPosition", new Point(600, 500));
		Debugger.DebugText("Activate health Position: x= " + h_pos.x + "  y= " + h_pos.y, debugMode);
		healthController.setPos(h_pos);
		
		/*  Eventually I'll store these in the config (once I have slash commands to edit them)
			For now, just hardcoding everything to make it easier to tweak during testing
		// Set "Now" thresholds - this set is the actual threshold for casts
		pct_SB1_Now = config.FindEntry("pct_SB1_Now", 0.75);
		pct_PS1_Now = config.FindEntry("pct_PS1_Now", 0.67);
		pct_PS2_Now = config.FindEntry("pct_PS2_Now", 0.45);
		pct_PS3_Now = config.FindEntry("pct_PS3_Now", 0.25);
		pct_FR_Now  = config.FindEntry("pct_FR_Now", 0.025);
		
		// Set "Soon" thresholds - this is when the Soon warning occurs
		pct_SB1_Soon = config.FindEntry("pct_SB1_Soon", pct_SB1_Now + 0.02);
		pct_PS1_Soon = config.FindEntry("pct_PS1_Soon", pct_PS1_Now + 0.02);
		pct_PS2_Soon = config.FindEntry("pct_PS2_Soon", pct_PS2_Now + 0.03);
		pct_PS3_Soon = config.FindEntry("pct_PS3_Soon", pct_PS3_Now + 0.03);
		pct_FR_Soon  = config.FindEntry("pct_FR_Soon" , pct_FR_Now  + 0.025);
		*/
		pct_SB1_Now = 0.75;
		pct_PS1_Now = 0.67;
		pct_PS2_Now = 0.45;
		pct_PS3_Now = 0.25;
		pct_FR_Now  = 0.025;
		
		// Set "Soon" thresholds - this is when the Soon warning occurs
		pct_SB1_Soon = pct_SB1_Now + 0.03;
		pct_PS1_Soon = pct_PS1_Now + 0.02;
		pct_PS2_Soon = pct_PS2_Now + 0.03;
		pct_PS3_Soon = pct_PS3_Now + 0.03;
		pct_FR_Soon  = pct_FR_Now  + 0.025;
		
		// Check for TargetChanged signal connection
		CheckForSignalHookup();
	}

	public function Deactivate():Archive{
		Debugger.DebugText("Deactivate()", debugMode);
		
		// save the current position in the config
		var config = new Archive();
		Debugger.DebugText("Deactivate warning position: x= " + m_pos.x + "  y= " + m_pos.y, debugMode);
		config.AddEntry("alia_warnPosition", m_pos);
		
		Debugger.DebugText("Deactivate health position: x= " + h_pos.x + "  y= " + h_pos.y, debugMode);
		config.AddEntry("alia_healthPosition", h_pos);
		
/*		//save all of the thresholds
		config.AddEntry("pct_SB1_Now", pct_SB1_Now);
		config.AddEntry("pct_PS1_Now", pct_PS1_Now);
		config.AddEntry("pct_PS2_Now", pct_PS2_Now);
		config.AddEntry("pct_PS3_Now", pct_PS3_Now);
		config.AddEntry("pct_FR_Now" , pct_FR_Now);
		config.AddEntry("pct_SB1_Soon", pct_SB1_Soon);
		config.AddEntry("pct_PS1_Soon", pct_PS1_Soon);
		config.AddEntry("pct_PS2_Soon", pct_PS2_Soon);
		config.AddEntry("pct_PS3_Soon", pct_PS3_Soon);
		config.AddEntry("pct_FR_Soon" , pct_FR_Soon);*/
		
		return config
	}
	
	private function IsNYR10(){
		var zone = m_player.GetPlayfieldID();
		return (debugMode || zone == 5715); // E10 is 5715
	}
	
	private function IsNYR(){
		var zone = m_player.GetPlayfieldID();
		return (debugMode || IsNYR10() || zone == 5710); // SM, E1, and E5 are all 5710
	}
		
	public function CheckForSignalHookup()
	{	
		// if in NYR, connect to the TargetChanged signal 
		if (IsNYR())
		{
			Debugger.DebugText("You have entered NYR", debugMode);	
			ConnectTargetChangedSignal();
		}
		else
		{		
			// disconnect all signals
			ResetLurker();
			DisconnectTargetChangedSignal();
		}
		
		// update visibility  & blink state of text fields
		warningController.setVisible( IsNYR() );
		warningController.stopBlink();		
		healthController.setVisible( IsNYR() ); 
	}
	
	public function ResetAnnounceFlags()
	{
		Ann_SB1_Soon = true;
		Ann_SB1_Now = true;
		SB1_Cast = false;
		Ann_PS1_Soon = true;
		Ann_PS1_Now = true;
		Ann_PS2_Soon = true;
		Ann_PS2_Now = true;
		Ann_PS3_Soon = true;
		Ann_PS3_Now = true;
		Ann_FR_Soon = true;
		Ann_FR_Now = true;
	}
	
	////// Encounter Logic //////
	
	public function TargetChanged(id:ID32)
	{	
		//Debugger.DebugText("TargetChanged id passed is " + id,debugMode);
				
		// If we haven't yet locked on to lurker and this id is useful
		if (!lurkerLocked && !id.IsNull()) {
			
			// update current target variable
			var currentTarget = Character.GetCharacter(id);
			Debugger.DebugText("currentTarget GetName is " + currentTarget.GetName(), debugMode); //dump name for testing
			
			// if the current target's name is "The Unutterable Lurker" (32030, 32433, 32030 should all work here)
			if (currentTarget.GetName() == lurkerNameLocalized ) {
				
				// set flags for announcements to true
				ResetAnnounceFlags();
				
				// store lurker variable
				lurker = currentTarget;
				
				// Connect to statchanged signal
				lurker.SignalStatChanged.Connect(LurkerStatChanged, this);
				lurker.SignalCommandStarted.Connect(LurkerCasting, this);
				
				// Connect deat/wipe signals to a function that resets signal connections 
				lurker.SignalCharacterDied.Connect(LurkerDied, this);
				lurker.SignalCharacterDestructed.Connect(ResetLurker, this);
				
				// Lock on lurker so that we don't continue to check targets anymore
				lurkerLocked = true;
				updateHealthDisplay = true;
				Debugger.DebugText("Lurker Locked!!", debugMode)
			}
		}
	}
	
	public function updatePercentHealthFlag() { updateHealthDisplay = true; }
	
	public function LurkerStatChanged(stat)
	{
		//Debugger.DebugText("Lurker's Stats Changed",debugMode);
		
		if (stat == 27) {
		
			// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
			var currentHP = lurker.GetStat(27, 1);
			var maxHP = lurker.GetStat(1, 1);
			var pct = currentHP / maxHP;
			
			// throttle display updates to every 250 ms
			if (updateHealthDisplay) {
			
				// pick one of these two
				//healthController.UpdateText( Math.round(pct * 1000) / 10 + "%");
				UpdateHealthText(Math.round(pct * 1000) / 10 + "%");
				
				updateHealthDisplay = false;
				setTimeout(Delegate.create(this, updatePercentHealthFlag), 250 );
			}
			
			
			//Debugger.DebugText("Health % is " + pct * 100 + "%", debugMode);
			
			// Shadow Incoming at 26369244 (75%)
			if ( Ann_SB1_Soon && pct < pct_SB1_Soon ) 
			{
				UpdateWarning("Shadow Soon (75%)");
				Ann_SB1_Soon = false;
			}
			else if ( Ann_SB1_Now && pct < pct_SB1_Now ) 
			{
				UpdateWarningWithBlink("Shadow Now! (75%)"); 
				Ann_SB1_Now = false;
			}
			
			/* 	
			Everything else only happens in phase 3, so we could put the rest of this inside an "if SB_Cast {}".
			However if someone crashes, SB1_Cast might not be true and then the addon would stop working.
			Workaround: put the first PS inside clause  b/c it's possible to push lurker below 69% in phase 1.
			*/
			
			// First Personal Space at 23556525 (67%)
			if ( Ann_PS1_Soon && SB1_Cast && IsNYR10() && pct < pct_PS1_Soon ) 
			{
				UpdateWarning("Personal Space Soon (67%)");	
				Ann_PS1_Soon = false;
			}
			else if ( Ann_PS1_Now && SB1_Cast && IsNYR10() && pct < pct_PS1_Now ) 
			{
				UpdateWarningWithBlink("Personal Space Now! (67%)"); 
				Ann_PS1_Now = false;
			}
			
			// Second Personal Space at 15821546 (45%)
			else if ( Ann_PS2_Soon && IsNYR10() && pct < pct_PS2_Soon ) 
			{
				UpdateWarning("Personal Space Soon (45%)");	
				Ann_PS2_Soon = false;
			}
			else if ( Ann_PS2_Now && IsNYR10() && pct < pct_PS2_Now ) 
			{
				UpdateWarningWithBlink("Personal Space Now! (45%)"); 
				Ann_PS2_Now = false;
			}
			
			// Third Personal Space at 8789478 (25%)
			else if ( Ann_PS3_Soon && IsNYR10() && pct < pct_PS3_Soon ) 
			{
				UpdateWarning("Personal Space Soon (25%)");	
				Ann_PS3_Soon = false;		
			}
			else if (Ann_PS3_Now && IsNYR10() && pct < pct_PS3_Now ) 
			{
				UpdateWarningWithBlink("Personal Space 3 Now! (25%)");
				Ann_PS3_Now = false;
			}
				
			// Final Resort at 1757950 (5%) - actually this seems to happen between 2.5% and 3%
			if (Ann_FR_Soon && pct < pct_FR_Soon ) 
			{
				UpdateWarning("Final Resort Soon (3%)");
				Ann_FR_Soon = false;				
			}
			else if (Ann_FR_Now && pct < pct_FR_Now ) 
			{
				UpdateWarningWithBlink("Final Resort Now! (3%)"); 
				Ann_FR_Now = false;			
			}
		}
	}
	
	public function LurkerCasting(spell)
	{
		Debugger.DebugText("Lurker is casting " + spell, debugMode);
		
		// only decay on the first shadow
		//Debugger.DebugText("SB1_Cast is " + SB1_Cast, debugMode);
		//Debugger.DebugText("string SoT is " + stringShadowOutOfTime, debugMode);
		//Debugger.DebugText("test is " + ( spell == stringShadowOutOfTime ), debugMode);
		if ( !SB1_Cast && ( spell == stringShadowOutOfTime ) )
		{	
			SB1_Cast = true;
			Debugger.DebugText("SB1_Cast is " + SB1_Cast, debugMode);
			warningController.decayText(3);
		}
		// decay on every PS
		else if (spell == stringPersonalSpace)
		{
			warningController.decayText(3);			
		}
		// decay FR and stop blinking effect
		else if (spell == stringFinalResort)
		{
			warningController.decayText(3);
			warningController.stopBlink();
			warningController.setTextColor(nowColor);
		}		
	}
	
	////// Signal Connections //////
	
	public function LurkerDied()
	{
		healthController.UpdateText("Dead");
		healthController.decayText(10);
		ResetLurker();
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
		
		// decay any remaining message, also stop blinking
		warningController.decayText(3);
		warningController.stopBlink();
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
	
	
	////// GUI stuff //////
	
	public function CreateTextFields()
	{
		Debugger.DebugText("CreateTextFields()", debugMode);
		
		// if a text field doesn't already exist, create one
		if !warningController {
			warningController = new TextFieldController(m_swfRoot, "warningText");
			Debugger.DebugText("Warning Controller created", debugMode);
		}
		
		// if pct health display doesn't already exist, create one
		if !healthController {
			healthController = new TextFieldController(m_swfRoot, "healthText");
			Debugger.DebugText("% Health Controller created", debugMode);
		}
		
		// Set default text
        warningController.UpdateText("A Lurker Is Announced");
		warningController.decayText(textDecayTime);
		healthController.UpdateText("100%")
		
		// Call a GuiEdit to update visibility and such
        GuiEdit();
    }
	
	private function UpdateHealthText(text:String)
	{
		// update health display
		healthController.UpdateText(text);
	}
	
	private function UpdateWarning(text:String)
	{
		// print text to chat, stop any existing blink effects, and update the text field
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.stopBlink();
		warningController.UpdateText(text);
	}
	
	private function UpdateWarningWithDecay(text:String)
	{
		// print text to chat, update the text field, schedule decay
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.UpdateText(text);		
		warningController.decayText(textDecayTime);
	}
	
	private function UpdateWarningWithBlink(text:String)
	{
		// print text to chat, set color to red, update the text field, start blinking
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.setTextColor( nowColor );
		warningController.UpdateText(text);
		warningController.blinkText();
	}
    
    public function warningStartDrag(){
		Debugger.DebugText("warningStartDrag called", debugMode);
        warningController.clip.startDrag();
    }

    public function warningStopDrag(){
		Debugger.DebugText("warningStopDrag called", debugMode);
        warningController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        m_pos = Common.getOnScreen(warningController.clip); 
		
		Debugger.DebugText("warningStopDrag: x: " + m_pos.x + "  y: " + m_pos.y, debugMode);
    }
	
    public function pctHealthStartDrag(){
		Debugger.DebugText("pctHealthStartDrag called", debugMode);
        healthController.clip.startDrag();
    }

    public function pctHealthStopDrag(){
		Debugger.DebugText("pctHealthStopDrag called", debugMode);
        healthController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        h_pos = Common.getOnScreen(healthController.clip); 
		
		Debugger.DebugText("pctHealthStopDrag: x: " + h_pos.x + "  y: " + h_pos.y, debugMode);
    }

    public function GuiEdit(state:Boolean){
		//Debugger.DebugText("GuiEdit called", debugMode);
		warningController.setVisible(IsNYR());
		warningController.enableInteraction(false);
		healthController.setVisible(IsNYR()); 
		
		//only editable in NYR
		if IsNYR() 
		{
			if (state) {
				Debugger.DebugText("GuiEdit: state true", debugMode);
				warningController.clip.onPress = Delegate.create(this, warningStartDrag);
				warningController.clip.onRelease = Delegate.create(this, warningStopDrag);
				warningController.UpdateText("~~~~~ Move Me!! ~~~~~");
				warningController.setVisible(true);
				warningController.toggleBackground(true);
				warningController.enableInteraction(true);
				warningController.stopBlink(); // probably unnecessary?
				
				healthController.clip.onPress = Delegate.create(this, pctHealthStartDrag);
				healthController.clip.onRelease = Delegate.create(this, pctHealthStopDrag);
				healthController.UpdateText("100%");
				healthController.setVisible(true);
				healthController.toggleBackground(true);
				healthController.enableInteraction(true);
			} 
			else {
				Debugger.DebugText("GuiEdit: state false", debugMode);
				warningController.clip.stopDrag();
				warningController.clip.onPress = undefined;
				warningController.clip.onRelease = undefined;
				warningController.UpdateText("A Lurker Is Announced");
				warningController.decayText(textDecayTime);
				warningController.toggleBackground(false);
				warningController.enableInteraction(false);
				warningController.stopBlink(); // probably unnecessary?
				
				healthController.clip.stopDrag();
				healthController.clip.onPress = undefined;
				healthController.clip.onRelease = undefined;
				healthController.toggleBackground(false);
				healthController.enableInteraction(false);
			}
		}
    }
	
}