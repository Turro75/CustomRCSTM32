unit PPMOUT;

{$mode objfpc}

interface

uses
  Arduino_compat, commontx, HWTimer, stm32f103fw;

const
  PPMOUT_PIN = PA8;
  PPMPHIGH = HIGH;
  PPMPLOW = LOW;
  long = 2000;
  mid = 1500;
  short = 1000;
  pause = 300;

type
  triple_sync = (synclow, syncmid, synchigh);
  ext_mode = (extno, ext08, ext10);
  { TPPMOUT_TX }

  TPPMOUT_TX = class(TCommonTX)
  private
    ppmout_index: byte;
    extended: ext_mode;
  public
    outputPin: board_pins;
    ppmout_readvalues: array [1..17] of word;
    constructor Create(positive: boolean = True; _extended: ext_mode = extno;
      outpin: board_pins = PPMOUT_PIN);
    destructor Destroy; override;
    procedure bind; override;
    procedure unbind; override;
    procedure command(Model: TModelData); override;
  end;


var
  ppmout_values: array [1..MAX_CHANNELS * 2 + 1] of word;
  highvalue: byte;
  lowvalue: byte;
  chan_sync: triple_sync = synclow;
  multiplex: array[0..2, 0..1] of word;

implementation

{ TPPMOUT_TX }

constructor TPPMOUT_TX.Create(positive: boolean; _extended: ext_mode;
  outpin: board_pins);
var
  GPIO_InitStructure: TGPIO_InitTypeDef;
  NVIC_InitStructure: TNVIC_InitTypeDef;
  TIM_TimeBaseStructure: TIM_TimeBaseInitTypeDef;
  TIM_OCInitStructure: TIM_OCInitTypeDef;
begin
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB or RCC_APB2Periph_AFIO, Enabled);

  GPIO_InitStructure.GPIO_Mode := GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed := GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Pin := GPIO_Pin_8;
  GPIO_Init(PortB, GPIO_InitStructure);

  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM4, Enabled);

  NVIC_InitStructure.NVIC_IRQChannel := TIM4_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority := 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority := 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd := Enabled;
  NVIC_Init(NVIC_InitStructure);

  TIM_TimeBaseStructure.TIM_Period := long + pause;
  TIM_TimeBaseStructure.TIM_Prescaler := (72000000 div 1000000) - 1;
  TIM_TimeBaseStructure.TIM_ClockDivision := 0;
  TIM_TimeBaseStructure.TIM_CounterMode := TIM_CounterMode_Up;

  TIM_TimeBaseInit(Timer4, TIM_TimeBaseStructure);

  TIM_OCInitStructure.TIM_OCMode := TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState := TIM_OutputState_enable;
  TIM_OCInitStructure.TIM_Pulse := pause;
  TIM_OCInitStructure.TIM_OCPolarity := TIM_OCPolarity_low;
  TIM_OC3Init(Timer4, TIM_OCInitStructure);
  TIM_OC3PreloadConfig(Timer4, TIM_OCPreload_Enable);

  TIM_ARRPreloadConfig(Timer4, Enabled);
  TIM_Cmd(Timer4, Enabled);
  TIM_ITConfig(Timer4, TIM_IT_CC3, Enabled);
  extended := _extended;
  timeCycle := 37;
  if positive = True then
  begin
    // Name:= 'PPM+';
    highValue := HIGH;
    lowvalue := LOW;
  end
  else
  begin
    //  Name:= 'PPM-';
    highValue := LOW;
    lowvalue := HIGH;
  end;
  // digitalWrite(outputPin, highvalue);
end;

destructor TPPMOUT_TX.Destroy;
begin
  if sysTimer1 <> nil then
  begin
    sysTimer1.Free;
  end;
  inherited Destroy;
end;

procedure TPPMOUT_TX.bind;
begin
  // inherited bind;
  //probably left empty
end;

procedure TPPMOUT_TX.unbind;
begin
  inherited unbind;
end;

procedure TPPMOUT_TX.command(Model: TModelData);
var
  i: byte;
begin
  for i := 1 to 7 do
  begin
    ppmout_values[i] := FUNCTION_DISABLED;
  end;

  ppmout_values[1] := map(Model.frame[aileron], 0, 1023, Model.ppm_min, Model.ppm_max);
  ppmout_values[2] := map(Model.frame[elevator], 0, 1023, Model.ppm_min, Model.ppm_max);
  ppmout_values[3] := map(Model.frame[throttle], 0, 1023, Model.ppm_min, Model.ppm_max);
  ppmout_values[4] := map(Model.frame[rudder], 0, 1023, Model.ppm_min, Model.ppm_max);

  case extended of
    extno:
    begin
      ppmout_values[5] :=
        map(Model.frame[aux01], 0, 1023, Model.ppm_min, Model.ppm_max);
      ppmout_values[6] :=
        map(Model.frame[aux02], 0, 1023, Model.ppm_min, Model.ppm_max);
    end;
    ext08:
    begin
      case chan_sync of
        synclow:
        begin
          ppmout_values[5] :=
            Model.ppm_min + (Model.frame[aux01] shr 2); //convert from 0-1023 to 0-255
          ppmout_values[6] :=
            Model.ppm_min + (Model.frame[aux03] shr 2);
          chan_sync := syncmid;
        end;
        syncmid:
        begin
          ppmout_values[5] :=
            Model.ppm_max - 255 + (Model.frame[aux02] shr 2); //convert from 0-1023 to 0-255
          ppmout_values[6] :=
            Model.ppm_max - 255 + (Model.frame[aux04] shr 2);
          chan_sync := synclow;
        end;
      end;
    end;
    ext10:
    begin
      case chan_sync of
        synclow:
        begin
          ppmout_values[5] :=
            Model.ppm_min + (Model.frame[aux01] shr 2); //convert from 0-1023 to 0-255
          ppmout_values[6] :=
            Model.ppm_min + (Model.frame[aux04] shr 2);
          chan_sync := syncmid;
        end;
        syncmid:
        begin
          ppmout_values[5] :=
            Model.ppm_min + ((Model.ppm_max - Model.ppm_min) div 2) - 127 + (Model.frame[aux02] shr 2);
          //convert from 0-1023 to 0-255
          ppmout_values[6] :=
            Model.ppm_min + ((Model.ppm_max - Model.ppm_min) div 2) - 127 + (Model.frame[aux05] shr 2);
          chan_sync := synchigh;
        end;
        synchigh:
        begin
          ppmout_values[5] :=
            Model.ppm_max - 255 + (Model.frame[aux03] shr 2); //convert from 0-1023 to 0-255
          ppmout_values[6] :=
            Model.ppm_max - 255 + (Model.frame[aux06] shr 2);
          chan_sync := synclow;
        end;
      end;
    end;
  end;

  Model.ppm_lastdelay := 0;
  for i := 1 to 6 do
  begin
    Model.ppm_lastdelay := Model.ppm_lastdelay + ppmout_values[i] + Model.ppm_pause;
  end;

  Model.ppm_lastdelay := Model.ppm_period - Model.ppm_lastdelay - Model.ppm_pause;
  ppmout_values[7] := Model.ppm_lastdelay;
  Model.ppm_numChannels := 6;

end;


end.
