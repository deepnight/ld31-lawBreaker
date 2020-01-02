package en;

import mt.MLib;
import mt.deepnight.slb.*;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	private function new(x,y) {
		super();

		ALL.push(this);

		setPosCase(x,y);
		physics = false;
		repels = false;

		spr.set("heart");
		spr.setCenter(0.5, 0.5);

		updateCoords();
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function updateCoords() {
		super.updateCoords();
	}

	function onPick() {
		destroy();
	}


	override function update() {
		super.update();

		var h = Game.ME.hero;
		if( h.car==null || h.car.canLeave() ) {
			if( Game.ME.pacman && cx==h.cx && cy==h.cy )
				onPick();

			if( !Game.ME.pacman && MLib.iabs(cx-h.cx)<=1 && MLib.iabs(cy-h.cy)<=1 )
				onPick();
		}
	}
}