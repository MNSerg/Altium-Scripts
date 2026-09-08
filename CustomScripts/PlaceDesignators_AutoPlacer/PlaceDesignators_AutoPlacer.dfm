object Form_PlaceSilk: TForm_PlaceSilk
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1056#1072#1089#1089#1090#1072#1085#1086#1074#1082#1072' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1086#1074
  ClientHeight = 450
  ClientWidth = 473
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnClose = Form_PlaceSilkClose
  OnCreate = Form_PlaceSilkCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblCmpOutLayer: TLabel
    Left = 16
    Top = 180
    Width = 126
    Height = 13
    Caption = #1057#1083#1086#1081' '#1082#1086#1085#1090#1091#1088#1072' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072':'
  end
  object RotationStrategyLbl: TLabel
    Left = 16
    Top = 248
    Width = 90
    Height = 13
    Caption = #1057#1090#1088#1072#1090#1077#1075#1080#1103' '#1087#1086#1074#1086#1088#1086#1090#1072':'
  end
  object PositionDeltaLbl: TLabel
    Left = 226
    Top = 328
    Width = 65
    Height = 13
    Caption = #1064#1072#1075' '#1087#1086#1079#1080#1094#1080#1080
  end
  object Label2: TLabel
    Left = 226
    Top = 180
    Width = 41
    Height = 13
    Caption = #1055#1086#1079#1080#1094#1080#1080':'
  end
  object HintLbl: TLabel
    Left = 136
    Top = 430
    Width = 183
    Height = 13
    Caption = #1054#1089#1090#1072#1085#1086#1074': Ctrl + Pause/Break'
    Visible = False
  end
  object RG_Filter: TRadioGroup
    Left = 16
    Top = 16
    Width = 149
    Height = 72
    Caption = #1060#1080#1083#1100#1090#1088
    ItemIndex = 0
    Items.Strings = (
      #1042#1089#1103' '#1087#1083#1072#1090#1072
      #1042#1099#1076#1077#1083#1077#1085#1085#1099#1077)
    TabOrder = 0
  end
  object RG_Failures: TRadioGroup
    Left = 16
    Top = 95
    Width = 185
    Height = 73
    Caption = #1045#1089#1083#1080' '#1085#1077' '#1091#1076#1072#1083#1086#1089#1100
    ItemIndex = 0
    Items.Strings = (
      #1055#1086' '#1094#1077#1085#1090#1088#1091' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072
      #1057#1082#1088#1099#1090#1100' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088)
    TabOrder = 2
  end
  object GB_AllowUnder: TGroupBox
    Left = 224
    Top = 16
    Width = 216
    Height = 152
    Caption = #1056#1072#1079#1088#1077#1096#1080#1090#1100' '#1096#1077#1083#1082' '#1087#1086#1076' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072#1084#1080
    TabOrder = 1
    object MEM_AllowUnder: TMemo
      Left = 11
      Top = 27
      Width = 185
      Height = 109
      Lines.Strings = (
        'MEM_AllowUnder')
      TabOrder = 0
      OnEnter = MEM_AllowUnderEnter
    end
  end
  object BTN_Run: TButton
    Left = 367
    Top = 401
    Width = 75
    Height = 25
    Caption = #1047#1072#1087#1091#1089#1082
    TabOrder = 3
    OnClick = BTN_RunClick
  end
  object ProgressBar1: TProgressBar
    Left = 12
    Top = 403
    Width = 340
    Height = 22
    TabOrder = 4
  end
  object cbCmpOutlineLayer: TComboBox
    Left = 15
    Top = 198
    Width = 193
    Height = 21
    TabOrder = 5
    Text = 'cbCmpOutlineLayer'
    OnChange = cbCmpOutlineLayerChange
  end
  object chkAvoidVias: TCheckBox
    Left = 15
    Top = 226
    Width = 200
    Height = 17
    Caption = #1048#1079#1073#1077#1075#1072#1090#1100' '#1087#1077#1088#1077#1093#1086#1076#1085#1099#1093' '#1086#1090#1074#1077#1088#1089#1090#1080#1081
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object RotationStrategyCb: TComboBox
    Left = 16
    Top = 266
    Width = 193
    Height = 21
    Style = csDropDownList
    ItemIndex = 5
    TabOrder = 7
    Text = #1057#1090#1080#1083#1100' KLC'
    Items.Strings = (
      #1055#1086#1074#1086#1088#1086#1090' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1072
      #1043#1086#1088#1080#1079#1086#1085#1090#1072#1083#1100#1085#1086
      #1042#1076#1086#1083#1100' '#1089#1090#1086#1088#1086#1085#1099
      #1042#1076#1086#1083#1100' '#1086#1089#1080
      #1042#1076#1086#1083#1100' '#1074#1099#1074#1086#1076#1086#1074
      #1057#1090#1080#1083#1100' KLC')
  end
  object FixedSizeChk: TCheckBox
    Left = 16
    Top = 320
    Width = 200
    Height = 17
    Caption = #1060#1080#1082#1089'. '#1074#1099#1089#1086#1090#1072
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object FixedSizeEdt: TEdit
    Left = 96
    Top = 320
    Width = 113
    Height = 21
    TabOrder = 9
    Text = '0.8mm'
  end
  object FixedWidthChk: TCheckBox
    Left = 16
    Top = 344
    Width = 90
    Height = 17
    Caption = #1060#1080#1082#1089'. '#1090#1086#1083#1097#1080#1085#1072
    Checked = True
    State = cbChecked
    TabOrder = 10
  end
  object FixedWidthEdt: TEdit
    Left = 96
    Top = 344
    Width = 113
    Height = 21
    TabOrder = 11
    Text = '0.15mm'
  end
  object PositionDeltaEdt: TEdit
    Left = 226
    Top = 344
    Width = 214
    Height = 21
    TabOrder = 12
    Text = '0.42mm'
  end
  object PositionsClb: TCheckListBox
    Left = 226
    Top = 196
    Width = 214
    Height = 120
    ItemHeight = 13
    Items.Strings = (
      'TopCenter'
      'CenterRight'
      'BottomCenter'
      'CenterLeft'
      'TopLeft'
      'TopRight'
      'BottomLeft'
      'BottomRight')
    TabOrder = 13
  end
  object TryAlteredRotationChk: TCheckBox
    Left = 16
    Top = 296
    Width = 180
    Height = 17
    Caption = #1044#1088#1091#1075#1086#1081' '#1087#1086#1074#1086#1088#1086#1090
    Checked = True
    State = cbChecked
    TabOrder = 14
  end
  object WiggleChk: TCheckBox
    Left = 16
    Top = 374
    Width = 200
    Height = 17
    Caption = #1042#1090#1086#1088#1086#1081' '#1087#1088#1086#1093#1086#1076
    Checked = True
    State = cbChecked
    TabOrder = 15
  end
  object UnhideAllChk: TCheckBox
    Left = 226
    Top = 374
    Width = 214
    Height = 17
    Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1074#1089#1077' '#1076#1077#1089#1080#1075#1085#1072#1090#1086#1088#1099
    TabOrder = 16
  end
end
