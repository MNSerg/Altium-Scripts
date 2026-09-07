object FormDxf: TFormDxf
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'DXF: '#1082#1086#1085#1090#1091#1088#1099' '#1089#1083#1086#1105#1074' '#1083#1080#1085#1080#1103#1084#1080
  ClientHeight = 420
  ClientWidth = 420
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
  object LabelLayers: TLabel
    Left = 16
    Top = 12
    Width = 280
    Height = 13
    Caption = #1042#1099#1073#1077#1088#1080#1090#1077' '#1089#1083#1086#1080' PCB ('#1082#1072#1078#1076#1099#1081' '#1089#1090#1072#1085#1077#1090' '#1089#1083#1086#1077#1084' DXF'):'
  end
  object CheckListLayers: TCheckListBox
    Left = 16
    Top = 32
    Width = 388
    Height = 280
    ItemHeight = 13
    TabOrder = 0
  end
  object ButtonAll: TButton
    Left = 16
    Top = 320
    Width = 90
    Height = 25
    Caption = #1042#1089#1077
    TabOrder = 1
    OnClick = ButtonAllClick
  end
  object ButtonNone: TButton
    Left = 112
    Top = 320
    Width = 90
    Height = 25
    Caption = #1057#1085#1103#1090#1100
    TabOrder = 2
    OnClick = ButtonNoneClick
  end
  object ButtonCopper: TButton
    Left = 208
    Top = 320
    Width = 120
    Height = 25
    Caption = #1058#1086#1083#1100#1082#1086' '#1084#1077#1076#1100
    TabOrder = 3
    OnClick = ButtonCopperClick
  end
  object ButtonOK: TButton
    Left = 112
    Top = 372
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 216
    Top = 372
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = ButtonCancelClick
  end
end
