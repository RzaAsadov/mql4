#include "../Include/libs/Mql/Collection/HashMap.mqh"
#include "../Include/libs/Mql/Collection/LinkedList.mqh"
#include "../Include/libs/Mql/Format/Json.mqh"
#include "../Include/libs/hash.mqh"
#include "../Include/libs/json.mqh"
#include "../Include/libs/JAson.mqh"

#include "../Include/TradersTube/core/Common.mqh"
#include "../Include/TradersTube/core/log.mqh"
#include "../Include/TradersTube/core/JsonOperations.mqh"
#include "../Include/TradersTube/extensions/ServerConnector.mqh"
#include "../Include/TradersTube/extensions/DrawDownCalculator.mqh"
#include "../Include/TradersTube/extensions/OrderHistoryCalculator.mqh"



extern string server_key = "";
extern string Server_Host = "api-ea-v1.fortfinance.ee";
extern int Calculated_data_period = 3600;

extern int SendDataEveryMs=1000;

extern int ServerRequestTimeoutMs = 10000;
extern int ServerFailTriesToReport = 10;

extern bool isDebug = false;
extern bool silentMode = true;


extern string main_log_filename = "";

string ea_name = "";
string version = "1.2.0";



int seconds_passed_dd_sender = 0;
int seconds_passed_history_sender = 0;

int last_total_history=-1;


char history_count_req_data[]; 


int account_id = 0;

bool first_start = true;

bool first_connection_to_server = true;


HashMap<string,int>*symbol_pairs = new HashMap<string,int>();

HashMap<string,string>*symbols_names_market = new HashMap<string,string>();

HashMap<string,string>*symbols_names_orig = new HashMap<string,string>();

HashMap<string,int>*timeframes_t = new HashMap<string,int>();

int OnInit() {

      ea_name = WindowExpertName();

      if (main_log_filename == "") {
            main_log_filename = ea_name + ".log";
      }      

      /*if (isDebug) {
            FileDelete(request_log_filename);
            FileDelete(response_log_filename);
            FileDelete(main_log_filename);
      } */     

      account_id==AccountNumber();

      if (AccountNumber()==0) {
            MessageBox("ERROR unable to get account id");
            ExpertRemove();
      }

      while (!getSymbolsFromServer()) {
            Print("Couldn't get symbol list from server !");
            Sleep(5000);        
      }      


   EventSetMillisecondTimer(SendDataEveryMs);

   Print("Init successful !");

   return(INIT_SUCCEEDED);

}

void OnDeinit(const int reason) {

   EventKillTimer();
   
}

void OnTick() {
 
   
}

void OnTimer() {


                        if (!isAllHistoryEnabled()) {
                              MessageBox("ERROR: History date range must from balance - All history mode");
                              ExpertRemove();                              
                        }

                        

                        Comment("Version: " + version);



                        CJAVal *all_data_to_be_send = new CJAVal();

                        all_data_to_be_send["tok_key"]=server_key;
                        all_data_to_be_send["acct_id"]=AccountNumber();   

                        if (isDebug) {
                              all_data_to_be_send["netondo_debug_mode_x999"]="activated";
                        }                                             

                        CJAVal *dd_data = getDrawDownData(server_key);

                              if (dd_data != NULL) {
                                    all_data_to_be_send["dd_data"].Set(dd_data);
                                    if (isDebug) {
                                          logWriteToFile("DD Json:" + dd_data.Serialize(),"tradertubetradereader.log");
                                    }
                              } 


                        if (isDebug) {
                              Print("History getter getting from: " + last_total_history);
                        }

                        if (last_total_history > -1) {

                              CJAVal *his_data = getOrdersHistory(server_key, last_total_history);

                                    if (his_data != NULL) {
                                          all_data_to_be_send["his_data"].Set(his_data);
                                          if (isDebug) {
                                                logWriteToFile("History Json:" + his_data.Serialize(),main_log_filename);
                                          }    
                                    } 

                                    delete his_data; 


                        }                        


                        char req_data[];   
                     

                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1);  

                        delete all_data_to_be_send;
                        delete dd_data;
                        

                              char response_json[];


                              int req_return_val = requestServer(req_data, "tradeReaderMainHandler",response_json);

                              if (req_return_val==0) {

                                    JSONParser *parser = new JSONParser();

                                    JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                                    delete parser;

                                    //Print("Server totals 1: " + last_total_history);


                                    last_total_history = getIntValFromJsonObject(j_data_obj,"his_count");
                                    int order_id = getIntValFromJsonObject(j_data_obj,"order_id");
                                    int ll = getIntValFromJsonObject(j_data_obj,"last_ticket");

      
                                    delete j_data_obj;


                              }

                              ArrayFree(req_data);
                              ArrayFree(response_json);


}



