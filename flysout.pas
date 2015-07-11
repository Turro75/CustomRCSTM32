unit FLYSOUT;

{$mode objfpc}

interface

uses
  Arduino_compat, commontx, HWSerial, HWTimer, stm32f103fw;

type

  { FLYSOUT_TX }

  FLYSOUT_TX = class(TCommonTX)
  private

  public

    constructor Create(_baudRate: longword);
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;


implementation

{ FLYSOUT_TX }

constructor FLYSOUT_TX.Create(_baudRate: longword);
begin
  if Serial1 <> nil then
  begin
    Serial1.Free;
  end;
  Serial1 := TSTM32Serial.Create(USART1, _baudRate);
  timeCycle := 40;
end;

destructor FLYSOUT_TX.Destroy;
begin
  inherited Destroy;
  Serial1.Free;
end;

procedure FLYSOUT_TX.bind;
begin
  inherited bind;
end;

procedure FLYSOUT_TX.unbind;
begin
  inherited unbind;
end;

procedure FLYSOUT_TX.command(Model: TModelData);
var
  tmpstr: string;
  chksum: word;
  tmpvalue: word;
  i: TFunctions;
begin
  chksum := $55 + $FC;
  tmpstr := char($55) + char($FC);

  tmpvalue := Model.frame[aileron] shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := Model.frame[aileron] and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);

  tmpvalue := Model.frame[elevator] shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := Model.frame[elevator] and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);

  tmpvalue := Model.frame[throttle] shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := Model.frame[throttle] and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);

  tmpvalue := Model.frame[rudder] shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := Model.frame[rudder] and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);

  tmpvalue := Model.frame[aux01] shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := Model.frame[aux01] and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);

  tmpvalue := highbyte(Model.frame[aux02]);// shr 8;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue);
  tmpvalue := lowbyte(Model.frame[aux02]);// and $FF;
  chksum := chksum + tmpvalue;
  tmpstr := tmpstr + char(tmpvalue) + char(chksum shr 8) + char(chksum and $FF);

  Serial1.println(tmpstr);
end;

end.
