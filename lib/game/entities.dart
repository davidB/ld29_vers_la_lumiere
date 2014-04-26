part of game;

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
     var areadef = assetpack['area'];
     renderFact.reset();
     var es = new List<Entity>();
//     es.add(newCamera("${assetpack.name}.music", areadef.aabb3));
//     es.add(newArea(assetpack.name));
//     es.add(newChronometer(areadef.chronometer, timeout));
//     es.add(newGateIns(areadef.gateIns, assetpack));
//     es.add(newGateOuts(areadef.gateOuts, assetpack));
//     es.add(newFloor());
//     es.addAll(areadef.staticWalls.map((x) => newStaticWalls(x, assetpack)));
//     es.addAll(areadef.mobileWalls.map((x) => newMobileWall(x, assetpack)));
//     es.addAll(areadef.cubeGenerators.map((x) => newCube(x)));

     es.add(newAvatar());
     return es;
   }

  Entity newAvatar() {
    return _world.createEntity([
      new AvatarControl()
      , new AvatarNumbers()
      , new Transform.w3d(new Vector3(0.0,0.0,0.0))
    ]);
  }
}

class Factory_Renderables {

  void reset(){}
}