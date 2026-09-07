{..............................................................................}
{ SchDesignatorReset.pas                                                        }
{ Запись десигнаторов: CreateSchIterator + GetState_SchDesignator.Text.        }
{ Down then Across, весь проект.                                                }
{..............................................................................}

var
    DoReset     : Boolean;
    DoAnnotate  : Boolean;
    AllSheets   : Boolean;
    ChangedCnt  : Integer;
    PrefixCounters : TStringList;

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

function SchReadDes(SchComp : ISch_Component) : String;
begin
    Result := '';
    try
        Result := SchComp.GetState_SchDesignator.Text;
    except
        Result := '';
    end;
end;

procedure SchWriteDes(SchComp : ISch_Component; const NewT : String);
begin
    SchComp.GetState_SchDesignator.Text := NewT;
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

procedure SchAnnotateDoc(SchDoc : ISch_Document);
var
    SchIt : ISch_Iterator;
    SchComp : ISch_Component;
    SchList : TStringList;
    Schi : Integer;
    SchX, SchY : Integer;
    OldT, NewT, Pref, SortKey : String;
begin
    { SchIterator_Create undeclared; CreateSchIterator — фабрика документа. }
    if SchDoc = nil then Exit;
    SchList := TStringList.Create;
    SchServer.ProcessControl.PreProcess(SchDoc, '');
    try
        SchIt := SchDoc.CreateSchIterator;
        SchIt.AddFilter_ObjectSet(MkSet(eSchComponent));
        SchComp := SchIt.FirstSchObject;
        while SchComp <> nil do
        begin
            SchX := SchComp.Location.X;
            SchY := SchComp.Location.Y;
            SortKey := SchPadNum(SchX div 100, 8) + '|' + SchPadNum(2000000000 - SchY, 10);
            SchList.AddObject(SortKey, SchComp);
            SchComp := SchIt.NextSchObject;
        end;
        SchDoc.DestroySchIterator(SchIt);

        SchList.Sorted := True;
        for Schi := 0 to SchList.Count - 1 do
        begin
            SchComp := SchList.Objects[Schi];
            OldT := SchReadDes(SchComp);
            Pref := SchPrefixOf(OldT);
            if DoReset and (not DoAnnotate) then
                NewT := Pref + '?'
            else if DoAnnotate then
                NewT := Pref + IntToStr(SchNextNum(Pref))
            else
                NewT := OldT;
            if NewT <> OldT then
            begin
                SchWriteDes(SchComp, NewT);
                Inc(ChangedCnt);
            end;
        end;
        SchDoc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(SchDoc, '');
        SchList.Free;
    end;
end;

procedure ProcessDocuments;
var
    SchWS : IWorkspace;
    SchProject : IProject;
    Schi : Integer;
    SchLogDoc : IDocument;
    SchKind, SchPath : String;
    SchDoc : ISch_Document;
    Current : ISch_Document;
    SheetCnt : Integer;
begin
    ChangedCnt := 0;
    SheetCnt := 0;

    if SchServer = nil then
    begin
        SchShowBox(LabelErrSch.Caption, 16);
        Exit;
    end;

    Current := SchServer.GetCurrentSchDocument;
    SchWS := GetWorkspace;
    if SchWS = nil then Exit;
    SchProject := SchWS.DM_FocusedProject;

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
                    try
                        SchServer.LoadSchDocumentByPath(SchPath);
                    except
                    end;
                    try
                        Client.OpenDocument('SCH', SchPath);
                    except
                    end;
                    SchDoc := SchServer.GetSchDocumentByPath(SchPath);
                    if SchDoc = nil then
                        SchDoc := SchServer.GetCurrentSchDocument;
                    SchAnnotateDoc(SchDoc);
                end;
            end;
            if SheetCnt = 0 then
                SchShowBox(LabelWarnSheets.Caption, 48)
            else
                SchShowBox(LabelInfoDone.Caption + IntToStr(ChangedCnt), 64);
        end
        else
        begin
            if Current = nil then
            begin
                SchShowBox(LabelErrDoc.Caption, 16);
                Exit;
            end;
            SchAnnotateDoc(Current);
            SchShowBox(LabelInfoDone.Caption + IntToStr(ChangedCnt), 64);
        end;
    finally
        PrefixCounters.Free;
        PrefixCounters := nil;
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
