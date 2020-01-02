class Main { //}

	static function main() {
		haxe.Log.setColor(0xFFFF00);
		flash.Lib.current.addEventListener( flash.events.Event.ENTER_FRAME, update );
		flash.Lib.current.stage.addEventListener( flash.events.Event.RESIZE, onResize );
		onResize(null);

		new Game();
	}

	static function onResize(_) {
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Const.UPSCALE = mt.MLib.round(flash.Lib.current.stage.stageWidth/425);
	}

	static function update(_) {
		mt.deepnight.Process.updateAll();
	}

}
