{..............................................................................}
{ BomExport.pas                                                                 }
{ BOM в Excel (SpreadsheetML, *.xls) без COM. Все компоненты, группировка.     }
{ Столбцы: Comment, Designator, Description, Quantity, Value.                   }
{..............................................................................}

var
    OutPath     : String;
    Groups      : TStringList; { key -> qty in Objects }
    DesLists    : TStringList; { key -> concatenated designators }
    ExtraFields : TStringList; { key -> Comment|Description|Value }

procedure Start; forward;
procedure _Start; forward;
procedure TFormBom.ButtonBrowseClick(Sender: TObject); forward;
procedure TFormBom.ButtonOKClick(Sender: TObject); forward;
procedure TFormBom.ButtonCancelClick(Sender: TObject); forward;
procedure TFormBom.FormBomShow(Sender: TObject); forward;
procedure LoadHelpImage(Img : TImage; Hint : TLabel; const FileName : String); forward;

function XmlEsc(const S : String) : String;
var
    T : String;
begin
    T := S;
    T := StringReplace(T, '&', '&amp;', [rfReplaceAll]);
    T := StringReplace(T, '<', '&lt;', [rfReplaceAll]);
    T := StringReplace(T, '>', '&gt;', [rfReplaceAll]);
    T := StringReplace(T, '"', '&quot;', [rfReplaceAll]);
    Result := T;
end;

function ParamVal(Comp : ISch_Component; const Names : String) : String;
var
    P : ISch_Parameter;
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

procedure AddPart(const Des, Comment, Description, Footprint, Value : String);
var
    Key, Fields : String;
    Idx, Qty : Integer;
begin
    { Ключ группировки: Comment+Value+Description; footprint только внутри, без столбца. }
    Key := UpperCase(Comment) + '||' + UpperCase(Value) + '||' +
           UpperCase(Description) + '||' + UpperCase(Footprint);
    Fields := Comment + '|' + Description + '|' + Value;

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
        else if Des <> '' then
            DesLists[Idx] := DesLists[Idx] + ', ' + Des;
    end;
end;

procedure HarvestSchDoc(Doc : ISch_Document);
var
    Iter : ISch_Iterator;
    Comp : ISch_Component;
    Des, Comment, Desc, Fp, Val : String;
begin
    if Doc = nil then Exit;
    Iter := Doc.SchIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eSchComponent));
    Comp := Iter.FirstSchObject;
    while Comp <> nil do
    begin
        { Ничего не исключаем: DNP, графические, NoBOM, механические — всё. }
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
        AddPart(Des, Comment, Desc, Fp, Val);
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

    if SchServer <> nil then
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

    { Fallback: компоненты PCB. }
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
        AddPart(Des, Comment, '', Fp, Comment);
        Cmp := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure WriteSettingsXml(const XlsPath : String);
var
    Xml : TStringList;
    XmlPath : String;
begin
    XmlPath := ChangeFileExt(XlsPath, '.bom.settings.xml');
    Xml := TStringList.Create;
    try
        Xml.Add('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.Add('<BomSettings generator="CustomScripts.BomExport" version="1.1">');
        Xml.Add('  <Output>' + XmlEsc(XlsPath) + '</Output>');
        Xml.Add('  <Format>SpreadsheetML (.xls)</Format>');
        Xml.Add('  <GroupBy>Comment,Value,Description,Footprint(internal)</GroupBy>');
        Xml.Add('  <ExcludeParts>None</ExcludeParts>');
        Xml.Add('  <Columns>Comment,Designator,Description,Quantity,Value</Columns>');
        Xml.Add('  <Notes>All parts included (DNP, graphical, NoBOM, mechanical). Excel opens SpreadsheetML .xls without COM.</Notes>');
        Xml.Add('</BomSettings>');
        Xml.SaveToFile(XmlPath);
    finally
        Xml.Free;
    end;
end;

procedure WriteExcel;
var
    Lines : TStringList;
    i : Integer;
    Parts : TStringList;
    Qty : Integer;
begin
    Lines := TStringList.Create;
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        Lines.Add('<?xml version="1.0"?>');
        Lines.Add('<?mso-application progid="Excel.Sheet"?>');
        Lines.Add('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
        Lines.Add(' xmlns:o="urn:schemas-microsoft-com:office:office"');
        Lines.Add(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
        Lines.Add(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');
        Lines.Add(' <Worksheet ss:Name="BOM">');
        Lines.Add('  <Table>');
        Lines.Add('   <Row>');
        Lines.Add('    <Cell><Data ss:Type="String">Comment</Data></Cell>');
        Lines.Add('    <Cell><Data ss:Type="String">Designator</Data></Cell>');
        Lines.Add('    <Cell><Data ss:Type="String">Description</Data></Cell>');
        Lines.Add('    <Cell><Data ss:Type="String">Quantity</Data></Cell>');
        Lines.Add('    <Cell><Data ss:Type="String">Value</Data></Cell>');
        Lines.Add('   </Row>');
        for i := 0 to Groups.Count - 1 do
        begin
            Qty := Integer(Groups.Objects[i]);
            Parts.DelimitedText := ExtraFields[i];
            while Parts.Count < 3 do Parts.Add('');
            Lines.Add('   <Row>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(Parts[0]) + '</Data></Cell>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(DesLists[i]) + '</Data></Cell>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(Parts[1]) + '</Data></Cell>');
            Lines.Add('    <Cell><Data ss:Type="Number">' + IntToStr(Qty) + '</Data></Cell>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(Parts[2]) + '</Data></Cell>');
            Lines.Add('   </Row>');
        end;
        Lines.Add('  </Table>');
        Lines.Add(' </Worksheet>');
        Lines.Add('</Workbook>');
        Lines.SaveToFile(OutPath);
        WriteSettingsXml(OutPath);
        ShowInfo('BOM записан: ' + OutPath + sLineBreak +
                 'Строк: ' + IntToStr(Groups.Count) + sLineBreak +
                 'Формат: Excel SpreadsheetML (.xls)' + sLineBreak +
                 'Настройки: ' + ChangeFileExt(OutPath, '.bom.settings.xml'),
                 'BOM');
    finally
        Parts.Free;
        Lines.Free;
    end;
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

procedure TFormBom.FormBomShow(Sender: TObject);
begin
    LoadHelpImage(ImageHelp, LabelImageHint, 'BomExport.png');
    if EditPath.Text = '' then
        EditPath.Text := 'bom.xls';
end;

procedure TFormBom.ButtonBrowseClick(Sender: TObject);
var
    Dlg : TSaveDialog;
begin
    Dlg := TSaveDialog.Create(nil);
    try
        Dlg.Title := 'Сохранить BOM Excel';
        Dlg.Filter := 'Excel (*.xls)|*.xls|Все файлы (*.*)|*.*';
        Dlg.DefaultExt := 'xls';
        Dlg.FileName := 'bom.xls';
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
        ShowError('Укажите путь к файлу .xls.');
        Exit;
    end;
    if LowerCase(ExtractFileExt(OutPath)) = '.csv' then
        OutPath := ChangeFileExt(OutPath, '.xls');
    if LowerCase(ExtractFileExt(OutPath)) = '' then
        OutPath := OutPath + '.xls';
    FormBom.Close;

    Groups := TStringList.Create;
    DesLists := TStringList.Create;
    ExtraFields := TStringList.Create;
    try
        HarvestFromProject;
        if Groups.Count = 0 then
            ShowWarning('Компоненты не найдены. Откройте схему или PCB проекта.')
        else
            WriteExcel;
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
    EditPath.Text := 'bom.xls';
    FormBom.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
