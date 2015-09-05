unit ModelManager;

{$mode objfpc}

interface

uses
  channelMixer, commontx;

const
  MAX_MODELS = 10;

type
  TModelList = array[0..MAX_MODELS - 1] of string;

function getModelList: TModelList;
procedure saveModel(_Model: TModelData; index: byte);
function getModelByIndex(index: byte; var tmpModel: TmodelData): TModelData;
function getModelByName(_name: string; var tmpModel: TmodelData): TModelData;
procedure getCalData;
procedure saveCalData;

var
  ModelList: TModelList;

implementation

function getModelList: TModelList;
var
  //i:byte;
  tmpList: TModelList;
begin
  tmpList[0] := ' PPM+ ';
  tmpList[1] := ' V2X2 ';
  tmpList[2] := 'CX10-A';
  tmpList[3] := ' BRAD ';
  tmpList[4] := ' X_39 ';
  tmpList[5] := 'PPM_8 ';
  tmpList[6] := 'PPM_10';
  tmpList[7] := ' FLYS ';
  tmpList[8] := 'FS_BND';
  tmpList[9] := 'TACTIC';
  Result := tmpList;
end;

procedure saveModel(_Model: TModelData; index: byte);
begin
  //procedure which reach the exact flash position then serialize the object

  //for each Model You need to save:
  //1)Name   10chars
  //2)Protocol  1word
  //3)PPMValues(period,min,max,pause,positive) 5 word
  //4)serialBaudRate   1word
  //5)the array [0..MAX_CHANNELS-1] of channels with 4 data:
  //a)Input  (as is)  1 word
  //b)Action (as is)  1 word
  //c)gain   (if channel inverted the -Gain    1 integer
  //d)curve  (as is)  1 word

  { ModelStoredSize:=MAX_MODELS*(
   }
end;

function getModelByIndex(index: byte; var tmpModel: TmodelData): TModelData;

begin
  //function which find the exact position in the flash given by index*ModelSize
  tmpModel := TModelData.Create;
  tmpModel.Name := ModelList[index];

  case index of
    0:
    begin
      //PPM
      tmpModel.serialBaudRate := 115200;
      tmpModel.ppm_max := 1700;
      tmpModel.ppm_min := 700;
      tmpModel.ppm_period := 18500;
      tmpModel.ppm_pause := 300;
      tmpModel.ppm_positive := True;
      tmpModel.protocol := ppm_p_prot;
      tmpModel.channels[2] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[3] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[1] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[0] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(Pot1, aux01, 100, curve00);
      tmpModel.channels[7] := TChannel.Create(Pot2, aux02, 100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, aux01, -100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW4, aux01mid, 100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW0, aux02, -100, curve00);
    end;
    1:
    begin
      //V2X2
      tmpModel.protocol := v2x2prot;
      tmpModel.channels[0] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[1] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[2] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[3] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW3, headlessOn, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[7] := TChannel.Create(SW0, acroOn, -100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, lightOn, 100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW2, videoOn, -100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW4, returntohomeOn, -100, curve00);
      tmpModel.channels[11] := TChannel.Create(SW6, cameraOn, -100, curve00);
    end;
    2:
    begin
      //CX10-A blue board
      tmpModel.protocol := cx10aprot;
      tmpModel.channels[0] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[1] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[2] := TChannel.Create(RVStick, elevator, -50, curve00Dual);
      tmpModel.channels[3] := TChannel.Create(RHStick, aileron, 50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(SW0, acroOn, -100, curve00);
      tmpModel.channels[7] := TChannel.Create(SW3, headlessOn, -100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW4, aux01, 100, curve00);  //mode2
    end;
    3:
    begin
      //BRADWII
      tmpModel.protocol := bradprot;
      tmpModel.channels[0] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[1] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[2] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[3] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW3, headlessOn, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[7] := TChannel.Create(SW0, acroOn, -100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, lightOn, 100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW2, videoOn, -100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW4, returntohomeOn, -100, curve00);
    end;
    4:
    begin
      //X_39
      tmpModel.protocol := yd717prot;
      tmpModel.channels[0] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[1] := TChannel.Create(LHStick, rudder, -50, curve00Dual);
      tmpModel.channels[2] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[3] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW3, headlessOn, -100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW4, returntohomeOn, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[7] := TChannel.Create(SW0, acroOn, -100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, lightOn, 100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW2, videoOn, -100, curve00);
    end;

    5:
    begin
      //PPM+ Extended to 8 channels multiplexed
      tmpModel.serialBaudRate := 115200;
      tmpModel.ppm_max := 1700;
      tmpModel.ppm_min := 700;
      tmpModel.ppm_period := 18500;
      tmpModel.ppm_pause := 300;
      tmpModel.ppm_positive := True;
      tmpModel.protocol := ppm_ext8_prot;
      tmpModel.channels[2] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[3] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[1] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[0] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(Pot1, aux01, 100, curve00);
      tmpModel.channels[7] := TChannel.Create(Pot2, aux02, 100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, aux03, -100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW4, aux03mid, 100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW0, aux04, -100, curve00);
      //   tmpModel.channels[11]:=TChannel.Create(SW1,aux05,-100, curve00);
      //   tmpModel.channels[12]:=TChannel.Create(SW2,aux05mid,-100, curve00);
      //   tmpModel.channels[13]:=TChannel.Create(SW5,aux06,-100, curve00);
    end;
    6:
    begin
      //PPM+ Extended to 10 channels multiplexed
      tmpModel.serialBaudRate := 115200;
      tmpModel.ppm_max := 1700;
      tmpModel.ppm_min := 700;
      tmpModel.ppm_period := 18500;
      tmpModel.ppm_pause := 300;
      tmpModel.ppm_positive := True;
      tmpModel.protocol := ppm_ext10_prot;
      tmpModel.channels[2] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[3] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[1] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[0] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(Pot1, aux01, 100, curve00);
      tmpModel.channels[7] := TChannel.Create(Pot2, aux02, 100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW3, aux03, -100, curve00);
      tmpModel.channels[9] := TChannel.Create(SW4, aux03mid, 100, curve00);
      tmpModel.channels[10] := TChannel.Create(SW0, aux04, -100, curve00);
      tmpModel.channels[11] := TChannel.Create(SW1, aux05, -100, curve00);
      tmpModel.channels[12] := TChannel.Create(SW2, aux05mid, 100, curve00);
      tmpModel.channels[13] := TChannel.Create(SW5, aux06, 100, curve00);
    end;
    7:
    begin
      //FLYS  FLYSKY CT6B serial protocol
      tmpModel.serialBaudRate := 115200;
      tmpModel.protocol := FSkyProt;
      tmpModel.channels[2] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[3] := TChannel.Create(LHStick, rudder, 50, curve00Dual);
      tmpModel.channels[1] := TChannel.Create(RVStick, elevator, 50, curve00Dual);
      tmpModel.channels[0] := TChannel.Create(RHStick, aileron, -50, curve00Dual);
      tmpModel.channels[4] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(SW3, aux01, -100, curve00);
      tmpModel.channels[7] := TChannel.Create(SW4, aux01mid, 100, curve00);
      tmpModel.channels[8] := TChannel.Create(SW0, aux02, -100, curve00);
    end;
    8:
    begin
      //FMS1  new FMS protocol 19200 baudrate
      tmpModel.protocol := FS_Bind;
    end;
    9:
    begin
      tmpModel.serialBaudRate := 115200;
      tmpModel.ppm_max := 1700;
      tmpModel.ppm_min := 700;
      tmpModel.ppm_period := 18500;
      tmpModel.ppm_pause := 300;
      tmpModel.ppm_positive := True;
      tmpModel.protocol := sltprot;
      tmpModel.channels[2] := TChannel.Create(LVStick, throttle, 100, curve00);
      tmpModel.channels[3] := TChannel.Create(LHStick, rudder, 50, curve02Dual);
      tmpModel.channels[1] := TChannel.Create(RVStick, elevator, 50, curve02Dual);
      tmpModel.channels[0] := TChannel.Create(RHStick, aileron, -50, curve02Dual);
      tmpModel.channels[4] := TChannel.Create(SW1, dualRateDg, -100, curve00);
      tmpModel.channels[5] := TChannel.Create(SW5, throttleCut, -100, curve00);
      tmpModel.channels[6] := TChannel.Create(Pot1, aux01, 100, curve00);
      tmpModel.channels[7] := TChannel.Create(Pot2, aux02, 100, curve00);
    end;
  end;

  //retrieve all data and build a TModelData as a result
  tmpModel.computePhysicalChannels;
  Result := tmpModel;
end;

function getModelByName(_name: string; var tmpModel: TmodelData): TModelData;
var
  tmpIndex: byte;
  found: boolean;
begin
  //function which find the the name, when found in the ModelList array the current index is the exact position in the flash given by index*ModelSize
  found := False;
  Result := nil;
  ModelList := getModelList; //get Model list names
  for tmpIndex := 0 to MAX_MODELS - 1 do      //search for it
  begin
    if ModelList[tmpIndex] = _name then    // compare target name with each stored name
    begin
      found := True;                 //found!!
      break;                       //stop iteration
    end;
  end;
  //if found the name call getModelByIndex otherwise return Nil

  if found = True then
  begin
    Result := getModelbyIndex(tmpIndex, tmpModel);
  end;
end;

procedure getCalData;
begin

  //calib_data : array[LVStick..VBatt, calMin..calMax] of word = (
  //          (50 , 512, 890),   //LVStick  //PA0
  calib_data[LVStick, calMin] := $AD;
  calib_data[LVStick, calMid] := $1DD;
  calib_data[LVStick, calMax] := $31F;
  //          (0 , 512, 1023),   //LHStick    PA1
  calib_data[LHStick, calMin] := $89;
  calib_data[LHStick, calMid] := $1DD;
  calib_data[LHStick, calMax] := $36F;
  //          (0 , 512, 1023),   //RVStick    PA2
  calib_data[RVStick, calMin] := $B6;
  calib_data[RVStick, calMid] := $1F8;
  calib_data[RVStick, calMax] := $320;
  //          (0 , 512, 1023),   //RHStick    PA3
  calib_data[RHStick, calMin] := $C2;
  calib_data[RHStick, calMid] := $230;
  calib_data[RHStick, calMax] := $398;
  //          (0 , 512, 1023),   //Pot1       PA4
  calib_data[Pot1, calMin] := 20;
  calib_data[Pot1, calMid] := 512;
  calib_data[Pot1, calMax] := 1000;
  //          (0 , 512, 1023),   //Pot2       Pa5
  calib_data[Pot2, calMin] := 20;
  calib_data[Pot2, calMid] := 512;
  calib_data[Pot2, calMax] := 1000;
  //          (0 , 512, 1023),   //Pot3       PA6
  //calib_data[Pot3,calMin]:=0;
  //calib_data[Pot3,calMid]:=512;
  //calib_data[Pot3,calMax]:=1023;
  //          (0 , 512, 1023));  //VBatt      PA7
  calib_data[VBatt, calMin] := 0;
  calib_data[VBatt, calMid] := 512;
  calib_data[VBatt, calMax] := 1023;

end;

procedure saveCalData;
begin

end;

end.