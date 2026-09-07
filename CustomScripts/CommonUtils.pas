{..............................................................................}
{ CommonUtils.pas — общие константы и справка по API Altium Designer 20+.       }
{ Скрипты в этом проекте самодостаточны и не требуют uses CommonUtils.          }
{ Модуль включён в CustomScripts.PrjScr как справочник.                         }
{..............................................................................}

const
    cCustomScriptsVersion = '1.0';
    cDefaultFilletRadiusMM = 0.5;
    cDefaultGndNetName     = 'GND';
    cDefaultPolyClearMM    = 0.2;

{ Точка входа-заглушка, чтобы модуль можно было открыть в Run Script. }
procedure Start;
begin
    ShowInfo(
        'CustomScripts v' + cCustomScriptsVersion + sLineBreak + sLineBreak +
        'Общие утилиты. Запускайте конкретный скрипт:' + sLineBreak +
        '  TrackCornerFillet, DxfOutlineExport, Panelizer,' + sLineBreak +
        '  SchDesignatorReset, BomExport, GroundPolygons,' + sLineBreak +
        '  PcbWizard, PlaceDesignators.' + sLineBreak + sLineBreak +
        'См. README.md и QUESTIONS.md в папке CustomScripts.',
        'CustomScripts');
end;

procedure _Start;
begin
    Start;
end;
