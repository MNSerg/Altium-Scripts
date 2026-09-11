{..............................................................................}
{ ProjectRenamer.pas                                                            }
{ Rename the focused Altium project file and matching documents on disk.        }
{ Prefix Ren* (no Zip* identifiers). No OLE, no PChar, no Val, no rfReplaceAll. }
{..............................................................................}

var
    RenPrjFile  : String;
    RenPrjDir   : String;
    RenOldName  : String;
    RenNewName  : String;
    RenDoDocs   : Boolean;
    RenDoFolder : Boolean;
    RenDoOld    : Boolean;

procedure StartProjectRenamer; forward;
procedure _StartProjectRenamer; forward;
procedure TFormRen.RenButtonOKClick(RenSender: TObject); forward;
procedure TFormRen.RenButtonCancelClick(RenSender: TObject); forward;
procedure TFormRen.FormRenShow(RenSender: TObject); forward;
procedure TFormRen.RenBtnBrowseClick(RenSender: TObject); forward;
procedure RenDoRename; forward;

procedure RenShowBox(const RenMsg : String);
begin
    ShowMessage(RenMsg);
end;

procedure RenUiRefresh;
begin
    try FormRen.Update; except end;
    try FormRen.Refresh; except end;
end;

function RenReplaceCI(const RenS, RenFind, RenRepl : String) : String;
var
    RenRest, RenURest, RenUFind : String;
    RenP : Integer;
begin
    Result := '';
    if RenFind = '' then
    begin
        Result := RenS;
        Exit;
    end;
    RenRest := RenS;
    RenUFind := UpperCase(RenFind);
    RenURest := UpperCase(RenRest);
    RenP := Pos(RenUFind, RenURest);
    while RenP > 0 do
    begin
        Result := Result + Copy(RenRest, 1, RenP - 1) + RenRepl;
        RenRest := Copy(RenRest, RenP + Length(RenFind), Length(RenRest));
        RenURest := UpperCase(RenRest);
        RenP := Pos(RenUFind, RenURest);
    end;
    Result := Result + RenRest;
end;

function RenEnsureSlash(const RenP : String) : String;
begin
    Result := RenP;
    if Result = '' then Exit;
    if (Result[Length(Result)] <> '\') and (Result[Length(Result)] <> '/') then
        Result := Result + '\';
end;

function RenNormSlash(const RenP : String) : String;
begin
    Result := RenReplaceCI(RenP, '/', '\');
end;

function RenTrimName(const RenS : String) : String;
var
    RenT : String;
begin
    RenT := RenS;
    while (Length(RenT) > 0) and (RenT[1] = ' ') do
        RenT := Copy(RenT, 2, Length(RenT));
    while (Length(RenT) > 0) and (RenT[Length(RenT)] = ' ') do
        RenT := Copy(RenT, 1, Length(RenT) - 1);
    Result := RenT;
end;

function RenNameOk(const RenN : String) : Boolean;
var
    Reni : Integer;
    RenU, RenC : String;
begin
    Result := False;
    if RenN = '' then Exit;
    if Length(RenN) > 200 then Exit;
    if (RenN[1] = ' ') or (RenN[Length(RenN)] = ' ') then Exit;
    if RenN[Length(RenN)] = '.' then Exit;
    if (RenN = '.') or (RenN = '..') then Exit;
    for Reni := 1 to Length(RenN) do
    begin
        RenC := Copy(RenN, Reni, 1);
        if (RenC = '<') or (RenC = '>') or (RenC = ':') or (RenC = '"') or
           (RenC = '/') or (RenC = '\') or (RenC = '|') or (RenC = '?') or
           (RenC = '*') then
            Exit;
        if RenN[Reni] < #32 then Exit;
    end;
    RenU := UpperCase(RenN);
    if (RenU = 'CON') or (RenU = 'PRN') or (RenU = 'AUX') or (RenU = 'NUL') then Exit;
    if (Length(RenU) = 4) and (Copy(RenU, 1, 3) = 'COM') and
       (RenU[4] >= '1') and (RenU[4] <= '9') then Exit;
    if (Length(RenU) = 4) and (Copy(RenU, 1, 3) = 'LPT') and
       (RenU[4] >= '1') and (RenU[4] <= '9') then Exit;
    Result := True;
end;

function RenIndexOfCI(RenL : TStringList; const RenS : String) : Integer;
var
    Reni : Integer;
    RenU : String;
begin
    Result := -1;
    RenU := UpperCase(RenS);
    if RenL = nil then Exit;
    for Reni := 0 to RenL.Count - 1 do
        if UpperCase(RenL.Strings[Reni]) = RenU then
        begin
            Result := Reni;
            Exit;
        end;
end;

function RenPathHasFolder(const RenRel, RenName : String) : Boolean;
var
    RenU, RenN : String;
begin
    RenU := UpperCase(RenNormSlash(RenRel));
    RenN := UpperCase(RenName);
    Result := (Copy(RenU, 1, Length(RenN) + 1) = RenN + '\') or
              (RenU = RenN) or
              (Pos('\' + RenN + '\', RenU) > 0) or
              (Copy(RenU, Length(RenU) - Length(RenN), Length(RenN) + 1) = '\' + RenN);
end;

function RenEndsWithOld(const RenRel : String) : Boolean;
var
    RenU : String;
begin
    RenU := UpperCase(RenNormSlash(RenRel));
    Result := (Copy(RenU, 1, 4) = 'OLD\') or (RenU = 'OLD') or
              (Pos('\OLD\', RenU) > 0);
end;

function RenIsPrjBackupZip(const RenPath : String) : Boolean;
var
    RenU : String;
begin
    RenU := UpperCase(RenPath);
    Result := (Pos('.PRJPCB.ZIP', RenU) > 0) or (Pos('.PRJSCH.ZIP', RenU) > 0) or
              (Pos('.PRJSCR.ZIP', RenU) > 0);
end;

function RenSkipRel(const RenRel : String) : Boolean;
begin
    Result := True;
    if RenPathHasFolder(RenRel, 'History') then Exit;
    if RenPathHasFolder(RenRel, '__Previews') then Exit;
    if RenIsPrjBackupZip(RenRel) then Exit;
    if (not RenDoOld) and RenEndsWithOld(RenRel) then Exit;
    Result := False;
end;

function RenHasStem(const RenFileName, RenStem : String) : Boolean;
begin
    Result := False;
    if (RenFileName = '') or (RenStem = '') then Exit;
    Result := Pos(UpperCase(RenStem), UpperCase(ExtractFileName(RenFileName))) > 0;
end;

function RenMapFileName(const RenFileName, RenOld, RenNew : String) : String;
var
    RenBase, RenExt : String;
begin
    RenExt := ExtractFileExt(RenFileName);
    RenBase := ChangeFileExt(ExtractFileName(RenFileName), '');
    if Pos(UpperCase(RenOld), UpperCase(RenBase)) > 0 then
        RenBase := RenReplaceCI(RenBase, RenOld, RenNew);
    Result := RenBase + RenExt;
end;

function RenIsTextExt(const RenPath : String) : Boolean;
var
    RenE : String;
begin
    RenE := UpperCase(ExtractFileExt(RenPath));
    Result := (RenE = '.PRJPCB') or (RenE = '.PRJSCH') or (RenE = '.PRJSCR') or
              (RenE = '.PRJLIB') or (RenE = '.PRJGRP') or (RenE = '.PRJMBD') or
              (RenE = '.OUTJOB') or (RenE = '.SCHDOC') or (RenE = '.SCHLIB') or
              (RenE = '.SCHDOT') or (RenE = '.TXT') or (RenE = '.CSV') or
              (RenE = '.XML') or (RenE = '.INI') or (RenE = '.CFG') or
              (RenE = '.HARNESS');
end;

function RenFileLooksText(const RenPath : String) : Boolean;
var
    RenF : File;
    RenChunk : String;
    Reni, RenN : Integer;
begin
    Result := False;
    if not FileExists(RenPath) then Exit;
    if not RenIsTextExt(RenPath) then Exit;
    AssignFile(RenF, RenPath);
    try
        Reset(RenF, 1);
        RenN := FileSize(RenF);
        if RenN <= 0 then
        begin
            Result := True;
            CloseFile(RenF);
            Exit;
        end;
        if RenN > 2000000 then
        begin
            CloseFile(RenF);
            Exit;
        end;
        RenChunk := 'X';
        Reni := 0;
        while (Reni < 256) and (not Eof(RenF)) do
        begin
            BlockRead(RenF, RenChunk[1], 1);
            if RenChunk[1] = #0 then
            begin
                CloseFile(RenF);
                Exit;
            end;
            Inc(Reni);
        end;
        CloseFile(RenF);
        Result := True;
    except
        try CloseFile(RenF); except end;
        Result := False;
    end;
end;

procedure RenAddPair(RenOldL, RenNewL : TStringList; const RenAOld, RenANew : String);
var
    Reni : Integer;
begin
    if (RenAOld = '') or (RenANew = '') then Exit;
    if UpperCase(RenNormSlash(RenAOld)) = UpperCase(RenNormSlash(RenANew)) then Exit;
    if RenIndexOfCI(RenOldL, RenAOld) >= 0 then Exit;
    for Reni := 0 to RenNewL.Count - 1 do
        if UpperCase(RenNormSlash(RenNewL.Strings[Reni])) = UpperCase(RenNormSlash(RenANew)) then
            Exit;
    RenOldL.Add(RenAOld);
    RenNewL.Add(RenANew);
end;

procedure RenSortByOldLen(RenOldL, RenNewL : TStringList);
var
    Reni, Renj : Integer;
    RenT : String;
begin
    if (RenOldL = nil) or (RenOldL.Count < 2) then Exit;
    for Reni := 0 to RenOldL.Count - 2 do
        for Renj := Reni + 1 to RenOldL.Count - 1 do
            if Length(ExtractFileName(RenOldL.Strings[Renj])) >
               Length(ExtractFileName(RenOldL.Strings[Reni])) then
            begin
                RenT := RenOldL.Strings[Reni];
                RenOldL.Strings[Reni] := RenOldL.Strings[Renj];
                RenOldL.Strings[Renj] := RenT;
                RenT := RenNewL.Strings[Reni];
                RenNewL.Strings[Reni] := RenNewL.Strings[Renj];
                RenNewL.Strings[Renj] := RenT;
            end;
end;

function RenApplyMaps(const RenLine : String; RenOldL, RenNewL : TStringList) : String;
var
    Reni : Integer;
    RenS, RenOldFn, RenNewFn : String;
begin
    RenS := RenLine;
    if RenOldL = nil then
    begin
        Result := RenS;
        Exit;
    end;
    for Reni := 0 to RenOldL.Count - 1 do
    begin
        RenOldFn := ExtractFileName(RenOldL.Strings[Reni]);
        RenNewFn := ExtractFileName(RenNewL.Strings[Reni]);
        if (RenOldFn <> '') and (UpperCase(RenOldFn) <> UpperCase(RenNewFn)) then
            RenS := RenReplaceCI(RenS, RenOldFn, RenNewFn);
    end;
    Result := RenS;
end;

function RenTryRenameFile(const RenAOld, RenANew : String) : Boolean;
begin
    Result := False;
    if (RenAOld = '') or (RenANew = '') then Exit;
    if not FileExists(RenAOld) then Exit;
    if FileExists(RenANew) then Exit;
    try
        Result := RenameFile(RenAOld, RenANew);
    except
        Result := False;
    end;
end;

procedure RenRewriteFile(const RenPath : String; RenOldL, RenNewL : TStringList;
                         RenLog : TStringList);
var
    RenSL : TStringList;
    Reni : Integer;
    RenChanged : Boolean;
    RenLine : String;
begin
    if (RenPath = '') or (not FileExists(RenPath)) then Exit;
    if not RenFileLooksText(RenPath) then Exit;
    RenSL := TStringList.Create;
    try
        try
            RenSL.LoadFromFile(RenPath);
        except
            if RenLog <> nil then
                RenLog.Add(RenPath);
            Exit;
        end;
        RenChanged := False;
        for Reni := 0 to RenSL.Count - 1 do
        begin
            RenLine := RenApplyMaps(RenSL.Strings[Reni], RenOldL, RenNewL);
            if RenLine <> RenSL.Strings[Reni] then
            begin
                RenSL.Strings[Reni] := RenLine;
                RenChanged := True;
            end;
        end;
        if RenChanged then
        try
            RenSL.SaveToFile(RenPath);
        except
            if RenLog <> nil then
                RenLog.Add(RenPath);
        end;
    finally
        RenSL.Free;
    end;
end;

procedure RenFillFromProject;
var
    RenWS  : IWorkspace;
    RenPrj : IProject;
begin
    RenPrjFile := '';
    RenPrjDir := '';
    RenOldName := '';
    RenWS := GetWorkspace;
    if RenWS = nil then Exit;
    RenPrj := RenWS.DM_FocusedProject;
    if RenPrj = nil then Exit;
    try
        RenPrjFile := RenPrj.DM_ProjectFullPath;
    except
        RenPrjFile := '';
    end;
    if (RenPrjFile = '') or (Pos('*', RenPrjFile) > 0) then Exit;
    if not FileExists(RenPrjFile) then Exit;
    RenOldName := ChangeFileExt(ExtractFileName(RenPrjFile), '');
    RenPrjDir := RenEnsureSlash(ExtractFilePath(RenPrjFile));
end;

procedure RenTrySaveAll;
begin
    try
        ResetParameters;
        AddStringParameter('ObjectKind', 'Project');
        AddStringParameter('SaveMode', 'All');
        RunProcess('WorkspaceManager:SaveObject');
    except
    end;
end;

procedure RenTryClosePrj;
begin
    try
        ResetParameters;
        AddStringParameter('ObjectKind', 'Project');
        RunProcess('WorkspaceManager:CloseObject');
    except
    end;
end;

function RenTryOpenPrj(const RenPath : String) : Boolean;
var
    RenWS : IWorkspace;
begin
    Result := False;
    if (RenPath = '') or (not FileExists(RenPath)) then Exit;
    try
        RenWS := GetWorkspace;
        if RenWS <> nil then
        begin
            RenWS.DM_OpenProject(RenPath, True);
            Result := True;
        end;
    except
        Result := False;
    end;
    if Result then Exit;
    try
        Client.OpenDocument('PROJECT', RenPath);
        Result := True;
    except
        Result := False;
    end;
    if Result then Exit;
    try
        ResetParameters;
        AddStringParameter('ObjectKind', 'Project');
        AddStringParameter('FileName', RenPath);
        RunProcess('WorkspaceManager:OpenObject');
        Result := True;
    except
        Result := False;
    end;
end;

function RenJoinHead(RenL : TStringList; RenMax : Integer) : String;
var
    Reni, RenN : Integer;
begin
    Result := '';
    if RenL = nil then Exit;
    RenN := RenL.Count;
    if RenN > RenMax then RenN := RenMax;
    for Reni := 0 to RenN - 1 do
    begin
        if Result <> '' then Result := Result + sLineBreak;
        Result := Result + RenL.Strings[Reni];
    end;
    if RenL.Count > RenMax then
        Result := Result + sLineBreak + '... (' + IntToStr(RenL.Count) + ')';
end;

procedure RenCollectFolder(RenOldL, RenNewL : TStringList);
var
    RenFiles : TStringList;
    Reni : Integer;
    RenPath, RenRel, RenNewPath, RenDir : String;
begin
    if (not RenDoFolder) or (RenPrjDir = '') then Exit;
    RenFiles := TStringList.Create;
    try
        try
            GetAllFilePathsMatchingMask(RenFiles, RenEnsureSlash(RenPrjDir), '*.*', True);
        except
            Exit;
        end;
        if RenFiles.Count = 0 then Exit;
        for Reni := 0 to RenFiles.Count - 1 do
        begin
            RenPath := RenNormSlash(RenFiles.Strings[Reni]);
            RenRel := ExtractRelativePath(RenEnsureSlash(RenPrjDir), RenPath);
            if (RenRel = cFilename_CurrentDir) or (RenRel = cFilename_ParentDir) then
                Continue;
            if RenSkipRel(RenRel) then Continue;
            if not RenHasStem(RenPath, RenOldName) then Continue;
            RenDir := ExtractFilePath(RenPath);
            RenNewPath := RenDir + RenMapFileName(RenPath, RenOldName, RenNewName);
            RenAddPair(RenOldL, RenNewL, RenPath, RenNewPath);
        end;
    finally
        RenFiles.Free;
    end;
end;

procedure RenCollectRewriteTargets(RenTargets, RenOldL, RenNewL : TStringList);
var
    RenFiles : TStringList;
    Reni, RenIdx : Integer;
    RenPath, RenRel : String;
begin
    if RenPrjFile <> '' then
        if RenIndexOfCI(RenTargets, RenPrjFile) < 0 then
            RenTargets.Add(RenPrjFile);
    for Reni := 0 to RenNewL.Count - 1 do
        if RenIndexOfCI(RenTargets, RenNewL.Strings[Reni]) < 0 then
            RenTargets.Add(RenNewL.Strings[Reni]);
    for Reni := 0 to RenOldL.Count - 1 do
        if RenIndexOfCI(RenTargets, RenOldL.Strings[Reni]) < 0 then
            RenTargets.Add(RenOldL.Strings[Reni]);
    if RenPrjDir = '' then Exit;
    RenFiles := TStringList.Create;
    try
        try
            GetAllFilePathsMatchingMask(RenFiles, RenEnsureSlash(RenPrjDir), '*.*', True);
        except
            Exit;
        end;
        for Reni := 0 to RenFiles.Count - 1 do
        begin
            RenPath := RenNormSlash(RenFiles.Strings[Reni]);
            RenRel := ExtractRelativePath(RenEnsureSlash(RenPrjDir), RenPath);
            if (RenRel = cFilename_CurrentDir) or (RenRel = cFilename_ParentDir) then
                Continue;
            if RenSkipRel(RenRel) then Continue;
            if not RenIsTextExt(RenPath) then Continue;
            RenIdx := RenIndexOfCI(RenOldL, RenPath);
            if RenIdx >= 0 then
                RenPath := RenNewL.Strings[RenIdx];
            if RenIndexOfCI(RenTargets, RenPath) < 0 then
                RenTargets.Add(RenPath);
        end;
    finally
        RenFiles.Free;
    end;
end;

procedure RenDoRename;
var
    RenWS   : IWorkspace;
    RenPrj  : IProject;
    RenDoc  : IDocument;
    RenOldL, RenNewL, RenMapOld, RenMapNew, RenOkL, RenErrL, RenTargets : TStringList;
    Reni, RenN, RenIdx : Integer;
    RenPath, RenNewPath, RenDir, RenNewPrj, RenMsg : String;
    RenOk : Boolean;
begin
    RenOldL := TStringList.Create;
    RenNewL := TStringList.Create;
    RenMapOld := TStringList.Create;
    RenMapNew := TStringList.Create;
    RenOkL := TStringList.Create;
    RenErrL := TStringList.Create;
    RenTargets := TStringList.Create;
    try
        RenNewPrj := ExtractFilePath(RenPrjFile) + RenNewName + ExtractFileExt(RenPrjFile);
        RenAddPair(RenOldL, RenNewL, RenNormSlash(RenPrjFile), RenNormSlash(RenNewPrj));
        RenAddPair(RenMapOld, RenMapNew, RenNormSlash(RenPrjFile), RenNormSlash(RenNewPrj));

        if RenDoDocs then
        begin
            RenWS := GetWorkspace;
            RenPrj := nil;
            if RenWS <> nil then
            try
                RenPrj := RenWS.DM_FocusedProject;
            except
                RenPrj := nil;
            end;
            RenN := 0;
            if RenPrj <> nil then
            try
                RenN := RenPrj.DM_LogicalDocumentCount;
            except
                RenN := 0;
            end;
            for Reni := 0 to RenN - 1 do
            begin
                try
                    RenDoc := RenPrj.DM_LogicalDocuments(Reni);
                except
                    RenDoc := nil;
                end;
                if RenDoc = nil then Continue;
                RenPath := '';
                try RenPath := RenDoc.DM_FullPath; except RenPath := ''; end;
                if (RenPath = '') or (Pos('*', RenPath) > 0) then Continue;
                RenPath := RenNormSlash(RenPath);
                if not FileExists(RenPath) then Continue;
                if UpperCase(RenPath) = UpperCase(RenNormSlash(RenPrjFile)) then Continue;
                if not RenHasStem(RenPath, RenOldName) then Continue;
                RenDir := ExtractFilePath(RenPath);
                RenNewPath := RenDir + RenMapFileName(RenPath, RenOldName, RenNewName);
                RenAddPair(RenOldL, RenNewL, RenPath, RenNewPath);
            end;
        end;

        RenCollectFolder(RenOldL, RenNewL);
        RenSortByOldLen(RenOldL, RenNewL);

        RenTrySaveAll;
        RenTryClosePrj;

        for Reni := 0 to RenOldL.Count - 1 do
        begin
            RenPath := RenOldL.Strings[Reni];
            RenNewPath := RenNewL.Strings[Reni];
            if UpperCase(RenPath) = UpperCase(RenNormSlash(RenPrjFile)) then
                Continue;
            RenOk := RenTryRenameFile(RenPath, RenNewPath);
            if RenOk then
            begin
                RenOkL.Add(ExtractFileName(RenPath) + ' -> ' + ExtractFileName(RenNewPath));
                RenAddPair(RenMapOld, RenMapNew, RenPath, RenNewPath);
            end
            else
                RenErrL.Add(ExtractFileName(RenPath));
        end;

        RenSortByOldLen(RenMapOld, RenMapNew);
        RenCollectRewriteTargets(RenTargets, RenMapOld, RenMapNew);
        for Reni := 0 to RenTargets.Count - 1 do
        begin
            RenPath := RenTargets.Strings[Reni];
            RenIdx := RenIndexOfCI(RenMapOld, RenPath);
            if RenIdx >= 0 then
            begin
                if FileExists(RenMapNew.Strings[RenIdx]) then
                    RenPath := RenMapNew.Strings[RenIdx]
                else if not FileExists(RenPath) then
                    Continue;
            end;
            RenRewriteFile(RenPath, RenMapOld, RenMapNew, RenErrL);
        end;

        RenOk := RenTryRenameFile(RenNormSlash(RenPrjFile), RenNormSlash(RenNewPrj));
        if RenOk then
            RenOkL.Add(ExtractFileName(RenPrjFile) + ' -> ' + ExtractFileName(RenNewPrj))
        else
            RenErrL.Add(ExtractFileName(RenPrjFile));

        if RenOk then
        begin
            if not RenTryOpenPrj(RenNewPrj) then
                RenErrL.Add(RenLabelInfoOpen.Caption + ' ' + RenNewPrj);
        end;

        RenMsg := RenLabelInfoDone.Caption + sLineBreak + RenJoinHead(RenOkL, 25);
        if RenErrL.Count > 0 then
            RenMsg := RenMsg + sLineBreak + sLineBreak + RenLabelInfoErr.Caption +
                      sLineBreak + RenJoinHead(RenErrL, 15);
        RenShowBox(RenMsg);
    finally
        RenTargets.Free;
        RenErrL.Free;
        RenOkL.Free;
        RenMapNew.Free;
        RenMapOld.Free;
        RenNewL.Free;
        RenOldL.Free;
    end;
end;

procedure TFormRen.RenBtnBrowseClick(RenSender: TObject);
var
    RenDlg : TOpenDialog;
    RenFn, RenExt : String;
begin
    RenDlg := TOpenDialog.Create(nil);
    try
        RenDlg.Title := RenLabelDlgPrj.Caption;
        RenDlg.Filter := 'Altium (*.PrjPcb;*.PrjSch;*.PrjScr)|*.PrjPcb;*.PrjSch;*.PrjScr|All (*.*)|*.*';
        try RenDlg.InitialDir := RenPrjDir; except end;
        if RenDlg.Execute then
        begin
            RenFn := RenDlg.FileName;
            RenExt := UpperCase(ExtractFileExt(RenFn));
            if (RenExt = '.PRJPCB') or (RenExt = '.PRJSCH') or (RenExt = '.PRJSCR') or
               (RenExt = '.PRJLIB') then
            begin
                RenPrjFile := RenFn;
                RenOldName := ChangeFileExt(ExtractFileName(RenFn), '');
                RenPrjDir := RenEnsureSlash(ExtractFilePath(RenFn));
                RenEditPath.Text := RenPrjFile;
                RenEditOld.Text := RenOldName;
                if RenEditNew.Text = '' then
                    RenEditNew.Text := RenOldName;
            end;
        end;
    finally
        RenDlg.Free;
    end;
end;

procedure TFormRen.RenButtonOKClick(RenSender: TObject);
begin
    RenPrjFile := RenTrimName(RenEditPath.Text);
    RenOldName := RenTrimName(RenEditOld.Text);
    RenNewName := RenTrimName(RenEditNew.Text);
    RenDoDocs := RenCheckDocs.Checked;
    RenDoFolder := RenCheckFolder.Checked;
    RenDoOld := RenCheckOld.Checked;

    if (RenPrjFile = '') or (Pos('*', RenPrjFile) > 0) then
    begin
        if Pos('*', RenPrjFile) > 0 then
            RenShowBox(RenLabelErrUnsaved.Caption)
        else
            RenShowBox(RenLabelErrPrj.Caption);
        Exit;
    end;
    if not FileExists(RenPrjFile) then
    begin
        RenShowBox(RenLabelErrMissing.Caption);
        Exit;
    end;
    if RenOldName = '' then
        RenOldName := ChangeFileExt(ExtractFileName(RenPrjFile), '');
    RenPrjDir := RenEnsureSlash(ExtractFilePath(RenPrjFile));

    if (RenNewName = '') or (UpperCase(RenNewName) = UpperCase(RenOldName)) then
    begin
        RenShowBox(RenLabelErrName.Caption);
        Exit;
    end;
    if not RenNameOk(RenNewName) then
    begin
        RenShowBox(RenLabelErrChars.Caption);
        Exit;
    end;

    if not ConfirmNoYes(RenLabelAsk.Caption + sLineBreak + RenOldName + ' -> ' + RenNewName) then
        Exit;

    ButtonOK.Enabled := False;
    ButtonCancel.Enabled := False;
    RenBtnBrowse.Enabled := False;
    RenLabelProg.Caption := RenLabelBusy.Caption;
    RenUiRefresh;

    RenDoRename;

    RenLabelProg.Caption := RenLabelReady.Caption;
    ButtonOK.Enabled := True;
    ButtonCancel.Enabled := True;
    RenBtnBrowse.Enabled := True;
    RenUiRefresh;
    FormRen.Close;
end;

procedure TFormRen.RenButtonCancelClick(RenSender: TObject);
begin
    FormRen.Close;
end;

function RenCS_ScriptFolder : String;
var
    RenWS  : IWorkspace;
    RenPrj : IProject;
    Reni   : Integer;
    RenP, RenName : String;
begin
    Result := '';
    try
        RenWS := GetWorkspace;
        if RenWS = nil then Exit;
        for Reni := 0 to RenWS.DM_ProjectCount - 1 do
        begin
            RenPrj := RenWS.DM_Projects(Reni);
            if RenPrj = nil then Continue;
            RenP := RenPrj.DM_ProjectFullPath;
            RenName := UpperCase(ExtractFileName(RenP));
            if RenName = 'PROJECTRENAMER.PRJSCR' then
            begin
                Result := ExtractFilePath(RenP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function RenCS_FindImageFile(const RenFileName : String) : String;
var
    RenDir, RenP : String;
begin
    Result := '';
    RenDir := RenCS_ScriptFolder;
    if RenDir <> '' then
    begin
        RenP := RenDir + RenFileName;
        if FileExists(RenP) then begin Result := RenP; Exit; end;
        RenP := RenDir + 'images\' + RenFileName;
        if FileExists(RenP) then begin Result := RenP; Exit; end;
    end;
    if FileExists(RenFileName) then begin Result := RenFileName; Exit; end;
    RenP := 'images\' + RenFileName;
    if FileExists(RenP) then Result := RenP;
end;

procedure RenCS_TryOneHelpFile(const RenName : String; var RenDone : Boolean);
var
    RenP : String;
begin
    if RenDone then Exit;
    RenP := RenCS_FindImageFile(RenName);
    if (RenP = '') or (not FileExists(RenP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(RenP);
        ImageHelp.Stretch := True;
        try ImageHelp.Proportional := True; except end;
        try ImageHelp.Center := True; except end;
        LabelImageHint.Caption := '';
        RenDone := True;
    except
    end;
end;

procedure RenCS_TryLoadHelpImage(const RenBmpName : String; const RenPngName : String);
var
    RenDone : Boolean;
begin
    RenDone := False;
    RenCS_TryOneHelpFile(RenPngName, RenDone);
    RenCS_TryOneHelpFile(RenBmpName, RenDone);
    RenCS_TryOneHelpFile('ProjectRenamer.png', RenDone);
    RenCS_TryOneHelpFile('ProjectRenamer.bmp', RenDone);
    if not RenDone then
        LabelImageHint.Caption := 'No image. Put ' + RenPngName + ' next to the script or in images\.';
end;

procedure TFormRen.FormRenShow(RenSender: TObject);
begin
    try
        RenCS_TryLoadHelpImage('ProjectRenamer.bmp', 'ProjectRenamer.png');
    except
    end;
    RenFillFromProject;
    RenEditPath.Text := RenPrjFile;
    RenEditOld.Text := RenOldName;
    RenEditNew.Text := RenOldName;
    RenCheckDocs.Checked := True;
    RenCheckFolder.Checked := False;
    RenCheckOld.Checked := False;
    RenLabelProg.Caption := '';
    try RenEditNew.SetFocus; except end;
end;

procedure StartProjectRenamer;
begin
    FormRen.ShowModal;
end;

procedure _StartProjectRenamer;
begin
    StartProjectRenamer;
end;
