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

extern string Key="Srsvc334232vASwwerwc";
extern string Server_Host = "api-ea-v1.netondo.io";

extern int ServerRequestTimeoutMs = 10000;
extern int ServerFailTriesToReport = 10;

extern int SendDataEveryMs = 20000;

extern bool isDebug = false;
extern bool silentMode = true;

extern string main_log_filename = "";

string ea_name = "";

bool first_connection_to_server = true;




HashMap<string,int>*symbols = new HashMap<string,int>();


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

   EventSetMillisecondTimer(SendDataEveryMs);
   
   return(INIT_SUCCEEDED); 
}


void OnDeinit(const int reason) {
   EventKillTimer();
}

void OnTick() {

}

void OnTimer() {



    char res_data[];

    CJAVal *collectedIndicatorData = new CJAVal();
    
    collectIndicatorData(symbols,collectedIndicatorData);

    delete symbols;
    symbols = new HashMap<string,int>();

    CJAVal *requestJsonObj = new CJAVal();

    requestJsonObj["tok_key"] = Key;
    requestJsonObj["indicator_data"].Set(collectedIndicatorData);


      string result = requestJsonObj.Serialize();

      delete collectedIndicatorData;
      delete requestJsonObj;



      char req_data[];


      ArrayResize(req_data, StringToCharArray(result, req_data, 0, WHOLE_ARRAY)-1); 

            char response_json[];

            int req_return_val = requestServer(req_data, "setIndicatorData",response_json);


            if (req_return_val==0) {

                  JSONParser *parser = new JSONParser();

                  JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                  delete parser;            

                  updateSymbolList(j_data_obj,symbols);

                  delete j_data_obj;

            }




            ArrayFree(res_data);
            ArrayFree(response_json);


}

void updateSymbolList(JSONObject &param_obj,HashMap<string,int> &symbol_pairs) {

            symbol_pairs.clear();

            JSONIterator *it = new JSONIterator(&param_obj);

            if (it == NULL) { delete it; return; };
      

            for( ; it.hasNext() ; it.next()) {  

                 string symbol_name = it.key();

                 JSONValue *single_order = it.val();
                 
                 symbol_pairs.set(symbol_name,single_order.getInt());

                 delete single_order;

            }

            delete it;

}



void collectIndicatorData(HashMap<string,int> &symbol_pairs,CJAVal &all_indicator_data) {


       if (symbol_pairs.isEmpty()) return;    

       int y=symbol_pairs.size()-1;

       foreachm(string,key,int,value,symbol_pairs) {

            CJAVal *iDataOfSymbol = new CJAVal();
            
            getIndicatorDataOfSymbol(key,value,iDataOfSymbol);
            
            all_indicator_data[y].Set(iDataOfSymbol);

            y--;

            delete iDataOfSymbol;

       }


}


void getIndicatorDataOfSymbol(string sym_str,int symbol_id,CJAVal &indicatorData) {
   
   double rsi_m1 = iRSI(sym_str,PERIOD_M1,14,PRICE_CLOSE,0);
   double rsi_m5 = iRSI(sym_str,PERIOD_M5,14,PRICE_CLOSE,0);
   double rsi_m15 = iRSI(sym_str,PERIOD_M15,14,PRICE_CLOSE,0); 
   double rsi_m30 = iRSI(sym_str,PERIOD_M30,14,PRICE_CLOSE,0);
   double rsi_h1 = iRSI(sym_str,PERIOD_H1,14,PRICE_CLOSE,0);
   double rsi_h4 = iRSI(sym_str,PERIOD_H4,14,PRICE_CLOSE,0);
   double rsi_d = iRSI(sym_str,PERIOD_D1,14,PRICE_CLOSE,0);
   double rsi_w = iRSI(sym_str,PERIOD_W1,14,PRICE_CLOSE,0);
   double rsi_mn = iRSI(sym_str,PERIOD_MN1,14,PRICE_CLOSE,0);
   
   double atr_1m = iATR(sym_str,PERIOD_M1,14,0);
   double atr_5m = iATR(sym_str,PERIOD_M5,14,0);
   double atr_15m = iATR(sym_str,PERIOD_M15,14,0);
   double atr_30m = iATR(sym_str,PERIOD_M30,14,0);
   double atr_h1 = iATR(sym_str,PERIOD_H1,14,0);
   double atr_h4 = iATR(sym_str,PERIOD_H4,14,0);
   double atr_d = iATR(sym_str,PERIOD_D1,14,0);
   double atr_w = iATR(sym_str,PERIOD_W1,14,0);
   double atr_mn = iATR(sym_str,PERIOD_MN1,14,0);

   double ma_1m_5 = iMA(sym_str,PERIOD_M1,5,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_1m_20 = iMA(sym_str,PERIOD_M1,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_1m_50 = iMA(sym_str,PERIOD_M1,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_1m_100 = iMA(sym_str,PERIOD_M1,100,0,MODE_SMMA,PRICE_CLOSE,0); 
   double ma_1m_200 = iMA(sym_str,PERIOD_M1,200,0,MODE_SMMA,PRICE_CLOSE,0);    
   

   double ma_5m_5 = iMA(sym_str,PERIOD_M5,5,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_5m_20 = iMA(sym_str,PERIOD_M5,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_5m_50 = iMA(sym_str,PERIOD_M5,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_5m_100 = iMA(sym_str,PERIOD_M5,100,0,MODE_SMMA,PRICE_CLOSE,0); 
   double ma_5m_200 = iMA(sym_str,PERIOD_M5,200,0,MODE_SMMA,PRICE_CLOSE,0); 

   
   double ma_15m_5 = iMA(sym_str,PERIOD_M15,5,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_15m_20 = iMA(sym_str,PERIOD_M15,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_15m_50 = iMA(sym_str,PERIOD_M15,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_15m_100 = iMA(sym_str,PERIOD_M15,100,0,MODE_SMMA,PRICE_CLOSE,0); 
   double ma_15m_200 = iMA(sym_str,PERIOD_M15,200,0,MODE_SMMA,PRICE_CLOSE,0); 


   double ma_30m_5 = iMA(sym_str,PERIOD_M30,5,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_30m_20 = iMA(sym_str,PERIOD_M30,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_30m_50 = iMA(sym_str,PERIOD_M30,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_30m_100 = iMA(sym_str,PERIOD_M30,100,0,MODE_SMMA,PRICE_CLOSE,0); 
   double ma_30m_200 = iMA(sym_str,PERIOD_M30,200,0,MODE_SMMA,PRICE_CLOSE,0);    


   double ma_h1_5 = iMA(sym_str,PERIOD_H1,5,0,MODE_SMMA,PRICE_CLOSE,0);   
   double ma_h1_20 = iMA(sym_str,PERIOD_H1,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h1_50 = iMA(sym_str,PERIOD_H1,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h1_100 = iMA(sym_str,PERIOD_H1,100,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h1_200 = iMA(sym_str,PERIOD_H1,200,0,MODE_SMMA,PRICE_CLOSE,0);
   

   double ma_h4_5 = iMA(sym_str,PERIOD_H4,5,0,MODE_SMMA,PRICE_CLOSE,0);     
   double ma_h4_20 = iMA(sym_str,PERIOD_H4,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h4_50 = iMA(sym_str,PERIOD_H4,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h4_100 = iMA(sym_str,PERIOD_H4,100,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_h4_200 = iMA(sym_str,PERIOD_H4,200,0,MODE_SMMA,PRICE_CLOSE,0);


   double ma_d_5 = iMA(sym_str,PERIOD_D1,5,0,MODE_SMMA,PRICE_CLOSE,0);   
   double ma_d_20 = iMA(sym_str,PERIOD_D1,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_d_50 = iMA(sym_str,PERIOD_D1,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_d_100 = iMA(sym_str,PERIOD_D1,100,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_d_200 = iMA(sym_str,PERIOD_D1,200,0,MODE_SMMA,PRICE_CLOSE,0);    


   double ma_w_5 = iMA(sym_str,PERIOD_W1,5,0,MODE_SMMA,PRICE_CLOSE,0);      
   double ma_w_20 = iMA(sym_str,PERIOD_W1,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_w_50 = iMA(sym_str,PERIOD_W1,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_w_100 = iMA(sym_str,PERIOD_W1,100,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_w_200 = iMA(sym_str,PERIOD_W1,200,0,MODE_SMMA,PRICE_CLOSE,0);   


   double ma_mn_5 = iMA(sym_str,PERIOD_MN1,5,0,MODE_SMMA,PRICE_CLOSE,0);      
   double ma_mn_20 = iMA(sym_str,PERIOD_MN1,20,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_mn_50 = iMA(sym_str,PERIOD_MN1,50,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_mn_100 = iMA(sym_str,PERIOD_MN1,100,0,MODE_SMMA,PRICE_CLOSE,0);
   double ma_mn_200 = iMA(sym_str,PERIOD_MN1,200,0,MODE_SMMA,PRICE_CLOSE,0);    



   indicatorData["rsi_m1"]=rsi_m1;
   indicatorData["rsi_m5"]=rsi_m5;
   indicatorData["rsi_m15"]=rsi_m15;
   indicatorData["rsi_m30"]=rsi_m30;   
   indicatorData["rsi_h1"]=rsi_h1;
   indicatorData["rsi_h4"]=rsi_h4;
   indicatorData["rsi_d"]=rsi_d;
   indicatorData["rsi_w"]=rsi_w;
   indicatorData["rsi_mn"]=rsi_mn;   

   indicatorData["atr_1m"]=atr_1m;
   indicatorData["atr_5m"]=atr_5m;
   indicatorData["atr_15m"]=atr_15m;
   indicatorData["atr_30m"]=atr_30m;
   indicatorData["atr_h1"]=atr_h1;
   indicatorData["atr_h4"]=atr_h4;
   indicatorData["atr_d"]=atr_d;
   indicatorData["atr_w"]=atr_w;
   indicatorData["atr_mn"]=atr_mn;

   indicatorData["ma_1m_5"]=ma_1m_5;
   indicatorData["ma_1m_20"]=ma_1m_20;
   indicatorData["ma_1m_50"]=ma_1m_50;
   indicatorData["ma_1m_100"]=ma_1m_100;
   indicatorData["ma_1m_200"]=ma_1m_200;   

   indicatorData["ma_5m_5"]=ma_5m_5;
   indicatorData["ma_5m_20"]=ma_5m_20;
   indicatorData["ma_5m_50"]=ma_5m_50;
   indicatorData["ma_5m_100"]=ma_5m_100;
   indicatorData["ma_5m_200"]=ma_5m_200;
  
   indicatorData["ma_15m_5"]=ma_15m_5;
   indicatorData["ma_15m_20"]=ma_15m_20;
   indicatorData["ma_15m_50"]=ma_15m_50;
   indicatorData["ma_15m_100"]=ma_15m_100;
   indicatorData["ma_15m_200"]=ma_15m_200;

   indicatorData["ma_30m_5"]=ma_30m_5;
   indicatorData["ma_30m_20"]=ma_30m_20;
   indicatorData["ma_30m_50"]=ma_30m_50;
   indicatorData["ma_30m_100"]=ma_30m_100;
   indicatorData["ma_30m_200"]=ma_30m_200;   

   indicatorData["ma_h1_5"]=ma_h1_5;
   indicatorData["ma_h1_20"]=ma_h1_20;
   indicatorData["ma_h1_50"]=ma_h1_50;
   indicatorData["ma_h1_100"]=ma_h1_100;
   indicatorData["ma_h1_200"]=ma_h1_200;

   indicatorData["ma_h4_5"]=ma_h4_5;
   indicatorData["ma_h4_20"]=ma_h4_20;
   indicatorData["ma_h4_50"]=ma_h4_50;
   indicatorData["ma_h4_100"]=ma_h4_100;
   indicatorData["ma_h4_200"]=ma_h4_200; 
 
   indicatorData["ma_d_5"]=ma_d_5;  
   indicatorData["ma_d_20"]=ma_d_20;  
   indicatorData["ma_d_50"]=ma_d_50;  
   indicatorData["ma_d_100"]=ma_d_100;  
   indicatorData["ma_d_200"]=ma_d_200; 

   indicatorData["ma_w_5"]=ma_w_5;
   indicatorData["ma_w_20"]=ma_w_20;  
   indicatorData["ma_w_50"]=ma_w_50;  
   indicatorData["ma_w_100"]=ma_w_100;  
   indicatorData["ma_w_200"]=ma_w_200; 

   indicatorData["ma_mn_5"]=ma_w_5;
   indicatorData["ma_mn_20"]=ma_w_20;  
   indicatorData["ma_mn_50"]=ma_w_50;  
   indicatorData["ma_mn_100"]=ma_w_100;  
   indicatorData["ma_mn_200"]=ma_w_200;  

   indicatorData["symbol_id"]=symbol_id;  
         
      
   return;

}