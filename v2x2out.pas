unit V2X2OUT;



interface

{$MACRO ON}
{$define _BV(i)=(1 shl i)}

uses
  Arduino_compat, commontx, NRF24L01, stm32f103fw;

type

  //txid_array = array [1..3] of byte;

  { TV2X2 }

  { TV2X2OUT_TX }

  TV2X2OUT_TX = class(TCommonTX)
  private
    radio: TRF24;
    bitrate: byte;// = NRF24L01_BR_1M;
    nrf_power: byte;// = NRF24L01_PWR_MIN;
    //  txid : array [0..4] of longint;
    rf_channels: array[0..15] of byte;
    packet_sent: boolean;// = False;
    rf_ch_num: byte;
    procedure send_command(Data: array of word);
    procedure radio_init;
    procedure setTXId(_txid: longword);
  public
    //   txid: array [0..2] of longint;
    constructor Create(_bitrate: byte = NRF24L01_BR_1M; _timeCycle: byte = 8);
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;

const
  freq_hopping: array[0..3, 0..15] of byte = (
    ($27, $1B, $39, $28, $24, $22, $2E, $36,
    $19, $21, $29, $14, $1E, $12, $2D, $18), //  00
    ($2E, $33, $25, $38, $19, $12, $18, $16,
    $2A, $1C, $1F, $37, $2F, $23, $34, $10), //  01
    ($11, $1A, $35, $24, $28, $18, $25, $2A,
    $32, $2C, $14, $27, $36, $34, $1C, $17), //  02
    ($22, $27, $17, $39, $34, $28, $2B, $1D,
    $18, $2A, $21, $38, $10, $26, $20, $1F)  //  03
    );

//testfreq : array [0..15] of byte =
//  ($2B, $1F, $3D, $2C, $28, $26, $32, $3A,
//   $1D, $25, $2D, $18, $22, $16, $31, $1C);

const
  V2X2_FLAG_NONE = $0000;
  V2X2_FLAG_CAMERA = $01; // also automatic Missile Launcher and Hoist in one direction
  V2X2_FLAG_VIDEO = $02;
  // also Sprayer, Bubbler, Missile Launcher(1), and Hoist in the other dir.
  V2X2_FLAG_FLIP = $04;
  V2X2_FLAG_LIGHT = $10;
  V2X2_FLAG_BIND = $C0;
  V2X2_FLAG_HEADLESS = $02; //byte[10] of the command string;



implementation

{ TV2X2 }

constructor TV2X2OUT_TX.Create(_bitrate: byte = NRF24L01_BR_1M; _timeCycle: byte = 8);

begin
  radio := TRF24.Create(PA8, PB12, $10);
  setTXId(cpuUniqueID0 and cpuUniqueID1 or cpuUniqueID2);
  //in order to get the most entropy, useless?
  bitrate := _bitrate;
  nrf_power := NRF24L01_PWR_MAX;
  timeCycle := _timeCycle;  //msec of timeCycle
  Name := 'V2x2';
end;

destructor TV2X2OUT_TX.Destroy;
begin
  inherited Destroy;
  radio.flushtx;
  radio.flushrx;
  radio.Free;
end;

procedure TV2X2OUT_TX.setTXId(_txid: longword);
var
  i, val, increment, index: word;
  sum: word;
  fh_row: array[0..15] of byte;
  tmp: longword;

begin
  txid[0] := (_txid shr 16) and $FF;
  txid[1] := (_txid shr 8) and $FF;
  txid[2] := _txid and $FF;
  sum := txid[0] + txid[1] + txid[2];
  // Base row is defined by lowest 2 bits
  index := sum and $03;
  // Higher 3 bits define increment to corresponding row
  increment := (sum and $1E) shr 2; //->$23
  for i := 0 to 15 do
  begin
    val := freq_hopping[index, i] + increment;
    // Strange avoidance of channels divisible by 16
    if (val and $0f) > 0 then
    begin
      rf_channels[i] := val;
    end
    else
    begin
      rf_channels[i] := val - 3;
    end;
  end;
end;

procedure TV2X2OUT_TX.bind;
var
  acounter: byte = 0;
  packet: array [1..9] of word;
begin
  radio_init;
  packet[2] := $80;
  packet[3] := $80;
  packet[4] := $80;
  packet[5] := $40;
  packet[6] := $40;
  packet[7] := $40;
  packet[8] := $00;
  packet[9] := V2X2_FLAG_BIND;
  for acounter := 0 to 255 do
    // while (acounter < 255) do
  begin
    packet[1] := acounter;
    send_command(packet);
    delayMicroseconds(1000);
    // inc(acounter);
  end;
  for acounter := 254 downto 0 do
    //  while (acounter > 0) do
  begin
    packet[1] := acounter;
    send_command(packet);
    delayMicroseconds(1000);
    //          dec(acounter);
  end;
  //  packet[1]:= acounter;
  //  send_command(packet);
  delayMicroseconds(1000);
end;

procedure TV2X2OUT_TX.unbind;
begin

end;

procedure TV2X2OUT_TX.command(Model: TModelData);
var
  _data: array [1..9] of word;
begin
  _data[1] := Model.frame[Aileron] shr 2;   //from 0-1023 to 0-255
  _data[2] := Model.frame[elevator] shr 2;
  _data[3] := Model.frame[throttle] shr 2;
  _data[4] := Model.frame[rudder] shr 2;
  _data[5] := $40;
  _data[6] := $40;
  _data[7] := $40;
  _data[8] := V2X2_FLAG_NONE;
  _data[9] := V2X2_FLAG_NONE;




  if ((Model.frame[videoOn] <> FUNCTION_DISABLED) and (Model.frame[videoOn] > 0)) then
  begin
    _data[9] := V2X2_FLAG_VIDEO;
  end;
  if ((Model.frame[cameraOn] <> FUNCTION_DISABLED) and (Model.frame[cameraOn] > 0)) then
  begin
    _data[9] := _data[9] or V2X2_FLAG_CAMERA;
  end;
  if ((Model.frame[acroOn] <> FUNCTION_DISABLED) and (Model.frame[acroOn] > 0)) then
  begin
    _data[9] := _data[9] or V2X2_FLAG_FLIP;
  end;
  if ((Model.frame[headlessOn] <> FUNCTION_DISABLED) and (Model.frame[headlessOn] > 0)) then
  begin
    _data[8] := _data[8] or V2X2_FLAG_HEADLESS;
  end;
  if ((Model.frame[lightOn] <> FUNCTION_DISABLED) and (Model.frame[lightOn] = 0)) then
  begin
    _data[9] := _data[9] or V2X2_FLAG_LIGHT;
  end;



  send_command(_data);
end;

procedure TV2X2OUT_TX.radio_init;
begin
  delayMicroseconds(5000);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl CRCO));
  radio.write_register(EN_AA, $00);
  //  radio.read_register(CONFIG);
  radio.write_register(EN_RXADDR, $3F);
  radio.write_register(SETUP_AW, $03);
  radio.write_register(SETUP_RETR, $FF);
  radio.write_register(RF_CH, $08);
  radio.write_register(RF_SETUP, bitrate or nrf_power or 1);
  //  radio.write_register(RF_SETUP,$05);
  radio.write_register(STATUS, $70);
  radio.write_register(OBSERVE_TX, $00);
  radio.write_register(CD, $00);
  radio.write_register(RX_ADDR_P2, $C3);
  radio.write_register(RX_ADDR_P3, $C4);
  radio.write_register(RX_ADDR_P4, $C5);
  radio.write_register(RX_ADDR_P5, $C6);
  radio.write_register(RX_PW_P0, $10);
  radio.write_register(RX_PW_P1, $10);
  radio.write_register(RX_PW_P2, $10);
  radio.write_register(RX_PW_P3, $10);
  radio.write_register(RX_PW_P4, $10);
  radio.write_register(RX_PW_P5, $10);
  radio.write_register(FIFO_STATUS, $00);
  radio.write_register(RX_ADDR_P0, #$66#$88#$68#$68#$68, 5);
  radio.write_register(RX_ADDR_P1, #$88#$66#$86#$86#$86, 5);
  radio.write_register(TX_ADDR, #$66#$88#$68#$68#$68, 5);
  radio.activate($53); // magic for BK2421 bank switch
  if (radio.read_register(STATUS) and $80) > 0 then
  begin
    //Serial.write("BK2421!\n");
    radio.write_register($00, #$40#$4B#$01#$E2, 4);
    radio.write_register($01, #$C0#$4B#$00#$00, 4);
    radio.write_register($02, #$D0#$FC#$8C#$02, 4);
    radio.write_register($03, #$F9#$00#$39#$21, 4);
    radio.write_register($04, #$C1#$96#$9A#$1B, 4);
    radio.write_register($05, #$24#$06#$7F#$A6, 4);
    radio.write_register($06, #$0#0#0#0, 4);
    radio.write_register($07, #$0#0#0#0, 4);
    radio.write_register($08, #$0#0#0#0, 4);
    radio.write_register($09, #$0#0#0#0, 4);
    radio.write_register($0A, #$0#0#0#0, 4);
    radio.write_register($0B, #$0#$0#$0#$0, 4);
    radio.write_register($0C, #$00#$12#$73#$00, 4);
    radio.write_register($0D, #$46#$B4#$80#$00, 4);
    radio.write_register($0E, #$41#$10#$04#$82#$20#$08#$08#$F2#$7D#$EF#$FF, 11);
    radio.write_register($04, #$C7#$96#$9A#$1B, 4);
    radio.write_register($04, #$C1#$96#$9A#$1B, 4);
  end;
  radio.activate($53); // switch bank back
  DELAYMICROSECONDS(200);
  radio.flushtx;
  DELAYMICROSECONDS(200);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl CRCO) or (1 shl PWR_UP));
  rf_ch_num := 0;
  packet_sent := False;
  delayMicroseconds(5000);
end;

procedure TV2X2OUT_TX.send_command(Data: array of word);
var
  buf: array[1..16] of byte;
  str, str1: string;
  sum, i, _rf_ch: byte;
  report_done: boolean;
begin
  //AETR DESIGN
  buf[1] := Data[2];    //throttle
  if Data[3] > $7F then    //rudder
  begin
    buf[2] := Data[3];
  end
  else
  begin
    buf[2] := $7F - Data[3];
  end;

  if Data[1] > $7F then     //elevator
  begin
    buf[3] := Data[1];
  end
  else
  begin
    buf[3] := $7F - Data[1];
  end;

  if Data[0] > $7F then      //ailerons
  begin
    buf[4] := Data[0];
  end
  else
  begin
    buf[4] := $7F - Data[0];
  end;
  //Trims, unused on CT6B
  buf[5] := $40;    //rudder_trim
  buf[6] := $40;    //elevator_trim
  buf[7] := $40;    //aileron_trim
  if Data[8] = V2X2_FLAG_BIND then
  begin
    buf[1] := Data[0];
    buf[2] := Data[1];
    buf[3] := Data[2];
    buf[4] := Data[3];
    buf[5] := Data[4];
    buf[6] := Data[5];
    buf[7] := Data[6];
  end;

  // TX id
  buf[8] := txid[0];
  buf[9] := txid[1];
  buf[10] := txid[2];

  // empty
  buf[11] := Data[7]; //extended Flags
  buf[12] := 0;
  buf[13] := 0;
  buf[14] := 0;
  buf[15] := Data[8]; //simple Flags
  sum := 0;

  for i := 1 to 15 do
  begin
    sum := sum + buf[i];
  end;

  buf[16] := sum;
  if (packet_sent = True) then
  begin
    while (radio.read_register(STATUS) and (1 shl TX_DS)) <> (1 shl TX_DS) do
    begin
    end;
    // begin
    //   radio.write_register(STATUS, 1 shl MAX_RT);
    //  end;
    // radio.write_register(STATUS, 1 shl RX_DR);
    radio.write_register(STATUS, 1 shl TX_DS);

  end;
  //  radio.write_register(STATUS, 1 shl TX_DS);



  _rf_ch := rf_channels[rf_ch_num shr 1];
  Inc(rf_ch_num);
  rf_ch_num := rf_ch_num and $1F;
  radio.write_register(RF_CH, _rf_ch);
  radio.flushtx;
  radio.write_payload(buf, $10);
  packet_sent := True;
end;

end.
