package actors;

class Projectile extends Actor {
	var still = false;

	public function new() {
		super();
		bumpActors = true;
		touchActors = true;
		friction = 0.92;
		radius = 4;
		lifeSpan = 10;
		bumpForce = 0.1;
		spr.tile = Res.rock.toTile();
		spr.tile.setCenterRatio();
	}

	override function onBeginPlay() {
		super.onBeginPlay();
	}

	override function onBump( other: Actor ) {
		super.onBump( other );
		if ( !still && isOfType( other, Enemy ) ) {
			other.life = 0;
			life =0;
		}
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();
		if ( velocity.lengthSq() < 0.002 ) {
			still = true;
			spr.colorAdd.r = 1;
		}
	}
}
