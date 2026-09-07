object FormSilk: TFormSilk
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1056#1072#1089#1089#1090#1072#1085#1086#1074#1082#1072' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074
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
  OnShow = FormSilkShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageHelp: TImage
    Left = 8
    Top = 8
    Width = 320
    Height = 214
  end
  object LabelImageHint: TLabel
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\PlaceDesignators.png'
    WordWrap = True
  end
  object LabelInfo: TLabel
    Left = 340
    Top = 12
    Width = 384
    Height = 72
    AutoSize = False
    Caption = #1058#1086#1083#1100#1082#1086' '#1096#1077#1083#1082#1086#1075#1088#1072#1092#1080#1103' (Top/Bottom Overlay). '#1045#1089#1083#1080' '#1074#1099#1076#1077#1083#1077#1085#1099' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1099' '#8212' '#1090#1086#1083#1100#1082#1086' '#1086#1085#1080'; '#1077#1089#1083#1080' '#1074#1099#1076#1077#1083#1077#1085#1080#1103' '#1085#1077#1090' '#8212' '#1074#1089#1077' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1099'.'
    WordWrap = True
  end
  object LabelH: TLabel
    Left = 340
    Top = 96
    Width = 220
    Height = 13
    Caption = #1042#1099#1089#1086#1090#1072' '#1090#1077#1082#1089#1090#1072', '#1084#1084' (0 = '#1085#1077' '#1084#1077#1085#1103#1090#1100'):'
  end
  object EditH: TEdit
    Left = 580
    Top = 92
    Width = 120
    Height = 21
    TabOrder = 0
    Text = '0'
  end
  object CheckSkipHidden: TCheckBox
    Left = 340
    Top = 132
    Width = 380
    Height = 17
    Caption = #1055#1088#1086#1087#1091#1089#1082#1072#1090#1100' '#1089#1082#1088#1099#1090#1099#1077' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1099
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object ButtonOK: TButton
    Left = 400
    Top = 290
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 510
    Top = 290
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
end
