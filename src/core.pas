unit core;
{$I defs.inc}

interface

uses
{$IFDEF HAS_UNITSCOPE}
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.WinSock, Vcl.ExtCtrls
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ELSE ~HAS_UNITSCOPE}
  SysUtils, Classes, Windows, WinSock, ExtCtrls
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ENDIF ~HAS_UNITSCOPE}
  , CPort;

const
  //////////////////////////////////////////////////////////////////////////////
  // Default values for controller
  DEF_COMMPORT_NAME                     = 'COM1';
  DEF_COMMPORT_SPEED                    = br38400;
//  DEF_BROADCAST_ADDRESS                 = $FFFFFFFF;
//  DEF_SEND_DATA_LEN                     = $07;
  DEF_WAIT_ANSWER_TIMER_INTERVAL        = 2000;

  //////////////////////////////////////////////////////////////////////////////
  // Response codes
  ERROR_SUCCESS                         = $00;

  //////////////////////////////////////////////////////////////////////////////
  // Additional data
  STX: Byte             = $02;
  STP: Byte             = $03;
  PACKET_ADDRESS_LEN    = $04;

type
  //////////////////////////////////////////////////////////////////////////////
  // Helper types
  TBuffer = array of Byte;
  PBuffer = ^TBuffer;

  TGeneric4ByteArray                    = array[0..PACKET_ADDRESS_LEN - 1] of Byte;
  TDeviceAddressArray                   = TGeneric4ByteArray;
  TDeviceSoftwareVersionArray           = TGeneric4ByteArray;

  //////////////////////////////////////////////////////////////////////////////
  // Events   
  TCdxNotifyEvent     = procedure( Sender: TObject; Msg: string) of object;
  TErrorEvent         = procedure( Sender : TObject; const ErrCode : Cardinal; const ErrMessage : String ) of object;
  TPacketHandlerEvent = procedure( Sender: TObject; APacket: PBuffer; Size: Integer) of object;
  TRxTxFrameEvent     = procedure( Sender: TObject; const Buffer; Count: Integer) of object;
  TRxTxHexFrameEvent  = procedure( Sender : TObject; const HexStr : String; ByteCount : Cardinal ) of object;

  TCustomCarddexProtocol = class(TComponent)
  private
    FComLink: TComLink;
    FComPort: TCustomComPort;
    FWaitAnswerTimer: TTimer;

    FRecvBuffer: TBuffer;
    FisFrame: Boolean;
    FRecvBufferCount: Integer;
    FOnPacketHandler: TPacketHandlerEvent;

    FAfterActive: TNotifyEvent;
    FNotifyEvent: TCdxNotifyEvent;
    FErrorEvent: TErrorEvent;
    FRxFrameEvent: TRxTxFrameEvent;
    FTxFrameEvent: TRxTxFrameEvent;   
    FRxHexFrameEvent: TRxTxHexFrameEvent;
    FTxHexFrameEvent: TRxTxHexFrameEvent;
    procedure DoDecodeFrame;
    procedure OnWaitAnswerTimer(Sender: TObject);
    procedure OnConn(Sender: TObject; OnOff: Boolean);
    procedure RxBuf(Sender: TObject; const Buffer; Count: Integer);
    procedure TxEmpty(Sender: TObject);
    procedure DoRxFrame(const Buffer; Count: Integer);
    procedure DoTxFrame(const Buffer; Count: Integer);
    procedure DoRxHexFrame(HexStr : String; Count: Cardinal);
    procedure DoTxHexFrame(HexStr : String; Count: Cardinal);
    procedure SetComPort(const Value: TCustomComPort);
    procedure SetRxFrameEvent(const Value: TRxTxFrameEvent);
    procedure SetTxFrameEvent(const Value: TRxTxFrameEvent);
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
    function GetWaitAnswerTimeout: Integer;
    procedure SetWaitAnswerTimeout(const Value: Integer);
  protected
    FPortName: string;
    FPortSpeed: TBaudRate;
    procedure DoAfterActive; dynamic;
    procedure DoError(ErrCode: Cardinal; ErrMessage: string); dynamic;
    procedure DoNotify(Msg: string); dynamic;
    procedure DoPacketHandler(APacket: PBuffer; ASize: Integer); dynamic;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; APortName: string; APortBaud: TBaudRate = DEF_COMMPORT_SPEED); reintroduce; overload;
    destructor Destroy; override;

    procedure SendPacket(APacket: PBuffer; ASize: Integer);// APacket - packet without start,stop bytes
    procedure ClearRecvBuffer;
    function CheckPortIsFree : Boolean; // throw Exception
    procedure InitPort(APortName: string; APortBaud: TBaudRate = DEF_COMMPORT_SPEED);
  published
    property Active         : Boolean read GetActive write SetActive;
    property ComPort: TCustomComPort read FComPort write SetComPort;
    property WaitAnswerTimeout: Integer read GetWaitAnswerTimeout write SetWaitAnswerTimeout;

    property OnAfterActive: TNotifyEvent read FAfterActive write FAfterActive;
    property OnPacketHandler: TPacketHandlerEvent read FOnPacketHandler
      write FOnPacketHandler;
    property OnNotify: TCdxNotifyEvent read FNotifyEvent write FNotifyEvent;
    property OnError: TErrorEvent read FErrorEvent write FErrorEvent;
    property OnRxFrame: TRxTxFrameEvent read FRxFrameEvent
      write SetRxFrameEvent;
    property OnTxFrame: TRxTxFrameEvent read FTxFrameEvent
      write SetTxFrameEvent;      
    property OnRxHexFrame: TRxTxHexFrameEvent read FRxHexFrameEvent
      write FRxHexFrameEvent;
    property OnTxHexFrame: TRxTxHexFrameEvent read FTxHexFrameEvent
      write FTxHexFrameEvent;
  end;

  TCarddexProtocol = class(TCustomCarddexProtocol)
  published
    property Active;
    property ComPort;
    property OnPacketHandler;
    property OnAfterActive;
    property OnNotify;
    property OnError;
    property OnRxFrame;
    property OnTxFrame;      
    property OnRxHexFrame;
    property OnTxHexFrame;
  end;

procedure EnumComPorts(PortList: TStrings);
function calcCRC(adata: array of Byte; Count: Integer;
  offset: Integer = 0): Byte;

function ConvertByteToASCIIArray( const SrcBuffer : array of Byte;
  const SrcCount : Byte;  DestBuffer : PBuffer;
  const DestCount : Byte; ExcludeFirstAndLast : Boolean = True ) : Byte;

function ConvertASCIIToByteArray( const SrcBuffer : array of Byte;
  const SrcCount : Byte;  DestBuffer : PBuffer;
  const DestCount : Byte; ExcludeFirst : Boolean = True ) : Byte; // throw Exception
                                                                               
function DumpBuffer2HexDataString( Data : PByte; DataCount : Integer; WithSpace: Boolean = True ): String;

const
  CdxError_RxTimeout = 42;

resourcestring
  rsComPortNotAssigned  = 'Невозможно выполнить запрос команды. Порт неактивен';
  rsComPortNotConnected = 'Невозможно выполнить запрос команды. Порт закрыт';
  rsComPortRxEvent      = 'Приняты данные от контроллера';
  rsComPortRxError      = 'Ошибка чтения из порта устройства';
  rsComPortNoSTX        = 'В пакете данных нет стартового байта, пакет проигнорирован';
  rsComPortTxEmpty      = 'Передача завершена';
  rsComPortTxError      = 'Ошибка записи в порт устройства';
  rsComPortRxTimeout    = 'Нет ответа от контроллера';



implementation

procedure EnumComPorts(PortList: TStrings);
begin
  CPort.EnumComPorts(PortList);
end;

function calcCRC(adata: array of Byte; Count: Integer;
  offset: Integer = 0): Byte;
var
  I: Integer;
begin
  Result := $FF;
  for I := offset to Count - 1 do
    Result := Result - adata[I];
  Result := Result + 1;
end;

// -----------------------------------------------------------------------------
function ConvertByteToASCIIArray( const SrcBuffer : array of Byte; const SrcCount : Byte;
   DestBuffer : PBuffer; const DestCount : Byte; ExcludeFirstAndLast : Boolean ) : Byte;
var
  I : Integer;
begin
  Result := 0;

  for I := 0 to SrcCount - 1 do
  begin                                  
    SetLength(DestBuffer^, Result + 1);
    if ExcludeFirstAndLast and ( I = 0 ) then
    begin
      DestBuffer^[I] := SrcBuffer[I];
      Inc( Result );

      Continue;
    end;     
    if ExcludeFirstAndLast and ( I = SrcCount - 1 ) then
    begin
      DestBuffer^[I * 2 - 1] := SrcBuffer[I];
      Inc( Result );

      Continue;
    end;                       
    SetLength(DestBuffer^, Result + 2);

    if ExcludeFirstAndLast then
    begin
      DestBuffer^[I * 2 - 1]   := Ord( UpperCase( IntToHex( ( SrcBuffer[I] shr 4 ) and $0F, 1 ) )[1] );
      DestBuffer^[I * 2]       := Ord( UpperCase( IntToHex( SrcBuffer[I] and $0F, 1 ) ) [1] );
    end
    else
    begin
      DestBuffer^[I * 2]       := Ord( UpperCase( IntToHex( ( SrcBuffer[I] shr 4 ) and $0F, 1 ) )[1] );
      DestBuffer^[I * 2 + 1]   := Ord( UpperCase( IntToHex( SrcBuffer[I] and $0F, 1 ) ) [1] );
    end;

    Inc( Result, 2 );
  end;
end;

// -----------------------------------------------------------------------------
function ConvertASCIIToByteArray( const SrcBuffer : array of Byte; const SrcCount : Byte;
   DestBuffer : PBuffer; const DestCount : Byte; ExcludeFirst : Boolean = True ) : Byte;
var
  I   : Integer;
  J   : Integer;
  c1  : Char;
  c2  : Char;
  s   : String;
  n   : Integer;
begin
  Result := 0;

  if ExcludeFirst then
  begin
    if SrcCount mod 2 > 0 then
      J := SrcCount div 2
    else
      J := SrcCount div 2 - 1;
  end
  else
    J := SrcCount div 2 - 1;

  for I := 0 to J do
  begin          
    SetLength(DestBuffer^, Result + 1);
    if ExcludeFirst and ( I = 0 ) then
    begin
      DestBuffer^[I] := SrcBuffer[I];
      Inc( Result );

      Continue;
    end;

    if ExcludeFirst then
    begin
      c1 := Char( SrcBuffer[I * 2 - 1] );
      c2 := Char( SrcBuffer[I * 2] );

      s := '$' + c1 + c2;
      if TryStrToInt( s, n ) then
        DestBuffer^[Result] := n
      else
        Break;
    end
    else
    begin
      c1 := Char( SrcBuffer[I * 2] );
      c2 := Char( SrcBuffer[I * 2 + 1] );

      s := '$' + c1 + c2;
      if TryStrToInt( s, n ) then
        DestBuffer^[Result] := n
      else
        Break;
    end;

    Inc( Result, 1 );
  end;
end;

function DumpBuffer2HexDataString( Data : PByte; DataCount : Integer; WithSpace: Boolean ): String;
var
  sDBG    : String;
  I       : Integer;
  rgByte  : TByteArray;
  s       : string;
begin
  ZeroMemory( @rgByte, SizeOf( rgByte ) );
  CopyMemory( @rgByte, Data, DataCount );

  sDBG  := EmptyStr;
  if WithSpace then
    s:= '%s 0x%.2X'
  else
    s:= '%s0x%.2X';

  for I := 0 to DataCount - 1 do
    sDBG := Format( s, [sDBG, rgByte[I]] );

  Result := sDBG;
  
  sDBG := 'DataCount = ' + IntToStr( DataCount ) + sDBG;
  
//  DBG( sDBG );
end;

{ TCustomCarddexProtocol }

function TCustomCarddexProtocol.CheckPortIsFree: Boolean;
var
  hPort : THandle;
begin
  if not Assigned(FComPort) then
  begin
    Result:= False;
    Exit;
  end;

  hPort := CreateFile( PChar( String( '\\.\' + FComPort.Port ) ),
    GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0 );

  if hPort <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle( hPort );
    Result := True;
  end
  else
  begin
    Result := False;
    RaiseLastOSError;
  end;
end;

procedure TCustomCarddexProtocol.ClearRecvBuffer;
begin
  ZeroMemory(@FRecvBuffer, FRecvBufferCount);
  FRecvBufferCount := 0;
  FisFrame:= False;
end;

constructor TCustomCarddexProtocol.Create(AOwner: TComponent; APortName: string;
  APortBaud: TBaudRate);
begin
  Create(AOwner);

  FPortName   := APortName;
  FPortSpeed  := APortBaud;
end;

constructor TCustomCarddexProtocol.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FComPort          := nil;
  FComLink          := TComLink.Create;
  FComLink.OnConn   := OnConn;
  FComLink.OnRxBuf  := RxBuf;
  FComLink.OnTxEmpty:= TxEmpty;

  FPortName  := DEF_COMMPORT_NAME;
  FPortSpeed := DEF_COMMPORT_SPEED;

  ClearRecvBuffer;

  FWaitAnswerTimer          := TTimer.Create(Self);
  FWaitAnswerTimer.Enabled  := False;
  FWaitAnswerTimer.Interval := DEF_WAIT_ANSWER_TIMER_INTERVAL;
  FWaitAnswerTimer.OnTimer  := OnWaitAnswerTimer;
end;

destructor TCustomCarddexProtocol.Destroy;
begin
  if Assigned( FWaitAnswerTimer ) then
    FreeAndNil( FWaitAnswerTimer );

  if Assigned ( FComPort ) then
  begin
    ComPort := nil;
    FreeAndNil( FComLink );
  end;

  inherited Destroy;
end;

procedure TCustomCarddexProtocol.DoAfterActive;
begin
  if Assigned(FAfterActive) then
    FAfterActive(Self);
end;

procedure TCustomCarddexProtocol.DoDecodeFrame;
var
  tmpBuf: TBuffer;
  lRecvBufferCount: Integer;
begin
  lRecvBufferCount:= ConvertASCIIToByteArray(FRecvBuffer, FRecvBufferCount, @tmpBuf, FRecvBufferCount * 2);
  CopyMemory(@tmpBuf[0], @tmpBuf[1], lRecvBufferCount - 1);
  ZeroMemory(@tmpBuf[lRecvBufferCount-1], 1);
  
  DoPacketHandler(@tmpBuf, lRecvBufferCount - 1);
end;

procedure TCustomCarddexProtocol.DoError(ErrCode: Cardinal; ErrMessage: string);
begin
  if Assigned(FErrorEvent) then
    FErrorEvent(Self,ErrCode, ErrMessage);
end;

procedure TCustomCarddexProtocol.DoNotify(Msg: string);
begin
  if Assigned(FNotifyEvent) then
    FNotifyEvent(Self, Msg);
end;

procedure TCustomCarddexProtocol.DoPacketHandler(APacket: PBuffer;
  ASize: Integer);
begin
  if Assigned(FOnPacketHandler) then
    FOnPacketHandler(Self, APacket, ASize);
end;

procedure TCustomCarddexProtocol.DoRxFrame(const Buffer; Count: Integer);
begin
  if Assigned(FRxFrameEvent) then
    FRxFrameEvent(Self, Buffer, Count);
end;

procedure TCustomCarddexProtocol.DoRxHexFrame(HexStr: String; Count: Cardinal);
begin
  if Assigned(FRxHexFrameEvent) then
    FRxHexFrameEvent(Self, HexStr, Count);
end;

procedure TCustomCarddexProtocol.DoTxFrame(const Buffer; Count: Integer);
begin
  if Assigned(FTxFrameEvent) then
    FTxFrameEvent(Self, Buffer, Count);
end;

procedure TCustomCarddexProtocol.DoTxHexFrame(HexStr: String; Count: Cardinal);
begin 
  if Assigned(FTxHexFrameEvent) then
    FTxHexFrameEvent(Self, HexStr, Count);
end;

function TCustomCarddexProtocol.GetActive: Boolean;
begin
  if Assigned(FComPort) then
    Result:= FComPort.Connected
  else
    Result:= False;
end;

function TCustomCarddexProtocol.GetWaitAnswerTimeout: Integer;
begin
  Result:= FWaitAnswerTimer.Interval;
end;

procedure TCustomCarddexProtocol.InitPort(APortName: string;
  APortBaud: TBaudRate);
begin
  FPortName   := APortName;
  FPortSpeed  := APortBaud;

  if not GetActive then
  begin
    if not Assigned(FComPort) then
    begin
      ComPort:= TCustomComPort.Create( Self );

      FComPort.DataBits:= TDataBits.dbEight;
      FComPort.StopBits:= TStopBits.sbOneStopBit;
      FComPort.Parity.Bits:= TParityBits.prNone;
    end;

    FComPort.Port:= FPortName;
    FComPort.BaudRate:= FPortSpeed;
  end;
end;

procedure TCustomCarddexProtocol.OnConn(Sender: TObject; OnOff: Boolean);
begin
  if OnOff then
    DoAfterActive;
end;

procedure TCustomCarddexProtocol.OnWaitAnswerTimer(Sender: TObject);
begin
  FWaitAnswerTimer.Enabled:= False;

  ClearRecvBuffer;

  DoError(CdxError_RxTimeout, rsComPortRxTimeout);
end;

procedure TCustomCarddexProtocol.RxBuf(Sender: TObject; const Buffer;
  Count: Integer);
var
  tmpBuf: TBuffer;
  I: Integer;
begin

  SetLength(tmpBuf, Count);
  try
    Move(Buffer, tmpBuf[0], Count);
  except
    DoError(40, rsComPortRxError);
    Exit;
  end;

  FWaitAnswerTimer.Enabled := False;

  DoNotify(rsComPortRxEvent);

  if (FRecvBufferCount = 0) and (tmpBuf[0] <> STX) and (not FisFrame) then
  begin                               
    DoNotify(rsComPortNoSTX);
    Exit;
  end;
  if (FRecvBufferCount = 0) and (tmpBuf[0] = STX) then
  begin
    FisFrame:= True;
  end;
  for I := 0 to Count - 1 do
  begin
    SetLength(FRecvBuffer, FRecvBufferCount + 1);
    FRecvBuffer[FRecvBufferCount]:= tmpBuf[i];
    Inc(FRecvBufferCount);
    if (FRecvBuffer[FRecvBufferCount - 1] = STP) then
    begin
      DoRxFrame(FRecvBuffer[0], FRecvBufferCount);
      DoRxHexFrame(DumpBuffer2HexDataString(@FRecvBuffer, FRecvBufferCount), FRecvBufferCount);
      DoDecodeFrame;
      ClearRecvBuffer;
      Exit;
    end;
  end;
end;

procedure TCustomCarddexProtocol.SendPacket(APacket: PBuffer; ASize: Integer); 
var
  pb    : TByteArray;
  sb    : TBuffer;
  LSendBufferCount: Integer;
begin
  if not Assigned( FComPort ) then
  begin
    DoNotify(Format(rsComPortNotAssigned, []));

    Exit;
  end;

  if not FComPort.Connected then
  begin                                
    DoNotify(Format(rsComPortNotConnected, []));

    Exit;    
  end;

  ZeroMemory(@pb, SizeOf( pb ));
  CopyMemory(@pb[1], @APacket^[0], ASize);
  pb[0]     := STX;
  pb[ASize+1] := STP;
  ASize     := ASize + 2;
  
  LSendBufferCount := ConvertByteToASCIIArray(pb, ASize, @sb, ASize * 2);
   
  if Assigned( FComPort ) and FComPort.Connected then
  begin
    DoTxFrame(sb[0], LSendBufferCount);
    DoTxHexFrame( DumpBuffer2HexDataString(@sb, LSendBufferCount), LSendBufferCount);

    FWaitAnswerTimer.Enabled  := True;

    try
      sleep(100);
      FComPort.Write(sb[0], LSendBufferCount);
    except
      Active:= False;

      DoError(41, rsComPortTxError);
    end;
  end;
end;

procedure TCustomCarddexProtocol.SetActive(const Value: Boolean);
var
  lErrMessage: string;
begin
  if Value <> GetActive then
  begin
    if Value then
    try
      InitPort(FPortName, FPortSpeed);

      if CheckPortIsFree then
        FComPort.Connected:= True;
    except on E: EOSError do
      begin
        lErrMessage:= e.Message;

        lErrMessage := StringReplace( lErrMessage, #10, ' ', [] );
        lErrMessage := StringReplace( lErrMessage, #13, ' ', [] );

        DoError(e.ErrorCode, lErrMessage);
      end;
    end
    else
    begin
      if Assigned(FComPort) then
        FComPort.Connected:= False;
      ClearRecvBuffer;
    end;
  end;
end;

procedure TCustomCarddexProtocol.SetComPort(const Value: TCustomComPort);
begin
  if Value <> FComPort then
  begin
    if FComPort <> nil then
      FComPort.UnRegisterLink(FComLink);
    FComPort := Value;
    if FComPort <> nil then
    begin
      FComPort.FreeNotification(Self);
      FComPort.RegisterLink(FComLink);

      FPortName:= FComPort.Port;
      FPortSpeed:= FComPort.BaudRate;
    end;
  end;
end;

procedure TCustomCarddexProtocol.SetRxFrameEvent(const Value: TRxTxFrameEvent);
begin
  FRxFrameEvent := Value;
end;

procedure TCustomCarddexProtocol.SetTxFrameEvent(const Value: TRxTxFrameEvent);
begin
  FTxFrameEvent := Value;
end;

procedure TCustomCarddexProtocol.SetWaitAnswerTimeout(const Value: Integer);
begin
  FWaitAnswerTimer.Interval:= Value;
end;

procedure TCustomCarddexProtocol.TxEmpty(Sender: TObject);
begin
  DoNotify(rsComPortTxEmpty);
end;

end.
