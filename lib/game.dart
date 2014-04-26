library game;

import 'dart:async';
import 'dart:math' as math;
import 'dart:html';
import 'dart:web_gl' as webgl;
import 'package:dartemis/dartemis.dart';
import 'package:dartemis_toolbox/system_entity_state.dart';
import 'package:dartemis_toolbox/system_animator.dart';
import 'package:dartemis_toolbox/system_transform.dart';
import 'package:dartemis_toolbox/utils_math.dart' as math2;
import 'package:dartemis_toolbox/progress_controler.dart' as pc;
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:simple_audio/simple_audio_asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_asset_pack.dart';
import 'package:glf/glf_rendererr.dart' as r;
import 'package:game_loop/game_loop_html.dart';

import 'events.dart';

part 'game/entities.dart';
part 'game/system_controller.dart';
part 'game/system_hud.dart';
part 'game/system_renderer.dart';

class Game {
  Element el;
  var audioManager;
  var bus;
  var areaReq = 'l0';

  World _world;
  GameLoopHtml _gameLoop;
  webgl.RenderingContext _gl;
  pc.ProgressControler _progressCtrl;
  AssetManager _assetManager;
//  glf.TextureUnitCache _textures;
  var _status;
  Factory_Entities _entitiesFactory;
  var _renderSystem;
  var _hudSystem;

  init() {
    _world = new World();
    _gameLoop = new GameLoopHtml(el);

    _gl = _newRenderingContext(el.querySelectorAll("canvas")[0]);
    if (_gl == null) {
      _handleError("Failed to acquire 3D RenderingContext", null);
      return;
    }

    _progressCtrl = new pc.ProgressControler(querySelector('#gameload'));
    _assetManager = _newAssetManager(_progressCtrl, _gl, audioManager);
    _preloadAssets();

//    _textures = new glf.TextureUnitCache(_gl);
    _entitiesFactory = new Factory_Entities(_world, _assetManager, new Factory_Renderables());
    _setupWorld(el);
    _setupGameLoop(el);

    el.tabIndex = -1;
    el.focus();
    bus.on(eventInGameReqAction).listen(onReqAction);
  }

  onReqAction(int req){
    switch(req) {
      case IGAction.INITIALIZE:
        _initialize();
        break;
      case IGAction.PLAY:
        _play();
        break;
      case IGAction.PAUSE:
        _pause();
        break;
      case IGAction.STOP:
        _stop(false, 0);
        break;
    }
  }

  get status => _status;
  void _updateStatus(int v) {
    _status = v;
    bus.fire(eventInGameStatus, new IGStatus()
    ..kind = v
    );
    print("status :" + _status.toString());
  }

  bool _play() {
    try {
    if  (!(_status == IGStatus.INITIALIZED || _status == IGStatus.STOPPING)){
//      print("DEBUG: NOT playable : ${_status}");
      return false;
    }
    if (_status != IGStatus.INITIALIZED) {
      _initialize().then((_) => _start());
      return true;
    } else {
      _start();
      return true;
    }
    } on Object catch(e, st) {
      _handleError(e, st);
    }
  }

  //_now() => new Int64(new DateTime.now().toUtc().millisecondsSinceEpoch);

  void _start() {
    _updateStatus(IGStatus.PLAYING);
    _resume();
  }

  void _stop(bool viaExit, int cubesGrabbed) {
    if (_status == IGStatus.PLAYING) {
      _updateStatus(IGStatus.STOPPING);
      _gameLoop.stop();
    }

    bus.fire(eventRunResult, new RunResult()
    ..score = 0
    );
    _initialize();
  }

  Future _initialize() {
    if (_status == IGStatus.INITIALIZING) {
      return new Future.error("already initializing an area");
    }
    _progressCtrl.start(3);
    _updateStatus(IGStatus.INITIALIZING);
    _world.deleteAllEntities();
    //_newWorld();

    return _loadArea(areaReq).then((pack){
      var es = _entitiesFactory.newFullArea(pack);
      es.forEach((e) => e.addToWorld());
      _world.processEntityChanges();
      _renderSystem.reset();
      _hudSystem.reset();
      _progressCtrl.end(3);
      _updateStatus(IGStatus.INITIALIZED);
      return true;
    });
  }

  Future _loadPack(String v) {
    return (_assetManager[v] == null) ?
        _assetManager.loadPack(v, '_packs/${v}/_.pack')
        : new Future.value(_assetManager[v]);
  }

  Future _loadArea(String areaId) {
    return Future.wait([
      _loadPack(areaId),
      _loadPack('0')
    ]).then((l) => l[0]);
  }

  void _setupWorld(Element container) {
    _renderSystem = new System_Render(_gl, _assetManager);
    _hudSystem = new System_Hud(container);

    //var collSpace = new collisions.Space_QuadtreeXY(new collisions.Checker_MvtAsPoly4(), new _EntityContactListener(new ComponentMapper<Collisions>(Collisions,_world)), grid : new collisions.QuadTreeXYAabb(-10.0, -10.0, 220.0, 220.0, 5));
    //_world.addManager(new PlayerManager());
    //_world.addManager(new GroupManager());
    _world.addSystem(new System_EntityState());
    _world.addSystem(new System_Animator());

    // Audio + Video display
    _world.addSystem(new System_CameraFollower());
    _world.addSystem(new System_AvatarController());
    _world.addSystem(new System_AvatarHandler());
    _world.addSystem(_renderSystem, passive: true);
    //if (audioManager != null) _world.addSystem(new System_Audio(audioManager, clipProvider : (x) => _assetManager[x], handleError: _handleError), passive : false);
    _world.addSystem(_hudSystem, passive: true);
    _world.initialize();
  }

  _handleError(e, st) {
    bus.fire(eventErr, new Err()
    ..category = "ingame"
    ..exc = e
    ..stacktrace = st
    );
  }

  // TODO add notification of errors
  static AssetManager _newAssetManager(pc.ProgressControler progressCtrl, gl, audioManager) {
    var tracer = new AssetPackTrace();
    var stream = tracer.asStream().asBroadcastStream();
    progressCtrl.bind(stream);
    //new EventsPrintControler().bind(stream);

    var b = new AssetManager(tracer);
    b.loaders['img'] = new ImageLoader();
    b.importers['img'] = new NoopImporter();

    if (gl != null) registerGlfWithAssetManager(gl, b);
    if (audioManager != null) registerSimpleAudioWithAssetManager(audioManager, b);
    return b;
  }

  webgl.RenderingContext _newRenderingContext(CanvasElement canvas) {
    return canvas.getContext3d(alpha: false, depth: true, antialias:false);
  }

  void _preloadAssets() {
    //_assetManager.loadAndRegisterAsset('explosion', 'audioclip', 'sfxr:3,,0.2847,0.7976,0.88,0.0197,,0.1616,,,,,,,,0.5151,,,1,,,,,0.72', null, null);
  }

  _setupGameLoop(element){
    _gameLoop.pointerLock.lockOnClick = false;
    _gameLoop.onVisibilityChange = (gameLoop){
      if (!gameLoop.isVisible) _pause();
    };
    _gameLoop.onUpdate = (gameLoop){
      try {
        _world.delta = gameLoop.dt * 1000.0;
        _world.process();
      } catch(e, s) {
        _handleError(e, s);
      }
    };
    _gameLoop.onRender = (gameLoop){
      try {
        _renderSystem.process();
        _hudSystem.process();
      } catch(e, s) {
        _handleError(e, s);
      }
    };
    return _gameLoop;
  }

  _pause() {
    audioManager.pauseAll();
    _gameLoop.stop();

    var pauseOverlay = querySelector("#pauseOverlay");
    if (pauseOverlay != null) {
      pauseOverlay.style.visibility = "visible";
      pauseOverlay.onClick.first.then((_){
        _resume();
      });
    }
  }

  _resume() {
    var pauseOverlay = querySelector("#pauseOverlay");
    if (pauseOverlay != null) {
      pauseOverlay.style.visibility = "hidden";
    }
    _gameLoop.start();
    audioManager.resumeAll();
  }
}
