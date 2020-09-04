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
	
    public var clip:MovieClip;
	
	private var barFontSize:Number = 16;
	private var barWidths:Number = 200;
	
	private var fromBeneathBar:SimpleBar;
	private var pureFilthBar:SimpleBar;
	
	
	
	public function lurkerBarDsiplay(target:MovieClip) 
	{
		
		clip = target.createEmptyMovieClip("npcStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		
		fromBeneathBar = new SimpleBar("fromBeneath", clip, 0, 0, barWidths, barFontSize);
		pureFilthBar = new SimpleBar("pureFilth", clip, 0, fromBeneathBar.barHeight, barWidths, barFontSize);
	}
	
	
	
	public function SetGUIEdit(state:Boolean) {
		Debugger.DebugText("lBD:SetGUIEdit() called with argument: " + state, debugMode);
		ToggleBackground(state);
		EnableInteraction(state);
		if state {
			SetFakeStatusText();
		}
		else {
			
		}
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
		
	public function SetVisible(flag:Boolean) {
		Debugger.DebugText("lBD.SetVisible()", debugMode);
		clip._visible = flag;
	}
	
	private function SetFakeStatusText() {
		fromBeneathBar.Update(0.5, "Left", "Right");
	}
	
	public function UpdateFromBeneathBar(pct:Number) {
		fromBeneathBar.Update(pct, "Alpha", "Beta");
	}
}