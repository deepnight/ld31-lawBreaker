package ui;

import mt.deepnight.slb.*;
import mt.deepnight.Lib;
import mt.MLib;

class Notification extends mt.deepnight.FProcess {
	var bmp				: flash.display.Bitmap;

	public function new(txt:String) {
		super(Game.ME);
		Game.ME.buffer.dm.add(root, Const.DP_INTERF);

		var tf = Assets.createField(txt.toUpperCase(), 0xFFCC00, 10, "tiny");
		tf.filters = [
			new flash.filters.GlowFilter(0x0,1, 2,2,4),
		];
		bmp = Lib.flatten(tf);
		bmp.bitmapData = Lib.scaleBitmap(bmp.bitmapData, 2, true);
		root.addChild(bmp);

		root.x = Game.ME.buffer.width;
		//root.y = Game.ME.buffer.height-bmp.height - 40;
		root.y = 150;
		tw.create(root.x, root.x-root.width, 400);
		cd.set("alive", Const.seconds(0.2*txt.length));
	}

	override function unregister() {
		super.unregister();

		bmp.bitmapData.dispose();
		bmp.bitmapData = null;
	}

	override function update() {
		super.update();

		if( !cd.has("alive") ) {
			root.alpha-=0.05;
			if( root.alpha<=0 )
				destroy();
		}
	}
}