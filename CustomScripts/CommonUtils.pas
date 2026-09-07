{..............................................................................}
{ CommonUtils.pas — version info only. Each script is self-contained.          }
{ Do not put form types (TImage) here — Altium compiles listed units together. }
{..............................................................................}

const
    cCustomScriptsVersion = '1.2';

procedure Start;
begin
    ShowInfo(
        'CustomScripts v' + cCustomScriptsVersion + sLineBreak + sLineBreak +
        'Run a specific script procedure Start (not this file).' + sLineBreak +
        'Help pictures: folder images\ next to CustomScripts.PrjScr.',
        'CustomScripts');
end;

procedure _Start;
begin
    Start;
end;
