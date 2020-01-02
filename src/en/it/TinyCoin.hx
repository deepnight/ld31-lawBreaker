package en.it;

import mt.MLib;
import mt.deepnight.slb.*;

class TinyCoin extends en.Item {
	public function new(x,y) {
		super(x,y);
		spr.set("tinyCoin");
	}

	override function onPick() {
		super.onPick();
		if( Game.ME.pacman ) {
			en.c.Cop.call911();
			Assets.SBANK.waka(0.1);
			Game.ME.gainMoney(this, 25, false);
			Fx.ME.pacmanEat(this);
		}
		else {
			Assets.SBANK.coin01(1);
			Game.ME.gainMoney(this, 25);
		}
		Game.ME.decPhaseCounterIf(P_Coins);

		if( Game.ME.pacman )
			Game.ME.decPhaseCounterIf(P_Banks);
	}


	override function update() {
		super.update();
	}
}