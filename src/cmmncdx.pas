unit cmmncdx;
{$I defs.inc}

interface

uses
{$IFDEF HAS_UNITSCOPE}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ELSE ~HAS_UNITSCOPE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls
{$IFDEF HAS_UNIT_ANSISTRINGS}
{$ENDIF}
{$ENDIF ~HAS_UNITSCOPE}
;

const
  CRLF_                               = #13#10;
  CRLFD_                              = CRLF_ + CRLF_;
  
////////////////////////////////////////////////////////////////////////////////
//
function DBG( AMsg : String ) : String; overload;
function DBG( AInt : Integer ) : String; overload;
function DumpBuffer2HexDataString( Data : PByte; DataCount : Integer ): String;

function cdxShowErrorMsg    ( Msg: String ): LongInt;
function cdxShowWarningMsg  ( Msg: String ): LongInt;
function cdxShowQuestionMsg ( Msg: String; DefBtn: LongInt = MB_DEFBUTTON3 ): LongInt;
function cdxShowInfoMsg     ( Msg: String; DefBtn: LongInt = MB_DEFBUTTON3 ): LongInt;

function IfThen( AValue: Boolean; const ATrue: String; const AFalse: String ): String; overload;
  
implementation


////////////////////////////////////////////////////////////////////////////////
//
function DBG( AMsg : String ) : String;
begin
  OutputDebugString( PChar( AMsg ) );

  Result := AMsg;
end;

// -----------------------------------------------------------------------------
function DBG( AInt : Integer ) : String;
begin
  Result := DBG( IntToStr( AInt ) );
end;

// -----------------------------------------------------------------------------
function DumpBuffer2HexDataString( Data : PByte; DataCount : Integer ): String;
var
  sDBG    : String;
  I       : Integer;
  rgByte  : TByteArray;
begin   
  ZeroMemory( @rgByte, SizeOf( rgByte ) );
  CopyMemory( @rgByte, Data, DataCount );
  
  sDBG  := EmptyStr;
  
  for I := 0 to DataCount - 1 do 
    sDBG := Format( '%s 0x%.2X', [sDBG, rgByte[I]] );    

  Result := sDBG;
  
  sDBG := 'DataCount = ' + IntToStr( DataCount ) + sDBG;
  
//  DBG( sDBG );
end;


// -----------------------------------------------------------------------------
function cdxShowErrorMsg( Msg: String ): LongInt;
begin
  Result := MessageBox( Application.Handle, PChar( Msg ), 'Ошибка', MB_ICONERROR or MB_OK or MB_APPLMODAL );
end;

// -----------------------------------------------------------------------------
function cdxShowWarningMsg( Msg: String ): LongInt;
begin
  Result := MessageBox( Application.Handle, PChar( Msg ), 'Предупреждение', MB_ICONWARNING or MB_OK or MB_APPLMODAL );
end;

// -----------------------------------------------------------------------------
function cdxShowQuestionMsg( Msg: String; DefBtn: LongInt ): LongInt;
begin
  Result := MessageBox( Application.Handle, PChar( Msg ), 'Подтверждение', MB_ICONQUESTION
    or MB_YESNOCANCEL or MB_APPLMODAL or DefBtn );
end;

// -----------------------------------------------------------------------------
function cdxShowInfoMsg ( Msg: String; DefBtn: LongInt ): LongInt;
begin
  Result := MessageBox( Application.Handle, PChar( Msg ), 'Информация', MB_ICONINFORMATION or MB_OK or MB_APPLMODAL );
end;

// -----------------------------------------------------------------------------
function IfThen( AValue: Boolean; const ATrue: String; const AFalse: String ): String;
begin
  if AValue then Result := ATrue
  else Result := AFalse;
end;


end.
