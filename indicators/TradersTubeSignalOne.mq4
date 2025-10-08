//------------------------------------------------------------------
#property copyright "Copyright 2023 TradersTube (Rza Asadov)"
#property link      "https://traders-tube.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 36



#include "../Include/libs/Mql/Collection/HashMap.mqh"
#include "../Include/libs/Mql/Collection/LinkedList.mqh"
#include "../Include/libs/Mql/Format/Json.mqh"
#include "../Include/libs/hash.mqh"
#include "../Include/libs/json.mqh"
#include "../Include/libs/JAson.mqh"
#include "../Include/TradersTube/core/JsonOperations.mqh"
#include "../Include/TradersTube/core/Common.mqh"
#include "../Include/TradersTube/core/log.mqh"
#include "../Include/TradersTube/extensions/ServerConnector.mqh"
#include "../Include/TradersTube/core/CandleData.mqh"
#include "../Include/TradersTube/core/IndicatorData.mqh"
#include "../Include/TradersTube/extensions/CandleHighlighter.mqh"
#include "../Include/TradersTube/ind/InitIndicator.mqh"



#property strict


extern string server_key = "";
extern string Server_Host = "api-ea-v1.traders-tube.com";
extern int ServerFailTriesToReport = 10;
extern int ServerRequestTimeoutMs = 10000;
extern bool first_connection_to_server = true;
extern bool silentMode = true;



bool isDebug = false;
extern bool take_screenshot = true;
extern int screenshot_interval = 2;

extern int BARS = 7000;

extern int ZLMA_LENGTH_SHORT = 0;
extern int ZLMA_APPLY_ON_SHORT = 0;
extern color DOWN_COLOR_SHORT = clrRed;
extern color UP_COLOR_SHORT = clrLimeGreen;

extern int ZLMA_LENGTH_LONG = -1;
extern int ZLMA_APPLY_ON_LONG = 0;
extern color DOWN_COLOR_LONG = clrOrange;
extern color UP_COLOR_LONG = clrSkyBlue;

extern int ZLMA_LENGTH_SLONG = -1;
extern int ZLMA_APPLY_ON_SLONG = 0;
extern color DOWN_COLOR_SLONG = clrYellow;
extern color UP_COLOR_SLONG = clrWhite;

extern int point_multiplier = 10;
extern bool Enable_Notifications = true;
extern bool Enable_MA_Notifications = true;
extern bool Draw_Arrows = true;
extern int CANDLE_LENGTH = 30;



int LAST_SG = 0;

int LAST_SG_PIPS = 0;

int LAST_DIRECTION_SG_SHORT = 0;
int LAST_DIRECTION_SG_LONG = 0;

int bars = BARS;

double LAST_SG_PRICE;
datetime LAST_SG_DATETIME;
int LAST_SG_SHIFT = bars;

int SG_BUY=1;
int SG_SELL=2;



double textPipsShift = 0.0;




           
HashMap<string,int>*symbol_pairs = new HashMap<string,int>();
HashMap<string,int>*timeframes_t = new HashMap<string,int>();

HashMap<string,string>*symbols_names_market = new HashMap<string,string>();
HashMap<string,string>*symbols_names_orig = new HashMap<string,string>();

int total_signals = 0;

int sym_digits;

IndicatorData shortData;
IndicatorData longData;
IndicatorData slongData;

double flat_array[13];


int OnInit() {



   ObjectsDeleteAll();   

   point_multiplier = getPointMultiplier(Symbol(),"0");

   sym_digits = (int)MarketInfo(Symbol(),MODE_DIGITS);


   IndicatorShortName("TradersTubeSignalOne");

   IndicatorBuffers(36);

   int bufferNum = 0;


   IndicatorDigits(sym_digits);


   shortData.arrowColorBuy = UP_COLOR_SHORT;
   shortData.arrowColorSell = DOWN_COLOR_SHORT;
   shortData.arrowTextColorBuy = UP_COLOR_SHORT;
   shortData.arrowTextColorSell = DOWN_COLOR_SHORT;
   shortData.up_line_color = UP_COLOR_SHORT; 
   shortData.down_line_color = DOWN_COLOR_SHORT;


   if (ZLMA_LENGTH_SHORT > 0) {
      shortData.Length = ZLMA_LENGTH_SHORT;
   } else if (ZLMA_LENGTH_SHORT == 0) {
      if (Period()==1) {
            shortData.Length = 60;
      } else if (Period()==5) {
            shortData.Length = 60;
      } else if (Period()==15) {
            shortData.Length = 60;
      } else if (Period()==30) {
            shortData.Length = 60;
      } else if (Period()==60) {
            shortData.Length = 60;
      } else if (Period()==240) {
            shortData.Length = 60;
      } else if (Period()==1440) {
            shortData.Length = 60;
      } else if (Period()==10080) {
            shortData.Length = 60;
      } else {
            MessageBox("Timeframe not supported");
            ChartIndicatorDelete(0,0,"TradersTubeSignalOne");
      }
   }

   if (ZLMA_LENGTH_SHORT > -1) {
      shortData.Price = ZLMA_APPLY_ON_SHORT;
      shortData.name = "shortdata";
      bufferNum = initIndicator(shortData,bufferNum);
   }



   bufferNum++;


   longData.arrowColorBuy = UP_COLOR_LONG;
   longData.arrowColorSell = DOWN_COLOR_LONG;
   longData.arrowTextColorBuy = UP_COLOR_LONG;
   longData.arrowTextColorSell = DOWN_COLOR_LONG;
   longData.up_line_color = UP_COLOR_LONG; 
   longData.down_line_color = DOWN_COLOR_LONG;

   if (ZLMA_LENGTH_LONG > 0) {
      longData.Length = ZLMA_LENGTH_LONG;
   } else if (ZLMA_APPLY_ON_LONG == 0) {
      if (Period()==1) {
            longData.Length = 300;
      }if (Period()==5) {
            longData.Length = 180;
      } else if (Period()==15) {
            longData.Length = 240;
      } else if (Period()==30) {
            longData.Length = 480;
      } else if (Period()==60) {
            longData.Length = 240;
      } else if (Period()==240) {
            longData.Length = 360;
      } else if (Period()==1440) {
            longData.Length = 300;
      } else if (Period()==10080) {
            longData.Length = 360;
      }
   }

   if (ZLMA_LENGTH_LONG > -1) {
      longData.Price = ZLMA_APPLY_ON_LONG;
      longData.name = "longdata";
      bufferNum = initIndicator(longData,bufferNum); 
   }


   bufferNum++;


   slongData.arrowColorBuy = UP_COLOR_SLONG;
   slongData.arrowColorSell = DOWN_COLOR_SLONG;
   slongData.arrowTextColorBuy = UP_COLOR_SLONG;
   slongData.arrowTextColorSell = DOWN_COLOR_SLONG;
   slongData.up_line_color = UP_COLOR_SLONG; 
   slongData.down_line_color = DOWN_COLOR_SLONG;

   if (ZLMA_LENGTH_SLONG > 0) {
      slongData.Length = ZLMA_LENGTH_SLONG;
   } else if (ZLMA_LENGTH_SLONG == 0) {
      if (Period()==1) {
            slongData.Length = 1500;
      }if (Period()==5) {
            slongData.Length = 720;
      } else if (Period()==15) {
            slongData.Length = 960;
      } else if (Period()==30) {
            slongData.Length = 2880;
      } else if (Period()==60) {
            slongData.Length = 1440;
      } else if (Period()==240) {
            slongData.Length = 1800;
      } else if (Period()==1440) {
            slongData.Length = 1200;
      } else if (Period()==10080) {
            slongData.Length = 1800;
      } 
   }

   if (ZLMA_LENGTH_SLONG > -1) {

      slongData.Price = ZLMA_APPLY_ON_SLONG;

      slongData.name = "slongdata";

      bufferNum = initIndicator(slongData,bufferNum); 

   }
      
   
   EventSetTimer(screenshot_interval);


   return(0);

}






void OnDeinit(const int reason) {

      ObjectsDeleteAll(0,"TTSG_TP_SELL_");
      ObjectsDeleteAll(0,"TTSG_TP_BUY_");
      ObjectsDeleteAll(0,"TTSG_SL_SELL_");
      ObjectsDeleteAll(0,"TTSG_SL_BUY_");  

      ObjectsDeleteAll(0,"DD_ORDER");
      ObjectsDeleteAll(0,"DD_PROFIT");
      ObjectsDeleteAll(0,"DD_TOTAL_PROFIT");
      ObjectsDeleteAll(0,"DD_EN");
      ObjectsDeleteAll(0,"DD_TP");
      ObjectsDeleteAll(0,"DD_SL");
      ObjectsDeleteAll(0,"DD_LINE");
      ObjectsDeleteAll(0,"IND_TIME");  
      ObjectsDeleteAll(0,"LAST_SG"); 
      ObjectsDeleteAll(0,"LAST_SG_PIPS");  

}


void OnTimer() {

      if (!take_screenshot) return;
            ResetLastError();   
            if (!ChartScreenShot(0,"signalone\\" + Symbol() + "_" + Period() +  ".png",1200,700,ALIGN_RIGHT)) Print("Screenshot error !");

}



int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double   &open[],const double   &high[],const double   &low[],
                const double   &close[],const long     &tick_volume[],const long     &volume[],const int &spread[]) {


   return calculateIndicator(prev_calculated,rates_total,slongData,longData,shortData);       

   
}


int calculateIndicator(int prev_calculated,int rates_total,IndicatorData &slong_data,IndicatorData &long_data,IndicatorData &short_data) {


      int limit=0;
      int CountedBars=prev_calculated;
      if(CountedBars>rates_total) CountedBars=rates_total;
      if(CountedBars<0) return(-1);
      if(CountedBars>0) CountedBars--;
      if(CountedBars<10) CountedBars = 10;
      limit=rates_total-CountedBars;  
      if (limit > bars) limit = bars;
      
      
      if (ZLMA_LENGTH_SHORT > -1) {

            for(int i=1;i < short_data.Length * short_data.Cycle + short_data.Length;i++) {
            
                  short_data.MABuffer[rates_total-i]=0;    
                  short_data.UpBuffer[rates_total-i]=0;  
                  short_data.DnBuffer[rates_total-i]=0;  
                  
            } 

      }


      if (ZLMA_LENGTH_LONG > -1) {

            for(int i=1;i < long_data.Length * long_data.Cycle + long_data.Length;i++) {
            
                  long_data.MABuffer[rates_total-i]=0;    
                  long_data.UpBuffer[rates_total-i]=0;  
                  long_data.DnBuffer[rates_total-i]=0;  
                  
            } 

      }

      if (ZLMA_LENGTH_SLONG > -1) {

            int slong_buffer_size = slong_data.Length * slong_data.Cycle + slong_data.Length;


            for(int x=1;x < slong_buffer_size;x++) {
            
                  slong_data.MABuffer[rates_total-x]=0;
                  slong_data.UpBuffer[rates_total-x]=0;  
                  slong_data.DnBuffer[rates_total-x]=0;  
                  
            }        

      }      


      
      for(int i=limit; i>=0; i--) {

            if (ZLMA_LENGTH_SLONG > -1) {
                  doTTMAWork(i,Symbol(),Period(),slongData,long_data);
            }

            if (ZLMA_LENGTH_LONG > -1) {
                  doTTMAWork(i,Symbol(),Period(),long_data,short_data);
            }

            if (ZLMA_LENGTH_SHORT > -1) {

                  doTTMAWork(i,Symbol(),Period(),short_data,long_data);

            }

            
      }

      showWorkingTrades();    


      return(rates_total);

} 




void doTTMAWork(int shift,string chart_symbol,int timeframe_t,IndicatorData &indicatorData,IndicatorData &long_data) {

      double price;
      indicatorData.Sum = 0;
      for (int i=0;i<=indicatorData.Len-1;i++) { 
      

         price = iMA(NULL,timeframe_t,1,0,ZLMA_APPLY_ON_SHORT,indicatorData.Price,i+shift);      
         indicatorData.Sum += indicatorData.alfa[i] * price;
      }
   
	if (Period() > 1) { 
            if (indicatorData.Weight > 0) indicatorData.MABuffer[shift] = (1.0 + indicatorData.Deviation/100) * indicatorData.Sum / indicatorData.Weight;
      } else {
            indicatorData.Deviation = 0.02;
            if (indicatorData.Weight > 0) indicatorData.MABuffer[shift] = (1.0 + indicatorData.Deviation/100) * indicatorData.Sum / indicatorData.Weight;
      }
      
      if (indicatorData.PctFilter > 0){
      
            indicatorData.Del[shift] = MathAbs(indicatorData.MABuffer[shift] - indicatorData.MABuffer[shift+1]);
         
            double sumdel=0;
            for (int i=0;i<=indicatorData.Length-1;i++) sumdel = sumdel+indicatorData.Del[shift+i];
            indicatorData.AvgDel[shift] = sumdel / indicatorData.Length;
         
            double sumpow = 0;
            for (int i=0;i<=indicatorData.Length-1;i++) sumpow+=MathPow(indicatorData.Del[shift+i]-indicatorData.AvgDel[shift+i],2);
            double StdDev = MathSqrt(sumpow / indicatorData.Length); 
         
            indicatorData.Filter = indicatorData.PctFilter * StdDev;
      
            if( MathAbs(indicatorData.MABuffer[shift]-indicatorData.MABuffer[shift+1]) < indicatorData.Filter ) indicatorData.MABuffer[shift]=indicatorData.MABuffer[shift+1];
         
      } else {
            indicatorData.Filter=0;
      }

      CandleData candle_data;

      candle_data.atr_val = iATR(NULL,timeframe_t,1,shift);
      candle_data.close_price_val = iClose(NULL,timeframe_t,shift);
      candle_data.open_price_val = iOpen(NULL,timeframe_t,shift);
      candle_data.high_price_val = iHigh(NULL,timeframe_t,shift);
      candle_data.low_price_val = iLow(NULL,timeframe_t,shift);
      candle_data.candle_time = iTime(NULL,timeframe_t,shift);

      textPipsShift = candle_data.atr_val;



      /*for (int i=0; i < 12; i++) {
            flat_array[i] = indicatorData.MABuffer[shift+i];
      }

      if (flat_array[0] > flat_array[11]) {
            flat_array[12] = flat_array[0] - flat_array[11];
      } else {
            flat_array[12] = flat_array[11] - flat_array[0];
      }*/

      //double ma_val = iMA(NULL,Period(),MA_LENGTH,0,MA_TYPE,0,shift);




      if (indicatorData.Color > 0) {
      
         indicatorData.trend[shift] = indicatorData.trend[shift+1];
         if (indicatorData.MABuffer[shift]-indicatorData.MABuffer[shift+1] > indicatorData.Filter) indicatorData.trend[shift]= 1; 
         if (indicatorData.MABuffer[shift+1]-indicatorData.MABuffer[shift] > indicatorData.Filter) indicatorData.trend[shift]=-1;



          
         if (indicatorData.trend[shift] > 0 ) { ////////////  UPTREND ///////////////
         
               indicatorData.UpBuffer[shift] = indicatorData.MABuffer[shift];
               if (indicatorData.trend[shift+indicatorData.ColorBarBack]<0) indicatorData.UpBuffer[shift+indicatorData.ColorBarBack]=indicatorData.MABuffer[shift+indicatorData.ColorBarBack];
               indicatorData.DnBuffer[shift] = EMPTY_VALUE;         
         
                  
                  if (indicatorData.name == "shortdata" && (LAST_SG == SG_SELL || LAST_SG == 0) ) {

                        if ((candle_data.low_price_val > indicatorData.UpBuffer[shift] ) && (candle_data.high_price_val > indicatorData.UpBuffer[shift] ) 
                                    && candle_data.open_price_val < candle_data.close_price_val ) {

                          


                                    if (indicatorData.name == "longdata"||indicatorData.name == "slongdata") {


                                                //indicatorData.up_arr[shift] = candle_data.low_price_val - textPipsShift / 3;
                                                //indicatorData.up_sl_arr[shift] = candle_data.par_sar_val;
                                                indicatorData.LAST_SG = SG_BUY;
                                    
                                                total_signals++;                                           

                                    } else if (indicatorData.name == "shortdata") {

                                                

                                                string cur_trend;
                                                
                                                if (ZLMA_LENGTH_LONG > -1) cur_trend = DoubleToStr(longData.trend[shift],0);
                                                

                                                if ( (ZLMA_LENGTH_LONG > -1 && cur_trend == 1 && candle_data.open_price_val > longData.MABuffer[shift]) || (ZLMA_LENGTH_LONG == -1)) {

                                                      if ( (ZLMA_LENGTH_LONG > -1 && shortData.MABuffer[shift] > longData.MABuffer[shift]) || (ZLMA_LENGTH_LONG == -1) ) {


                                                                  Print("Signal BUY at " + LAST_SG_DATETIME  + " Timeframe: " + GetNameTF(Period()) + "Last signal num: " + LAST_SG_SHIFT + " Candle num: " + shift);

                                                                  if ( (LAST_SG_SHIFT - shift) > CANDLE_LENGTH) {
                                                                        indicatorData.up_arr[shift] = candle_data.low_price_val - textPipsShift;
                                                                        LAST_SG = SG_BUY;
                                                                        LAST_DIRECTION_SG_SHORT = 0;
                                                                        LAST_SG_PRICE = candle_data.open_price_val;
                                                                        LAST_SG_DATETIME = candle_data.candle_time;
                                                                        LAST_SG_SHIFT = shift; 
                                                                        indicatorData.LAST_SG = SG_BUY;


                                                                        if (Enable_Notifications && shift == 0) SendNotification(Symbol() + " BUY Signal" + "\nPeriod: " + GetNameTF(Period()) + "\nPrice: " + NormalizeDouble(candle_data.close_price_val,sym_digits) + "\n");  

                                                                        total_signals++;                                                                                                                                               
                                                                  }


                                                      }

                                                } 

                                    }


                              

                        } else {

                        }

                  }
             
               //Print("LAST SG: " + IntegerToString(LAST_SG));
            
         }
         
         if (indicatorData.trend[shift] < 0) { /////////// DOWNTREND //////////
         
         
               indicatorData.DnBuffer[shift] = indicatorData.MABuffer[shift];
               if (indicatorData.trend[shift+indicatorData.ColorBarBack]>0) indicatorData.DnBuffer[shift+indicatorData.ColorBarBack]=indicatorData.MABuffer[shift+indicatorData.ColorBarBack];
               indicatorData.UpBuffer[shift] = EMPTY_VALUE;   

                  if (indicatorData.name == "shortdata" && (LAST_SG == SG_BUY || LAST_SG == 0) ) {
            

                        if ( candle_data.low_price_val < indicatorData.DnBuffer[shift] && candle_data.high_price_val < indicatorData.DnBuffer[shift] 
                        && candle_data.open_price_val > candle_data.close_price_val) {
                        


                                    if (indicatorData.name == "longdata"||indicatorData.name == "slongdata") {

                                                //indicatorData.dn_arr[shift] = candle_data.high_price_val + textPipsShift / 3;
                                                //indicatorData.dn_sl_arr[shift] = candle_data.par_sar_val ;
                                                indicatorData.LAST_SG = SG_SELL;

                                                total_signals++;                                          

                                    } else if (indicatorData.name == "shortdata" ) {


                                                string cur_trend;
                                                
                                                if (ZLMA_LENGTH_LONG > -1) cur_trend = DoubleToStr(longData.trend[shift],0);
                                                


                                                if ( (ZLMA_LENGTH_LONG > -1 && cur_trend == -1 && candle_data.open_price_val < longData.MABuffer[shift]) || (ZLMA_LENGTH_LONG == -1) ) {

                                                      if ( (ZLMA_LENGTH_LONG > -1 && shortData.MABuffer[shift] < longData.MABuffer[shift]) || (ZLMA_LENGTH_LONG == -1) ) {

                                                                  if ( (LAST_SG_SHIFT - shift) > CANDLE_LENGTH) {
                                                                        Print("Signal SELL at " + LAST_SG_DATETIME + " Timeframe: " + GetNameTF(Period()) + "Last signal num: " + LAST_SG_SHIFT  + " candle num: " + shift);
                                                                        indicatorData.dn_arr[shift] = candle_data.high_price_val + textPipsShift;
                                                                        LAST_SG = SG_SELL;
                                                                        LAST_DIRECTION_SG_SHORT = 0;
                                                                        LAST_SG_PRICE = candle_data.open_price_val;
                                                                        LAST_SG_DATETIME = candle_data.candle_time;
                                                                                    LAST_SG_SHIFT = shift;
                                                                        indicatorData.LAST_SG = SG_SELL;

                                                                        if (Enable_Notifications && shift == 0) SendNotification(Symbol() + "SELL Signal" + "\nPeriod: " + GetNameTF(Period()) + "\nPrice: " + NormalizeDouble(candle_data.close_price_val,sym_digits) + "\n");  

                                                                        total_signals++;                                                                                                                                                 
                                                                  }


                                                      }

                                                }

                                    }

                    
                              
                        } else {

                        }

                  }

            
         }
      }


}


void drawDownSL(CandleData &candle_dt,IndicatorData &indicatorData,string chart_symbol,int psar_distance_in_pips,int t_total_signals) {


            string t_text = "";
          

            t_text = t_text + " " + DoubleToStr(flat_array[12],3);


            string t_name =  "TTSG_SL_SELL_" + chart_symbol + "_" + indicatorData.Length + "_" + IntegerToString(t_total_signals);
            
            if(ObjectCreate(0, t_name,OBJ_TEXT,0,candle_dt.candle_time,candle_dt.high_price_val + textPipsShift * 3)) {
            
                  ObjectSetString(0,t_name,OBJPROP_TEXT,t_text);
                  ObjectSetString(0,t_name,OBJPROP_FONT,"Tahoma");
                  ObjectSetInteger(0,t_name,OBJPROP_FONTSIZE,10);
                  ObjectSetDouble(0,t_name,OBJPROP_ANGLE,90.0);
                  ObjectSetInteger(0,t_name,OBJPROP_ANCHOR,ANCHOR_CENTER);
                  ObjectSetInteger(0,t_name,OBJPROP_COLOR,indicatorData.arrowTextColorSell); 
                              
            }  

            /*if (ObjectCreate(0,t_name + "L",OBJ_TREND,0,t_candle_time,t_candle_high + 0.5,t_candle_time,t_candle_price)) {
                  ObjectSetInteger(0,t_name + "L",OBJPROP_RAY,false);
                  ObjectSetInteger(0,t_name + "L",OBJPROP_COLOR,clrRed);
                  ObjectSetInteger(0,t_name + "L",OBJPROP_HIDDEN,1);
            }*/

}

void drawUpSL(CandleData &candle_dt,IndicatorData &indicatorData,string chart_symbol,int psar_distance_in_pips,int t_total_signals) {


            string t_text = "";       

            t_text = t_text + " " + DoubleToStr(flat_array[12],3);


            string t_name =  "TTSG_SL_SELL_" + chart_symbol + "_" + indicatorData.Length + "_" + IntegerToString(t_total_signals);            

            if(ObjectCreate(0,t_name,OBJ_TEXT,0,candle_dt.candle_time,candle_dt.low_price_val - textPipsShift * 3)) {
            
                  ObjectSetString(0,t_name,OBJPROP_TEXT,t_text);
                  ObjectSetString(0,t_name,OBJPROP_FONT,"Tahoma");
                  ObjectSetInteger(0,t_name,OBJPROP_FONTSIZE,10);
                  ObjectSetDouble(0,t_name,OBJPROP_ANGLE,90.0);
                  ObjectSetInteger(0,t_name,OBJPROP_ANCHOR,ANCHOR_CENTER);
                  ObjectSetInteger(0,t_name,OBJPROP_COLOR,indicatorData.arrowTextColorBuy); 
                              
            }  

            /*if (ObjectCreate(0,t_name + "L",OBJ_TREND,0,t_candle_time,t_candle_low - 0.5,t_candle_time,t_candle_price)) {
                  ObjectSetInteger(0,t_name + "L",OBJPROP_RAY,false);
                  ObjectSetInteger(0,t_name + "L",OBJPROP_COLOR,clrLimeGreen);
                  ObjectSetInteger(0,t_name + "L",OBJPROP_HIDDEN,1);
            } */                    


}



void showWorkingTrades () {

      int text_downshift = 0;      

      ObjectDelete(0,"IND_TIME");
      
      drawStaticText("IND_TIME","DATETIME: " + TimeToStr(TimeLocal()),10,5,text_downshift,clrWhite); 


      ObjectDelete(0,"LAST_SG");

      int digits_t = (int)MarketInfo(Symbol(),MODE_DIGITS);

      text_downshift = text_downshift + 20;

      int pips_went = getLastSignalPips();

      if (LAST_SG != 0) {
            
            if (LAST_SG == SG_BUY) {
                  drawStaticText("LAST_SG","BUY (" + pips_went + ") - " + DoubleToStr(LAST_SG_PRICE,digits_t) + " - " + StringSubstr(TimeToStr(LAST_SG_DATETIME),5),10,5,text_downshift,clrLime); 

            } else if (LAST_SG == SG_SELL) {
                  drawStaticText("LAST_SG","SELL (" + pips_went + ") - " + DoubleToStr(LAST_SG_PRICE,digits_t) + " - " + StringSubstr(TimeToStr(LAST_SG_DATETIME),5),10,5,text_downshift,clrRed);
            }
         
      }

      text_downshift = text_downshift + 20;

      //ObjectDelete("LAST_SG_PIPS");

      //drawStaticText("LAST_SG_PIPS","LAST SIGNAL PIPS:  " + getLastSignalPips(),10,5,text_downshift,clrRed);



      ObjectsDeleteAll(0,"DD_ORDER");
      ObjectsDeleteAll(0,"DD_PROFIT");
      ObjectsDeleteAll(0,"DD_TOTAL_PROFIT");
      ObjectsDeleteAll(0,"DD_EN");
      ObjectsDeleteAll(0,"DD_TP");
      ObjectsDeleteAll(0,"DD_SL");
      ObjectsDeleteAll(0,"DD_LINE");

        if (OrdersTotal() > 0) {

            string running_orders;

            int total_profit = 0 ;


            for(int i=OrdersTotal()-1;i>=0;i--) {

                  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

                  string order_symbol = OrderSymbol();
                  double order_price = OrderOpenPrice();
                  double order_tp = OrderTakeProfit();
                  double order_sl = OrderStopLoss();
                  double order_lots = OrderLots();

                  double order_profit = OrderProfit();
                  double order_swap = OrderSwap();
                  double order_comm = OrderCommission();

                  total_profit = total_profit + order_profit + order_comm + order_swap;

                  string order_type = (OrderType() == 0) ? "BUY" : "SELL";


                  int sym_digits = (int)MarketInfo(order_symbol,MODE_DIGITS);



                  int symbol_tp_price_len = StringLen(DoubleToStr(order_tp,sym_digits));
                  int symbol_sl_price_len = StringLen(DoubleToStr(order_sl,sym_digits));
                  int symbol_price_len = StringLen(DoubleToStr(order_price,sym_digits));
                  int tp_shift = 0;
                  int en_shift = 0;

                  if (symbol_tp_price_len == 4) {
                        tp_shift = 60;
                        en_shift = 120;
                  } else if ((symbol_tp_price_len == 7)) {
                        tp_shift = 60;
                        en_shift = 140;
                  }

                  if (symbol_sl_price_len == 4) {
                        //tp_shift = tp_shift + 20;
                        //en_shift = en_shift + 20;
                  } else if (symbol_sl_price_len == 7) {
                        tp_shift = tp_shift + 20;
                        en_shift = en_shift + 20;
                  }
                  
                  if (order_type == "BUY") {
                        drawStaticText("DD_PROFIT_" + text_downshift,order_symbol + " (" + order_type + "-" + DoubleToStr(order_lots,2) + ")  P: " + DoubleToStr(order_profit,2),10,5,text_downshift + 20,clrYellow); 
                  } else if (order_type == "SELL") {
                        drawStaticText("DD_PROFIT_" + text_downshift,order_symbol + " (" + order_type + "-" + DoubleToStr(order_lots,2) + ")  P: " + DoubleToStr(order_profit,2),10,5,text_downshift + 20,clrYellow); 
                  }

                  drawStaticText("DD_EN_" + text_downshift,"EN: " + DoubleToStr(order_price,sym_digits),10,en_shift,text_downshift + 40,clrWhite); 

                  drawStaticText("DD_TP_" + text_downshift,"TP: " + DoubleToStr(order_tp,sym_digits),10,tp_shift,text_downshift + 40,clrLimeGreen); 

                  drawStaticText("DD_SL_" + text_downshift,"SL: " + DoubleToStr(order_sl,sym_digits),10,5,text_downshift + 40,clrRed);  

                  //drawStaticText("DD_LINE" + text_downshift,"----------------------------------------",8,5,text_downshift + 45,clrWhite);  

                  text_downshift = text_downshift + 45;


            }

                  drawStaticText("DD_LINE" + text_downshift,"----------------------------------------",8,5,text_downshift + 60,clrWhite); 

                  drawStaticText("DD_TOTAL_PROFIT_" + text_downshift,"Total profit: " + IntegerToString(total_profit),10,5,text_downshift + 80,clrYellow); 



        } 


}

int getLastSignalPips () {

      if (LAST_SG == 0) return -1;

      double order_entry_price = LAST_SG_PRICE;

      RefreshRates();

      int pips;


      if (LAST_SG == SG_BUY) {

            double cur_price = Ask;

            pips = (cur_price - order_entry_price) / ( Point * point_multiplier );


      } else if (LAST_SG == SG_SELL) {

            double cur_price = Bid;

            pips =  (order_entry_price - cur_price) / ( Point * point_multiplier);

      }

      return pips;


}

void sendPipsMessages(int pips) {

      //if (pips)

}


void drawStaticText (string t_name,string t_text,int t_size,int X,int Y,color text_color) {

            if(ObjectCreate(0, t_name,OBJ_LABEL,0,0,0,0,0)) {
            
                  ObjectSet(t_name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
                  ObjectSet(t_name,OBJPROP_XDISTANCE,X);
                  ObjectSet(t_name,OBJPROP_YDISTANCE,Y);    
                  ObjectSetText(t_name,t_text,t_size,"Tahoma",Black);                   
                  //ObjectSetInteger(0,t_name,OBJPROP_FONTSIZE,12);
                  ObjectSetInteger(0,t_name,OBJPROP_COLOR,text_color); 
                 
                              
            }  
}




string GetNameTF(int ctTF) {

   switch (ctTF) {
      case 1 : return "M1"; break;
      case 5 : return "M5"; break;
      case 15 : return "M15"; break;
      case 30 : return "M30"; break;
      case 60 : return "H1"; break;
      case 240 : return "H4"; break;
      case 1440 : return "D1"; break;
      case 10080 : return "W1"; break;
      case 43200 : return "MN1"; break;
   }
   
   return "";
   
} 



