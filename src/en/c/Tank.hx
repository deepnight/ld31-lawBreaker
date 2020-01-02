package en.c;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class Tank extends en.Car {
	public static var ALL : Array<Tank> = [];
	public function new(x,y) {
		super(x,y);

		ALL.push(this);
		setLife(200);
		speed *= 0.5;
		weight = 100;
		spr.set("tank");
		side.set("tankSide");
	}

	//override function repop(x,y) {
		//super.repop(x,y);
		//new en.c.Tank(x,y);
	//}


	override function onRepeledBy(e,r) {
		super.onRepeledBy(e,r);

		if( hasHeroDriver() && e.isCar() ) {
			e.hit(5);
			if( e.destroyAsked && !cd.has("911") ) {
				cd.set("911", Const.seconds(10));
				en.c.Cop.call911();
			}
		}
	}


	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
	}
}
