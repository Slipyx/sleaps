// crt shader for s2d filter.
// uses code from deepnight's dnlib Crt filter

package;

class CrtShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture: Sampler2D;
		@param var size: Vec2;
		@param var scale: Int;

		var sz: Vec2;
		var ps: Vec2;

		function curve( uv: Vec2 ): Vec2 {
			var out = uv * 2 - 1;
			var amt = 0.5;
			var offs = abs( out.yx ) / vec2(2+(1.0-amt)*10);
			out = out + out * offs * offs;
			out = out * 0.5 + 0.5;
			return out;
		}

		function vignet( uv: Vec2 ): Float {
			var off = max( abs( uv.y * 2 - 1 ) / 4, abs( uv.x * 2 - 1 ) / 4 );
			return 300 * off * off * off * off * off;
		}

		function vertex() {
			sz = size / scale;
			//var tsz = vec2( sz.x * 1.0, sz.y );
			ps = 1.0 / sz;
			calculatedUV = input.uv;// + ps * vec2( -0.49, 0 );
			output.position = vec4( input.position.x, input.position.y * flipY, 0, 1 );
		}

		function fragment() {
			// curve
			var uv = curve( calculatedUV );
			pixelColor = texture.get( uv );
			// vignet
			pixelColor.rgb *= 1 - 0.5 * vignet( calculatedUV );
			// clip out of curve pixels
			pixelColor.rgba *= step( 0, uv.x ) * step( uv.x, 1 ) *
				step( 0, uv.y ) * step( uv.y, 1 );
		}

		// an atempt at porting the crt-hyllian-fast libretro shader
		/*function crt_hyllian_fast() {
			var dx = vec2( ps.x, 0.0 );
			var dy = vec2( 0.0, ps.y );
			var tc = (floor( calculatedUV * (sz) ) + vec2( 0.5, 0.5 )) / (sz);
			var fp = fract( calculatedUV * (sz) );
			var c10 = texture.get( curve(tc - dx) ).rgb;
			var c11 = texture.get( curve(tc) ).rgb;
			var c12 = texture.get( curve(tc + dx) ).rgb;
			var c13 = texture.get( curve(tc + 2.0 * dx) ).rgb;

			var lobes = vec4( fp.x * fp.x * fp.x, fp.x * fp.x, fp.x, 1.0 );
			var invX = vec4( 0.0 );
			invX.x = dot( vec4( -0.5, 1.0, -0.5, 0.0 ), lobes );
			invX.y = dot( vec4( 1.5, -2.5, 0.0, 1.0 ), lobes );
			invX.z = dot( vec4( -1.5, 2.0, 0.5, 0.0 ), lobes );
			invX.w = dot( vec4( 0.5, -0.5, 0.0, 0.0 ), lobes );

			var color = invX.x * c10.rgb;
			color += invX.y * c11.rgb;
			color += invX.z * c12.rgb;
			color += invX.w * c13.rgb;
			color = pow( color, vec3( 2.4 ) ); // gamma in

			var pos1 = 1.5 - 0.72 - abs( fp.y - 0.5 );
			var d1 = max( 0.0, min( 1.0, pos1 ) );
			var d = d1 * d1 * (3.0 + 1.5 - (2.0 * d1));
			color = color * d;

			// var modf = calculatedUV.x * (size.x) * (sz.x) / (sz.x);
			// var dmw = mix( vec4( 1.0, 1.0-0.5, 1.0, 1.0 ),
			// 	vec4( 1.0 - 0.5, 1.0, 1.0-0.5, 1.0 ),
			// 	floor( mod( modf, 2.0 ) ) );
			// color *= dmw.rgb;

			color = pow( color, vec3( 1.0 / 2.2 ) ); // gamma out
			pixelColor = vec4( color, 1 );
		}*/
	}
}
