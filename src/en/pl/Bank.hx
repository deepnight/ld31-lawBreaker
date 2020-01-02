package en.pl;

import mt.MLib;
import mt.deepnight.slb.*;

class Bank extends en.Place {
	public static var ALL : Array<Bank> = [];
	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		icon.set("itemMoney");
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function onPick() {
		super.onPick();
		Game.ME.gainMoney( this, MLib.round( irnd(2500,3000)/10 )*10 );
		en.c.Cop.onRobbery();

		Assets.SBANK.coin03(1);

		var names = [
			"Bank",
			"Jewelry",
			"Estate",
		];
		var name = names[Std.random(names.length)];

		if( !Game.ME.pacman )
			Game.ME.decPhaseCounterIf(P_Banks);

		Fx.ME.text(Game.ME.hero, name+" robbed!");

		if( ALL.length>1 )
			Game.ME.delayer.add(function() {
				for( e in ALL )
					if( e!=this )
						Fx.ME.bleep(e, 0xFF0000, 10, 4, true);
			}, 1000);
	}


	override function update() {
		super.update();
	}
}