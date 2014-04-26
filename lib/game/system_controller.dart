part of game;

var _keysForward = [ KeyCode.UP, KeyCode.W, KeyCode.Z ];
var _keysBackward = [ KeyCode.DOWN, KeyCode.S];
var _keysTurnLeft = [ KeyCode.LEFT, KeyCode.A, KeyCode.Q ];
var _keysTurnRight = [KeyCode.RIGHT, KeyCode.D];
var _keysCameraMode = [KeyCode.M];

class AvatarControl extends Component {
  static final CT = ComponentTypeManager.getTypeFor(AvatarControl);
  double forward = 0.0;
  double turn = 0.0;

  AvatarControl();
}

class AvatarNumbers extends Component {
  static final CT = ComponentTypeManager.getTypeFor(AvatarNumbers);
  int score = 0;
  AvatarNumbers();
}

class CameraFollower extends Component {
  static final CT = ComponentTypeManager.getTypeFor(CameraFollower);
  static const TOP = 0;
  static const TPS = 1;
  static const FPS = 2;
  glf.CameraInfo info;
  Aabb3 focusAabb;
  final Vector3 targetTranslation = new Vector3.zero();
  int _mode;
  get mode => _mode;
  set mode(int v) {
    switch(v) {
      case TOP :
        _mode = 0;
        targetTranslation.setValues(0.0, 0.0, 80.0);
        break;
      case TPS :
        _mode = 1;
        targetTranslation.setValues(-10.0, 0.0, 4.0);
        break;
      case FPS :
        _mode = 2;
        targetTranslation.setValues(-0.01, 0.0, 0.0);
        break;
    }
  }
}

class System_CameraFollower extends EntityProcessingSystem {
  ComponentMapper<CameraFollower> _followerMapper;
  ComponentMapper<Transform> _transformMapper;

  System_CameraFollower() : super(Aspect.getAspectForAllOf([CameraFollower, Transform]));

  void initialize(){
    _followerMapper = new ComponentMapper<CameraFollower>(CameraFollower, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
}

  bool checkProcessing() {
    return true;
  }

  void processEntities(Iterable<Entity> entities) => entities.forEach((entity) => processEntity(entity));

  void processEntity(Entity entity) {
    var follower = _followerMapper.get(entity);
    var transform = _transformMapper.get(entity);
    if (follower.info == null) return;
    var _targetPosition = transform.position3d;
    var camera = follower.info;
    if (follower.mode == CameraFollower.TOP) {
      var next = new Vector3.copy(_targetPosition).add(follower.targetTranslation);
      var position = camera.position;
      position.x = approachMulti(next.x, position.x, 0.2);
      position.y = approachMulti(next.y, position.y, 0.2);
      position.z = approachMulti(next.z, position.z, 0.3);
      camera.upDirection.setFrom(math2.VY_AXIS);
      camera.focusPosition.setFrom(_targetPosition);
    }
    //follower.info.updateProjectionMatrix();
    //camera.adjustNearFar(follower.focusAabb, 0.001, 0.1);
    camera.updateViewMatrix();
  }

  double approachAdd(double target, double current, double step) {
    var mstep = target - current;
    return current + math.min(step, mstep);
  }

  double approachMulti(double target, double current, double step) {
    var mstep = target - current;
    return current + step * mstep;
  }
}

class System_AvatarController extends EntityProcessingSystem {
  ComponentMapper<AvatarControl> _avatarControlMapper;
  AvatarControl _state;
  var _subUp, _subDown;

  System_AvatarController() : super(Aspect.getAspectForAllOf([AvatarControl]));

  void initialize(){
    _avatarControlMapper = new ComponentMapper<AvatarControl>(AvatarControl, world);
    _state = new AvatarControl();
    _bindKeyboardControl();
  }

  void processEntity(Entity entity) {
    var dest = _avatarControlMapper.get(entity);
    dest.forward = _state.forward;
    dest.turn = _state.turn;
  }

  void _bindKeyboardControl(){
   _subDown = document.onKeyDown.listen((KeyboardEvent e) {
      if (_keysForward.contains(e.keyCode)) _state.forward = 1.0;
      else if (_keysBackward.contains(e.keyCode)) _state.forward = -0.3;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 1.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = -1.0;
    });
    _subUp = document.onKeyUp.listen((KeyboardEvent e) {
      if (_keysForward.contains(e.keyCode)) _state.forward = 0.0;
      else if (_keysBackward.contains(e.keyCode)) _state.forward = 0.0;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 0.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = 0.0;
    });
  }
}

class System_AvatarHandler extends EntityProcessingSystem {
  ComponentMapper<AvatarControl> _avatarControlMapper;
  ComponentMapper<AvatarNumbers> _avatarNumbersMapper;
  ComponentMapper<EntityStateComponent> _statesMapper;
  Game _game;
  var _printDebug = false;

  System_AvatarHandler(this._game) : super(Aspect.getAspectForAllOf([AvatarControl, AvatarNumbers, EntityStateComponent]));

  void initialize(){
    _avatarControlMapper = new ComponentMapper<AvatarControl>(AvatarControl, world);
    _avatarNumbersMapper = new ComponentMapper<AvatarNumbers>(AvatarNumbers, world);
    _statesMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
  }

  void processEntity(Entity entity) {
    var esc = _statesMapper.getSafe(entity);
    var numbers = _avatarNumbersMapper.get(entity);
//    collisions.colliders.iterateAndUpdate((collider){
//      return null;
//    });
  }
}
