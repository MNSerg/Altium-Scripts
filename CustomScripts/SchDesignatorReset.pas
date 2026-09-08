{..............................................................................}
{ SchDesignatorReset.pas                                                        }
{ Запись через IDocument.DM_Components (как Auto_Panelizer: DM_LogicalDocuments). }
{ Без *Iterator*. Assign DM_LogicalDesignator.                                  }
{..............................................................................}

var
    DoReset     : Boolean;
    DoAnnotate  : Boolean;
    AllSheets   : Boolean;
    ChangedCnt  : Integer;
    PrefixCounters : TStringList;
    SampleNames : TStringList;

{ Run Script: choose procedure StartSchDesignatorReset (project compiles only this .pas). }
procedure StartSchDesignatorReset; forward;
procedure _StartSchDesignatorReset; forward;
procedure TFormAnnot.ButtonOKClick(SchSender: TObject); forward;
procedure TFormAnnot.ButtonCancelClick(SchSender: TObject); forward;
procedure TFormAnnot.FormAnnotShow(SchSender: TObject); forward;

procedure SchShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

function SchAskYesNo(const Msg : String) : Boolean;
begin
    Result := ConfirmNoYes(Msg);
end;

function SchPadNum(SchN, SchWidth : Integer) : String;
begin
    Result := IntToStr(SchN);
    while Length(Result) < SchWidth do
        Result := '0' + Result;
end;

function SchPrefixOf(const SchDes : String) : String;
var
    Schi : Integer;
    SchC : Char;
begin
    Result := '';
    for Schi := 1 to Length(SchDes) do
    begin
        SchC := SchDes[Schi];
        if ((SchC >= 'A') and (SchC <= 'Z')) or ((SchC >= 'a') and (SchC <= 'z')) then
            Result := Result + SchC
        else
            Break;
    end;
    if Result = '' then Result := 'U';
end;

function SchReadDes(SchComp : IComponent) : String;
begin
    Result := '';
    try Result := SchComp.DM_LogicalDesignator; except Result := ''; end;
    if Result = '' then
        try Result := SchComp.DM_PhysicalDesignator; except Result := ''; end;
end;

function SchWriteDes(SchComp : IComponent; const NewT : String) : Boolean;
var
    Got : String;
begin
    Result := False;
    try
        SchComp.DM_LogicalDesignator := NewT;
        Got := '';
        try Got := SchComp.DM_LogicalDesignator; except Got := ''; end;
        if Got = NewT then Result := True;
    except
        Result := False;
    end;
    if Result then Exit;
    try
        SchComp.DM_PhysicalDesignator := NewT;
        Got := '';
        try Got := SchComp.DM_PhysicalDesignator; except Got := ''; end;
        if Got = NewT then Result := True;
    except
        Result := False;
    end;
end;

function SchNextNum(const Prefix : String) : Integer;
var
    SchIdx : Integer;
begin
    SchIdx := PrefixCounters.IndexOfName(Prefix);
    if SchIdx < 0 then
    begin
        Result := 1;
        PrefixCounters.Add(Prefix + '=1');
    end
    else
    begin
        Result := StrToInt(PrefixCounters.ValueFromIndex[SchIdx]) + 1;
        PrefixCounters.ValueFromIndex[SchIdx] := IntToStr(Result);
    end;
end;

procedure SchAnnotateLogDoc(SchLogDoc : IDocument);
var
    Schi, Schn : Integer;
    SchComp : IComponent;
    OldT, NewT, Pref : String;
begin
    if SchLogDoc = nil then Exit;
    try
        Schn := SchLogDoc.DM_ComponentCount;
    except
        Schn := 0;
    end;
    for Schi := 0 to Schn - 1 do
    begin
        SchComp := SchLogDoc.DM_Components(Schi);
        if SchComp = nil then Continue;
        OldT := SchReadDes(SchComp);
        Pref := SchPrefixOf(OldT);
        if DoReset and (not DoAnnotate) then
            NewT := Pref + '?'
        else if DoAnnotate then
            NewT := Pref + IntToStr(SchNextNum(Pref))
        else
            NewT := OldT;
        if NewT = OldT then Continue;
        if SchWriteDes(SchComp, NewT) then
        begin
            Inc(ChangedCnt);
            if SampleNames.Count < 5 then
                SampleNames.Add(OldT + ' -> ' + NewT);
        end;
    end;
end;

procedure SchTryRunAnnotate(const SchPath : String);
begin
    try
        Client.OpenDocument('SCH', SchPath);
    except
    end;
    try
        ResetParameters;
        AddStringParameter('Action', 'ReAnnotate');
        RunProcess('Sch:Annotate');
    except
    end;
end;

procedure ProcessDocuments;
var
    SchWS : IWorkspace;
    SchProject : IProject;
    Schi : Integer;
    SchLogDoc : IDocument;
    SchKind, SchPath, Msg : String;
    Current : IDocument;
    SheetCnt : Integer;
begin
    ChangedCnt := 0;
    SheetCnt := 0;

    SchWS := GetWorkspace;
    if SchWS = nil then Exit;
    SchProject := SchWS.DM_FocusedProject;
    try
        Current := SchWS.DM_FocusedDocument;
    except
        Current := nil;
    end;

    if AllSheets then
    begin
        if SchProject = nil then
        begin
            SchShowBox(LabelErrPrj.Caption, 16);
            Exit;
        end;
        if not SchAskYesNo(LabelAskAll.Caption) then
            Exit;
    end;

    PrefixCounters := TStringList.Create;
    SampleNames := TStringList.Create;
    try
        PrefixCounters.NameValueSeparator := '=';

        if AllSheets and (SchProject <> nil) then
        begin
            for Schi := 0 to SchProject.DM_LogicalDocumentCount - 1 do
            begin
                SchLogDoc := SchProject.DM_LogicalDocuments(Schi);
                SchKind := '';
                try SchKind := SchLogDoc.DM_DocumentKind; except SchKind := ''; end;
                if (SchKind = 'SCH') or (SchKind = 'SCHDOC') then
                begin
                    Inc(SheetCnt);
                    SchPath := '';
                    try SchPath := SchLogDoc.DM_FullPath; except SchPath := ''; end;
                    SchTryRunAnnotate(SchPath);
                    SchAnnotateLogDoc(SchLogDoc);
                end;
            end;
            if SheetCnt = 0 then
                SchShowBox(LabelWarnSheets.Caption, 48)
            else if ChangedCnt = 0 then
                SchShowBox(LabelErrApi.Caption, 16)
            else
            begin
                Msg := LabelInfoDone.Caption + IntToStr(ChangedCnt);
                if SampleNames.Count > 0 then
                    Msg := Msg + sLineBreak + LabelInfoSample.Caption + SampleNames.CommaText;
                SchShowBox(Msg, 64);
            end;
        end
        else
        begin
            if Current = nil then
            begin
                SchShowBox(LabelErrDoc.Caption, 16);
                Exit;
            end;
            SchKind := '';
            try SchKind := Current.DM_DocumentKind; except SchKind := ''; end;
            SchPath := '';
            try SchPath := Current.DM_FullPath; except SchPath := ''; end;
            if (SchKind = 'SCH') or (SchKind = 'SCHDOC') then
            begin
                SchTryRunAnnotate(SchPath);
                SchAnnotateLogDoc(Current);
            end;
            if ChangedCnt = 0 then
                SchShowBox(LabelErrApi.Caption, 16)
            else
            begin
                Msg := LabelInfoDone.Caption + IntToStr(ChangedCnt);
                if SampleNames.Count > 0 then
                    Msg := Msg + sLineBreak + LabelInfoSample.Caption + SampleNames.CommaText;
                SchShowBox(Msg, 64);
            end;
        end;
    finally
        PrefixCounters.Free;
        PrefixCounters := nil;
        SampleNames.Free;
        SampleNames := nil;
    end;
end;

procedure TFormAnnot.ButtonOKClick(SchSender: TObject);
begin
    DoReset := CheckReset.Checked;
    DoAnnotate := CheckAnnotate.Checked;
    AllSheets := CheckAllSheets.Checked;
    if (not DoReset) and (not DoAnnotate) then
    begin
        SchShowBox(LabelWarnChoose.Caption, 48);
        Exit;
    end;
    FormAnnot.Close;
    ProcessDocuments;
end;

procedure TFormAnnot.ButtonCancelClick(SchSender: TObject);
begin
    FormAnnot.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function SchCS_ScriptFolder : String;
var
    SchWS  : IWorkspace;
    SchPrj : IProject;
    Schi   : Integer;
    SchP, SchName : String;
begin
    Result := '';
    try
        SchWS := GetWorkspace;
        if SchWS = nil then Exit;
        for Schi := 0 to SchWS.DM_ProjectCount - 1 do
        begin
            SchPrj := SchWS.DM_Projects(Schi);
            if SchPrj = nil then Continue;
            SchP := SchPrj.DM_ProjectFullPath;
            SchName := UpperCase(ExtractFileName(SchP));
            if SchName = 'SCHDESIGNATORRESET.PRJSCR' then
            begin
                Result := ExtractFilePath(SchP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function SchCS_FindImageFile(const SchFileName : String) : String;
var
    SchDir, SchP : String;
begin
    Result := '';
    SchDir := SchCS_ScriptFolder;
    if SchDir <> '' then
    begin
        SchP := SchDir + SchFileName;
        if FileExists(SchP) then begin Result := SchP; Exit; end;
        SchP := SchDir + 'images\' + SchFileName;
        if FileExists(SchP) then begin Result := SchP; Exit; end;
    end;
    if FileExists(SchFileName) then begin Result := SchFileName; Exit; end;
    SchP := 'images\' + SchFileName;
    if FileExists(SchP) then Result := SchP;
end;

procedure SchCS_TryOneHelpFile(const SchName : String; var SchDone : Boolean);
var
    SchP : String;
begin
    if SchDone then Exit;
    SchP := SchCS_FindImageFile(SchName);
    if (SchP = '') or (not FileExists(SchP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(SchP);
        ImageHelp.Stretch := True;
        try
            ImageHelp.Proportional := True;
        except
        end;
        try
            ImageHelp.Center := True;
        except
        end;
        LabelImageHint.Caption := '';
        SchDone := True;
    except
    end;
end;

procedure SchCS_TryLoadHelpImage(const SchBmpName : String; const SchPngName : String);
var
    SchDone : Boolean;
begin
    SchDone := False;
    SchCS_TryOneHelpFile(SchPngName, SchDone);
    SchCS_TryOneHelpFile(SchBmpName, SchDone);
    SchCS_TryOneHelpFile('SchDesignatorReset.png', SchDone);
    SchCS_TryOneHelpFile('SchDesignatorReset.bmp', SchDone);
    if not SchDone then
        LabelImageHint.Caption := 'No image. Put ' + SchPngName + ' next to the script or in images\.';
end;


procedure TFormAnnot.FormAnnotShow(SchSender: TObject);
begin
    try
        SchCS_TryLoadHelpImage('SchAnnotate.bmp', 'SchAnnotate.png');
    except
    end;
    CheckAnnotate.Checked := True;
    CheckAllSheets.Checked := True;
end;

procedure StartSchDesignatorReset;
begin
    FormAnnot.ShowModal;
end;

procedure _StartSchDesignatorReset;
begin
    StartSchDesignatorReset;
end;
