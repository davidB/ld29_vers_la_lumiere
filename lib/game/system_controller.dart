part of game;

var _keysUp = [ KeyCode.UP, KeyCode.W, KeyCode.Z, KeyCode.SPACE ];
var _keysDown = [ KeyCode.DOWN, KeyCode.S];
var _keysLeft = [ KeyCode.LEFT, KeyCode.A, KeyCode.Q ];
var _keysRight = [KeyCode.RIGHT, KeyCode.D];

class AvatarControl extends Component {
  static final CT = ComponentTypeManager.getTypeFor(AvatarControl);
  static const SPEED0 = 0.006; // unit/ms
  static const SPEEDJUMP = 0.006 * 0.8; // unit/ms
  static const SPEEDDASH = 0.006 * 0.3; // unit/ms
  double z = 0.0;
  double x = 0.0;
  double speed = SPEED0;
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
  final Vector3 focusTranslation = new Vector3.zero();
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
        focusTranslation.setValues(0.0, 5.0, -1.0);
        break;
    }
  }
}

class Barrier extends Component {
  static const K_UNDEF = 0;
  static const K_H0 = 1 + 2 + 4;
  static const K_H1 = 8 + 16 + 32;
  static const K_H2 = 64 + 128 + 256;
  static const K_V0 = 1 + 8 + 64;
  static const K_V1 = 2 + 16 + 128;
  static const K_V2 = 4 + 32 + 256;
  int kind = K_UNDEF;
  int cycleMax = 1;
  int cyclePos = 0;
  List barriers;
  final Vector3 dim = new Vector3(0.5, 0.5, 0.5);
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
    if (follower.mode == CameraFollower.FPS) {
      var next = new Vector3.copy(_targetPosition).add(follower.targetTranslation);
      var position = camera.position;
      position.x = approachMulti(next.x, position.x, 0.2);
      position.y = approachMulti(next.y, position.y, 0.2);
      position.z = approachMulti(next.z, position.z, 0.3);
      camera.upDirection.setFrom(math2.VZ_AXIS);
      camera.focusPosition.setFrom(_targetPosition).add(follower.focusTranslation);
      camera.focusPosition.z = math.max(0.0, camera.focusPosition.z);
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
  var _jumpEnd = 0.0, _dashEnd = 0.0;
  final _jumpDuration = 4.0 / AvatarControl.SPEEDJUMP;
  final _dashDuration = 3.5 / AvatarControl.SPEEDDASH;
  final _dashF = ease.outCubic;
  final _jumpF = ease.goback(ease.inQuartic);
  var time = 0.0;

  System_AvatarController() : super(Aspect.getAspectForAllOf([AvatarControl]));

  void initialize(){
    _avatarControlMapper = new ComponentMapper<AvatarControl>(AvatarControl, world);
    _state = new AvatarControl();
    _bindKeyboardControl();
  }

  void processEntity(Entity entity) {
    time = world.time;
    var dest = _avatarControlMapper.get(entity);
    if (dest == null) return;
    dest.x = _state.x;
    _state.x = 0.0;
    var jumpR = _jumpF(math.max(0.0, _jumpEnd - time) / _jumpDuration, 1.0, 0.0);
    var dashR = _dashF(math.max(0.0, _dashEnd - time) / _dashDuration, 1.0, 0.0);
    dest.z = jumpR - dashR;
    dest.speed = (dest.z >= 0.3)? AvatarControl.SPEEDJUMP
      : (dest.z <= -0.3) ? AvatarControl.SPEEDDASH
      : AvatarControl.SPEED0
      ;
  }

  void _bindKeyboardControl(){
    _subDown = document.onKeyDown.listen((KeyboardEvent e) {
      var isJumpingOrDashing =  (_jumpEnd - (0.1 * _jumpDuration) > time || _dashEnd - (0.1 * _dashDuration)> time);
      if (!isJumpingOrDashing) {
        if (_keysUp.contains(e.keyCode)) {
          _jumpEnd = time + _jumpDuration;
        }
        else if (_keysDown.contains(e.keyCode)){
          _dashEnd = time + _dashDuration;
        }
        else if (_keysLeft.contains(e.keyCode)) _state.x = -1.0;
        else if (_keysRight.contains(e.keyCode)) _state.x = 1.0;
      }
    });
//    _subUp = document.onKeyUp.listen((KeyboardEvent e) {
//      if (_keysUp.contains(e.keyCode)) _state.z = 0.0;
//      else if (_keysDown.contains(e.keyCode)) _state.z = 0.0;
//      else if (_keysLeft.contains(e.keyCode)) _state.x = 0.0;
//      else if (_keysRight.contains(e.keyCode)) _state.x = 0.0;
//    });
  }
}

class System_AvatarHandler extends EntityProcessingSystem {
  ComponentMapper<AvatarControl> _avatarControlMapper;
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<AvatarNumbers> _avatarNumbersMapper;
  ComponentMapper<Barrier> _barrierMapper;
  Game _game;
  GroupManager _gm;

  System_AvatarHandler(this._game) : super(Aspect.getAspectForAllOf([AvatarNumbers, Transform]));

  void initialize(){
    _avatarControlMapper = new ComponentMapper<AvatarControl>(AvatarControl, world);
    _avatarNumbersMapper = new ComponentMapper<AvatarNumbers>(AvatarNumbers, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _barrierMapper = new ComponentMapper<Barrier>(Barrier, world);
    _gm = world.getManager(GroupManager) as GroupManager;
  }

  void processEntity(Entity entity) {
    //var esc = _statesMapper.getSafe(entity);
    //var numbers = _avatarNumbersMapper.get(entity);
    var transform = _transformMapper.get(entity);
    var p = transform.position3d;
    var ctrl = _avatarControlMapper.get(entity);
    if (ctrl != null) {
      p.x = math2.clamp(p.x + ctrl.x, 1.0, -1.0);
      p.z = math2.clamp(ctrl.z, 1.0, -1.0);
      p.y += ctrl.speed * world.delta;
      //TODO test if exitpoint
      var exiting = _gm.getEntities(GROUP_EXITZONE).fold(false, (acc, e2){
        var t2 = _transformMapper.get(e2);
        return (t2 != null && p.y > t2.position3d.y);
      });
      if (exiting) {
        _exiting();
        return;
      }
      //TODO test if collision
      var avatarMask = avatarMaskFrom(p.x, p.z);
      var collision = _gm.getEntities(GROUP_BARRIER).fold(false, (acc, e2){
        var similarY = false;
        var t2 = _transformMapper.get(e2);
        if (t2 != null) {
          var deltaY = (p.y - t2.position3d.y);
          similarY = (deltaY < 0.4 && deltaY > -0.4);
        }
        var overlap = false;
        if (similarY) {
          var b2 = _barrierMapper.get(e2);
          overlap = ((b2 != null) && (avatarMask & b2.kind) != 0);
        }
        return acc || overlap;
      });
      if (collision) _collideBarrier(entity);
    } else {
      p.x = 0.0;
      p.z = 0.0;
      p.y += -0.06 * world.delta;
      if (p.y < -100) {
        _game._stop(false);
      }
    }
  }

  int avatarMaskFrom(x, z) {
    var avatarMask = 1 << (x.toInt() + 1);
    avatarMask = avatarMask | avatarMask << 3;
    // jump
    if (z >= 0.3) avatarMask = avatarMask << 3;
    // dash
    else if (z <= -0.3) avatarMask = avatarMask >> 3;
    return avatarMask;
  }

  void _exiting() {
    _game._stop(true);
  }

  void _collideBarrier(Entity entity) {
    entity.removeComponentByType(AvatarControl.CT);
    //TODO make animation to disable barrier (need state)
    _gm.getEntities(GROUP_BARRIER).forEach((e2){
      //var t2 = _transformMapper.get(e2);
      //if (t2 != null) t2.position3d.z = -100.0;
      e2.disable();
    });
  }
}

class System_BarrierHandler extends EntityProcessingSystem {
  ComponentMapper<Barrier> _barrierMapper;
  ComponentMapper<Transform> _transformMapper;
  GroupManager _gm;
  double recycleY;

  System_BarrierHandler() : super(Aspect.getAspectForAllOf([Barrier, Transform]));

  void initialize(){
    _barrierMapper = new ComponentMapper<Barrier>(Barrier, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _gm = world.getManager(GroupManager) as GroupManager;
  }

  bool checkProcessing() {
    recycleY = _gm.getEntities(GROUP_AVATAR).fold(0.0, (acc, e2){
      var t2 = _transformMapper.get(e2);
      if (t2 != null) acc = t2.position3d.y - 2.0;
      return acc;
    });
    return true;
  }

  void processEntity(Entity entity) {
    var barrier = _barrierMapper.get(entity);
    var transform = _transformMapper.get(entity);
    var p = transform.position3d;
    if (barrier.kind ==  Barrier.K_UNDEF) {
      setCyclePos(barrier, p, barrier.cyclePos);
    }
    if (p.y <= recycleY) {
      nextPos(barrier, p, entity);
    }
  }

  void nextPos(barrier, p, entity) {
    var newCyclePos = (barrier.cyclePos + barrier.cycleMax);
    if (newCyclePos >=   barrier.barriers.length) {
      p.z = -50.0;
      entity.disable();
    } else {
      if (!setCyclePos(barrier, p, newCyclePos)) {
        nextPos(barrier, p, entity);
      }
    }
  }
  bool setCyclePos(barrier, p, newCyclePos) {
    var nfo = barrier.barriers[newCyclePos];
    barrier.cyclePos = newCyclePos;
    barrier.kind = nfo[1];
    if (barrier.kind < 0) {
      if ((world.time ~/ 100)% 2 == 0) {
        // ignore this position
        return false;
      }
      barrier.kind = -barrier.kind;
    }
    p.y = nfo[0].toDouble();
    switch(barrier.kind) {
      case Barrier.K_H0 :
        barrier.dim.setValues(2.0, 0.5, 0.4);
        p.x = 0.0;
        p.z = -1.0;
        break;
      case Barrier.K_H1 :
        barrier.dim.setValues(2.0, 0.5, 0.4);
        p.x = 0.0;
        p.z = 0.0;
        break;
      case Barrier.K_H2 :
        barrier.dim.setValues(2.0, 0.5, 0.4);
        p.x = 0.0;
        p.z = 1.0;
        break;
      case Barrier.K_V0 :
        barrier.dim.setValues(0.4, 0.5, 2.0);
        p.x = -1.0;
        p.z = 0.0;
        break;
      case Barrier.K_V1 :
        barrier.dim.setValues(0.4, 0.5, 2.0);
        p.x = 0.0;
        p.z = 0.0;
        break;
      case Barrier.K_V2 :
        barrier.dim.setValues(0.4, 0.5, 2.0);
        p.x = 1.0;
        p.z = 0.0;
        break;
    }
    return true;
  }
}
