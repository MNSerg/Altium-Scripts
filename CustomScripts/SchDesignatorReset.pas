{..............................................................................}
{ SchDesignatorReset.pas                                                        }
{ Сброс десигнаторов схемы в "?" и позиционная аннотация по листам проекта.    }
{..............................................................................}

var
    DoReset     : Boolean;
    DoAnnotate  : Boolean;
    AllSheets   : Boolean;
    ChangedCnt  : Integer;
    SkippedLock : Integer;

procedure Start; forward;
procedure _Start; forward;
procedure TFormAnnot.ButtonOKClick(Sender: TObject); forward;
procedure TFormAnnot.ButtonCancelClick(Sender: TObject); forward;

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
var
    K : Integer;
begin
    Result := False;
    try
        K := Comp.ComponentKind;
        { Graphical / Net Tie / Jumper могут не требовать аннотации — не исключаем сброс. }
        if K = eComponentKind_Graphical then Result := True;
    except
        Result := False;
    end;
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
    i, n : Integer;
    Prefix : String;
    Counters : TStringList;
    Idx, Num : Integer;
    Key, DesText : String;
    X, Y : Integer;
    SortKey : String;
begin
    if Doc = nil then Exit;
    List := TStringList.Create;
    Counters := TStringList.Create;
    Counters.NameValueSeparator := '=';
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
                { Слева направо, сверху вниз: Y по убыванию, затем X по возрастанию. }
                SortKey := Format('%.10d|%.10d', [1000000000 - Y, X]);
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
            Idx := Counters.IndexOfName(Prefix);
            if Idx < 0 then
            begin
                Num := 1;
                Counters.Add(Prefix + '=1');
            end
            else
            begin
                Num := StrToInt(Counters.ValueFromIndex[Idx]) + 1;
                Counters.ValueFromIndex[Idx] := IntToStr(Num);
            end;
            Comp.Designator.Text := Prefix + IntToStr(Num);
            Inc(ChangedCnt);
        end;
        Doc.GraphicallyInvalidate;
    finally
        SchServer.ProcessControl.PostProcess(Doc, '');
        List.Free;
        Counters.Free;
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
        if not ConfirmNoYes('Обработать все схематические листы проекта?') then
            Exit;
    end;

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
             'Синхронизируйте PCB через ECO при необходимости.',
             'Аннотация');
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
