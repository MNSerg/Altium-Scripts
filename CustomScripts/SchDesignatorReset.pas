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

procedure Start; forward;
procedure _Start; forward;
procedure TFormAnnot.ButtonOKClick(Sender: TObject); forward;
procedure TFormAnnot.ButtonCancelClick(Sender: TObject); forward;
procedure TFormAnnot.FormAnnotShow(Sender: TObject); forward;
procedure LoadHelpImage(Img : TImage; Hint : TLabel; const FileName : String); forward;

function DesignatorPrefix(const Des : String) : String;
var
    i : Integer;
    C : Char;
begin
    Result := '';
    for i := 1 to Length(Des) do
    begin
        C := Des[i];
        if ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) then
            Result := Result + C
        else
            Break;
    end;
    if Result = '' then Result := 'U';
end;

function IsLockedDesignator(Comp : ISch_Component) : Boolean;
begin
    Result := False;
    try
        Result := Comp.DesignatorLocked;
    except
        try
            Result := Comp.GetState_LockDesignator;
        except
            Result := False;
        end;
    end;
end;

function CompKindExcluded(Comp : ISch_Component) : Boolean;
begin
    Result := False;
end;

procedure ResetSheet(Doc : ISch_Document);
var
    Iter : ISch_Iterator;
    Comp : ISch_Component;
    Des  : ISch_Designator;
    Text : String;
    Pref : String;
begin
    if Doc = nil then Exit;
    SchServer.ProcessControl.PreProcess(Doc, '');
    try
        Iter := Doc.SchIterator_Create;
        Iter.AddFilter_ObjectSet(MkSet(eSchComponent));
        Comp := Iter.FirstSchObject;
        while Comp <> nil do
        begin
            if not CompKindExcluded(Comp) then
            begin
                if IsLockedDesignator(Comp) then
                    Inc(SkippedLock)
                else
                begin
                    try
                        Des := Comp.Designator;
                        Text := Des.Text;
                        Pref := DesignatorPrefix(Text);
                        Comp.SetState_x_Location(Comp.Location.X); { touch for undo }
                        Des.Text := Pref + '?';
                        Inc(ChangedCnt);
                    except
                    end;
                end;
            end;
            Comp := Iter.NextSchObject;
        end;
        Doc.SchIterator_Destroy(Iter);
        Doc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(Doc, '');
    end;
end;

procedure AnnotateSheet(Doc : ISch_Document);
var
    Iter : ISch_Iterator;
    Comp : ISch_Component;
    List : TStringList;
    i : Integer;
    Prefix : String;
    Idx, Num : Integer;
    X, Y : Integer;
    SortKey : String;
begin
    if Doc = nil then Exit;
    List := TStringList.Create;
    SchServer.ProcessControl.PreProcess(Doc, '');
    try
        Iter := Doc.SchIterator_Create;
        Iter.AddFilter_ObjectSet(MkSet(eSchComponent));
        Comp := Iter.FirstSchObject;
        while Comp <> nil do
        begin
            if (not CompKindExcluded(Comp)) and (not IsLockedDesignator(Comp)) then
            begin
                X := Comp.Location.X;
                Y := Comp.Location.Y;
                { Down then Across: сначала колонка сверху вниз, затем следующая слева направо. }
                SortKey := Format('%.10d|%.10d', [X, 1000000000 - Y]);
                List.AddObject(SortKey, Comp);
            end;
            Comp := Iter.NextSchObject;
        end;
        Doc.SchIterator_Destroy(Iter);

        List.Sorted := True;

        for i := 0 to List.Count - 1 do
        begin
            Comp := List.Objects[i];
            Prefix := DesignatorPrefix(Comp.Designator.Text);
            Idx := PrefixCounters.IndexOfName(Prefix);
            if Idx < 0 then
            begin
                Num := 1;
                PrefixCounters.Add(Prefix + '=1');
            end
            else
            begin
                Num := StrToInt(PrefixCounters.ValueFromIndex[Idx]) + 1;
                PrefixCounters.ValueFromIndex[Idx] := IntToStr(Num);
            end;
            Comp.Designator.Text := Prefix + IntToStr(Num);
            Inc(ChangedCnt);
        end;
        Doc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(Doc, '');
        List.Free;
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
    WS : IWorkspace;
    Project : IProject;
    i : Integer;
    LogDoc : IDocument;
    SchDoc : ISch_Document;
    Current : ISch_Document;
    CountSheets : Integer;
begin
    ChangedCnt := 0;
    SkippedLock := 0;

    if SchServer = nil then
    begin
        ShowError('Нет открытой схемы (SchServer).');
        Exit;
    end;

    Current := SchServer.GetCurrentSchDocument;
    WS := GetWorkspace;
    if WS = nil then Exit;
    Project := WS.DM_FocusedProject;

    if AllSheets then
    begin
        if Project = nil then
        begin
            ShowError('Нет активного проекта.');
            Exit;
        end;
        if not ConfirmNoYes('Перенумеровать все схематические листы проекта (Down then Across)?') then
            Exit;
    end;

    PrefixCounters := TStringList.Create;
    try
        PrefixCounters.NameValueSeparator := '=';

        if DoReset then
            TryOfficialReset;

        if AllSheets and (Project <> nil) then
        begin
            CountSheets := 0;
            for i := 0 to Project.DM_LogicalDocumentCount - 1 do
            begin
                LogDoc := Project.DM_LogicalDocuments(i);
                if (LogDoc.DM_DocumentKind = 'SCH') or (LogDoc.DM_DocumentKind = 'SCHDOC') then
                begin
                    Inc(CountSheets);
                    try
                        SchServer.LoadSchDocumentByPath(LogDoc.DM_FullPath);
                    except
                    end;
                    SchDoc := SchServer.GetSchDocumentByPath(LogDoc.DM_FullPath);
                    if SchDoc = nil then
                        SchDoc := SchServer.GetCurrentSchDocument;
                    if SchDoc <> nil then
                    begin
                        if DoReset then ResetSheet(SchDoc);
                        if DoAnnotate then AnnotateSheet(SchDoc);
                    end;
                end;
            end;
            if CountSheets = 0 then
                ShowWarning('В проекте не найдено схематических листов.');
        end
        else
        begin
            if Current = nil then
            begin
                ShowError('Нет текущего схематического документа.');
                Exit;
            end;
            if DoReset then ResetSheet(Current);
            if DoAnnotate then AnnotateSheet(Current);
        end;

        ShowInfo('Готово.' + sLineBreak +
                 'Изменено десигнаторов: ' + IntToStr(ChangedCnt) + sLineBreak +
                 'Пропущено (заблокированы): ' + IntToStr(SkippedLock) + sLineBreak + sLineBreak +
                 'Порядок: Down then Across. Счётчики префиксов общие на весь проект.' + sLineBreak +
                 'Синхронизируйте PCB через ECO при необходимости.',
                 'Аннотация');
    finally
        PrefixCounters.Free;
        PrefixCounters := nil;
    end;
end;

procedure TFormAnnot.ButtonOKClick(Sender: TObject);
begin
    DoReset := CheckReset.Checked;
    DoAnnotate := CheckAnnotate.Checked;
    AllSheets := CheckAllSheets.Checked;
    if (not DoReset) and (not DoAnnotate) then
    begin
        ShowWarning('Выберите сброс и/или перенумерацию.');
        Exit;
    end;
    FormAnnot.Close;
    ProcessDocuments;
end;

procedure TFormAnnot.ButtonCancelClick(Sender: TObject);
begin
    FormAnnot.Close;
end;

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
        try
            WS := GetWorkspace;
            if WS <> nil then
                for i := 0 to WS.DM_ProjectCount - 1 do
                begin
                    Prj := WS.DM_Projects(i);
                    if Prj <> nil then
                        Cands.Add(ExtractFilePath(Prj.DM_ProjectFullPath) + 'images\' + FileName);
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
                    if Hint <> nil then Hint.Caption := 'Замените картинку: images\' + FileName;
                    Exit;
                except
                end;
            end;
        end;
        if Hint <> nil then
            Hint.Caption := 'Нет картинки. Положите ' + FileName + ' в images\ рядом со скриптами.';
    finally
        Cands.Free;
    end;
end;

procedure TFormAnnot.FormAnnotShow(Sender: TObject);
begin
    LoadHelpImage(ImageHelp, LabelImageHint, 'SchAnnotate.png');
    CheckAnnotate.Checked := True;
    CheckAllSheets.Checked := True;
end;

procedure Start;
begin
    if SchServer = nil then
    begin
        ShowError('Откройте схематический документ.');
        Exit;
    end;
    FormAnnot.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
