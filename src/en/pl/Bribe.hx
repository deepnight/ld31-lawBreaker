package en.pl;

import mt.MLib;
import mt.deepnight.slb.*;

class Bribe extends en.Place {
	public static var ALL : Array<Bribe> = [];
	public function new(x,y) {
		super(x,y);
		//speed*=0.33;
		if( Game.ME.pacman )
			speed*=2.5;
		ALL.push(this);
		if( Game.ME.pacman )
			icon.set("itemCherry");
		else
			icon.set("itemStar");
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function onPick() {
		if( !Game.ME.pacman && en.c.Cop.getAlarmedCount()==0 ) {
			if( !cd.hasSet("useless", Const.seconds(4)) )
				Fx.ME.text(Game.ME.hero, "Not wanted by the police");
			return;
		}

		super.onPick();

		for(e in en.c.Cop.ALL) {
			if( Game.ME.pacman )
				e.cd.set("alarm", Const.seconds(8));
			else
				e.cd.set("alarm", Const.seconds(5));

			e.setAlarm(false);
		}

		if( Game.ME.pacman ) {
			Game.ME.hero.cd.set("cherry", Const.seconds(8));
			Fx.ME.text(Game.ME.hero, "Revenge!");
		}
		else
			Fx.ME.text(Game.ME.hero, "Got rid of the cops");

		Assets.SBANK.bribe(1);
	}


	override function update() {
		super.update();
	}
}