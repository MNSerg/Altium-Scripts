object FormAnnot: TFormAnnot
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1073#1088#1086#1089' '#1080' '#1072#1085#1085#1086#1090#1072#1094#1080#1103' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074
  ClientHeight = 240
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object LabelInfo: TLabel
    Left = 16
    Top = 12
    Width = 388
    Height = 40
    AutoSize = False
    Caption = #1057#1073#1088#1086#1089' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074' '#1074' "?" '#1080'/'#1080#1083#1080' '#1087#1086#1079#1080#1094#1080#1086#1085#1085#1072#1103' '#1087#1077#1088#1077#1085#1091#1084#1077#1088#1072#1094#1080#1103' (слева направо, '#1089#1074#1077#1088#1093#1091' '#1074#1085#1080#1079'). '#1055#1088#1077#1092#1080#1082#1089#1099' R, C, U '#1089#1086#1093#1088#1072#1085#1103#1102#1090#1089#1103'.'
    WordWrap = True
  end
  object CheckReset: TCheckBox
    Left = 16
    Top = 64
    Width = 380
    Height = 17
    Caption = #1057#1073#1088#1086#1089#1080#1090#1100' '#1074#1089#1077' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1099' '#1074' "?" (unannotated)'
    Checked = True
    State = cbChecked
    TabOrder = 0
  end
  object CheckAnnotate: TCheckBox
    Left = 16
    Top = 92
    Width = 380
    Height = 17
    Caption = #1055#1077#1088#1077#1085#1091#1084#1077#1088#1086#1074#1072#1090#1100' '#1087#1086#1079#1080#1094#1080#1086#1085#1085#1086
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object CheckAllSheets: TCheckBox
    Left = 16
    Top = 120
    Width = 380
    Height = 17
    Caption = #1042#1089#1077' '#1083#1080#1089#1090#1099' '#1089#1093#1077#1084#1099' '#1087#1088#1086#1077#1082#1090#1072' (иначе '#1090#1086#1083#1100#1082#1086' '#1090#1077#1082#1091#1099#1080#1081')'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object ButtonOK: TButton
    Left = 110
    Top = 190
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 220
    Top = 190
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 4
    OnClick = ButtonCancelClick
  end
end
