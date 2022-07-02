package;

class Actor implements IUpdater {
	public var game(default, null): Game;
	public var level(default, null): Level;

	public var destroyed(default, set): Bool = false;
	// actor that owns this actor, null for no owner
	public var owner(default, set): Actor;
	// actors that have this actor as owner
	var ownees: List<Actor>;
	// cell location
	public var cellLocation: IPoint;
	// ratio within cell location
	public var cellRatio: Point;
	// current pixel location
	public var location(get, never): Point;
	inline function get_location()
		return new Point( (cellLocation.x + cellRatio.x) * level.GRID,
			(cellLocation.y + cellRatio.y) * level.GRID );
	// set pixel location
	public function setLocation( x: Float, y: Float ) {
		cellLocation.x = int(x / level.GRID);
		cellLocation.y = int(y / level.GRID);
		cellRatio.x = (x - cellLocation.x * level.GRID) / level.GRID;
		cellRatio.y = (y - cellLocation.y * level.GRID) / level.GRID;
	}
	// previous fixed update pixel location
	var _lastFixedLocation: Point;
	// collision radius
	public var radius: Float;
	// cell ratio velocity
	public var velocity: Point;
	// visual
	public var visible: Bool = true; // latent spr.visible
	public var spr: Sprite;

	// temp spawn vars for base constructor
	static var _st_owner: Actor = null;
	static var _st_location: Point = null;

	public function new() {
		trace( 'New Actor!' );
		game = Game.ME;
		level = Level.ME;
		destroyed = false;
		level.addActor( this ); // throws if no more room in level

		ownees = new List<Actor>();
		owner = _st_owner;
		cellLocation = new IPoint( 0, 0 );
		cellRatio = new Point( 0, 0 );
		velocity = new Point( 0, 0 );

		_st_location = _st_location != null ? _st_location :
			(_st_owner != null ? _st_owner.location : new Point( 0, 0 ));

		setLocation( _st_location.x, _st_location.y );
		_lastFixedLocation = location.clone();
		radius = level.GRID / 2.0;

		spr = new Sprite( game.defaultTile );
		game.scroller.add( spr, G.LAYER_MAIN );
	}

	// spawn a new actor in the level at location and with owner
	// returns null if unable spawn in level
	@:generic
	public static function spawn<T: Constructible<Void->Void> & Actor>(
			base: Class<T>, ?ownerActor: Actor = null, ?loc: Point = null ): T {
		var a: T = null;

		// set spawn temps for base constructor
		_st_owner = ownerActor;
		_st_location = loc;

		// init and try to add to level
		try {
			a = new T();
		} catch ( e ) {
			trace( 'Failed to spawn actor of type \'${base}\' at ${_st_location}! ${e.message}' );
			return null;
		}

		//a.onSpawned(); // ready for play...
		return a;
	}

	// change, set, or remove the owner
	function set_owner( value: Actor ) {
		if ( owner == value || owner == this ) return owner;
		var pOwner = owner;
		if ( value != null ) {
			// null to real owner
			if ( pOwner == null ) {
				owner = value;
				owner.ownees.add( this );
			// real owner to new real owner
			} else {
				pOwner.ownees.remove( this );
				owner = value;
				owner.ownees.add( this );
			}
		// real to null owner
		} else {
			pOwner.ownees.remove( this );
			owner = value;
		}
		return value;
	}

	// destroy and remove actor from level at end of frame
	public inline final function destroy() { destroyed = true; }
	// actual destruction is done when var is set
	function set_destroyed( v: Bool ) {
		// only set to true once in lifetime
		if ( !destroyed ) {
			if ( v ) {
				destroyed = true;
				level.destroyActor( this );
				return true;
			} else return destroyed = false;
		}
		return true;
	}

	// after init and added to level...
	//public function onSpawned() {}

	// when destroyed and removed from level
	public function onDestroyed() {
		// sprite
		spr.remove();
		spr = null;
		// owner 
		owner = null;
		for ( o in ownees )
			o.owner = null;
		ownees.clear();
	}

	// prestep collision / physics checks
	function onPreStepX() {}
	function onPreStepY() {}

	// update callbacks
	public function onPreUpdate() {}

	public function onUpdate() {}

	public function onFixedUpdate() {
		_lastFixedLocation.load( location );
		// step through movement. adopted from deepnight's gamebase entity
		var steps = M.ceil( (M.abs( velocity.x ) + M.abs( velocity.y )) / 0.33 );
		if ( steps > 0 ) {
			var n = 0;
			while ( n < steps ) {
				cellRatio.x += velocity.x / steps;
				if ( velocity.x != 0 ) onPreStepX();
				while ( cellRatio.x > 1 ) { cellRatio.x--; cellLocation.x++; }
				while ( cellRatio.x < 0 ) { cellRatio.x++; cellLocation.x--; }
				cellRatio.y += velocity.y / steps;
				if ( velocity.y != 0 ) onPreStepY();
				while ( cellRatio.y > 1 ) { cellRatio.y--; cellLocation.y++; }
				while ( cellRatio.y < 0 ) { cellRatio.y++; cellLocation.y--; }
				n++;
			}
		}
		// friction
		velocity.x *= 0.82;
		velocity.y *= 0.82;
		if ( M.abs( velocity.x ) <= 0.0005 ) velocity.x = 0;
		if ( M.abs( velocity.y ) <= 0.0005 ) velocity.y = 0;
	}

	public function onPostUpdate() {
		// update lerped sprite position.
		var loc = location;
		spr.x = M.lerp( _lastFixedLocation.x, loc.x, game.fixedAlpha );
		spr.y = M.lerp( _lastFixedLocation.y, loc.y, game.fixedAlpha );
		spr.visible = visible;
	}
}

// custom sprite
class Sprite extends h2d.Drawable {
	// tile
	public var tile: h2d.Tile;

	public function new( t: h2d.Tile, ?p: h2d.Object ) {
		super( p );
		tile = t;
	}

	override function onRemove() {
		tile = null;
		super.onRemove();
	}

	override function getBoundsRec( rel, out, forSize ) {
		super.getBoundsRec( rel, out, forSize );
		addBounds( rel, out, tile.dx, tile.dy, tile.width, tile.height );
	}

	override function draw( ctx: h2d.RenderContext ) {
		emitTile( ctx, tile );
	}

	override function sync( ctx: h2d.RenderContext ) {
		super.sync( ctx );
	}
}
