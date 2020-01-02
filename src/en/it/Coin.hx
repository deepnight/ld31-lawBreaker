package en.it;

import mt.MLib;
import mt.deepnight.slb.*;

class Coin extends en.Item {
	public function new(x,y) {
		super(x,y);
		spr.a.playAndLoop("coin");
		spr.a.setCurrentAnimSpeed(0.5);
		spr.a.unsync();
	}

	override function onPick() {
		super.onPick();
		Assets.SBANK.coin02(1);
		Game.ME.gainMoney(this, 500);
		Game.ME.decPhaseCounterIf(P_Coins);
	}


	override function update() {
		super.update();
	}
}