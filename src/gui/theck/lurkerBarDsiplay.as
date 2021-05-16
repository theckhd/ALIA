/**
 * ...
 * @author theck
 */

import gui.theck.SimpleBar;
import flash.geom.Point;
import com.theck.Utils.Debugger;
 
class gui.theck.lurkerBarDsiplay
{
	private var debugMode:Boolean = false;
	private var shadowBarEnabled:Boolean = false;
	
    public var clip:MovieClip;
	
	private var barFontSize:Number = 16;
	private var barWidthInSeconds:Number = 30;
	
	public var fromBeneathBar:SimpleBar;
	public var pureFilthBar:SimpleBar;
	public var shadowBar:SimpleBar;
	
	// color order is [darker lighter], default is Grey [0x2E2E2E, 0x585858]
	private var podColors:Array = [0x997A00, 0xFFD11A];  
	private var pureFilthColors:Array = [0x000066, 0x3333FF]; 
	
	public function lurkerBarDsiplay(target:MovieClip, barScale:Number) 
	{
		if !barScale { barScale = 9 }; // default: 10 pixels per second
		var barWidths:Number = barWidthInSeconds * barScale;
		
		clip = target.createEmptyMovieClip("lurkerBarDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		clip.backgroundColor = 0x000000;
		
		fromBeneathBar = new SimpleBar("fromBeneath", clip, 0, 0, barWidths, barFontSize, podColors);
		pureFilthBar = new SimpleBar("pureFilth", clip, 0, fromBeneathBar.barHeight, barWidths, barFontSize, pureFilthColors);
		
		fromBeneathBar.SetRightText("Pod");
		pureFilthBar.SetRightText("Pure Filth");
		
		//fromBeneathBar.EnableInteraction(false);
		//pureFilthBar.EnableInteraction(false);
		//shadowBar.EnableInteraction(false);
		
		// disable shadow bar for now since it's useless
		if shadowBarEnabled {
			shadowBar = new SimpleBar("shadow", clip, 0, fromBeneathBar.barHeight + pureFilthBar.barHeight, barWidths, barFontSize);
			shadowBar.SetRightText("Shadow");
		}
		//shadowBar.SetVisible(false);
	}
	
	
	
	public function SetGUIEdit(state:Boolean) {
		Debugger.DebugText("lBD:SetGUIEdit() called with argument: " + state, debugMode);
		ToggleBackground(state);
		EnableInteraction(state);
		
		UpdateFromBeneathBar( barWidthInSeconds * 1000 * ( state ? 0.25 : 1 ) );
		UpdatePureFilthBar( barWidthInSeconds * 1000 * ( state ? 0.5 : 1 ) ); 
		if shadowBarEnabled {UpdateShadowBar(barWidthInSeconds * 1000 * ( state ? 0.75 : 1 ) ) }; 
		
		fromBeneathBar.ShowDragText(state);
		pureFilthBar.ShowDragText(state);
		if shadowBarEnabled {shadowBar.ShowDragText(state) };
	}
	
	public function ToggleBackground(flag:Boolean) {
		clip.background = flag;
	}

	public function EnableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
		
	}
	
	
	public function SetPos(pos:Point) {
		// sanitize inputs - this fixes a bug where someone changes screen resolution and suddenly the field is off the visible screen
		if ( pos.x > Stage.width || pos.x < 0 ) { pos.x = Stage.width / 2; }
		if ( pos.y > Stage.height || pos.y < 0 ) { pos.y = Stage.height / 2; }
		
		// set position
		clip._x = pos.x;
		clip._y = pos.y;
	}
	
	public function GetPos() {
		var pos:Point = new Point(clip._x, clip._y);
		Debugger.DebugText("GetPos: x: " + pos.x + "  y: " + pos.y, debugMode);
		return pos;
	}
		
	public function SetVisible(flag:Boolean, phase:Number) {
		Debugger.DebugText("LBD.SetVisible(): flag=" + flag + ", phase=" + phase, debugMode);
		if ( phase == 4 ) {
			clip._visible = false;
		}
		else {
			clip._visible = flag;
		}
		
		if ( shadowBarEnabled && phase && ( phase == 3 ) ) {
			shadowBar.SetVisible(flag);
			Debugger.DebugText("shadowBar set to flag", debugMode);
		}
		else {
			shadowBar.SetVisible(false);
			Debugger.DebugText("shadowBar set to false", debugMode);
		}
	}

	
	//private function SetFakeStatusText() {
		//fromBeneathBar.Update(10, "Drag", "Me");
		//pureFilthBar.Update(20);
		//shadowBar.Update(30);
	//}
	
	public function EnableShadowBar(flag:Boolean) {
		shadowBarEnabled = flag;
	}
	
	public function UpdateFromBeneathBar(time:Number) {

		fromBeneathBar.Update( time / barWidthInSeconds / 1000, FormatTimeString(time), "Pod");
	}
	
	public function UpdatePureFilthBar(time:Number) {

		pureFilthBar.Update(time / barWidthInSeconds / 1000, FormatTimeString(time), "Pure Filth");
	}
		
	public function UpdateShadowBar(time:Number) {
		
		if shadowBarEnabled { shadowBar.Update(time / barWidthInSeconds / 1000, FormatTimeString(time), "Shadow") };
	}
	
	public function FormatTimeString(time:Number):String {
		//Debugger.DebugText("LBD.FormatTimeString() time is " + time, debugMode);
		var timeStr:String;
		var timeInSec:Number = Math.round(time / 100) / 10;
		//var fullSeconds:Number = Math.floor(timeInSec);
		//var tenths:Number = 10*(timeInSec-fullSeconds);
		var fullSeconds:Number = Math.round(timeInSec);
		
		if ( time == undefined ) {
			timeStr = "N/A";
		}
		else if ( time <= 0 ) {
			timeStr = "Ready";
		}
		else {
			//timeStr = fullSeconds.toString() + "." + tenths.toString();
			timeStr = fullSeconds.toString();
		}
		return timeStr;
	}
}