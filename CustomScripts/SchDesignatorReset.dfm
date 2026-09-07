object FormAnnot: TFormAnnot
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1073#1088#1086#1089' '#1080' '#1072#1085#1085#1086#1090#1072#1094#1080#1103' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074
  ClientHeight = 340
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormAnnotShow
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
    Height = 40
    AutoSize = False
    Caption = 'images\SchAnnotate.png'
    WordWrap = True
  end
  object LabelInfo: TLabel
    Left = 340
    Top = 12
    Width = 384
    Height = 72
    AutoSize = False
    Caption = #1042#1077#1089#1100' '#1087#1088#1086#1077#1082#1090'. '#1055#1086#1088#1103#1076#1086#1082' Altium Down then Across: '#1089#1085#1072#1095#1072#1083#1072' '#1082#1086#1083#1086#1085#1082#1072' '#1089#1074#1077#1088#1093#1091' '#1074#1085#1080#1079', '#1079#1072#1090#1077#1084' '#1089#1083#1077#1076#1091#1102#1097#1072#1103' '#1089#1083#1077#1074#1072' '#1085#1072#1087#1088#1072#1074#1086'. '#1053#1077' Across then Down.'
    WordWrap = True
  end
  object CheckReset: TCheckBox
    Left = 340
    Top = 96
    Width = 380
    Height = 17
    Caption = #1057#1085#1072#1095#1072#1083#1072' '#1089#1073#1088#1086#1089#1080#1090#1100' '#1074' "?"'
    TabOrder = 0
  end
  object CheckAnnotate: TCheckBox
    Left = 340
    Top = 124
    Width = 380
    Height = 17
    Caption = #1055#1077#1088#1077#1085#1091#1084#1077#1088#1086#1074#1072#1090#1100' Down then Across'
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object CheckAllSheets: TCheckBox
    Left = 340
    Top = 152
    Width = 380
    Height = 17
    Caption = #1042#1089#1077' '#1083#1080#1089#1090#1099' '#1089#1093#1077#1084#1099' '#1087#1088#1086#1077#1082#1090#1072
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object ButtonOK: TButton
    Left = 400
    Top = 290
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 510
    Top = 290
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 4
    OnClick = ButtonCancelClick
  end
end
