import caurina.transitions.Tweener;
/**
 * ...
 * @author fox
 */

class gui.theck.TextFieldController
{
    public var clip:MovieClip;
    private var field:TextField;
    
    public function TextFieldController(target:MovieClip) 
    {
        clip = target.createEmptyMovieClip("TextContainer", target.getNextHighestDepth());
        var textFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFFFFFF, true);
        textFormat.align = "center"
        field = clip.createTextField("m_Text", clip.getNextHighestDepth(), 0, 0, 0, 0);
        field.setNewTextFormat(textFormat);
        field._x = Stage.width /  2;
        field._y = 100;
        
        field.autoSize = "center";
    }
    
    public function UpdateText(text){
        field._alpha = 100;
        field.text = text;
        Tweener.addTween(field, {_alpha : 0, time:10});
    }
}