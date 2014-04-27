import 'dart:html';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:html_toolbox/html_toolbox.dart';
import 'package:html_toolbox/effects.dart';
import 'package:simple_audio/simple_audio.dart';
import 'package:ld29_vers_la_lumiere/events.dart';
import 'package:ld29_vers_la_lumiere/screens.dart';
import 'package:ld29_vers_la_lumiere/game.dart';

var bus = makeBus();
var game = null;
var screenInit = null;
var screenRunResult = null;

void main() {
  bus.on(eventErr).listen(handleError);
  loadDataSvgs().map((f) => f.catchError((err,st) {
    bus.fire(eventErr, new Err()
    ..category = "load svg"
    ..exc = err
    ..stacktrace = st
    );
  }));
  new Timer(const Duration(), () {
    var audioManager = _newAudioManager(findBaseUrl());

    //_setupLog();
    new UiAudioVolume()
    ..el = querySelector("#audioVolume")
    ..audioManager = audioManager
    ;
    UiDropdown.bind(document.body);

    screenInit = new UiScreenInit()
    ..el = querySelector("#screenInit")
    ..bus = bus
    ..init()
    ;
    screenRunResult = new UiScreenRunResult()
    ..el = querySelector('#screenRunResult')
    ..bus = bus
    ..init()
    ;
    bus.on(eventRunResult).listen((x) {
      _showScreen("screenRunResult");
    });
    bus.on(eventInGameStatus).listen((x) {
      if (x.kind == IGStatus.PLAYING) _showScreen("screenInGame");
    });

    game = new Game()
    ..el = querySelector("#screenInGame")
    ..audioManager = audioManager
    ..bus = bus
    //..dataServices = dataServices
    ..init()
    ;
    _setupRoutes();
  });
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    _route(window.location.hash);
  });
  _route(window.location.hash);
}

void _route(String hash) {
  //RegExp exp = new RegExp(r"(\w+)");
  if (hash.startsWith("#/a/")) {
    game.areaReq = hash.substring("#/a/".length);
    bus.fire(eventInGameReqAction, IGAction.INITIALIZE);
    _showScreen("screenInit");
  } else if (hash.startsWith("#/s/")) {
    bus.fire(eventInGameReqAction, IGAction.PAUSE);
    _showScreen(hash.substring("#/s/".length));
  } else {
    window.location.hash = '/a/l0';
  }
}

void _showScreen(id){
  if (_currentScreenId == id) return;
  var previousScreenId = _currentScreenId;
  var previousScreenTransition = _findTransition(previousScreenId);
  _currentScreenId = id;
  var currentScreenTransition = _findTransition(_currentScreenId);
  Swapper.swap(document.querySelector('#layers').children, document.querySelector('#$id'), effect: currentScreenTransition, duration : 1000, effectTiming: EffectTiming.ease, hideEffect: previousScreenTransition);
}

var _currentScreenId = '';

_findTransition(id) {
  return _transitionsDefault;
}
final _transitionsDefault = new ScaleEffect();
//final _transitionsFromTop = new ScaleEffect();

void _setupLog() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((r){
    if (r.level == Level.SEVERE) {
      window.console.error(r);
    } else if (r.level == Level.WARNING) {
      window.console.warn(r);
    } else if (r.level == Level.INFO) {
      window.console.log(r);
    } else {
//      window.console.debug(r);
    }
  });
  var _logger = new Logger("test");
  _logger.info("info");
  _logger.fine("fine");
  _logger.finer("finer");
  _logger.warning("warning");
  _logger.severe("severe");
}

AudioManager _newAudioManager(baseUrl) {
  try {
    var audioManager = new AudioManager(baseUrl);
    audioManager.mute = false;
    audioManager.masterVolume = 1.0;
    audioManager.musicVolume = 0.5;
    audioManager.sourceVolume = 0.9;
    return audioManager;
  } catch (e, st) {
    bus.fire(eventErr, new Err()
    ..exc = e
    ..stacktrace = st
    );
    return null;
  }
}

void handleError(Err err) {
  print("${err.category}\tERROR\t${err.exc}");
  if (err.stacktrace != null) print(err.stacktrace); //.fullStackTrace); // This should print the full stack trace)
}

