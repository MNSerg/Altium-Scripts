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

{ Run Script: choose procedure StartBomExport (project compiles only this .pas). }
procedure StartBomExport; forward;
procedure _StartBomExport; forward;
procedure TFormBom.ButtonBrowseClick(BomSender: TObject); forward;
procedure TFormBom.ButtonOKClick(BomSender: TObject); forward;
procedure TFormBom.ButtonCancelClick(BomSender: TObject); forward;
procedure TFormBom.FormBomShow(BomSender: TObject); forward;

function XmlEsc(const BomS : String) : String;
var
    BomT : String;
begin
    BomT := BomS;
    BomT := StringReplace(BomT, '&', '&amp;', [rfReplaceAll]);
    BomT := StringReplace(BomT, '<', '&lt;', [rfReplaceAll]);
    BomT := StringReplace(BomT, '>', '&gt;', [rfReplaceAll]);
    BomT := StringReplace(BomT, '"', '&quot;', [rfReplaceAll]);
    Result := BomT;
end;

function ParamVal(BomComp : ISch_Component; const BomNames : String) : String;
var
    BomP : ISch_Parameter;
    Rest, BomName : String;
    PosSep : Integer;
begin
    Result := '';
    Rest := BomNames;
    while Rest <> '' do
    begin
        PosSep := Pos('|', Rest);
        if PosSep > 0 then
        begin
            BomName := Copy(Rest, 1, PosSep - 1);
            Rest := Copy(Rest, PosSep + 1, Length(Rest));
        end
        else
        begin
            BomName := Rest;
            Rest := '';
        end;
        try
            BomP := BomComp.GetSchParameterByName(BomName);
            if BomP <> nil then
            begin
                Result := BomP.Text;
                if Result <> '' then Exit;
            end;
        except
        end;
    end;
end;

function FootprintOf(BomComp : ISch_Component) : String;
var
    Impl : ISch_Implementation;
    Bomi : Integer;
begin
    Result := ParamVal(BomComp, 'Footprint|PCBFootprint');
    if Result <> '' then Exit;
    try
        for Bomi := 0 to BomComp.ImplementationCount - 1 do
        begin
            Impl := BomComp.Implementations[Bomi];
            if Impl.ModelType = 'PCB' then
            begin
                Result := Impl.ModelName;
                Exit;
            end;
        end;
    except
    end;
end;

procedure AddPart(const BomDes, Comment, Description, Footprint, Value : String);
var
    BomKey, Fields : String;
    BomIdx, Qty : Integer;
begin
    { Ключ группировки: Comment+Value+Description; footprint только внутри, без столбца. }
    BomKey := UpperCase(Comment) + '||' + UpperCase(Value) + '||' +
           UpperCase(Description) + '||' + UpperCase(Footprint);
    Fields := Comment + '|' + Description + '|' + Value;

    BomIdx := Groups.IndexOf(BomKey);
    if BomIdx < 0 then
    begin
        Groups.Add(BomKey);
        Groups.Objects[Groups.Count - 1] := TObject(1);
        DesLists.Add(BomDes);
        ExtraFields.Add(Fields);
    end
    else
    begin
        Qty := Integer(Groups.Objects[BomIdx]) + 1;
        Groups.Objects[BomIdx] := TObject(Qty);
        if DesLists[BomIdx] = '' then
            DesLists[BomIdx] := BomDes
        else if BomDes <> '' then
            DesLists[BomIdx] := DesLists[BomIdx] + ', ' + BomDes;
    end;
end;

procedure HarvestSchDoc(BomDoc : ISch_Document);
var
    BomIter : ISch_Iterator;
    BomComp : ISch_Component;
    BomDes, Comment, Desc, Fp, BomVal : String;
begin
    if BomDoc = nil then Exit;
    BomIter := BomDoc.SchIterator_Create;
    BomIter.AddFilter_ObjectSet(MkSet(eSchComponent));
    BomComp := BomIter.FirstSchObject;
    while BomComp <> nil do
    begin
        { Ничего не исключаем: DNP, графические, NoBOM, механические — всё. }
        try
            BomDes := BomComp.Designator.Text;
        except
            BomDes := '';
        end;
        try
            Comment := BomComp.Comment.Text;
        except
            Comment := ParamVal(BomComp, 'Comment');
        end;
        Desc := ParamVal(BomComp, 'Description|Part Description');
        Fp := FootprintOf(BomComp);
        BomVal := ParamVal(BomComp, 'Value');
        if BomVal = '' then BomVal := Comment;
        AddPart(BomDes, Comment, Desc, Fp, BomVal);
        BomComp := BomIter.NextSchObject;
    end;
    BomDoc.SchIterator_Destroy(BomIter);
end;

procedure HarvestFromProject;
var
    BomWS : IWorkspace;
    BomProject : IProject;
    Bomi : Integer;
    BomLogDoc : IDocument;
    BomSchDoc : ISch_Document;
    BomBoard : IPCB_Board;
    BomCmp : IPCB_Component;
    BomIter : IPCB_BoardIterator;
    BomDes, Comment, Fp : String;
begin
    BomWS := GetWorkspace;
    if BomWS = nil then Exit;
    BomProject := BomWS.DM_FocusedProject;

    if SchServer <> nil then
    begin
        if BomProject <> nil then
        begin
            for Bomi := 0 to BomProject.DM_LogicalDocumentCount - 1 do
            begin
                BomLogDoc := BomProject.DM_LogicalDocuments(Bomi);
                if (BomLogDoc.DM_DocumentKind = 'SCH') or (BomLogDoc.DM_DocumentKind = 'SCHDOC') then
                begin
                    try
                        SchServer.LoadSchDocumentByPath(BomLogDoc.DM_FullPath);
                    except
                    end;
                    BomSchDoc := SchServer.GetSchDocumentByPath(BomLogDoc.DM_FullPath);
                    if BomSchDoc <> nil then HarvestSchDoc(BomSchDoc);
                end;
            end;
        end
        else if SchServer.GetCurrentSchDocument <> nil then
            HarvestSchDoc(SchServer.GetCurrentSchDocument);
    end;

    if Groups.Count > 0 then Exit;

    { Fallback: компоненты PCB. }
    if PCBServer = nil then Exit;
    BomBoard := PCBServer.GetCurrentPCBBoard;
    if BomBoard = nil then Exit;
    BomIter := BomBoard.BoardIterator_Create;
    BomIter.AddFilter_ObjectSet(MkSet(eComponentObject));
    BomIter.AddFilter_LayerSet(AllLayers);
    BomIter.AddFilter_Method(eProcessAll);
    BomCmp := BomIter.FirstPCBObject;
    while BomCmp <> nil do
    begin
        BomDes := '';
        Comment := '';
        Fp := '';
        try BomDes := BomCmp.Name.Text; except BomDes := ''; end;
        try Comment := BomCmp.Comment.Text; except Comment := ''; end;
        if Comment = '' then
        try Comment := BomCmp.SourceLibReference; except Comment := ''; end;
        try Fp := BomCmp.Pattern; except Fp := ''; end;
        AddPart(BomDes, Comment, '', Fp, Comment);
        BomCmp := BomIter.NextPCBObject;
    end;
    BomBoard.BoardIterator_Destroy(BomIter);
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
    Bomi : Integer;
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
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Qty := Integer(Groups.Objects[Bomi]);
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            Lines.Add('   <Row>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(Parts[0]) + '</Data></Cell>');
            Lines.Add('    <Cell><Data ss:Type="String">' + XmlEsc(DesLists[Bomi]) + '</Data></Cell>');
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

{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function BomCS_ScriptFolder : String;
var
    BomWS  : IWorkspace;
    BomPrj : IProject;
    Bomi   : Integer;
    BomP   : String;
begin
    Result := '';
    try
        BomWS := GetWorkspace;
        if BomWS = nil then Exit;
        BomPrj := BomWS.DM_FocusedProject;
        if BomPrj <> nil then
        begin
            BomP := ExtractFilePath(BomPrj.DM_ProjectFullPath);
            if BomP <> '' then
            begin
                Result := BomP;
                Exit;
            end;
        end;
        for Bomi := 0 to BomWS.DM_ProjectCount - 1 do
        begin
            BomPrj := BomWS.DM_Projects(Bomi);
            if BomPrj <> nil then
            begin
                BomP := BomPrj.DM_ProjectFullPath;
                if Pos('CustomScripts', BomP) > 0 then
                begin
                    Result := ExtractFilePath(BomP);
                    Exit;
                end;
            end;
        end;
    except
        Result := '';
    end;
end;

function BomCS_FindImageFile(const BomFileName : String) : String;
var
    BomDir, BomP : String;
begin
    Result := '';
    BomDir := BomCS_ScriptFolder;
    if BomDir <> '' then
    begin
        BomP := BomDir + 'images\' + BomFileName;
        if FileExists(BomP) then
        begin
            Result := BomP;
            Exit;
        end;
        BomP := BomDir + BomFileName;
        if FileExists(BomP) then
        begin
            Result := BomP;
            Exit;
        end;
    end;
    BomP := 'images\' + BomFileName;
    if FileExists(BomP) then Result := BomP;
end;

procedure BomCS_TryLoadHelpImage(const BomBmpName : String; const BomPngName : String);
var
    BomP : String;
begin
    try
        BomP := BomCS_FindImageFile(BomBmpName);
        if BomP = '' then
            BomP := BomCS_FindImageFile(BomPngName);
        if (BomP <> '') and FileExists(BomP) then
        begin
            ImageHelp.Picture.LoadFromFile(BomP);
            LabelImageHint.Caption := 'Replace image: images\' + BomBmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + BomBmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
end;


procedure TFormBom.FormBomShow(BomSender: TObject);
begin
    try
        BomCS_TryLoadHelpImage('BomExport.bmp', 'BomExport.png');
    except
    end;
    if EditPath.Text = '' then
        EditPath.Text := 'bom.xls';
end;

procedure TFormBom.ButtonBrowseClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := 'Сохранить BOM Excel';
        BomDlg.Filter := 'Excel (*.xls)|*.xls|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xls';
        BomDlg.FileName := 'bom.xls';
        if BomDlg.Execute then
            EditPath.Text := BomDlg.FileName;
    finally
        BomDlg.Free;
    end;
end;

procedure TFormBom.ButtonOKClick(BomSender: TObject);
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

procedure TFormBom.ButtonCancelClick(BomSender: TObject);
begin
    FormBom.Close;
end;

procedure StartBomExport;
begin
    FormBom.ShowModal;
end;

procedure _StartBomExport;
begin
    StartBomExport;
end;
