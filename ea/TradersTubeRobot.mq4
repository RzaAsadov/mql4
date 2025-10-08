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
#include "../Include/TradersTube/extensions/DrawDownCalculator.mqh"
#include "../Include/TradersTube/extensions/OrderHistoryCalculator.mqh"
#include "../Include/TradersTube/extensions/getExecuteCommands.mqh"
#include "../Include/TradersTube/extensions/symbolManager.mqh"




extern string Key = "";
string Server_Host = "api-ea-v1.traders-tube.com";

int Robot_Magic_Number = 19841984;

extern bool isDebug = false;


int Calculated_data_period = "3600";

int SendDataEveryMs=1000;

int ServerFailTriesToReport = 10;
int ServerRequestTimeoutMs = 10000;

double addPipsToSL = 0;

bool silentMode = true;
bool emulateTradeOperations = false;

string main_log_filename = "";

string ea_name="";


int seconds_passed_dd_sender = 0;
int seconds_passed_history_sender = 0;

int last_total_history=-1;

string server_key = Key;


const int CLOSE_FULL=0;
const int CLOSE_PARTIAL=1;

int account_id = 0;

bool first_connection_to_server = true;

HashMap<string,int>*symbol_pairs = new HashMap<string,int>();

HashMap<string,string>*symbols_names_market = new HashMap<string,string>();
HashMap<string,string>*symbols_names_orig = new HashMap<string,string>();

HashMap<string,int>*timeframes_t = new HashMap<string,int>();


//CJAVal *emulatedTrades = new CJAVal();


int OnInit() {


      ea_name = WindowExpertName();

      if (main_log_filename == "") {
            main_log_filename = ea_name + ".log";
      }      

      account_id=AccountNumber();

      while  (account_id==0) {
            Print("ERROR unable to get account id");
            account_id=AccountNumber();
            Sleep(1000);
      }

      if (!activateRobotOnServer()) {

      }

      while (!getSymbolsFromServer()) {
            Print("Couldn't get symbol list from server !");
            Sleep(5000);        
      }


      /* while (!getSymbolsFromServer()) {
            Print("Couldn't get symbol list from server !");
            Sleep(5000);        
      }  */     

      //info();

   EventSetMillisecondTimer(SendDataEveryMs);

   Print("Init successful !");



   return(INIT_SUCCEEDED);

}

void OnDeinit(const int reason) {
   EventKillTimer();
}


void OnTimer() {

                        if (!isAllHistoryEnabled()) {
                              MessageBox("ERROR: History date range must from balance - All history mode");
                              ExpertRemove();                              
                        }      

                        checkAndClearGlobalvars();

                        //findAndCloseOrderAfterCandleCount(5);

                        findAndHalfCoseOrders();

                        CJAVal *all_data_to_be_send = new CJAVal();

                        CJAVal *dd_data = getDrawDownData(Key);


                        if (dd_data != NULL) {
                              all_data_to_be_send["dd_data"].Set(dd_data);
                        }

                              CJAVal *his_data = getOrdersHistory(Key, last_total_history);


                              if (his_data != NULL) {
                                 all_data_to_be_send["his_data"].Set(his_data);
                              }                           


                        all_data_to_be_send["tok_key"]=Key;
                        all_data_to_be_send["acct_id"]=account_id;


                        if (isDebug) {
                              all_data_to_be_send["netondo_debug_mode_x999"]="activated";
                        }

                        char req_data[];              


                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 

                        delete all_data_to_be_send;
                        delete dd_data;
                        delete his_data;

                              char response_json[];

                              int req_return_val = requestServer(req_data, "tradeCopierMainHandler",response_json);
                              


                              if (req_return_val==0) {




                                    JSONParser *parser = new JSONParser();

                                    JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json) );

                                    delete parser;

                                    last_total_history = getIntValFromJsonObject(j_data_obj,"his_count");


                                    JSONValue *signal_data_val = j_data_obj.getValue("signals");
                                    JSONObject *signal_data_obj = signal_data_val;


                                    ///// Retrive orders from server

                                    if (signal_data_obj != null) {
                                          if (isDebug) Print("Calling method -> getAndExecuteOrders!");
                                          getAndExecuteOrders(signal_data_obj); 
                                    } 



                                    //delete jo;
                                    delete signal_data_obj;
                                    delete signal_data_val;
                                    delete j_data_obj;

                              }

                              ArrayFree(req_data);
                              ArrayFree(response_json);

}

void info () {

            //--- Name of the company
            string company=AccountInfoString(ACCOUNT_COMPANY);
            //--- Name of the client
            string name=AccountInfoString(ACCOUNT_NAME);
            //--- Account number
            long login=AccountInfoInteger(ACCOUNT_LOGIN);
            //--- Name of the server
            string server=AccountInfoString(ACCOUNT_SERVER);
            //--- Account currency
            string currency=AccountInfoString(ACCOUNT_CURRENCY);
            //--- Demo, contest or real account
            ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
            //--- Now transform the value of  the enumeration into an understandable form
            string trade_mode;
            switch(account_type)
            {
                  case  ACCOUNT_TRADE_MODE_DEMO:
                  trade_mode="demo";
                  break;
                  case  ACCOUNT_TRADE_MODE_CONTEST:
                  trade_mode="contest";
                  break;
                  default:
                  trade_mode="real";
                  break;
            }
            //--- Stop Out is set in percentage or money
            ENUM_ACCOUNT_STOPOUT_MODE stop_out_mode=(ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
            //--- Get the value of the levels when Margin Call and Stop Out occur
            double margin_call=AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
            double stop_out=AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
            //--- Show brief account information
            PrintFormat("The account of the client '%s' #%d %s opened in '%s' on the server '%s'",
                        name,login,trade_mode,company,server);
            PrintFormat("Account currency - %s, MarginCall and StopOut levels are set in %s",
                        currency,(stop_out_mode==ACCOUNT_STOPOUT_MODE_PERCENT)?"percentage":" money");
            PrintFormat("MarginCall=%G, StopOut=%G",margin_call,stop_out);  

}


bool activateRobotOnServer () {

                        CJAVal *all_data_to_be_send = new CJAVal();
                      


                        all_data_to_be_send["tok_key"]=Key;
                        all_data_to_be_send["acct_id"]=account_id;

                        if (IsDemo()) {
                              all_data_to_be_send["is_demo"] = 1;
                        } else {
                              all_data_to_be_send["is_demo"] = 0;
                        }

                        all_data_to_be_send["acct_company"] = AccountInfoString(ACCOUNT_COMPANY);
                        all_data_to_be_send["acct_server"] = AccountInfoString(ACCOUNT_SERVER);
                        all_data_to_be_send["acct_name"] = AccountInfoString(ACCOUNT_NAME);
                        all_data_to_be_send["acct_currency"] = AccountInfoString(ACCOUNT_CURRENCY);
                        all_data_to_be_send["acct_deposit"] = AccountInfoDouble(ACCOUNT_BALANCE);


                        if (isDebug) {
                              all_data_to_be_send["netondo_debug_mode_x999"]="activated";
                        }

                        char req_data[];              


                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 

                        delete all_data_to_be_send;


                              char response_json[];

                              int req_return_val = requestServer(req_data, "setRobotStatus",response_json);


                              if (req_return_val==0) {


                                    JSONParser *parser = new JSONParser();

                                    JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                                    delete parser;

                                    string result_str = getStringValFromJsonObject(j_data_obj,"result");

                                    if (result_str == "error") {
                                          MessageBox("Activate erro: " + getStringValFromJsonObject(j_data_obj,"result"));
                                          delete j_data_obj;
                                          ArrayFree(response_json); 
                                          return false;
                                    } else {
                                          delete j_data_obj;                                          
                                          return true;
                                    }




                              }

                              ArrayFree(req_data);
                              ArrayFree(response_json);  

                        return false;                            

}