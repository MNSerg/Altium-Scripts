{..............................................................................}
{ SchDesignatorReset.pas                                                        }
{ Сброс десигнаторов и аннотация всего проекта: Down then Across.              }
{ Обход: SchDoc/Comp.Iterator_Create (не SchIterator_Create). DESIGNATOR.Text.  }
{..............................................................................}

var
    DoReset     : Boolean;
    DoAnnotate  : Boolean;
    AllSheets   : Boolean;
    ChangedCnt  : Integer;
    SkippedLock : Integer;
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

function DesignatorPrefix(const SchDes : String) : String;
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

function SchDesText(SchComp : ISch_Component) : String;
var
    SchIt : ISch_Iterator;
    SchP : ISch_Parameter;
    PName : String;
begin
    { Не Comp.Designator — в этом диалекте идентификатор Designator нет. }
    Result := '';
    try
        SchIt := SchComp.Iterator_Create;
        SchIt.AddFilter_ObjectSet(MkSet(eParameter));
        SchP := SchIt.FirstSchObject;
        while SchP <> nil do
        begin
            PName := '';
            try PName := SchP.Name; except PName := ''; end;
            if UpperCase(PName) = 'DESIGNATOR' then
            begin
                try Result := SchP.Text; except Result := ''; end;
                SchComp.Iterator_Destroy(SchIt);
                Exit;
            end;
            SchP := SchIt.NextSchObject;
        end;
        SchComp.Iterator_Destroy(SchIt);
    except
        Result := '';
    end;
    if Result = '' then
    begin
        try
            Result := SchComp.GetState_SchDesignator.Text;
        except
        end;
    end;
end;

procedure SchSetDes(SchComp : ISch_Component; const NewT : String);
var
    SchIt : ISch_Iterator;
    SchP : ISch_Parameter;
    PName : String;
begin
    try
        SchIt := SchComp.Iterator_Create;
        SchIt.AddFilter_ObjectSet(MkSet(eParameter));
        SchP := SchIt.FirstSchObject;
        while SchP <> nil do
        begin
            PName := '';
            try PName := SchP.Name; except PName := ''; end;
            if UpperCase(PName) = 'DESIGNATOR' then
            begin
                SchP.Text := NewT;
                SchComp.Iterator_Destroy(SchIt);
                Exit;
            end;
            SchP := SchIt.NextSchObject;
        end;
        SchComp.Iterator_Destroy(SchIt);
    except
    end;
end;

function IsLockedDesignator(SchComp : ISch_Component) : Boolean;
begin
    Result := False;
    try
        Result := SchComp.DesignatorLocked;
    except
        try
            Result := SchComp.GetState_LockDesignator;
        except
            Result := False;
        end;
    end;
end;

function CompKindExcluded(SchComp : ISch_Component) : Boolean;
begin
    Result := False;
end;

procedure ResetSheet(SchSchDoc : ISch_Document);
var
    SchIter : ISch_Iterator;
    SchComp : ISch_Component;
    Text : String;
    Pref : String;
begin
    if SchSchDoc = nil then Exit;
    SchServer.ProcessControl.PreProcess(SchSchDoc, '');
    try
        SchIter := SchSchDoc.Iterator_Create;
        SchIter.AddFilter_ObjectSet(MkSet(eSchComponent));
        SchComp := SchIter.FirstSchObject;
        while SchComp <> nil do
        begin
            if not CompKindExcluded(SchComp) then
            begin
                if IsLockedDesignator(SchComp) then
                    Inc(SkippedLock)
                else
                begin
                    try
                        Text := SchDesText(SchComp);
                        Pref := DesignatorPrefix(Text);
                        SchSetDes(SchComp, Pref + '?');
                        Inc(ChangedCnt);
                    except
                    end;
                end;
            end;
            SchComp := SchIter.NextSchObject;
        end;
        SchSchDoc.Iterator_Destroy(SchIter);
        SchSchDoc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(SchSchDoc, '');
    end;
end;

procedure AnnotateSheet(SchSchDoc : ISch_Document);
var
    SchIter : ISch_Iterator;
    SchComp : ISch_Component;
    SchList : TStringList;
    Schi : Integer;
    Prefix : String;
    SchIdx, Num : Integer;
    SchX, SchY : Integer;
    SortKey : String;
begin
    if SchSchDoc = nil then Exit;
    SchList := TStringList.Create;
    SchServer.ProcessControl.PreProcess(SchSchDoc, '');
    try
        SchIter := SchSchDoc.Iterator_Create;
        SchIter.AddFilter_ObjectSet(MkSet(eSchComponent));
        SchComp := SchIter.FirstSchObject;
        while SchComp <> nil do
        begin
            if (not CompKindExcluded(SchComp)) and (not IsLockedDesignator(SchComp)) then
            begin
                SchX := SchComp.Location.X;
                SchY := SchComp.Location.Y;
                { Down then Across: колонка = корзина X, внутри колонки Y сверху вниз.
                  Без корзины компоненты одной колонки с разным X шли бы как отдельные столбцы. }
                SortKey := SchPadNum(SchX div 100, 8) + '|' + SchPadNum(2000000000 - SchY, 10);
                SchList.AddObject(SortKey, SchComp);
            end;
            SchComp := SchIter.NextSchObject;
        end;
        SchSchDoc.Iterator_Destroy(SchIter);

        SchList.Sorted := True;

        for Schi := 0 to SchList.Count - 1 do
        begin
            SchComp := SchList.Objects[Schi];
            Prefix := DesignatorPrefix(SchDesText(SchComp));
            SchIdx := PrefixCounters.IndexOfName(Prefix);
            if SchIdx < 0 then
            begin
                Num := 1;
                PrefixCounters.Add(Prefix + '=1');
            end
            else
            begin
                Num := StrToInt(PrefixCounters.ValueFromIndex[SchIdx]) + 1;
                PrefixCounters.ValueFromIndex[SchIdx] := IntToStr(Num);
            end;
            SchSetDes(SchComp, Prefix + IntToStr(Num));
            Inc(ChangedCnt);
        end;
        SchSchDoc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(SchSchDoc, '');
        SchList.Free;
    end;
end;

procedure TryOfficialReset;
begin
    try
        ResetParameters;
        AddStringParameter('Action', 'ResetDesignators');
        RunProcess('Sch:ResetDesignators');
    except
    end;
end;

procedure ProcessDocuments;
var
    SchWS : IWorkspace;
    SchProject : IProject;
    Schi : Integer;
    SchLogDoc : IDocument;
    SchSchDoc : ISch_Document;
    Current : ISch_Document;
    CountSheets : Integer;
begin
    ChangedCnt := 0;
    SkippedLock := 0;

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

        if DoReset then
            TryOfficialReset;

        if AllSheets and (SchProject <> nil) then
        begin
            CountSheets := 0;
            for Schi := 0 to SchProject.DM_LogicalDocumentCount - 1 do
            begin
                SchLogDoc := SchProject.DM_LogicalDocuments(Schi);
                if (SchLogDoc.DM_DocumentKind = 'SCH') or (SchLogDoc.DM_DocumentKind = 'SCHDOC') then
                begin
                    Inc(CountSheets);
                    try
                        SchServer.LoadSchDocumentByPath(SchLogDoc.DM_FullPath);
                    except
                    end;
                    SchSchDoc := SchServer.GetSchDocumentByPath(SchLogDoc.DM_FullPath);
                    if SchSchDoc = nil then
                        SchSchDoc := SchServer.GetCurrentSchDocument;
                    if SchSchDoc <> nil then
                    begin
                        if DoReset then ResetSheet(SchSchDoc);
                        if DoAnnotate then AnnotateSheet(SchSchDoc);
                    end;
                end;
            end;
            if CountSheets = 0 then
                SchShowBox(LabelWarnSheets.Caption, 48);
        end
        else
        begin
            if Current = nil then
            begin
                SchShowBox(LabelErrDoc.Caption, 16);
                Exit;
            end;
            if DoReset then ResetSheet(Current);
            if DoAnnotate then AnnotateSheet(Current);
        end;

        SchShowBox(LabelInfoDone.Caption + IntToStr(ChangedCnt) + sLineBreak +
                   LabelInfoLock.Caption + IntToStr(SkippedLock), 64);
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
