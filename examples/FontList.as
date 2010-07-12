package {
	
	import flash.display.Sprite;
	import flash.text.Font;
	import flash.external.ExternalInterface;
	
	public class FontList extends Sprite
	{
		public function FontList()
		{
			ExternalInterface.call('populateFontList', getDeviceFonts());
		}
		
		public function getDeviceFonts():Array
		{
			var embeddedFonts:Array = Font.enumerateFonts(true);
			var embeddedAndDeviceFonts:Array = Font.enumerateFonts(true);
			
			var deviceFontNames:Array = [];
			for each (var font:Font in embeddedAndDeviceFonts)
			{
				if (embeddedFonts.indexOf(font) != -1)
					continue;
				deviceFontNames.push(font.fontName);
			}
			
			deviceFontNames.sort();
			return deviceFontNames;
		}
	}
}
