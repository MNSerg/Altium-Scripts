# Altium script shortcut bitmaps

Icons for **DXP → Customizing** (Process Launcher / custom menus). Altium expects a small BMP (typically **24×24** or **32×32**, 24-bit or 16-color).

## Files

| Script | 24×24 | 32×32 |
| --- | --- | --- |
| TrackCornerFillet | `24x24/TrackCornerFillet.bmp` | `32x32/TrackCornerFillet.bmp` |
| DxfOutlineExport | `24x24/DxfOutlineExport.bmp` | `32x32/DxfOutlineExport.bmp` |
| Panelizer | `24x24/Panelizer.bmp` | `32x32/Panelizer.bmp` |
| SchDesignatorReset | `24x24/SchDesignatorReset.bmp` | `32x32/SchDesignatorReset.bmp` |
| BomExport | `24x24/BomExport.bmp` | `32x32/BomExport.bmp` |
| GroundPolygons | `24x24/GroundPolygons.bmp` | `32x32/GroundPolygons.bmp` |
| PcbWizard | `24x24/PcbWizard.bmp` | `32x32/PcbWizard.bmp` |
| PlaceDesignators | `24x24/PlaceDesignators.bmp` | `32x32/PlaceDesignators.bmp` |

Copies of the 24×24 set also sit in this folder (`TrackCornerFillet.bmp`, …) so you can pick a file without opening a subfolder.

## Assign in Altium

1. **DXP → Customizing…** (or **DXP → Customize**).
2. Open the **Process** / **Toolbar** / **Menu** page and select the script command (or add **Run Process** / script launcher for `Start…`).
3. In the command properties, set **Bitmap** (sometimes **Image** / **Button bitmap**) to one of these `.bmp` files.
4. Use **24×24** for toolbars; **32×32** if the UI looks better with a larger glyph.

Dialog illustrations (left pane of each form) are separate: `CustomScripts/images/*.png` at **320×214** to match the DFM `TImage`.
