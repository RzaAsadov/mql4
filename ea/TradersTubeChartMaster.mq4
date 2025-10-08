#include "../Include/libs/Mql/Collection/HashMap.mqh"
#include "../Include/libs/Mql/Collection/LinkedList.mqh"
#include "../Include/libs/Mql/Format/Json.mqh"
#include "../Include/libs/hash.mqh"
#include "../Include/libs/json.mqh"
#include "../Include/libs/JAson.mqh"
#include "../Include/TradersTube/extensions/ServerConnector.mqh"
#include "../Include/TradersTube/core/log.mqh"
#include "../Include/TradersTube/core/JsonOperations.mqh"
#include "../Include/TradersTube/core/Common.mqh"

#define        WIDTH  1200     // Image width to call ChartScreenShot()
#define        HEIGHT 700     // Image height to call ChartScreenShot()



extern string server_key = "dsadasewr23452323ASFDSR32432fsacQWfasfds";
extern string Server_Host = "api-ea-v1.fortfinance.ee";
extern int RSI_Period = 14;
extern int ATR_Period = 7;
extern bool Open_charts = false;

extern bool Is_Test_Mode = false;
extern bool Test_Send_Signal = true;
extern bool Test_Failed_Signal = false;
extern string Test_Symbol = "XAUUSD";
extern string Test_Serial = "100000";
extern string Test_Timeframe = "H1";
extern string Test_Direction = "Bullish";
extern string Test_Type = "Hidden";




bool first_connection_to_server = true;

int ServerFailTriesToReport = 10;
int ServerRequestTimeoutMs = 10000;
bool silentMode = true;

extern bool isDebug = false;

int absent_symbols_count = 0;




datetime ea_started_at;

string ea_name = "";

string ea_version = "1.5.0";

HashMap<string,int>*symbol_pairs = new HashMap<string,int>();

HashMap<string,string>*symbols_names_market = new HashMap<string,string>();
HashMap<string,string>*symbols_names_orig = new HashMap<string,string>();



HashMap<string,int>*timeframes_t = new HashMap<string,int>();

datetime screen_capture_start_datetime,screen_capture_stop_datetime;


datetime robot_timer_start_datetime,robot_timer_stop_datetime;
double robot_timer_passed_seconds = 0;

bool is_process_avialable = true;

int screenshot_taken = 0;

int generation_hours=0,generation_min=0,generation_sec=0;

double generation_speed=0;

bool is_initilized = false;


int cycle_num = 0;

string chart_comment_str="";

string timeframe_name = "";

int current_charts_count = 0;


int DIRECTION_BULLISH = 1;
int DIRECTION_BEARISH = 2;

int DIVERGENCE_TYPE_REGULAR = 1;
int DIVERGENCE_TYPE_HIDDEN = 2;

int COLOR_REGULAR_BULLISH = 32768;
int COLOR_REGULAR_BEARISH = 255;
int COLOR_HIDDEN_BULLISH = 65407;
int COLOR_HIDDEN_BEARISH = 5275647;


int OnInit() {


    if (is_initilized) return(INIT_SUCCEEDED); // Prevent from double init. 


    ea_name = WindowExpertName();



    while (!IsConnected()) {
        Print("No connection to server !");
        Sleep(5000);
    }



    //ChartApplyTemplate(0,"TradersTube.tpl");


    ea_started_at = TimeLocal();

    setupTimeframes();

    while (!getDivergenceSymbolsAndTimeframes()) {
        Print("Couldn't get symbol list from server !");
        Sleep(5000);        
    }





            if (Open_charts) {
                closePrevioslyOpenedCharts();
            }

            Sleep(2000);

            // Open charts
            if (Open_charts) {
                openCharts(symbol_pairs,timeframes_t);
                waitForAllChartsOpen();
            }

            Sleep(1000);

            ChartSetInteger(0,CHART_BRING_TO_TOP,0,true); 



 
       Print("Init successful!");
       Print("Version is " + ea_version);

       doWork();

       EventSetTimer(10);

       is_initilized = true; 

        if (Is_Test_Mode && Test_Send_Signal) {
                int return_val = send_test_signal(Test_Symbol,StringToInteger(Test_Serial),Test_Timeframe,
                                Test_Direction,Test_Type);  

                MessageBox(IntegerToString(return_val));     
        }
            

      return(INIT_SUCCEEDED);

}



void OnDeinit(const int reason) {

    //EventKillTimer();

}

void OnTimer() {


        string comment_str = "Version: " + ea_version + "\nEA started at:" + ea_started_at + "\n";

        comment_str  = comment_str + "Open chart count: " + getChartCount() + "\n";

        Comment(comment_str);


        //captureCharts();
        doWork();


}


void doWork() {


        datetime current_time = TimeCurrent();

        long nextChart = ChartFirst();

        if (nextChart == -1) return;

        while (nextChart > -1) {

                        /*if (nextChart != ChartID()) {  // FOR TESTING PURPOSES

                                nextChart = ChartNext(nextChart);

                                continue;
                        }*/

                        findAndSendDivergenceForSingleChart(nextChart);

                        findAndSendMACrossingsForSingleChart(nextChart);

                        nextChart = ChartNext(nextChart);


        } 



     
}

void findAndSendMACrossingsForSingleChart (long nextChart) {
        

        int timeframe_t = ChartPeriod(nextChart);
        string chart_symbol = ChartSymbol(nextChart);

        CheckConditions(chart_symbol, timeframe_t, "MA50",nextChart);
        CheckConditions(chart_symbol, timeframe_t, "MA100",nextChart);
        CheckConditions(chart_symbol, timeframe_t, "MA200",nextChart);




}

void findAndSendDivergenceForSingleChart (long nextChart) {

                        int timeframe_t = ChartPeriod(nextChart);
                        string chart_symbol = ChartSymbol(nextChart);
                        string chart_period = timeframeToString(timeframe_t);

                        int last_arrow_id = GlobalVariableGet(chart_symbol + "_" + chart_period);


                        int symbol_digits = getDigits(chart_symbol);

                        // Bullish divergence finder
                        int obj_total=ObjectsTotal(nextChart,0);


                        for(int i=0;i<obj_total;i++) {

                                string name = ObjectName(nextChart,i);

                                if (StringFind(name,"RSI_Div_Arrow") == -1) {
                                        continue;
                                }


                                int arrow_color = ObjectGetInteger(nextChart,name,OBJPROP_COLOR);

                                datetime arrow_time = ObjectGetInteger(nextChart,name,OBJPROP_TIME);


                                string chart_divergence_direction=getDivergenceDirection(arrow_color);
                                string chart_divergence_type=getDivergenceType(arrow_color);

                                if ( (chart_divergence_direction == "Undeclared") || (chart_divergence_type == "Undeclared") ) continue;

                      

                                int arrow_id = StringToInteger(StringSubstr(name,14));



                                if (arrow_id > last_arrow_id) {

                                        //Print(arrow_id + " > " + last_arrow_id + " " + chart_symbol + "_" + chart_period);


                                        string screenshot_filename = "charts_images\\" + chart_symbol + "_" + chart_period + "_" + IntegerToString(arrow_id) +  ".png";
                                        ResetLastError();   

                                        bool screenshot_res = ChartScreenShot(nextChart,screenshot_filename,WIDTH,HEIGHT,ALIGN_RIGHT);

                                        if (!screenshot_res) {

                                                Print("Screenshot error , chart_id = " + nextChart + ", code=" + GetLastError() + ", p=" + chart_period + ", sym=" + chart_symbol + " W=" + WIDTH + ", H=" + HEIGHT);
                                                Print("Error on file: " + screenshot_filename);
                                                continue;

                                        } else {

                                                
                                                double vbid,vask;

                                                int bar_shift=iBarShift(chart_symbol,timeframe_t,arrow_time);
                                                
                                                if (bar_shift == 0) {
                                                        RefreshRates();
                                                        vbid = NormalizeDouble(MarketInfo(chart_symbol,MODE_BID),symbol_digits);
                                                        vask = NormalizeDouble(MarketInfo(chart_symbol,MODE_ASK),symbol_digits);   
                                                } else {
                                                        vbid = iClose(chart_symbol,timeframe_t,bar_shift);
                                                        vask = vbid;
                                                }


                                                double is_ma_check_needed = symbol_pairs.get(chart_symbol + ":" + chart_period,0);


                                                char response_data[];
                                                char req_data[];

                                                //if (bar_shift == 0) {

                                                        double ma_20 = NormalizeDouble(iMA(chart_symbol,timeframe_t,20,0,MODE_SMMA,PRICE_CLOSE,bar_shift),symbol_digits);
                                                        double ma_50 = NormalizeDouble(iMA(chart_symbol,timeframe_t,50,0,MODE_SMMA,PRICE_CLOSE,bar_shift),symbol_digits);
                                                        double ma_100 = NormalizeDouble(iMA(chart_symbol,timeframe_t,100,0,MODE_SMMA,PRICE_CLOSE,bar_shift),symbol_digits); 
                                                        double ma_200 = NormalizeDouble(iMA(chart_symbol,timeframe_t,200,0,MODE_SMMA,PRICE_CLOSE,bar_shift),symbol_digits); 
                                                        double atr = NormalizeDouble(iATR(chart_symbol,timeframe_t,ATR_Period,bar_shift),symbol_digits);    
                                                        double rsi = NormalizeDouble(iRSI(chart_symbol,timeframe_t,RSI_Period,PRICE_CLOSE,bar_shift),2);


                                                        string candle_datetime = TimeToStr(arrow_time);
                                                        StringReplace(candle_datetime,".","-");

                                                        CJAVal *all_data_to_be_send = new CJAVal();

                                                        all_data_to_be_send["symbol"]=chart_symbol;
                                                        all_data_to_be_send["cur_price_ask"]=DoubleToStr(vask,symbol_digits);
                                                        all_data_to_be_send["cur_price_bid"]=DoubleToStr(vbid,symbol_digits);
                                                        all_data_to_be_send["timeframe"]=chart_period;
                                                        all_data_to_be_send["direction"]=chart_divergence_direction;
                                                        all_data_to_be_send["ma20"]=DoubleToStr(ma_20,symbol_digits);
                                                        all_data_to_be_send["ma50"]=DoubleToStr(ma_50,symbol_digits);
                                                        all_data_to_be_send["ma100"]=DoubleToStr(ma_100,symbol_digits);
                                                        all_data_to_be_send["ma200"]=DoubleToStr(ma_200,symbol_digits);
                                                        all_data_to_be_send["rsi"]=DoubleToStr(rsi,symbol_digits);
                                                        all_data_to_be_send["atr"]=DoubleToStr(atr,symbol_digits);
                                                        all_data_to_be_send["serial"]=arrow_id;
                                                        all_data_to_be_send["candle_dt"]=candle_datetime;
                                                        all_data_to_be_send["divergence_type"]=chart_divergence_type;
                                                        all_data_to_be_send["indicator_token"]=server_key;


                                                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 


                                                        int req_return_val = requestServer(req_data, "setDivergenceData",response_data);


                                                        if (req_return_val==0) {

                                                                GlobalVariableSet(chart_symbol + "_" + chart_period,arrow_id);
                                                                Print("Divergence for symbol=" + chart_symbol + "_" + chart_period + " - ("+ arrow_id + ")" + " sent to server!");

                                                                if (bar_shift == 0) {

                                                                        string ma_50_direction = get_ma50_direction(chart_divergence_direction,vask,vbid,ma_50);
                                                                        string ma_200_direction = get_ma200_direction(chart_divergence_direction,vask,vbid,ma_200);


                                                                        string push_msg = chart_symbol + " (" + chart_divergence_direction + "/" + chart_divergence_type + ") " + chart_period + "\n";
                                                                        push_msg = push_msg + "Price - " + DoubleToStr(vask,symbol_digits) + " / " + DoubleToStr(vbid,symbol_digits) + "\n";
                                                                        push_msg = push_msg + "MA50 - " + DoubleToStr(ma_50,symbol_digits) + " (" + ma_50_direction + ") " + "\n" + " MA200 - " + DoubleToStr(ma_200,symbol_digits) + " (" + ma_200_direction + ") " + "\n";
                                                                        push_msg = push_msg + "RSI - " + rsi + " \n";
                                                                        push_msg = push_msg + "Datetime - " + candle_datetime + " \n";
                                                                        SendNotification(push_msg);

                                                                }                                                                        

                                                        } else {
                                                                Print("ERROR (" + req_return_val + "): Divergence for symbol=" + chart_symbol + "_" + chart_period + " - ("+ arrow_id + ")" + " not sent to server!");

                                                        }   
                                           

                                                        ArrayFree(response_data);
                                                        ArrayFree(req_data);

                                                        delete all_data_to_be_send;

                                                //} else {
                                                //        GlobalVariableSet(chart_symbol + "_" + chart_period,arrow_id);

                                                //}

                                        }                                                                                            

                                }




                        }  

                        bool is_previous_found = false;

                        string chart_divergence_direction,chart_divergence_type;


                        for(int i=0;i<obj_total;i++) {

                                string name = ObjectName(nextChart,i);

                                if (StringFind(name,"RSI_Div_Arrow") == -1) {
                                        continue;
                                }


                                int arrow_color = ObjectGetInteger(nextChart,name,OBJPROP_COLOR);

                                datetime arrow_time = ObjectGetInteger(nextChart,name,OBJPROP_TIME);

                                chart_divergence_direction=getDivergenceDirection(arrow_color);
                                chart_divergence_type=getDivergenceType(arrow_color); 

                                int arrow_id = StringToInteger(StringSubstr(name,14));


                                if (arrow_id == last_arrow_id) is_previous_found = true; // NEEDED FOR DISAPPERING / FAILED DIVERGENCES


                        }                        

                        if (!is_previous_found && last_arrow_id != 0) { // We have not find previous arrow , it seems divergence failed

                                        Print("Disappeared ARROW ON Chart=" + chart_symbol + " timeframe=" + chart_period + " arrow_id=" + last_arrow_id);


                                        char response_data[];
                                        char req_data[];   

                                        CJAVal *all_data_to_be_send = new CJAVal();

                                        all_data_to_be_send["symbol"]=chart_symbol;
                                        all_data_to_be_send["timeframe"]=chart_period;
                                        all_data_to_be_send["direction"]=chart_divergence_direction;
                                        all_data_to_be_send["serial"]=last_arrow_id;
                                        all_data_to_be_send["divergence_type"]=chart_divergence_type;
                                        all_data_to_be_send["indicator_token"]=server_key;


                                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 

                                        int req_return_val = requestServer(req_data, "updateDivergenceData",response_data);


                                        if (req_return_val==0) {                                         


                                                        GlobalVariableDel(chart_symbol + "_" + chart_period);
                                                        Print("Divergence UPDATE for symbol=" + chart_symbol + " - ("+ last_arrow_id + ")" + " sent to server!");

                                                        if (isDebug) {
                                                                Print("Divergence UPDATE for symbol=" + chart_symbol + " - ("+ last_arrow_id + ")" + " sent to server!");
                                                        }

                                                        string push_msg = "DIVERGENCE FAILED\n" + chart_symbol + " (" + chart_divergence_direction + ") " + chart_period + "\n";
                                                        SendNotification(push_msg);                                                        

                                        }    
                                
                                        //Print(CharArrayToString(response_data));                                             

                                        ArrayFree(response_data);
                                        ArrayFree(req_data);  

                                        delete all_data_to_be_send;                                                                                                                  
                        } 


}

int send_test_signal(string chart_symbol,int serial,string chart_period,string chart_divergence_direction,string chart_divergence_type) {


        int symbol_digits = getDigits(chart_symbol);


        double vbid = NormalizeDouble(MarketInfo(chart_symbol,MODE_BID),symbol_digits);
        double vask = NormalizeDouble(MarketInfo(chart_symbol,MODE_ASK),symbol_digits);       

        int timeframe_t = timeframeNameToPeriodValue(chart_period);   


        double ma_20 = NormalizeDouble(iMA(chart_symbol,timeframe_t,20,0,MODE_EMA,PRICE_CLOSE,0),symbol_digits);
        double ma_50 = NormalizeDouble(iMA(chart_symbol,timeframe_t,50,0,MODE_EMA,PRICE_CLOSE,0),symbol_digits);
        double ma_100 = NormalizeDouble(iMA(chart_symbol,timeframe_t,100,0,MODE_EMA,PRICE_CLOSE,0),symbol_digits); 
        double ma_200 = NormalizeDouble(iMA(chart_symbol,timeframe_t,200,0,MODE_EMA,PRICE_CLOSE,0),symbol_digits); 
        double atr = NormalizeDouble(iATR(chart_symbol,timeframe_t,ATR_Period,0),symbol_digits);    
        double rsi = NormalizeDouble(iRSI(chart_symbol,timeframe_t,RSI_Period,PRICE_CLOSE,0),2);


        CJAVal *all_data_to_be_send = new CJAVal();

        all_data_to_be_send["symbol"]=chart_symbol;
        all_data_to_be_send["cur_price_ask"]=DoubleToStr(vask,symbol_digits);
        all_data_to_be_send["cur_price_bid"]=DoubleToStr(vbid,symbol_digits);
        all_data_to_be_send["timeframe"]=chart_period;
        all_data_to_be_send["direction"]=chart_divergence_direction;
        all_data_to_be_send["ma20"]=DoubleToStr(ma_20,symbol_digits);
        all_data_to_be_send["ma50"]=DoubleToStr(ma_50,symbol_digits);
        all_data_to_be_send["ma100"]=DoubleToStr(ma_100,symbol_digits);
        all_data_to_be_send["ma200"]=DoubleToStr(ma_200,symbol_digits);
        all_data_to_be_send["rsi"]=DoubleToStr(rsi,symbol_digits);
        all_data_to_be_send["atr"]=DoubleToStr(atr,symbol_digits);


        all_data_to_be_send["serial"]=serial;
        all_data_to_be_send["candle_dt"]=TimeToStr(TimeLocal());
        all_data_to_be_send["divergence_type"]=chart_divergence_type;
        all_data_to_be_send["indicator_token"]=server_key;

        char response_data[];
        char req_data[];


        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 


        int res =  requestServer(req_data, "setDivergenceData",response_data);

        ArrayFree(response_data);
        ArrayFree(req_data);  

        return res;       



}


string get_ma50_direction(string chart_divergence_direction,double vask,double vbid,double ma_50) {

        if (chart_divergence_direction=="Bullish") {

                if (ma_50 < vask) { 
                        return "BUY";
                } else if (ma_50 > vask) {
                        return "SELL";
                } else {
                        return "NEUTRAL";
                } 
   

        } else if (chart_divergence_direction=="Bearish") {

                if (ma_50 < vbid) { 
                        return "BUY";
                } else if (ma_50 > vbid) {
                        return "SELL";
                } else {
                        return "NEUTRAL";
                }                                                                                         

        }   

        return "error";

}

string get_ma200_direction(string chart_divergence_direction,double vask,double vbid,double ma_200) {

        if (chart_divergence_direction=="Bullish") {

                if (ma_200 < vask) { 
                        return "BUY";
                } else if (ma_200 > vask) {
                        return "SELL";
                } else {
                        return "NEUTRAL";
                }       

        } else if (chart_divergence_direction=="Bearish") {

                if (ma_200 < vbid) { 
                        return "BUY";
                } else if (ma_200 > vbid) {
                        return "SELL";
                } else {
                        return "NEUTRAL";
                }                                                                                           

        }  

        return "error";         
             
}


void CheckConditions(string symbol, int timeframe, string maName,long nextChart) {


   
   int ma50Period = 50;
   int ma100Period = 100;
   int ma200Period = 200;     


   int symbol_digits = getDigits(symbol);


   double maValue = NormalizeDouble(iMA(symbol, timeframe, maName == "MA50" ? ma50Period : maName == "MA100" ? ma100Period : ma200Period, 0, MODE_SMMA, PRICE_CLOSE, 0),symbol_digits);

   string globalVarName = symbol + "_" + timeframeToString(timeframe) + "_" + maName;


   int last_direction = GlobalVariableGet(globalVarName);

   int current_direction = 0;
   string ma_direction;

   if (last_direction == 0) {

        double lastClose = iClose(symbol, timeframe, 1);   

        if (lastClose > maValue) {

                        current_direction = 1;
                        ma_direction = "Bullish";

        } else if (lastClose < maValue) {

                        current_direction = 2;
                        ma_direction = "Bearish";
        }


   } else {

        double lastClose = iClose(symbol, timeframe, 1);   


        if (lastClose > maValue && last_direction == 2) {

                        current_direction = 1;
                        ma_direction = "Bullish";

        } else if (lastClose < maValue && last_direction == 1) {

                        current_direction = 2;
                        ma_direction = "Bearish";

        } else {
                current_direction = last_direction;
        }


   }

   
   if (last_direction != current_direction) {

        string screenshot_filename = "charts_images\\" + symbol + "_" + timeframeToString(timeframe) +  ".png";
        ResetLastError();           

        if (!ChartScreenShot(nextChart,screenshot_filename,WIDTH,HEIGHT,ALIGN_RIGHT)) {

                Print("Screenshot error , chart_id = " + nextChart + ", code=" + GetLastError() + ", p=" + timeframeToString(timeframe) + ", sym=" + symbol + " W=" + WIDTH + ", H=" + HEIGHT);
                Print("Error on file: " + screenshot_filename);
                return;

        } else {        


                RefreshRates();

                double vbid = NormalizeDouble(MarketInfo(symbol,MODE_BID),symbol_digits);
                double vask = NormalizeDouble(MarketInfo(symbol,MODE_ASK),symbol_digits);   

                char response_data[];
                char req_data[];


                        double atr = NormalizeDouble(iATR(symbol,timeframe,ATR_Period,1),symbol_digits);    
                        double rsi = NormalizeDouble(iRSI(symbol,timeframe,RSI_Period,PRICE_CLOSE,1),2);

                        datetime currentBarTime = iTime(symbol, timeframe, 1);


                        string candle_datetime = TimeToStr(currentBarTime);
                        StringReplace(candle_datetime,".","-");                        

                        CJAVal *all_data_to_be_send = new CJAVal();

                        all_data_to_be_send["symbol"]=symbol;
                        all_data_to_be_send["cur_price_ask"]=DoubleToStr(vask,symbol_digits);
                        all_data_to_be_send["cur_price_bid"]=DoubleToStr(vbid,symbol_digits);
                        all_data_to_be_send["timeframe"]=timeframeToString(timeframe);
                        all_data_to_be_send["rsi"]=DoubleToStr(rsi,2);
                        all_data_to_be_send["atr"]=DoubleToStr(atr,symbol_digits);                        
                        all_data_to_be_send["ma_period"]=maName;
                        all_data_to_be_send["ma_value"]=DoubleToStr(maValue,symbol_digits);
                        all_data_to_be_send["ma_direction"]=ma_direction;
                        all_data_to_be_send["candle_dt"]=candle_datetime;
                        all_data_to_be_send["indicator_token"]=server_key;


                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 


                        int req_return_val = requestServer(req_data, "setMaData",response_data);


                        if (req_return_val==0) {                          

                                        GlobalVariableSet(globalVarName, current_direction);
                                        if (last_direction==0) {
                                                Print("MA First data for symbol=" + symbol + "_" + timeframeToString(timeframe) + " - ("+ currentBarTime + ")" + " sent to server!");
                                        } else {
                                                Print("MA Trend change for symbol=" + symbol + "_" + timeframeToString(timeframe) + " - ("+ currentBarTime + ")" + " sent to server!");
                                        }

                        }    
                
                        //Print(CharArrayToString(response_data));                                             

                        ArrayFree(response_data);
                        ArrayFree(req_data);

                        delete all_data_to_be_send;

        }


   }


}



string getDivergenceDirection (int arrow_color) {

        if (arrow_color==COLOR_REGULAR_BULLISH) {
                return "Bullish";
        } else if (arrow_color==COLOR_HIDDEN_BULLISH) {
                return "Bullish";
        } else if (arrow_color==COLOR_REGULAR_BEARISH) {
                return "Bearish";
        } else if (arrow_color==COLOR_HIDDEN_BEARISH) {
                return "Bearish";
        }   

        return "Undeclared";

}

string getDivergenceType (int arrow_color) {

        if (arrow_color==COLOR_REGULAR_BULLISH) {
                return "Regular";
        } else if (arrow_color==COLOR_HIDDEN_BULLISH) {
                return "Hidden";
        } else if (arrow_color==COLOR_REGULAR_BEARISH) {
                return "Regular";
        } else if (arrow_color==COLOR_HIDDEN_BEARISH) {
                return "Hidden";
        } 

        return "Undeclared";  

}


void waitForAllChartsOpen() {

        current_charts_count = getChartCount();

        Print("Waiting for opening of all charts (" + (symbol_pairs.size()-absent_symbols_count) + ") , current = " + current_charts_count);


        while (current_charts_count < (symbol_pairs.size()-absent_symbols_count)) {

                current_charts_count = getChartCount();

                //Print("Waiting for opening of all charts (" + (symbol_pairs.size()-absent_symbols_count+1) + ") , current = " + current_charts_count);

                Sleep(2000);

        }   

        Print("All charts opened"); 

}


void closePrevioslyOpenedCharts() {

    Print("Closing opened charts.....");


        current_charts_count = getChartCount();

        while (current_charts_count > 1) {

                current_charts_count = getChartCount();

                // Close all previos opened chart 
                int closed_charts_count = closeAllCharts();

                Print("Closed = " + closed_charts_count); 

                Sleep(1000);           

        } 

        current_charts_count = getChartCount();       

    Print("Current opened chart count is " + current_charts_count);    

}






int timeframeNameToPeriodValue (string tf_val) {

    foreachm(string,keytf,int,valuetf,timeframes_t) {

        if (keytf==tf_val) return valuetf;

    }
    return NULL;
}


void openCharts (HashMap<string,int> &symbol_pairs, HashMap<string,int> &timeframes_m) {

        Print("Opening charts....");

                foreachm(string,key,int,value,symbol_pairs) {

                        ushort u_sep;                  // The code of the separator character
                        string result[];               // An array to get strings
                        //--- Get the separator code
                        u_sep=StringGetCharacter(":",0);
                        //--- Split the string to substrings
                        int k=StringSplit(key,u_sep,result);

                        int input_array_size = ArraySize(result);   

                        string valuetf,e_symbol;

                        if (input_array_size == 2) {
                                e_symbol = result[0];                                
                                valuetf = result[1];
                        } else {
                                Print("Server data incorrect for " + key);
                                ArrayFree(result);
                                continue;
                        }           

                        ArrayFree(result);

                        Print("Chart open for: " + key + " (" + valuetf + ")");


                        if ( e_symbol==Symbol() && timeframeNameToPeriodValue(valuetf)==Period() ) continue;


                        long already_opened_chart_id = isChartOpen(e_symbol,timeframeNameToPeriodValue(valuetf));    

                        if (already_opened_chart_id > -1 && already_opened_chart_id != ChartID()) continue;

                        ResetLastError();

                        long chart_id = ChartOpen(e_symbol,timeframeNameToPeriodValue(valuetf));

                        if (chart_id == 0) {
                            Print("OpenChartsInd: Symbol \"" + e_symbol + "\" not found in marketwatch, error code = " + GetLastError());
                            absent_symbols_count++;
                            continue;
                        } 

                        ChartApplyTemplate(chart_id,"TradersTube.tpl");
                        



                        ChartSetInteger(chart_id,CHART_AUTOSCROLL,0,true);
                        ChartSetInteger(chart_id,CHART_WIDTH_IN_BARS,0,130);

                        Sleep(1000);

                }


}




long isChartOpen(string symbol_str,int period_val) {


        long nextChart = ChartFirst();

        if (nextChart == -1) return -1;

        while (nextChart > -1) {

                nextChart = ChartNext(nextChart);

                if (ChartPeriod(nextChart)==period_val) {

                    if (ChartSymbol(nextChart)==period_val) {
                            return nextChart;
                    }

                }

        }

        return -1;

}

int closeAllCharts() {

        int closed_count = 0;

        long nextChart = ChartFirst();

        if (nextChart == -1) return 0;

        while (nextChart > -1) {

                nextChart = ChartNext(nextChart);

                if (ChartClose(nextChart)) {
                    closed_count++;
                }

        } 

        return closed_count;
}

int getChartCount() {

        int count = 0;

        long nextChart = ChartFirst();

        if (nextChart == -1) return 0;

        while (nextChart > -1) {

                nextChart = ChartNext(nextChart);

                count++;

        } 

        return count;
}

