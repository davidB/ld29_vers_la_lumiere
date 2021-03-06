part of game;

typedef Renderable RenderableF(webgl.RenderingContext gl, Entity e);

class Renderable {
  glf.CameraInfo camera;
  r.ObjectInfo obj;
  List<glf.Filter2D> filters;
  Map ext = {};
}

class RenderableDef extends Component {
  static final CT = ComponentTypeManager.getTypeFor(RenderableDef);

  RenderableF onInsert;

  RenderableDef();
}

class RenderableCache extends Component {
  static final CT = ComponentTypeManager.getTypeFor(RenderableCache);

  Renderable v;

  RenderableCache(this.v);
}

class System_Render extends EntitySystem {
  ComponentMapper<RenderableDef> _objDefMapper;
  ComponentMapper<RenderableCache> _objCacheMapper;
  GroupManager _groupManager;

  final r.RendererR _renderer;
  final AssetManager _am;
  int stepmax;
  Future<AssetManager> _assets;

  factory System_Render(webgl.RenderingContext gl, AssetManager am)  {
    //TODO better feedback
    if (gl == null) {
      throw new Exception("webgl not supported");
    }
    return new System_Render._(gl, am);
  }

  System_Render._(gl, this._am) :
    super(Aspect.getAspectForAllOf([RenderableDef])),
    _renderer = new r.RendererR(gl)
  ;

  void initialize(){
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
    _assets = _loadAssets();
  }

  bool checkProcessing() => _renderer.camera != null;

  void reset() {
    _renderer.debugPrintFragShader = false;
    //_renderer.nearLight = r.nearLight_SpotGrid(10.0);
    //_renderer.lightSegment = r.lightSegment_spotAt(new Vector3(50.0, 50.0, 50.0));
    _renderer.stepmax = stepmax;
    //_renderer.epsilon_de = 0.001;
    _renderer.bgcolor = "return vec3(0.0,0.0,0.0);";
    _renderer.shadeAll = """
//        vec3 p2 = p + o.x * rd;
//        float t2 = t + o.x;
//        n = n_de(o, p2);
//        nf = faceforward(n, rd, n);
        col = myshade(col, p, nf, t, rd);
        //return vec4(vec3(1.0) - aoToColor(p, nf).rgb, 1.0);
        //return vec4(aoToColor(p, nf).rgb, 1.0);
//        return normalToColor(nf);
        //return col * ao_de(p, nf);
//return col;
//        return vec4( vec3(1.0) - distToColor(t2, ${glf.SFNAME_NEAR}, ${glf.SFNAME_FAR}).rgb, 1.0); ;
//        return distToColor(t2, ${glf.SFNAME_NEAR}, ${glf.SFNAME_FAR});
        """;
    _renderer.updateShader();
  }

  void processEntities(Iterable<Entity> entities) {
    _renderer.run();
    //call gl.finish() doesn't prevente frame "tearing" (when you rotate vdrones)
    //see http://www.opengl.org/wiki/Swap_Interval
    //_renderer.gl.finish();
  }

  void inserted(Entity entity){
    var objDef = _objDefMapper.get(entity);
    if (objDef != null) {
      var v = objDef.onInsert(_renderer.gl, entity);
      var cache = new RenderableCache(v);
      if (v != null) {
        entity.addComponent(cache);
        entity.changedInWorld();
        if (v.camera != null) _renderer.camera = v.camera;
        if (v.obj != null) _renderer.register(v.obj);
        if (v.filters != null) _renderer.filters2d.addAll(v.filters);
      }
    }
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      var v = cache.v;
      if (v != null) {
        //TODO if (v.viewportCamera != null) _renderer.cameraViewport = v.viewportCamera;
        if (v.camera != null) _renderer.camera = null;
        if( v.obj != null ) _renderer.unregister(v.obj);
        if( v.filters != null ) v.filters.forEach((e) => _renderer.filters2d.remove(e));
      }
      cache.v = null;
      entity.removeComponentByType(RenderableCache.CT);
    }
  }

  Future<AssetManager> _loadAssets() {
    var factory_filter2d = new Factory_Filter2D()
    ..am = _am
    ;
    var bctrl = new BrightnessCtrl()
    ..brightness = 0.1
    ..contrast = 0.3
    ;
    return factory_filter2d.init().then((_){
      //_renderer.filters2d.add(factory_filter2d.makeFXAA());
      //_renderer.filters2d.add(factory_filter2d.makeConvolution3(Factory_Filter2D.c3_gaussianBlur3));
      _renderer.filters2d.add(factory_filter2d.makeHBlur(1.0));
      _renderer.filters2d.add(factory_filter2d.makeVBlur(0.5));
      _renderer.filters2d.add(factory_filter2d.makeBrightness(bctrl));
    }).then((l) => _am);
  }
}

