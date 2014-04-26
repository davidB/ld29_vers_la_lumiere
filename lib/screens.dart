library screens;

import 'dart:html';
import 'package:simple_audio/simple_audio.dart';
import 'package:intl/intl.dart';
import 'events.dart';

class UiAudioVolume {
  Element _element;
  AudioManager _audioManager;

  var subscriptions = new List();
  set el(Element v) {
    _element = v;
    _bind();
  }

  set audioManager(AudioManager v){
    _audioManager = v;
    _bind();
  }

  _bind() {
    subscriptions.forEach((x) => x.cancel());
    subscriptions.clear();
    if (_element == null || _audioManager == null) return;
    _bind0("#mute", _masterMute(), _changeMasterMute);
    _bind0("#masterVolume", _masterVolume(), _changeMasterVolume);
    _bind0("#musicVolume", _musicVolume(), _changeMusicVolume);
    _bind0("#sourceVolume", _sourceVolume(), _changeSourceVolume);
  }

  _bind0(selector, init, onChange) {
    var el = _element.querySelector(selector);
    if (el.type == "checkbox") el.checked = init;
    else if (el is InputElement) el.value = init.toString();
    else if (el is Element) el.text = init;
    subscriptions.add(el.onChange.listen(onChange));
  }

  _masterMute(){
    if (_audioManager == null) return true;
    return _audioManager.mute;
  }

  _changeMasterMute(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as CheckboxInputElement;
    _audioManager.mute = target.checked;
  }

  _masterVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.masterVolume;
  }

  _changeMasterVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.masterVolume = double.parse(target.value);
  }

  _musicVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.musicVolume;
  }

  _changeMusicVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.musicVolume = double.parse(target.value);
  }

  _sourceVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.sourceVolume;
  }

  _changeSourceVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.sourceVolume = double.parse(target.value);
  }
}



class UiScreenInit {
  Element el;
  var bus;

  var _onPlayEnabled = false;
  var _area = "";
  var _onPlay;

  init() {
    bus.on(eventInGameStatus).listen((x) {
      _onPlayEnabled = (x.kind == IGStatus.INITIALIZED || x.kind == IGStatus.STOPPED);
      _area = x.area;
      update();
    });
    _onPlay = (_){
      bus.fire(eventInGameReqAction, IGAction.PLAY);
    };
  }

  update(){
    if (el == null) return;
    el.querySelector("#msgLoading").style.opacity = _onPlayEnabled ? "0" : "1";
    el.querySelector("[data-text=area]").text = _area;
    var btn = el.querySelector(".play");
    (btn as ButtonElement).disabled = !_onPlayEnabled;
    btn.onClick.first.then(_onPlay);
  }
}

class UiScreenRunResult {
  Element el;
  var bus;
  num score = 0;
  var _onPlayEnabled = false;
  Function _onPlay;
  var _fmt = new NumberFormat("+00");

  init() {
    bus.on(eventRunResult).listen((x) {
      score = x.score;
      update();
    });
    bus.on(eventInGameStatus).listen((x) {
      _onPlayEnabled = (x.kind == IGStatus.INITIALIZED || x.kind == IGStatus.STOPPED);
      update();
    });
    _onPlay = (_){
      bus.fire(eventInGameReqAction, IGAction.PLAY);
    };
  }

  update(){
    if (el == null) return;
    try {
      _update0("score", score);
      var btnPlay = el.querySelector(".play");
      (btnPlay as ButtonElement).disabled = !_onPlayEnabled;
      btnPlay.onClick.first.then(_onPlay);
      var btnNext = el.querySelector(".next");
      (btnNext as ButtonElement).disabled = (_findNextAreaId() == null);
      btnNext.onClick.first.then(_onNext);
    } catch(e, st) {
//      print("WARNING");
//      print(e);
//      print(st);
    }
  }

  _update0(k, v) {
    var el0 = el.querySelector("[data-text=$k]");
    if (el0 != null) {
      el0.text = v.toString();
    }
  }

  _onNext(_) {
    var n = _findNextAreaId();
    if (n != null) {
      window.location.hash = '/a/$n';
    }
  }

  _findNextAreaId() {
//    switch(areaId) {
//      case 'alpha0': return 'beta0';
//      case 'beta0': return 'beta1';
//      case 'beta1': return 'gamma0';
//      case 'gamma0': return 'pacman0';
//    }
    return null;
  }
}