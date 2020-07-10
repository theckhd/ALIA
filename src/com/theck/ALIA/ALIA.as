/*
* ...
* @author theck
*/

import com.GameInterface.DistributedValue;
import com.theck.ALIA.GetHealthPercent;
import com.theck.ALIA.LurkerCasting;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.VicinitySystem;
//import com.GameInterface.UtilsBase;
//import com.GameInterface.ProjectUtilsBase;
//import com.Utils.WeakList;
import com.Utils.ID32;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.Utils.GlobalSignal;
import com.theck.Utils.Common;
import com.theck.Utils.Debugger;
import com.theck.ALIA.npcStatusMonitor;
import gui.theck.TextFieldController;
import gui.theck.npcStatusDisplay;
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
	static var stringFromBeneath:String = LDBFormat.LDBGetText(50210, 8934432); //"From Beneath You, It Devours"
	static var alex112:Number = 32302;
	static var mei112:Number = 32301;
	static var rose112:Number = 32299;
	static var zuberi112:Number = 32303;
	static var eguard112:Number = 37266;
	static var hulk112:Number = 37333; 
	static var textDecayTime:Number = 10;
	static var nowColor:Number = 0xFF0000;
	
	// character variables
	public var m_player:Character;
	private var lurker:Character;
	private var alex:npcStatusMonitor;
	private var rose:npcStatusMonitor;
	private var mei:npcStatusMonitor;
	private var zuberi:npcStatusMonitor;
	private var currentBird:Character;
	private var currentHulk:Character;
	
	// GUI stuff
	private var m_swfRoot:MovieClip;
    private var AnnounceText:TextField;
	private var w_pos:flash.geom.Point;
	private var h_pos:flash.geom.Point;
	private var n_pos:flash.geom.Point;
	private var warningController:TextFieldController;
	private var healthController:TextFieldController;
	private var updateHealthDisplay:Boolean;
	private var npcDisplay:npcStatusDisplay;
	
	// logic flags and accumulators
	private var Ann_SB1_Soon:Boolean;
	private var Ann_SB1_Now:Boolean;
	private var Ann_PS1_Soon:Boolean;
	private var Ann_PS1_Now:Boolean;
	private var Ann_PS2_Soon:Boolean;
	private var Ann_PS2_Now:Boolean;
	private var Ann_PS3_Soon:Boolean;
	private var Ann_PS3_Now:Boolean;
	private var Ann_FR_Soon:Boolean;
	private var Ann_FR_Now:Boolean;
	private var AnnounceSettingsBool:Boolean;
	private var personalSoundAlreadyPlaying:Boolean = false;
	private var fromBeneathSoundAlreadyPlaying:Boolean = false;
	private var loadFinished = false;
	private var encounterPhase:Number;
	private var numBirds:Number;
	private var numHulks:Number;
	private var numShadows:Number;
	private var shadowThrottleFlag:Boolean = true;
	
	
	// percentages
	static var pct_SB1_Now:Number = 0.75;
	static var pct_PS1_Now:Number = 0.67;
	static var pct_PS2_Now:Number = 0.45;
	static var pct_PS3_Now:Number = 0.25;
	static var pct_FR_Now:Number  = 0.05;
	private var pct_warning:DistributedValue;
	
	// other options
	private var showZuberi:DistributedValue;
	private var personalSound:DistributedValue;
	private var fromBeneathSound:DistributedValue;
	private var showSlashCommands:DistributedValue;

	//////////////////////////////
	////// Addon Management //////
	//////////////////////////////
	
	public function ALIA(swfRoot:MovieClip) {
        m_swfRoot = swfRoot;
		
		// create options
		CreateOptions();
    }

	public function Load() {
		com.GameInterface.UtilsBase.PrintChatText("A Lurker Is Loaded");
		DebugText("Debug mode enabled");
		
		// grab character
		m_player = Character.GetClientCharacter();	
		
		//create text field, connect to GuiEdit
		CreateGuiElements();
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		
		// connect options to SettingsChanged function
		ConnetOptionsSignals();
		
		// announce settings flag
		AnnounceSettingsBool = true;
		setTimeout(Delegate.create(this, setLoadFinishedFlag), 5000);
	}

	public function Unload() {		
		DebugText("Unload()");
		
		// disconnect all signals
		ResetLurker();
		
		DisconnetOptionsSignals();
	}
	
	public function Activate(config:Archive) {
		DebugText("Activate()");
				
		// set options
		ActivateOptions(config);
		
		// Initialize vicinity signal and update visibility
		Initialize();
		
		// Announce any relevant settings the first time Activate() is called within NYR
		AnnounceSettings();
	}

	public function Deactivate():Archive {
		DebugText("Deactivate()");
		
		// save the current position in the config
		var config = new Archive();
		
		config = DeactivateOptions();
		
		return config
	}
	
	private function IsNYR10() {
		var zone = m_player.GetPlayfieldID();
		return (debugMode || zone == 5715); // E10 & E17 are 5715
	}
	
	private function IsNYR() {
		var zone = m_player.GetPlayfieldID();
		return (debugMode || IsNYR10() || zone == 5710); // SM, E1, and E5 are all 5710
	}
	
	private function setLoadFinishedFlag() {
		loadFinished = true;
	}
		
	public function Initialize() {	
		// if in NYR, connect to the TargetChanged signal 
		if (IsNYR())
		{	
			ConnectVicinitySignals();
			encounterPhase = 0;
			numBirds = 0;
			numHulks = 0;
			numShadows = 0;
		}
		else
		{		
			// disconnect all signals
			ResetLurker();
			DisconnectVicinitySignals();
		}
		
		// update visibility  & blink state of text fields
		warningController.setVisible( IsNYR() );
		warningController.stopBlink();		
		healthController.setVisible( IsNYR() ); 
		npcDisplay.setVisible( IsNYR(), Boolean(showZuberi.GetValue()) ); 
	}
	
	//////////////////////////////
	////// Options Handling //////
	//////////////////////////////
	
	private function CreateOptions() {		
		
		// create options (note: each is a DistributedValue, need to access w/ SetValue() / GetValue() in code
		// the argument here is the string used to adjust the variable via chat window
		pct_warning = DistributedValue.Create("alia_warnpct");
		showZuberi = DistributedValue.Create("alia_zuberi");
		personalSound = DistributedValue.Create("alia_ps_sound");
		fromBeneathSound = DistributedValue.Create("alia_pod_sound");
		showSlashCommands = DistributedValue.Create("alia_options");
	}
	
	private function ConnetOptionsSignals() {
		
		// connect option change signals to SettingsChanged
		pct_warning.SignalChanged.Connect(SettingsChanged, this);
		showZuberi.SignalChanged.Connect(SettingsChanged, this);
		personalSound.SignalChanged.Connect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Connect(SettingsChanged, this);
		showSlashCommands.SignalChanged.Connect(AnnounceSlashCommands, this);
	}
	
	private function DisconnetOptionsSignals() {
		
		// disconnect option change signals 	
		pct_warning.SignalChanged.Disconnect(SettingsChanged, this);
		showZuberi.SignalChanged.Disconnect(SettingsChanged, this);
		personalSound.SignalChanged.Disconnect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Disconnect(SettingsChanged, this);
		showSlashCommands.SignalChanged.Disconnect(AnnounceSlashCommands, this);
	}
	
	private function ActivateOptions(config:Archive) {
		
		// Move text to desired position
		w_pos = config.FindEntry("alia_warnPosition", new Point(600, 600));		
		warningController.setPos(w_pos);
		
		h_pos = config.FindEntry("alia_healthPosition", new Point(600, 500));
		healthController.setPos(h_pos);
		
		n_pos = config.FindEntry("alia_npcPosition", new Point(600, 400));
		npcDisplay.setPos(n_pos);
		
		// set options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		pct_warning.SetValue(config.FindEntry("alia_pct_warning", 3));
		showZuberi.SetValue( config.FindEntry("alia_showZuberi", false));
		personalSound.SetValue( config.FindEntry("alia_personalSound", true));
		fromBeneathSound.SetValue( config.FindEntry("alia_fromBeneathSound", true));
		showSlashCommands.SetValue( false );
	}
	
	private function DeactivateOptions():Archive {
		
		// save the current position in the config
		var config = new Archive();
		config.AddEntry("alia_warnPosition", w_pos);
		config.AddEntry("alia_healthPosition", h_pos);
		config.AddEntry("alia_npcPosition", n_pos);
		
		// save options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		config.AddEntry("alia_pct_warning", pct_warning.GetValue());
		config.AddEntry("alia_showZuberi", showZuberi.GetValue());
		config.AddEntry("alia_personalSound", personalSound.GetValue());
		config.AddEntry("alia_fromBeneathSound", fromBeneathSound.GetValue());
		
		return config
	}
	
	
	private function SettingsChanged(dv:DistributedValue) {
		
		DebugText("SettingsChanged()");
        DebugText("SettingsChanged: dv.GetName() is " + dv.GetName());
        DebugText("SettingsChanged: dv.GetValue() is " + dv.GetValue());
		
		AnnounceSettingsBool = true;
		
		// switch off of the settings name (defined in ALIA constructor)
		switch (dv.GetName()) {
		case "alia_warnpct":
			pct_warning = dv;
			break;
		case "alia_zuberi":
			showZuberi = dv;
			npcDisplay.setVisible( IsNYR(), Boolean(showZuberi.GetValue()));
			break;
		case "alia_ps_sound":
			personalSound = dv;
			if (loadFinished && personalSound.GetValue() ) { PlayPersonalSpaceWarningSound(); };
			break;
		case "alia_pod_sound":
			fromBeneathSound = dv;
			if ( loadFinished && fromBeneathSound.GetValue() ) { PlayFromBeneathWarningSound(); };
			break;
		}
		
		AnnounceSettings(loadFinished);
	}
	
	public function AnnounceSettings(override:Boolean) {
		if ( debugMode || override || ( AnnounceSettingsBool && IsNYR() ) )  {
			com.GameInterface.UtilsBase.PrintChatText("ALIA:" + ( IsNYR() ? " NYR Detected." : "" ) + " Warning setting is " + pct_warning.GetValue() + '%, Zuberi is ' + ( showZuberi.GetValue() ? "shown" : "hidden" ) + ". Sound alert for Personal Space " + ( personalSound.GetValue() ? "enabled" : "disabled" ) + ". Sound alert for Pod cast " + ( fromBeneathSound.GetValue() ? "enabled" : "disabled" ) + "." );
			com.GameInterface.UtilsBase.PrintChatText("ALIA: Type \"/option alia_options true\" to see slash commands.");
			AnnounceSettingsBool = false; // only resets on Load() or SettingsChanged()
		}
		
	}
	
	public function AnnounceSlashCommands(dv:DistributedValue):Void {
		if dv.GetValue() {
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_warnpct #\" will change the warning threshold to #%.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_zuberi (true/false)\" will toggle Zuberi display.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_ps_sound (true/false)\" will enable Personal Space warning sound.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_pod_sound (true/false)\" will enable From Beneath You It Devours warning sound.");
		}
		dv.SetValue(false);
	}
	
	/////////////////////////////
	////// Encounter Logic //////
	/////////////////////////////
	
	public function ResetAnnounceFlags() {
		// only enable announcements if the lurker is below the threshold (crash/reloadui protection)
		var pct = lurker.GetStat(27, 1) / lurker.GetStat(1, 1);
		if ( pct > pct_SB1_Now ) {	
			Ann_SB1_Soon = true;
			Ann_SB1_Now = true;
		}
		if (pct > pct_PS1_Now ) {
			Ann_PS1_Soon = true;
			Ann_PS1_Now = true;
		}
		if ( pct > pct_PS2_Now ) {
			Ann_PS2_Soon = true;
			Ann_PS2_Now = true;
		}
		if ( pct > pct_PS3_Now ) {
			Ann_PS3_Soon = true;
			Ann_PS3_Now = true;
		}
		Ann_FR_Soon = true;
		Ann_FR_Now = true;
	}
	
	public function ResetUpdateHealthDisplayFlag() { updateHealthDisplay = true; }
	
	public function DetectNPCs(dynelId:ID32):Void {
		//DebugText("DetectNPCs()");
		
		/* Notes: 
		// dynelID and dynel.GetID() match, and give type:spawnid (e.g. 50000:12345). spawnid seems to be generated anew each time something is spawned
		// GetType() and m_Type are 50000 for all characters (players, hostile and friendly npcs, etc)
		// GetNameTagCategory() seems to return 5 for NPCs (hostile or friendly), but 6 for lurker (probably "boss")
		// GetName() gives the name
		// GetStat(112) gives the unique character ID, which is what we want to grab
		// Useful 112s:  Eldritch Guardian (bird) is 37266, (hulk) is 37333
		// 112s pulled from E1 intro: Alex is 32302, Mei Ling is 32301, Rose is 32299, Zuberi 32303
		// 112s for lurker:
		//	SM: 37265 (first spawn), 37263 (after wipe)
		//	E1: 32433 (first spawn), 32030 (after wipe)
		//	E5: 37256 (first pull), 37255 (after wipe)
		// 	E10: 35448 (First pull), 35449 (after wipe)
		*/
		
		// bail if this isn't a character
		if dynelId.GetType() != 50000 {return; }
		
		var dynel:Dynel = Dynel.GetDynel(dynelId);
		var dynel112:Number = dynel.GetStat(112);
		
		/* Debugging stuff
		DebugText("Dynel GetName(): " + dynel.GetName());
		DebugText("Dynel Stat 112: " + dynel.GetStat(112));
		DebugText("Dynel Id: " + dynelId);
		DebugText("Dynel GetID(): " + dynel.GetID());
		DebugText("Dynel Interaction type: " + ProjectUtilsBase.GetInteractionType(dynelId));
		DebugText("Dynel m_Type: " + dynelId.m_Type);
		DebugText("Dynel GetType(): " + dynelId.GetType());
		DebugText("Dynel NameTagCategory: " + dynel.GetNametagCategory());
		*/
		
		// check for lurker first
		if ( !lurker && dynel.GetName() == stringLurker ) {
			DebugText("DetectNPCs(): Lurker hooked")
			
			// store lurker variable
			lurker = Character.GetCharacter(dynel.GetID());
			
			// Connect to lurker-specific signals
			ConnectLurkerSignals();
			
			// set flags for announcements to true
			ResetAnnounceFlags();
			
			// enable health display updating
			updateHealthDisplay = true;
		}
		
		// attempt to grab helpful NPCs only under certain conditions (to try and avoid entrance grab)
		// if we know we're past phase 1, or we're in combat, check for Alex/Rose/Mei
		else if ( encounterPhase > 1 || m_player.IsInCombat() ) {
			
			if ( !alex && ( dynel112 == alex112 ) ) {
				alex = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				alex.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				setPhaseState(3, alex.char.GetName());
				DebugText("DetectNPCs(): Alex hooked");
			}
			else if ( !rose && ( dynel112 == rose112 ) ) {			
				rose = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				rose.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				setPhaseState(3, rose.char.GetName());
				DebugText("DetectNPCs(): Rose hooked");
			}
			else if ( !mei && ( dynel112 == mei112 ) ) {
				mei = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				mei.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				setPhaseState(3, mei.char.GetName());
				DebugText("DetectNPCs(): Mei hooked");
			}
		}
		// Zuberi ONLY shows up in phase 3, so we can check for him freely and use him as a phase 3 test/update for crashes/reloadui
		if ( !zuberi && ( dynel112 == zuberi112 ) ) {
			zuberi = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			zuberi.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
			UpdateNPCStatusDisplay();
			setPhaseState(3, zuberi.char.GetName());
			DebugText("DetectNPCs(): Zuberi hooked");	
		}
		
		// Hulks only show up in phase 2, use them for encounter state detection
		if ( dynel112 == hulk112 ) {
			DebugText("DetectNPCs(): Detected " + dynel.GetName() + " #" + ( numHulks + 1 ) );	
			
			// grab hulk and store until dead
			currentHulk = Character.GetCharacter(dynel.GetID());
			currentHulk.SignalCharacterDied.Connect(HulkDied, this);
			
			// encounter state logic - detecting a hulk means at least phase 2
			setPhaseState(2, "detecting any Hulk");		
		}
		
		// Birds only show up in phase 2, use them for encounter state detection
		if ( dynel112 == eguard112 ) {
			DebugText("DetectNPCs(): Detected " + dynel.GetName() + " #" + ( numBirds +1 ) );	
			
			// grab bird and store until dead
			currentBird = Character.GetCharacter(dynel.GetID());
			currentBird.SignalCharacterDied.Connect(BirdDied, this);
			
			// encounter state logic - detecting a hulk means at least phase 2
			setPhaseState(2, "detecting any Bird");
		}
		
		// unhook this function if we have all the NPCs 
		if ( alex && rose && mei && zuberi && lurker ) { 
			DisconnectVicinitySignals(); 
		}
	}
	
	private function setPhaseState( state:Number, debugText:String ) {
		if state > encounterPhase {
			DebugText("encounterPhase changed from " + encounterPhase + " to " + state + " by " + debugText);
			encounterPhase = state;
		}
	}
	
	private function GetHealthPercent(char:Character):Number {
		// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
		var pct = char.GetStat(27, 1) / char.GetStat(1, 1);
		return pct;
	}
	
	public function LurkerStatChanged(stat)	{
		//DebugText("Lurker's Stats Changed",debugMode);
		
		if (stat == 27) {
		
			// get lurker's health percent (decimal form)
			var pct = GetHealthPercent(lurker);
			
			// throttle display updates to every 250 ms
			if (updateHealthDisplay && !isNaN(pct) ) {
			
				healthController.UpdateText( Math.round(pct * 1000) / 10 + "%");
				
				updateHealthDisplay = false;
				setTimeout(Delegate.create(this, ResetUpdateHealthDisplayFlag), 250 );
			}
			if ( encounterPhase < 1 && pct < 0.99 ) { 
				setPhaseState(1, "lurker health below 99%");
			}
			
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
			
			// First Personal Space at 23556525 (67%)
			// Limit to phase 3 b/c it's possible to push lurker past 67% + pct_warning in phase 1 and have annoying messages during phase 2.
			if ( Ann_PS1_Soon && ( encounterPhase > 2 ) && IsNYR10() && pct < ( pct_PS1_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Personal Space Soon (67%)");	
				Ann_PS1_Soon = false;
			}
			else if ( Ann_PS1_Now && ( encounterPhase > 2 ) && IsNYR10() && pct < pct_PS1_Now ) 
			{
				UpdateWarningWithBlink("Personal Space Now! (67%)"); 
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
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
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
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
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
				Ann_PS3_Now = false;
			}
				
			// Final Resort at 1757950 (5%) -  this seems to happen between 2.5% and 3% on Story Mode, but who cares about story mode anyway
			if (Ann_FR_Soon && pct < ( pct_FR_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Final Resort Soon (5%)");
				Ann_FR_Soon = false;				
			}
			else if (Ann_FR_Now && pct < pct_FR_Now ) 
			{
				UpdateWarningWithBlink("Final Resort Now! (5%)"); 
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
				Ann_FR_Now = false;			
			}
		}
	}
	
	public function LurkerCasting(spell) {
		DebugText("Lurker is casting " + spell);
		
		// this needs to be throttled because reticle-targetting can cause this to be triggered multiple times in one cast
		if ( spell == stringShadowOutOfTime && shadowThrottleFlag )
		{	
			numShadows++;
			shadowThrottleFlag = false;
			
			// encounter phase logic
			if numShadows > 2 {
				setPhaseState(3, "Shadow 3+");
			}
			else
			{
				setPhaseState(2, "Shadow 1");
			}
			
			// reset throttle flag after 10 seconds (cast is only 8 seconds)
			setTimeout(Delegate.create(this, ResetShadowThrottleFlag), 10000);
			
			// only decay warning text on the first shadow
			if numShadows < 2 {
				warningController.decayText(3);
			}
		}
		
		// decay warning text when PS is cast
		else if (spell == stringPersonalSpace)
		{
			warningController.decayText(3);			
			setPhaseState(3, "Personal Space");
		}
		
		// decay warning text and stop blinking effect when FR cast
		else if (spell == stringFinalResort)
		{
			warningController.decayText(3);
			warningController.stopBlink();
			warningController.setTextColor(nowColor);
		}
		
		// play a warning sound for pod casts (audible cue for cleansers)
		else if (spell == stringFromBeneath )
		{
			if (Boolean(fromBeneathSound.GetValue())) { PlayFromBeneathWarningSound(); }
		}
	}
	
	private function ResetShadowThrottleFlag() { shadowThrottleFlag = true;	}
	
	////////////////////////////////
	////// Signal Connections //////
	////////////////////////////////
	
	public function LurkerDied() {
		
		healthController.UpdateText("Dead");
		healthController.decayText(10);
		
		// disconnect lurker signals
		DisconnectLurkerSignals();
		lurker = undefined; // probably not needed
		
		// decay any remaining message, also stop blinking
		warningController.decayText(3);
		warningController.stopBlink();
		npcDisplay.decayDisplay(3);
	}
	
	public function ResetLurker() {
		DebugText("Lurker signals disconnected, lurker unlocked")
		
		// Disconnect all of the lurker-specific signals
		DisconnectLurkerSignals();
		
		// re-enable Vicinity Signals
		setTimeout(Delegate.create(this, ConnectVicinitySignals), 3000 );
		
		// decay any remaining message, also stop blinking
		warningController.decayText(3);
		warningController.stopBlink();
		
		// reset accumulators / encounter state variable
		numBirds = 0;
		numHulks = 0;
		numShadows = 0;
		encounterPhase = 0;
		currentBird = undefined;
		currentHulk = undefined;
	}
	
	public function ConnectLurkerSignals() {	
		DebugText("ConnectLurkerSignals()");
		
		// Connect to statchanged signal
		lurker.SignalStatChanged.Connect(LurkerStatChanged, this);
		lurker.SignalCommandStarted.Connect(LurkerCasting, this);
		
		// Connect deat/wipe signals to a function that resets signal connections 
		lurker.SignalCharacterDied.Connect(LurkerDied, this);
		lurker.SignalCharacterDestructed.Connect(ResetLurker, this);	
	}
	
	public function DisconnectLurkerSignals() {
		
		// Disconnect all of the lurker-specific signals
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(LurkerDied, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker, this);		
	}
	
	public function HulkDied() {
		
		// disconnect signals
		currentHulk.SignalCharacterDied.Disconnect(HulkDied, this);
		currentHulk = undefined; // probably not needed
		
		// increment Hulk Counter
		numHulks++;	
		
		// encounter state logic - update to phase 3 if this is the third hulk
		if ( numHulks > 2 ) { setPhaseState(3, "Hulk #" + numHulks); }
	}
	
	public function BirdDied() {
		
		// disconnect signals
		currentBird.SignalCharacterDied.Disconnect(BirdDied, this);
		currentBird = undefined; // probably not needed
		
		// increment Hulk Counter
		numBirds++;	
		
		// encounter state logic - update to phase 3 if this is the third bird
		if ( numBirds > 2 ) { setPhaseState(3, "Bird #" + numBirds); }	
	}
	
	public function ConnectVicinitySignals() {
		DebugText("ConnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Connect(DetectNPCs, this);
		m_player.SignalOffensiveTargetChanged.Connect(DetectNPCs, this);
		m_player.SignalDefensiveTargetChanged.Connect(DetectNPCs, this);
		
		// reset all of the character variables
		alex = undefined;
		rose = undefined;
		mei = undefined;
		zuberi = undefined;
		lurker = undefined;
		
		UpdateNPCStatusDisplay();
		
	}
	
	public function DisconnectVicinitySignals()	{
		DebugText("DisconnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(DetectNPCs, this);
		m_player.SignalOffensiveTargetChanged.Disconnect(DetectNPCs, this);
		m_player.SignalDefensiveTargetChanged.Disconnect(DetectNPCs, this);
		
	}
	
	///////////////////////
	//////  Sounds  ///////
	///////////////////////
	
	public function PlayPersonalSpaceWarningSound() {
		// breaking target and retargeting the boss can generate the signal multiple times,
		// so we have to throttle the sound playing
		if ( !personalSoundAlreadyPlaying ) {
			// throttle sound 
			personalSoundAlreadyPlaying = true;
			// create beep pattern
			for ( var i:Number = 0; i < 10; i ++ )
			{
				setTimeout(Delegate.create(this, PlaySingleBeep), i*450);
			}
			// unthrottle after 5 seconds
			setTimeout(Delegate.create(this, ResetPersonalSpaceWarningSoundFlag), 5000 );
		}		
	}
	
	public function ResetPersonalSpaceWarningSoundFlag() {
		personalSoundAlreadyPlaying = false;
	}
	
	public function PlayFromBeneathWarningSound() {
		// breaking target and retargeting the boss can generate the signal multiple times,
		// so we have to throttle the sound playing
		if ( !fromBeneathSoundAlreadyPlaying ) {
			// throttle sound 
			fromBeneathSoundAlreadyPlaying = true;
			// create beep pattern
			for ( var i:Number = 0; i < 4; i ++ )
			{
				setTimeout(Delegate.create(this, PlaySingleMobilePositive), i*900);
			}
			// unthrottle after 5 seconds
			setTimeout(Delegate.create(this, ResetFromBeneathWarningSoundFlag), 5000 );
		}
	}
	
	public function ResetFromBeneathWarningSoundFlag() {
		fromBeneathSoundAlreadyPlaying = false;
	}
	
	public function PlaySingleBeep() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fxpackage_beep_single.xml");
	}
	
	public function PlaySingleMobilePositive() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_positive_feedback.xml");
	}
	
	///////////////////////
	////// GUI stuff //////
	///////////////////////
	
	public function CreateGuiElements() {
		DebugText("CreateGuiElements()");
		
		// if a warning field doesn't already exist, create one
		if !warningController {
			warningController = new TextFieldController(m_swfRoot, "warningText");
			DebugText("Warning Controller created");
		}
		
		// if pct health display doesn't already exist, create one
		if !healthController {
			healthController = new TextFieldController(m_swfRoot, "healthText");
			DebugText("% Health Controller created");
		}
		
		// if the NPC display doesn't already exist, create one
		if !npcDisplay {
			npcDisplay = new npcStatusDisplay(m_swfRoot);
			DebugText("NPC Status Display created");
		}
		
		// Set default text
        warningController.UpdateText("A Lurker Is Announced");
		warningController.decayText(textDecayTime);
		healthController.UpdateText("100%");
		
		// Call a GuiEdit to update visibility and such
        GuiEdit();
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
    
	private function UpdateNPCStatusDisplay() {
		DebugText("UpdateNPCStatusDisplay(): m: " + mei.GetStatus() + " r: " + rose.GetStatus() + " a: " + alex.GetStatus() + " z: " + zuberi.GetStatus() );
		npcDisplay.UpdateAll(mei.GetStatus(), rose.GetStatus(), alex.GetStatus(), zuberi.GetStatus());
	}
	
    public function warningStartDrag() {
		DebugText("warningStartDrag called");
        warningController.clip.startDrag();
    }

    public function warningStopDrag() {
		DebugText("warningStopDrag called");
        warningController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        w_pos = Common.getOnScreen(warningController.clip); 
		
		DebugText("warningStopDrag: x: " + w_pos.x + "  y: " + w_pos.y);
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
	
    public function npcStartDrag() {
		DebugText("npcStartDrag called");
        npcDisplay.clip.startDrag();
    }

    public function npcStopDrag() {
		DebugText("npcStopDrag called");
        npcDisplay.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        n_pos = Common.getOnScreen(npcDisplay.clip); 
		
		DebugText("npcStopDrag: x: " + n_pos.x + "  y: " + n_pos.y);
    }

    public function GuiEdit(state:Boolean) {
		//DebugText("GuiEdit called");
		warningController.setVisible(IsNYR());
		warningController.enableInteraction(false);
		healthController.setVisible(IsNYR()); 
		npcDisplay.setVisible(IsNYR(), Boolean(showZuberi.GetValue()));
		
		//only editable in NYR
		if IsNYR() 
		{
			if (state) {
				DebugText("GuiEdit: state true");
				warningController.clip.onPress = Delegate.create(this, warningStartDrag);
				warningController.clip.onRelease = Delegate.create(this, warningStopDrag);
				warningController.UpdateText("~~~~~ Move Me!! ~~~~~");
				warningController.setVisible(true);
				warningController.setGUIEdit(true);
				warningController.stopBlink(); // probably unnecessary?
				
				healthController.clip.onPress = Delegate.create(this, pctHealthStartDrag);
				healthController.clip.onRelease = Delegate.create(this, pctHealthStopDrag);
				healthController.UpdateText("100%");
				healthController.setVisible(true);
				healthController.setGUIEdit(true);
				
				npcDisplay.setGUIEdit(true);
				npcDisplay.clip.onPress = Delegate.create(this, npcStartDrag);
				npcDisplay.clip.onRelease = Delegate.create(this, npcStopDrag);
			} 
			else {
				DebugText("GuiEdit: state false");
				warningController.clip.stopDrag();
				warningController.clip.onPress = undefined;
				warningController.clip.onRelease = undefined;
				warningController.UpdateText("A Lurker Is Announced");
				warningController.decayText(textDecayTime);
				warningController.setGUIEdit(false);
				warningController.stopBlink(); // probably unnecessary?
				
				healthController.clip.stopDrag();
				healthController.clip.onPress = undefined;
				healthController.clip.onRelease = undefined;
				healthController.setGUIEdit(false);
				
				npcDisplay.clip.stopDrag();
				npcDisplay.clip.onPress = undefined;
				npcDisplay.clip.onRelease = undefined;
				npcDisplay.setGUIEdit(false);
			}
		}
    }
	
	// Debugging
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText(text);
	}
}