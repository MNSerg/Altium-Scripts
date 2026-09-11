{..............................................................................}
{ ProjectZipper.pas                                                             }
{ Archive the focused Altium project with the scripting-engine zip API          }
{ from Zipper-example.pas: TXceedZip, GetAllFilePathsMatchingMask,              }
{ ExtractRelativePath, AddFilesToProcess, Zip.Zip. No OLE, no BlockWrite.       }
{..............................................................................}

var
    ZipPrjPath  : String;
    ZipOutPath  : String;
    ZipOldDir   : String;
    ZipPrjName  : String;
    ZipLastFile : String;

procedure StartProjectZipper; forward;
procedure _StartProjectZipper; forward;
procedure TFormZip.ButtonOKClick(ZipSender: TObject); forward;
procedure TFormZip.ButtonCancelClick(ZipSender: TObject); forward;
procedure TFormZip.FormZipShow(ZipSender: TObject); forward;
procedure TFormZip.ZipBtnBrowsePrjClick(ZipSender: TObject); forward;
procedure TFormZip.ZipBtnBrowseZipClick(ZipSender: TObject); forward;
procedure ZipDoArchive; forward;

procedure ZipShowBox(const Msg : String);
begin
    ShowMessage(Msg);
end;

procedure ZipUiRefresh;
begin
    try FormZip.Update; except end;
    try FormZip.Refresh; except end;
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

function ZipStripSlash(const ZipP : String) : String;
begin
    Result := ZipP;
    if Result = '' then Exit;
    if (Result[Length(Result)] = '\') or (Result[Length(Result)] = '/') then
        Result := Copy(Result, 1, Length(Result) - 1);
end;

function ZipFolderName(const ZipP : String) : String;
var
    T : String;
begin
    T := ZipStripSlash(ZipP);
    Result := ExtractFileName(T);
    if Result = '' then Result := 'Project';
end;

procedure ZipDefaultOut;
begin
    if ZipPrjName = '' then ZipPrjName := ZipFolderName(ZipPrjPath);
    ZipOldDir := ZipEnsureSlash(ZipPrjPath) + 'OLD';
    ZipOutPath := ZipOldDir + '\' + ZipPrjName + '_' + ZipStamp + '.zip';
end;

function ZipPickFolder(const ZipCap, ZipStart : String) : String;
var
    ZipDlg : TOpenDialog;
    ZipDir : String;
    ZipOk  : Boolean;
begin
    Result := '';
    ZipLastFile := '';
    ZipDir := ZipStart;
    ZipOk := False;
    try
        ZipOk := SelectDirectory(ZipCap, '', ZipDir);
    except
        ZipOk := False;
    end;
    if ZipOk and (ZipDir <> '') then
    begin
        Result := ZipEnsureSlash(ZipDir);
        Exit;
    end;
    ZipDlg := TOpenDialog.Create(nil);
    try
        ZipDlg.Title := ZipCap;
        ZipDlg.Filter := 'Altium (*.PrjPcb;*.PcbDoc)|*.PrjPcb;*.PcbDoc|Zip (*.zip)|*.zip|All (*.*)|*.*';
        try ZipDlg.InitialDir := ZipStart; except end;
        if ZipDlg.Execute then
        begin
            ZipLastFile := ZipDlg.FileName;
            if UpperCase(ExtractFileExt(ZipDlg.FileName)) = '.ZIP' then
                Result := ZipDlg.FileName
            else
                Result := ZipEnsureSlash(ExtractFilePath(ZipDlg.FileName));
        end;
    finally
        ZipDlg.Free;
    end;
end;

procedure ZipFillFromProject;
var
    ZipWS  : IWorkspace;
    ZipPrj : IProject;
begin
    ZipPrjPath := '';
    ZipOldDir := '';
    ZipOutPath := '';
    ZipPrjName := '';
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
    ZipPrjName := ChangeFileExt(ExtractFileName(ZipPrjPath), '');
    ZipPrjPath := ZipEnsureSlash(ExtractFilePath(ZipPrjPath));
    ZipDefaultOut;
end;

procedure ZipApplyEdits;
begin
    if EditPrj.Text <> '' then
        ZipPrjPath := ZipEnsureSlash(EditPrj.Text);
    if EditZip.Text <> '' then
        ZipOutPath := EditZip.Text;
    ZipOldDir := ZipStripSlash(ExtractFilePath(ZipOutPath));
    if ZipOldDir = '' then
        ZipOldDir := ZipEnsureSlash(ZipPrjPath) + 'OLD';
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

    ProjectPath := ZipEnsureSlash(ZipPrjPath);
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

        try ZipProgress.Position := 50; except end;
        ZipUiRefresh;

        ZipRc := Zip.Zip;

        try ZipProgress.Position := 100; except end;
        ZipLabelProg.Caption := LabelProgDone.Caption;
        ZipUiRefresh;

        ZipShowBox(LabelInfoDone.Caption + ZipOutPath + sLineBreak +
                   LabelInfoRc.Caption + IntToStr(ZipRc) + sLineBreak +
                   LabelInfoSize.Caption + IntToStr(Zip.InstanceSize));
    finally
        GeneratedFiles.Free;
        Zip.Free;
    end;
end;

procedure TFormZip.ZipBtnBrowsePrjClick(ZipSender: TObject);
var
    ZipP, ZipFn : String;
begin
    ZipP := ZipPickFolder(LabelDlgPrj.Caption, EditPrj.Text);
    if ZipP = '' then Exit;
    if (Length(ZipP) > 4) and (UpperCase(Copy(ZipP, Length(ZipP) - 3, 4)) = '.ZIP') then
        Exit;
    ZipFn := ExtractFileName(ZipLastFile);
    if (ZipFn <> '') and
       ((UpperCase(ExtractFileExt(ZipFn)) = '.PRJPCB') or
        (UpperCase(ExtractFileExt(ZipFn)) = '.PCBDOC')) then
        ZipPrjName := ChangeFileExt(ZipFn, '')
    else
        ZipPrjName := ZipFolderName(ZipP);
    ZipPrjPath := ZipEnsureSlash(ZipP);
    EditPrj.Text := ZipPrjPath;
    ZipDefaultOut;
    EditZip.Text := ZipOutPath;
end;

procedure TFormZip.ZipBtnBrowseZipClick(ZipSender: TObject);
var
    ZipP, ZipFn : String;
begin
    ZipP := ZipPickFolder(LabelDlgZip.Caption, ExtractFilePath(EditZip.Text));
    if ZipP = '' then Exit;
    if (Length(ZipP) > 4) and (UpperCase(Copy(ZipP, Length(ZipP) - 3, 4)) = '.ZIP') then
    begin
        EditZip.Text := ZipP;
        Exit;
    end;
    ZipFn := ExtractFileName(EditZip.Text);
    if ZipFn = '' then
        ZipFn := ZipFolderName(EditPrj.Text) + '_' + ZipStamp + '.zip';
    EditZip.Text := ZipEnsureSlash(ZipP) + ZipFn;
end;

procedure TFormZip.ButtonOKClick(ZipSender: TObject);
begin
    ZipApplyEdits;
    if (ZipPrjPath = '') or (ZipOutPath = '') then
    begin
        ZipShowBox(LabelErrPrj.Caption);
        Exit;
    end;
    if not ConfirmNoYes(LabelAskFreeze.Caption) then Exit;

    ButtonOK.Enabled := False;
    ButtonCancel.Enabled := False;
    ZipBtnBrowsePrj.Enabled := False;
    ZipBtnBrowseZip.Enabled := False;
    ZipLabelProg.Caption := LabelProgBusy.Caption;
    try ZipProgress.Position := 10; except end;
    ZipUiRefresh;

    ZipDoArchive;

    ZipLabelProg.Caption := LabelProgDone.Caption;
    try ZipProgress.Position := 100; except end;
    ButtonOK.Enabled := True;
    ButtonCancel.Enabled := True;
    ZipBtnBrowsePrj.Enabled := True;
    ZipBtnBrowseZip.Enabled := True;
    ZipUiRefresh;
    FormZip.Close;
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
    ZipLabelProg.Caption := '';
    try ZipProgress.Position := 0; except end;
end;

procedure StartProjectZipper;
begin
    FormZip.ShowModal;
end;

procedure _StartProjectZipper;
begin
    StartProjectZipper;
end;
