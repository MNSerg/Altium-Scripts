object FormBom: TFormBom
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1069#1082#1089#1087#1086#1088#1090' BOM'
  ClientHeight = 360
  ClientWidth = 440
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
  object LabelPath: TLabel
    Left = 16
    Top = 16
    Width = 80
    Height = 13
    Caption = #1060#1072#1081#1083' CSV:'
  end
  object EditPath: TEdit
    Left = 16
    Top = 32
    Width = 300
    Height = 21
    TabOrder = 0
  end
  object ButtonBrowse: TButton
    Left = 324
    Top = 30
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = ButtonBrowseClick
  end
  object CheckDnp: TCheckBox
    Left = 16
    Top = 72
    Width = 400
    Height = 17
    Caption = #1048#1089#1082#1083#1102#1095#1072#1090#1100' DNP / Not Fitted / No BOM / Graphical'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object CheckGroupMpn: TCheckBox
    Left = 16
    Top = 96
    Width = 400
    Height = 17
    Caption = #1043#1088#1091#1087#1087#1080#1088#1086#1074#1072#1090#1100' '#1090#1072#1082#1078#1077' '#1087#1086' Manufacturer Part Number'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object LabelCols: TLabel
    Left = 16
    Top = 128
    Width = 300
    Height = 80
    AutoSize = False
    Caption = #1057#1090#1086#1083#1073#1094#1099': Designator, Quantity, Comment, Description, Footprint, Value, Manufacturer, MPN, Supplier, SPN. '#1043#1088#1091#1087#1087#1080#1088#1086#1074#1082#1072': Comment+Footprint (+MPN).'
    WordWrap = True
  end
  object ButtonOK: TButton
    Left = 120
    Top = 310
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 230
    Top = 310
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = ButtonCancelClick
  end
end
