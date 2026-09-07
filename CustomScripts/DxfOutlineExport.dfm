object FormDxf: TFormDxf
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'DXF: '#1082#1086#1085#1090#1091#1088#1099' '#1089#1083#1086#1105#1074' '#1083#1080#1085#1080#1103#1084#1080
  ClientHeight = 460
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormDxfShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageHelp: TImage
    Left = 8
    Top = 8
    Width = 320
    Height = 214
    Center = True
    Proportional = True
    Stretch = True
  end
  object LabelImageHint: TLabel
    Left = 8
    Top = 226
    Width = 320
    Height = 36
    AutoSize = False
    Caption = 'images\DxfExport.png'
    WordWrap = True
  end
  object LabelLayers: TLabel
    Left = 340
    Top = 8
    Width = 380
    Height = 28
    AutoSize = False
    Caption = #1052#1077#1076#1100' = '#1082#1086#1085#1090#1091#1088#1099' LINE/ARC. '#1054#1090#1074#1077#1088#1089#1090#1080#1103' = '#1089#1083#1086#1081' HOLES ('#1082#1088#1091#1075#1080'). '#1064#1077#1083#1082#1086#1075#1088#1072#1092#1080#1103' = Overlay.'
    WordWrap = True
  end
  object CheckListLayers: TCheckListBox
    Left = 340
    Top = 40
    Width = 384
    Height = 320
    ItemHeight = 13
    TabOrder = 0
  end
  object ButtonAll: TButton
    Left = 340
    Top = 368
    Width = 90
    Height = 25
    Caption = #1042#1089#1077
    TabOrder = 1
    OnClick = ButtonAllClick
  end
  object ButtonNone: TButton
    Left = 436
    Top = 368
    Width = 90
    Height = 25
    Caption = #1057#1085#1103#1090#1100
    TabOrder = 2
    OnClick = ButtonNoneClick
  end
  object ButtonCopper: TButton
    Left = 532
    Top = 368
    Width = 120
    Height = 25
    Caption = #1058#1086#1083#1100#1082#1086' '#1084#1077#1076#1100
    TabOrder = 3
    OnClick = ButtonCopperClick
  end
  object ButtonOK: TButton
    Left = 436
    Top = 420
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 540
    Top = 420
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = ButtonCancelClick
  end
end
