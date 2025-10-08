#import "shell32.dll"
    int ShellExecuteA(int hWnd, string Verb, string File, string Parameter, string Path, int ShowCommand);
#import


#include "../Include/libs/Mql/Collection/HashMap.mqh"
#include "../Include/libs/Mql/Collection/LinkedList.mqh"
#include "../Include/libs/Mql/Format/Json.mqh"
#include "../Include/libs/hash.mqh"
#include "../Include/libs/json.mqh"
#include "../Include/libs/JAson.mqh"
#include "../Include/TradersTube/core/log.mqh"
#include "../Include/TradersTube/core/JsonOperations.mqh"
#include "../Include/TradersTube/core/Common.mqh"
#include "../Include/TradersTube/extensions/ServerConnector.mqh"

#define        WIDTH  800     // Image width to call ChartScreenShot()
#define        HEIGHT 600     // Image height to call ChartScreenShot()

extern string Key="Frekd453Fe43fWefcde444";
extern string Server_Host = "api-ea-v1.netondo.io";

extern bool capture_m1 = true;
extern bool capture_m5 = false;
extern bool capture_m15 = false;
extern bool capture_m30 = false;
extern bool capture_h1 = false;
extern bool capture_h4 = false;
extern bool capture_d1 = false;
extern bool capture_w1 = false;
extern bool capture_mn1 = false;

extern int workPeriodMs = 15000;

extern int ServerFailTriesToReport = 10;

extern int ServerRequestTimeoutMs = 5000;

extern bool isDebug = false;

extern bool silentMode = true;

extern bool sendInitStatusToServer = false;

extern bool sendRunningStatusToServer = false;

extern string main_log_filename = "";




datetime ea_started_at;

string ea_name = "";

string ea_version = "2.4.0";

HashMap<string,int>*symbol_pairs = new HashMap<string,int>();

HashMap<string,int>*timeframes_t = new HashMap<string,int>();

datetime screen_capture_start_datetime,screen_capture_stop_datetime;


datetime robot_timer_start_datetime,robot_timer_stop_datetime;
double robot_timer_passed_seconds = 0;

bool is_process_avialable = true;

int screenshot_taken = 0;

int generation_hours=0,generation_min=0,generation_sec=0;

double generation_speed=0;

bool is_initilized = false;

int absent_symbols_count = 0;

int cycle_num = 0;

string chart_comment_str="";

int timeframe_id = 0;

string timeframe_name = "";

int current_charts_count = 0;


int OnInit() {


    if (is_initilized) return(INIT_SUCCEEDED); // Prevent from double init. 

    ea_name = WindowExpertName();

    if (main_log_filename == "") {
        main_log_filename = ea_name + ".log";
    }    

    while (!IsConnected()) {
        Print("No connection to server !");
        Sleep(5000);
    }



    ea_started_at = TimeLocal();

    setupTimeframes();


    Comment("Timeframe is: " + timeframe_name + "\nVersion: " + ea_version + "\nEA started at:" + ea_started_at);


    if (sendInitStatusToServer) {

        Print("Waiting for init status sending (start).....");

        int is_init_busy = sendInitStatusToBackend(false);  

        while (is_init_busy > 0 || is_init_busy == -1) {

            is_init_busy = sendInitStatusToBackend(false); 

            Print("Waiting for init status sending (start).....");

            Sleep(2000); 

        }  

    }





        setupSymbols();

        closePrevioslyOpenedCharts();

        // Open charts
        openCharts(symbol_pairs,timeframes_t);

        waitForAllChartsOpen();


    if (sendInitStatusToServer) {

        Print("Waiting for init status sending (stop)....."); 

        int ret_val = sendInitStatusToBackend(true);

        while  (ret_val == -1) {
            ret_val = sendInitStatusToBackend(true);
            Print("Waiting for init status sending (stop).....");            
            Sleep(2000);
       }

    }   

       Print("Init successful!");
       Print("Version is " + ea_version);
       Print("Timeframe val is: " + timeframe_id); 

       setupFirstChart();              

       //setupTimer();

       captureCharts();

       closePrevioslyOpenedCharts();

       string command_to_run = "/F /FI \"WINDOWTITLE eq " + AccountNumber() + "*\"";

       ShellExecuteA(0, "Open", "c:\\windows\\system32\\taskkill.exe",command_to_run, "", 1);

       ExpertRemove();

       is_initilized = true; 
       
            

      return(INIT_SUCCEEDED);

}



void OnDeinit(const int reason) {

    //EventKillTimer();

}

void OnTimer() {



    robot_timer_stop_datetime = TimeLocal();

    robot_timer_passed_seconds = robot_timer_stop_datetime - robot_timer_start_datetime;

    if (robot_timer_passed_seconds > (workPeriodMs/1000) && is_process_avialable) {

            captureCharts();

            robot_timer_start_datetime = TimeLocal();

    }


    Comment("Timeframe is: " + timeframe_name + "\nVersion: " + ea_version + "\nEA started at:" + ea_started_at + "\nUpdate time: " + workPeriodMs + "\n" + chart_comment_str + "\nLast generation_speed: " + generation_speed + " sec. \nNext generate time (sec): " + ((workPeriodMs/1000)-robot_timer_passed_seconds));


}


void setupTimer() {

       robot_timer_start_datetime = TimeLocal();
       robot_timer_stop_datetime = TimeLocal();       

       EventSetTimer(2); 

}



void setupFirstChart() {

        

        ChartSetInteger(ChartFirst(),CHART_COLOR_CHART_UP,clrBlack);
        ChartSetInteger(ChartFirst(),CHART_COLOR_CHART_DOWN,clrBlack);
        ChartSetInteger(ChartFirst(),CHART_COLOR_CANDLE_BULL,clrBlack);
        ChartSetInteger(ChartFirst(),CHART_COLOR_CANDLE_BEAR,clrBlack);

        ResetLastError();

        if (!ChartSetInteger(ChartFirst(),CHART_BRING_TO_TOP,1)) {
                  //--- display the error message in Experts journal
                Print(__FUNCTION__+", Error Code = ",GetLastError());
        }


        Print("Setup first chart done !");

}


void waitForAllChartsOpen() {

        current_charts_count = getChartCount();

        Print("Waiting for opening of all charts (" + (symbol_pairs.size()-absent_symbols_count+1) + ") , current = " + current_charts_count);


        while (current_charts_count < (symbol_pairs.size()-absent_symbols_count)+1) {

                current_charts_count = getChartCount();

                //Print("Waiting for opening of all charts (" + (symbol_pairs.size()-absent_symbols_count+1) + ") , current = " + current_charts_count);

                Sleep(2000);

        }    

}


void closePrevioslyOpenedCharts() {

    Print("Closing opened charts.....");


        current_charts_count = getChartCount();

        while (current_charts_count > 1) {

                current_charts_count = getChartCount();

                // Close all previos opened chart 
                int closed_charts_count = closeAllCharts();

                Print("Closed = " + closed_charts_count); 

                Sleep(300);           

        } 

        current_charts_count = getChartCount();       

    Print("Current opened chart count is " + current_charts_count);    

}

void setupSymbols() {

      symbol_pairs.set("EURUSD",PERIOD_H1);
      symbol_pairs.set("EURJPY",PERIOD_H1);
      symbol_pairs.set("EURCAD",PERIOD_H1);
      symbol_pairs.set("EURCHF",PERIOD_H1);
      symbol_pairs.set("EURGBP",PERIOD_H1);
      symbol_pairs.set("EURNZD",PERIOD_H1);
      symbol_pairs.set("EURAUD",PERIOD_H1);

      symbol_pairs.set("GBPUSD",PERIOD_H1);
      symbol_pairs.set("GBPAUD",PERIOD_H1);
      symbol_pairs.set("GBPNZD",PERIOD_H1);
      symbol_pairs.set("GBPCHF",PERIOD_H1);
      symbol_pairs.set("GBPCAD",PERIOD_H1);
      symbol_pairs.set("GBPJPY",PERIOD_H1); 

      symbol_pairs.set("USDJPY",PERIOD_H1);
      symbol_pairs.set("USDCAD",PERIOD_H1);
      symbol_pairs.set("USDCHF",PERIOD_H1);

      symbol_pairs.set("AUDCAD",PERIOD_H1);
      symbol_pairs.set("AUDNZD",PERIOD_H1);
      symbol_pairs.set("AUDCHF",PERIOD_H1);
      symbol_pairs.set("AUDUSD",PERIOD_H1);
      symbol_pairs.set("AUDJPY",PERIOD_H1);

      symbol_pairs.set("CHFJPY",PERIOD_H1);

      symbol_pairs.set("NZDCHF",PERIOD_H1);
      symbol_pairs.set("NZDUSD",PERIOD_H1);
      symbol_pairs.set("NZDCAD",PERIOD_H1);
      symbol_pairs.set("NZDJPY",PERIOD_H1);
      

      symbol_pairs.set("CADJPY",PERIOD_H1);
      symbol_pairs.set("CADCHF",PERIOD_H1);

      symbol_pairs.set("XAUUSD",PERIOD_H1);
      symbol_pairs.set("XAGUSD",PERIOD_H1);

      symbol_pairs.set("EURTRY",PERIOD_H1);
      symbol_pairs.set("USDTRY",PERIOD_H1);
      symbol_pairs.set("GBPTRY",PERIOD_H1);
      symbol_pairs.set("TRYJPY",PERIOD_H1);

      symbol_pairs.set("#NASDAQ100",PERIOD_H1);
      symbol_pairs.set("#US30",PERIOD_H1); 
      symbol_pairs.set("BTCUSD",PERIOD_H1);  
      symbol_pairs.set("ETHUSD",PERIOD_H1);  
      symbol_pairs.set("LTCUSD",PERIOD_H1);  
      symbol_pairs.set("RIPPLE",PERIOD_H1);  
      symbol_pairs.set("#SPX500",PERIOD_H1);    

}

void setupTimeframes() {

        if (capture_m1) {
            timeframes_t.set("M1",PERIOD_M1);
            timeframe_id=1;
            timeframe_name = "M1";
        }

        if (capture_m5) {
            timeframes_t.set("M5",PERIOD_M5);
            timeframe_id=2;
            timeframe_name = "M5";
        }

        if (capture_m15) {
            timeframes_t.set("M15",PERIOD_M15);
            timeframe_id=3;
            timeframe_name = "M15";
        }

        if (capture_m30) {
            timeframes_t.set("M30",PERIOD_M30);
            timeframe_id=4;
            timeframe_name = "M30";
        }

        if (capture_h1) {
            timeframes_t.set("H1",PERIOD_H1);
            timeframe_id=5;
            timeframe_name = "H1";
        }

        if (capture_h4) {    
            timeframes_t.set("H4",PERIOD_H4);
            timeframe_id=6;
            timeframe_name = "H4";
        }
        
        if (capture_d1) {
            timeframes_t.set("D1",PERIOD_D1);
            timeframe_id=7;
            timeframe_name = "D1";
        }

        if (capture_w1) {
            timeframes_t.set("W1",PERIOD_W1);
            timeframe_id=8;
            timeframe_name = "W1";
        }

        if (capture_mn1) {
            timeframes_t.set("MN1",PERIOD_MN1);
            timeframe_id=9;
            timeframe_name = "MN1";
        }


        if (GlobalVariableGet("env")==1) {
            timeframes_t.set("M5",PERIOD_M5);
            timeframe_id=2;
            timeframe_name = "M5";
        }  
        
}

string timeframeToString (int tf_val) {

    foreachm(string,keytf,int,valuetf,timeframes_t) {

        if (valuetf==tf_val) return keytf;

    }
    return NULL;
}


void openCharts (HashMap<string,int> &symbol_pairs, HashMap<string,int> &timeframes_m) {

        Print("Opening charts....");

        foreachm(string,keytf,int,valuetf,timeframes_m) {


                foreachm(string,key,int,value,symbol_pairs) {


                        long already_opened_chart_id = isChartOpen(key,valuetf);    

                        if (already_opened_chart_id > -1 && already_opened_chart_id != ChartID()) continue;


                        long chart_id = ChartOpen(key,valuetf);

                        if (chart_id == 0) {
                            Print("Symbol \"" + key + "\" not found in marketwatch, error code = " + GetLastError());
                            absent_symbols_count++;
                            continue;
                        } 
                        
                        //Print("Chart open for: " + key + " (" + valuetf + ")");



                        ChartApplyTemplate(chart_id,"Herobot.tpl");

                        ChartSetInteger(chart_id,CHART_AUTOSCROLL,0,true);
                        ChartSetInteger(chart_id,CHART_WIDTH_IN_BARS,0,90);

                        Sleep(30);

                }

        }


}


void captureCharts () {


        if (!silentMode) {

            is_process_avialable = false;

            int is_server_busy = sendRunningStatusToBackend(is_process_avialable);

            if (is_server_busy > 0)  { 
                is_process_avialable = true;
                return;
            } else if (is_server_busy == -1) {
                is_process_avialable = true;
                return;            
            }

        }

        screen_capture_start_datetime = TimeLocal();

        screenshot_taken = 0;


        long nextChart = ChartFirst();

        if (nextChart == -1) return;

        while (nextChart > -1) {

                nextChart = ChartNext(nextChart);

                if (nextChart == -1) break;

                if (nextChart == ChartID()) continue;


                string chartSymbol_t = ChartSymbol(nextChart);

                int chartPeriod_t = ChartPeriod(nextChart);

                
                string screenshot_filename = "charts_images\\" + chartSymbol_t + "_" + timeframeToString(chartPeriod_t) +  ".png";

                FileDelete(screenshot_filename);


                if (!ChartScreenShot(nextChart,screenshot_filename,WIDTH,HEIGHT,ALIGN_RIGHT)) {

                        Print("Screenshot error , chart_id = " + nextChart + ", code=" + GetLastError() + ", p=" + chartPeriod_t + " ,pSTR=" +  timeframeToString(chartPeriod_t) + ", sym=" + chartSymbol_t + " W=" + WIDTH + ", H=" + HEIGHT);
                        Print("Error on file: " + screenshot_filename);

                } else {
                                screenshot_taken++;
                                //Sleep(100);
                }

                chart_comment_str = "Current open charts count=" + getChartCount() + "\nScreenshot taken:" + screenshot_taken + "\nTime local: " + TimeToStr(TimeLocal());
                Comment("Timeframe is: " + timeframe_name + "\nVersion: " + ea_version + "\nEA started at:" + ea_started_at + "\nUpdate time: " + workPeriodMs + "\n" + chart_comment_str);


        }   

        screen_capture_stop_datetime = TimeLocal(); 

        generation_speed = screen_capture_stop_datetime - screen_capture_start_datetime;


        if (!silentMode) {

            is_process_avialable = true;

            int ret_val = sendRunningStatusToBackend(is_process_avialable);

            while  (ret_val == -1) {
                ret_val = sendRunningStatusToBackend(is_process_avialable);
                Sleep(500);
            }

        }


}


int sendRunningStatusToBackend (bool is_process_avialable) {

            CJAVal *all_data_to_be_send = new CJAVal();

            all_data_to_be_send["tok_key"]=Key;

            all_data_to_be_send["is_process_avialable"]=is_process_avialable;

            all_data_to_be_send["timeframe_id"]=timeframe_id;

            all_data_to_be_send["chart_count"]=getChartCount();


            char req_data[];   


            ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1);  

            
            char response_json[];

            int req_return_val = requestServer(req_data, "setChartScreenerStatus",response_json);



            if (req_return_val==0) {

                JSONParser *parser = new JSONParser();

                JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                delete parser;                 

                if (j_data_obj == NULL) {

                        delete j_data_obj;
                        return -1;

                }

                JSONValue *is_server_busy_key = j_data_obj.getValue("is_server_busy");

                if (is_server_busy_key == NULL) {

                    delete is_server_busy_key;
                    delete j_data_obj;
                    return -1;   

                }

                int ret_val =  getIntValFromJsonObject(j_data_obj,"is_server_busy");

                delete is_server_busy_key;
                delete j_data_obj;
                return ret_val;

            }

            return -1;

            

}

int sendInitStatusToBackend (bool is_process_avialable) {

            CJAVal *all_data_to_be_send = new CJAVal();

            all_data_to_be_send["tok_key"]=Key;

            all_data_to_be_send["is_init_avialable"]=is_process_avialable;

            all_data_to_be_send["timeframe_id"]=timeframe_id;

            all_data_to_be_send["chart_count"]=getChartCount();


            char req_data[];   



            ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1);  


            char response_json[];

            int req_return_val = requestServer(req_data, "setChartScreenerInit",response_json);



            if (req_return_val==0) {

                JSONParser *parser = new JSONParser();

                JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                delete parser;                  


                if (j_data_obj == NULL) {

                    delete j_data_obj;
                    return -1;

                }

                JSONValue *is_init_busy_key = j_data_obj.getValue("is_init_busy");

                if (is_init_busy_key == NULL) {

                        delete is_init_busy_key;
                        delete j_data_obj;
                        return -1; 

                }

                int ret_val =  getIntValFromJsonObject(j_data_obj,"is_init_busy");

                
                delete is_init_busy_key;
                delete j_data_obj;

                return ret_val;

            }
                return -1;

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

