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

		/*g.clear();
		g.beginFill( 0x0000ff );
		g.lineStyle( 0.5, 0x0000ff, 1 );
		g.x = g.y = 0;*/
		// path
		var path = level.path.getPath( cellLocation.x, cellLocation.y,
			pl.cellLocation.x, pl.cellLocation.y );
		// draw path
		/*var p1 = cellLocation.toPoint( 16 ).add( new Point(8,8) );
		var p2 = p1;
		for ( pi in 0...path.length ) {
			p2 = path[pi];
			g.drawCircle( p2.x, p2.y, 2 );
			g.moveTo( p1.x, p1.y );
			g.lineTo( p2.x, p2.y );
			p1 = p2;
		}*/
		lastPlLoc = path[0];
		var dist = lastPlLoc.distanceSq( location );

		spr.colorAdd = new h3d.Vector(1);
		var dirToP = lastPlLoc.sub( location ).normalized();
		if ( dist >= 4 ) {
			velocity.x += dirToP.x * 0.02;
			velocity.y += dirToP.y * 0.02;
			spr.colorAdd.r = 0;
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
			other.takeDamage( 9, this );
			life = 0;
		}
	}

	override function onPreStepX() {
		super.onPreStepX();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// right blocked
		if ( cellRatio.x > 0.5 ) {
			var rightcol = level.getCollision( cx+1, cy );
			if ( rightcol == Col_Solid || curcol == Col_Right || rightcol == Col_Left ) {
				cellRatio.x = 0.5;
			}
		}

		// left blocked
		if ( cellRatio.x < 0.5 ) {
			var leftcol = level.getCollision( cx-1, cy );
			if ( leftcol == Col_Solid || curcol == Col_Left || leftcol == Col_Right ) {
				cellRatio.x = 0.5;
			}
		}
	}

	override function onPreStepY() {
		super.onPreStepY();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// bottom blocked
		if ( cellRatio.y > 0.5 ) {
			var bottomcol = level.getCollision( cx, cy+1 );
			if ( bottomcol == Col_Solid || curcol == Col_Bottom || bottomcol == Col_Top ) {
				cellRatio.y = 0.5;
			}
		}
		// top blocked
		if ( cellRatio.y < 0.5 ) {
			var topcol = level.getCollision( cx, cy-1 );
			if ( topcol == Col_Solid || curcol == Col_Top || topcol == Col_Bottom ) {
				cellRatio.y = 0.5;
			}
		}
	}
}
