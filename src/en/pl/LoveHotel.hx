package en.pl;

import mt.MLib;
import mt.deepnight.slb.*;

class LoveHotel extends en.Place {
	public static var ALL : Array<LoveHotel> = [];
	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		speed*=2;
		icon.set("itemLove");
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function onPick() {
		var h = Game.ME.hero;
		if( h.life>=h.maxLife ) {
			if( !cd.hasSet("useless", Const.seconds(4)) )
				Fx.ME.text(Game.ME.hero, "You are not wounded honey");
			return;
		}

		super.onPick();

		if( h.life<h.maxLife )  {
			h.life = h.maxLife;
			Game.ME.infos.updateInfos();
		}

		Assets.SBANK.hit01(1);

		var names = [
			"Bob",
			"Mike",
			"Brenda",
			"Jenny",
		];
		var name = names[Std.random(names.length)];

		Fx.ME.text(Game.ME.hero, "You met "+name+" (healed)");
	}


	override function update() {
		super.update();
	}
}