// your worse enemy
package;

class Enemy extends Actor {
	var p: Player;
	var frames: Array<Tile>;
	var cf = 0.0;

	function new() {
		super();
		touchActors = true;
		bumpActors = true;
		friction = 0.2;
		bumpForce = 0.2;
		radius = 6;

		spr.tile = Res.ghost.toTile();
		frames = spr.tile.gridFlatten( 16, -8, -8 );
		cf = G.rand.uint() % 2;
	}

	override function onBeginPlay() {
		super.onBeginPlay();
		// get ref to player
		for ( a in level.allActors( Player ) ) {
			p = cast a;
		}
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		var dirToP = p.location.sub( location ).normalized();
		velocity.x += dirToP.x * 0.03;
		velocity.y += dirToP.y * 0.03;
	}

	override function onPostUpdate() {
		super.onPostUpdate();
		spr.tile = frames[int(cf) % frames.length];
		cf += 6 / G.FPS * game.tmod;
	}

	override function onBump( other: Actor ) {
		if ( isOfType( other, Player ) ) {
			other.takeDamage( 0.05 );
		}
	}

	override function onPreStepX() {
		super.onPreStepX();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// right blocked
		if ( cellRatio.x > 0.55 ) {
			var rightcol = level.getCollision( cx+1, cy );
			if ( rightcol == Col_Solid || curcol == Col_Right || rightcol == Col_Left ) {
				cellRatio.x = 0.55;
			}
		}

		// left blocked
		if ( cellRatio.x < 0.45 ) {
			var leftcol = level.getCollision( cx-1, cy );
			if ( leftcol == Col_Solid || curcol == Col_Left || leftcol == Col_Right ) {
				cellRatio.x = 0.45;
			}
		}
	}

	override function onPreStepY() {
		super.onPreStepY();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// bottom blocked
		if ( cellRatio.y > 0.55 ) {
			var bottomcol = level.getCollision( cx, cy+1 );
			if ( bottomcol == Col_Solid || curcol == Col_Bottom || bottomcol == Col_Top ) {
				cellRatio.y = 0.55;
			}
		}
		// top blocked
		if ( cellRatio.y < 0.45 ) {
			var topcol = level.getCollision( cx, cy-1 );
			if ( topcol == Col_Solid || curcol == Col_Top || topcol == Col_Bottom ) {
				cellRatio.y = 0.45;
			}
		}
	}
}
