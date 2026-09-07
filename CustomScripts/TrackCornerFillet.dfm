object FormFillet: TFormFillet
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1082#1088#1091#1075#1083#1077#1085#1080#1077' '#1091#1075#1083#1086#1074' '#1090#1088#1077#1082#1072
  ClientHeight = 170
  ClientWidth = 400
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
    Width = 368
    Height = 40
    AutoSize = False
    Caption = #1042#1099#1076#1077#1083#1080#1090#1077' '#1089#1077#1075#1084#1077#1085#1090#1099' '#1090#1088#1077#1082#1072' ('#1080' '#1089#1091#1097#1077#1089#1090#1074#1091#1102#1097#1080#1077' '#1076#1091#1075#1080'). '#1057#1082#1088#1091#1075#1083#1077#1085#1080#1103' '#1073#1091#1076#1091#1090' '#1087#1086#1089#1090#1072#1074#1083#1077#1085#1099' '#1085#1072' '#1074#1089#1077' '#1091#1075#1083#1099' '#1074#1099#1076#1077#1083#1077#1085#1085#1086#1075#1086' '#1087#1091#1090#1080'.'
    WordWrap = True
  end
  object LabelRadius: TLabel
    Left = 16
    Top = 64
    Width = 180
    Height = 13
    Caption = #1056#1072#1076#1080#1091#1089' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103', '#1084#1084':'
  end
  object EditRadius: TEdit
    Left = 240
    Top = 60
    Width = 140
    Height = 21
    TabOrder = 0
    Text = '0.5'
  end
  object ButtonOK: TButton
    Left = 96
    Top = 120
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 208
    Top = 120
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 2
    OnClick = ButtonCancelClick
  end
end
