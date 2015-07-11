unit commontx;


interface

uses
  Arduino_compat, channelMixer, stm32f103fw;

const

  //  FLAG_NONE = $00;
  //  FLAG_BIND = $01;
  //  FLAG_FLIP = $02;
  //  FLAG_LIGHT = $03;
  //  FLAG_VIDEO = $04;
  //  FLAG_CAMERA = $05;
  basesamples = 9;
  samples = 200;
  FUNCTION_DISABLED = 2000;
  MAX_CHANNELS = 15;

type

  { TCommonTX }

  TDualRate = (
    dualRateAnalog,
    dualRateDigital,
    dualRateDisabled);

  TProtocol = (
    V2x2Prot,
    BRADProt,
    YD717Prot,
    CX10AProt,
    PPM_P_Prot,
    PPM_Ext8_Prot,
    PPM_Ext10_Prot,
    PPM_N_Prot,
    FMSProt,
    FSkyProt,
    FS_Bind);


  TCalibData = (CalMin, calMid, calMax);

  TInputs = (
    LVStick,       //PA0
    LHStick,       //PA1
    RVStick,       //PA2
    RHStick,       //PA3
    Pot1,          //PA4
    Pot2,          //PA5
    Pot3,          //PA6
    Pot4,          //PA7
    VBatt,         //PB0
    //till there all analog input so less than or equal VBatt means analog
    SW0,           //PC14
    SW1,           //PB10
    SW2,           //PB11
    SW3,           //PB1
    SW4,           //PC15
    SW5,           //PC13
    SW6,           //PA12
    None            //Not Connected to any pin
    );

  {
    digitalRead(PC14)=HIGH then
      sw1:=0;
   tmpstr:=tmpstr+hexstr(sw1,3)+' ';

   if digitalRead(PB10)=HIGH then
      sw2:=0;
   tmpstr:=tmpstr+hexstr(sw2,3)+' ';

   if digitalRead(PB11)=HIGH then
      sw3:=0;
   tmpstr:=tmpstr+hexstr(sw3,3)+' ';

   if digitalRead(PB1)=HIGH then
      sw4:=0;
   tmpstr:=tmpstr+hexstr(sw4,3)+' ';

   if digitalRead(PC15)=HIGH then
      sw5:=0;
   tmpstr:=tmpstr+hexstr(sw5,3)+' ';

   if digitalRead(PC13)=HIGH then
      sw6:=0;
   tmpstr:=tmpstr+hexstr(sw6,3)+' ';

   bat0:=analogRead(PB0);
   bat0:=bat0*825 div 1023;
   tmpstr:=tmpstr+hexstr(bat0,3);


  }


  TTypeInput = (
    disabledInput,
    analogInput,
    digitalInput
    );

  TChannelOutput = (
    Channel01,
    Channel02,
    Channel03,
    Channel04,
    Channel05,
    Channel06,
    Channel07,
    Channel08,
    Channel09,
    Channel10
    );




  TFunctions = (
    throttle,
    rudder,   //yaw
    aileron,  //roll
    elevator, //pitch
    aux01,
    aux01Mid,
    aux02,
    aux02Mid,
    aux03,
    aux03Mid,
    aux04,
    aux04Mid,
    aux05,
    aux05Mid,
    aux06,
    aux06Mid,
    dualRateAn,
    dualRateDg,
    throttleCut,
    acroOn,
    cameraOn,
    videoOn,
    lightOn,
    headlessOn,
    returntohomeOn,
    disabledFunction
    );

  TFuncArray = array[throttle..disabledFunction] of word;




  { TChannel }

  TChannel = class
  private

  public
    defaultGain: byte;  //0-100 for DualRate
    gain: shortint;
    Value: word;
    curve: expoCurve;  //maybe a set?
    inverted: boolean; //False means original value, True means reversed
    dualRate: TDualRate;
    chDual: boolean; //True if standby is at center, False id standby is at zero.
    input: TInputs; //input pins to read;
    action: TFunctions; //maybe set of function output?
    inputType: TTypeInput;
    function getChannelValue: word;
    constructor Create(_input: TInputs; _action: TFunctions;
      _defaultGain: integer; _curve: expoCurve);
    constructor Create;
    destructor Destroy; override;
  end;




  { TModelData }

  TModelData = class
  private

  public
    Name: string;
    protocol: TProtocol;
    numchannels: byte;
    channels: array[0..MAX_CHANNELS - 1] of TChannel; //8 channels to start with
    ppm_period: word;
    ppm_lastdelay: word;
    ppm_pause: word;
    ppm_min: word;
    ppm_max: word;
    ppm_index: word;
    ppm_positive: boolean;
    ppm_numChannels: byte;
    serialBaudRate: longword;
    frame: TFuncArray;
    function computePhysicalChannels: word;
    function getChannelbyFunction(_func: TFunctions): byte;
    procedure computeFrame;
    constructor Create;
    destructor Destroy; override;


  end;

  TCommonTX = class
  public
    timeCycle: byte;
    Name: string;
    txid: array [0..4] of longword;
    procedure bind; dynamic;
    procedure unbind; dynamic;
    procedure command(model: TModelData); dynamic;
    constructor Create;
    destructor Destroy; override;

  end;



//function convertChannel(min_, mid_, max_, Value: word): word;


procedure setADC_DMA;

var
  //this array associates the input pins to a named value i.e. LVStick is PA0
  input_pin: array[LVStick..SW6] of
  board_pins = (PA0, PA1, PA2, PA3, PA4, PA5, PA6, PA7, PB0,    //analog inputs
    PC14, PB10, PB11, PB1, PC15, PC13, PA12);
  //digital inputs

  //  ADC_values : array[1..40] of word;
  adValues: array [0..samples * basesamples - 1] of word;
  adValuesGood: array [LVStick..VBatt] of longword;
  //these are values used to calibrate the analog inputs
  //calMin is the value read at minimum position
  //calMid is the center of pot/Stick
  //calMax is the maximum position
  calib_data: array[LVStick..VBatt, calMin..calMax] of word;

implementation




{ TModelData }

function TModelData.computePhysicalChannels: word;
var
  i: word;
begin
  numChannels := 0;
  for i := 0 to MAX_CHANNELS - 1 do
  begin
    if channels[i] <> nil then
    begin
      if channels[i].action < aux06Mid then
      begin
        //ok here we are in a valid
        Inc(numChannels);
      end;
    end;
  end;
  if numChannels > MAX_CHANNELS then
  begin
    numChannels := MAX_CHANNELS;
  end;
  Result := numChannels;
end;

function TModelData.getChannelbyFunction(_func: TFunctions): byte;
var
  i: byte;
begin
  for i := 0 to MAX_CHANNELS - 1 do
  begin
    if channels[i] <> nil then
    begin
      if channels[i].action = _func then
      begin
        Result := i;
      end;
    end;
  end;
end;

procedure TModelData.computeFrame;
var
  i: byte;
  t: TFunctions;
  tmpFrame: TFuncArray;
begin
  //read all channels and fill frame data in the right order
  //be careful this will be called inside a timer interrupt
  for t := throttle to disabledFunction do
  begin
    tmpFrame[t] := FUNCTION_DISABLED;
  end;
  for i := 0 to MAX_CHANNELS - 1 do
  begin
    if channels[i] <> nil then
    begin
      case channels[i].action of
        //retrieve standard 4 channel values
        throttle:
        begin
          tmpframe[throttle] := channels[i].getChannelValue;
        end;
        aileron:
        begin
          tmpframe[aileron] := channels[i].getChannelValue;
        end;
        rudder:
        begin
          tmpframe[rudder] := channels[i].getChannelValue;
        end;
        elevator:
        begin
          tmpframe[elevator] := channels[i].getChannelValue;
        end;
        //ok let's try to understand what to do with all other channels
        aux01:
        begin
          tmpframe[aux01] := channels[i].getChannelValue;
        end;
        aux01Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux01] = 0 then
            begin
              tmpframe[aux01] := 512;
            end;
          end;
        end;
        aux02:
        begin
          tmpframe[aux02] := channels[i].getChannelValue;
        end;
        aux02Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux02] = 0 then
            begin
              tmpframe[aux02] := 512;
            end;
          end;
        end;
        aux03:
        begin
          tmpframe[aux03] := channels[i].getChannelValue;
        end;
        aux03Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux03] = 0 then
            begin
              tmpframe[aux03] := 512;
            end;
          end;
        end;
        aux04:
        begin
          tmpframe[aux04] := channels[i].getChannelValue;
        end;
        aux04Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux04] = 0 then
            begin
              tmpframe[aux04] := 512;
            end;
          end;
        end;
        aux05:
        begin
          tmpframe[aux05] := channels[i].getChannelValue;
        end;
        aux05Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux05] = 0 then
            begin
              tmpframe[aux05] := 512;
            end;
          end;
        end;
        aux06:
        begin
          tmpframe[aux06] := channels[i].getChannelValue;
        end;
        aux06Mid:
        begin
          if channels[i].getChannelValue > 0 then
          begin
            if tmpframe[aux06] = 0 then
            begin
              tmpframe[aux06] := 512;
            end;
          end;
        end;
        dualRateAn:
        begin
          tmpframe[dualRateAn] := channels[i].getChannelValue;
        end;
        dualRateDg:
        begin
          tmpframe[dualRateDg] := channels[i].getChannelValue;
        end;
        throttleCut:
        begin
          tmpframe[throttleCut] := channels[i].getChannelValue;
        end;
        acroOn:
        begin
          tmpframe[acroOn] := channels[i].getChannelValue;
          if tmpFrame[acroOn] = 1023 then
          begin
            tmpFrame[dualRateDg] := 1023;
          end;
        end;
        cameraOn:
        begin
          tmpframe[cameraOn] := channels[i].getChannelValue;
        end;
        videoOn:
        begin
          tmpframe[videoOn] := channels[i].getChannelValue;
        end;
        lightOn:
        begin
          tmpframe[lightOn] := channels[i].getChannelValue;
        end;
        headlessOn:
        begin
          tmpframe[headlessOn] := channels[i].getChannelValue;
        end;
        returnToHomeOn:
        begin
          tmpframe[returnToHomeOn] := channels[i].getChannelValue;
        end;
      end;
    end;

  end;
  //solve here some common tasks like throttle cut
  if ((tmpFrame[throttleCut] <> FUNCTION_DISABLED) and (tmpFrame[throttleCut] > 0)) then
  begin
    tmpFrame[throttle] := 0;
  end;
  // fix here the dualRate?
  if ((tmpFrame[dualRateAn] <> FUNCTION_DISABLED) or
    (tmpFrame[dualRateDg] <> FUNCTION_DISABLED)) then
  begin
    for i := 0 to numchannels - 1 do
    begin
      channels[i].gain := channels[i].defaultGain;
      case channels[i].dualRate of
        dualRateAnalog:
        begin
          if tmpFrame[dualRateAn] <> FUNCTION_DISABLED then
          begin
            channels[i].gain := map(tmpFrame[dualRateAn], 0, 1023, 20, 100);
          end;  //minimum dualrate analog gain 20%
        end;
        dualRateDigital:
        begin
          if tmpFrame[dualRateDg] <> FUNCTION_DISABLED then
          begin
            if tmpFrame[dualRateDg] > 0 then
            begin
              channels[i].gain := 100;
            end;
          end;
        end;
      end;
    end;
  end;
  frame := tmpFrame;
end;

constructor TModelData.Create;
begin
  self.Name := 'BaseModel';
  self.ppm_max := 2000;
  self.ppm_positive := True;
  self.ppm_min := 1000;
  self.ppm_pause := 400;
  self.ppm_period := 22500;
  self.ppm_index := 1;
  self.protocol := PPM_P_Prot;
  self.serialBaudRate := 19200;
  // create base skeleton for channels
  //TChannel.Create(_input: TInputs; _inputType: TTypeInput;
  //         _action: TFunctions; _chDual: boolean; _gain: byte; _inverted: boolean;
  //         _curve: expoCurve);

  //AETR Scheme
  //self.channels[0]:=TChannel.Create(RHStick, aileron   ,  100,curve00Dual); //1st channel is aileron Right Stick Horizontal
  //self.channels[1]:=TChannel.Create(RVStick, elevator  ,  100, curve01Dual);
  //self.channels[2]:=TChannel.Create(LVStick, throttle  ,  100,curve00);
  //self.channels[3]:=TChannel.Create(LHStick, rudder    ,  -100, curve00Dual);
  //self.channels[4]:=TChannel.Create(SW4    , videoOn   ,  100, curve00);
  //self.channels[5]:=TChannel.Create(SW5    , headlessOn,  100, curve00);
  //self.channels[6]:=TChannel.Create(SW6    , acroOn    ,  100, curve00);
  //self.channels[7]:=TChannel.Create(Pot1   , DualRateAn,  100, curve00);
  //computePhysicalChannels;
end;

destructor TModelData.Destroy;
begin
  inherited Destroy;
end;



{ TChannel }

function TChannel.getChannelValue: word;   //0-1023 value
var
  tmpValue: word;
begin
  tmpValue := FUNCTION_DISABLED;
  if inputType <> disabledInput then
  begin
    case inputType of
      analogInput:
      begin
        // tmpValue:=analogRead(input_pin[self.input]);   //modify this to read the values from DMA transfer
        tmpValue := adValuesGood[self.input];
        //here I have to apply calibration
        tmpValue :=
          constrain(tmpValue, calib_data[input, calMin], calib_data[input, calMax]);
        if tmpValue < calib_data[input, calMid] then
        begin
          tmpValue := map(tmpValue, calib_data[input, calMin], calib_data[input, calMid], 0, 511);
        end
        else
        begin
          tmpValue := map(tmpValue, calib_data[input, calMid], calib_data[input, calMax], 512, 1023);
        end;

        //here apply simple mixer
        tmpValue := applyExpo(tmpValue, chDual, curve);
        if dualRate <> dualRateDisabled then
        begin
          tmpValue := applyDualRate(tmpValue, chDual, Gain);
        end;
        tmpValue := invertChannel(tmpValue, inverted);
      end;
      digitalInput:
      begin
        tmpValue := digitalRead(input_pin[self.input]);
        if tmpValue <> 0 then
        begin
          tmpValue := 1023;
        end;
        tmpValue := invertChannel(tmpValue, inverted);
      end;
      else
      begin
        tmpValue := FUNCTION_DISABLED;
      end;

    end;
  end;
  self.Value := tmpValue;
  Result := tmpValue;
end;

constructor TChannel.Create(_input: TInputs; _action: TFunctions;
  _defaultGain: integer; _curve: expoCurve);
begin
  input := _input;
  if input <= VBatt then
  begin
    inputType := analogInput;
  end
  else
  begin
    inputType := digitalInput;
  end;
  if input = None then
  begin
    inputType := disabledInput;
  end;
  action := _action;

  defaultGain := abs(_defaultGain);
  if _defaultGain < 0 then
  begin
    inverted := True;
  end
  else
  begin
    inverted := False;
  end;
  case defaultGain of
    1:
    begin
      dualRate := dualRateAnalog;
    end;
    100:
    begin
      dualRate := dualRateDisabled;
    end;
    else
    begin
      dualRate := dualRateDigital;
    end;
  end;
  chDual := True;
  if ((_curve >= curve00) and (_curve < curve00Dual)) then
  begin
    chDual := False;
  end;
  curve := _curve;

end;

constructor TChannel.Create;
begin
  input := None;
  inputType := disabledInput;
  action := disabledFunction;
  chDual := False;
  gain := 100;
  inverted := False;
  curve := curve00;
end;

destructor TChannel.Destroy;
begin
  inherited Destroy;
end;


{ TCommonTX }

procedure TCommonTX.bind;
begin

end;

procedure TCommonTX.unbind;
begin

end;

procedure TCommonTX.command(model: TModelData);
begin

end;

constructor TCommonTX.Create;
begin

end;

destructor TCommonTX.Destroy;
begin
  inherited Destroy;
end;


procedure setADC_DMA;
var
  ADC_InitStructure: TADC_InitTypeDef;
  DMA_InitStructure: TDMA_InitTypeDef;
  NVIC_InitStructure: TNVIC_InitTypeDef;
begin

  RCC_ADCCLKConfig(RCC_PCLK2_Div8);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1, Enabled);

  ADC_InitStructure.ADC_Mode := ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode := Enabled; // Single Channel
  ADC_InitStructure.ADC_ContinuousConvMode := Enabled; // Scan on Demand
  ADC_InitStructure.ADC_ExternalTrigConv := ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign := ADC_DataAlign_Right;
  //I have to study a way to automatically manage the number of channel
  //involved, maybe an array of boolean?
  ADC_InitStructure.ADC_NbrOfChannel := 9;
  ADC_Init(ADC1, ADC_InitStructure);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_0, 1, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_1, 2, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_2, 3, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_3, 4, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_4, 5, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_5, 6, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_5, 7, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_7, 8, ADC_SampleTime_41Cycles5);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_8, 9, ADC_SampleTime_41Cycles5);
  ADC_Cmd(ADC1, Enabled);

  //enable DMA for ADC
  ADC_DMACmd(ADC1, Enabled);
  //Enable ADC1 reset calibration register
  ADC_ResetCalibration(ADC1);


  //Check the end of ADC1 reset calibration register
  while (ADC_GetResetCalibrationStatus(ADC1)) do
  begin
  end;
  //Start ADC1 calibration
  ADC_StartCalibration(ADC1);
  //Check the end of ADC1 calibration
  while (ADC_GetCalibrationStatus(ADC1)) do
  begin
  end;

  // ADC Finished, start with DMA configuration

  //enable DMA1 clock
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, Enabled);
  //create DMA structure

  //reset DMA1 channe1 to default values;
  DMA_DeInit(DMA1.Channel[0]);

  //channel will be used for memory to memory transfer
  DMA_InitStructure.DMA_M2M := DMA_M2M_Disable;
  //setting normal mode (non circular)
  DMA_InitStructure.DMA_Mode := DMA_Mode_Circular;
  //medium priority
  DMA_InitStructure.DMA_Priority := DMA_Priority_High;
  //source and destination data size word=32bit
  DMA_InitStructure.DMA_PeripheralDataSize := DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize := DMA_MemoryDataSize_HalfWord;
  //automatic memory destination increment enable.
  DMA_InitStructure.DMA_MemoryInc := DMA_MemoryInc_Enable;
  //source address increment disable
  DMA_InitStructure.DMA_PeripheralInc := DMA_PeripheralInc_Disable;
  //Location assigned to peripheral register will be source
  DMA_InitStructure.DMA_DIR := DMA_DIR_PeripheralSRC;
  //chunk of data to be transfered
  DMA_InitStructure.DMA_BufferSize := samples * basesamples;
  //source and destination start addresses
  DMA_InitStructure.DMA_PeripheralBaseAddr := @ADC1.DR;
  DMA_InitStructure.DMA_MemoryBaseAddr := @ADvalues;
  //send values to DMA registers
  DMA_Init(DMA1.Channel[0], DMA_InitStructure);
  // Enable DMA1 Channel Transfer Complete interrupt

  //    DMA_Cmd(DMA1.Channel[0], ENABLED); //Enable the DMA1 - Channel1

{    //Enable DMA1 channel IRQ Channel */
    NVIC_InitStructure.NVIC_IRQChannel := DMAChannel1_IRQChannel;
    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority := 1;
    NVIC_InitStructure.NVIC_IRQChannelSubPriority := 1;
    NVIC_InitStructure.NVIC_IRQChannelCmd := ENABLED;
    NVIC_Init(NVIC_InitStructure);
 }
  DMA_Cmd(DMA1.Channel[0], Enabled);
  //Start ADC1 Software Conversion
  ADC_SoftwareStartConvCmd(ADC1, Enabled);

end;


end.
