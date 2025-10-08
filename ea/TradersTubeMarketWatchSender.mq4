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

extern string Key="Defe33434Vsdfw324";
extern string Server_Host = "api-ea-v1.netondo.io";

extern int ServerFailTriesToReport = 10;

extern int ServerRequestTimeoutMs = 10000;

extern bool isDebug = false;
extern bool silentMode = true;

extern string main_log_filename = "";


string ea_name = "";

bool first_connection_to_server = true;



HashMap<string,int>*symbols = new HashMap<string,int>();

int cccc=0;



int OnInit() {

      EventSetMillisecondTimer(100);

      ea_name = WindowExpertName();

      if (main_log_filename == "") {
            main_log_filename = ea_name + ".log";
      }      

      /*if (isDebug) {
            FileDelete(request_log_filename);
            FileDelete(response_log_filename);
            FileDelete(main_log_filename);
      } */    
   

      return(INIT_SUCCEEDED);

}


void OnDeinit(const int reason) {

   EventKillTimer();
   
}

void OnTick() {

}

void OnTimer() {



    CJAVal *collectedPrices = new CJAVal(); 

    //Print("1 " + collectedPrices.Size());
    
    collectPrices(symbols,collectedPrices);

    delete symbols;

    symbols = new HashMap<string,int>();

    CJAVal *requestJsonObj = new CJAVal();

    requestJsonObj["tok_key"] = Key;
    requestJsonObj["prices"].Set(collectedPrices);



      string result = requestJsonObj.Serialize();

      delete collectedPrices;
      delete requestJsonObj;



      char req_data[];


      ArrayResize(req_data, StringToCharArray(result, req_data, 0, WHOLE_ARRAY)-1); 

            char response_json[];

            int req_return_val = requestServer(req_data, "setMarketWatch",response_json);

           if (req_return_val==0) {

                  JSONParser *parser = new JSONParser();

                  JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                  delete parser;            
      
                  updateSymbolList(j_data_obj,symbols);

                  delete j_data_obj;                   

            }




            ArrayFree(req_data);
            ArrayFree(response_json);                          


}

void updateSymbolList(JSONObject &param_obj,HashMap<string,int> &symbol_pairs) {


            symbol_pairs.clear();


            JSONIterator *it = new JSONIterator(&param_obj);

            if (it == NULL)  { delete it; return; };
      

            for( ; it.hasNext() ; it.next()) {  

                 string symbol_name = it.key();

                 JSONValue *single_order = it.val();
                 
                 symbol_pairs.set(symbol_name,single_order.getInt());

                 delete single_order;

            }



            delete it;

}



void collectPrices(HashMap<string,int> &symbol_pairs,CJAVal &all_prices) {


       if (symbol_pairs.isEmpty()) return;

       int y=symbol_pairs.size()-1;

       foreachm(string,key,int,value,symbol_pairs) {



            CJAVal *symbolPrice = new CJAVal(); // to be deleted

                RefreshRates();

                double askPrice = getAsk(key);   
                double bidPrice = getBid(key);

                double digits = getDigits(key);

                symbolPrice["ask"]=askPrice;
                symbolPrice["bid"]=bidPrice;
                symbolPrice["digits"]=digits;
                symbolPrice["symbol_id"]=value;


            all_prices[y].Set(symbolPrice);

            y--;

            delete symbolPrice;                                            

       }



    
}


