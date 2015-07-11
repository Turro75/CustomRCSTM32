unit CX10_A;


{/*
 This project is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Deviation is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Deviation.  If not, see <http://www.gnu.org/licenses/>.
 */
 }




interface

uses
  Arduino_compat, commontx, nrf24l01, stm32f103fw;

const
  CX10_PACKET_SIZE = $0F;
  CX10A_PACKET_SIZE = $13;       // CX10 blue board packets have 19-byte payload


  // flags
  FLAG_FLIP = $1000; // goes to rudder channel
  FLAG_MODE_MASK = $0003;
  FLAG_HEADLESS = $0004;
  // flags2
  FLAG_VIDEO = $0002;
  FLAG_SNAPSHOT = $0004;

  RF_BIND_CHANNEL = $02;
  NUM_RF_CHANNELS = $04;

type

  { TCX10_AOUT }

  TCX10_AOUT = class(Tcommontx)
  private
    radio: TRF24;
    current_chan: word;
    bitrate: byte;// = NRF24L01_BR_1M;
    nrf_power: byte;// = NRF24L01_PWR_MIN;
    tx_id: array [0..3] of longint;
    rx_id: array[0..3] of byte;
    packet: array[0..CX10A_PACKET_SIZE - 1] of byte;
    rf_chans: array[0..3] of byte;
    procedure send_bind_command;
    procedure radio_init;

  public
    constructor Create;
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;


implementation

{ TCX10_AOUT }

constructor TCX10_AOUT.Create;
var
  _txid: longword;
begin
  _txid := cpuUniqueID0 and cpuUniqueID1 or cpuUniqueID2;
  //in order to get the most entropy, useless?
  radio := TRF24.Create(PA8, PB12, CX10A_PACKET_SIZE);
  tx_id[0] := (_txid shr 24) and $FF;
  tx_id[1] := ((_txid shr 16) and $FF);
  tx_id[2] := (_txid shr 8) and $FF;
  tx_id[3] := _txid and $FF;
  tx_id[1] := tx_id[1] and $2F;
  fillchar(rx_id, 4, #0);
  // rf channels
  rf_chans[0] := $03 + (tx_id[0] and $0F);
  rf_chans[1] := $16 + (tx_id[0] shr 4);
  rf_chans[2] := $2D + (tx_id[1] and $0F);
  rf_chans[3] := $40 + (tx_id[1] shr 4);
  current_chan := 0;
  packet[5] := $FF;
  packet[6] := $FF;
  packet[7] := $FF;
  packet[8] := $FF;
  bitrate := NRF24L01_BR_1M;
  nrf_power := NRF24L01_PWR_MAX;
  timeCycle := 12; //500usec * timeCycle
end;

procedure TCX10_AOUT.radio_init;
var
  rx_tx_addr: array [0..4] of byte = ($cc, $cc, $cc, $cc, $cc);
begin
  radio.ce(LOW);
  radio.flushtx;
  radio.flushrx;
  radio.csn(LOW);
  radio.SPI.transfer($FF);
  radio.csn(HIGH);
  radio.read_register(STATUS);
  radio.setrfoffmode;
  radio.read_register(STATUS);
  radio.settxmode;
  delay(10);
  radio.XN297_SetTXAddr(rx_tx_addr, 5);
  radio.XN297_SetRXAddr(rx_tx_addr, 5);
  radio.flushtx;
  radio.write_register(STATUS, $70);     // Clear data ready, data sent, and retransmit
  radio.write_register(EN_AA, $00);      // No Auto Acknowldgement on all data pipes
  radio.write_register(RX_PW_P0, CX10A_PACKET_SIZE);
  // bytes of data payload for rx pipe 1
  radio.write_register(EN_RXADDR, $01);  // Enable data pipe 0 only
  radio.write_register(RF_SETUP, bitrate or nrf_power or 1);
  radio.write_register(DYNPD, $00);
  radio.write_Register(FEATURE, $00);
  delay(150);
end;

procedure TCX10_AOUT.bind;

var
  timeout: longword;
  bound: boolean = False;
  bindcount: word = 100;
  i: byte;
begin
  radio_init;
  while (bound = False) do
  begin
    radio.settxmode;
    send_bind_command;
    delay(1);
    radio.setrxmode;
    radio.write_register(STATUS, $70);
    radio.flushrx;
    radio.XN297_Configure((1 shl EN_CRC) or (1 shl CRCO) or
      (1 shl PWR_UP) or (1 shl PRIM_RX));
    timeout := millis + 5;
    while (millis < timeout) and (bound = False) do
    begin
      if ((radio.read_register(STATUS) and (1 shl RX_DR)) <> 0) then
      begin
        radio.XN297_ReadPayload(packet, CX10A_PACKET_SIZE);
        if (packet[9] = $01) then
        begin
          bound := True;
          for i := 0 to 3 do
          begin
            rx_id[i] := packet[5 + i];
          end;
        end;
        break;
      end;
    end;
  end;
end;

procedure TCX10_AOUT.send_bind_command;
var
  i: word;
begin
  packet[0] := $AA;
  packet[1] := byte(tx_id[0]);
  packet[2] := byte(tx_id[1]);
  packet[3] := byte(tx_id[2]);
  packet[4] := byte(tx_id[3]);
  packet[9] := lowbyte(1500);   //aileron
  packet[10] := highbyte(1500);
  packet[11] := lowbyte(1500);   //elevator
  packet[12] := highbyte(1500);
  packet[13] := lowbyte(1000);   //throttle
  packet[14] := highbyte(1000);
  packet[15] := lowbyte(1500);   //rudder
  packet[16] := highbyte(1500);
  packet[17] := $0;
  packet[18] := $0;
  // Power on, TX mode, 2byte CRC
  // Why CRC0? xn297 does not interpret it - either 16-bit CRC or nothing
  radio.XN297_Configure((1 shl EN_CRC) or (1 shl CRCO) or (1 shl PWR_UP));
  radio.write_register(RF_CH, RF_BIND_CHANNEL);
  // clear packet status bits and TX FIFO
  radio.write_register(STATUS, $70);
  radio.FlushTx;
  radio.XN297_WritePayload(packet, cx10a_packet_size);
end;

procedure TCX10_AOUT.command(Model: TModelData);
var
  tmpvalue: word;
  i: byte;
begin
  packet[0] := $55;
  for i := 0 to 3 do
  begin
    packet[i + 1] := byte(tx_id[i]);
    packet[i + 5] := byte(rx_id[i]);
  end;
  tmpvalue := map(Model.frame[aileron], 0, 1023, 1000, 2000);
  packet[9] := lowbyte(tmpvalue);   //aileron
  packet[10] := highbyte(tmpvalue);
  tmpvalue := map(Model.frame[elevator], 0, 1023, 1000, 2000);
  packet[11] := lowbyte(tmpvalue);  //elevator
  packet[12] := highbyte(tmpvalue);
  tmpvalue := map(Model.frame[throttle], 0, 1023, 1000, 2000);
  packet[13] := lowbyte(tmpvalue);   //throttle
  packet[14] := highbyte(tmpvalue);
  tmpvalue := map(Model.frame[rudder], 0, 1023, 1000, 2000);
  packet[15] := lowbyte(tmpvalue);  //rudder
  packet[16] := highbyte(tmpvalue);   //or'ed with $10 if flag flip
  if Model.frame[acroOn] = 1023 then
  begin
    packet[16] := packet[16] or $10;
  end;
  packet[17] := $0;  //$02 if headless on / $01 if mode2 / $00 if mode1
  if Model.frame[aux01] = 1023 then
  begin
    packet[17] := $01;
  end;
  if Model.frame[headlessOn] = 1023 then
  begin
    packet[17] := $02;
  end;
  packet[18] := $0; //for video, useless on cx-10a
  // Power on, TX mode, 2byte CRC
  // Why CRC0? xn297 does not interpret it - either 16-bit CRC or nothing
  radio.XN297_Configure((1 shl EN_CRC) or (1 shl CRCO) or (1 shl PWR_UP));
  radio.write_register(RF_CH, rf_chans[current_chan]);
  Inc(current_chan);
  current_chan := current_chan mod NUM_RF_CHANNELS;
  // clear packet status bits and TX FIFO
  radio.write_register(STATUS, $70);
  radio.FlushTx;
  radio.XN297_WritePayload(packet, cx10a_packet_size);
end;

destructor TCX10_AOUT.Destroy;
begin

end;

procedure TCX10_AOUT.unbind;
begin

end;

end.
