package;

// LDtk 1.1.3 json structs

typedef LDtk = {
	var worldGridWidth: Int;
	var worldGridHeight: Int;
	var defaultGridSize: Int;
	var bgColor: String;
	var defaultLevelBgColor: String;
	var externalLevels: Bool;

	var defs: LDtkDefs;
	var levels: Array<LDtkLevel>;
}

typedef LDtkLevel = {
	var identifier: String;
	var uid: Int;
	var worldX: Int;
	var worldY: Int;
	var externalRelPath: String;
	var layerInstances: Array<LDtkLayer>;
}

typedef LDtkLayer = {
	var __identifier: String;
	var __type: String;
	var __cWid: Int;
	var __cHei: Int;
	var __gridSize: Int;
	var __pxTotalOffsetX: Int;
	var __pxTotalOffsetY: Int;
	var __tilesetDefUid: Int;
	var __tilesetRelPath: String;
	var layerDefUid: Int;
	var pxOffsetX: Int;
	var pxOffsetY: Int;
	// ...

	var intGridCsv: Array<Int>;
	var autoLayerTiles: Array<LDtkTile>;
	var gridTiles: Array<LDtkTile>;
	var entityInstances: Array<LDtkEntity>;
}

typedef LDtkEntity = {
	var __identifier: String;
	var __grid: Array<Int>;
	var __pivot: Array<Int>;
	var iid: String;
	var width: Int;
	var height: Int;
	var defUid: Int;
	var px: Array<Int>;
}

typedef LDtkTile = {
	var px: Array<Int>;
	var src: Array<Int>;
	var f: Int;
	var t: Int;
}

typedef LDtkDefs = {
	var layers: Array<LDtkLayerDef>;
	var tilesets: Array<LDtkTilesetDef>;
}

typedef LDtkLayerDef = {
	var __type: String;
	var identifier: String;
	var type: String;
	var uid: Int;
	var pxOffsetX: Int;
	var pxOffsetY: Int;
	var parallaxFactorX: Float;
	var parallaxFactorY: Float;
	var parallaxScaling: Bool;
	var tilesetDefUid: Int;
}

typedef LDtkTilesetDef = {
	var __cWid: Int;
	var __cHei: Int;
}
