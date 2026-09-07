{..............................................................................}
{ CommonUtils.pas — version info only. Not listed in any .PrjScr.              }
{ Each script is its own project. Do not add this file next to the scripts.    }
{..............................................................................}

const
    cCustomScriptsVersion = '1.3';

{ Run Script: StartCustomScriptsInfo — not used by the eight tools. }
procedure StartCustomScriptsInfo;
begin
    ShowInfo(
        'CustomScripts v' + cCustomScriptsVersion + sLineBreak + sLineBreak +
        'Open the per-script .PrjScr (Panelizer.PrjScr, TrackCornerFillet.PrjScr, ...).' + sLineBreak +
        'Run the unique Start… procedure (StartPanelizer, StartTrackCornerFillet, ...).' + sLineBreak +
        'Do not compile all .pas in one project — Altium shares one namespace.' + sLineBreak +
        'Help pictures: folder images\ next to the .PrjScr files.',
        'CustomScripts');
end;

procedure _StartCustomScriptsInfo;
begin
    StartCustomScriptsInfo;
end;
