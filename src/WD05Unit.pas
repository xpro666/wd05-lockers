unit WD05Unit;
{$I defs.inc}

interface

uses
{$IFDEF HAS_UNITSCOPE}
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.WinSock, System.Types
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ELSE ~HAS_UNITSCOPE}
    SysUtils, Classes, Windows, WinSock, Types
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ENDIF ~HAS_UNITSCOPE}
    , Forms, core, CPort;

const
  //////////////////////////////////////////////////////////////////////////////
  // Default values for controller
  DEF_DEVICE_ADDRESS                    = $01;

  //////////////////////////////////////////////////////////////////////////////
  // Additional data
  PACKET_HEADER_LEN                     = $04;
  DATA_PACKET_LEN                       = $20;
  DATA_PACKET_CRC_POS                   = $01;
  CARD_UID_LEN                          = $0A;

  RESPONSE_E                            = 'E';
  RESPONSE_C                            = 'C';
  RESPONSE_R                            = 'R';

  MASTER_RECORD_COUNT                   = 8;

type
  /// ///////////////////////////////////////////////////////////////////////////
  // Helper types
  TBuffer = core.TBuffer;
  PBuffer = core.PBuffer;

  TBaudRate = CPort.TBaudRate;

  TGeneric4ByteArray = array [0 .. PACKET_ADDRESS_LEN - 1] of Byte;
  TSerialNumberArray = TGeneric4ByteArray;
  TDeviceSoftwareVersionArray = TGeneric4ByteArray;
  TDataByteArray     = array[0..DATA_PACKET_LEN - 1] of Byte;
  TCardByteArray     = array[0..CARD_UID_LEN - 1] of Byte;
  PCardByteArray     = ^TCardByteArray;

  /// ///////////////////////////////////////////////////////////////////////////
  // WD05 commands
  TWD05Commands = (
  //                     $<CM2><CM1>
      cmdPing             = $0101 // CM1,CM2> <CM1,CM2,FW3,FW2,FW1,FW0

    , cmdSetSerialNumber  = $0103 // CM1,CM2,S3,S2,S1,S0> <CM1,CM2,'E','C'
    , cmdGetSerialNumber  = $0203 // CM1,CM2> <CM1,CM2,S3,S2,S1,S0
    , cmdReset            = $0303 // CM1,CM2> <CM1,CM2,'E','C'

    , cmdAddMaster        = $0104 // CM1,CM2,R,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdFindMaster       = $0204 // CM1,CM2,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdDelMaster        = $0304 // CM1,CM2,R> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdGetMaster        = $0404 // CM1,CM2,R> <CM1,CM2,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0 | CM1,CM2,'E','R'
    , cmdSetMasterLength  = $0504 // CM1,CM2,N(3,4,8)> <CM1,CM2,'E','C'
    , cmdGetMasterLength  = $0604 // CM1,CM2> <CM1,CM2,N

    , cmdGetCellCount     = $0105 // CM1,CM2> <CM1,CM2,C(1..8)
    , cmdOpenCellLock     = $0205 // CM1,CM2,C(0..7)> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdSetCellCard      = $0305 // CM1,CM2,C,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdFindCard         = $0405 // CM1,CM2,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0> <CM1,CM2,C | CM1,CM2,'E','R'
    , cmdDelCellCard      = $0505 // CM1,CM2,C> <CM1,CM2,'E','C' | CM1,CM2,'E','R'
    , cmdGetCellCard      = $0605 // CM1,CM2,C> <CM1,CM2,N9,N8,N7,N6,N5,N4,N3,N2,N1,N0 | CM1,CM2,'E','R'
    , cmdSetCardLength    = $0705 // CM1,CM2,N(3,4,8)> <CM1,CM2,'E','C'
    , cmdGetCardLength    = $0805 // CM1,CM2> <CM1,CM2,N
  );

  TWD05CardUidLength = (
    uclThree    = 3
    , uclFour   = 4
    , uclEight  = 8
  );

  TWD05Firmware = record
    Major   : Byte;
    Minor   : Byte;
    Release : Byte;
    Build   : Byte;
  public
    function Empty: Boolean;
  end;

  TWD05PacketHeader = record
    DeviceAddress : Byte;
    CRC           : Byte;
    Command       : TWD05Commands;
  end;

  TWD05CardUid = class;

  TWD05MasterRecordArray = array[0..MASTER_RECORD_COUNT - 1] of TWD05CardUid;

  //////////////////////////////////////////////////////////////////////////////
  ///  Events
  TWD05SimpleResponseEvent = procedure( Sender:TObject; DeviceAddress: Byte; Msg: string) of object;
  TWD05PingEvent = procedure( Sender:TObject; DeviceAddress: Byte; DeviceFirmware: TWD05Firmware) of object;
  TWD05SerialNumberEvent = procedure( Sender:TObject; DeviceAddress: Byte; SerialNumber: Cardinal) of object;
  TWD05FindCardEvent = procedure( Sender: TObject; DeviceAddress: Byte; CellNumber: Byte) of object;
  TWD05ResponseCardNumberEvent = procedure( Sender: TObject; DeviceAddress: Byte; CardUID: TWD05CardUid) of object;
  TWD05ResponseCardLengthEvent = procedure( Sender: TObject; DeviceAddress: Byte; CardUIDLength: TWD05CardUidLength) of object;
  TWD05ResponseCellCountEvent = procedure( Sender:TObject; DeviceAddress: Byte; CellCount: Byte ) of object;


  TWD05CardUid = class(TPersistent)
  private
    FRaw: TCardByteArray;
    function GetRaw: TCardByteArray;
    procedure SetRaw(const Value: TCardByteArray);
    function GetSUid: string;
    function GetPRaw: PCardByteArray;
    function GetIsEmpty: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(); overload;
    constructor Create(ARaw : TCardByteArray); overload;
    constructor Create(AHex : string); overload;
    procedure Clear;
    procedure FromString(sUid: string);
    function Compare(Dest: TWD05CardUid):Integer;
    function ToString(): string; override;
    property Raw: TCardByteArray read GetRaw write SetRaw;
    property PRaw: PCardByteArray read GetPRaw;
    property StringUid: string read GetSUid;
    property IsEmpty: Boolean read GetIsEmpty;
  end;

  TCustomLockerWD05 = class;

  TLockerWD05Link = class
  private
    FAfterActive: TNotifyEvent;
    FErrorEvent: TErrorEvent;
    FPingEvent: TWD05PingEvent;
    FSimpleResponseEvent: TWD05SimpleResponseEvent;
    FResponseSerialNumberEvent: TWD05SerialNumberEvent;
    FResponseFindMasterEvent: TWD05FindCardEvent;
    FResponseMasterCardEvent: TWD05ResponseCardNumberEvent;
    FResponseMasterLengthEvent: TWD05ResponseCardLengthEvent;
    FResponseCellCountEvent: TWD05ResponseCellCountEvent;
    FResponseFindCardEvent: TWD05FindCardEvent;
    FResponseCellCardEvent: TWD05ResponseCardNumberEvent;
    FResponseCardLengthEvent: TWD05ResponseCardLengthEvent;
  public
    property OnAfterActive: TNotifyEvent read FAfterActive write FAfterActive;
    property OnError: TErrorEvent read FErrorEvent write FErrorEvent;
    property OnPing: TWD05PingEvent read FPingEvent write FPingEvent;
    property OnSimpleResponse: TWD05SimpleResponseEvent read FSimpleResponseEvent write FSimpleResponseEvent;
    property OnResponseSerialNumber: TWD05SerialNumberEvent read FResponseSerialNumberEvent write FResponseSerialNumberEvent;
    property OnResponseMasterCard: TWD05ResponseCardNumberEvent read FResponseMasterCardEvent write FResponseMasterCardEvent;
    property OnResponseMasterLength: TWD05ResponseCardLengthEvent read FResponseMasterLengthEvent write FResponseMasterLengthEvent;
    property OnResponseFindMaster: TWD05FindCardEvent read FResponseFindMasterEvent write FResponseFindMasterEvent;
    property OnResponseCellCount: TWD05ResponseCellCountEvent read FResponseCellCountEvent write FResponseCellCountEvent;
    property OnResponseCellCard: TWD05ResponseCardNumberEvent read FResponseCellCardEvent write FResponseCellCardEvent;
    property OnResponseFindCard: TWD05FindCardEvent read FResponseFindCardEvent write FResponseFindCardEvent;
    property OnResponseCardLength: TWD05ResponseCardLengthEvent read FResponseCardLengthEvent write FResponseCardLengthEvent;
  end;

  TCustomLockerWD05 = class(TCustomCarddexProtocol)
  private
    FSendPacket       : TBuffer;
    FSendPacketCount  : Integer;
    FSendPacketHeader : TWD05PacketHeader;
    FRecvPacketHeader : TWD05PacketHeader;

    FMasterCardLength : TWD05CardUidLength;
    FCellCardLength   : TWD05CardUidLength;

    FLinks            : TList;
    FHasLink          : Boolean;

    FAddress          : Byte;
    FCellCard         : TWD05CardUid;
    FCellNumber       : Byte;
    FAnswerError      : string;

    FSleepSyncMS      : Integer;

    FPingEvent: TWD05PingEvent;
    FSimpleResponseEvent: TWD05SimpleResponseEvent;
    FResponseSerialNumberEvent: TWD05SerialNumberEvent;
    FResponseFindMasterEvent: TWD05FindCardEvent;
    FResponseMasterCardEvent: TWD05ResponseCardNumberEvent;
    FResponseMasterLengthEvent: TWD05ResponseCardLengthEvent;
    FResponseCellCountEvent: TWD05ResponseCellCountEvent;
    FResponseFindCardEvent: TWD05FindCardEvent;
    FResponseCellCardEvent: TWD05ResponseCardNumberEvent;
    FResponseCardLengthEvent: TWD05ResponseCardLengthEvent;

    procedure ClearSendPacket;
    procedure ClearSendPacketHeader;
    procedure ClearRecvPacketHeader;

    function HasLink: Boolean;

    procedure ParsePing( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseSerialResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseSimpleResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseFindMasterResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseGetMasterResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseGetMasterLengthResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseGetCellCountResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseGetCardResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseFindCardResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure ParseGetCardLengthResponse( const DataBuffer : array of Byte; const DataCount : Byte );
    procedure PrepareHeader(Cmd: TWD05Commands; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    function PrepareData( var Data : TDataByteArray; const DataCount: Integer) : Byte;

    procedure SelfResponseCellCard( Sender: TObject; DeviceAddress: Byte; CardUID: TWD05CardUid);
    procedure SelfResponseFindCard( Sender: TObject; DeviceAddress: Byte; CellNumber: Byte);
    procedure SelfError(Sender:TObject; const ErrCode : Cardinal; const ErrMessage : String);
    procedure SelfSimpleResponse( Sender:TObject; DeviceAddress: Byte; Msg: string);

  protected
    procedure DoAfterActive;override;
    procedure DoError(ErrCode: Cardinal; ErrMessage: string);override;
    procedure DoPacketHandler(APacket: PBuffer; ASize: Integer); override;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; APortName: string; APortBaud: TBaudRate = DEF_COMMPORT_SPEED); reintroduce; overload;
    destructor Destroy; override;
  public
    procedure RegisterLink(ALockerWD05Link: TLockerWD05Link);
    procedure UnRegisterLink(ALockerWD05Link: TLockerWD05Link);
    ////////////////////////////////////////////////////////////////////////////
    procedure Ping(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    ////////////////////////////////////////////////////////////////////////////
    procedure SetSerialNumber(SerialNumber: Cardinal; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure GetSerialNumber(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure Reset(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    ////////////////////////////////////////////////////////////////////////////
    procedure AddMaster(Row: Byte; CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure FindMaster(CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure DeleteMaster(Row: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure GetMaster(Row: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure GetMasterLength(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure SetMasterLength(UidLength: TWD05CardUidLength; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    ////////////////////////////////////////////////////////////////////////////
    procedure GetCellCount(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure OpenLockerCell(CellIndex: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure SetCellCard(CellIndex: Byte; CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure SetCellCardSync(CellIndex: Byte; CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure FindCellCard(CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    function FindCellCardSync(CardUID: TWD05CardUid; DeviceAddress: Byte = DEF_DEVICE_ADDRESS): Integer;
    procedure DelCellCard(CellIndex: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure DelCellCardSync(CellIndex: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure GetCellCard(CellIndex: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    function GetCellCardSync(CellIndex: Byte; DeviceAddress: Byte = DEF_DEVICE_ADDRESS): TWD05CardUid;
    procedure GetCellCardLength(DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    procedure SetCellCardLength(UidLength: TWD05CardUidLength; DeviceAddress: Byte = DEF_DEVICE_ADDRESS);
    //Handle Exceptions
    procedure CallException(AnException:Word; const WinError:Int64 =0);
  published
    property OnPing: TWD05PingEvent read FPingEvent write FPingEvent;
    property OnSimpleResponse: TWD05SimpleResponseEvent read FSimpleResponseEvent write FSimpleResponseEvent;
    property OnResponseSerialNumber: TWD05SerialNumberEvent read FResponseSerialNumberEvent write FResponseSerialNumberEvent;
    property OnResponseMasterCard: TWD05ResponseCardNumberEvent read FResponseMasterCardEvent write FResponseMasterCardEvent;
    property OnResponseMasterLength: TWD05ResponseCardLengthEvent read FResponseMasterLengthEvent write FResponseMasterLengthEvent;
    property OnResponseFindMaster: TWD05FindCardEvent read FResponseFindMasterEvent write FResponseFindMasterEvent;
    property OnResponseCellCount: TWD05ResponseCellCountEvent read FResponseCellCountEvent write FResponseCellCountEvent;
    property OnResponseCellCard: TWD05ResponseCardNumberEvent read FResponseCellCardEvent write FResponseCellCardEvent;
    property OnResponseFindCard: TWD05FindCardEvent read FResponseFindCardEvent write FResponseFindCardEvent;
    property OnResponseCardLength: TWD05ResponseCardLengthEvent read FResponseCardLengthEvent write FResponseCardLengthEvent;
  end;

  TLockersWD05 = class(TCustomLockerWD05)
  published
    property Active;
    property ComPort;
    property WaitAnswerTimeout;
  published
    property OnAfterActive;
    property OnPacketHandler;
    property OnNotify;
    property OnError;
    property OnRxFrame;
    property OnTxFrame;
    property OnRxHexFrame;
    property OnTxHexFrame;
    property OnPing;

    property OnSimpleResponse;
    property OnResponseSerialNumber;
    property OnResponseMasterCard;
    property OnResponseMasterLength;
    property OnResponseFindMaster;
    property OnResponseCellCount;
    property OnResponseCellCard;
    property OnResponseFindCard;
    property OnResponseCardLength;
  end;

  ELockersWD05 = class(Exception)
  private
    FWinCode: Integer;
    FCode: Integer;
  public
    constructor Create(ACode: Integer; AWinCode: Integer);
    constructor CreateNoWinCode(ACode: Integer);
    property WinCode: Integer read FWinCode write FWinCode;
    property Code: Integer read FCode write FCode;
  end;

const
  cIntBaudRates : array[TBaudRate] of Integer = (
    0, 110, 300, 600, 1200, 2400, 4800, 9600, 14400,
    19200, 38400, 56000, 57600, 115200, 128000, 256000);

    //Error codes
    CdxError_RxTimeout = core.CdxError_RxTimeout;

    LError_RegFailed       = 1;

procedure EnumComPorts(PortList: TStrings);
procedure EnumComBauds( Bauds: TStrings);
function GetPortBaudByInt(IntBaud: Integer): TBaudRate;
function GetIntByPortBaud(Baud: TBaudRate): Integer;

function CardUidLengthToString(ACardUidLength: TWD05CardUidLength): string;
procedure EnumCardUidLength(AItems: TStrings);
function CommandToString(ACommand: TWD05Commands): String;
// function EventToString( AEvent : TCBU250Events ): String;
function DeviceSerial2DeviceAddress(const DeviceSerial: Cardinal)
  : TSerialNumberArray;
function DeviceAddress2DeviceSerial(const DeviceAddr: TSerialNumberArray)
  : Cardinal;

resourcestring
  rsLError_RegFailed    = 'Link (un)registration failed';

  rsCmdPing             = 'Проверка связи (ping)';
  rsCmdSetSerialNumber  = 'Установка серийного номера';
  rsCmdGetSerialNumber  = 'Получение серийного номера';
  rsCmdReset            = 'Сброс контроллера';
  rsCmdAddMaster        = 'Добавление мастер карты в базу';
  rsCmdFindMaster       = 'Поиск мастер карты в базе';
  rsCmdDelMaster        = 'Удаление мастер карты из базы';
  rsCmdGetMaster        = 'Получение текущей мастер карты из базы';
  rsCmdSetMasterLength  = 'Установка количества байт номера мастер карты';
  rsCmdGetMasterLength  = 'Получение текущего количества байт номера мастер карты';
  rsCmdGetCellCount     = 'Получение количества ячеек в секции';
  rsCmdOpenCellLock     = 'Открытие ячейки в секции';
  rsCmdSetCellCard      = 'Установка номера идентификатора для ячейки';
  rsCmdFindCard         = 'Поиск номера индентификатора по ячейкам в секции';
  rsCmdDelCellCard      = 'Удаление номера идентификатора из ячейки в секции';
  rsCmdGetCellCard      = 'Получение текущего номера идентификатора ячейки в секции';
  rsCmdSetCardLength    = 'Установка количества байт номера идентификатора';
  rsCmdGetCardLength    = 'Получение текущего количества байт номера идентификатора';

  rsUclThree            = '3';
  rsUclFour             = '4';
  rsUclEight            = '8';

  rsPacketCRCError      = 'Ошибка! Контрольная сумма пакета = 0x%.2X не совпадает с рассчитанной = 0x%.2X';
  rsPacketCRCSuccess    = 'Контрольная сумма пакета = 0x%.2X совпадает с рассчитанной = 0x%.2X';

  rsCmdSuccess          = 'Нет ошибок';
  rsCmdError            = 'Ошибка выполнения команды';
  rsNotFoundUID         = 'Карта не найдена';

  {$EXTERNALSYM ntohll}
function ntohll(netlong: UInt64): UInt64; stdcall;
  {$EXTERNALSYM htonll}
function htonll(hostlong: UInt64): UInt64; stdcall;


procedure Register;

implementation

const
  winsocket = 'wsock32.dll';

var
  LockerErrorMessages: array[1..1] of string;

function htonll;             external    winsocket name 'htonll';
function ntohll;             external    winsocket name 'ntohll';

procedure Register;
begin
  RegisterComponents('DoingSoft Turnstile Controls', [TLockersWD05]);
end;

procedure EnumComPorts(PortList: TStrings);
begin
  core.EnumComPorts(PortList);
end;

procedure EnumComBauds( Bauds: TStrings);
var
  TmpBauds: TStringList;
  baud: TBaudRate;
begin
  TmpBauds:= TStringList.Create;
  try
    for baud := Low(TBaudRate) to High(TBaudRate) do
    begin
      if GetIntByPortBaud(baud) <> 0 then
        TmpBauds.Add(IntToStr(GetIntByPortBaud(baud)));
    end;
    Bauds.Assign(TmpBauds);
  finally
    TmpBauds.Free;
  end;

end;

function GetPortBaudByInt(IntBaud: Integer): TBaudRate;
begin
  case IntBaud of
  110: Result:= TBaudRate.br110;
  300: Result:= TBaudRate.br300;
  600: Result:= TBaudRate.br600;
  1200: Result:= TBaudRate.br1200;
  2400: Result:= TBaudRate.br2400;
  4800: Result:= TBaudRate.br4800;
  9600: Result:= TBaudRate.br9600;
  14400: Result:= TBaudRate.br14400;
  19200: Result:= TBaudRate.br19200;
  38400: Result:= TBaudRate.br38400;
  56000: Result:= TBaudRate.br56000;
  57600: Result:= TBaudRate.br57600;
  115200: Result:= TBaudRate.br115200;
  128000: Result:= TBaudRate.br128000;
  256000: Result:= TBaudRate.br256000;
  else
    Result:= TBaudRate.brCustom;
  end;
end;

function GetIntByPortBaud(Baud: TBaudRate): Integer;
begin
  case Baud of
    br110: Result:= 110;
    br300: Result:= 300;
    br600: Result:= 600;
    br1200: Result:= 1200;
    br2400: Result:= 2400;
    br4800: Result:= 4800;
    br9600: Result:= 9600;
    br14400: Result:= 14400;
    br19200: Result:= 19200;
    br38400: Result:= 38400;
    br56000: Result:= 56000;
    br57600: Result:= 57600;
    br115200: Result:= 115200;
    br128000: Result:= 128000;
    br256000: Result:= 256000;
  else
    Result:= 0;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
function CommandToString(ACommand: TWD05Commands): String;
begin
  case ACommand of
    cmdPing: Result := rsCmdPing;
    cmdSetSerialNumber: Result := rsCmdSetSerialNumber;
    cmdGetSerialNumber: Result := rsCmdGetSerialNumber;
    cmdReset: Result := rsCmdReset;
    cmdAddMaster: Result := rsCmdAddMaster;
    cmdFindMaster: Result := rsCmdFindMaster;
    cmdDelMaster: Result := rsCmdDelMaster;
    cmdGetMaster: Result := rsCmdGetMaster;
    cmdSetMasterLength: Result := rsCmdSetMasterLength;
    cmdGetMasterLength: Result := rsCmdGetMasterLength;
    cmdGetCellCount: Result := rsCmdGetCellCount;
    cmdOpenCellLock: Result := rsCmdOpenCellLock;
    cmdSetCellCard: Result := rsCmdSetCellCard;
    cmdFindCard: Result := rsCmdFindCard;
    cmdDelCellCard: Result := rsCmdDelCellCard;
    cmdGetCellCard: Result := rsCmdGetCellCard;
    cmdSetCardLength: Result := rsCmdSetCardLength;
    cmdGetCardLength: Result := rsCmdGetCardLength;
  else
    Result:= '';
  end;
end;

function CardUidLengthToString(ACardUidLength: TWD05CardUidLength): string;
begin
  case ACardUidLength of
    uclThree: Result:= rsUclThree;
    uclFour:  Result:= rsUclFour;
    uclEight: Result:= rsUclEight;
  else
    Result:= '';
  end;
end;

procedure EnumCardUidLength(AItems: TStrings);
var
  ucl: TWD05CardUidLength;
begin
  AItems.BeginUpdate;
  try
    AItems.Clear;
    for ucl := Low(TWD05CardUidLength) to High(TWD05CardUidLength) do
      if Length(CardUidLengthToString(ucl)) > 0 then
        AItems.AddObject(CardUidLengthToString(ucl), TObject(ucl));
  finally
    AItems.EndUpdate;
  end;
end;

// -----------------------------------------------------------------------------
function DeviceSerial2DeviceAddress(const DeviceSerial: Cardinal)
  : TSerialNumberArray;
var
  c: Cardinal;
begin
  c := htonl(DeviceSerial);
  CopyMemory(@Result, @c, SizeOf(Cardinal));
end;

// -----------------------------------------------------------------------------
function DeviceAddress2DeviceSerial(const DeviceAddr: TSerialNumberArray)
  : Cardinal;
begin
  CopyMemory(@Result, @DeviceAddr, SizeOf(Cardinal));

  Result := ntohl(Result);
end;

procedure Delay(Milliseconds: Integer);
  {by Hagen Reddmann}
var
  Tick: DWORD;
  Event: THandle;
begin
  Event := CreateEvent(nil, False, False, nil);
  try
    Tick := GetTickCount + DWORD(Milliseconds);
    while (Milliseconds > 0) and
      (MsgWaitForMultipleObjects(1, Event, False, Milliseconds,
      QS_ALLINPUT) <> WAIT_TIMEOUT) do
    begin
      Application.ProcessMessages;
      Milliseconds := Tick - GetTickCount;
    end;
  finally
    CloseHandle(Event);
  end;
end;

{ TCustomLockerWD05 }

procedure TCustomLockerWD05.AddMaster(Row: Byte; CardUID: TWD05CardUid;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdAddMaster, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  CopyMemory( @data[1], CardUID.PRaw, SizeOf(CardUID.Raw) );
  data[0]:= Row;

  FSendPacketCount := PrepareData( data , SizeOf(CardUID.Raw) + 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.CallException(AnException: Word;
  const WinError: Int64);
var
  WinMessage: string;
begin
//  if Assigned(FOnException) then
//  begin
//    if WinError > 0 then //get windows error string
//    try
//      Win32Check(winerror = 0);
//    except
//      on E:Exception do
//        WinMessage := e.message;
//    end;
//    FOnException(self,TException(AnException),ComErrorMessages[AnException],WinError, WinMessage);
//  end
//  else
  if WinError > 0 then
    raise ELockersWD05.Create(AnException, WinError)
  else
    raise ELockersWD05.CreateNoWinCode(AnException);
end;

procedure TCustomLockerWD05.ClearRecvPacketHeader;
begin
  ZeroMemory( @FRecvPacketHeader, SizeOf(TWD05PacketHeader));
end;

procedure TCustomLockerWD05.ClearSendPacket;
begin
  ZeroMemory(@FSendPacket, FSendPacketCount);
  FSendPacketCount:= 0;
end;

procedure TCustomLockerWD05.ClearSendPacketHeader;
begin
  ZeroMemory( @FSendPacketHeader, SizeOf(TWD05PacketHeader));
end;

constructor TCustomLockerWD05.Create(AOwner: TComponent; APortName: string;
  APortBaud: TBaudRate);
begin
  Create(AOwner);

  FPortName:= APortName;
  FPortSpeed:= APortBaud;
end;

constructor TCustomLockerWD05.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FSleepSyncMS:= 10;

  ClearSendPacket;
  ClearSendPacketHeader;
  ClearRecvPacketHeader;

  FMasterCardLength := uclFour;
  FCellCardLength   := uclFour;

  FLinks:= TList.Create;
  FHasLink:= HasLink;
end;

procedure TCustomLockerWD05.DelCellCard(CellIndex, DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdDelCellCard, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= CellIndex;

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.DelCellCardSync(CellIndex, DeviceAddress: Byte);
var
  link: TLockerWD05Link;
  oldWaitTime:Integer;
begin
  link:= TLockerWD05Link.create;
//  link.OnResponseFindCard:= SelfResponseFindCard;
  link.OnError:= SelfError;
  link.OnSimpleResponse:= SelfSimpleResponse;
  Self.RegisterLink(link);
  oldWaitTime:= Self.WaitAnswerTimeout;
  Self.WaitAnswerTimeout:= 2 * oldWaitTime;
  try
//    Result:= -1;
//    sleep(100);
    DelCellCard(CellIndex, DeviceAddress);
    FAnswerError := '';
    FAddress:= DeviceAddress;
    while FAnswerError = '' do
    begin
      Delay(FSleepSyncMS);
      application.ProcessMessages;
    end;
    if FAnswerError <> 'OK' then
      raise Exception.Create(FAnswerError);
  finally
    Self.UnRegisterLink(link);
    link.Free;
    FAnswerError := '';
    FAddress:= 0;
    Self.WaitAnswerTimeout:= oldWaitTime;
  end;
end;

procedure TCustomLockerWD05.DeleteMaster(Row, DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdDelMaster, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= Row;

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

destructor TCustomLockerWD05.Destroy;
begin

  inherited Destroy;
  FLinks.Free;
end;

procedure TCustomLockerWD05.DoAfterActive;
var
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  inherited DoAfterActive;

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnAfterActive) then
      LockerWD05Link.OnAfterActive(Self);
  end;

end;

procedure TCustomLockerWD05.DoError(ErrCode: Cardinal; ErrMessage: string);
var
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  inherited DoError(ErrCode, ErrMessage);

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnError) then
      LockerWD05Link.OnError(Self, ErrCode, ErrMessage);
  end;

end;

procedure TCustomLockerWD05.DoPacketHandler(APacket: PBuffer; ASize: Integer);
var
  crcPacket: Byte;
  sb: TByteArray;
begin
  if ASize > PACKET_HEADER_LEN then
  begin
    ClearRecvPacketHeader;
    CopyMemory(@FRecvPacketHeader, @APacket^[0], PACKET_HEADER_LEN);

    APacket^[DATA_PACKET_CRC_POS]:= 0;

    crcPacket := calcCRC(APacket^, ASize);
    if crcPacket <> FRecvPacketHeader.CRC then
    begin
      inherited DoNotify(Format( rsPacketCRCError, [FRecvPacketHeader.CRC, crcPacket] ));
    end else
    begin
      inherited DoNotify(Format( rsPacketCRCSuccess, [FRecvPacketHeader.CRC, crcPacket] ));
      CopyMemory(@sb, @APacket^[PACKET_HEADER_LEN], ASize - PACKET_HEADER_LEN);
      ParseResponse(sb, ASize - PACKET_HEADER_LEN);
    end;
  end else
    inherited DoPacketHandler(APacket, ASize);
end;

procedure TCustomLockerWD05.FindCellCard(CardUID: TWD05CardUid;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdFindCard, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  CopyMemory( @data, CardUID.PRaw, SizeOf(CardUID.Raw) );

  FSendPacketCount := PrepareData( data , SizeOf(CardUID.Raw));

  SendPacket(@FSendPacket, FSendPacketCount);
end;

function TCustomLockerWD05.FindCellCardSync(CardUID: TWD05CardUid;
  DeviceAddress: Byte): Integer;
var
  link: TLockerWD05Link;
  oldWaitTime: Integer;
begin
  link:= TLockerWD05Link.create;
  link.OnResponseFindCard:= SelfResponseFindCard;
  link.OnError:= SelfError;
  link.OnSimpleResponse:= SelfSimpleResponse;
  Self.RegisterLink(link);
  oldWaitTime:= Self.WaitAnswerTimeout;
  Self.WaitAnswerTimeout:= 2 * oldWaitTime;
  try
    Result:= -1;
//    sleep(100);
    FindCellCard(CardUID, DeviceAddress);
    FAnswerError := '';
    FAddress:= DeviceAddress;
    while FAnswerError = '' do
    begin
      Delay(FSleepSyncMS);
      application.ProcessMessages;
    end;
    if FAnswerError = 'OK' then
      Result:= FCellNumber
    else if FAnswerError <> rsNotFoundUID then
      raise Exception.Create(FAnswerError);
  finally
    Self.UnRegisterLink(link);
    link.Free;
    FAnswerError := '';
    FAddress:= 0;
    Self.WaitAnswerTimeout:= oldWaitTime;
  end;
end;

procedure TCustomLockerWD05.FindMaster(CardUID: TWD05CardUid;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdFindMaster, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  CopyMemory( @data, CardUID.PRaw, SizeOf(CardUID.Raw) );

  FSendPacketCount := PrepareData( data , SizeOf(CardUID.Raw));

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.GetCellCard(CellIndex, DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetCellCard, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= CellIndex;

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.GetCellCardLength(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetCardLength, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

function TCustomLockerWD05.GetCellCardSync(CellIndex, DeviceAddress: Byte): TWD05CardUid;
var
  link: TLockerWD05Link;
  oldWaitTime: Integer;
  st: TDateTime;
begin
  link:= TLockerWD05Link.create;
  link.OnResponseCellCard:= SelfResponseCellCard;
  link.OnError:= SelfError;
  link.OnSimpleResponse:= SelfSimpleResponse;
  Self.RegisterLink(link);
  oldWaitTime:= Self.WaitAnswerTimeout;
  Self.WaitAnswerTimeout:= 2 * oldWaitTime;
  if not Assigned(FCellCard) then
    FCellCard:= TWD05CardUid.Create
  else
    FCellCard.Clear;
  try
    Result:= TWD05CardUid.Create;
//    sleep(100);
    st:= Now;
    GetCellCard(CellIndex, DeviceAddress);
    FAnswerError := '';
    FAddress:= DeviceAddress;
    while FAnswerError = '' do
    begin
      Delay(FSleepSyncMS);
      application.ProcessMessages;
    end;
    OutputDebugString(PWideChar(FormatDateTime('hh:mm:ss.zzz', Now - st)));
    if FAnswerError <> 'OK' then
      raise Exception.Create(FAnswerError);
    Result.Assign( FCellCard);
  finally
    Self.UnRegisterLink(link);
    link.Free;
    FAnswerError := '';
    FAddress:= 0;
    Self.WaitAnswerTimeout:= oldWaitTime;
  end;
end;

procedure TCustomLockerWD05.GetCellCount(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetCellCount, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.GetMaster(Row, DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetMaster, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= Row;

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.GetMasterLength(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetMasterLength, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.GetSerialNumber(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdGetSerialNumber, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

function TCustomLockerWD05.HasLink: Boolean;
var
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  Result := False;
  // examine links
  if FLinks.Count > 0 then
    for I := 0 to FLinks.Count - 1 do
    begin
      LockerWD05Link := TLockerWD05Link(FLinks[I]);
      if Assigned(LockerWD05Link.OnPing) then
        Result := True;
    end;
end;

procedure TCustomLockerWD05.OpenLockerCell(CellIndex, DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdOpenCellLock, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= CellIndex;

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.ParseFindCardResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  c: Byte;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount >= 2) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_R )) then
  begin
    c := 0;
    inherited DoNotify(rsNotFoundUID);
    for I := 0 to FLinks.Count - 1 do
    begin
      LockerWD05Link:= TLockerWD05Link(FLinks[i]);
      if Assigned(LockerWD05Link.OnSimpleResponse) then
        LockerWD05Link.OnSimpleResponse(Self, FRecvPacketHeader.DeviceAddress, rsNotFoundUID);
    end;
    if Assigned(FSimpleResponseEvent) then
      FSimpleResponseEvent(Self, FRecvPacketHeader.DeviceAddress, rsNotFoundUID);
  end else
  begin
    c := DataBuffer[0] + 1;
  end;

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseFindCard) then
      LockerWD05Link.OnResponseFindCard(Self, FRecvPacketHeader.DeviceAddress, c);
  end;

  if Assigned(FResponseFindCardEvent) then
    FResponseFindCardEvent(Self, FRecvPacketHeader.DeviceAddress, c);
end;

procedure TCustomLockerWD05.ParseFindMasterResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  r: Byte;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount >= 2) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_C )) then
    r := 1
  else
  begin
    r := 0;
    inherited DoNotify(rsNotFoundUID);
  end;

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseFindMaster) then
      LockerWD05Link.OnResponseFindMaster(Self, FRecvPacketHeader.DeviceAddress, r);
  end;

  if Assigned(FResponseFindMasterEvent) then
    FResponseFindMasterEvent(Self, FRecvPacketHeader.DeviceAddress, r);
end;

procedure TCustomLockerWD05.ParseGetCardLengthResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  CopyMemory( @FCellCardLength, @DataBuffer, SizeOf(FCellCardLength) );

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseCardLength) then
      LockerWD05Link.OnResponseCardLength(Self, FRecvPacketHeader.DeviceAddress, FCellCardLength);
  end;

  if Assigned(FResponseCardLengthEvent) then
    FResponseCardLengthEvent(Self, FRecvPacketHeader.DeviceAddress, FCellCardLength);
end;

procedure TCustomLockerWD05.ParseGetCardResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  raw: TCardByteArray;
  cUid: TWD05CardUid;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount < SizeOf(raw)) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_R )) then
    DoError(100, rsCmdError)
  else
  begin
    CopyMemory(@raw, @DataBuffer, SizeOf(raw));
    cUid := TWD05CardUid.Create(raw);

    for I := 0 to FLinks.Count - 1 do
    begin
      LockerWD05Link:= TLockerWD05Link(FLinks[i]);
      if Assigned(LockerWD05Link.OnResponseCellCard) then
        LockerWD05Link.OnResponseCellCard( Self, FRecvPacketHeader.DeviceAddress, cUid);
    end;

    if Assigned(FResponseCellCardEvent) then
      FResponseCellCardEvent( Self, FRecvPacketHeader.DeviceAddress, cUid);
  end;
end;

procedure TCustomLockerWD05.ParseGetCellCountResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  c: Byte;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount >= 2) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_R )) then
  begin
    c := 0;
    inherited DoNotify(rsCmdError);
  end else
  begin
    c := DataBuffer[0];
  end;

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseCellCount) then
      LockerWD05Link.OnResponseCellCount(Self, FRecvPacketHeader.DeviceAddress, c);
  end;

  if Assigned(FResponseCellCountEvent) then
    FResponseCellCountEvent(Self, FRecvPacketHeader.DeviceAddress, c);
end;

procedure TCustomLockerWD05.ParseGetMasterLengthResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  CopyMemory(@FMasterCardLength, @DataBuffer, SizeOf(FMasterCardLength) );

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseMasterLength) then
      LockerWD05Link.OnResponseMasterLength(Self, FRecvPacketHeader.DeviceAddress, FMasterCardLength);
  end;

  if Assigned(FResponseMasterLengthEvent) then
    FResponseMasterLengthEvent(Self, FRecvPacketHeader.DeviceAddress, FMasterCardLength);
end;

procedure TCustomLockerWD05.ParseGetMasterResponse(
  const DataBuffer: array of Byte; const DataCount: Byte);
var
  raw: TCardByteArray;
  cUid: TWD05CardUid;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount < SizeOf(raw)) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_R )) then
    DoError(100, rsCmdError)
  else
  begin
    CopyMemory(@raw, @DataBuffer, SizeOf(raw));
    cUid := TWD05CardUid.Create(raw);

    for I := 0 to FLinks.Count - 1 do
    begin
      LockerWD05Link:= TLockerWD05Link(FLinks[i]);
      if Assigned(LockerWD05Link.OnResponseMasterCard) then
        LockerWD05Link.OnResponseMasterCard( Self, FRecvPacketHeader.DeviceAddress, cUid);
    end;

    if Assigned(FResponseMasterCardEvent) then
      FResponseMasterCardEvent( Self, FRecvPacketHeader.DeviceAddress, cUid);
  end;
end;

procedure TCustomLockerWD05.ParsePing(const DataBuffer: array of Byte;
  const DataCount: Byte);
var
  lFirmware: TWD05Firmware;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  CopyMemory(@lFirmware, @DataBuffer, DataCount );

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnPing) then
      LockerWD05Link.OnPing(Self, FRecvPacketHeader.DeviceAddress, lFirmware);
  end;

  if Assigned(FPingEvent) then
    FPingEvent(Self, FRecvPacketHeader.DeviceAddress, lFirmware);
end;

procedure TCustomLockerWD05.ParseResponse(const DataBuffer: array of Byte;
  const DataCount: Byte);
begin
  case FRecvPacketHeader.Command of
    cmdPing           : ParsePing( DataBuffer, DataCount);
    cmdSetSerialNumber: ParseSimpleResponse( DataBuffer, DataCount);
    cmdGetSerialNumber: ParseSerialResponse( DataBuffer, DataCount);
    cmdReset          : ParseSimpleResponse( DataBuffer, DataCount);
    cmdAddMaster      : ParseSimpleResponse( DataBuffer, DataCount);
    cmdFindMaster     : ParseFindMasterResponse( DataBuffer, DataCount);
    cmdDelMaster      : ParseSimpleResponse( DataBuffer, DataCount);
    cmdGetMaster      : ParseGetMasterResponse( DataBuffer, DataCount );
    cmdSetMasterLength: ParseSimpleResponse( DataBuffer, DataCount);
    cmdGetMasterLength: ParseGetMasterLengthResponse( DataBuffer, DataCount );
    cmdGetCellCount   : ParseGetCellCountResponse( DataBuffer, DataCount );
    cmdOpenCellLock   : ParseSimpleResponse( DataBuffer, DataCount);
    cmdSetCellCard    : ParseSimpleResponse( DataBuffer, DataCount);
    cmdFindCard       : ParseFindCardResponse( DataBuffer, DataCount );
    cmdDelCellCard    : ParseSimpleResponse( DataBuffer, DataCount );
    cmdGetCellCard    : ParseGetCardResponse( DataBuffer, DataCount );
    cmdSetCardLength  : ParseSimpleResponse(DataBuffer, DataCount);
    cmdGetCardLength  : ParseGetCardLengthResponse( DataBuffer, DataCount );

  else inherited DoPacketHandler(@DataBuffer, DataCount);
  end;
end;

procedure TCustomLockerWD05.ParseSerialResponse(const DataBuffer: array of Byte;
  const DataCount: Byte);
var
  c: Cardinal;
  sb: TSerialNumberArray;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  CopyMemory(@sb, @DataBuffer, SizeOf(sb));

  c:= DeviceAddress2DeviceSerial(sb);

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnResponseSerialNumber) then
      LockerWD05Link.OnResponseSerialNumber(Self, FRecvPacketHeader.DeviceAddress, c);
  end;
  if Assigned(FResponseSerialNumberEvent) then
    FResponseSerialNumberEvent(Self, FRecvPacketHeader.DeviceAddress, c);
end;

procedure TCustomLockerWD05.ParseSimpleResponse(const DataBuffer: array of Byte;
  const DataCount: Byte);
var
  s: string;
  I: Integer;
  LockerWD05Link: TLockerWD05Link;
begin
  if (DataCount >= 2) and (DataBuffer[0] = Ord( RESPONSE_E )) and (DataBuffer[1] = Ord( RESPONSE_C )) then
    s := rsCmdSuccess
  else
    s := rsCmdError;

  for I := 0 to FLinks.Count - 1 do
  begin
    LockerWD05Link:= TLockerWD05Link(FLinks[i]);
    if Assigned(LockerWD05Link.OnSimpleResponse) then
      LockerWD05Link.OnSimpleResponse(Self, FRecvPacketHeader.DeviceAddress, s);
  end;
  if Assigned(FSimpleResponseEvent) then
    FSimpleResponseEvent(Self, FRecvPacketHeader.DeviceAddress, s);
end;

procedure TCustomLockerWD05.Ping(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdPing, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

function TCustomLockerWD05.PrepareData(var Data: TDataByteArray;
  const DataCount: Integer): Byte;
var
  sb: TDataByteArray;
begin
   Result:= PACKET_HEADER_LEN + DataCount;

   CopyMemory( @sb, @FSendPacketHeader, PACKET_HEADER_LEN );
   CopyMemory( @sb[PACKET_HEADER_LEN], @Data, DataCount );

   sb[DATA_PACKET_CRC_POS]:= calcCRC(sb, Result);

   SetLength(FSendPacket, Result);
   CopyMemory( @FSendPacket[0], @sb[0], Result );
end;

procedure TCustomLockerWD05.PrepareHeader(Cmd: TWD05Commands; DeviceAddress: Byte);
begin
  FSendPacketHeader.DeviceAddress:= DeviceAddress;
  FSendPacketHeader.CRC := $00;
  FSendPacketHeader.Command:= Cmd;
end;

procedure TCustomLockerWD05.RegisterLink(ALockerWD05Link: TLockerWD05Link);
begin
  if FLinks.IndexOf(Pointer(ALockerWD05Link)) > -1 then
    //raise EComPort.CreateNoWinCode
    CallException(LError_RegFailed)
  else
    FLinks.Add(Pointer(ALockerWD05Link));
  FHasLink := HasLink;
end;

procedure TCustomLockerWD05.Reset(DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  ZeroMemory( @data, SizeOf( TDataByteArray ) );

  PrepareHeader(cmdReset, DeviceAddress);

  FSendPacketCount := PrepareData( data , 0);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.SelfError(Sender: TObject; const ErrCode: Cardinal;
  const ErrMessage: String);
begin
  FAnswerError:= ErrMessage;
end;

procedure TCustomLockerWD05.SelfResponseCellCard(Sender: TObject;
  DeviceAddress: Byte; CardUID: TWD05CardUid);
begin
  if FAddress <> DeviceAddress then Exit;

  if not Assigned(FCellCard) then
    FCellCard:= TWD05CardUid.Create;
  FCellCard.Assign(CardUID);
  FAnswerError:= 'OK';
end;

procedure TCustomLockerWD05.SelfResponseFindCard(Sender: TObject; DeviceAddress,
  CellNumber: Byte);
begin
    if FAddress <> DeviceAddress then Exit;

  FCellNumber:= CellNumber;
  FAnswerError:= 'OK';
end;

procedure TCustomLockerWD05.SelfSimpleResponse(Sender: TObject;
  DeviceAddress: Byte; Msg: string);
begin
  if Msg = rsCmdSuccess then
    FAnswerError:= 'OK'
  else
    FAnswerError:= Msg;
end;

procedure TCustomLockerWD05.SetCellCard(CellIndex: Byte; CardUID: TWD05CardUid;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdSetCellCard, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  CopyMemory( @data[1], CardUID.PRaw, SizeOf(CardUID.Raw) );
  data[0]:= CellIndex;

  FSendPacketCount := PrepareData( data , SizeOf(CardUID.Raw) + 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.SetCellCardLength(UidLength: TWD05CardUidLength;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdSetCardLength, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= Byte(UidLength);

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.SetCellCardSync(CellIndex: Byte;
  CardUID: TWD05CardUid; DeviceAddress: Byte);
var
  link: TLockerWD05Link;
  oldWaitTime: Integer;
begin
  link:= TLockerWD05Link.create;
//  link.OnResponseFindCard:= SelfResponseFindCard;
  link.OnError:= SelfError;
  link.OnSimpleResponse:= SelfSimpleResponse;
  Self.RegisterLink(link);
  oldWaitTime:= Self.WaitAnswerTimeout;
  Self.WaitAnswerTimeout:= 2 * oldWaitTime;
  try
//    Result:= -1;
//    sleep(100);
    SetCellCard(CellIndex, CardUID, DeviceAddress);
    FAnswerError := '';
    FAddress:= DeviceAddress;
    while FAnswerError = '' do
    begin
      Delay(FSleepSyncMS);
      application.ProcessMessages;
    end;
    if FAnswerError <> 'OK' then
      raise Exception.Create(FAnswerError);
  finally
    Self.UnRegisterLink(link);
    link.Free;
    FAnswerError := '';
    FAddress:= 0;
  Self.WaitAnswerTimeout:= oldWaitTime;
  end;
end;

procedure TCustomLockerWD05.SetMasterLength(UidLength: TWD05CardUidLength;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  PrepareHeader(cmdSetMasterLength, DeviceAddress);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  data[0]:= Byte(UidLength);

  FSendPacketCount := PrepareData( data , 1);

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.SetSerialNumber(SerialNumber: Cardinal;
  DeviceAddress: Byte);
var
  data: TDataByteArray;
  sb: TSerialNumberArray;
begin
  ClearSendPacket;
  ClearSendPacketHeader;

  sb:= DeviceSerial2DeviceAddress(SerialNumber);

  ZeroMemory( @data, SizeOf( TDataByteArray ) );
  CopyMemory( @data, @sb, SizeOf( Cardinal ) );

  PrepareHeader(cmdSetSerialNumber, DeviceAddress);

  FSendPacketCount := PrepareData( data , SizeOf( Cardinal ) );

  SendPacket(@FSendPacket, FSendPacketCount);
end;

procedure TCustomLockerWD05.UnRegisterLink(ALockerWD05Link: TLockerWD05Link);
begin
  if FLinks.IndexOf(Pointer(ALockerWD05Link)) = -1 then
    //raise EComPort.CreateNoWinCode
    CallException(LError_RegFailed)
  else
    FLinks.Remove(Pointer(ALockerWD05Link));
  FHasLink := HasLink;
end;

{ TWD05CardUid }

constructor TWD05CardUid.Create(ARaw : TCardByteArray);
begin
  Create;
  SetRaw(ARaw);
end;

procedure TWD05CardUid.AssignTo(Dest: TPersistent);
begin
  TWD05CardUid(Dest).Raw:= Self.Raw;
end;

procedure TWD05CardUid.Clear;
begin
  ZeroMemory(@FRaw, SizeOf(FRaw));
  FillChar(FRaw, SizeOf(FRaw), $FF);
end;

function TWD05CardUid.Compare(Dest: TWD05CardUid): Integer;
var
  I: Integer;
begin
  Result:= 0;
  if Self.IsEmpty = Dest.IsEmpty then
    Exit;
  for I := Length(FRaw) - 1 downto 0 do
  begin
    if Self.FRaw[i] > Dest.Raw[i] then
      Result := 1
    else if Self.FRaw[i] < Dest.Raw[i] then
      Result := -1;
    if Result <> 0 then
      Break;
  end;
end;

constructor TWD05CardUid.Create(AHex: string);
begin
  Create;
  FromString(AHex);
end;

procedure TWD05CardUid.FromString(sUid: string);
var
  len, i, j: Integer;
  s: string;
begin
  Clear;
  sUid:= StringReplace(sUid, '0x', '', [rfReplaceAll]);
  sUid:= StringReplace(sUid, '$', '', [rfReplaceAll]);
  sUid:= StringReplace(sUid, ' ', '', [rfReplaceAll]);
  len := Length(sUid);
  j:= Length(FRaw) - 1;
  s:= '';
  for I := len downto 1 do
  begin
    s:= sUid[i] + s;
    if (j >= 0) and (Length(s) = 2) then
    begin
      FRaw[j]:= StrToUIntDef('$'+s, $0); Dec(j);
      s:= '';
    end;
  end;
  if (j >= 0) and (Length(s) > 0) then
  begin
    FRaw[j]:= StrToUIntDef('$'+s, $0);
    s:= '';
  end;
end;

constructor TWD05CardUid.Create;
begin
  inherited Create;

  Clear;
end;

function TWD05CardUid.GetIsEmpty: Boolean;
var
  I, e, z: Integer;
begin
  e:= 0;
  z:= 0;
  for I := 0 to Length(FRaw) - 1 do
  begin
//    if (FRaw[i] = $00) or (FRaw[i] = $FF) then
    if (FRaw[i] = $FF) then
      inc(e);
    if (FRaw[i] = $00) then
      inc(z);
  end;
  Result:= (e = Length(FRaw));
  if Result and (z <> 0) then
    Clear;
end;

function TWD05CardUid.GetPRaw: PCardByteArray;
begin
  Result:= @FRaw;
end;

function TWD05CardUid.GetRaw: TCardByteArray;
begin
  Result:= FRaw;
end;


function TWD05CardUid.GetSUid: string;
begin
  Result:= Trim(DumpBuffer2HexDataString(@FRaw, SizeOf(FRaw), False));
end;

procedure TWD05CardUid.SetRaw(const Value: TCardByteArray);
begin
  Clear;
  CopyMemory(@FRaw, @Value, SizeOf(FRaw));
  GetIsEmpty;
end;


function TWD05CardUid.ToString: string;
begin
  Result:= Trim(DumpBuffer2HexDataString(@FRaw, SizeOf(FRaw)));
  Result:= StringReplace(Result, '0x', '', [rfReplaceAll]);
  Result:= StringReplace(Result, '$', '', [rfReplaceAll]);
  while (Pos('00', UpperCase(Result)) = 1) or (Pos('FF', UpperCase(Result)) = 1) do
  begin
    Result:= Trim(Copy(Result, 3, Length(Result) - 2));
  end;
end;

{ ELockersWD05 }

constructor ELockersWD05.Create(ACode, AWinCode: Integer);
begin
  FWinCode := AWinCode;
  FCode := ACode;
  inherited CreateFmt(LockerErrorMessages[ACode] + ' (Error: %d)', [AWinCode]);
end;

constructor ELockersWD05.CreateNoWinCode(ACode: Integer);
begin
  FWinCode := -1;
  FCode := ACode;
  inherited Create(LockerErrorMessages[ACode]);
end;

{ TWD05Firmware }

function TWD05Firmware.Empty: Boolean;
begin
  Result:=
    ((Major = 0)
      and (Minor = 0)
      and (Release = 0)
      and (Build = 0))
    or ((Major = $FF)
      and (Minor = $FF)
      and (Release = $FF)
      and (Build = $FF))
end;

initialization
  LockerErrorMessages[LError_RegFailed]:= rsLError_RegFailed;
end.
