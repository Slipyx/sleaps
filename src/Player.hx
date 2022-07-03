package;

class Player extends Actor {
	var frames: Array<Tile>;
	var fi: Float;

	var g: h2d.Graphics;
	var g2: h2d.Graphics;
	// current, target forward dir
	var cfwd: Point;
	var tfwd: Point;
	var tps = 5; // 5
	var afps = 6; // 6

	public function new() {
		super();

		for ( a in level.allActors(  ) ) {
			trace( '${$type(a)}, ${a.tag}' );
		}

		trace( 'New player! ${location}' );
		cfwd = new Point(1,0);
		tfwd = new Point(1,0);

		spr.tile = Res.pchar.toTile();
		//spr.t = Tile.autoCut( Res.char.toBitmap(), 16, 16 ).main;
		//be.t.setCenterRatio();
		frames = new Array<Tile>();
		for ( y in 0...4 )
			for ( x in 0...4 ) {
				frames.push( spr.tile.sub( x*16,y*32,16,32, -8,-24 ) );
			}
		fi = 0;

		// snap cam to spawn
		game.camLocation.x = spr.x;
		game.camLocation.y = spr.y;

		// bounds
		g = new h2d.Graphics( spr );
		g.lineStyle( 0.5, 0x00ff00, 1 );
		g.drawRect( -8 , -8, 16, 16 );
		g.lineStyle( 0.5, 0xff0000, 1 );
		g.drawCircle( 0, 0, radius );
		// cur fwd dir
		g2 = new h2d.Graphics( spr );
		g2.beginFill( 0x0000ff );
		g2.drawRect( radius, -1, 8, 2 );
		g2.endFill();
		trace( 'Player init!' );
	}

	override function onPreStepX() {
		super.onPreStepX();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );

		// right blocked
		if ( cellRatio.x > 0.5 ) {
			var rightcol = level.getCollision( cellLocation.x+1, cellLocation.y );
			if ( rightcol == Col_Solid || curcol == Col_Right || rightcol == Col_Left ) {
				cellRatio.x = 0.5;
				velocity.x = 0;
			}
		}

		// left blocked
		if ( cellRatio.x < 0.5 ) {
			var leftcol = level.getCollision( cellLocation.x-1, cellLocation.y );
			if ( leftcol == Col_Solid || curcol == Col_Left || leftcol == Col_Right ) {
				cellRatio.x = 0.5;
				velocity.x = 0;
			}
		}
	}

	override function onPreStepY() {
		super.onPreStepY();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );

		// bottom blocked
		if ( cellRatio.y > 0.5 ) {
			var bottomcol = level.getCollision( cellLocation.x, cellLocation.y+1 );
			if ( bottomcol == Col_Solid || curcol == Col_Bottom || bottomcol == Col_Top ) {
				cellRatio.y = 0.5;
				velocity.y = 0;
			}
		}
		// top blocked
		if ( cellRatio.y < 0.5 ) {
			var topcol = level.getCollision( cellLocation.x, cellLocation.y-1 );
			if ( topcol == Col_Solid || curcol == Col_Top || topcol == Col_Bottom ) {
				cellRatio.y = 0.5;
				velocity.y = 0;
			}
		}
	}

	override function onUpdate() {
		super.onUpdate();

		game.camLocation.x = M.lerp( game.camLocation.x, spr.x, 0.33 );
		game.camLocation.y = M.lerp( game.camLocation.y, spr.y, 0.33 );
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		// movement vector based on screen mouse pos distance from center of window
		var m = new Point( game.scrMouseX, game.scrMouseY );
		var wnd = game.window;
		var gscale = G.SCALE;
		var scrc = new Point( wnd.width/gscale/2.0, wnd.height/gscale/2.0 );

		if ( Key.isDown( Key.MOUSE_LEFT ) ) {
			var dst = m.distance( scrc );
			if ( dst > 0 ) {
				tfwd.x = m.x - scrc.x;
				tfwd.y = m.y - scrc.y;
				tfwd.normalize();
				cfwd.lerp( cfwd, tfwd, 0.55 );
				cfwd.normalize();
				g2.rotation = M.atan2( cfwd.y, cfwd.x );
			}
			velocity = cfwd.multiply( (1.0/G.FIXED_FPS) * tps ); // tiles per sec
		}
	}

	var afwd = true;
	var astart = 0;
	override function onPostUpdate() {
		super.onPostUpdate();

		var qang = (M.PI / 4.0);
		var ang = M.atan2( cfwd.y, cfwd.x );
		if ( ang > (-qang) && ang < (qang) ) { // right
			if ( astart != 4 ) fi = 4;
			astart = 4;
		}
		if ( ang > (qang) && ang < (qang * 3) ) { // down
			if ( astart != 0 ) fi = 0;
			astart = 0;
		}
		if ( ang > (-qang * 3) && ang < (-qang) ) { // up
			if ( astart != 8 ) fi = 8;
			astart = 8;
		}
		if ( ang > (qang * 3) || ang < (-qang * 3) ) { // left
			if ( astart != 12 ) fi = 12;
			astart = 12;
		}

		var arate = afps / G.FPS * game.tmod; // fps
		if ( velocity.length() <= 0.01 ) {arate = 0; fi = astart;}
		// frame start and end
		var aframes = 4;
		var aend = astart + aframes-1;
		// loop
		fi += arate;
		if ( fi >= aend + 1 ) fi = astart;
		// pong
		/*if ( afwd ) {
			fi += arate;
			if ( fi >= aend + 1 ) { fi = aend; afwd = false; }
		} else {
			fi -= arate;
			if ( fi <= astart ) { fi = astart + 1; afwd = true; }
		}*/

		spr.tile = frames[int(fi)];
	}

	override function onDestroyed() {
		trace( 'Player destroyed!' );
		frames = null;
		super.onDestroyed();
	}
}
