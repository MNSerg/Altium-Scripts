# Dialog pictures

Restored from git commit `3e7d76e` (the set before the DFM-embed commit). PNG is the original art; BMP is the 320×214 dialog copy. Both live in `images/` and next to each `.pas`.

`TImage` in `.dfm` is empty (Left/Top/Width/Height only). Scripts `LoadFromFile` only if `FileExists`: this `.PrjScr` folder first, then `images\`. Missing file = caption hint, no crash.

| File | Script |
| --- | --- |
| Fillet.png / Fillet.bmp | TrackCornerFillet |
| DxfExport.png / DxfExport.bmp | DxfOutlineExport |
| Panelizer.png / Panelizer.bmp | Panelizer |
| SchAnnotate.png / SchAnnotate.bmp | SchDesignatorReset |
| BomExport.png / BomExport.bmp | BomExport |
| GroundPolygons.png / GroundPolygons.bmp | GroundPolygons |
| PcbWizard.png / PcbWizard.bmp | PcbWizard |
| PlaceDesignators.png / PlaceDesignators.bmp | PlaceDesignators |
