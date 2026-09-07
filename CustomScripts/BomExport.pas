{..............................................................................}
{ BomExport.pas                                                                 }
{ BOM в Excel (.xlsx OOXML) без COM. Все листы проекта, разделение по Value.
  Столбцы как BOM_UniBrain.xlsx: Comment, Description, Designator, Value, Quantity. }
{..............................................................................}

var
    OutPath     : String;
    BomTitle    : String;
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

function ParamVal(BomComp : IComponent; const BomNames : String) : String;
begin
    { Нет безопасного getter значения параметра (DM_Value / DM_PhysicalValue undeclared). }
    Result := '';
end;

function FootprintOf(BomComp : IComponent) : String;
begin
    Result := '';
    try Result := BomComp.DM_FootPrint; except Result := ''; end;
    if Result = '' then
        Result := ParamVal(BomComp, 'Footprint|PCBFootprint');
end;

procedure AddPart(const BomDes, Comment, Description, Footprint, Value : String);
var
    BomKey, Fields : String;
    BomIdx, Qty : Integer;
begin
    { Ключ: Value (+ Comment/Description/Footprint) — разделение по Value. }
    BomKey := UpperCase(Value) + '||' + UpperCase(Comment) + '||' +
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

procedure HarvestDmDoc(BomLogDoc : IDocument);
var
    Bomi, Bomn : Integer;
    BomComp : IComponent;
    BomDes, Comment, Desc, Fp, BomVal : String;
begin
    { Индексный обход IDocument (тот же DM_, что Auto_Panelizer.pas: DM_FocusedProject).
      В !SCRIPTS нет schematic-итератора — Create не используем. }
    if BomLogDoc = nil then Exit;
    try
        Bomn := BomLogDoc.DM_ComponentCount;
    except
        Bomn := 0;
    end;
    for Bomi := 0 to Bomn - 1 do
    begin
        BomComp := BomLogDoc.DM_Components(Bomi);
        if BomComp = nil then Continue;
        BomDes := '';
        Comment := '';
        Desc := '';
        Fp := '';
        BomVal := '';
        try BomDes := BomComp.DM_PhysicalDesignator; except BomDes := ''; end;
        if BomDes = '' then
        try BomDes := BomComp.DM_LogicalDesignator; except BomDes := ''; end;
        if BomDes = '' then
            BomDes := ParamVal(BomComp, 'Designator');
        try Comment := BomComp.DM_Comment; except Comment := ''; end;
        BomVal := Comment;
        Desc := '';
        Fp := FootprintOf(BomComp);
        AddPart(BomDes, Comment, Desc, Fp, BomVal);
    end;
end;

procedure HarvestFromProject;
var
    BomWS : IWorkspace;
    BomProject : IProject;
    Bomi : Integer;
    BomLogDoc : IDocument;
    BomBoard : IPCB_Board;
    BomCmp : IPCB_Component;
    BomIter : IPCB_BoardIterator;
    BomDes, Comment, Fp : String;
begin
    BomWS := GetWorkspace;
    if BomWS = nil then Exit;
    BomProject := BomWS.DM_FocusedProject;
    BomTitle := 'BOM';
    try
        if BomProject <> nil then
            BomTitle := ChangeFileExt(ExtractFileName(BomProject.DM_ProjectFullPath), '');
    except
        BomTitle := 'BOM';
    end;
    if BomTitle = '' then BomTitle := 'BOM';

    if BomProject <> nil then
    begin
        try
            BomProject.DM_Compile;
        except
        end;
        for Bomi := 0 to BomProject.DM_LogicalDocumentCount - 1 do
        begin
            BomLogDoc := BomProject.DM_LogicalDocuments(Bomi);
            if (BomLogDoc.DM_DocumentKind = 'SCH') or (BomLogDoc.DM_DocumentKind = 'SCHDOC') then
                HarvestDmDoc(BomLogDoc);
        end;
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

function BomCrc32Of(const BomS : String) : Integer;
var
    Crc, Bomi, Bomj, B : Integer;
begin
    Crc := -1;
    for Bomi := 1 to Length(BomS) do
    begin
        B := Ord(BomS[Bomi]) and 255;
        Crc := Crc xor B;
        for Bomj := 1 to 8 do
        begin
            if (Crc and 1) <> 0 then
                Crc := ((Crc shr 1) and $7FFFFFFF) xor $EDB88320
            else
                Crc := (Crc shr 1) and $7FFFFFFF;
        end;
    end;
    Result := Crc xor -1;
end;

procedure BomWriteByte(var BomF : File; BomV : Integer);
var
    BomB : Byte;
begin
    BomB := BomV and 255;
    BlockWrite(BomF, BomB, 1);
end;

procedure BomWriteBytes(var BomF : File; const BomS : String);
var
    Bomi : Integer;
begin
    for Bomi := 1 to Length(BomS) do
        BomWriteByte(BomF, Ord(BomS[Bomi]));
end;

procedure BomWriteU16(var BomF : File; BomV : Integer);
begin
    BomWriteByte(BomF, BomV);
    BomWriteByte(BomF, BomV shr 8);
end;

procedure BomWriteU32(var BomF : File; BomV : Integer);
begin
    BomWriteByte(BomF, BomV);
    BomWriteByte(BomF, BomV shr 8);
    BomWriteByte(BomF, BomV shr 16);
    BomWriteByte(BomF, BomV shr 24);
end;

function BomSsIndex(Ss : TStringList; const BomS : String) : Integer;
begin
    Result := Ss.IndexOf(BomS);
    if Result < 0 then
    begin
        Ss.Add(BomS);
        Result := Ss.Count - 1;
    end;
end;

procedure BomZipLocal(var BomF : File; const ZName, ZBody : String);
var
    Crc : Integer;
begin
    Crc := BomCrc32Of(ZBody);
    BomWriteBytes(BomF, 'PK' + Chr(3) + Chr(4));
    BomWriteU16(BomF, 20);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU32(BomF, Crc);
    BomWriteU32(BomF, Length(ZBody));
    BomWriteU32(BomF, Length(ZBody));
    BomWriteU16(BomF, Length(ZName));
    BomWriteU16(BomF, 0);
    BomWriteBytes(BomF, ZName);
    BomWriteBytes(BomF, ZBody);
end;

procedure BomZipCentral(var BomF : File; const ZName, ZBody : String; ZOff : Integer);
var
    Crc : Integer;
begin
    Crc := BomCrc32Of(ZBody);
    BomWriteBytes(BomF, 'PK' + Chr(1) + Chr(2));
    BomWriteU16(BomF, 20);
    BomWriteU16(BomF, 20);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU32(BomF, Crc);
    BomWriteU32(BomF, Length(ZBody));
    BomWriteU32(BomF, Length(ZBody));
    BomWriteU16(BomF, Length(ZName));
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU16(BomF, 0);
    BomWriteU32(BomF, 0);
    BomWriteU32(BomF, ZOff);
    BomWriteBytes(BomF, ZName);
end;

procedure BomWriteUtf16Xml(const XmlPath, BodyUni : String);
var
    BomF : File;
    Bomi, Cp, MaxCp : Integer;
begin
    AssignFile(BomF, XmlPath);
    Rewrite(BomF, 1);
    try
        BomWriteByte(BomF, 255);
        BomWriteByte(BomF, 254);
        MaxCp := 0;
        for Bomi := 1 to Length(BodyUni) do
            if Ord(BodyUni[Bomi]) > MaxCp then MaxCp := Ord(BodyUni[Bomi]);
        for Bomi := 1 to Length(BodyUni) do
        begin
            Cp := Ord(BodyUni[Bomi]);
            if MaxCp <= 255 then
                Cp := BomWin1251Cp(Cp);
            BomWriteByte(BomF, Cp);
            BomWriteByte(BomF, Cp shr 8);
        end;
    finally
        CloseFile(BomF);
    end;
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
        Xml.Add('<BomSettings generator="CustomScripts.BomExport" version="1.2">');
        Xml.Add('  <Output>' + XmlEsc(XlsPath) + '</Output>');
        Xml.Add('  <Format>Office Open XML (.xlsx) UTF-8 + CSV UTF-8 BOM</Format>');
        Xml.Add('  <GroupBy>Value,Comment,Description,Footprint(internal)</GroupBy>');
        Xml.Add('  <ExcludeParts>None</ExcludeParts>');
        Xml.Add('  <Columns>Comment,Description,Designator,Value,Quantity</Columns>');
        Xml.Add('  <Notes>Matches BOM_UniBrain.xlsx. All schematic sheets. No exclusions.</Notes>');
        Xml.Add('</BomSettings>');
        Xml.SaveToFile(XmlPath);
    finally
        Xml.Free;
    end;
end;

function BomCsvEsc(const BomS : String) : String;
begin
    if (Pos(',', BomS) > 0) or (Pos('"', BomS) > 0) or (Pos(Chr(10), BomS) > 0) then
        Result := '"' + BomReplaceStr(BomS, '"', '""') + '"'
    else
        Result := BomS;
end;

procedure BomPutUtf8Line(var BomF : File; const BomS : String);
var
    Bi : Integer;
    Enc : String;
begin
    Enc := BomToUtf8(BomS);
    for Bi := 1 to Length(Enc) do
        BomWriteByte(BomF, Ord(Enc[Bi]));
    BomWriteByte(BomF, 13);
    BomWriteByte(BomF, 10);
end;

procedure WriteCsvUtf8(const CsvPath : String);
var
    BomF : File;
    Bomi : Integer;
    Parts : TStringList;
    Line, CellC, CellE, CellD, CellV : String;
begin
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    AssignFile(BomF, CsvPath);
    Rewrite(BomF, 1);
    try
        BomWriteByte(BomF, 239);
        BomWriteByte(BomF, 187);
        BomWriteByte(BomF, 191);
        BomPutUtf8Line(BomF, BomCsvEsc(BomTitle));
        BomPutUtf8Line(BomF, 'Comment,Description,Designator,Value,Quantity');
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := Parts[0];
            CellE := Parts[1];
            CellV := Parts[2];
            CellD := DesLists[Bomi];
            Line := BomCsvEsc(CellC) + ',' + BomCsvEsc(CellE) + ',' + BomCsvEsc(CellD) + ',' +
                    BomCsvEsc(CellV) + ',' + QtyList[Bomi];
            BomPutUtf8Line(BomF, Line);
        end;
    finally
        CloseFile(BomF);
        Parts.Free;
    end;
end;

procedure WriteXlsx;
var
    BomF : File;
    Ss : TStringList;
    Names, Bodies : TStringList;
    Offs : TStringList;
    Parts : TStringList;
    Bomi, LastRow, CdStart, CdSize, LocalOff : Integer;
    Sheet, Sst, Styles, Wb, Wr, Rels, Ct : String;
    CellC, CellE, CellD, CellV : String;
    SiT, SiC, SiD, SiE, SiV : Integer;
begin
    { OOXML STORE zip. UTF-8 internals. Стиль как BOM_UniBrain.xlsx. }
    Ss := TStringList.Create;
    Names := TStringList.Create;
    Bodies := TStringList.Create;
    Offs := TStringList.Create;
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        LastRow := Groups.Count + 2;
        BomSsIndex(Ss, BomTitle);
        BomSsIndex(Ss, 'Comment');
        BomSsIndex(Ss, 'Description');
        BomSsIndex(Ss, 'Designator');
        BomSsIndex(Ss, 'Value');
        BomSsIndex(Ss, 'Quantity');

        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            BomSsIndex(Ss, Parts[0]);
            BomSsIndex(Ss, Parts[1]);
            BomSsIndex(Ss, DesLists[Bomi]);
            BomSsIndex(Ss, Parts[2]);
        end;

        Sst := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="' +
            IntToStr(Ss.Count) + '" uniqueCount="' + IntToStr(Ss.Count) + '">');
        for Bomi := 0 to Ss.Count - 1 do
            Sst := Sst + BomToUtf8('<si><t xml:space="preserve">') + BomToUtf8(XmlEsc(Ss[Bomi])) +
                   BomToUtf8('</t></si>');
        Sst := Sst + BomToUtf8('</sst>');

        Sheet := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
            '<dimension ref="A1:E' + IntToStr(LastRow) + '"/>' +
            '<sheetViews><sheetView tabSelected="1" workbookViewId="0"/></sheetViews>' +
            '<sheetFormatPr defaultRowHeight="15"/>' +
            '<cols>' +
            '<col min="1" max="1" width="22.5" customWidth="1"/>' +
            '<col min="2" max="2" width="20" customWidth="1"/>' +
            '<col min="3" max="3" width="20" customWidth="1"/>' +
            '<col min="4" max="4" width="12" customWidth="1"/>' +
            '<col min="5" max="5" width="10" customWidth="1"/>' +
            '</cols><sheetData>');
        SiT := BomSsIndex(Ss, BomTitle);
        Sheet := Sheet + BomToUtf8('<row r="1"><c r="A1" s="5" t="s"><v>' + IntToStr(SiT) +
            '</v></c></row>');
        Sheet := Sheet + BomToUtf8('<row r="2">' +
            '<c r="A2" s="2" t="s"><v>' + IntToStr(BomSsIndex(Ss, 'Comment')) + '</v></c>' +
            '<c r="B2" s="2" t="s"><v>' + IntToStr(BomSsIndex(Ss, 'Description')) + '</v></c>' +
            '<c r="C2" s="3" t="s"><v>' + IntToStr(BomSsIndex(Ss, 'Designator')) + '</v></c>' +
            '<c r="D2" s="2" t="s"><v>' + IntToStr(BomSsIndex(Ss, 'Value')) + '</v></c>' +
            '<c r="E2" s="2" t="s"><v>' + IntToStr(BomSsIndex(Ss, 'Quantity')) + '</v></c>' +
            '</row>');
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := Parts[0];
            CellE := Parts[1];
            CellV := Parts[2];
            CellD := DesLists[Bomi];
            SiC := BomSsIndex(Ss, CellC);
            SiE := BomSsIndex(Ss, CellE);
            SiD := BomSsIndex(Ss, CellD);
            SiV := BomSsIndex(Ss, CellV);
            Sheet := Sheet + BomToUtf8('<row r="' + IntToStr(Bomi + 3) + '">' +
                '<c r="A' + IntToStr(Bomi + 3) + '" s="1" t="s"><v>' + IntToStr(SiC) + '</v></c>' +
                '<c r="B' + IntToStr(Bomi + 3) + '" s="1" t="s"><v>' + IntToStr(SiE) + '</v></c>' +
                '<c r="C' + IntToStr(Bomi + 3) + '" s="4" t="s"><v>' + IntToStr(SiD) + '</v></c>' +
                '<c r="D' + IntToStr(Bomi + 3) + '" s="1" t="s"><v>' + IntToStr(SiV) + '</v></c>' +
                '<c r="E' + IntToStr(Bomi + 3) + '" s="1"><v>' + QtyList[Bomi] + '</v></c>' +
                '</row>');
        end;
        Sheet := Sheet + BomToUtf8('</sheetData><mergeCells count="1"><mergeCell ref="A1:E1"/></mergeCells>' +
            '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>' +
            '</worksheet>');

        Styles := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
            '<fonts count="2"><font><sz val="11"/><name val="Calibri"/><charset val="204"/></font>' +
            '<font><b/><sz val="11"/><name val="Calibri"/><charset val="204"/></font></fonts>' +
            '<fills count="3"><fill><patternFill patternType="none"/></fill>' +
            '<fill><patternFill patternType="gray125"/></fill>' +
            '<fill><patternFill patternType="solid"><fgColor rgb="FFD3D3D3"/></patternFill></fill></fills>' +
            '<borders count="2"><border><left/><right/><top/><bottom/></border>' +
            '<border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="thin"/></border></borders>' +
            '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
            '<cellXfs count="6">' +
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>' +
            '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1"/>' +
            '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment wrapText="1"/></xf>' +
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment wrapText="1"/></xf>' +
            '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center"/></xf>' +
            '</cellXfs></styleSheet>');

        Wb := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ' +
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
            '<sheets><sheet name="BOM" sheetId="1" r:id="rId1"/></sheets></workbook>');
        Wr := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>' +
            '</Relationships>');
        Rels := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
            '</Relationships>');
        Ct := BomToUtf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>' +
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
            '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' +
            '</Types>');

        Names.Add('[Content_Types].xml'); Bodies.Add(Ct);
        Names.Add('_rels/.rels'); Bodies.Add(Rels);
        Names.Add('xl/workbook.xml'); Bodies.Add(Wb);
        Names.Add('xl/_rels/workbook.xml.rels'); Bodies.Add(Wr);
        Names.Add('xl/worksheets/sheet1.xml'); Bodies.Add(Sheet);
        Names.Add('xl/sharedStrings.xml'); Bodies.Add(Sst);
        Names.Add('xl/styles.xml'); Bodies.Add(Styles);

        AssignFile(BomF, OutPath);
        Rewrite(BomF, 1);
        try
            LocalOff := 0;
            for Bomi := 0 to Names.Count - 1 do
            begin
                Offs.Add(IntToStr(LocalOff));
                BomZipLocal(BomF, Names[Bomi], Bodies[Bomi]);
                LocalOff := LocalOff + 30 + Length(Names[Bomi]) + Length(Bodies[Bomi]);
            end;
            CdStart := LocalOff;
            for Bomi := 0 to Names.Count - 1 do
                BomZipCentral(BomF, Names[Bomi], Bodies[Bomi], StrToInt(Offs[Bomi]));
            CdSize := 0;
            for Bomi := 0 to Names.Count - 1 do
                CdSize := CdSize + 46 + Length(Names[Bomi]);
            BomWriteBytes(BomF, 'PK' + Chr(5) + Chr(6));
            BomWriteU16(BomF, 0);
            BomWriteU16(BomF, 0);
            BomWriteU16(BomF, Names.Count);
            BomWriteU16(BomF, Names.Count);
            BomWriteU32(BomF, CdSize);
            BomWriteU32(BomF, CdStart);
            BomWriteU16(BomF, 0);
        finally
            CloseFile(BomF);
        end;
    finally
        Parts.Free;
        Offs.Free;
        Bodies.Free;
        Names.Free;
        Ss.Free;
    end;
end;

procedure WriteSpreadsheetXml(const XmlPath : String);
var
    Body : String;
    Bomi : Integer;
    Parts : TStringList;
    CellC, CellE, CellD, CellV : String;
begin
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        Body := '<?xml version="1.0"?>' +
            '<?mso-application progid="Excel.Sheet"?>' +
            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" ' +
            'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">' +
            '<Styles>' +
            '<Style ss:ID="Title"><Font ss:Bold="1"/><Interior ss:Color="#D3D3D3" ss:Pattern="Solid"/>' +
            '<Alignment ss:Horizontal="Center"/></Style>' +
            '<Style ss:ID="Hdr"><Font ss:Bold="1"/><Interior ss:Color="#D3D3D3" ss:Pattern="Solid"/>' +
            '<Borders><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' +
            '<Style ss:ID="Cell"><Borders><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' +
            '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' +
            '</Styles><Worksheet ss:Name="BOM"><Table>' +
            '<Column ss:Width="120"/><Column ss:Width="120"/><Column ss:Width="140"/><Column ss:Width="80"/><Column ss:Width="50"/>' +
            '<Row><Cell ss:MergeAcross="4" ss:StyleID="Title"><Data ss:Type="String">' + XmlEsc(BomTitle) + '</Data></Cell></Row>' +
            '<Row>' +
            '<Cell ss:StyleID="Hdr"><Data ss:Type="String">Comment</Data></Cell>' +
            '<Cell ss:StyleID="Hdr"><Data ss:Type="String">Description</Data></Cell>' +
            '<Cell ss:StyleID="Hdr"><Data ss:Type="String">Designator</Data></Cell>' +
            '<Cell ss:StyleID="Hdr"><Data ss:Type="String">Value</Data></Cell>' +
            '<Cell ss:StyleID="Hdr"><Data ss:Type="String">Quantity</Data></Cell></Row>';
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := Parts[0];
            CellE := Parts[1];
            CellV := Parts[2];
            CellD := DesLists[Bomi];
            Body := Body + '<Row>' +
                '<Cell ss:StyleID="Cell"><Data ss:Type="String">' + XmlEsc(CellC) + '</Data></Cell>' +
                '<Cell ss:StyleID="Cell"><Data ss:Type="String">' + XmlEsc(CellE) + '</Data></Cell>' +
                '<Cell ss:StyleID="Cell"><Data ss:Type="String">' + XmlEsc(CellD) + '</Data></Cell>' +
                '<Cell ss:StyleID="Cell"><Data ss:Type="String">' + XmlEsc(CellV) + '</Data></Cell>' +
                '<Cell ss:StyleID="Cell"><Data ss:Type="Number">' + QtyList[Bomi] + '</Data></Cell></Row>';
        end;
        Body := Body + '</Table></Worksheet></Workbook>';
        BomWriteUtf16Xml(XmlPath, Body);
    finally
        Parts.Free;
    end;
end;

procedure WriteBomFiles;
var
    Ext, CsvPath : String;
begin
    Ext := LowerCase(ExtractFileExt(OutPath));
    if Ext = '.csv' then
        WriteCsvUtf8(OutPath)
    else if Ext = '.xml' then
        WriteSpreadsheetXml(OutPath)
    else
    begin
        if Ext <> '.xlsx' then
            OutPath := ChangeFileExt(OutPath, '.xlsx');
        WriteXlsx;
        CsvPath := ChangeFileExt(OutPath, '.csv');
        WriteCsvUtf8(CsvPath);
    end;
    WriteSettingsXml(OutPath);
    BomShowBox(LabelInfoDone.Caption + OutPath + sLineBreak +
               LabelInfoCount.Caption + IntToStr(Groups.Count), 64);
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
        EditPath.Text := 'bom.xlsx';
end;

procedure TFormBom.ButtonBrowseClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := 'Сохранить BOM';
        BomDlg.Filter := 'Excel (*.xlsx)|*.xlsx|CSV UTF-8 (*.csv)|*.csv|Excel XML (*.xml)|*.xml|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xlsx';
        BomDlg.FileName := 'bom.xlsx';
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
    if LowerCase(ExtractFileExt(OutPath)) = '.xls' then
        OutPath := ChangeFileExt(OutPath, '.xlsx');
    if LowerCase(ExtractFileExt(OutPath)) = '' then
        OutPath := OutPath + '.xlsx';
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
            WriteBomFiles;
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
