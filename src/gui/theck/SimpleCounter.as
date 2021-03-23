/**
 * ...
 * @author theck
 */

 
import com.theck.Utils.Debugger;
import com.Utils.Text;
import mx.utils.Delegate;
import flash.geom.Point;

class gui.theck.SimpleCounter
{
	private var debugMode:Boolean = false;
		
	public var clip:MovieClip;
	private var m_text:TextField;
	private var m_parent:MovieClip;
	
	static var POLLING_INTERVAL:Number = 100;
	private var lastUpdateTime:Date;
	private var timeRemaining:Number;
	private var counterUpdateInterval:Number;
	
	public function SimpleCounter(name:String, parent:MovieClip, inFontSize:Number) 
	{
		var fontSize:Number = inFontSize;
		if (fontSize == null || fontSize < 6) {
			fontSize = 14;
			Debugger.DebugText("Fontsize defaulted to " + fontSize, debugMode);
		}
		
		m_parent = parent;
		clip = m_parent.createEmptyMovieClip(name + "SimpleCounter", m_parent.getNextHighestDepth());
		
		clip._x = Stage.width /  2;
		clip._y = Stage.height / 2;
		
		var textFormat:TextFormat = new TextFormat("_StandardFont", fontSize, 0xFFFFFF, true);
		textFormat.align = "center";
		
		var extents:Object = Text.GetTextExtent("10:00", textFormat, clip);
		var height:Number = Math.ceil( extents.height * 1.00 );
		var width:Number = Math.ceil( extents.width * 1.00 );
		
		m_text = clip.createTextField("10:00", clip.getNextHighestDepth(), 0, 0, width, height);
		
		m_text.setNewTextFormat(textFormat);
		m_text.background = true;
		m_text.backgroundColor = 0x000000;
	}
	
		
	public function StartCounting():Void {
		
		// clear any existing polling interval
		StopCounting();
		Debugger.DebugText("StartCounting()", debugMode);
		
		
		// start polling every 100 ms (set by POLLING_INTERVAL)
		counterUpdateInterval = setInterval(Delegate.create(this, UpdateCounter), POLLING_INTERVAL);
		UpdateCounter();
	}
	
	public function StopCounting() 
	{	
		
		Debugger.DebugText("StopCounting()", debugMode);
		clearInterval(counterUpdateInterval); 
		lastUpdateTime = undefined;
	}
	
	public function SetTime(mins:Number, secs:Number, msecs:Number) {
		Debugger.DebugText("SC.SetTime() called with " + mins + " " + secs + " " + msecs, debugMode);
		
		// to set time to a particular value
		timeRemaining = msecs + secs * 1000 + mins * 60 * 1000;
		UpdateText(FormatTimeText(timeRemaining));
	}
	
	private function FormatTimeText(time:Number):String {
		
		var outputText:String;
		
		var mins = Math.floor(time / 1000 / 60 );
		var secs = Math.floor( ( time - (60 * 1000 * mins) ) / 1000 );
		var dsecs = Math.floor( ( time - 60 * 1000 * mins - 1000 * secs ) / 100 );
		
		var secsString:String;
		var dsecsString:String;
		
		secsString = ParseSeconds(secs);
		dsecsString = dsecs.toString();
		
		if ( mins > 0 || secs > 30 ) {
			outputText = mins.toString() + ":" + secsString;
		}
		else {
			outputText = secsString + "." + dsecsString;
		}
		
		return outputText;
	}
	
	private function ParseSeconds(time:Number):String {
		if time >= 10 {
			return time.toString();
		}
		else if ( time < 10 && time > 0 ) {
			return "0" + time.toString();
		}
		else {
			return "00";
		}
	}
	
	
	private function UpdateCounter() 
	{
		//Debugger.DebugText("UpdateCounter()", debugMode);
		
		var currentTime:Date = new Date();
		
		if !lastUpdateTime { lastUpdateTime = currentTime; }
		
		var reduxAmount:Number;
		
		reduxAmount = currentTime.getTime() - lastUpdateTime.getTime();
		if reduxAmount > (2 * POLLING_INTERVAL ) {
			Debugger.DebugText("UpdateCounter(): anomalous reduxAmount is " + reduxAmount, debugMode);
		}
		
		timeRemaining = ReduceTimeRemaining( timeRemaining, reduxAmount );
		
		UpdateText(FormatTimeText(timeRemaining));
		
		lastUpdateTime = currentTime;
		
	}
	
	public function UpdateText(text) {
		//Debugger.DebugText("UpdateText called", debugMode);
        m_text.text = text;
    }
	
	private function ReduceTimeRemaining(timer:Number, amount:Number) 
	{
		// if the timer hasn't been started yet, skip
		if ( timer == undefined ) {
			return undefined;
		}
		
		var newTime = timer
		
		// decrement time remaining
		newTime -= amount;
		
		// cap at zero
		if newTime < 0 {
			newTime = 0;
		}
		
		return newTime;
	}
	
	
	// GUI Stuff
	
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
		Debugger.DebugText("SC.SetVisible()", debugMode);
		clip._visible = flag;
		m_text._visible = flag;
	}
	
	public function SetGUIEdit(state:Boolean) {
		Debugger.DebugText("SC:SetGUIEdit() called with argument: " + state, debugMode);
		//ToggleBackground(state);
		EnableInteraction(state);
		
		if state {
			UpdateText("12:34");		
		}
		//else if (timeRemaining > 0 ) {
			//UpdateCounter();
		//}
	}

	public function EnableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
		
	}
}