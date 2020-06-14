import caurina.transitions.Tweener;
import flash.geom.Point;
import com.theck.Utils.Debugger;
import flash.geom.ColorTransform;
import mx.utils.Delegate;
/**
 * ...
 * @author fox
 */

class gui.theck.TextFieldController
{
	// toggle debug messages
	static var debugMode = false;
	
    public var clip:MovieClip;
    private var field:TextField;
    
    public function TextFieldController(target:MovieClip, fieldName:String) 
    {
        clip = target.createEmptyMovieClip(fieldName, target.getNextHighestDepth());
        var textFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFFFFFF, true);
        textFormat.align = "center"
        field = clip.createTextField("m_Text", clip.getNextHighestDepth(), 0, 0, 0, 0);
        field.setNewTextFormat(textFormat);
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
        
        field.autoSize = "center";
		field.background = false;
		field.backgroundColor = 0x000000;
    }
    
    public function UpdateText(text) {
		Debugger.DebugText("UpdateText called", debugMode);
		Tweener.removeTweens(field);
        field._alpha = 100;
        field.text = text;
		field.textColor = 0xFFFFFF;
    }

	public function decayText(decayTime) {
		Debugger.DebugText("decayText called", debugMode);
		Tweener.addTween(field, {_alpha : 0, delay : 2, time : decayTime});	
        //setTimeout(Delegate.create(this, stopBlink), decayTime*1000 + 500);
	}
	
	public function setPos(pos:Point) {
		clip._x = pos.x;
		clip._y = pos.y;
	}
	
	public function getPos() {
		var pos:Point = new Point(clip._x, clip._y);
		Debugger.DebugText("getPos: x: " + pos.x + "  y: " + pos.y, debugMode);
		return pos;
	}
	
	public function setVisible(flag:Boolean) {
		field._visible = flag;	
	}
	
	public function toggleBackground(flag:Boolean) {
		field.background = flag;
	}
	
	public function setTextColor(color:Number) {
		field.textColor = color;
	}
	
	public function setGUIEdit(state:Boolean) {
		toggleBackground(state);
		enableInteraction(state);
	}
	
    public function blinkText() {
		Debugger.DebugText("blinkText called", debugMode);
		
		// clear any existing blinking effects first
        clearInterval(clip.blinkInterval);
        clip.transform.colorTransform = new ColorTransform();
		
		// Set up the color transform
        var colorTransform:ColorTransform = this.clip.transform.colorTransform;
        colorTransform.rgb = 0xFFFFFF;
        clip.transform.colorTransform = colorTransform;
        var increment = 20;		
        clip.blinkInterval = setInterval(Delegate.create(this,function(){
            if (colorTransform.greenOffset >= 255) increment = -20;
            if (colorTransform.greenOffset <= 0) increment = 20;
            colorTransform.greenOffset += increment;
            colorTransform.blueOffset += increment;
            this.clip.transform.colorTransform = colorTransform;
        }), 50);
    }
    
    public function stopBlink() {
		Debugger.DebugText("stopBlink called", debugMode);
        clearInterval(clip.blinkInterval);
        clip.transform.colorTransform = new ColorTransform();
    }

	public function enableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
		field.hitTestDisable = !state;
	}
}