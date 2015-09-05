unit SLTOUT;

{$mode objfpc}

interface

uses
  Arduino_compat, commontx, nrf24l01, stm32f103fw;

const
  payloadsize = 7;
  nfreqchannels = 15;
  ttxid_size = 4;

type



  { TSLTOUT_TX }

  TSLTOUT_TX = class(TcommonTx)
  private
    radio: TRF24;
    bitrate: byte;// = NRF24L01_BR_250K;
    nrf_power: byte;// = NRF24L01_PWR_MAX;
    //  txid : array [0..4] of longint;
    rf_channels: array[0..nfreqchannels - 1] of byte;
    packet_sent: boolean;// = False;
    rf_ch_num: byte;
    counter: word;
    procedure send_command(Data: array of byte);
    procedure sendBindPacket;
    procedure radio_init;
    procedure setTXId(_txid: longword);
    procedure mydelay1ms;
  public
    //   txid: array [0..2] of longint;
    constructor Create(_bitrate: byte = NRF24L01_BR_250K; _timeCycle: byte = 44);
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;



implementation

{ TSLTOUT_TX }

procedure TSLTOUT_TX.send_command(Data: array of byte);
begin
  if (packet_sent) then
  begin
    while (radio.read_register(STATUS) and (1 shl TX_DS)) = 0 do
    begin
    end;
  end;
  packet_sent := False;
  radio.flushtx;
  radio.write_register(STATUS, (1 shl TX_DS) or (1 shl RX_DR) or (1 shl MAX_RT));
  radio.write_payload(Data, sizeof(Data));
  packet_sent := True;

end;

procedure TSLTOUT_TX.sendBindPacket;
begin

end;

procedure TSLTOUT_TX.radio_init;

begin
  delayMicroseconds(5000);
  radio.write_register(CONFIG, (1 shl EN_CRC) or (1 shl CRCO));
  radio.write_register(EN_AA, $00);
  radio.write_register(EN_RXADDR, $01);
  radio.write_register(SETUP_AW, $02);
  radio.write_register(SETUP_RETR, $00);
  radio.write_register(STATUS, $70);
  radio.write_register(RX_PW_P0, 4);
  radio.write_register(RF_SETUP, bitrate or nrf_power or 1);
  radio.write_register(RX_ADDR_P0, #$C3#$C3#$AA#$55, 4);
  radio.flushrx;
  DELAYMICROSECONDS(200);
  radio.flushtx;
  DELAYMICROSECONDS(200);
  radio.settxmode;
  rf_ch_num := 0;
  packet_sent := False;
end;

procedure TSLTOUT_TX.setTXId(_txid: longword);
var
  x ,i, j: byte;
  next_i: byte;
  base: byte;
  done: boolean;
  tmprfch : array [0..nfreqchannels-1] of byte = ($3F, $22, $1A, $18, $1F, $28, $1C, $09, $11, $40, $23, $13, $47, $2C, $17);
begin
  txid[0]:=$7C;
  txid[1]:=$95;
  txid[2]:=$C1;
  txid[3]:=$70;
  move(tmprfch,rf_channels,nfreqchannels);
  //txid[0] := (_txid shr 24) and $FF;
  //txid[1] := (_txid shr 16) and $FF;
  //txid[2] := (_txid shr 8) and $FF;
  //txid[3] := _txid and $FF;
  //for x := 0 to 3 do
  //begin
  //  next_i := (x + 1) mod 4;
  //  if i < 2 then
  //  begin
  //    base := $3;
  //  end
  //  else
  //  begin
  //    base := $10;
  //  end;
  //  rf_channels[x * 4 + 0] := (txid[x] and $3F) + base;
  //  rf_channels[x * 4 + 1] := (txid[x] shr 2) + base;
  //  rf_channels[x * 4 + 2] := (txid[x] shr 4) + ((txid[next_i] and $03) * $10) + base;
  //  if ((x * 4) + 3) < nfreqchannels then
  //  begin
  //    rf_channels[x * 4 + 3] := (txid[x] shr 6) + ((txid[next_i] and $0F) * 4) + base;
  //  end;
  //end;
  //
  //for i := 0 to nfreqchannels - 1 do
  //begin
  //  done := True;
  //  while done do
  //  begin
  //    done := False;
  //    for j := 0 to i do
  //    begin
  //      if rf_channels[i] = rf_channels[j] then
  //      begin
  //        done := True;
  //        rf_channels[i] := rf_channels[i] + 7;
  //        if rf_channels[i] >= $50 then
  //        begin
  //          rf_channels[i] := $03 + rf_channels[i] - $50;
  //        end;
  //      end;
  //    end;
  //  end;
  //end;

end;

procedure TSLTOUT_TX.mydelay1ms;
var
  delay: longword;
begin
  for delay := 0 to 720 do
  begin
    asm
             NOP;
    end;
  end;
end;

constructor TSLTOUT_TX.Create(_bitrate: byte; _timeCycle: byte);
begin
  radio := TRF24.Create(PA8, PB12, $7);

  //in order to get the most entropy, useless?
  bitrate := _bitrate;
  nrf_power := NRF24L01_PWR_MAX;
  timeCycle := _timeCycle;  //msec of timeCycle
  Name := 'SLT ';
  radio_init;
  setTXId(cpuUniqueID0 and cpuUniqueID1 or cpuUniqueID2);
end;

destructor TSLTOUT_TX.Destroy;
begin
  radio.flushtx;
  radio.flushrx;
  radio.Free;
  inherited Destroy;
end;

procedure TSLTOUT_TX.bind;
var
  buf: array[0..3] of byte;
begin
  buf[0] := byte(txid[0]);
  buf[1] := byte(txid[1]);
  buf[2] := byte(txid[2]);
  buf[3] := byte(txid[3]);
  if (packet_sent) then
  begin
    while (radio.read_register(STATUS) and (1 shl TX_DS)) = 0 do
    begin
    end;
  end;
  packet_sent := False;
  radio.write_register(RF_SETUP, bitrate or NRF24L01_PWR_LOW or 1);
  radio.write_register(TX_ADDR, #$7E#$B8#$63#$A9, 4);
  radio.write_register(RF_CH, $50);
  send_command(buf);
  if (packet_sent) then
  begin
    while (radio.read_register(STATUS) and (1 shl TX_DS)) = 0 do
    begin
    end;
  end;
  packet_sent := False;
  radio.write_register(RF_SETUP, bitrate or nrf_power or 1);
  radio.write_register(TX_ADDR, buf, 4);
  counter := 0;
end;

procedure TSLTOUT_TX.unbind;
begin

end;

procedure TSLTOUT_TX.command(Model: TModelData);
var
   sltData: array [0..6] of byte;
  msbbyte: word;
  i: word;
begin
  sltData[0] := $FF and Model.frame[aileron];
  msbbyte := (Model.frame[Aileron] shr 2) and $C0;
  sltData[1] := $FF and Model.frame[elevator];
  msbbyte := (msbbyte shr 2) or ((Model.frame[elevator] shr 2) and $C0);
  sltData[2] := $FF and Model.frame[throttle];
  msbbyte := (msbbyte shr 2) or ((Model.frame[throttle] shr 2) and $C0);
  sltData[3] := $FF and Model.frame[rudder];
  msbbyte := (msbbyte shr 2) or ((Model.frame[rudder] shr 2) and $C0);
  sltData[5] := $FF and (Model.frame[aux01] shr 2);
  sltData[6] := $FF and (Model.frame[aux02] shr 2);
  sltData[4] := msbbyte; //to be adjusted to msb's

  radio.write_register(RF_CH,rf_channels[rf_ch_num]);
  inc(rf_ch_num);
  if rf_ch_num>=nfreqchannels then rf_ch_num:=0;

  send_command(sltData);
  mydelay1ms;
  send_command(sltData);
  mydelay1ms;
  send_command(sltData);
  mydelay1ms;
  ////every 100 the bind packet has to be resent
  Inc(counter);
  if counter >= 100 then
  begin
    bind;
  end;
  ////the standard packet is sent three times after 1000usec
end;

end.
