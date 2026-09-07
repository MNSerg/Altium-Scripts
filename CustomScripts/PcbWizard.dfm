object FormWizard: TFormWizard
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1052#1072#1089#1090#1077#1088' '#1085#1086#1074#1086#1081' PCB'
  ClientHeight = 500
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormWizardShow
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
    Caption = 'images\PcbWizard.png'
    WordWrap = True
  end
  object LabelW: TLabel
    Left = 340
    Top = 16
    Width = 140
    Height = 13
    Caption = #1064#1080#1088#1080#1085#1072', '#1084#1084':'
  end
  object EditW: TEdit
    Left = 540
    Top = 12
    Width = 200
    Height = 21
    TabOrder = 0
    Text = '80'
  end
  object LabelH: TLabel
    Left = 340
    Top = 44
    Width = 140
    Height = 13
    Caption = #1042#1099#1089#1086#1090#1072', '#1084#1084':'
  end
  object EditH: TEdit
    Left = 540
    Top = 40
    Width = 200
    Height = 21
    TabOrder = 1
    Text = '50'
  end
  object LabelFillet: TLabel
    Left = 340
    Top = 72
    Width = 180
    Height = 13
    Caption = #1057#1082#1088#1091#1075#1083#1077#1085#1080#1077' '#1082#1086#1085#1090#1091#1088#1072', '#1084#1084':'
  end
  object EditFillet: TEdit
    Left = 540
    Top = 68
    Width = 200
    Height = 21
    TabOrder = 2
    Text = '2'
  end
  object LabelHole: TLabel
    Left = 340
    Top = 100
    Width = 180
    Height = 13
    Caption = #1054#1090#1074#1077#1088#1089#1090#1080#1077' '#1082#1088#1077#1087#1077#1078#1072', '#1084#1084':'
  end
  object EditHole: TEdit
    Left = 540
    Top = 96
    Width = 200
    Height = 21
    TabOrder = 3
    Text = '3.2'
  end
  object LabelPad: TLabel
    Left = 340
    Top = 128
    Width = 180
    Height = 13
    Caption = #1044#1080#1072#1084#1077#1090#1088' '#1087#1083#1086#1097#1072#1076#1082#1080', '#1084#1084':'
  end
  object EditPad: TEdit
    Left = 540
    Top = 124
    Width = 200
    Height = 21
    TabOrder = 4
    Text = '6'
  end
  object LabelMargin: TLabel
    Left = 340
    Top = 156
    Width = 180
    Height = 13
    Caption = #1054#1090#1089#1090#1091#1087' '#1086#1090' '#1091#1075#1083#1072', '#1084#1084':'
  end
  object EditMargin: TEdit
    Left = 540
    Top = 152
    Width = 200
    Height = 21
    TabOrder = 5
    Text = '4'
  end
  object LabelGrid: TLabel
    Left = 340
    Top = 184
    Width = 180
    Height = 13
    Caption = #1057#1077#1090#1082#1072', '#1084#1084':'
  end
  object EditGrid: TEdit
    Left = 540
    Top = 180
    Width = 200
    Height = 21
    TabOrder = 6
    Text = '0.1'
  end
  object LabelLayers: TLabel
    Left = 340
    Top = 212
    Width = 180
    Height = 13
    Caption = #1052#1077#1076#1085#1099#1093' '#1089#1083#1086#1105#1074' (2/4/6):'
  end
  object ComboLayers: TComboBox
    Left = 540
    Top = 208
    Width = 200
    Height = 21
    Style = csDropDownList
    ItemIndex = 1
    TabOrder = 7
    Text = '4'
    Items.Strings = (
      '2'
      '4'
      '6')
  end
  object CheckFourHoles: TCheckBox
    Left = 340
    Top = 248
    Width = 400
    Height = 17
    Caption = #1063#1077#1090#1099#1088#1077' '#1082#1088#1077#1087#1105#1078#1085#1099#1093' '#1086#1090#1074#1077#1088#1089#1090#1080#1103' '#1087#1086' '#1091#1075#1083#1072#1084
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object CheckGnd: TCheckBox
    Left = 340
    Top = 272
    Width = 400
    Height = 17
    Caption = #1057#1086#1079#1076#1072#1090#1100' '#1087#1086#1083#1080#1075#1086#1085#1099' GND'
    TabOrder = 9
  end
  object CheckMask: TCheckBox
    Left = 340
    Top = 296
    Width = 400
    Height = 17
    Caption = #1055#1086#1083#1080#1075#1086#1085' '#1074#1089#1082#1088#1099#1090#1080#1103' '#1084#1072#1089#1082#1080
    TabOrder = 10
  end
  object CheckNewDoc: TCheckBox
    Left = 340
    Top = 320
    Width = 400
    Height = 17
    Caption = #1057#1086#1079#1076#1072#1090#1100' '#1085#1086#1074#1099#1081' PcbDoc'
    Checked = True
    State = cbChecked
    TabOrder = 11
  end
  object ButtonOK: TButton
    Left = 420
    Top = 456
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 12
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 530
    Top = 456
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 13
    OnClick = ButtonCancelClick
  end
end
