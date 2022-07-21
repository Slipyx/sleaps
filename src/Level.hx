package;

import LDtkTypes;
import actors.*;

enum abstract ColVal(Int) from Int to Int {
	var Col_None;
	var Col_Solid;
	var Col_Right;
	var Col_Left;
	var Col_Top;
	var Col_Bottom;
}

class Level implements IUpdater {
	public static var ME(default, null): Level;
	public var game(default, null): Game;
	//public var root: Layers;
	public var GRID(default, null): Int = 16;
	// level size in grid units. determined by Collisions layer
	public var cellWidth(default,null): Int;
	public var cellHeight(default,null): Int;
	// pathfinder
	public var path(default,null): lib.PathFinder<Point>;

	// fixed size array of actors in level
	var actors: Vector<Actor>;
	// list of actors pending destruction at end of frame
	var destroyedActors: List<Actor>;
	// current number of active actors in level
	var numActors: Int = 0;

	var ldtk: LDtk;
	var layerTGs: Array<TileGroup>; // layer tilegroups
	var col: Array<ColVal>; // collision layer intgrid

	public function new() {
		ME = this;
		game = Game.ME;
		//root = new Layers();
		//game.scroller.add( root, G.LAYER_BG );
		actors = new Vector<Actor>( 1024 );
		destroyedActors = new List<Actor>();
		// array of layer tilegroups. order should be same as in ldtk (top to bottom)
		layerTGs = new Array<TileGroup>();

		// ldtk json project
		var st = haxe.Timer.stamp();
		ldtk = haxe.Json.parse( Res.levels.entry.getText() );
		// level0
		var level0 = ldtk.levels[0];
		// layers
		for ( l in level0.layerInstances ) {
			// get by identifiers
			if ( l.__identifier == 'BG' ) {
				// BG to BG layer
				var tg = renderLayer( l );
				// add to display and tg array
				if ( tg != null ) {
					layerTGs.push( tg );
					game.scroller.add( tg, G.LAYER_BG );
				}
			// collisions intgrid
			} else if ( l.__identifier == 'Collisions' ) {
				cellWidth = l.__cWid;
				cellHeight = l.__cHei;
				col = l.intGridCsv;
			// entity layer
			} else if ( l.__identifier == 'Entities' ) {
				for ( e in l.entityInstances ) {
					EntSpawner.spawnEntity( e );
				}
			}
		}

		st = (haxe.Timer.stamp() - st) * 1000;
		trace( 'Loaded LDtk project in $st ms.' );

		// init pathfinder
		path = new lib.PathFinder( (x,y)->new Point(x*GRID+8,y*GRID+8) );
		path.init( cellWidth, cellHeight );

		// call onBeginPlay on all active actors
		for ( i in 0...numActors ) {
			if ( !actors[i].destroyed )
				actors[i].onBeginPlay();
		}
	}

	// render a Tiles or AutoLayer layer to a new tilegroup and return it.
	// returns null if not these types
	function renderLayer( layer: LDtkLayer ): TileGroup {
		// tile data
		var data: Array<LDtkTile> = null;
		if ( layer.__type == 'Tiles' ) {
			data = layer.gridTiles;
		} else if ( layer.__type == 'AutoLayer' ) {
			data = layer.autoLayerTiles;
		}
		if ( data == null ) return null;
		var tg = new TileGroup( Res.loader.load( layer.__tilesetRelPath ).toTile() );
		for ( t in data ) {
			var sz = layer.__gridSize;
			tg.add( t.px[0] + layer.__pxTotalOffsetX, t.px[1] + layer.__pxTotalOffsetY,
				tg.tile.sub( t.src[0], t.src[1], sz, sz ) );
		}
		return tg;
	}

	// try to add new actor to level
	function addActor( a: Actor ) {
		if ( numActors >= actors.length ) {
			throw 'Actor limit reached!';
		}
		actors[numActors] = a;
		numActors++;
	}
	// set actor to be destroyed and removed from level at end of frame
	inline function destroyActor( a: Actor ) {
		destroyedActors.add( a );
	}
	// iterate on all active actors, optionally of only specfic class and/or tag
	public inline function allActors( ?base: Class<Actor>, ?tag: String ): Iterator<Actor> {
		return new ActorIter( base, tag );
	}

	// return collision value at location from intgrid
	public inline function getCollision( cx: Int, cy: Int ): ColVal {
		return col[cy * cellWidth + cx];
	}

	function purgeActors() {
		if ( destroyedActors.isEmpty() ) return;
		for ( a in destroyedActors ) {
			// remove from actors array
			for ( i in 0...numActors ) {
				if ( actors[i] == a ) {
					// remove this index
					actors[i] = null;
					if ( numActors > 1 ) {
						actors[i] = actors[numActors - 1];
						actors[numActors - 1] = null;
						numActors--;
					} else numActors = 0;
					break;
				}
			}
			// callback
			a.onDestroyed();
		}
		destroyedActors.clear();
	}

	public function destroy() {
		trace( 'Destroying level with $numActors active actors.' );
		for ( i in 0...numActors ) {
			actors[i].destroy();
		}
		purgeActors();
		actors = null;
		// ldtk and layer groups
		col = null;
		for ( tg in layerTGs ) {
			tg.remove();
			layerTGs.remove( tg );
			tg = null;
		}
		layerTGs = null;
		ldtk = null;
		trace( 'Destroyed level, ${numActors} actors survived.' );
	}

	public function onPreUpdate(): Void {
		for ( i in 0...numActors ) {
			if ( !actors[i].destroyed )
				actors[i].onPreUpdate();
		}
	}

	public function onUpdate(): Void {
		for ( i in 0...numActors ) {
			if ( !actors[i].destroyed )
				actors[i].onUpdate();
		}
	}

	public function onFixedUpdate(): Void {
		for ( i in 0...numActors ) {
			if ( !actors[i].destroyed )
				actors[i].onFixedUpdate();
		}
	}

	public function onPostUpdate(): Void {
		for ( i in 0...numActors ) {
			if ( !actors[i].destroyed )
				actors[i].onPostUpdate();
		}
		// remove actors pending destruction
		purgeActors();
	}
}

// iterator for level's active actors
@:access( Level )
private class ActorIter {
	var i: Int; // iteration
	var base: Class<Actor>; // class to filter by, null for all actors
	var tag: String; // tag to filter by, null for all

	public function new( ?base: Class<Actor>, ?tag: String ) {
		i = 0;
		this.base = base;
		this.tag = tag;
	}

	public inline function hasNext(): Bool {
		while ( i < Level.ME.numActors ) {
			if ( !(Level.ME.actors[i].destroyed) &&
					(if (base != null) isOfType( Level.ME.actors[i], base ) else true) &&
					(if (tag != null) (Level.ME.actors[i].tag == tag) else true) )
				return true;
			i++;
		}
		return false;
	}

	public inline function next(): Actor {
		return Level.ME.actors[i++];
	}
}

// spawning entities from LDtk levels
private class EntSpawner {
	// remapping ent names to actual class name
	static var _remaps: Map<String, String> = [
		'PlayerStart' => 'Player'
	];

	@:access(Actor._st_location)
	public static function spawnEntity( ent: LDtkEntity ) {
		var cname = ent.__identifier;
		// check for remap
		if ( _remaps.exists( cname ) ) cname = _remaps[cname];

		var a = Actor.spawnByName( cname, null, new Point( ent.px[0], ent.px[1] ) );
		if ( a == null ) return;

		// rudimentary entity fields parsing
		var afields = Type.getInstanceFields( Type.getClass( a ) );
		for ( f in ent.fieldInstances ) {
			if ( f.__value == null ) continue;
			if ( afields.contains( f.__identifier ) ) {
				// note: inline setters might not work here with DCE=full
				Reflect.setProperty( a, f.__identifier, f.__value );
			}
		}
	}

	// for resolveClass visibility...
	static var __classes: Array<Class<Actor>> = [
		Actor, Player, Enemy, Spawner
	];
}
