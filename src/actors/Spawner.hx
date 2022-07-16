package actors;

// automated actor spawner
class Spawner extends Actor {
	var className: String = null;
	var maxCount: Int = 1;
	var timeout: Float = 2.0;
	var _ct = 0.0;

	function new() {
		super();
		spr.tile = Res.skull.toTile();
		spr.tile.setCenterRatio();
	}

	function spawnActor() {
		var e = Actor.spawnByName( className, this );
		if ( e == null ) return;
		e.onBeginPlay();
		e.velocity.x+=0.001;
	}

	override function onUpdate() {
		_ct += game.tmod / G.FPS;
		if ( className == null ) destroy();
		if ( _ct >= timeout && ownees.length < maxCount ) {
			_ct = 0;
			spawnActor();
		}
	}
}
