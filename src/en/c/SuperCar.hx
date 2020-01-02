package en.c;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class SuperCar extends en.Car {
	public static var ALL : Array<SuperCar> = [];
	public function new(x,y) {
		super(x,y);

		ALL.push(this);
		setLife(15);
		setSkin(0);
	}

	override function repop(x,y) {
		super.repop(x,y);
		new en.c.SuperCar(x,y);
	}


	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
	}
}
