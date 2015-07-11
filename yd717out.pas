unit YD717OUT;



interface

{$MACRO ON}
{$define _BV(i)=(1 shl i)}

uses
  Arduino_compat, commontx, NRF24L01, stm32f103fw;

type


  { TYD717 }

  { TYD717OUT_TX }

  TYD717OUT_TX = class(TCommonTX)
  private
    radio: TRF24;
    bitrate: byte;// = NRF24L01_BR_1M;
    nrf_power: byte;// = NRF24L01_PWR_MIN;
    //  txid: array [0..4] of longint;
    txidstr: string;
    procedure send_command(Data: array of byte);
    procedure radio_init;
  public

    constructor Create;
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;

const
  YD717_FLAG_NONE = $00;
  YD717_FLAG_CAMERA = $40; // also automatic Missile Launcher and Hoist in one direction
  YD717_FLAG_VIDEO = $20;
  // also Sprayer, Bubbler, Missile Launcher(1), and Hoist in the other dir.
  YD717_FLAG_FLIP = $0F;
  YD717_FLAG_LIGHT = $80;
  YD717_FLAG_BIND = $00;
  YD717_FLAG_HEADLESS = $10;
  YD717_CHANNEL = $3C;



implementation

{ TYD717OUT_TX }

procedure TYD717OUT_TX.send_command(Data: array of byte);
var
  buf: array[0..7] of byte;
  i: byte;
begin
 {
  if (Data[7] <> YD717_FLAG_BIND) then
  begin
    //AETR
    //  Serial.println("yd717_send_command1");
    buf[0] := Data[2]; //throttle
    buf[1] := Data[3]; //rudder
    buf[2] := $40; //rudder_trim unused on CT6b
    buf[3] := Data[1]; //Elevator
    buf[4] := Data[0]; //Aileron
    buf[5] := $40; //elevator_trim unused on CT6b
    buf[6] := $40; //Aileron_trim unused on CT6b
    buf[7] := Data[7];
  end
  else
  begin  //BIND PACKET
    for i := 0 to 7 do
      buf[i] := Data[i];

  end;
  }
  radio.read_register(STATUS);
  radio.write_register(STATUS, $7F);
  radio.flushtx;
  radio.write_payload(Data, 8);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl PWR_UP));
end;

procedure TYD717OUT_TX.radio_init;
begin
  radio.read_register(SETUP_AW);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl PWR_UP));
  radio.write_register(EN_AA, $3F);
  radio.write_register(EN_RXADDR, $3F);
  radio.write_register(SETUP_AW, $03);
  radio.write_register(SETUP_RETR, $1A);
  radio.write_register(RF_CH, YD717_CHANNEL);
  radio.write_register(RF_SETUP, bitrate or nrf_power or 1);
  radio.write_register(STATUS, $07);
  radio.write_register(OBSERVE_TX, $00);
  radio.write_register(CD, $00);
  radio.write_register(RX_ADDR_P2, $C3);
  radio.write_register(RX_ADDR_P3, $C4);
  radio.write_register(RX_ADDR_P4, $C5);
  radio.write_register(RX_ADDR_P5, $C6);
  radio.write_register(RX_PW_P0, 8);
  radio.write_register(RX_PW_P1, 8);
  radio.write_register(RX_PW_P2, 8);
  radio.write_register(RX_PW_P3, 8);
  radio.write_register(RX_PW_P4, 8);
  radio.write_register(RX_PW_P5, 8);
  radio.write_register(FIFO_STATUS, $00);
  radio.write_register(DYNPD, $3F);
  radio.read_register(FEATURE);
  radio.activate($73);
  radio.write_register(DYNPD, $3F);
  radio.write_register(FEATURE, $07);
  radio.read_register(FEATURE);
  radio.write_register(RX_ADDR_P0, txidstr, 5);
  radio.write_register(TX_ADDR, txidstr, 5);
  radio.flushtx;
  if (radio.read_register(STATUS) and $80) > 0 then
  begin
    radio.activate($53);
    radio.write_register($00, #$40#$4B#$01#$E2, 4);
    radio.write_register($01, #$C0#$4B#$00#$00, 4);
    radio.write_register($02, #$D0#$FC#$8C#$02, 4);
    radio.write_register($03, #$99#$00#$39#$21, 4);
    radio.write_register($04, #$D9#$96#$82#$1B, 4);
    radio.write_register($05, #$24#$06#$7F#$A6, 4);
    radio.write_register($0C, #$00#$12#$73#$00, 4);
    radio.write_register($0D, #$46#$B4#$80#$00, 4);
    radio.write_register($04, #$DF#$96#$82#$1B, 4);
    radio.write_register($04, #$D9#$96#$82#$1B, 4);
    //   radio.read_register(STATUS);
    //   radio.activate($53);
  end;

  radio.read_register(STATUS);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl PWR_UP));
  radio.flushtx;
  radio.write_register(STATUS, $7F);
  delayMicroseconds(50000);
  radio.write_register(RF_CH, YD717_CHANNEL);
  delayMicroseconds(500);
  radio.write_register(RX_ADDR_P0, txidstr, 5);
  radio.write_register(TX_ADDR, txidstr, 5);
  radio.flushtx;

end;

constructor TYD717OUT_TX.Create;
var
  _txid: longword;
  __txid: array [0..3] of longint;
begin
  _txid := cpuUniqueID0 and cpuUniqueID1 or cpuUniqueID2;
  //in order to get the most entropy, useless?
  radio := TRF24.Create(PA8, PB12, True);
  __txid[0] := (_txid shr 24) and $FF;
  txid[0] := __txid[0];
  __txid[1] := (_txid shr 16) and $FF;
  txid[1] := __txid[1];
  __txid[2] := (_txid shr 8) and $FF;
  txid[2] := __txid[2];
  __txid[3] := (_txid shr 0) and $FF;
  txid[3] := __txid[3];
  txid[0] := $57;
  txid[1] := $a1;
  txid[2] := $80;
  txid[3] := $1a;
  txid[4] := $C1;
  txidstr := char(txid[0]) + char(txid[1]) + char(txid[2]) + char(txid[3]) + char(txid[4]);
  //txidstr:=#$57#$a1#$80#$1a#$C1;
  bitrate := NRF24L01_BR_1M;
  nrf_power := NRF24L01_PWR_MAX;
  timeCycle := 16; //500usec * timeCycle
  //Name := 'X_39';
end;

destructor TYD717OUT_TX.Destroy;
begin
  inherited Destroy;
  radio.flushtx;
  radio.flushrx;
  radio.Free;
end;

procedure TYD717OUT_TX.bind;
var
  bind_packet: array[0..7] of byte = ($0, $80, $40, $80, $80, $40, $40, YD717_FLAG_BIND);
begin
  radio_init;
  send_command(bind_packet);
  radio.read_register(STATUS);
  radio.flushtx;
  radio.write_register(RX_ADDR_P0, #$65#$65#$65#$65#$65, 5);
  radio.write_register(TX_ADDR, #$65#$65#$65#$65#$65, 5);
  radio.flushtx;
  radio.flushtx;
  radio.read_register(STATUS);
  radio.write_register(STATUS, $7F);
  bind_packet[0] := txid[0];
  bind_packet[1] := txid[1];
  bind_packet[2] := txid[2];
  bind_packet[3] := txid[3];
  bind_packet[4] := $56;
  bind_packet[5] := $AA;
  bind_packet[6] := $32;
  send_command(bind_packet);
  radio.read_register(STATUS);
  radio.write_register(STATUS, $7F);
  delay_ms(100);
  radio.write_register(RX_ADDR_P0, txidstr, 5);
  radio.write_register(TX_ADDR, txidstr, 5);
  radio.flushtx;
end;

procedure TYD717OUT_TX.unbind;
begin

end;

procedure TYD717OUT_TX.command(Model: TModelData);
var
  _data: array [0..7] of byte;
begin
 { ## Example data packet
aa bb cc dd ee ff gg hh
00 80 3C 80 80 47 6C 00

0  aa: throttle (0 is full down)
1  bb: rudder (0 is full right)
2  cc: elevator trim
3  dd: elevator (0 is full down)
4  ee: aileron (0 is full right)
5  ff: aileron trim
6  gg: rudder trim
7  hh: flag }
  //AETR Sequence
  _data[0] := Model.frame[throttle] shr 2; //Throttle
  _data[1] := Model.frame[rudder] shr 2;  //Rudder
  _data[2] := $40;  //elevator trim
  _data[3] := Model.frame[elevator] shr 2;   //Elevator
  _data[4] := Model.frame[aileron] shr 2;    //Aileron
  _data[5] := $40;  // aileron trim  unused
  _data[6] := $40;  // rudder trim  unused
  _data[7] := YD717_FLAG_NONE;
  if ((Model.frame[videoOn] <> FUNCTION_DISABLED) and (Model.frame[videoOn] > 0)) then
  begin
    _data[7] := YD717_FLAG_VIDEO;
  end;
  if ((Model.frame[cameraOn] <> FUNCTION_DISABLED) and (Model.frame[cameraOn] > 0)) then
  begin
    _data[7] := _data[7] or YD717_FLAG_CAMERA;
  end;
  if ((Model.frame[acroOn] <> FUNCTION_DISABLED) and (Model.frame[acroOn] > 0)) then
  begin
    _data[7] := _data[7] or YD717_FLAG_FLIP;
  end;
  if ((Model.frame[lightOn] <> FUNCTION_DISABLED) and (Model.frame[lightOn] > 0)) then
  begin
    _data[7] := _data[7] or YD717_FLAG_LIGHT;
  end;
  send_command(_data);
end;




end.
