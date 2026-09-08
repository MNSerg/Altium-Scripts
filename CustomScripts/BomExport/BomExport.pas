{..............................................................................}
{ BomExport.pas                                                                 }
{ BOM as HTML spreadsheet *.xls, charset windows-1251. Raw DM_ strings.         }
{ No UTF-16/UTF-8 recode. Table cells, wide wrapping columns.                   }
{ Value = DM_Comment. All sheets of the project.                                }
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

procedure WriteSettingsXml(const XlsPath : String);
var
    Xml : TStringList;
    XmlPath : String;
begin
    XmlPath := ChangeFileExt(XlsPath, '.bom.settings.xml');
    Xml := TStringList.Create;
    try
        Xml.Add('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.Add('<BomSettings generator="CustomScripts.BomExport" version="1.4">');
        Xml.Add('  <Output>' + XmlEsc(XlsPath) + '</Output>');
        Xml.Add('  <Format>HTML spreadsheet .xls windows-1251</Format>');
        Xml.Add('  <GroupBy>Value,Comment,Description,Footprint(internal)</GroupBy>');
        Xml.Add('  <ExcludeParts>None</ExcludeParts>');
        Xml.Add('  <Columns>Comment;Designator;Description;Value;Quantity</Columns>');
        Xml.Add('  <Notes>Value = DM_Comment. Raw CP1251 strings. No Unicode recode.</Notes>');
        Xml.Add('</BomSettings>');
        Xml.SaveToFile(XmlPath);
    finally
        Xml.Free;
    end;
end;

function BomTd(const BomS : String; BomHeader : Boolean) : String;
var
    BomSt : String;
begin
    BomSt := 'width:220pt; white-space:normal; mso-style-parent:yes; mso-data-placement:same-cell';
    if BomHeader then
        Result := '<th style="' + BomSt + '; font-weight:bold">' + XmlEsc(BomS) + '</th>'
    else
        Result := '<td style="' + BomSt + '">' + XmlEsc(BomS) + '</td>';
end;

procedure WriteHtmlXls(const XlsPath : String);
var
    BomF : TextFile;
    Bomi : Integer;
    Parts : TStringList;
    CellC, CellE, CellD, CellV : String;
begin
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    AssignFile(BomF, XlsPath);
    Rewrite(BomF);
    try
        WriteLn(BomF, '<html><head><meta http-equiv="Content-Type" content="text/html; charset=windows-1251"></head>');
        WriteLn(BomF, '<table border="1">');
        WriteLn(BomF, '<tr>' + BomTd('Comment', True) + BomTd('Designator', True) +
                      BomTd('Description', True) + BomTd('Value', True) +
                      BomTd('Quantity', True) + '</tr>');
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := Parts[0];
            CellE := Parts[1];
            CellV := Parts[2];
            CellD := DesLists[Bomi];
            WriteLn(BomF, '<tr>' + BomTd(CellC, False) + BomTd(CellD, False) +
                          BomTd(CellE, False) + BomTd(CellV, False) +
                          BomTd(QtyList[Bomi], False) + '</tr>');
        end;
        WriteLn(BomF, '</table></html>');
    finally
        CloseFile(BomF);
        Parts.Free;
    end;
end;

procedure WriteBomFiles;
begin
    if LowerCase(ExtractFileExt(OutPath)) <> '.xls' then
        OutPath := ChangeFileExt(OutPath, '.xls');
    WriteHtmlXls(OutPath);
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


function BomInitDir : String;
var
    BomWS : IWorkspace;
    BomPrj : IProject;
    BomDoc : IDocument;
    BomP : String;
begin
    Result := '';
    BomWS := GetWorkspace;
    if BomWS <> nil then
    begin
        BomPrj := BomWS.DM_FocusedProject;
        if BomPrj <> nil then
        begin
            BomP := BomPrj.DM_ProjectFullPath;
            if (BomP <> '') and (Pos('*', BomP) = 0) then
                Result := ExtractFilePath(BomP);
        end;
        if Result = '' then
        try
            BomDoc := BomWS.DM_FocusedDocument;
            if BomDoc <> nil then
                Result := ExtractFilePath(BomDoc.DM_FullPath);
        except
        end;
    end;
    if Result = '' then
    try
        Result := GetEnvironmentVariable('USERPROFILE') + '\Documents';
    except
        Result := '';
    end;
end;

function BomPathAllowed(const BomP : String) : Boolean;
var
    BomDir, BomName, BomU : String;
begin
    Result := False;
    if BomP = '' then Exit;
    BomName := ExtractFileName(BomP);
    if BomName = '' then Exit;
    BomDir := ExtractFilePath(BomP);
    BomU := UpperCase(BomP);
    if (BomU = 'C:\') or (BomU = 'C:') or (BomP = '/') or (BomP = '\') then Exit;
    if (BomDir = 'C:\') or (BomDir = '/') or (BomDir = '\') then Exit;
    Result := True;
end;

procedure TFormBom.FormBomShow(BomSender: TObject);
var
    BomDir : String;
begin
    try
        BomCS_TryLoadHelpImage('BomExport.bmp', 'BomExport.png');
    except
    end;
    BomDir := BomInitDir;
    if BomDir = '' then
        EditPath.Text := 'BOM.xls'
    else
        EditPath.Text := BomDir + 'BOM.xls';
end;

procedure TFormBom.ButtonBrowseClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := LabelDlgSave.Caption;
        BomDlg.Filter := 'Excel (*.xls)|*.xls|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xls';
        BomDlg.FileName := 'BOM.xls';
        BomDlg.InitialDir := BomInitDir;
        if BomDlg.Execute then
            EditPath.Text := BomDlg.FileName;
    finally
        BomDlg.Free;
    end;
end;

procedure TFormBom.ButtonOKClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := LabelDlgSave.Caption;
        BomDlg.Filter := 'Excel (*.xls)|*.xls|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xls';
        if EditPath.Text <> '' then
            BomDlg.FileName := ExtractFileName(EditPath.Text)
        else
            BomDlg.FileName := 'BOM.xls';
        BomDlg.InitialDir := BomInitDir;
        if ExtractFilePath(EditPath.Text) <> '' then
            BomDlg.InitialDir := ExtractFilePath(EditPath.Text);
        if not BomDlg.Execute then
            Exit;
        OutPath := BomDlg.FileName;
    finally
        BomDlg.Free;
    end;
    if not BomPathAllowed(OutPath) then
    begin
        BomShowBox(LabelErrPath.Caption, 16);
        Exit;
    end;
    if LowerCase(ExtractFileExt(OutPath)) <> '.xls' then
        OutPath := ChangeFileExt(OutPath, '.xls');
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
