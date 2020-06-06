import mx.utils.Delegate;
/**
 * ...
 * @author theck
 */
class gui.theck.guiBase
{
	
	public function guiBase() 
	{
		
	}
	
	public var AnnounceText:MovieClip
	
	public function createTextField(m_swfRoot:MovieClip){
		
		var textFormat:TextFormat = new TextFormat("_StandardFont", 30,0xFFFFFF, true);
        textFormat.align = "center"
		
        AnnounceText = m_swfRoot.createTextField("m_Text", m_swfRoot.getNextHighestDepth(), 0, 0, 0, 0);
        AnnounceText.setNewTextFormat(textFormat);
        AnnounceText._x = Stage.width /  2;
        AnnounceText._y = 100;
        AnnounceText.autoSize = "center";
        
        AnnounceText.text = "Somewhat long lurker announcement testing string";
        AnnounceText.interval = setInterval(Delegate.create(this, function(){
            if (this.AnnounceText.color){
                this.AnnounceText.color = false;
                this.AnnounceText.textColor = 0xFFFFFF;
            }
            else
            {
                this.AnnounceText.color = true;
                this.AnnounceText.textColor = 0xFF0F0F;
            }
        }), 200);
        //clearInterval(AnnounceText.interval);
        //this.AnnounceText._visible = false;
	
	}
	
	
}
class gui.theck.guiBase.guiCreator
{
    static function createTextfield(target){
        return new TextFieldController(target);
    }
}