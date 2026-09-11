{..............................................................................}
{ ProjectRenamer.pas                                                            }
{ Rename focused project + DM_LogicalDocuments. Modes: increment trailing vN/VN }
{ or full new stem. Sheets always NewStem_ShN. Do not patch sheet symbols.      }
{ Prefix Ren*. No OLE, no PChar, no Val, no rfReplaceAll.                       }
{..............................................................................}

var
    RenPrjFile     : String;
    RenPrjDir      : String;
    RenOldName     : String;
    RenNewName     : String;
    RenIncMode     : Boolean;
    RenPreviewBusy : Boolean;

procedure StartProjectRenamer; forward;
procedure _StartProjectRenamer; forward;
procedure TFormRen.RenButtonOKClick(RenSender: TObject); forward;
procedure TFormRen.RenButtonCancelClick(RenSender: TObject); forward;
procedure TFormRen.FormRenShow(RenSender: TObject); forward;
procedure TFormRen.RenBtnBrowseClick(RenSender: TObject); forward;
procedure TFormRen.RenRadioIncClick(RenSender: TObject); forward;
procedure TFormRen.RenRadioFullClick(RenSender: TObject); forward;
procedure TFormRen.RenEditNewChange(RenSender: TObject); forward;
procedure RenUpdatePreview; forward;
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

{ Trailing v/V + integer on the stem. Widget_v2 -> prefix Widget_, letter v, N=2. }
function RenParseVN(const RenStem : String; var RenPrefix, RenLetter : String;
                    var RenN : Integer) : Boolean;
var
    RenLen, RenI, RenJ, RenDigits : Integer;
    RenCh : String;
begin
    Result := False;
    RenPrefix := '';
    RenLetter := '';
    RenN := 0;
    RenLen := Length(RenStem);
    if RenLen < 2 then Exit;
    RenI := RenLen;
    RenDigits := 0;
    while (RenI >= 1) and (RenStem[RenI] >= '0') and (RenStem[RenI] <= '9') do
    begin
        Inc(RenDigits);
        RenI := RenI - 1;
    end;
    if (RenDigits < 1) or (RenDigits > 9) then Exit;
    if RenI < 1 then Exit;
    RenCh := Copy(RenStem, RenI, 1);
    if (RenCh <> 'v') and (RenCh <> 'V') then Exit;
    RenPrefix := Copy(RenStem, 1, RenI - 1);
    RenLetter := RenCh;
    RenN := 0;
    for RenJ := RenI + 1 to RenLen do
        RenN := RenN * 10 + (Ord(RenStem[RenJ]) - Ord('0'));
    Result := True;
end;

function RenTryIncStem(const RenOld : String; var RenNew : String) : Boolean;
var
    RenPrefix, RenLetter : String;
    RenN : Integer;
begin
    Result := False;
    RenNew := '';
    if not RenParseVN(RenOld, RenPrefix, RenLetter, RenN) then Exit;
    RenNew := RenPrefix + RenLetter + IntToStr(RenN + 1);
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

function RenIsSchDoc(const RenKind, RenPath : String) : Boolean;
var
    RenK, RenE : String;
begin
    RenK := UpperCase(RenKind);
    RenE := UpperCase(ExtractFileExt(RenPath));
    Result := (RenK = 'SCH') or (RenK = 'SCHDOC') or (RenE = '.SCHDOC');
end;

function RenIsPcbDoc(const RenKind, RenPath : String) : Boolean;
var
    RenK, RenE : String;
begin
    RenK := UpperCase(RenKind);
    RenE := UpperCase(ExtractFileExt(RenPath));
    Result := (RenK = 'PCB') or (RenK = 'PCBDOC') or (RenE = '.PCBDOC');
end;

function RenIsOutJob(const RenKind, RenPath : String) : Boolean;
var
    RenK, RenE : String;
begin
    RenK := UpperCase(RenKind);
    RenE := UpperCase(ExtractFileExt(RenPath));
    Result := (RenK = 'OUTJOB') or (RenE = '.OUTJOB');
end;

function RenIsPatchExt(const RenPath : String) : Boolean;
var
    RenE : String;
begin
    RenE := UpperCase(ExtractFileExt(RenPath));
    Result := (RenE = '.PRJPCB') or (RenE = '.PRJSCH') or (RenE = '.PRJSCR') or
              (RenE = '.OUTJOB');
end;

function RenOtherTag(const RenKind, RenPath : String) : String;
var
    RenK, RenE : String;
begin
    RenK := UpperCase(RenKind);
    RenE := UpperCase(ExtractFileExt(RenPath));
    if (RenK = 'OUTJOB') or (RenE = '.OUTJOB') then Result := 'OutJob'
    else if (RenK = 'SCHLIB') or (RenE = '.SCHLIB') then Result := 'SchLib'
    else if (RenK = 'PCBLIB') or (RenE = '.PCBLIB') then Result := 'PcbLib'
    else if (RenK = 'HARNESS') or (RenE = '.HARNESS') then Result := 'Harness'
    else if Length(RenE) > 1 then Result := Copy(RenE, 2, Length(RenE))
    else Result := 'Doc';
end;

function RenCountClass(RenPaths, RenKinds : TStringList; const RenClass : String) : Integer;
var
    Reni : Integer;
    RenKind, RenPath : String;
begin
    Result := 0;
    for Reni := 0 to RenPaths.Count - 1 do
    begin
        RenPath := RenPaths.Strings[Reni];
        RenKind := RenKinds.Strings[Reni];
        if (RenClass = 'SCH') and RenIsSchDoc(RenKind, RenPath) then Inc(Result)
        else if (RenClass = 'PCB') and RenIsPcbDoc(RenKind, RenPath) then Inc(Result);
    end;
end;

function RenCountTag(RenPaths, RenKinds : TStringList; const RenTag : String) : Integer;
var
    Reni : Integer;
    RenKind, RenPath : String;
begin
    Result := 0;
    for Reni := 0 to RenPaths.Count - 1 do
    begin
        RenPath := RenPaths.Strings[Reni];
        RenKind := RenKinds.Strings[Reni];
        if RenIsSchDoc(RenKind, RenPath) then Continue;
        if RenIsPcbDoc(RenKind, RenPath) then Continue;
        if RenOtherTag(RenKind, RenPath) = RenTag then Inc(Result);
    end;
end;

function RenTagIndexUpTo(RenPaths, RenKinds : TStringList; RenUpTo : Integer;
                         const RenTag : String) : Integer;
var
    Reni : Integer;
    RenKind, RenPath : String;
begin
    Result := 0;
    for Reni := 0 to RenUpTo do
    begin
        RenPath := RenPaths.Strings[Reni];
        RenKind := RenKinds.Strings[Reni];
        if RenIsSchDoc(RenKind, RenPath) then Continue;
        if RenIsPcbDoc(RenKind, RenPath) then Continue;
        if RenOtherTag(RenKind, RenPath) = RenTag then Inc(Result);
    end;
end;

function RenTakeName(RenUsed : TStringList; const RenCandidate : String) : String;
var
    RenI : Integer;
    RenBase, RenExt, RenTry : String;
begin
    if RenIndexOfCI(RenUsed, RenCandidate) < 0 then
    begin
        RenUsed.Add(RenCandidate);
        Result := RenCandidate;
        Exit;
    end;
    RenExt := ExtractFileExt(RenCandidate);
    RenBase := ChangeFileExt(RenCandidate, '');
    RenI := 2;
    RenTry := RenBase + '_' + IntToStr(RenI) + RenExt;
    while (RenIndexOfCI(RenUsed, RenTry) >= 0) and (RenI < 999) do
    begin
        Inc(RenI);
        RenTry := RenBase + '_' + IntToStr(RenI) + RenExt;
    end;
    RenUsed.Add(RenTry);
    Result := RenTry;
end;

function RenNewDocName(const RenPath, RenKind, RenStem : String;
                       RenPaths, RenKinds, RenUsed : TStringList;
                       RenIdx, RenSchN, RenPcbN, RenSchTotal, RenPcbTotal : Integer) : String;
var
    RenExt, RenTag, RenCand : String;
    RenTagTotal, RenTagN : Integer;
begin
    RenExt := ExtractFileExt(RenPath);
    if RenIsSchDoc(RenKind, RenPath) then
        RenCand := RenStem + '_Sh' + IntToStr(RenSchN) + RenExt
    else if RenIsPcbDoc(RenKind, RenPath) then
    begin
        if RenPcbTotal <= 1 then
            RenCand := RenStem + RenExt
        else
            RenCand := RenStem + '_Pcb' + IntToStr(RenPcbN) + RenExt;
    end
    else
    begin
        RenTag := RenOtherTag(RenKind, RenPath);
        RenTagTotal := RenCountTag(RenPaths, RenKinds, RenTag);
        RenTagN := RenTagIndexUpTo(RenPaths, RenKinds, RenIdx, RenTag);
        if RenTagTotal <= 1 then
            RenCand := RenStem + RenExt
        else
            RenCand := RenStem + '_' + RenTag + IntToStr(RenTagN) + RenExt;
        if RenIndexOfCI(RenUsed, RenCand) >= 0 then
            RenCand := RenStem + '_' + RenTag + RenExt;
        if RenIndexOfCI(RenUsed, RenCand) >= 0 then
            RenCand := RenStem + '_' + ChangeFileExt(ExtractFileName(RenPath), '') + RenExt;
    end;
    Result := RenTakeName(RenUsed, RenCand);
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

function RenTempName(const RenPath : String; RenI : Integer) : String;
var
    RenDir, RenExt : String;
    RenN : Integer;
begin
    RenDir := ExtractFilePath(RenPath);
    RenExt := ExtractFileExt(RenPath);
    RenN := RenI;
    Result := RenDir + '__ren' + IntToStr(RenN) + RenExt;
    while FileExists(Result) do
    begin
        Inc(RenN);
        Result := RenDir + '__ren' + IntToStr(RenN) + RenExt;
        if RenN > RenI + 500 then Exit;
    end;
end;

function RenFileLooksText(const RenPath : String) : Boolean;
var
    RenF : File;
    RenChunk : String;
    Reni, RenN : Integer;
begin
    Result := False;
    if not FileExists(RenPath) then Exit;
    if not RenIsPatchExt(RenPath) then Exit;
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

procedure RenUpdatePreview;
var
    RenOld, RenNew : String;
begin
    if RenPreviewBusy then Exit;
    RenPreviewBusy := True;
    try
        RenOld := RenTrimName(RenEditOld.Text);
        if RenRadioInc.Checked then
        begin
            try RenEditNew.ReadOnly := True; except end;
            if RenTryIncStem(RenOld, RenNew) then
            begin
                if RenEditNew.Text <> RenNew then
                    RenEditNew.Text := RenNew;
                RenLabelPreview.Caption := RenLabelWill.Caption + ' ' + RenOld + ' -> ' + RenNew;
            end
            else
            begin
                if RenEditNew.Text <> '' then
                    RenEditNew.Text := '';
                RenLabelPreview.Caption := RenLabelErrNoVN.Caption;
            end;
        end
        else
        begin
            try RenEditNew.ReadOnly := False; except end;
            RenNew := RenTrimName(RenEditNew.Text);
            if RenNew <> '' then
                RenLabelPreview.Caption := RenLabelWill.Caption + ' ' + RenOld + ' -> ' + RenNew
            else
                RenLabelPreview.Caption := RenLabelWill.Caption;
        end;
    finally
        RenPreviewBusy := False;
    end;
end;

procedure RenDoRename;
var
    RenWS   : IWorkspace;
    RenPrj  : IProject;
    RenDoc  : IDocument;
    RenPaths, RenKinds, RenUsed, RenOldL, RenNewL, RenMapOld, RenMapNew : TStringList;
    RenOkL, RenErrL, RenTemps : TStringList;
    Reni, RenN, RenSchTotal, RenPcbTotal, RenSchN, RenPcbN : Integer;
    RenPath, RenKind, RenNewFn, RenNewPath, RenNewPrj, RenTmp, RenMsg : String;
    RenOk : Boolean;
begin
    RenPaths := TStringList.Create;
    RenKinds := TStringList.Create;
    RenUsed := TStringList.Create;
    RenOldL := TStringList.Create;
    RenNewL := TStringList.Create;
    RenMapOld := TStringList.Create;
    RenMapNew := TStringList.Create;
    RenOkL := TStringList.Create;
    RenErrL := TStringList.Create;
    RenTemps := TStringList.Create;
    try
        RenNewPrj := ExtractFilePath(RenPrjFile) + RenNewName + ExtractFileExt(RenPrjFile);
        RenUsed.Add(ExtractFileName(RenNewPrj));
        RenAddPair(RenOldL, RenNewL, RenNormSlash(RenPrjFile), RenNormSlash(RenNewPrj));
        RenAddPair(RenMapOld, RenMapNew, RenNormSlash(RenPrjFile), RenNormSlash(RenNewPrj));

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
            RenKind := '';
            try RenKind := RenDoc.DM_DocumentKind; except RenKind := ''; end;
            RenPaths.Add(RenPath);
            RenKinds.Add(RenKind);
        end;

        RenSchTotal := RenCountClass(RenPaths, RenKinds, 'SCH');
        RenPcbTotal := RenCountClass(RenPaths, RenKinds, 'PCB');
        RenSchN := 0;
        RenPcbN := 0;
        for Reni := 0 to RenPaths.Count - 1 do
        begin
            RenPath := RenPaths.Strings[Reni];
            RenKind := RenKinds.Strings[Reni];
            if RenIsSchDoc(RenKind, RenPath) then Inc(RenSchN);
            if RenIsPcbDoc(RenKind, RenPath) then Inc(RenPcbN);
            RenNewFn := RenNewDocName(RenPath, RenKind, RenNewName, RenPaths, RenKinds,
                                     RenUsed, Reni, RenSchN, RenPcbN, RenSchTotal, RenPcbTotal);
            RenNewPath := ExtractFilePath(RenPath) + RenNewFn;
            RenAddPair(RenOldL, RenNewL, RenPath, RenNewPath);
        end;

        for Reni := 0 to RenOldL.Count - 1 do
        begin
            RenNewPath := RenNewL.Strings[Reni];
            if FileExists(RenNewPath) and
               (RenIndexOfCI(RenOldL, RenNewPath) < 0) then
                RenErrL.Add(ExtractFileName(RenNewPath));
        end;
        if RenErrL.Count > 0 then
        begin
            RenShowBox(RenLabelInfoErr.Caption + sLineBreak + RenJoinHead(RenErrL, 15));
            Exit;
        end;

        RenTrySaveAll;
        RenTryClosePrj;

        for Reni := 0 to RenOldL.Count - 1 do
        begin
            RenPath := RenOldL.Strings[Reni];
            if UpperCase(RenPath) = UpperCase(RenNormSlash(RenPrjFile)) then
            begin
                RenTemps.Add('');
                Continue;
            end;
            RenTmp := RenTempName(RenPath, Reni);
            RenOk := RenTryRenameFile(RenPath, RenTmp);
            if RenOk then
                RenTemps.Add(RenTmp)
            else
            begin
                RenTemps.Add('');
                RenErrL.Add(ExtractFileName(RenPath));
            end;
        end;

        for Reni := 0 to RenOldL.Count - 1 do
        begin
            if UpperCase(RenOldL.Strings[Reni]) = UpperCase(RenNormSlash(RenPrjFile)) then
                Continue;
            RenTmp := '';
            if Reni < RenTemps.Count then
                RenTmp := RenTemps.Strings[Reni];
            if RenTmp = '' then Continue;
            RenNewPath := RenNewL.Strings[Reni];
            RenOk := RenTryRenameFile(RenTmp, RenNewPath);
            if RenOk then
            begin
                RenOkL.Add(ExtractFileName(RenOldL.Strings[Reni]) + ' -> ' + ExtractFileName(RenNewPath));
                RenAddPair(RenMapOld, RenMapNew, RenOldL.Strings[Reni], RenNewPath);
            end
            else
            begin
                RenErrL.Add(ExtractFileName(RenOldL.Strings[Reni]));
                RenTryRenameFile(RenTmp, RenOldL.Strings[Reni]);
            end;
        end;

        RenSortByOldLen(RenMapOld, RenMapNew);
        RenRewriteFile(RenNormSlash(RenPrjFile), RenMapOld, RenMapNew, RenErrL);
        for Reni := 0 to RenMapOld.Count - 1 do
        begin
            RenNewPath := RenMapNew.Strings[Reni];
            if RenIsPatchExt(RenNewPath) and
               (UpperCase(ExtractFileExt(RenNewPath)) = '.OUTJOB') then
            begin
                if FileExists(RenNewPath) then
                    RenRewriteFile(RenNewPath, RenMapOld, RenMapNew, RenErrL)
                else if FileExists(RenMapOld.Strings[Reni]) then
                    RenRewriteFile(RenMapOld.Strings[Reni], RenMapOld, RenMapNew, RenErrL);
            end;
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
        RenTemps.Free;
        RenErrL.Free;
        RenOkL.Free;
        RenMapNew.Free;
        RenMapOld.Free;
        RenNewL.Free;
        RenOldL.Free;
        RenUsed.Free;
        RenKinds.Free;
        RenPaths.Free;
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
                RenUpdatePreview;
            end;
        end;
    finally
        RenDlg.Free;
    end;
end;

procedure TFormRen.RenRadioIncClick(RenSender: TObject);
begin
    RenUpdatePreview;
end;

procedure TFormRen.RenRadioFullClick(RenSender: TObject);
begin
    RenUpdatePreview;
    try RenEditNew.SetFocus; except end;
end;

procedure TFormRen.RenEditNewChange(RenSender: TObject);
begin
    if not RenRadioInc.Checked then
        RenUpdatePreview;
end;

procedure TFormRen.RenButtonOKClick(RenSender: TObject);
var
    RenIncNew : String;
begin
    RenPrjFile := RenTrimName(RenEditPath.Text);
    RenOldName := RenTrimName(RenEditOld.Text);
    RenIncMode := RenRadioInc.Checked;

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

    if RenIncMode then
    begin
        if not RenTryIncStem(RenOldName, RenIncNew) then
        begin
            RenShowBox(RenLabelErrNoVN.Caption);
            Exit;
        end;
        RenNewName := RenIncNew;
    end
    else
        RenNewName := RenTrimName(RenEditNew.Text);

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
    RenRadioInc.Enabled := False;
    RenRadioFull.Enabled := False;
    RenLabelProg.Caption := RenLabelBusy.Caption;
    RenUiRefresh;

    RenDoRename;

    RenLabelProg.Caption := RenLabelReady.Caption;
    ButtonOK.Enabled := True;
    ButtonCancel.Enabled := True;
    RenBtnBrowse.Enabled := True;
    RenRadioInc.Enabled := True;
    RenRadioFull.Enabled := True;
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
    RenRadioInc.Checked := True;
    RenRadioFull.Checked := False;
    RenLabelProg.Caption := '';
    RenUpdatePreview;
end;

procedure StartProjectRenamer;
begin
    FormRen.ShowModal;
end;

procedure _StartProjectRenamer;
begin
    StartProjectRenamer;
end;
