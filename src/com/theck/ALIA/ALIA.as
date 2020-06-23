/*
* ...
* @author theck
*/

//import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.DistributedValue;
//import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.VicinitySystem;
import com.GameInterface.UtilsBase;
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
	
	// logic flags
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
	private var personalSoundAlreadyPlaying:Boolean = false;
	private var fromBeneathSoundAlreadyPlaying:Boolean = false;
	
	// percentages
	private var pct_SB1_Now:Number;
	private var pct_PS1_Now:Number;
	private var pct_PS2_Now:Number;
	private var pct_PS3_Now:Number;
	private var pct_FR_Now:Number;
	private var pct_warning:DistributedValue;
	
	// other options
	private var showZuberi:DistributedValue;
	private var personalSound:DistributedValue;
	private var fromBeneathSound:DistributedValue;

	//////////////////////////////
	////// Addon Management //////
	//////////////////////////////
	
	public function ALIA(swfRoot:MovieClip) {
        m_swfRoot = swfRoot;
		
		// create options (note: each is a DistributedValue, need to access w/ SetValue() / GetValue() in code
		// the argument here is the string used to adjust the variable via chat window
		pct_warning = DistributedValue.Create("alia_warnpct");
		showZuberi = DistributedValue.Create("alia_zuberi");
		personalSound = DistributedValue.Create("alia_ps_sound");
		fromBeneathSound = DistributedValue.Create("alia_pod_sound");
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
		pct_warning.SignalChanged.Connect(SettingsChanged, this);
		showZuberi.SignalChanged.Connect(SettingsChanged, this);
		personalSound.SignalChanged.Connect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Connect(SettingsChanged, this);
		
		// announce settings flag
		AnnounceSettingsBool = true;
	}

	public function Unload() {		
		DebugText("Unload()");
		
		// disconnect all signals
		ResetLurker();
		//DisconnectTargetChangedSignal();
		pct_warning.SignalChanged.Disconnect(SettingsChanged, this);
		showZuberi.SignalChanged.Disconnect(SettingsChanged, this);
		personalSound.SignalChanged.Disconnect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Disconnect(SettingsChanged, this);
	}
	
	public function Activate(config:Archive) {
		DebugText("Activate()");
		
		// Move text to desired position
		w_pos = config.FindEntry("alia_warnPosition", new Point(600, 600));		
		warningController.setPos(w_pos);
		
		h_pos = config.FindEntry("alia_healthPosition", new Point(600, 500));
		healthController.setPos(h_pos);
		
		n_pos = config.FindEntry("alia_npcPosition", new Point(600, 400));
		npcDisplay.setPos(n_pos);
				
		pct_SB1_Now = 0.75;
		pct_PS1_Now = 0.67;
		pct_PS2_Now = 0.45;
		pct_PS3_Now = 0.25;
		pct_FR_Now  = 0.025;
		
		// set options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		pct_warning.SetValue(config.FindEntry("pct_warning", 3));
		showZuberi.SetValue( config.FindEntry("showZuberi", false));
		personalSound.SetValue( config.FindEntry("alia_personalSound", true));
		fromBeneathSound.SetValue( config.FindEntry("alia_fromBeneathSound", true));
		
		// Initialize vicinity signal and update visibility
		Initialize();
		
		// This seems to crash client during loading screens
		//kickstart(); // grab NPCs that already exist
		
		// Announce any relevant settings the first time Activate() is called w/in NYR
		AnnounceSettings();
		DebugText("SB1: is " + SB1_Cast);
	}

	public function Deactivate():Archive {
		DebugText("Deactivate()");
		
		// save the current position in the config
		var config = new Archive();
		config.AddEntry("alia_warnPosition", w_pos);
		config.AddEntry("alia_healthPosition", h_pos);
		config.AddEntry("alia_npcPosition", n_pos);
		
		// save options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		config.AddEntry("pct_warning", pct_warning.GetValue());
		config.AddEntry("showZuberi", showZuberi.GetValue());
		config.AddEntry("alia_personalSound", personalSound.GetValue());
		config.AddEntry("alia_fromBeneathSound", fromBeneathSound.GetValue());
		
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
			if personalSound.GetValue() { PlayPersonalSpaceWarningSound(); };
			break;
		case "alia_pod_sound":
			fromBeneathSound = dv;
			if fromBeneathSound.GetValue() { PlayFromBeneathWarningSound(); };
			break;
		}
		
		AnnounceSettings(true);
	}
		
	public function Initialize() {	
		// if in NYR, connect to the TargetChanged signal 
		if (IsNYR())
		{	
			//ConnectTargetChangedSignal();
			ConnectVicinitySignals();
		}
		else
		{		
			// disconnect all signals
			ResetLurker();
			//DisconnectTargetChangedSignal();
			DisconnectVicinitySignals();
		}
		
		// update visibility  & blink state of text fields
		warningController.setVisible( IsNYR() );
		warningController.stopBlink();		
		healthController.setVisible( IsNYR() ); 
		npcDisplay.setVisible( IsNYR(), Boolean(showZuberi.GetValue()) ); 
	}
	
	public function ResetAnnounceFlags() {
		// only enable announcements if the lurker is below the threshold (crash/reloadui protection)
		var pct = lurker.GetStat(27, 1) / lurker.GetStat(1, 1);
		if ( pct > pct_SB1_Now ) 
		{	
			Ann_SB1_Soon = true;
			Ann_SB1_Now = true;
			SB1_Cast = false;
		}
		if (pct > pct_PS1_Now )
		{
			Ann_PS1_Soon = true;
			Ann_PS1_Now = true;
		}
		if ( pct > pct_PS2_Now )
		{
			Ann_PS2_Soon = true;
			Ann_PS2_Now = true;
		}
		if ( pct > pct_PS3_Now )
		{
			Ann_PS3_Soon = true;
			Ann_PS3_Now = true;
		}		
		Ann_FR_Soon = true;
		Ann_FR_Now = true;
	}
	
	public function AnnounceSettings(override:Boolean) {
		if ( debugMode || override || ( AnnounceSettingsBool && IsNYR() ) )  {
			com.GameInterface.UtilsBase.PrintChatText("ALIA:" + ( IsNYR() ? " NYR Detected." : "" ) + " Warning setting is " + pct_warning.GetValue() + '%, Zuberi is ' + ( showZuberi.GetValue() ? "shown" : "hidden" ) + ". Audible alert for Personal Space " + ( personalSound.GetValue() ? "enabled" : "disabled" ) + ". Audible alert for Pod cast " + ( fromBeneathSound.GetValue() ? "enabled" : "disabled" ) + "." );
			AnnounceSettingsBool = false; // only resets on Load() or SettingsChanged()
		}
		
	}
	
	/////////////////////////////
	////// Encounter Logic //////
	/////////////////////////////

	public function setPercentHealthFlag() { updateHealthDisplay = true; }
	
	public function DetectNPCs(dynelId:ID32):Void {
		//DebugText("DetectNPCs()");
		
		/* Notes: 
		// dynelID and dynel.GetID() match, and give type:spawnid (e.g. 50000:12345). spawnid seems to be generated anew each time something is spawned
		// GetType() and m_Type are 50000 for all characters (players, hostile and friendly npcs, etc)
		// GetNameTagCategory() seems to return 5 for NPCs (hostile or friendly), but 6 for lurker (probably "boss")
		// GetName() gives the name
		// GetStat(112) gives the unique character ID, which is what we want to grab I guess
		// Useful 112s:  Eldritch Guardian (bird) is 37266, (hulk) is ????
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
			
			// Lock on lurker so that we don't continue to check targets anymore
			updateHealthDisplay = true;
		}
		
		// only connect helpful NPCs if we're in combat (avoids entrance grab)
		else if ( m_player.IsInCombat() ) {
			if ( !alex && ( dynel.GetStat(112) == alex112 ) ) {
				alex = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				alex.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				DebugText("DetectNPCs(): Alex hooked");
			}
			else if ( !rose && ( dynel.GetStat(112) == rose112 ) ) {			
				rose = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				rose.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				DebugText("DetectNPCs(): Rose hooked");
			}
			else if ( !mei && ( dynel.GetStat(112) == mei112 ) ) {
				mei = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				mei.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				DebugText("DetectNPCs(): Mei hooked");
			}
			else if ( !zuberi && ( dynel.GetStat(112) == zuberi112 ) ) {
				zuberi = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				zuberi.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				DebugText("DetectNPCs(): Zuberi hooked");	
				
				// Zuberi ONLY shows up in P3, so we can use him as a test for phase
				// this is only needed to help recover from a crash or /reloadui
				if !SB1_Cast {
					DebugText("DetectNPCs(): SB1_Cast set to true by Zuberi");	
					SetShadow1Flag();			
				}
			}			
			// this is only needed to help recover from a crash or /reloadui
			// note that the guardians in story mode have a 112 of 32407, so they shouldn't trigger this
			else if !SB1_Cast && ( dynel.GetStat(112) == eguard112 || dynel.GetStat(112) == hulk112 ) {
				// Birds and hulks only show up in phase 2, so we can use them as a test for phase
				// TODO: put hulk ID in here
					DebugText("DetectNPCs(): SB1_Cast set to true by a " + dynel.GetName() );
				SetShadow1Flag();
			}
		}
		
		// unhook this function if we have all the NPCs
		if ( alex && rose && mei && zuberi && lurker ) { 
			DisconnectVicinitySignals(); 
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
				healthController.UpdateText( Math.round(pct * 1000) / 10 + "%");
				
				updateHealthDisplay = false;
				setTimeout(Delegate.create(this, setPercentHealthFlag), 250 );
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
			
			/* 	
			Everything else only happens in phase 3, so we could put the rest of this inside an "if SB_Cast {}".
			However if someone crashes, SB1_Cast might not be true and then the addon would stop working.
			Workaround: put the first PS inside clause  b/c it's possible to push lurker past 67% + pct_warning in phase 1.
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
		if ( !SB1_Cast && ( spell == stringShadowOutOfTime ) )
		{	
			// delay changing the flag by 15 seconds so that we don't get personal space warnings during phase 2
			setTimeout(Delegate.create(this, SetShadow1Flag), 25000 );
			warningController.decayText(3);
		}
		// decay on every PS
		else if (spell == stringPersonalSpace)
		{
			warningController.decayText(3);	
			if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
			
			// can clear the SB1 flag here too (in case of crash or /reloadui)
			if !SB1_Cast { SB1_Cast = true; }		
		}
		// decay FR and stop blinking effect
		else if (spell == stringFinalResort)
		{
			warningController.decayText(3);
			warningController.stopBlink();
			warningController.setTextColor(nowColor);
			if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
		}
		else if (spell == stringFromBeneath )
		{
			if (Boolean(fromBeneathSound.GetValue())) { PlayFromBeneathWarningSound(); }
			//UtilsBase.PlaySound(soundName); // need soundName:String here
		}
	}
	
	private function SetShadow1Flag() {
		SB1_Cast = true;
		DebugText("SetShadow1Flag(): " + SB1_Cast);
	}
	
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
		// breaking target and retargeting the boss seems to somehow call the LurkerCasting function a second time,
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
		// breaking target and retargeting the boss seems to somehow call the LurkerCasting function a second time,
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
		healthController.UpdateText("100%")
		
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
				
				if (debugMode && Boolean(fromBeneathSound.GetValue())) { PlayFromBeneathWarningSound(); }
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
				
				if (debugMode  && Boolean(personalSound.GetValue())) { PlayPersonalSpaceWarningSound(); }
			}
		}
    }
	
	// Debugging
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText(text);
	}
	
	
	///////////////////////////////////////
	////// Deprecated - delete later //////
	///////////////////////////////////////
		
/*	public function TargetChanged(id:ID32) {	
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
				
				// Connect to lurker-specific signals
				ConnectLurkerSignals();
				
				// Lock on lurker so that we don't continue to check targets anymore
				lurkerLocked = true;
				updateHealthDisplay = true;
				DebugText("Lurker Locked!!")
				// TODO: should we just call DisconnectTargetChangedSignal() here and remove hte lurkerLocked flag?
			}
		}
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
	
	// from LairTracker - find dynels that were already loaded before connecting signals
	private function kickstart() {
		DebugText("kickstart()");
		var ls:WeakList = Dynel.s_DynelList
		for (var num = 0; num < ls.GetLength(); num++) {
			var dyn:Character = ls.GetObject(num);
			DetectNPCs(dyn.GetID());
		}
	}
	*/

}