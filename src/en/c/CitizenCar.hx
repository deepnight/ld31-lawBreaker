package en.c;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class CitizenCar extends en.Car {
	public function new(x,y) {
		super(x,y);

		setSkin( irnd(2,4) );
	}

	override function repop(x,y) {
		super.repop(x,y);
		new en.c.CitizenCar(x,y);
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
	}
}
