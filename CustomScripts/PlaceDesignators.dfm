object FormSilk: TFormSilk
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1056#1072#1089#1089#1090#1072#1085#1086#1074#1082#1072' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074
  ClientHeight = 280
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
    Height = 48
    AutoSize = False
    Caption = #1064#1077#1083#1082#1086#1075#1088#1072#1092#1080#1095#1077#1089#1082#1080#1077' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1099' '#1089#1085#1072#1088#1091#1078#1080' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072', '#1073#1077#1079' '#1085#1072#1083#1086#1078#1077#1085#1080#1103' '#1085#1072' '#1087#1083#1086#1097#1072#1076#1082#1080'/'#1090#1088#1077#1082#1080'/'#1076#1088#1091#1075#1080#1077' '#1090#1077#1082#1089#1090#1099'. 0'#176' '#1080#1083#1080' 90'#176'.'
    WordWrap = True
  end
  object LabelH: TLabel
    Left = 16
    Top = 72
    Width = 220
    Height = 13
    Caption = #1042#1099#1089#1086#1090#1072' '#1090#1077#1082#1089#1090#1072', '#1084#1084' (0 = '#1085#1077' '#1084#1077#1085#1103#1090#1100'):'
  end
  object EditH: TEdit
    Left = 280
    Top = 68
    Width = 120
    Height = 21
    TabOrder = 0
    Text = '0'
  end
  object CheckSelected: TCheckBox
    Left = 16
    Top = 108
    Width = 380
    Height = 17
    Caption = #1058#1086#1083#1100#1082#1086' '#1074#1099#1076#1077#1083#1077#1085#1085#1099#1077' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1099' ('#1077#1089#1083#1080' '#1077#1089#1090#1100' '#1074#1099#1076#1077#1083#1077#1085#1080#1077')'
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object CheckSkipHidden: TCheckBox
    Left = 16
    Top = 132
    Width = 380
    Height = 17
    Caption = #1055#1088#1086#1087#1091#1089#1082#1072#1090#1100' '#1089#1082#1088#1099#1090#1099#1077' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1099
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object ButtonOK: TButton
    Left = 110
    Top = 230
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 220
    Top = 230
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 4
    OnClick = ButtonCancelClick
  end
end
