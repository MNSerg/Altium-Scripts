# Dialog pictures

All dialog illustrations are **320×214** pixels — the same size as `TImage` (`Width = 320`, `Height = 214`) in every `.dfm`. PNG and BMP match. Scripts still set `Stretch := True` after a successful `LoadFromFile`.

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
| Offset.png / Offset.bmp | Offset |
| PanelizerTest.png / PanelizerTest.bmp | PanelizerTest |

Toolbar icons (24×24 / 32×32 BMP) are in [`../Shortcuts/`](../Shortcuts/).
