import mt.deepnight.slb.*;
import mt.deepnight.slb.assets.TexturePacker;
import mt.flash.Sfx;
import mt.MLib;

class Assets {
	public static var initDone = false;
	public static var tiles		: BLib;
	public static var SBANK = Sfx.importDirectory("assets/sfx");

	public static var music : Sfx;
	public static var engine : Array<Sfx>;

	public static function init() {
		if( initDone )
			return;

		music = SBANK.music();
		music.setChannel(1);
		Sfx.setChannelVolume(0, 1);
		Sfx.setChannelVolume(1, 0.6);
		Sfx.setChannelVolume(2, 0.25);

		#if debug
		Sfx.muteChannel(1); // HACK
		#end

		engine = [];
		var i = 0;
		for(f in [SBANK.engine0, SBANK.engine1, SBANK.engine2, SBANK.engine3]) {
			var s = f();
			s.setChannel(2);
			engine[i] = s;
			i++;
		}

		initDone = true;
		tiles = TexturePacker.importXml("tiles.xml");
	}

	static var curEngine : Int;
	public static function setEngine(?f=-1.0) {

		if( f>=0 ) {
			f = MLib.fmin(f,1);
			var i = MLib.round((engine.length-1)*f);
			if( curEngine!=i ) {
				for( s in engine )
					s.stop();
				curEngine = i;
				engine[i].playLoop();
			}
		}
		else {
			for( s in engine )
				s.stop();
			curEngine = -1;
		}
	}

	public static function createField(str:Dynamic, ?col=0xFFFFFF, ?size=8, ?font="def") {
		var f = new flash.text.TextFormat(font, size, col);
		var tf = new flash.text.TextField();
		tf.defaultTextFormat = f;
		tf.setTextFormat(f);
		tf.embedFonts = true;
		tf.selectable = tf.mouseEnabled = tf.multiline = tf.wordWrap = false;
		tf.text = Std.string(str);
		tf.width = 300;
		tf.width = tf.textWidth+5;
		tf.height = tf.textHeight+3;
		return tf;
	}
}


