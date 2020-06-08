import caurina.transitions.Tweener;
import flash.geom.Point;
/**
 * ...
 * @author fox
 */

class gui.theck.TextFieldController
{
    public var clip:MovieClip;
    private var field:TextField;
	private var defaultTextFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFFFFFF, true);
	private var redTextFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFF0000, true);
    
    public function TextFieldController(target:MovieClip) 
    {
        clip = target.createEmptyMovieClip("TextContainer", target.getNextHighestDepth());
        var textFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFFFFFF, true);
        textFormat.align = "center"
        field = clip.createTextField("m_Text", clip.getNextHighestDepth(), 0, 0, 0, 0);
        field.setNewTextFormat(textFormat);
        field._x = Stage.width /  2;
        field._y = Stage.height / 2;
        
        field.autoSize = "center";
		field.background = false;
		field.backgroundColor = 0x000000;
    }
    
    public function UpdateText(text){
        field._alpha = 100;
        field.text = text;
		field.setNewTextFormat(defaultTextFormat);
		Tweener.removeAllTweens(true);
        //Tweener.addTween(field, {_alpha : 0, time:10});
    }

	public function decayText(decayTime){
		Tweener.addTween(field, {_alpha : 0, delay : 2, time : decayTime});		
	}
	
	public function setPos(pos:Point)
	{
		field._x = pos.x;
		field._y = pos.y;
	}
	
	public function getPos()
	{
		// this doesn't work
		var pos:Point = new Point(field._x, field._y);
		return pos;
	}
	
	public function setVisible(flag:Boolean)
	{
		field._visible = flag;	
	}
	
	public function toggleBackground(flag:Boolean)
	{
		field.background = flag;
	}
	
	public function setTextColor(color)
	{
        var textFormat:TextFormat = new TextFormat("_StandardFont", 30, color, true);
		field.setNewTextFormat(textFormat);
	}
	
/*	
	// crude attempt at making text blink - doesn't work
	public function blinkText()
	{
		goRed = function() {Tweener.addTween(field, {_textColor : 0xFF0000, delay : 1, time : 1, onComplete: goWhite}); }
		goWhite = function() {Tweener.addTween(field, {_textColor : 0xFFFFFF, delay : 1, time : 1, onComplete: goRed});}
		goRed();
	}
	*/
}