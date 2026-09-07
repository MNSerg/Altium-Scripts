{..............................................................................}
{ CommonUtils.pas — общие константы и загрузка картинок-описаний.               }
{ Скрипты самодостаточны; этот модуль — справочник и можно вызывать Start.     }
{ Картинки: CustomScripts/images/<имя>.png — замените файл своим рисунком.      }
{..............................................................................}

const
    cCustomScriptsVersion = '1.1';
    cDefaultFilletRadiusMM = 0.5;
    cDefaultGndNetName     = 'GND';
    cImagesSubdir          = 'images';

{ Ищет PNG рядом со скриптом / PrjScr и грузит в TImage. }
procedure LoadHelpImage(Img : TImage; Hint : TLabel; const FileName : String);
var
    Cands : TStringList;
    i : Integer;
    P : String;
    WS : IWorkspace;
    Prj : IProject;
begin
    if Img = nil then Exit;
    Cands := TStringList.Create;
    try
        try Cands.Add(ExtractFilePath(ParamStr(0)) + 'images\' + FileName); except end;
        try Cands.Add(ExtractFilePath(ParamStr(0)) + FileName); except end;
        try
            WS := GetWorkspace;
            if WS <> nil then
            begin
                for i := 0 to WS.DM_ProjectCount - 1 do
                begin
                    Prj := WS.DM_Projects(i);
                    if Prj <> nil then
                        Cands.Add(ExtractFilePath(Prj.DM_ProjectFullPath) + 'images\' + FileName);
                end;
                if WS.DM_FocusedProject <> nil then
                    Cands.Add(ExtractFilePath(WS.DM_FocusedProject.DM_ProjectFullPath) + 'images\' + FileName);
            end;
        except
        end;
        Cands.Add('images\' + FileName);
        Cands.Add('CustomScripts\images\' + FileName);
        for i := 0 to Cands.Count - 1 do
        begin
            P := Cands[i];
            if (P <> '') and FileExists(P) then
            begin
                try
                    Img.Picture.LoadFromFile(P);
                    Img.Visible := True;
                    if Hint <> nil then
                        Hint.Caption := 'Картинку можно заменить файлом images\' + FileName;
                    Exit;
                except
                end;
            end;
        end;
        if Hint <> nil then
            Hint.Caption := 'Нет картинки. Положите ' + FileName + ' в папку images рядом со скриптами.';
    finally
        Cands.Free;
    end;
end;

procedure Start;
begin
    ShowInfo(
        'CustomScripts v' + cCustomScriptsVersion + sLineBreak + sLineBreak +
        'Картинки описаний: папка images\ рядом с CustomScripts.PrjScr.' + sLineBreak +
        'Запускайте конкретный скрипт (процедура Start).',
        'CustomScripts');
end;

procedure _Start;
begin
    Start;
end;
