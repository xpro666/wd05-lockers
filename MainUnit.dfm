object frmCdxWD05: TfrmCdxWD05
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Carddex WD-05 tester'
  ClientHeight = 539
  ClientWidth = 669
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    669
    539)
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTool: TPanel
    Left = 0
    Top = 0
    Width = 669
    Height = 41
    Align = alTop
    Caption = 'pnlTool'
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      669
      41)
    object lblPort: TLabel
      Left = 8
      Top = 14
      Width = 20
      Height = 13
      Caption = 'Port'
    end
    object lblDeviceAddress: TLabel
      Left = 210
      Top = 14
      Width = 74
      Height = 13
      Caption = 'Device Address'
    end
    object cbbComPorts: TComboBox
      Left = 44
      Top = 11
      Width = 77
      Height = 21
      TabOrder = 0
    end
    object btnOpenPort: TButton
      Left = 128
      Top = 9
      Width = 75
      Height = 25
      Action = actActivePort
      TabOrder = 1
    end
    object btnPing: TButton
      Left = 372
      Top = 9
      Width = 88
      Height = 25
      Action = actPing
      Anchors = [akTop, akRight]
      TabOrder = 2
    end
    object chkAutoPing: TCheckBox
      Left = 466
      Top = 13
      Width = 124
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'Auto ping with interval'
      TabOrder = 3
    end
    object sePingInterval: TSpinEdit
      Left = 598
      Top = 11
      Width = 63
      Height = 22
      Anchors = [akTop, akRight]
      MaxValue = 1000
      MinValue = 1
      TabOrder = 4
      Value = 5
    end
    object seDeviceAddres: TSpinEdit
      Left = 289
      Top = 11
      Width = 57
      Height = 22
      MaxValue = 254
      MinValue = 1
      TabOrder = 5
      Value = 1
    end
  end
  object mmoLog: TMemo
    Left = 0
    Top = 399
    Width = 669
    Height = 140
    Align = alBottom
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object grpManufactureSettings: TGroupBox
    Left = 0
    Top = 103
    Width = 330
    Height = 114
    Caption = 'Manufacture Settings'
    TabOrder = 2
    DesignSize = (
      330
      114)
    object lblSN: TLabel
      Left = 16
      Top = 27
      Width = 66
      Height = 13
      Caption = 'Serial Number'
    end
    object edtSN: TEdit
      Left = 206
      Top = 24
      Width = 121
      Height = 21
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      NumbersOnly = True
      TabOrder = 0
      Text = '0'
    end
    object btnGetSN: TButton
      Left = 138
      Top = 51
      Width = 86
      Height = 25
      Action = actGetSN
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
    object btnSetSN: TButton
      Left = 230
      Top = 51
      Width = 97
      Height = 25
      Action = actSetSN
      Anchors = [akTop, akRight]
      TabOrder = 2
    end
    object btnReset: TButton
      Left = 230
      Top = 82
      Width = 97
      Height = 25
      Action = actReset
      Anchors = [akTop, akRight]
      TabOrder = 3
    end
  end
  object grpDeviceInfo: TGroupBox
    Left = 0
    Top = 47
    Width = 330
    Height = 50
    Caption = ' Device Info'
    TabOrder = 3
    object lblFW: TLabel
      Left = 16
      Top = 24
      Width = 87
      Height = 13
      Caption = 'Firmware: 0.0.0.0'
    end
  end
  object grpMasterCards: TGroupBox
    Left = 0
    Top = 223
    Width = 330
    Height = 171
    Caption = 'Master Cards'
    TabOrder = 4
    DesignSize = (
      330
      171)
    object lblMasterUID: TLabel
      Left = 16
      Top = 27
      Width = 18
      Height = 13
      Caption = 'UID'
    end
    object lblMasterRow: TLabel
      Left = 16
      Top = 54
      Width = 83
      Height = 13
      Caption = 'Master row index'
    end
    object lblMasterUIDCount: TLabel
      Left = 16
      Top = 112
      Width = 75
      Height = 13
      Caption = 'UID Byte Count'
    end
    object edtMasterUID: TEdit
      Left = 101
      Top = 24
      Width = 190
      Height = 21
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 0
      Text = '00 00 00 00 00 00 00 00 00 00'
    end
    object btnAddMasterCard: TButton
      Left = 77
      Top = 78
      Width = 56
      Height = 25
      Action = actAddMasterCard
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
    object btnFindMaster: TButton
      Left = 137
      Top = 78
      Width = 56
      Height = 25
      Action = actFindMasterCard
      Anchors = [akTop, akRight]
      TabOrder = 2
    end
    object btnDelMaster: TButton
      Left = 197
      Top = 78
      Width = 70
      Height = 25
      Action = actDeleteMasterCard
      Anchors = [akTop, akRight]
      TabOrder = 3
    end
    object btnGetMaster: TButton
      Left = 271
      Top = 78
      Width = 56
      Height = 25
      Action = actGetMasterCard
      Anchors = [akTop, akRight]
      TabOrder = 4
    end
    object cbbMasterRow: TComboBox
      Left = 230
      Top = 51
      Width = 97
      Height = 21
      Anchors = [akTop, akRight]
      ItemIndex = 0
      TabOrder = 5
      Text = '0'
      Items.Strings = (
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7')
    end
    object cbbMasterUIDCount: TComboBox
      Left = 198
      Top = 109
      Width = 129
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 6
      Text = 'cbbMasterUIDCount'
    end
    object btnGetMasterLength: TButton
      Left = 209
      Top = 136
      Width = 56
      Height = 25
      Action = actGetMasterUidLength
      Anchors = [akTop, akRight]
      TabOrder = 7
    end
    object btnSetMasterLength: TButton
      Left = 271
      Top = 136
      Width = 56
      Height = 25
      Action = actSetMasterUidLength
      Anchors = [akTop, akRight]
      TabOrder = 8
    end
    object btnReadCard1: TButton
      Left = 297
      Top = 24
      Width = 30
      Height = 21
      Action = actReadMasterCard
      Anchors = [akTop, akRight]
      TabOrder = 9
    end
  end
  object grpCells: TGroupBox
    Left = 339
    Top = 47
    Width = 330
    Height = 347
    Anchors = [akTop, akRight]
    Caption = 'Cells'
    TabOrder = 5
    DesignSize = (
      330
      347)
    object lblCell: TLabel
      Left = 3
      Top = 24
      Width = 17
      Height = 13
      Caption = 'Cell'
    end
    object lblCellCardUID: TLabel
      Left = 3
      Top = 84
      Width = 18
      Height = 13
      Caption = 'UID'
    end
    object lblCellCardUIDCount: TLabel
      Left = 3
      Top = 142
      Width = 96
      Height = 13
      Caption = 'Cell Card UID Count'
    end
    object cbbCells: TComboBox
      Left = 101
      Top = 21
      Width = 124
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 0
    end
    object btnGetCellsCount: TButton
      Left = 231
      Top = 19
      Width = 96
      Height = 25
      Action = actGetCellsCount
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
    object btnOpenCell: TButton
      Left = 252
      Top = 50
      Width = 75
      Height = 25
      Action = actOpenCell
      Anchors = [akTop, akRight]
      TabOrder = 2
    end
    object edtCellCardUID: TEdit
      Left = 101
      Top = 81
      Width = 190
      Height = 21
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 3
      Text = '00 00 00 00 00 00 00 00 00 00'
    end
    object btnReadCellCard: TButton
      Left = 297
      Top = 80
      Width = 30
      Height = 21
      Action = actReadCellCard
      Anchors = [akTop, akRight]
      TabOrder = 4
    end
    object btnSetCellCard: TButton
      Left = 75
      Top = 108
      Width = 56
      Height = 25
      Action = actSetCellCard
      Anchors = [akTop, akRight]
      TabOrder = 5
    end
    object btnFindCellCard: TButton
      Left = 135
      Top = 108
      Width = 56
      Height = 25
      Action = actFindCellCard
      Anchors = [akTop, akRight]
      TabOrder = 6
    end
    object btnDeleteCellCard: TButton
      Left = 195
      Top = 108
      Width = 70
      Height = 25
      Action = actDeleteCellCard
      Anchors = [akTop, akRight]
      TabOrder = 7
    end
    object btnGetCellCard: TButton
      Left = 271
      Top = 108
      Width = 56
      Height = 25
      Action = actGetCellCard
      Anchors = [akTop, akRight]
      TabOrder = 8
    end
    object cbbCellCardUIDCount: TComboBox
      Left = 197
      Top = 139
      Width = 130
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 9
      Text = 'cbbCellCardUIDCount'
    end
    object btnGetCardUIDCount: TButton
      Left = 211
      Top = 166
      Width = 56
      Height = 25
      Action = actGetCardUIDCount
      Anchors = [akTop, akRight]
      TabOrder = 10
    end
    object btnSetCardUIDCount: TButton
      Left = 271
      Top = 166
      Width = 56
      Height = 25
      Action = actSetCardUIDCount
      Anchors = [akTop, akRight]
      TabOrder = 11
    end
  end
  object actlst1: TActionList
    Left = 360
    object actActivePort: TAction
      Caption = 'actActivePort'
      OnExecute = actActivePortExecute
      OnUpdate = actActivePortUpdate
    end
    object actPing: TAction
      Category = 'NetCMD'
      Caption = 'Ping'
      OnExecute = actPingExecute
    end
    object actGetSN: TAction
      Category = 'ManufactureCMD'
      Caption = 'Get SN'
      OnExecute = actGetSNExecute
    end
    object actSetSN: TAction
      Category = 'ManufactureCMD'
      Caption = 'Set SN'
      OnExecute = actSetSNExecute
    end
    object actReset: TAction
      Category = 'ManufactureCMD'
      Caption = 'Reset'
      OnExecute = actResetExecute
    end
    object actAddMasterCard: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Set Card'
      OnExecute = actAddMasterCardExecute
    end
    object actFindMasterCard: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Find Card'
      OnExecute = actFindMasterCardExecute
    end
    object actDeleteMasterCard: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Delete Card'
      OnExecute = actDeleteMasterCardExecute
    end
    object actGetMasterCard: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Get Card'
      OnExecute = actGetMasterCardExecute
    end
    object actGetMasterUidLength: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Get Count'
      OnExecute = actGetMasterUidLengthExecute
    end
    object actSetMasterUidLength: TAction
      Category = 'MasterCardsCMD'
      Caption = 'Set Count'
      OnExecute = actSetMasterUidLengthExecute
    end
    object actReadMasterCard: TAction
      Category = 'MasterCardsCMD'
      Caption = '...'
      OnExecute = actReadMasterCardExecute
    end
    object actGetCellsCount: TAction
      Category = 'CellsCMD'
      Caption = 'Get Cells Count'
      OnExecute = actGetCellsCountExecute
    end
    object actOpenCell: TAction
      Category = 'CellsCMD'
      Caption = 'Open Cell'
      OnExecute = actOpenCellExecute
    end
    object actSetCellCard: TAction
      Category = 'CellsCMD'
      Caption = 'Set Card'
      OnExecute = actSetCellCardExecute
    end
    object actFindCellCard: TAction
      Category = 'CellsCMD'
      Caption = 'Find Card'
      OnExecute = actFindCellCardExecute
    end
    object actDeleteCellCard: TAction
      Category = 'CellsCMD'
      Caption = 'Delete Card'
      OnExecute = actDeleteCellCardExecute
    end
    object actGetCellCard: TAction
      Category = 'CellsCMD'
      Caption = 'Get Card'
      OnExecute = actGetCellCardExecute
    end
    object actGetCardUIDCount: TAction
      Category = 'CellsCMD'
      Caption = 'Get Count'
      OnExecute = actGetCardUIDCountExecute
    end
    object actSetCardUIDCount: TAction
      Category = 'CellsCMD'
      Caption = 'Set Count'
      OnExecute = actSetCardUIDCountExecute
    end
    object actReadCellCard: TAction
      Category = 'CellsCMD'
      Caption = '...'
      OnExecute = actReadCellCardExecute
    end
  end
  object tmrAutoPing: TTimer
    Enabled = False
    OnTimer = tmrAutoPingTimer
    Left = 544
    Top = 8
  end
end
