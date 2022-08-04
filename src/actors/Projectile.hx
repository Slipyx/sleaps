package actors;

class Projectile extends Actor {
	var still = false;

	public function new() {
		super();
		touchActors = true;
		friction = 1.0;
		radius = 3;
		lifeSpan = 2;
		spr.tile = Res.proj.toTile();
		spr.tile.setCenterRatio();
	}

	override function onBeginPlay() {
		super.onBeginPlay();
	}

	override function onTouch( other: Actor ) {
		super.onTouch( other );
		if ( isOfType( other, Enemy ) ) {
			other.life = 0;
			life = 0;
		}
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();
	}

	override function onPreStepX() {
		super.onPreStepX();
		if ( level.getCollision( cellLocation.x, cellLocation.y ) != Col_None )
			life = 0;
	}
}
