import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.deepnight.Tweenie;
import mt.MLib;

class Outro extends mt.deepnight.FProcess {
	public var buffer		: Buffer;
	public var cm			: mt.deepnight.Cinematic;

	var ty					: Float;

	public function new() {
		super();

		ty = 50;

		var stage = flash.Lib.current.stage;
		buffer = new Buffer(425,267, Const.UPSCALE, false, 0x0);
		buffer.drawQuality = flash.display.StageQuality.MEDIUM;
		buffer.setTexture( Buffer.makeScanline(Const.UPSCALE), 0.6, true );
		root.addChild(buffer.render);

		cm = new mt.deepnight.Cinematic(Const.FPS);

		var logo = Assets.tiles.get("logo");
		buffer.dm.add(logo, Const.DP_LOGO);
		logo.setCenter(0.5, 0.5);
		logo.x = Std.int(buffer.width*0.25);
		logo.y = Std.int(buffer.height*0.5);
		logo.alpha = 0;
		tw.create(logo.alpha, 1, 2000);

		cm.create({
			2000;
			addLine("Thank you for playing!");
			addLine();
			1500;

			addLine("This game was created in 48h");
			500;
			addLine("for the Ludum Dare 31 game jam");
			500;
			addLine("(theme: \"Entire Game on One Screen\")");
			addLine();
			1500;

			addLine("If you liked Law Breaker,", 0xF38914);
			500;
			addLine("visit DEEPNIGHT.NET :)", 0xF38914);
			addLine();
			1500;

			addLine("Twitter: @deepnightFR", 0x6368A5);
			1500;
		});
	}

	override function onResize() {
		super.onResize();
		buffer.setScale(Const.UPSCALE);
	}

	function addLine(?txt:String, ?col=0xFFFFFF) {
		if( txt==null )
			ty+=10;
		else {
			var tf = Assets.createField(txt, col);
			buffer.dm.add(tf, Const.DP_INTERF);
			tf.x = 200;
			tf.y = ty;
			tf.alpha = 0;
			tw.create(tf.alpha, 1);

			ty+=tf.height;
		}
	}

	override function update() {
		super.update();
		cm.update();
		buffer.update();
	}
}