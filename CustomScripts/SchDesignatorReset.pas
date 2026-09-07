{..............................................................................}
{ SchDesignatorReset.pas                                                        }
{ Сброс десигнаторов и аннотация всего проекта: Down then Across.              }
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
    try
        MessageBox(0, PChar(Msg), PChar(FormAnnot.Caption), Flags);
    except
        try ShowInfo(Msg, FormAnnot.Caption); except end;
    end;
end;

function SchAskYesNo(const Msg : String) : Boolean;
begin
    Result := False;
    try
        Result := MessageBox(0, PChar(Msg), PChar(FormAnnot.Caption), 36) = 6;
    except
        try Result := ConfirmNoYes(Msg); except end;
    end;
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
    SchDes  : ISch_Designator;
    Text : String;
    Pref : String;
begin
    if SchSchDoc = nil then Exit;
    SchServer.ProcessControl.PreProcess(SchSchDoc, '');
    try
        SchIter := SchSchDoc.SchIterator_Create;
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
                        SchDes := SchComp.Designator;
                        Text := SchDes.Text;
                        Pref := DesignatorPrefix(Text);
                        SchDes.Text := Pref + '?';
                        Inc(ChangedCnt);
                    except
                    end;
                end;
            end;
            SchComp := SchIter.NextSchObject;
        end;
        SchSchDoc.SchIterator_Destroy(SchIter);
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
        SchIter := SchSchDoc.SchIterator_Create;
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
        SchSchDoc.SchIterator_Destroy(SchIter);

        SchList.Sorted := True;

        for Schi := 0 to SchList.Count - 1 do
        begin
            SchComp := SchList.Objects[Schi];
            Prefix := DesignatorPrefix(SchComp.Designator.Text);
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
            SchComp.Designator.Text := Prefix + IntToStr(Num);
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

{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function SchCS_ScriptFolder : String;
var
    SchWS  : IWorkspace;
    SchPrj : IProject;
    Schi   : Integer;
    SchP   : String;
begin
    Result := '';
    try
        SchWS := GetWorkspace;
        if SchWS = nil then Exit;
        SchPrj := SchWS.DM_FocusedProject;
        if SchPrj <> nil then
        begin
            SchP := ExtractFilePath(SchPrj.DM_ProjectFullPath);
            if SchP <> '' then
            begin
                Result := SchP;
                Exit;
            end;
        end;
        for Schi := 0 to SchWS.DM_ProjectCount - 1 do
        begin
            SchPrj := SchWS.DM_Projects(Schi);
            if SchPrj <> nil then
            begin
                SchP := SchPrj.DM_ProjectFullPath;
                if Pos('CustomScripts', SchP) > 0 then
                begin
                    Result := ExtractFilePath(SchP);
                    Exit;
                end;
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
        SchP := SchDir + 'images\' + SchFileName;
        if FileExists(SchP) then
        begin
            Result := SchP;
            Exit;
        end;
        SchP := SchDir + SchFileName;
        if FileExists(SchP) then
        begin
            Result := SchP;
            Exit;
        end;
    end;
    SchP := 'images\' + SchFileName;
    if FileExists(SchP) then Result := SchP;
end;

procedure SchCS_TryLoadHelpImage(const SchBmpName : String; const SchPngName : String);
var
    SchP : String;
begin
    try
        SchP := SchCS_FindImageFile(SchBmpName);
        if SchP = '' then
            SchP := SchCS_FindImageFile(SchPngName);
        if (SchP <> '') and FileExists(SchP) then
        begin
            ImageHelp.Picture.LoadFromFile(SchP);
            LabelImageHint.Caption := 'Replace image: images\' + SchBmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + SchBmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
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
