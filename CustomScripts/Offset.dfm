object FormOff: TFormOff
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Offset '#1090#1088#1077#1082#1086#1074
  ClientHeight = 300
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormOffShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageHelp: TImage
    Left = 8
    Top = 8
    Width = 320
    Height = 214
  end
  object LabelImageHint: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\Offset.png'
    WordWrap = True
  end
  object LabelInfo: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 12
    Width = 364
    Height = 56
    AutoSize = False
    Caption = #1042#1099#1076#1077#1083#1080#1090#1077' '#1090#1088#1077#1082#1080' ('#1086#1090#1082#1088#1099#1090#1072#1103' '#1094#1077#1087#1100' '#1080#1083#1080' '#1079#1072#1084#1082#1085#1091#1090#1099#1081' '#1082#1086#1085#1090#1091#1088'). '#1053#1072#1088#1091#1078#1091' = '#1089#1087#1088#1072#1074#1072' '#1087#1086' '#1093#1086#1076#1091' '#1076#1083#1103' CCW.'
    WordWrap = True
  end
  object LabelDist: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 76
    Width = 180
    Height = 13
    Caption = #1057#1084#1077#1097#1077#1085#1080#1077', '#1084#1084':'
  end
  object EditDist: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 540
    Top = 72
    Width = 160
    Height = 21
    TabOrder = 0
    Text = '0.5'
  end
  object RadioOut: TRadioButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 108
    Width = 360
    Height = 17
    Caption = #1053#1072#1088#1091#1078#1091
    Checked = True
    TabOrder = 1
    TabStop = True
  end
  object RadioIn: TRadioButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 132
    Width = 360
    Height = 17
    Caption = #1042#1085#1091#1090#1088#1100
    TabOrder = 2
  end
  object CheckReplace: TCheckBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 160
    Width = 360
    Height = 17
    Caption = #1047#1072#1084#1077#1085#1080#1090#1100' '#1080#1089#1093#1086#1076#1085#1099#1077
    TabOrder = 3
  end
  object ButtonOK: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 400
    Top = 250
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 4
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 510
    Top = 250
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = ButtonCancelClick
  end
  object LabelErrDist: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1089#1084#1077#1097#1077#1085#1080#1077' > 0 '#1084#1084' (0.5 '#1080#1083#1080' 0,5).'
  end
  object LabelErrNoPcb: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1054#1090#1082#1088#1086#1081#1090#1077' PCB-'#1076#1086#1082#1091#1084#1077#1085#1090'.'
  end
  object LabelWarnNone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1042#1099#1076#1077#1083#1080#1090#1077' '#1093#1086#1090#1103' '#1073#1099' '#1086#1076#1080#1085' '#1090#1088#1077#1082'.'
  end
  object LabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1057#1086#1079#1076#1072#1085#1086' '#1089#1077#1075#1084#1077#1085#1090#1086#1074': '
  end
  object LabelInfoDel: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1059#1076#1072#1083#1077#1085#1086' '#1080#1089#1093#1086#1076#1085#1099#1093': '
  end
end
