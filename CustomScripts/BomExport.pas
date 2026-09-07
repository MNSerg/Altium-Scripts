{..............................................................................}
{ BomExport.pas                                                                 }
{ Сбор BOM: группировка Comment+Footprint (+MPN), исключение DNP/графики.      }
{ CSV UTF-8 + сопроводительный XML настроек.                                    }
{..............................................................................}

var
    OutPath     : String;
    ExcludeDnp  : Boolean;
    GroupByMpn  : Boolean;
    Groups      : TStringList; { key -> qty in Objects as integer via string value }
    DesLists    : TStringList; { key -> concatenated designators }
    ExtraFields : TStringList; { key -> pipe-separated fields }

procedure Start; forward;
procedure _Start; forward;
procedure TFormBom.ButtonBrowseClick(Sender: TObject); forward;
procedure TFormBom.ButtonOKClick(Sender: TObject); forward;
procedure TFormBom.ButtonCancelClick(Sender: TObject); forward;

function CsvEscape(const S : String) : String;
var
    T : String;
begin
    T := S;
    if (Pos('"', T) > 0) or (Pos(',', T) > 0) or (Pos(sLineBreak, T) > 0) then
    begin
        T := StringReplace(T, '"', '""', [rfReplaceAll]);
        Result := '"' + T + '"';
    end
    else
        Result := T;
end;

function ParamVal(Comp : ISch_Component; const Names : String) : String;
var
    P : ISch_Parameter;
    Iter : ISch_Iterator;
    One : String;
    Rest, Name : String;
    PosSep : Integer;
begin
    Result := '';
    Rest := Names;
    while Rest <> '' do
    begin
        PosSep := Pos('|', Rest);
        if PosSep > 0 then
        begin
            Name := Copy(Rest, 1, PosSep - 1);
            Rest := Copy(Rest, PosSep + 1, Length(Rest));
        end
        else
        begin
            Name := Rest;
            Rest := '';
        end;
        try
            P := Comp.GetSchParameterByName(Name);
            if P <> nil then
            begin
                Result := P.Text;
                if Result <> '' then Exit;
            end;
        except
        end;
    end;
end;

function IsDnpOrNoBom(Comp : ISch_Component) : Boolean;
var
    K : Integer;
    V : String;
begin
    Result := False;
    try
        K := Comp.ComponentKind;
        if (K = eComponentKind_Graphical) or (K = eComponentKind_Standard_NoBOM) then
        begin
            Result := True;
            Exit;
        end;
        if K = eComponentKind_Mechanical then
        begin
            { Mechanical без Fitted — исключаем. }
            Result := True;
        end;
    except
    end;
    V := UpperCase(ParamVal(Comp, 'DNP|DoNotFit|Do Not Fit|Fitted|NotFitted'));
    if (V = 'DNP') or (V = 'TRUE') or (V = 'YES') or (V = '1') or (V = 'NOTFITTED') or (V = 'NOT FITTED') then
        Result := True;
    if UpperCase(ParamVal(Comp, 'Fitted')) = 'FALSE' then
        Result := True;
end;

function FootprintOf(Comp : ISch_Component) : String;
var
    Impl : ISch_Implementation;
    i : Integer;
begin
    Result := ParamVal(Comp, 'Footprint|PCBFootprint');
    if Result <> '' then Exit;
    try
        for i := 0 to Comp.ImplementationCount - 1 do
        begin
            Impl := Comp.Implementations[i];
            if Impl.ModelType = 'PCB' then
            begin
                Result := Impl.ModelName;
                Exit;
            end;
        end;
    except
    end;
end;

procedure AddPart(const Des, Comment, Description, Footprint, Value, Mfr, Mpn, Sup, Spn : String);
var
    Key, Fields : String;
    Idx, Qty : Integer;
begin
    if GroupByMpn and (Mpn <> '') then
        Key := UpperCase(Comment) + '||' + UpperCase(Footprint) + '||' + UpperCase(Mpn)
    else
        Key := UpperCase(Comment) + '||' + UpperCase(Footprint);

    Fields := Comment + '|' + Description + '|' + Footprint + '|' + Value + '|' + Mfr + '|' + Mpn + '|' + Sup + '|' + Spn;

    Idx := Groups.IndexOf(Key);
    if Idx < 0 then
    begin
        Groups.Add(Key);
        Groups.Objects[Groups.Count - 1] := TObject(1);
        DesLists.Add(Des);
        ExtraFields.Add(Fields);
    end
    else
    begin
        Qty := Integer(Groups.Objects[Idx]) + 1;
        Groups.Objects[Idx] := TObject(Qty);
        if DesLists[Idx] = '' then
            DesLists[Idx] := Des
        else
            DesLists[Idx] := DesLists[Idx] + ', ' + Des;
    end;
end;

procedure HarvestSchDoc(Doc : ISch_Document);
var
    Iter : ISch_Iterator;
    Comp : ISch_Component;
    Des, Comment, Desc, Fp, Val, Mfr, Mpn, Sup, Spn : String;
begin
    if Doc = nil then Exit;
    Iter := Doc.SchIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eSchComponent));
    Comp := Iter.FirstSchObject;
    while Comp <> nil do
    begin
        if (not ExcludeDnp) or (not IsDnpOrNoBom(Comp)) then
        begin
            try
                Des := Comp.Designator.Text;
            except
                Des := '';
            end;
            try
                Comment := Comp.Comment.Text;
            except
                Comment := ParamVal(Comp, 'Comment');
            end;
            Desc := ParamVal(Comp, 'Description|Part Description');
            Fp := FootprintOf(Comp);
            Val := ParamVal(Comp, 'Value');
            if Val = '' then Val := Comment;
            Mfr := ParamVal(Comp, 'Manufacturer|Mfr');
            Mpn := ParamVal(Comp, 'Manufacturer Part Number|ManufacturerPartNumber|MPN|PartNumber');
            Sup := ParamVal(Comp, 'Supplier|Supplier 1|Supplier1');
            Spn := ParamVal(Comp, 'Supplier Part Number|Supplier Part Number 1|SPN');
            AddPart(Des, Comment, Desc, Fp, Val, Mfr, Mpn, Sup, Spn);
        end;
        Comp := Iter.NextSchObject;
    end;
    Doc.SchIterator_Destroy(Iter);
end;

procedure HarvestFromProject;
var
    WS : IWorkspace;
    Project : IProject;
    i : Integer;
    LogDoc : IDocument;
    SchDoc : ISch_Document;
    Board : IPCB_Board;
    Cmp : IPCB_Component;
    Iter : IPCB_BoardIterator;
    Des, Comment, Fp : String;
begin
    WS := GetWorkspace;
    if WS = nil then Exit;
    Project := WS.DM_FocusedProject;

    if (SchServer <> nil) then
    begin
        if Project <> nil then
        begin
            for i := 0 to Project.DM_LogicalDocumentCount - 1 do
            begin
                LogDoc := Project.DM_LogicalDocuments(i);
                if (LogDoc.DM_DocumentKind = 'SCH') or (LogDoc.DM_DocumentKind = 'SCHDOC') then
                begin
                    try
                        SchServer.LoadSchDocumentByPath(LogDoc.DM_FullPath);
                    except
                    end;
                    SchDoc := SchServer.GetSchDocumentByPath(LogDoc.DM_FullPath);
                    if SchDoc <> nil then HarvestSchDoc(SchDoc);
                end;
            end;
        end
        else if SchServer.GetCurrentSchDocument <> nil then
            HarvestSchDoc(SchServer.GetCurrentSchDocument);
    end;

    if Groups.Count > 0 then Exit;

    { Fallback: компоненты PCB, UniqueID источника. }
    if PCBServer = nil then Exit;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then Exit;
    Iter := Board.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eComponentObject));
    Iter.AddFilter_LayerSet(AllLayers);
    Iter.AddFilter_Method(eProcessAll);
    Cmp := Iter.FirstPCBObject;
    while Cmp <> nil do
    begin
        Des := '';
        Comment := '';
        Fp := '';
        try Des := Cmp.Name.Text; except Des := ''; end;
        try Comment := Cmp.Comment.Text; except Comment := ''; end;
        if Comment = '' then
        try Comment := Cmp.SourceLibReference; except Comment := ''; end;
        try Fp := Cmp.Pattern; except Fp := ''; end;
        AddPart(Des, Comment, '', Fp, Comment, '', '', '', '');
        Cmp := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure WriteSettingsXml(const CsvPath : String);
var
    Xml : TStringList;
    XmlPath : String;
begin
    XmlPath := ChangeFileExt(CsvPath, '.bom.settings.xml');
    Xml := TStringList.Create;
    try
        Xml.Add('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.Add('<BomSettings generator="CustomScripts.BomExport" version="1.0">');
        Xml.Add('  <Output>' + CsvPath + '</Output>');
        Xml.Add('  <Format>CSV</Format>');
        if GroupByMpn then
            Xml.Add('  <GroupBy>Comment,Footprint,MPN</GroupBy>')
        else
            Xml.Add('  <GroupBy>Comment,Footprint</GroupBy>');
        if ExcludeDnp then
            Xml.Add('  <ExcludeDNP>True</ExcludeDNP>')
        else
            Xml.Add('  <ExcludeDNP>False</ExcludeDNP>');
        Xml.Add('  <Columns>Designator,Quantity,Comment,Description,Footprint,Value,Manufacturer,Manufacturer Part Number,Supplier,Supplier Part Number</Columns>');
        Xml.Add('  <Notes>Grouped unique lines. Graphical/NoBOM/DNP excluded when enabled. Not an Altium OutJob, companion settings only.</Notes>');
        Xml.Add('</BomSettings>');
        Xml.SaveToFile(XmlPath);
    finally
        Xml.Free;
    end;
end;

procedure WriteCsv;
var
    Lines : TStringList;
    i : Integer;
    Parts : TStringList;
    Qty : Integer;
    Fields : String;
begin
    Lines := TStringList.Create;
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        Lines.Add('Designator,Quantity,Comment,Description,Footprint,Value,Manufacturer,Manufacturer Part Number,Supplier,Supplier Part Number');
        for i := 0 to Groups.Count - 1 do
        begin
            Qty := Integer(Groups.Objects[i]);
            Parts.DelimitedText := ExtraFields[i];
            while Parts.Count < 8 do Parts.Add('');
            Lines.Add(
                CsvEscape(DesLists[i]) + ',' +
                IntToStr(Qty) + ',' +
                CsvEscape(Parts[0]) + ',' +
                CsvEscape(Parts[1]) + ',' +
                CsvEscape(Parts[2]) + ',' +
                CsvEscape(Parts[3]) + ',' +
                CsvEscape(Parts[4]) + ',' +
                CsvEscape(Parts[5]) + ',' +
                CsvEscape(Parts[6]) + ',' +
                CsvEscape(Parts[7])
            );
        end;
        Lines.SaveToFile(OutPath);
        WriteSettingsXml(OutPath);
        ShowInfo('BOM записан: ' + OutPath + sLineBreak +
                 'Строк: ' + IntToStr(Groups.Count) + sLineBreak +
                 'Настройки: ' + ChangeFileExt(OutPath, '.bom.settings.xml'),
                 'BOM');
    finally
        Parts.Free;
        Lines.Free;
    end;
end;

procedure TFormBom.ButtonBrowseClick(Sender: TObject);
var
    Dlg : TSaveDialog;
begin
    Dlg := TSaveDialog.Create(nil);
    try
        Dlg.Title := 'Сохранить BOM CSV';
        Dlg.Filter := 'CSV (*.csv)|*.csv';
        Dlg.DefaultExt := 'csv';
        Dlg.FileName := 'bom.csv';
        if Dlg.Execute then
            EditPath.Text := Dlg.FileName;
    finally
        Dlg.Free;
    end;
end;

procedure TFormBom.ButtonOKClick(Sender: TObject);
begin
    OutPath := EditPath.Text;
    if OutPath = '' then
    begin
        ShowError('Укажите путь к CSV.');
        Exit;
    end;
    ExcludeDnp := CheckDnp.Checked;
    GroupByMpn := CheckGroupMpn.Checked;
    FormBom.Close;

    Groups := TStringList.Create;
    DesLists := TStringList.Create;
    ExtraFields := TStringList.Create;
    try
        HarvestFromProject;
        if Groups.Count = 0 then
            ShowWarning('Компоненты не найдены. Откройте схему или PCB проекта.')
        else
            WriteCsv;
    finally
        Groups.Free;
        DesLists.Free;
        ExtraFields.Free;
    end;
end;

procedure TFormBom.ButtonCancelClick(Sender: TObject);
begin
    FormBom.Close;
end;

procedure Start;
begin
    EditPath.Text := 'bom.csv';
    FormBom.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
