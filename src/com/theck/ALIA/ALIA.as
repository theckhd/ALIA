/*
* ...
* @author theck
*/

import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.VicinitySystem;
import com.GameInterface.ProjectUtilsBase;
import com.Utils.WeakList;
import com.Utils.ID32;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.Utils.GlobalSignal;
import com.theck.Utils.Common;
import com.theck.Utils.Debugger;
import com.theck.ALIA.npcStatusMonitor;
import gui.theck.TextFieldController;
import mx.utils.Delegate;
import flash.geom.Point;


class com.theck.ALIA.ALIA 
{
	// toggle debug messages and enable addon outisde of NYR
	static var debugMode:Boolean = false;
	
	// basic settings and text strings
	static var stringLurker:String = LDBFormat.LDBGetText(51000, 32030);
	static var stringShadowOutOfTime:String = LDBFormat.LDBGetText(50210, 8934410); //"Shadow Out Of Time";
	static var stringPersonalSpace:String = LDBFormat.LDBGetText(50210, 8934415); //"Personal Space";
	static var stringFinalResort:String = LDBFormat.LDBGetText(50210, 7963851); //"Final Resort";
	static var alex112:Number = 32302;
	static var mei112:Number = 32301;
	static var rose112:Number = 32299;
	static var zuberi112:Number = 32303;
	static var textDecayTime:Number = 10;
	static var nowColor:Number = 0xFF0000;
	
	// character variables
	public var m_player:Character;
	private var lurker:Character;
	private var alex:npcStatusMonitor;
	private var rose:npcStatusMonitor;
	private var mei:npcStatusMonitor;
	private var zuberi:npcStatusMonitor;
	
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
	private var AnnounceSettingsBool:Boolean;
	
	// percentages
	private var pct_SB1_Now:Number;
	private var pct_PS1_Now:Number;
	private var pct_PS2_Now:Number;
	private var pct_PS3_Now:Number;
	private var pct_FR_Now:Number;
	private var pct_warning:DistributedValue;
	
	
	////// Addon Management //////
	
	public function ALIA(swfRoot:MovieClip) {
        m_swfRoot = swfRoot;
		
		// create options (note: each is a DistributedValue, need to access w/ SetValue() / GetValue() in code
		pct_warning = DistributedValue.Create("alia_warnpct");
    }

	public function Load() {
		com.GameInterface.UtilsBase.PrintChatText("A Lurker Is Loaded");
		DebugText("Debug mode enabled");
		
		// grab character
		m_player = Character.GetClientCharacter();	
		lurkerLocked = false;		
		
		//create text field, connect to GuiEdit
		CreateTextFields();
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		
		// Check for TargetChanged signal connection
		//CheckForSignalHookup();
		
		// connect options to SettingsChanged function
		pct_warning.SignalChanged.Connect(SettingsChanged, this);
		
		// announce settings flag
		AnnounceSettingsBool = true;
			
/*		// debugging text strings
		DebugText("~~~Text String testing~~");
		DebugText("shadow: " + stringShadowOutOfTime);
		DebugText("ps: " + stringPersonalSpace);
		DebugText("fr: " + stringFinalResort);
		// these all give "The Unutterable Lurker"
		DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode);
		DebugText("51000,32433 is " + LDBFormat.LDBGetText(51000, 32433),debugMode);
		DebugText("51000,32030 is " + LDBFormat.LDBGetText(51000, 32030),debugMode); 
		DebugText("~~~~~~~~~~~~~~~~~~~~~~~");*/
	}

	public function Unload() {		
		DebugText("Unload()");
		
		// disconnect all signals
		ResetLurker();
		DisconnectTargetChangedSignal();
		pct_warning.SignalChanged.Disconnect(SettingsChanged, this);
	}
	
	public function Activate(config:Archive) {
		DebugText("Activate()");
		
		// Move text to desired position
		m_pos = config.FindEntry("alia_warnPosition", new Point(600, 600));		
		warningController.setPos(m_pos);
		
		h_pos = config.FindEntry("alia_healthPosition", new Point(600, 500));
		healthController.setPos(h_pos);
		
		pct_SB1_Now = 0.75;
		pct_PS1_Now = 0.67;
		pct_PS2_Now = 0.45;
		pct_PS3_Now = 0.25;
		pct_FR_Now  = 0.025;
		
		// set options
		pct_warning.SetValue(config.FindEntry("pct_warning", 3));
		
		// Check for TargetChanged signal connection
		CheckForSignalHookup();
		kickstart(); // grab NPCs that already exist
		
		// Announce any relevant settings the first time Activate() is called w/in NYR
		AnnounceSettings();
	}

	public function Deactivate():Archive {
		DebugText("Deactivate()");
		
		// save the current position in the config
		var config = new Archive();
		config.AddEntry("alia_warnPosition", m_pos);
		config.AddEntry("alia_healthPosition", h_pos);
		
		// save options
		config.AddEntry("pct_warning", pct_warning.GetValue());
		
		return config
	}
	
	private function IsNYR10() {
		var zone = m_player.GetPlayfieldID();
		return (debugMode || zone == 5715); // E10 is 5715
	}
	
	private function IsNYR() {
		var zone = m_player.GetPlayfieldID();
		return (debugMode || IsNYR10() || zone == 5710); // SM, E1, and E5 are all 5710
	}
	
	private function SettingsChanged(dv:DistributedValue) {
		
		DebugText("SettingsChanged()");
        DebugText("SettingsChanged: dv.GetName() is " + dv.GetName());
        DebugText("SettingsChanged: dv.GetValue() is " + dv.GetValue());
		
		AnnounceSettingsBool = true;
		
		switch (dv.GetName()) {
		case "alia_warnpct":
			pct_warning = dv;
			break;
		}
		AnnounceSettings();
	}
		
	public function CheckForSignalHookup() {	
		// if in NYR, connect to the TargetChanged signal 
		if (IsNYR())
		{	
			ConnectTargetChangedSignal();
			ConnectVicinitySignals();
		}
		else
		{		
			// disconnect all signals
			ResetLurker();
			DisconnectTargetChangedSignal();
			DisconnectVicinitySignals();
		}
		
		// update visibility  & blink state of text fields
		warningController.setVisible( IsNYR() );
		warningController.stopBlink();		
		healthController.setVisible( IsNYR() ); 
	}
	
	public function ResetAnnounceFlags() {
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
	
	public function AnnounceSettings() {
		if ( debugMode || ( AnnounceSettingsBool && IsNYR() ) ) {
			com.GameInterface.UtilsBase.PrintChatText("ALIA: NYR Detected. Warning setting is " + pct_warning.GetValue() + '%');
			AnnounceSettingsBool = false; // only resets on Load() or SettingsChanged()
		}
		
	}
	
	////// Encounter Logic //////
	
	public function TargetChanged(id:ID32) {	
		//DebugText("TargetChanged id passed is " + id,debugMode);
				
		// If we haven't yet locked on to lurker and this id is useful
		if (!lurkerLocked && !id.IsNull()) {
			
			// update current target variable
			var currentTarget = Character.GetCharacter(id);
			DebugText("currentTarget GetName is " + currentTarget.GetName()); //dump name for testing
			
			// if the current target's name is "The Unutterable Lurker" (32030, 32433, 32030 should all work here)
			if (currentTarget.GetName() == stringLurker ) {
				
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
				DebugText("Lurker Locked!!")
				// TODO: should we just call DisconnectTargetChangedSignal() here and remove hte lurkerLocked flag?
			}
		}
	}
	
	public function setPercentHealthFlag() { updateHealthDisplay = true; }
	
	public function HookUpNPCs(dynelId:ID32):Void {
		DebugText("HookUpNPCs()");
		
		// Notes: 
		// dynelID and dynel.GetID() match, and give type:spawnid (e.g. 50000:12345). spawnid seems to be generated anew each time something is spawned
		// GetType() and m_Type are 50000 for all characters (players, hostile and friendly npcs, etc)
		// GetNameTagCategory() seems to return 5 for NPCs (hostile or friendly), but 6 for lurker (probably "boss")
		// GetName() gives the name
		// GetStat(112) gives the unique character ID, which is what we want to grab I guess
		// Useful 112s:  Alex is 14242, Mei Ling is 14258, Rose is 14259, Zuberi is 14279, Eldritch Guardian (bird) is 37266
		// 112s pulled from E1 intro: Alex is 32302, Mei Ling is 32301, Rose is 32299, Zuberi 32303
		// 112s for lurker:
		//	SM: 37265 (first spawn), 37263 (after wipe)
		//	E1: 32433 (first spawn), 32030 (after wipe)
		//	E5: 37256 (first pull), 37255 (after wipe)
		// 	E10: 35448 (First pull), 35449 (after wipe)
		
		var dynel:Dynel = Dynel.GetDynel(dynelId);
		
		// bail if this isn't a character
		if dynelId.GetType() != 50000 {return; }
		
		// minimize spam while testing
		//if ( dynel.GetName() == "Abominated Civilian" ) {return; }
		
		//DebugText("Dynel GetName(): " + dynel.GetName());
		//DebugText("Dynel Id: " + dynelId);
		//DebugText("Dynel GetID(): " + dynel.GetID());
		//DebugText("Dynel Interaction type: " + ProjectUtilsBase.GetInteractionType(dynelId));
		//DebugText("Dynel m_Type: " + dynelId.m_Type);
		//DebugText("Dynel GetType(): " + dynelId.GetType());
		//DebugText("Dynel NameTagCategory: " + dynel.GetNametagCategory());
		//DebugText("Dynel Stat 112: " + dynel.GetStat(112));
		
		//DebugText("HookUpNPCs(): !alex is " + !alex );
		if ( !alex && ( dynel.GetStat(112) == alex112 ) ) {
			alex = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			DebugText("HookUpNPCs(): Alex hooked")
		}
		else if ( !rose && ( dynel.GetStat(112) == rose112 ) ) {			
			rose = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			DebugText("HookUpNPCs(): Rose hooked")
		}
		else if ( !mei && ( dynel.GetStat(112) == mei112 ) ) {
			mei = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			DebugText("HookUpNPCs(): Mei hooked")		
		}
		else if ( !zuberi && ( dynel.GetStat(112) == zuberi112 ) ) {
			zuberi = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			DebugText("HookUpNPCs(): Zuberi hooked")		
		}
		
		if ( dynel.GetName() == stringLurker ) {
			DebugText("HookUpNPCs(): Lurker could be locked here")
			//lurker = Character.GetCharacter(dynel.GetID());
			//lurkerLocked = true;
		}
		
		// unhook this function if we have all the NPCs
		if ( alex && rose && mei && zuberi ) { DisconnectVicinitySignals(); }
		
		
	}
	
	public function CheckBuff(buffID:Number) {
		// Notes: Potentially useful buffIDs:
		// 7863490: "Knocked Down",
		// 7945521: "Gaia Incarnate - Rose",
		// 7945522: "Gaia Incarnate - Alex",
		// 7945523: "Gaia Incarnate - Mei Ling",
		// 7854429: "From Beneath You, It Devours",
		// 8907521": "Inevitable Doom",
		DebugText("CheckBuff(): buffID is " + buffID);
	}
	
	// from LairTracker - find dynels that were already loaded before connecting signals
	private function kickstart() {
		DebugText("kickstart()");
		var ls:WeakList = Dynel.s_DynelList
		for (var num = 0; num < ls.GetLength(); num++) {
			var dyn:Character = ls.GetObject(num);
			HookUpNPCs(dyn.GetID());
		}
	}
	
	public function LurkerStatChanged(stat)	{
		//DebugText("Lurker's Stats Changed",debugMode);
		
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
				setTimeout(Delegate.create(this, setPercentHealthFlag), 250 );
			}
			
			
			//DebugText("Health % is " + pct * 100 + "%");
			
			// Shadow Incoming at 26369244 (75%)
			if ( Ann_SB1_Soon && pct < ( pct_SB1_Now + pct_warning.GetValue() / 100 ) ) 
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
			if ( Ann_PS1_Soon && SB1_Cast && IsNYR10() && pct < ( pct_PS1_Now + pct_warning.GetValue() / 100 ) ) 
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
			else if ( Ann_PS2_Soon && IsNYR10() && pct < ( pct_PS2_Now + pct_warning.GetValue() / 100 ) ) 
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
			else if ( Ann_PS3_Soon && IsNYR10() && pct < ( pct_PS3_Now + pct_warning.GetValue() / 100 ) ) 
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
			if (Ann_FR_Soon && pct < ( pct_FR_Now + pct_warning.GetValue() / 100 ) ) 
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
	
	public function LurkerCasting(spell) {
		DebugText("Lurker is casting " + spell);
		
		// only decay on the first shadow
		//DebugText("SB1_Cast is " + SB1_Cast);
		//DebugText("string SoT is " + stringShadowOutOfTime);
		//DebugText("test is " + ( spell == stringShadowOutOfTime ));
		if ( !SB1_Cast && ( spell == stringShadowOutOfTime ) )
		{	
			// delay changing the flag by 15 seconds so that we don't get personal space warnings during phase 2
			setTimeout(Delegate.create(this, function(){this.SB1_Cast = true; }), 15000 );
			SB1_Cast = true;
			DebugText("SB1_Cast is " + SB1_Cast);
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
	
	public function LurkerDied() {
		healthController.UpdateText("Dead");
		healthController.decayText(10);
		ResetLurker();
	}
	
	public function ResetLurker() {
		DebugText("Lurker signals disconnected, lurker unlocked")
		
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
	
	public function ConnectTargetChangedSignal() {
		DebugText("TargetChanged connected")
		
		// connects to targetchanged signal to search for lurker
		m_player.SignalOffensiveTargetChanged.Connect(TargetChanged, this);
		
	}
		
	public function DisconnectTargetChangedSignal()	{
		DebugText("TargetChanged disconnected")
		
		// disconnect targetchanged signal (usually called only when leaving NYR)
		m_player.SignalOffensiveTargetChanged.Disconnect(TargetChanged, this);
	}
	
	public function ConnectVicinitySignals() {
		DebugText("ConnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Connect(HookUpNPCs, this);
		m_player.SignalOffensiveTargetChanged.Connect(HookUpNPCs, this);
		m_player.SignalDefensiveTargetChanged.Connect(HookUpNPCs, this);
		
	}
	
	public function DisconnectVicinitySignals()	{
		DebugText("DisconnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(HookUpNPCs, this);
		m_player.SignalOffensiveTargetChanged.Disconnect(HookUpNPCs, this);
		m_player.SignalDefensiveTargetChanged.Disconnect(HookUpNPCs, this);
		
	}
	
	////// GUI stuff //////
	
	public function CreateTextFields() {
		DebugText("CreateTextFields()");
		
		// if a text field doesn't already exist, create one
		if !warningController {
			warningController = new TextFieldController(m_swfRoot, "warningText");
			DebugText("Warning Controller created");
		}
		
		// if pct health display doesn't already exist, create one
		if !healthController {
			healthController = new TextFieldController(m_swfRoot, "healthText");
			DebugText("% Health Controller created");
		}
		
		// Set default text
        warningController.UpdateText("A Lurker Is Announced");
		warningController.decayText(textDecayTime);
		healthController.UpdateText("100%")
		
		// Call a GuiEdit to update visibility and such
        GuiEdit();
    }
	
	private function UpdateHealthText(text:String) {
		// update health display
		healthController.UpdateText(text);
	}
	
	private function UpdateWarning(text:String)	{
		// print text to chat, stop any existing blink effects, and update the text field
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.stopBlink();
		warningController.UpdateText(text);
	}
	
	private function UpdateWarningWithDecay(text:String) {
		// print text to chat, update the text field, schedule decay
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.UpdateText(text);		
		warningController.decayText(textDecayTime);
	}
	
	private function UpdateWarningWithBlink(text:String) {
		// print text to chat, set color to red, update the text field, start blinking
		com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.setTextColor( nowColor );
		warningController.UpdateText(text);
		warningController.blinkText();
	}
    
    public function warningStartDrag() {
		DebugText("warningStartDrag called");
        warningController.clip.startDrag();
    }

    public function warningStopDrag() {
		DebugText("warningStopDrag called");
        warningController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        m_pos = Common.getOnScreen(warningController.clip); 
		
		DebugText("warningStopDrag: x: " + m_pos.x + "  y: " + m_pos.y);
    }
	
    public function pctHealthStartDrag() {
		DebugText("pctHealthStartDrag called");
        healthController.clip.startDrag();
    }

    public function pctHealthStopDrag() {
		DebugText("pctHealthStopDrag called");
        healthController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        h_pos = Common.getOnScreen(healthController.clip); 
		
		DebugText("pctHealthStopDrag: x: " + h_pos.x + "  y: " + h_pos.y);
    }

    public function GuiEdit(state:Boolean) {
		//DebugText("GuiEdit called");
		warningController.setVisible(IsNYR());
		warningController.enableInteraction(false);
		healthController.setVisible(IsNYR()); 
		
		//only editable in NYR
		if IsNYR() 
		{
			if (state) {
				DebugText("GuiEdit: state true");
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
				DebugText("GuiEdit: state false");
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
	
	// Debugging
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText(text);
	}
	
}