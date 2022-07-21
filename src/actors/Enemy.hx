// your worse enemy
package actors;

class Enemy extends Actor {
	var pl: Player;
	var frames: Array<Tile>;
	var cf = 0.0;
	var lastPlLoc: Point;
	var g: h2d.Graphics;

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
		g = new h2d.Graphics();
		game.scroller.add( g, G.LAYER_TOP );
	}

	override function onDestroyed() {
		g.remove();
		super.onDestroyed();
	}

	override function onBeginPlay() {
		super.onBeginPlay();
		// get ref to player
		pl = Player.ME;
		//lifeSpan = 8;
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		spr.colorAdd = new h3d.Vector(1);
		/*g.clear();
		g.beginFill( 0x0000ff );
		g.lineStyle( 0.5, 0x0000ff, 1 );
		g.x = g.y = 0;*/
		// path
		var path = level.path.getPath( cellLocation.x, cellLocation.y,
			pl.cellLocation.x, pl.cellLocation.y );
		/*for ( pi in 0...path.length ) {
			var p2 = path[cast M.min(pi+1,path.length-1)];
			var p1 = path[pi];
			g.drawCircle( p1.x, p1.y, 2 );
			g.moveTo( p1.x, p1.y );
			g.lineTo( p2.x, p2.y );
		}*/
		if ( path.length > 0 ) {
			lastPlLoc = path[0]; // only go to first node for now...
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
		// fade out
		//spr.alpha = M.min( 1.0, (lifeSpan) / 1 );
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
