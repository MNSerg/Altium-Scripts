{..............................................................................}
{ ProjectZipper.pas                                                             }
{ Archive the focused Altium project with the scripting-engine zip API          }
{ from Zipper-example.pas: TXceedZip, GetAllFilePathsMatchingMask,              }
{ ExtractRelativePath, AddFilesToProcess, Zip.Zip.                              }
{..............................................................................}

var
    ZipPrjPath  : String;
    ZipOutPath  : String;
    ZipOldDir   : String;

procedure StartProjectZipper; forward;
procedure _StartProjectZipper; forward;
procedure TFormZip.ButtonOKClick(ZipSender: TObject); forward;
procedure TFormZip.ButtonCancelClick(ZipSender: TObject); forward;
procedure TFormZip.FormZipShow(ZipSender: TObject); forward;
procedure ZipDoArchive; forward;

procedure ZipShowBox(const Msg : String);
begin
    ShowMessage(Msg);
end;

function ZipEndsWithOld(const Rel : String) : Boolean;
var
    U : String;
begin
    U := UpperCase(Rel);
    Result := (Copy(U, 1, 4) = 'OLD\') or (Copy(U, 1, 4) = 'OLD/') or
              (U = 'OLD') or (Pos('\OLD\', U) > 0) or (Pos('/OLD/', U) > 0);
end;

function ZipStamp : String;
begin
    Result := FormatDateTime('yyyymmdd_hhnn', Now);
end;

{ GetAllFilePathsMatchingMask / ExtractRelativePath expect a trailing slash,
  as in Zipper-example.pas (ProjectPath := '...\'). }
function ZipEnsureSlash(const ZipP : String) : String;
begin
    Result := ZipP;
    if Result = '' then Exit;
    if (Result[Length(Result)] <> '\') and (Result[Length(Result)] <> '/') then
        Result := Result + '\';
end;

procedure ZipFillFromProject;
var
    ZipWS  : IWorkspace;
    ZipPrj : IProject;
    ZipName : String;
begin
    ZipPrjPath := '';
    ZipOldDir := '';
    ZipOutPath := '';
    ZipWS := GetWorkspace;
    if ZipWS = nil then Exit;
    ZipPrj := ZipWS.DM_FocusedProject;
    if ZipPrj = nil then Exit;
    try
        ZipPrjPath := ZipPrj.DM_ProjectFullPath;
    except
        ZipPrjPath := '';
    end;
    if (ZipPrjPath = '') or (not FileExists(ZipPrjPath)) then Exit;
    ZipName := ChangeFileExt(ExtractFileName(ZipPrjPath), '');
    ZipPrjPath := ZipEnsureSlash(ExtractFilePath(ZipPrjPath));
    ZipOldDir := ZipPrjPath + 'OLD';
    ZipOutPath := ZipOldDir + '\' + ZipName + '_' + ZipStamp + '.zip';
end;

procedure ZipDoArchive;
var
    Zip            : TXceedZip;
    GeneratedFiles : TStringList;
    FilePath       : WideString;
    Rel            : String;
    Zipi, ZipRc    : Integer;
    ProjectPath    : String;
begin
    if (ZipPrjPath = '') or (ZipOutPath = '') then
    begin
        ZipShowBox(LabelErrPrj.Caption);
        Exit;
    end;
    if not DirectoryExists(ZipOldDir) then
        MkDir(ZipOldDir);
    if not DirectoryExists(ZipOldDir) then
    begin
        ZipShowBox(LabelErrOld.Caption);
        Exit;
    end;

    ProjectPath := ZipPrjPath;
    Zip := TXCeedZip.Create(ZipOutPath);
    GeneratedFiles := TStringList.Create;
    try
        Zip.UseTempFile := False;
        Zip.BasePath := RemoveSlash(ProjectPath, cPathSeparator);
        Zip.ProcessSubfolders := False;

        GetAllFilePathsMatchingMask(GeneratedFiles, ProjectPath, '*.*', True);

        if GeneratedFiles.Count > 0 then
            for Zipi := 0 to GeneratedFiles.Count - 1 do
            begin
                FilePath := GeneratedFiles.Strings[Zipi];
                Rel := ExtractRelativePath(ProjectPath, FilePath);
                if (Rel = cFilename_CurrentDir) or (Rel = cFilename_ParentDir) then
                    Continue;
                if ZipEndsWithOld(Rel) then Continue;
                Zip.AddFilesToProcess(Rel);
            end;

        ZipRc := Zip.Zip;
        ZipShowBox(LabelInfoDone.Caption + ZipOutPath + sLineBreak +
                   LabelInfoRc.Caption + IntToStr(ZipRc) + sLineBreak +
                   LabelInfoSize.Caption + IntToStr(Zip.InstanceSize));
    finally
        GeneratedFiles.Free;
        Zip.Free;
    end;
end;

procedure TFormZip.ButtonOKClick(ZipSender: TObject);
begin
    ZipFillFromProject;
    if EditPrj.Text <> '' then
        ZipPrjPath := ZipEnsureSlash(EditPrj.Text);
    if EditZip.Text <> '' then
        ZipOutPath := EditZip.Text;
    ZipOldDir := ExtractFilePath(ZipOutPath);
    if (Length(ZipOldDir) > 0) and
       ((ZipOldDir[Length(ZipOldDir)] = '\') or (ZipOldDir[Length(ZipOldDir)] = '/')) then
        ZipOldDir := Copy(ZipOldDir, 1, Length(ZipOldDir) - 1);
    FormZip.Close;
    ZipDoArchive;
end;

procedure TFormZip.ButtonCancelClick(ZipSender: TObject);
begin
    FormZip.Close;
end;

function ZipCS_ScriptFolder : String;
var
    ZipWS  : IWorkspace;
    ZipPrj : IProject;
    Zipi   : Integer;
    ZipP, ZipName : String;
begin
    Result := '';
    try
        ZipWS := GetWorkspace;
        if ZipWS = nil then Exit;
        for Zipi := 0 to ZipWS.DM_ProjectCount - 1 do
        begin
            ZipPrj := ZipWS.DM_Projects(Zipi);
            if ZipPrj = nil then Continue;
            ZipP := ZipPrj.DM_ProjectFullPath;
            ZipName := UpperCase(ExtractFileName(ZipP));
            if ZipName = 'PROJECTZIPPER.PRJSCR' then
            begin
                Result := ExtractFilePath(ZipP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function ZipCS_FindImageFile(const ZipFileName : String) : String;
var
    ZipDir, ZipP : String;
begin
    Result := '';
    ZipDir := ZipCS_ScriptFolder;
    if ZipDir <> '' then
    begin
        ZipP := ZipDir + ZipFileName;
        if FileExists(ZipP) then begin Result := ZipP; Exit; end;
        ZipP := ZipDir + 'images\' + ZipFileName;
        if FileExists(ZipP) then begin Result := ZipP; Exit; end;
    end;
    if FileExists(ZipFileName) then begin Result := ZipFileName; Exit; end;
    ZipP := 'images\' + ZipFileName;
    if FileExists(ZipP) then Result := ZipP;
end;

procedure ZipCS_TryOneHelpFile(const ZipName : String; var ZipDone : Boolean);
var
    ZipP : String;
begin
    if ZipDone then Exit;
    ZipP := ZipCS_FindImageFile(ZipName);
    if (ZipP = '') or (not FileExists(ZipP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(ZipP);
        ImageHelp.Stretch := True;
        try ImageHelp.Proportional := True; except end;
        try ImageHelp.Center := True; except end;
        LabelImageHint.Caption := '';
        ZipDone := True;
    except
    end;
end;

procedure ZipCS_TryLoadHelpImage(const ZipBmpName : String; const ZipPngName : String);
var
    ZipDone : Boolean;
begin
    ZipDone := False;
    ZipCS_TryOneHelpFile(ZipPngName, ZipDone);
    ZipCS_TryOneHelpFile(ZipBmpName, ZipDone);
    ZipCS_TryOneHelpFile('ProjectZipper.png', ZipDone);
    ZipCS_TryOneHelpFile('ProjectZipper.bmp', ZipDone);
    if not ZipDone then
        LabelImageHint.Caption := 'No image. Put ' + ZipPngName + ' next to the script or in images\.';
end;

procedure TFormZip.FormZipShow(ZipSender: TObject);
begin
    try
        ZipCS_TryLoadHelpImage('ProjectZipper.bmp', 'ProjectZipper.png');
    except
    end;
    ZipFillFromProject;
    EditPrj.Text := ZipPrjPath;
    EditZip.Text := ZipOutPath;
end;

procedure StartProjectZipper;
begin
    FormZip.ShowModal;
end;

procedure _StartProjectZipper;
begin
    StartProjectZipper;
end;
