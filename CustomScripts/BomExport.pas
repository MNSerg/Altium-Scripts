{..............................................................................}
{ BomExport.pas                                                                 }
{ BOM в Excel (SpreadsheetML, *.xls) без COM. Все компоненты, группировка.     }
{ Столбцы: Comment, Designator, Description, Quantity, Value.                   }
{..............................................................................}

var
    OutPath     : String;
    Groups      : TStringList; { grouping key }
    DesLists    : TStringList; { key -> concatenated designators }
    ExtraFields : TStringList; { key -> Comment|Description|Value }
    QtyList     : TStringList; { key -> quantity as decimal string }

{ Run Script: choose procedure StartBomExport (project compiles only this .pas). }
procedure StartBomExport; forward;
procedure _StartBomExport; forward;
procedure TFormBom.ButtonBrowseClick(BomSender: TObject); forward;
procedure TFormBom.ButtonOKClick(BomSender: TObject); forward;
procedure TFormBom.ButtonCancelClick(BomSender: TObject); forward;
procedure TFormBom.FormBomShow(BomSender: TObject); forward;

{ Без set-литерала rfReplaceAll: в DelphiScript скобки дают Array Variant. }
function BomReplaceStr(const BomS, FindStr, Repl : String) : String;
var
    Bomi : Integer;
    Rest : String;
begin
    Result := '';
    Rest := BomS;
    if FindStr = '' then
    begin
        Result := BomS;
        Exit;
    end;
    Bomi := Pos(FindStr, Rest);
    while Bomi > 0 do
    begin
        Result := Result + Copy(Rest, 1, Bomi - 1) + Repl;
        Rest := Copy(Rest, Bomi + Length(FindStr), Length(Rest));
        Bomi := Pos(FindStr, Rest);
    end;
    Result := Result + Rest;
end;

function XmlEsc(const BomS : String) : String;
var
    BomT : String;
begin
    BomT := BomS;
    BomT := BomReplaceStr(BomT, '&', '&amp;');
    BomT := BomReplaceStr(BomT, '<', '&lt;');
    BomT := BomReplaceStr(BomT, '>', '&gt;');
    BomT := BomReplaceStr(BomT, '"', '&quot;');
    Result := BomT;
end;

function BomUtf8Char(BomCp : Integer) : String;
begin
    if BomCp < 0 then BomCp := 0;
    if BomCp < 128 then
        Result := Chr(BomCp)
    else if BomCp < 2048 then
        Result := Chr(192 + (BomCp div 64)) + Chr(128 + (BomCp mod 64))
    else
        Result := Chr(224 + (BomCp div 4096)) +
                  Chr(128 + ((BomCp div 64) mod 64)) +
                  Chr(128 + (BomCp mod 64));
end;

function BomWin1251Cp(B : Integer) : Integer;
begin
    Result := B;
    if (B >= 192) and (B <= 255) then
        Result := 1040 + (B - 192);
    if B = 168 then Result := 1025;
    if B = 184 then Result := 1105;
end;

function BomToUtf8(const BomS : String) : String;
var
    Bomi, Cp, MaxCp : Integer;
begin
    MaxCp := 0;
    for Bomi := 1 to Length(BomS) do
        if Ord(BomS[Bomi]) > MaxCp then MaxCp := Ord(BomS[Bomi]);
    Result := '';
    for Bomi := 1 to Length(BomS) do
    begin
        Cp := Ord(BomS[Bomi]);
        if MaxCp <= 255 then
            Cp := BomWin1251Cp(Cp);
        Result := Result + BomUtf8Char(Cp);
    end;
end;

function ParamVal(BomComp : ISch_Component; const BomNames : String) : String;
var
    BomIter : ISch_Iterator;
    BomP : ISch_Parameter;
    Rest, BomName, PName, PText : String;
    PosSep : Integer;
begin
    { Имя параметра читаем обходом ISch_Parameter (eParameter). }
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
            BomIter := BomComp.SchIterator_Create;
            BomIter.AddFilter_ObjectSet(MkSet(eParameter));
            BomP := BomIter.FirstSchObject;
            while BomP <> nil do
            begin
                PName := '';
                PText := '';
                try PName := BomP.Name; except PName := ''; end;
                if UpperCase(PName) = UpperCase(BomName) then
                begin
                    try PText := BomP.Text; except PText := ''; end;
                    if PText <> '' then
                    begin
                        Result := PText;
                        BomComp.SchIterator_Destroy(BomIter);
                        Exit;
                    end;
                end;
                BomP := BomIter.NextSchObject;
            end;
            BomComp.SchIterator_Destroy(BomIter);
        except
        end;
    end;
end;

function FootprintOf(BomComp : ISch_Component) : String;
begin
    Result := ParamVal(BomComp, 'Footprint|PCBFootprint');
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
        QtyList.Add('1');
        DesLists.Add(BomDes);
        ExtraFields.Add(Fields);
    end
    else
    begin
        Qty := StrToInt(QtyList[BomIdx]) + 1;
        QtyList[BomIdx] := IntToStr(Qty);
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
        BomDes := ParamVal(BomComp, 'Designator');
        Comment := ParamVal(BomComp, 'Comment');
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

procedure BomShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
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
          Xml.Add('  <Format>Excel HTML (.xls), UTF-8</Format>');
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
    CellC, CellD, CellE, CellV : String;
begin
    { HTML Spreadsheet as .xls — Excel opens without XML security warning. UTF-8 BOM. }
    Lines := TStringList.Create;
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        Lines.Add(Chr(239) + Chr(187) + Chr(191) + '<html xmlns:o="urn:schemas-microsoft-com:office:office"');
        Lines.Add(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
        Lines.Add(' xmlns="http://www.w3.org/TR/REC-html40">');
        Lines.Add('<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">');
        Lines.Add('<!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet>');
        Lines.Add('<x:Name>BOM</x:Name><x:WorksheetOptions><x:FreezePanes/><x:FrozenNoSplit/>');
        Lines.Add('<x:SplitHorizontal>1</x:SplitHorizontal><x:TopRowBottomPane>1</x:TopRowBottomPane>');
        Lines.Add('</x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->');
        Lines.Add('<style>');
        Lines.Add('th { font-weight:bold; background:#DDDDDD; border:1px solid #666666; }');
        Lines.Add('td { border:1px solid #999999; vertical-align:top; }');
        Lines.Add('td.des { mso-number-format:"\@"; white-space:normal; }');
        Lines.Add('col.c { width:120pt; } col.d { width:220pt; } col.e { width:220pt; } col.q { width:50pt; } col.v { width:100pt; }');
        Lines.Add('</style></head><body><table border="1" cellspacing="0" cellpadding="4">');
        Lines.Add('<colgroup><col class="c"><col class="d"><col class="e"><col class="q"><col class="v"></colgroup>');
        Lines.Add('<tr><th>Comment</th><th>Designator</th><th>Description</th><th>Quantity</th><th>Value</th></tr>');
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Qty := StrToInt(QtyList[Bomi]);
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := BomToUtf8(XmlEsc(Parts[0]));
            CellD := BomToUtf8(XmlEsc(DesLists[Bomi]));
            CellE := BomToUtf8(XmlEsc(Parts[1]));
            CellV := BomToUtf8(XmlEsc(Parts[2]));
            Lines.Add('<tr><td>' + CellC + '</td><td class="des">' + CellD +
                      '</td><td>' + CellE + '</td><td align="right">' + IntToStr(Qty) +
                      '</td><td>' + CellV + '</td></tr>');
        end;
        Lines.Add('</table></body></html>');
        Lines.SaveToFile(OutPath);
        WriteSettingsXml(OutPath);
        BomShowBox(LabelInfoDone.Caption + OutPath + sLineBreak +
                   LabelInfoCount.Caption + IntToStr(Groups.Count), 64);
    finally
        Parts.Free;
        Lines.Free;
    end;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function BomCS_ScriptFolder : String;
var
    BomWS  : IWorkspace;
    BomPrj : IProject;
    Bomi   : Integer;
    BomP, BomName : String;
begin
    Result := '';
    try
        BomWS := GetWorkspace;
        if BomWS = nil then Exit;
        for Bomi := 0 to BomWS.DM_ProjectCount - 1 do
        begin
            BomPrj := BomWS.DM_Projects(Bomi);
            if BomPrj = nil then Continue;
            BomP := BomPrj.DM_ProjectFullPath;
            BomName := UpperCase(ExtractFileName(BomP));
            if BomName = 'BOMEXPORT.PRJSCR' then
            begin
                Result := ExtractFilePath(BomP);
                Exit;
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
        BomP := BomDir + BomFileName;
        if FileExists(BomP) then begin Result := BomP; Exit; end;
        BomP := BomDir + 'images\' + BomFileName;
        if FileExists(BomP) then begin Result := BomP; Exit; end;
    end;
    if FileExists(BomFileName) then begin Result := BomFileName; Exit; end;
    BomP := 'images\' + BomFileName;
    if FileExists(BomP) then Result := BomP;
end;

procedure BomCS_TryOneHelpFile(const BomName : String; var BomDone : Boolean);
var
    BomP : String;
begin
    if BomDone then Exit;
    BomP := BomCS_FindImageFile(BomName);
    if (BomP = '') or (not FileExists(BomP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(BomP);
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
        BomDone := True;
    except
    end;
end;

procedure BomCS_TryLoadHelpImage(const BomBmpName : String; const BomPngName : String);
var
    BomDone : Boolean;
begin
    BomDone := False;
    BomCS_TryOneHelpFile(BomPngName, BomDone);
    BomCS_TryOneHelpFile(BomBmpName, BomDone);
    BomCS_TryOneHelpFile('BomExport.png', BomDone);
    BomCS_TryOneHelpFile('BomExport.bmp', BomDone);
    if not BomDone then
        LabelImageHint.Caption := 'No image. Put ' + BomPngName + ' next to the script or in images\.';
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
        BomShowBox(LabelErrPath.Caption, 16);
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
    QtyList := TStringList.Create;
    try
        HarvestFromProject;
        if Groups.Count = 0 then
            BomShowBox(LabelWarnNone.Caption, 48)
        else
            WriteExcel;
    finally
        Groups.Free;
        DesLists.Free;
        ExtraFields.Free;
        QtyList.Free;
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
