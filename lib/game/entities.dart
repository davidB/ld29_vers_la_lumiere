part of game;

const GROUP_AVATAR = "GROUP_AVATAR";
const GROUP_EXITZONE = "GROUP_EXITZONE";
const GROUP_BARRIER = "GROUP_BARRIER";

class Factory_Entities {
  static final _random = new math.Random();

  final Factory_Renderables renderFact;
  final World _world;
  final AssetManager _assetManager;

  Factory_Entities(
    this._world,
    this._assetManager,
    this.renderFact
  );

  List<Entity> newFullArea(AssetPack assetpack) {
     var gm = (_world.getManager(GroupManager) as GroupManager);
     renderFact.reset();
     var es = new List<Entity>();
     var cameraInfo = newCameraInfo(new Aabb3.minMax(new Vector3(-2.0, -5.0, -2.0), new Vector3(2.0, 102.0, 2.0)));
//     es.add(newCamera("${assetpack.name}.music", new Aabb3.minMax(new Vector3(-1.1, -5.1, -1.1), new Vextor(1.1, 101.1, 1.1))));
     es.add(newCamera(cameraInfo));
//     es.add(newArea(assetpack.name));
//     es.add(newChronometer(areadef.chronometer, timeout));
//     es.add(newGateIns(areadef.gateIns, assetpack));
//     es.add(newGateOuts(areadef.gateOuts, assetpack));
//     es.add(newFloor());
//     es.addAll(areadef.staticWalls.map((x) => newStaticWalls(x, assetpack)));
//     es.addAll(areadef.mobileWalls.map((x) => newMobileWall(x, assetpack)));
//     es.addAll(areadef.cubeGenerators.map((x) => newCube(x)));

     var avatar = newAvatar(cameraInfo);
     es.add(avatar);
     gm.add(avatar, GROUP_AVATAR);

     es.add(newCorridor());

     var exitZone = newExitZone();
     es.add(exitZone);
     gm.add(exitZone, GROUP_EXITZONE);

     var barriers = assetpack['barriers'];
     var cycleMax = math.min(10, barriers.length);
     for(var cyclePos = 0; cyclePos < cycleMax; cyclePos++) {
       var b = newBarrier(barriers, cyclePos, cycleMax);
       es.add(b);
       gm.add(b, GROUP_BARRIER);
     }
     return es;
   }

  glf.CameraInfo newCameraInfo(sceneAabb) {
    var camera = new glf.CameraInfo()
    ..fovRadians = degrees2radians * 45.0
    ..near = 1.0
    ..far = 100.0
//      ..left = vp.x.toDouble()
//      ..right = vp.x.toDouble() + vp.viewWidth.toDouble()
//      ..top = vp.y.toDouble()
//      ..bottom = vp.y.toDouble() + vp.viewHeight.toDouble()
    ..isOrthographic = false
//      ..aspectRatio = vp.viewWidth.toDouble() / vp.viewHeight.toDouble()
    ..position.setValues(0.0, 0.0, 1.0)
    ..focusPosition.setValues(0.0, 50.0, 0.0)
    ..adjustNearFar(sceneAabb, 0.1, 0.1)
//      ..updateProjectionMatrix()
    ;
    return camera;
  }

  Entity newCamera(cameraInfo) => _world.createEntity([
    renderFact.newCamera(cameraInfo)
    //,new AudioDef()..add(music)..isAudioListener = true
  ]);

  Entity newAvatar(cameraInfo) => _world.createEntity([
    new AvatarControl()
    , new AvatarNumbers()
    , new Transform.w3d(new Vector3(0.0,0.0,0.0))
    , new CameraFollower()
    ..mode = CameraFollower.FPS
    ..info = cameraInfo
  ]);

  Entity newCorridor() => _world.createEntity([
    renderFact.newCorridor(500.0)
  ]);

  Entity newExitZone(){
    var t = new Transform.w3d(new Vector3(0.0, 100.0, 0.0));
    return _world.createEntity([
      t
      ,renderFact.newExitZone(t.position3d)
    ]);
  }

  Entity newBarrier(barriers, cyclePos, cycleMax){
    var t = new Transform.w3d(new Vector3(0.0, -100.0, 0.0));
    var b = new Barrier()
    ..barriers = barriers
    ..cyclePos = cyclePos
    ..cycleMax = cycleMax
    ..kind =  Barrier.K_UNDEF
    ;
    return _world.createEntity([
      t
      ,b
      ,renderFact.newBarrier(t.position3d, b.dim)
    ]);
  }
}

class Factory_Renderables {

  var _uCnt = 0;

  reset() {
    print("[DEBUG] reset");
    _uCnt = 0;
  }

  _vec3(Vector3 v) => "vec3(${v.x}, ${v.y}, ${v.z})";
  _vec4(Vector4 v) => "vec4(${v.x}, ${v.y}, ${v.z}, ${v.w})";

  _defaultShadeMats(l) {
    r.n_de(l);
    r.normalToColor(l);
    r.aoToColor(l);
    r.distToColor(l);
    _myshade(l);
  }
  _myshade(l) {
 //   r.softshadow(l);
    l.add('''
#define HIGH
  // see http://www.altdevblogaday.com/2011/08/23/shader-code-for-physically-based-lighting/
  const vec3 light_colour = vec3(1.0, 1.0, 1.0);
  const float specular_power = 1.0;
  const float specular_colour = 0.5;
  const float PI_OVER_FOUR = PI / 4.0;
  const float PI_OVER_TWO = PI / 2.0;

float myao(in vec3 p, in vec3 n, float sca0){
  float totao = 0.0;
  float sca = sca0;
  for (int aoi=0; aoi<5; aoi++ ) {
    float hr = 0.01 + 0.02*float(aoi);
    vec3 aopos =  n * hr + p;
    float dd = de( aopos ).x;
    totao += -(dd-hr)*sca;
    sca *= 0.75;
  }
  return clamp(1.0- 4.0*totao, 0.0, 1.0 );
}
  color myshade(color c, vec3 p, vec3 n, float t, vec3 rd) {
    vec3 light_direction = normalize( -rd );
    float n_dot_l = clamp( dot( n, light_direction ), 0.0, 1.0 ); 
    //vec3 diffuse = light_colour * n_dot_l;
    float diffuse = n_dot_l;
    //float diffuse = 1.0;
    //diffuse =  mix ( diffuse, 0, somethingAboutSpecularLobeLuminance );

    vec3 hv = normalize(light_direction - rd);
    float n_dot_h = clamp( dot( n, hv ), 0.0, 1.0 );
    //float normalisation_term = ( specular_power + 2.0 ) / 2.0 * PI;
    float normalisation_term = ( specular_power + 2.0 ) / 8.0;
    float blinn_phong = pow( n_dot_h, specular_power );
    float specular_term = normalisation_term * blinn_phong;
    float cosine_term = n_dot_l;
    //vec3 specular = (PI / 4.0f) * specular_term * cosine_term * fresnel_term * visibility_term * light_colour;
    float specularCoeff = specular_term * cosine_term;
#if defined(MID) || defined(HIGH) 
    float h_dot_l = dot(hv, light_direction); // Dot product of half vector and light vector. No need to saturate as it can't go above 90 degrees
    float base = 1.0 - h_dot_l;    
    float exponential = pow( base, 5.0 );
    float fresnel_term = specular_colour + ( 1.0 - specular_colour ) * exponential;
    specularCoeff = specularCoeff * fresnel_term;
#endif
#ifdef HIGH
    float n_dot_v = dot(n, -rd);
    float alpha = 1.0 / ( sqrt( PI_OVER_FOUR * specular_power + PI_OVER_TWO ) );
    float visibility_term = ( n_dot_l * ( 1.0 - alpha ) + alpha ) * ( n_dot_v * ( 1.0 - alpha ) + alpha ); // Both dot products should be saturated
    visibility_term = 1.0 / visibility_term;
    specularCoeff = specularCoeff * visibility_term;
#endif
    vec3 albedo = c.rgb;
    float sh = myao(p, n, 1.0);
    diffuse = diffuse * 3.0 / max(t, 3.0);
    //diffuse = clamp(diffuse, ambient, 1.0);
    // no shadow as r0 is the light source (spot)
    c.rgb = albedo * diffuse * sh ;//+ light_colour * specularCoeff;
    //c.rgb = vec3(sh);
    return c;
//
//    float ao = ao_de(p, n);
//
//    float amb = clamp( 0.5+0.5*n.z, 0.0, 1.0 );
//    float dif = clamp( dot( n, lig ), 0.0, 1.0 );
//    float bac = clamp( dot( n, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-p.y,0.0,1.0);
//
//    float sh = 1.0;
//    if( dif>0.02 ) { sh = softshadow( p, lig, 0.02, 10.0, 7.0 ); dif *= sh; }
//
//    vec3 brdf = vec3(0.0);
//    brdf += 0.20*amb*vec3(0.10,0.11,0.13)*ao;
//    brdf += 0.20*bac*vec3(0.15,0.15,0.15)*ao;
//    brdf += 1.20*dif*vec3(1.00,0.90,0.70);
//
//    float pp = clamp(dot(reflect(rd, n), lig), 0.0, 1.0 );
//    float spe = sh*pow(pp, 16.0);
//    float fre = ao*pow(clamp(1.0+dot(n, rd),0.0,1.0), 2.0 );
//
//    vec3 col = c.rgb;
//    col = col*brdf + col * vec3(1.0)*spe + 0.2*fre*(0.5+0.5*col);
//    col *= exp( -0.01*t*t );
//    c.rgb = col;
//    return c;
  }
    ''');
  }
  _defaultShade({String c : "normalToColor(n)", String n : "n_de(o, p)"}) {
    return """
        vec3 p2 = p + o.x * rd;
        float t2 = t + o.x;
        vec3 n = n_de(o, p2);
        vec3 nf = faceforward(n, rd, n);
        return myshade($c, p2, nf, t2, rd);
        //return vec4(vec3(1.0) - aoToColor(p, nf).rgb, 1.0);
        //return vec4(aoToColor(p, nf).rgb, 1.0);
//        return normalToColor(nf);
        //return $c * ao_de(p, nf);
//return $c;
//        return vec4( vec3(1.0) - distToColor(t2, ${glf.SFNAME_NEAR}, ${glf.SFNAME_FAR}).rgb, 1.0); ;
//        return distToColor(t2, ${glf.SFNAME_NEAR}, ${glf.SFNAME_FAR});
        """;
  }

  RenderableDef newCamera(camera){
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      return new Renderable()
      ..camera = camera
      ;
    };
  }

  RenderableDef newCorridor(length) {
    /// glsl: float sd_corridor(in vec3 p)
    sd_corridor() {
    return (l) => l.add('''
    float sd_corridor(in vec3 p) {
    float z = abs(p.z) - 1.5;/* + mod(0.2 * (ceil(p.y / 0.8) + 1.0), 0.72)), ;*/
    float x = abs(p.x) - 1.6;
    return max(x, z); 
    }
    ''');
    }

    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      return new Renderable()
      ..obj = (new r.ObjectInfo()
//        ..uniforms = 'uniform vec3 scroll;'
        ..de = "sd_corridor(p)"
        ..sds = [sd_corridor()]
        ..mats = [r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0)), _defaultShadeMats]
        //..sh = _defaultShade(c: "mat_chessboardXY0(p)")
        ..sh = _defaultShade(c: "vec4(0.3,0.3,0.3,1.0)")
//        ..at = (ctx) {
//          ctx.gl.uniform3fv(ctx.getUniformLocation("scroll"), scroll.storage);
//        }
      )
      ;
    }
    ;
  }

  RenderableDef newExitZone(Vector3 position) {
          // TODO optimize to reduce number of copy (position3d => Float32List => buffer)
          //updateVertices();
          //_mdt.extrudeInto(vertices, extrusion, geometry.meshDef);
          //geometry.verticesNeedUpdate = true;
//          var vp0 = ps.position3d[1];
//          var vm = geometry.meshDef.vertices;
//          geometry..transforms.setTranslationRaw(vp0.x - vm[0], vp0.y - vm[1], vp0.z - vm[2]);
    var utx = "p${_uCnt++}";
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var transform = new Matrix4.identity();
      var obj = new r.ObjectInfo()
        ..uniforms = 'uniform vec3 ${utx};'
        ..de = "sd_box(p - ${utx}, vec3(1.4, 1.5, 1.4))"
        ..sds = [r.sd_box]
        ..mats = [_defaultShadeMats]
        //..sh = _defaultShade(c : _vec4(new Vector4(1.0,1.0,1.0,1.0)))
        ..sh = "return vec4(1.0,1.0,1.0,1.0);"
        ..at = (ctx) {
          ctx.gl.uniform3fv(ctx.getUniformLocation(utx), position.storage);
        }
      ;
      return new Renderable()..obj = obj;
    }
    ;
  }
  RenderableDef newBarrier(Vector3 position, Vector3 dim) {
    var utx = "p${_uCnt++}";
    var udim = "d${_uCnt++}";
    twist(l) => l.add("""vec3 opTwist( vec3 p )
    {
        float c = cos(20.0*p.y);
        float s = sin(20.0*p.y);
        mat2  m = mat2(c,-s,s,c);
        vec3  q = vec3(m*p.xz,p.y);
        return q;
    }""");
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var transform = new Matrix4.identity();
      var obj = new r.ObjectInfo()
        ..uniforms = 'uniform vec3 ${utx}; uniform vec3 ${udim};'
        ..de = "sd_box(p - ${utx}, ${udim})"
        ..sds = [r.sd_box, twist]
        ..mats = [_defaultShadeMats]
        ..sh = _defaultShade(c : "vec4(.5,.5,.5,1.0)")
        ..at = (ctx) {
          ctx.gl.uniform3fv(ctx.getUniformLocation(utx), position.storage);
          ctx.gl.uniform3fv(ctx.getUniformLocation(udim), dim.storage);
        }
      ;
      return new Renderable()..obj = obj;
    }
    ;
  }

/*
  RenderableDef newMobileWall(Iterable<Polygone> shapes, num dz, Vector4 color) {
    var utx = 'utx${_uCnt++}';
          // TODO optimize to reduce number of copy (position3d => Float32List => buffer)
          //updateVertices();
          //_mdt.extrudeInto(vertices, extrusion, geometry.meshDef);
          //geometry.verticesNeedUpdate = true;
//          var vp0 = ps.position3d[1];
//          var vm = geometry.meshDef.vertices;
//          geometry..transforms.setTranslationRaw(vp0.x - vm[0], vp0.y - vm[1], vp0.z - vm[2]);
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var transform = new Matrix4.identity();
      var obj = new r.ObjectInfo()
        ..uniforms = 'uniform mat4 ${utx};'
        ..de = "sd_box(opTx(p, ${utx}), vec3(1.0, 3.0, $dz))"
        ..mats = [_defaultShadeMats]
        ..sh = _defaultShade(c : _vec4(color))
        ..at = (ctx) {
            glf.injectMatrix4(ctx, transform, utx);
            transform.setIdentity();
            //transform.setTranslation(-ps.position3d[0]);
            //print("$shapes, $dz');
        }
      ;
      return new Renderable()..obj = obj;
    }
    ;
  }
*/
}