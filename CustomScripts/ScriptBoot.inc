{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function CS_ScriptFolder : String;
var
    WS  : IWorkspace;
    Prj : IProject;
    i   : Integer;
    P   : String;
begin
    Result := '';
    try
        WS := GetWorkspace;
        if WS = nil then Exit;
        Prj := WS.DM_FocusedProject;
        if Prj <> nil then
        begin
            P := ExtractFilePath(Prj.DM_ProjectFullPath);
            if P <> '' then
            begin
                Result := P;
                Exit;
            end;
        end;
        for i := 0 to WS.DM_ProjectCount - 1 do
        begin
            Prj := WS.DM_Projects(i);
            if Prj <> nil then
            begin
                P := Prj.DM_ProjectFullPath;
                if Pos('CustomScripts', P) > 0 then
                begin
                    Result := ExtractFilePath(P);
                    Exit;
                end;
            end;
        end;
    except
        Result := '';
    end;
end;

function CS_FindImageFile(const FileName : String) : String;
var
    Dir, P : String;
begin
    Result := '';
    Dir := CS_ScriptFolder;
    if Dir <> '' then
    begin
        P := Dir + 'images\' + FileName;
        if FileExists(P) then
        begin
            Result := P;
            Exit;
        end;
        P := Dir + FileName;
        if FileExists(P) then
        begin
            Result := P;
            Exit;
        end;
    end;
    P := 'images\' + FileName;
    if FileExists(P) then Result := P;
end;

procedure CS_TryLoadHelpImage(const BmpName : String; const PngName : String);
var
    P : String;
begin
    try
        P := CS_FindImageFile(BmpName);
        if P = '' then
            P := CS_FindImageFile(PngName);
        if (P <> '') and FileExists(P) then
        begin
            ImageHelp.Picture.LoadFromFile(P);
            LabelImageHint.Caption := 'Replace image: images\' + BmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + BmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
end;
