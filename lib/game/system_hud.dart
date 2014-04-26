part of game;

class System_Hud extends IntervalEntitySystem {
  ComponentMapper<AvatarNumbers> _avatarNumbersMapper;

  Element _container;
  Element _scoreEl;
  Element _scoreIncEl;
  bool _initialized = false;

  System_Hud(this._container):super(1000.0/15, Aspect.getAspectForOneOf([AvatarNumbers]));

  void initialize(){
    _avatarNumbersMapper = new ComponentMapper<AvatarNumbers>(AvatarNumbers, world);
    //TODO Window.resizeEvent.forTarget(window).listen(_updateViewportSize);
    //TODO use AssetManager to retreive dom or a web_ui component
    reset();
  }

  void _initializeDom(domElem) {
    if (domElem != null) {
      _scoreEl = _container.querySelector("#score");
      if (_scoreEl != null) _scoreEl.text = "0";
      _scoreIncEl = _container.querySelector("#scoreInc");
      if (_scoreIncEl != null) {
        _scoreIncEl.style.transition = "all 1.5s ease-out";
      }
      _initialized = true;
    }
  }

  bool checkProcessing() {
    var b = super.checkProcessing();
    if (!_initialized) reset();
    return b && _initialized;
  }

  void processEntities(Iterable<Entity> entities) {
    entities.forEach((entity){
      var numbers = _avatarNumbersMapper.getSafe(entity);
      if (numbers != null) {
        if (_scoreEl != null) _scoreEl.text = numbers.score.toString();
      }
    });
  }

  void reset() {
    _initialized = false;
    var c = _container.querySelector("#hud").childNodes;
    if (c.length == 1) _initializeDom(c[0]);
  }
}
