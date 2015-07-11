unit main;

interface

uses
  stm32f103fw, interrupts, Arduino_compat, HWSerial, V2X2out, yd717out, cx10_a,
  ppmout,flysout, nrf24l01, ssd1306SPI,commontx, HWTimer, channelMixer, ModelManager;

procedure setup;
procedure loop;

function readButtons:boolean;
procedure setupMenu;
procedure printStatusBar(_str:string);
procedure printProgressBar(_str:string);
//procedure testReadAnalog;



const
  refresh_time = 40;
  buttonPinUp = 1;
  buttonPinDown = 2;
  buttonPinEnter = 3;
  buttonpinBack = 4;
  buttonPinNone = 0;


  V2X2_PROT=0;
  CX10_PROT=1;
  X39_PROT=2;
  PPMOUTP_PROT=3;
  PPMOUTN_PROT=4;
  FMSOUT_PROT=5;
  FLYSKY_PROT=6;
  BRAD_PROT=7;
 // CALIBRATION=MENU_SIZE;


var

  mytx: TCommonTX;
  currentModel  :TModelData;
  myTimer2 : TTimer_STM32;
 // NokiaLCD: TNokia1100LCD;
  NokiaLCD : Adafruit_SSD1306;


//  ciaobello :longint = 0;
//  ciaobello1 : longint = 0;
  lastMillis: int64 = 0;

//  menu_button : byte;
  menu_lastbutton : byte;
  menu_index : byte;
  MENU_SIZE : byte;

//  tmpflag:boolean=true;
//  counter1,counter2:word;


implementation




procedure TIM2_global_interrupt; [public, alias: 'TIM2_global_interrupt'];
//timer interrupt function which reads the channel inputs

begin
   if (TIM_GetITStatus(Timer2, TIM_IT_Update) <> False) then
    begin
        TIM_ClearITPendingBit(Timer2, TIM_IT_Update);
     //   testReadAnalog;
        currentModel.computeFrame;      //retrieve all channels and function data
        mytx.command(currentModel);     //send packet or update
    end;
 //  Serial1.println('Timer2');
end;


procedure TIM4_global_interrupt; [public, alias: 'TIM4_global_interrupt'];
begin
if (TIM_GetITStatus(Timer4, TIM_IT_CC3) <> False) then
   begin
      TIM_ClearITPendingBit(Timer4, TIM_IT_CC3);
      if currentModel.ppm_index>=8 then
         begin
         //   DMA_Cmd(DMA1.Channel[0], ENABLED);
            currentModel.ppm_index:=1;
            Timer4.CCR3:=currentModel.ppm_pause;
	 end;
      Timer4.ARR:=ppmout_values[currentModel.ppm_index]+currentModel.ppm_pause;
      if Timer4.ARR<100 then
        Timer4.ARR:=2300;
      inc(currentModel.ppm_index);
   end;
//Serial1.println(decStr(Timer4.ARR,5));
end;


procedure DMA1_Channel1_global_interrupt; [public, alias: 'DMA1_Channel1_global_interrupt'];
var
  i : TInputs;
  a :word;
begin
   if(DMA_GetITStatus(DMA1_IT_TC1)) then
     begin
       for i := LVStick to Vbatt do
           begin
              adValuesGood[i]:=0;
              for a:=0 to samples -1 do
                begin
                   advaluesgood[i]:=adValuesGood[i]+adValues[ord(i)+(basesamples*a)];
		end;
             advaluesgood[i]:=(adValuesGood[i] div samples) shr 2; //values 10bit 0-1023
	   end;
       DMA_ClearITPendingBit(DMA1_IT_GL1);
     end;

end;



procedure setup;
var
  indexList, i, tmpValue:integer;
  modelList :TModelList;


begin
  //Create or initialize variables and objects
  //heapsize is adjusted in the .lpr file
 // counter1:=0;
///  counter2:=0;
  pinMode(PA0, INPUT_ANALOG);    //LVStick
  pinMode(PA1, INPUT_ANALOG);    //LHStick
  pinMode(PA2, INPUT_ANALOG);    //RVStick
  pinMode(PA3, INPUT_ANALOG);    //RHStick
  pinMode(PA4, INPUT_ANALOG);    //Pot1
  pinMode(PA5, INPUT_ANALOG);    //Pot2
  pinMode(PA6, INPUT_ANALOG);    //Free
  pinMode(PA7, INPUT_ANALOG);    //Free
  pinMode(PB0, INPUT_ANALOG);    //VBatt
  pinMode(PC13,INPUT_PULLUP);           //SW0
  pinMode(PC14,INPUT_PULLUP);           //SW1
  pinMode(PC15,INPUT_PULLUP);           //SW2
  pinMode(PB1, INPUT_PULLUP);           //SW3
  pinMode(PB10,INPUT_PULLUP);           //SW4
  pinMode(PB11,INPUT_PULLUP);           //SW5
  pinMode(PA12,INPUT_PULLUP);           //SW6
  pinMode(PB4,OUTPUT);           //??
  NokiaLCD := Adafruit_SSD1306.create(PB6,PB7,PA11 ,NC);// PA12 ex CS;
//  Adafruit_SSD1306.Create(_sid: board_pins; _sclk: board_pins; _dc: board_pins; _cs: board_pins);

 delay(200);
 NokiaLCD._begin(SSD1306_SWITCHCAPVCC,0,false);
 NokiaLCD.setRotation(ROTATION000DEG);
 delay(200);
 NokiaLcd.clearDisplay;
 NokiaLcd.display;
 getCalData;
 modelList:=getModelList;
 menu_size:=MAX_MODELS-1;
 menu_index:=9;
 printStatusBar(modelList[menu_index]);
  //Create Serial Object
 //Serial1:=TSTM32serial.Create(USART1,115200);
 while readButtons <> true do //until enter has been pressed
     begin
       printStatusBar(modelList[menu_index]);
       delay_ms(250);
     end;

 getModelbyName(modelList[menu_index], currentModel);

 case currentModel.protocol of
          FSkyProt : begin
                       mytx:= FLYSOUT_TX.Create(currentModel.serialBaudRate);

	             end;
	  FS_Bind :  begin
                         // it should use a single digital output to close bind button
                         // and remove/give the power to the rf module
                     end;
	  PPM_P_Prot :      begin
                         mytx := TPPMOUT_TX.Create(True);
                 	  end;
          PPM_Ext8_Prot :    begin
                         mytx := TPPMOUT_TX.Create(False,ext08);
                 	  end;
          PPM_Ext10_Prot :    begin
                         mytx := TPPMOUT_TX.Create(False,ext10);
                          end;
	  PPM_N_Prot :    begin
                         mytx := TPPMOUT_TX.Create(False);
                           end;
          V2X2Prot :  begin
                         mytx := TV2X2OUT_TX.Create;
                      end;
          CX10AProt :  begin
                         mytx := TCX10_AOUT.Create;
                       end;
          BRADProt :  begin
                         mytx := TV2X2OUT_TX.Create($20);//NRF24L01_BR_250K
                      end;
	  YD717Prot : begin
                        mytx := TYD717OUT_TX.Create;
                      end;
 end;

currentModel.computeFrame;
 tmpValue:=1;
//check here if throttle is low
  while (tmpValue <> 0) do
      begin
         //wait and write to LCD to set Throttle low
        printProgressBar('Set Throttle LOW');
        adValuesGood[currentModel.channels[currentModel.getChannelbyFunction(throttle)].input]:=analogRead(input_pin[currentModel.channels[currentModel.getChannelbyFunction(throttle)].input]);
        tmpValue:=currentModel.channels[currentModel.getChannelbyFunction(throttle)].getChannelValue;
      end;

  printProgressBar('Bind in Progress');
  mytx.bind;
  delay_ms(500);
  printProgressBar('     Bound!     ');

  currentModel.ppm_index:=1;
  sysTimer2:=TTImer_STM32.Create(Timer2,enabled);
  sysTimer2.setIntervalus(mytx.timeCycle*500);
  sysTimer2.start;
  setADC_DMA;
  setup_interrupts;

end;

//==============================================================================
procedure loop;
var
  myFrameStr : array[throttle..disabledFunction] of string[5];
  curMillis: int64;
  i : TFunctions;
begin
	  curMillis := millis;
          for i:=throttle to returntohomeOn do
              begin
                 if currentModel.frame[i]=FUNCTION_DISABLED then
                   myFrameStr[i]:='--'
                   else
                   myFrameStr[i]:=hexstr(currentModel.frame[i] shr 2,2);
	      end;
          printstatusbar(currentModel.name);
      //    printprogressBar('VBatt='+decStr(adValuesGood[VBatt]*4 div 51,2)+'     ');
          NokiaLCD.setCursor(75,0);
          NokiaLCD.setTextSize(2);
          Nokialcd.print(decStr(adValuesGood[VBatt]*4 div 49,2)+'dV');//*4 div 51,2)+'dV');
          NokiaLCD.setCursor(0,24);
          Nokialcd.print('Ai'+hexstr(currentModel.frame[aileron] shr 2,2)+' ',1);
          Nokialcd.print('El'+myFrameStr[elevator]+' ',1);
          Nokialcd.print('Th'+myFrameStr[throttle]+' ',1);
          Nokialcd.println('Rd'+myFrameStr[rudder],1);
          NokiaLCD.print('X1'+myFrameStr[aux01]+' ',1);
          NokiaLCD.print('X2'+myFrameStr[aux02]+' ',1);
          NokiaLCD.print('X3'+myFrameStr[aux03]+' ',1);
          NokiaLCD.println('X4'+myFrameStr[aux04],1);
          NokiaLCD.print('X5'+myFrameStr[aux05]+' ',1);
          NokiaLCD.println('X6'+myFrameStr[aux06],1);
          NokiaLCD.print('TC'+myFrameStr[throttleCut]+' ',1);
          NokiaLCD.print('DR'+myFrameStr[DualRateDg]+' ',1);
          NokiaLCD.print('AC'+myFrameStr[acroOn]+' ',1);
          NokiaLCD.println('VD'+myFrameStr[videoOn],1);
          NokiaLCD.print('CM'+myFrameStr[cameraOn]+' ',1);
          NokiaLCD.print('LG'+myFrameStr[lightOn]+' ',1);
          NokiaLCD.print('HL'+myFrameStr[headlessOn]+' ',1);
          NokiaLCD.println('RH'+myFrameStr[returntohomeOn],1);

          NokiaLCD.display;
 	  while ((millis - curMillis) <= refresh_time) do ;    //repeat loop every 40msec -> 25Hz refresh rate
          lastMillis := curMillis;
end;

function readButtons:boolean;
var
  tmpvalue: word;
  menu_button:byte;
begin
 //replace with analog sticks position
   //  NokiaLcd.lcdGotoyx(3,0);
  result:=False;
  tmpvalue:=analogRead8bit(input_pin[RVStick]);  //adjust to the elevator stick
  menu_button:=buttonPinNone;
  if tmpvalue<100 then
        menu_button:=buttonPinDown;
  if tmpvalue> 160 then
        menu_button:=buttonPinUp;
  tmpvalue:=analogRead8bit(input_pin[RHStick]);  //adjust to aileron stick
   if tmpvalue<100 then
        menu_button:=buttonPinBack;
  tmpvalue:=digitalread(input_pin[SW0]);
  if tmpvalue=LOW then
        menu_button:=buttonPinEnter;

  if (menu_button<>menu_lastButton) and (menu_button <> buttonPinNone) then
       begin
           case menu_button of
            buttonPinDown  :  begin
                            if (menu_Index < MENU_SIZE) then
                               inc(menu_Index)
                            else if (menu_Index = MENU_SIZE) then
                               menu_Index:=0;
	                        end;
	    buttonPinUp    : begin
                            if (menu_Index > 0) then
                               dec(menu_Index)
                             else if (menu_Index = 0) then
                               menu_Index:=MENU_SIZE;
                             end;
	    buttonPinEnter : begin
                              Result:=true;
                             end;
            end;
       end;
   menu_lastButton:=menu_button;
end;

procedure setupMenu;
begin

end;

procedure printStatusBar(_str: string);
begin
          if NokiaLCD<>Nil then
            begin
                 NokiaLCD.setCursor(0,0);
                 NokiaLCD.print(_str,2);
                 NokiaLCD.display;
	    end;
end;

procedure printProgressBar(_str: string);
begin
          if NokiaLCD<>Nil then
            begin
                 NokiaLCD.setCursor(0,16);
                 NokiaLCD.print(_str,1);
                 NokiaLCD.display;
	    end;
end;


end.
