// your worse enemy
package;

class Enemy extends Actor {
	var pl: Player;
	var frames: Array<Tile>;
	var cf = 0.0;
	var lastPlLoc: Point;

	function new() {
		super();
		touchActors = true;
		bumpActors = true;
		friction = 0.5;
		bumpForce = 0.2;
		radius = 6;

		lastPlLoc = location;
		spr.tile = Res.ghost.toTile();
		frames = spr.tile.gridFlatten( 16, -8, -8 );
		cf = G.rand.uint() % 2;
	}

	override function onBeginPlay() {
		super.onBeginPlay();
		// get ref to player
		pl = Player.ME;
	}

	inline function losCanPass( px: Int, py: Int, tx: Int, ty: Int ): Bool {
		// initial check
		if ( px == tx && py == ty )
			return level.getCollision( tx, ty ) != Col_Solid;
		// target is solid
		if ( level.getCollision( tx, ty ) == Col_Solid ) return false;

		var dx = tx - px;
		var dy = ty - py;
		var pc = level.getCollision( px, py );
		var tc = level.getCollision( tx, ty );
		// up
		if ( dx == 0 && dy == -1 ) {
			if ( pc == Col_Top || tc == Col_Bottom ) return false;
		}
		// down
		if ( dx == 0 && dy == 1 ) {
			if ( pc == Col_Bottom || tc == Col_Top ) return false;
		}
		// left
		if ( dx == -1 && dy == 0 ) {
			if ( pc == Col_Left || tc == Col_Right ) return false;
		}
		// right
		if ( dx == 1 && dy == 0 ) {
			if ( pc == Col_Right || tc == Col_Left ) return false;
		}
		// diagonals...
		var lc = level.getCollision( px - 1, py );
		var rc = level.getCollision( px + 1, py );
		var dc = level.getCollision( px, py + 1 );
		var uc = level.getCollision( px, py - 1 );
		// diag up/left
		if ( dx == -1 && dy == -1 ) {
			if ( pc == Col_Left || pc == Col_Top ) return false;
			if ( ((lc == Col_Solid || lc == Col_Right || lc == Col_Top) &&
				 (uc == Col_Solid || uc == Col_Bottom || uc == Col_Left)) ||
				 (tc == Col_Bottom || tc == Col_Right) ) return false;
		}
		// diag up/right
		if ( dx == 1 && dy == -1 ) {
			if ( pc == Col_Right || pc == Col_Top ) return false;
			if ( ((rc == Col_Solid || rc == Col_Left || rc == Col_Top) &&
				 (uc == Col_Solid || uc == Col_Bottom || uc == Col_Right)) ||
				 (tc == Col_Bottom || tc == Col_Left) ) return false;
		}
		// diag down/left
		if ( dx == -1 && dy == 1 ) {
			if ( pc == Col_Left || pc == Col_Bottom ) return false;
			if ( ((lc == Col_Solid || lc == Col_Right || lc == Col_Bottom) &&
				 (dc == Col_Solid || dc == Col_Top || dc == Col_Left)) ||
				 (tc == Col_Top || tc == Col_Right) ) return false;
		}
		// diag down/right
		if ( dx == 1 && dy == 1 ) {
			if ( pc == Col_Right || pc == Col_Bottom ) return false;
			if ( ((rc == Col_Solid || rc == Col_Left || rc == Col_Bottom) &&
				 (dc == Col_Solid || dc == Col_Top || dc == Col_Right)) ||
				 (tc == Col_Top || tc == Col_Left) ) return false;
		}

		return true;
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		spr.colorAdd = new h3d.Vector(1);
		// line of sight
		if ( lib.PathFinder.checkLine( cellLocation.x, cellLocation.y,
				pl.cellLocation.x, pl.cellLocation.y, losCanPass ) ) {
			lastPlLoc = pl.location;
			spr.colorAdd.r = 0;
		}

		var dirToP = lastPlLoc.sub( location ).normalized();
		var dist = lastPlLoc.distanceSq( location );
		if ( dist > 256 ) {
			velocity.x += dirToP.x * 0.02;
			velocity.y += dirToP.y * 0.02;
		}
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
