unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,  System.StrUtils,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, WD05Unit,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin, System.Actions, Vcl.ActnList;

type
  TfrmCdxWD05 = class(TForm)
    pnlTool: TPanel;
    lblPort: TLabel;
    cbbComPorts: TComboBox;
    btnOpenPort: TButton;
    btnPing: TButton;
    chkAutoPing: TCheckBox;
    sePingInterval: TSpinEdit;
    actlst1: TActionList;
    actActivePort: TAction;
    actPing: TAction;
    seDeviceAddres: TSpinEdit;
    lblDeviceAddress: TLabel;
    mmoLog: TMemo;
    tmrAutoPing: TTimer;
    grpManufactureSettings: TGroupBox;
    grpDeviceInfo: TGroupBox;
    lblFW: TLabel;
    lblSN: TLabel;
    edtSN: TEdit;
    btnGetSN: TButton;
    btnSetSN: TButton;
    btnReset: TButton;
    actGetSN: TAction;
    actSetSN: TAction;
    actReset: TAction;
    grpMasterCards: TGroupBox;
    edtMasterUID: TEdit;
    lblMasterUID: TLabel;
    btnAddMasterCard: TButton;
    btnFindMaster: TButton;
    btnDelMaster: TButton;
    btnGetMaster: TButton;
    cbbMasterRow: TComboBox;
    lblMasterRow: TLabel;
    lblMasterUIDCount: TLabel;
    cbbMasterUIDCount: TComboBox;
    btnGetMasterLength: TButton;
    btnSetMasterLength: TButton;
    actAddMasterCard: TAction;
    actFindMasterCard: TAction;
    actDeleteMasterCard: TAction;
    actGetMasterCard: TAction;
    actGetMasterUidLength: TAction;
    actSetMasterUidLength: TAction;
    btnReadCard1: TButton;
    actReadMasterCard: TAction;
    grpCells: TGroupBox;
    lblCell: TLabel;
    cbbCells: TComboBox;
    btnGetCellsCount: TButton;
    btnOpenCell: TButton;
    lblCellCardUID: TLabel;
    edtCellCardUID: TEdit;
    btnReadCellCard: TButton;
    btnSetCellCard: TButton;
    btnFindCellCard: TButton;
    btnDeleteCellCard: TButton;
    btnGetCellCard: TButton;
    lblCellCardUIDCount: TLabel;
    cbbCellCardUIDCount: TComboBox;
    btnGetCardUIDCount: TButton;
    btnSetCardUIDCount: TButton;
    actGetCellsCount: TAction;
    actOpenCell: TAction;
    actSetCellCard: TAction;
    actFindCellCard: TAction;
    actDeleteCellCard: TAction;
    actGetCellCard: TAction;
    actGetCardUIDCount: TAction;
    actSetCardUIDCount: TAction;
    actReadCellCard: TAction;
    procedure FormCreate(Sender: TObject);
    procedure actActivePortUpdate(Sender: TObject);
    procedure actActivePortExecute(Sender: TObject);
    procedure actPingExecute(Sender: TObject);
    procedure tmrAutoPingTimer(Sender: TObject);
    procedure actResetExecute(Sender: TObject);
    procedure actGetSNExecute(Sender: TObject);
    procedure actSetSNExecute(Sender: TObject);
    procedure actAddMasterCardExecute(Sender: TObject);
    procedure actFindMasterCardExecute(Sender: TObject);
    procedure actDeleteMasterCardExecute(Sender: TObject);
    procedure actGetMasterCardExecute(Sender: TObject);
    procedure actGetMasterUidLengthExecute(Sender: TObject);
    procedure actSetMasterUidLengthExecute(Sender: TObject);
    procedure actReadMasterCardExecute(Sender: TObject);
    procedure actGetCellsCountExecute(Sender: TObject);
    procedure actOpenCellExecute(Sender: TObject);
    procedure actSetCellCardExecute(Sender: TObject);
    procedure actFindCellCardExecute(Sender: TObject);
    procedure actDeleteCellCardExecute(Sender: TObject);
    procedure actGetCardUIDCountExecute(Sender: TObject);
    procedure actSetCardUIDCountExecute(Sender: TObject);
    procedure actReadCellCardExecute(Sender: TObject);
    procedure actGetCellCardExecute(Sender: TObject);
  private
    { Private declarations }
    FLockerWD05: TCustomLockerWD05;
    procedure WriteLog(AMsg: string); overload;
    procedure WriteLog(ADeviceAddress: Byte; AMsg: string); overload;
    procedure OnLockerWD05Notify( Sender: TObject; Msg: string);
    procedure OnLockerWD05Error( Sender : TObject; const ErrCode : Cardinal; const ErrMessage : String );
    procedure OnLockerWD05SimpleResponse( Sender:TObject; DeviceAddress: Byte; Msg: string);
    procedure OnLockerWD05Ping( Sender:TObject; DeviceAddress: Byte; DeviceFirmware: TWD05Firmware);
    procedure OnLockerWD05GetSerialNumber( Sender:TObject; DeviceAddress: Byte; SerialNumber: Cardinal);
    procedure OnLockerWD05FindMaster( Sender: TObject; DeviceAddress: Byte; CellNumber: Byte);
    procedure OnLockerWD05GetMaster( Sender: TObject; DeviceAddress: Byte; CardUID: TWD05CardUid);
    procedure OnLockerWD05GetMasterBytesCount( Sender: TObject; DeviceAddress: Byte; CardUIDLength: TWD05CardUidLength);
    procedure OnLockerWD05GetCellsCount(  Sender:TObject; DeviceAddress: Byte; CellCount: Byte );
    procedure OnLockerWD05FindCard( Sender: TObject; DeviceAddress: Byte; CellNumber: Byte);
    procedure OnLockerWD05GetCellCard( Sender: TObject; DeviceAddress: Byte; CardUID: TWD05CardUid);
    procedure OnLockerWD05GetCellCardBytesCount( Sender: TObject; DeviceAddress: Byte; CardUIDLength: TWD05CardUidLength);
  public
    { Public declarations }
  end;

var
  frmCdxWD05: TfrmCdxWD05;

resourcestring
  rsLogFormat = '[%s] %s';
  rsDateLog   = 'hh:mm:ss.zzz';

implementation

{$R *.dfm}

uses CardReaderUnit;

procedure TfrmCdxWD05.actActivePortExecute(Sender: TObject);
var
  i: Integer;
begin
  if not FLockerWD05.Active then
  begin
    i:= cbbComPorts.ItemIndex;
    if i < 0 then
    begin
      MessageDlg('Com port is not selected', mtError, [mbOk], 0);
      Exit;
    end;
    FLockerWD05.InitPort(cbbComPorts.Items[i]);
    FLockerWD05.Active:= True;
  end else
  begin
    FLockerWD05.Active:= False;
    EnumComPorts(cbbComPorts.Items);
    cbbComPorts.ItemIndex:= cbbComPorts.Items.IndexOf(FLockerWD05.ComPort.Port);
  end;
end;

procedure TfrmCdxWD05.actActivePortUpdate(Sender: TObject);
begin
  actActivePort.Caption:= IfThen(FLockerWD05.Active, 'Close', 'Open port');
  grpManufactureSettings.Enabled:= FLockerWD05.Active;
  grpMasterCards.Enabled:= FLockerWD05.Active;
  actPing.Enabled:= FLockerWD05.Active;
  cbbComPorts.Enabled:= not FLockerWD05.Active;
end;

procedure TfrmCdxWD05.actAddMasterCardExecute(Sender: TObject);
var
  uid: TWD05CardUid;
begin
  uid:= TWD05CardUid.Create(edtMasterUID.Text);
  FLockerWD05.AddMaster(cbbMasterRow.ItemIndex, uid, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actDeleteCellCardExecute(Sender: TObject);
begin
  if cbbCells.ItemIndex < 0 then
  begin
    WriteLog('Cell is not selected');
    Exit;
  end;
  FLockerWD05.DelCellCard(cbbCells.ItemIndex, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actDeleteMasterCardExecute(Sender: TObject);
begin
  FLockerWD05.DeleteMaster(cbbMasterRow.ItemIndex, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actFindCellCardExecute(Sender: TObject);
begin
  FLockerWD05.FindCellCard(TWD05CardUid.Create(edtCellCardUID.Text), seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actFindMasterCardExecute(Sender: TObject);
begin
  FLockerWD05.FindMaster(TWD05CardUid.Create(edtMasterUID.Text), seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetCardUIDCountExecute(Sender: TObject);
begin
  FLockerWD05.GetCellCardLength(seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetCellCardExecute(Sender: TObject);
begin
  if cbbCells.ItemIndex < 0 then
  begin
    WriteLog('Cell is not selected');
    Exit;
  end;
  FLockerWD05.GetCellCard(cbbCells.ItemIndex, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetCellsCountExecute(Sender: TObject);
begin
  FLockerWD05.GetCellCount(seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetMasterCardExecute(Sender: TObject);
begin
  FLockerWD05.GetMaster(cbbMasterRow.ItemIndex, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetMasterUidLengthExecute(Sender: TObject);
begin
  FLockerWD05.GetMasterLength(seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actGetSNExecute(Sender: TObject);
begin
  FLockerWD05.GetSerialNumber(seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actOpenCellExecute(Sender: TObject);
begin
  if cbbCells.ItemIndex < 0 then
  begin
    WriteLog('Cell is not selected');
    Exit;
  end;
  FLockerWD05.OpenLockerCell(cbbCells.ItemIndex);
end;

procedure TfrmCdxWD05.actPingExecute(Sender: TObject);
begin
  FLockerWD05.Ping(seDeviceAddres.Value);
  tmrAutoPing.Interval:= sePingInterval.Value * 1000;
  tmrAutoPing.Enabled:= chkAutoPing.Checked;
end;

procedure TfrmCdxWD05.actReadCellCardExecute(Sender: TObject);
begin
  edtCellCardUID.Text:= ReadCardFromReader().ToString;
end;

procedure TfrmCdxWD05.actReadMasterCardExecute(Sender: TObject);

begin
  edtMasterUID.Text:= ReadCardFromReader().ToString;
end;

procedure TfrmCdxWD05.actResetExecute(Sender: TObject);
begin
  FLockerWD05.Reset(seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actSetCardUIDCountExecute(Sender: TObject);
var
  i: Integer;
begin
  i:= cbbCellCardUIDCount.ItemIndex;
  if i < 0 then
  begin
    WriteLog('Cell is not selected');
    Exit;
  end;
  FLockerWD05.SetCellCardLength(TWD05CardUidLength(cbbCellCardUIDCount.Items.Objects[i]), seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actSetCellCardExecute(Sender: TObject);
var
  i: Integer;
  uid: TWD05CardUid;
begin
  i:= cbbCells.ItemIndex;
  if i < 0 then
  begin
    WriteLog('Cell is not selected');
    Exit;
  end;
  uid:= TWD05CardUid.Create(edtCellCardUID.Text);
  FLockerWD05.SetCellCard(i, uid, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actSetMasterUidLengthExecute(Sender: TObject);
var
  i: Integer;
begin
  i:= cbbMasterUIDCount.ItemIndex;
  if i < 0 then
  begin
    WriteLog('Master UID Byte count is not selected');
    Exit;
  end;
  FLockerWD05.SetMasterLength(TWD05CardUidLength(cbbMasterUIDCount.Items.Objects[i]), seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.actSetSNExecute(Sender: TObject);
var
  c: Cardinal;
begin
  c:= StrToUIntDef(edtSN.Text, $ffffffff);
  FLockerWD05.SetSerialNumber(c, seDeviceAddres.Value);
end;

procedure TfrmCdxWD05.WriteLog(AMsg: string);
var
  sd: string;
begin
  sd:= FormatDateTime(rsDateLog, Now);
  mmoLog.Lines.Add(Format(rsLogFormat, [sd, AMsg]));
end;

procedure TfrmCdxWD05.FormCreate(Sender: TObject);
begin
  EnumComPorts(cbbComPorts.Items);
  FLockerWD05:= TCustomLockerWD05.Create(Self);
  FLockerWD05.OnNotify:= OnLockerWD05Notify;
  FLockerWD05.OnError := OnLockerWD05Error;
  FLockerWD05.OnSimpleResponse:= OnLockerWD05SimpleResponse;
  FLockerWD05.OnPing:= OnLockerWD05Ping;
  FLockerWD05.OnResponseSerialNumber:= OnLockerWD05GetSerialNumber;
  FLockerWD05.OnResponseFindMaster:= OnLockerWD05FindMaster;
  FLockerWD05.OnResponseMasterCard:= OnLockerWD05GetMaster;
  FLockerWD05.OnResponseMasterLength:= OnLockerWD05GetMasterBytesCount;
  FLockerWD05.OnResponseCellCount:= OnLockerWD05GetCellsCount;
  FLockerWD05.OnResponseFindCard:= OnLockerWD05FindCard;
  FLockerWD05.OnResponseCellCard:= OnLockerWD05GetCellCard;
  FLockerWD05.OnResponseCardLength:= OnLockerWD05GetCellCardBytesCount;

  EnumCardUidLength(cbbMasterUIDCount.Items);
  cbbMasterUIDCount.ItemIndex:= cbbMasterUIDCount.Items.IndexOf(CardUidLengthToString(TWD05CardUidLength.uclFour));
  cbbCells.Clear;
  EnumCardUidLength(cbbCellCardUIDCount.Items);
  cbbCellCardUIDCount.ItemIndex:= cbbCellCardUIDCount.Items.IndexOf(CardUidLengthToString(TWD05CardUidLength.uclFour));
end;

procedure TfrmCdxWD05.OnLockerWD05Error(Sender: TObject;
  const ErrCode: Cardinal; const ErrMessage: String);
begin
  WriteLog(Format('Error: %s. Code: %d', [ErrMessage, ErrCode]));
end;

procedure TfrmCdxWD05.OnLockerWD05FindCard(Sender: TObject; DeviceAddress,
  CellNumber: Byte);
begin
  if CellNumber > 0 then
    WriteLog(DeviceAddress, Format('Card found in Cell: %d', [CellNumber]))
//  else
//    WriteLog(DeviceAddress, Format('Card not found in cells', []));
end;

procedure TfrmCdxWD05.OnLockerWD05FindMaster(Sender: TObject; DeviceAddress,
  CellNumber: Byte);
begin
  if CellNumber > 0 then
    WriteLog(DeviceAddress, 'Master card found');
end;

procedure TfrmCdxWD05.OnLockerWD05GetCellCard(Sender: TObject;
  DeviceAddress: Byte; CardUID: TWD05CardUid);
begin
  edtCellCardUID.Text:= CardUID.ToString;
  WriteLog(DeviceAddress, Format('Get card of cell: %s', [ CardUID.ToString ]));
end;

procedure TfrmCdxWD05.OnLockerWD05GetCellCardBytesCount(Sender: TObject;
  DeviceAddress: Byte; CardUIDLength: TWD05CardUidLength);
begin
  cbbCellCardUIDCount.ItemIndex:= cbbCellCardUIDCount.Items.IndexOfObject(TObject(CardUIDLength));
  WriteLog(DeviceAddress, Format('Cell Card UID Bytes count: %s', [ CardUidLengthToString(CardUIDLength)]));
end;

procedure TfrmCdxWD05.OnLockerWD05GetCellsCount(Sender: TObject; DeviceAddress,
  CellCount: Byte);
var
  i: Integer;
begin
  cbbCells.Clear;
  for I := 1 to CellCount do
    cbbCells.Items.Add(IntToStr(i));

  WriteLog(DeviceAddress, Format('%d cells is actived', [CellCount]));
end;

procedure TfrmCdxWD05.OnLockerWD05GetMaster(Sender: TObject;
  DeviceAddress: Byte; CardUID: TWD05CardUid);
begin
  edtMasterUID.Text:= CardUID.ToString;
  WriteLog(DeviceAddress, Format('Get Master card record: %s', [ CardUID.ToString ]));
end;

procedure TfrmCdxWD05.OnLockerWD05GetMasterBytesCount(Sender: TObject;
  DeviceAddress: Byte; CardUIDLength: TWD05CardUidLength);
begin
  cbbMasterUIDCount.ItemIndex:= cbbMasterUIDCount.Items.IndexOfObject(TObject(CardUIDLength));
  WriteLog(DeviceAddress, Format('Master UID Bytes count: %s', [ CardUidLengthToString(CardUIDLength)]));
end;

procedure TfrmCdxWD05.OnLockerWD05GetSerialNumber(Sender: TObject;
  DeviceAddress: Byte; SerialNumber: Cardinal);
begin
  edtSN.Text:= IntToStr(SerialNumber);

  WriteLog(DeviceAddress, Format('SN: %d', [ SerialNumber ]));
end;

procedure TfrmCdxWD05.OnLockerWD05Notify(Sender: TObject; Msg: string);
begin
  WriteLog(Msg);
end;

procedure TfrmCdxWD05.OnLockerWD05Ping(Sender: TObject; DeviceAddress: Byte;
  DeviceFirmware: TWD05Firmware);
begin
  lblFW.Caption:= Format('Firmware: %d.%d.%d.%d', [
      DeviceFirmware.Major,
      DeviceFirmware.Minor,
      DeviceFirmware.Release,
      DeviceFirmware.Build]);

  WriteLog(DeviceAddress, Format('FW: %d.%d.%d.%d', [
      DeviceFirmware.Major,
      DeviceFirmware.Minor,
      DeviceFirmware.Release,
      DeviceFirmware.Build]));
end;

procedure TfrmCdxWD05.OnLockerWD05SimpleResponse(Sender: TObject;
  DeviceAddress: Byte; Msg: string);
begin
  WriteLog(DeviceAddress, Msg);
end;

procedure TfrmCdxWD05.tmrAutoPingTimer(Sender: TObject);
begin
  actPing.Execute;
end;

procedure TfrmCdxWD05.WriteLog(ADeviceAddress: Byte; AMsg: string);
begin
  WriteLog(Format('%.2X - %s', [ADeviceAddress, AMsg]));
end;

end.

