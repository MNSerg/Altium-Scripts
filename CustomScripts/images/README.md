# Dialog pictures

All dialog illustrations are **320×214** pixels — the same size as `TImage` (`Width = 320`, `Height = 214`) in every `.dfm`. PNG and BMP match. Scripts still set `Stretch := True` after a successful `LoadFromFile`.

Copies also live in each `CustomScripts/<Name>/` folder next to that script’s `.PrjScr`. Loader looks there first, then this `images\` folder.

| File | Script |
| --- | --- |
| Fillet.png / Fillet.bmp | TrackCornerFillet |
| DxfExport.png / DxfExport.bmp | DxfOutlineExport |
| Panelizer.png / Panelizer.bmp | Panelizer |
| Panelize_Hard_Form.png / Panelize_Hard_Form.bmp | Panelize_Hard_Form |
| SchAnnotate.png / SchAnnotate.bmp | SchDesignatorReset |
| BomExport.png / BomExport.bmp | BomExport |
| GroundPolygons.png / GroundPolygons.bmp | GroundPolygons |
| PcbWizard.png / PcbWizard.bmp | PcbWizard |
| PlaceDesignators.png / PlaceDesignators.bmp | PlaceDesignators |
| Offset.png / Offset.bmp | Offset |

Toolbar icons (24×24 / 32×32 BMP) are in [`../Shortcuts/`](../Shortcuts/).
