double getBid(string currency_pair) {

   MqlTick last_tick;

   if(SymbolInfoTick(currency_pair,last_tick)) {
      return last_tick.bid;
   } else { 
      log(currency_pair,"getBid","SymbolInfoTick(BID) failed , error = " + GetLastError());   
      return 0;
   }

}

double getAsk(string currency_pair) {

   MqlTick last_tick;

   if(SymbolInfoTick(currency_pair,last_tick)) {
      return last_tick.ask;
   } else { 
      log(currency_pair,"getAsk","SymbolInfoTick(ASK) failed on " + currency_pair +  ", error = " + GetLastError());   
      return 0;
   }
}

double getPoint(string currency_pair) {
   return MarketInfo(currency_pair,MODE_POINT);
}

string getSymbolNameFromMarket(string sig_symbol) {


        if (sig_symbol == "XAUUSD") {

                if (!IsSymbol(sig_symbol)) {
                    if (IsSymbol("GOLD")) {
                        return "GOLD";
                    } else {
                        Print("ERROR: " + sig_symbol + " not exists in marketwatch");
                        return NULL;
                    }
                }


        } else if (sig_symbol == "XAGUSD" ) {

                if (!IsSymbol(sig_symbol)) {
                    if (IsSymbol("SILVER")) {
                        return "SILVER";
                    } else {
                        Print("ERROR: " + sig_symbol + " not exists in marketwatch");
                        return NULL;
                    }
                }


        } 

            if (IsSymbol(sig_symbol)) {
               return sig_symbol;
            }

 

        return NULL; 

}

string findSymbolInMarketWatch (string sig_symbol) {

    int total_sym = SymbolsTotal(false);

    for (int i=0; i < total_sym; i++) {

            string symbol_name_market = SymbolName(i,false);
            string orig_symbol_name_market = symbol_name_market;

            StringToLower(symbol_name_market);

            StringToLower(sig_symbol);

            //Print(symbol_name_market + " / " + symbol_name_market);

            if (StringFind(symbol_name_market,sig_symbol) > -1) {
                  
                   //Print("Symbol " + sig_symbol + " found as: " + symbol_name_market);

                   if ((int)MarketInfo(orig_symbol_name_market,MODE_TRADEALLOWED)==1) {
                   
                        return orig_symbol_name_market; 

                   }

            }

    }





    return "none";

}

string findSymbolAltsInMarketWatch (string sig_symbol,JSONArray &symbol_alternatives) {

        int total_sym = SymbolsTotal(false);


        for (int i=0; i < total_sym; i++) {

                string symbol_name_market = SymbolName(i,false);
                string orig_symbol_name_market = symbol_name_market;
                StringToLower(symbol_name_market);    


                for(int x=0; x < symbol_alternatives.size(); x++) {  

                        string single_symbol = symbol_alternatives.getString(x);

                        StringToLower(single_symbol);

                        if (StringFind(symbol_name_market,single_symbol) > -1) {
                            //Print("Symbol2 " + single_symbol + " found as: " + symbol_name_market);

                            if ((int)MarketInfo(orig_symbol_name_market,MODE_TRADEALLOWED)==1) {
                            
                                    return orig_symbol_name_market; 

                            }                            
                        }                    


                }


        }

        return "none";

}

int getPointMultiplier(string sym_name_market,string sig_symbol_orig) {

        if (sig_symbol_orig=="0") {
            sig_symbol_orig = sym_name_market;
        }


        if (sig_symbol_orig == "XAUUSD") {


                if (getDigits(sym_name_market)==3) {
                    return 100;
                } else if (getDigits(sym_name_market)==2) {
                    return 10;
                }



        } else if (sig_symbol_orig == "XAGUSD" ) {


                if (getDigits(sym_name_market)==4) {
                    return 100;
                } else if (getDigits(sym_name_market)==3) {
                    return 10;
                }         



        }
        
         return 10;
 

}

double getDigits(string currency_pair) {
   return (int)MarketInfo(currency_pair,MODE_DIGITS);
}

bool IsSymbol(string symbol) {

    SymbolInfoDouble(symbol, SYMBOL_BID);

    int error = GetLastError() ;


    if (error == 4106) {
          return false;
    } else {
          return true;
    }

}

int getOrdersCountByOperationTypeAndSymbol (string sig_symbol, int sig_op_type) {

    int s_count=0;

    for (int v = OrdersTotal() - 1; v >= 0; v--) {

        OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

        if (sig_symbol != NULL) {
            if (OrderSymbol() != sig_symbol) continue;
        }        

        if (sig_op_type > -1) {
            if (OrderType() != sig_op_type) continue;
        }
        
        s_count++;

    }

    return s_count;
}

bool getDivergenceSymbolsAndTimeframes() {

                        CJAVal *all_data_to_be_send = new CJAVal();    

                        all_data_to_be_send["token_key"]=server_key;

                        char req_data[];              

                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 

                        delete all_data_to_be_send;


                              char response_json[];

                              int req_return_val = requestServer(req_data, "getDivergenceSymbolsAndTimeframes",response_json);


                              //Print("req_val" + req_return_val +  ", array: " + CharArrayToString(response_json));

                              if (req_return_val==0) {

                                    JSONParser *parser = new JSONParser();

                                    JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                                    delete parser;
                                    ArrayFree(response_json);

                                    JSONIterator *it = new JSONIterator(j_data_obj);
                              

                                    for( ; it.hasNext() ; it.next()) {  

                                          JSONObject *single_order = it.val();

                                          string symbol_name = getStringValFromJsonObject(single_order,"symbol");
                                          string symbol_orig = symbol_name;

                                            symbol_name = findSymbolInMarketWatch(symbol_name);

                                            

                                            bool symbol_found = false;

                                            if (symbol_name == "none") {

                                                Print("Symbol " + symbol_orig + " not found in market watch, trying alternative names if available!");


                                                JSONArray *sig_symbol_alt  = single_order.getValue("symbol_alts");

                                                if (sig_symbol_alt != NULL) {

                                                        symbol_name = findSymbolAltsInMarketWatch(symbol_name,sig_symbol_alt);

                                                        if (symbol_name == "none") {
                                                                Print("Symbol " + symbol_name + "not found in market watch, alternative also not available!");
                                                                delete sig_symbol_alt;

                                                                continue;

                                                        } else {
                                                                symbol_found = true;
                                                        }                                               
                                                } 

                                                delete sig_symbol_alt;

                                            } else {
                                                symbol_found = true;
                                            }

                                            if (symbol_found) {
                                                Print("Symbol: " + symbol_orig + " found as " + symbol_name);
                                                symbols_names_market.set(symbol_orig,symbol_name);
                                                symbols_names_orig.set(symbol_name,symbol_orig);
                                            }                                          

                                          string timeframe_name = getStringValFromJsonObject(single_order,"timeframe");

                                          int ma100_confirm = getIntValFromJsonObject(single_order,"ma100_confirm");


                                          string symbol_timeframe = symbol_name + ":" + timeframe_name;

                                          symbol_pairs.set(symbol_timeframe,ma100_confirm);



                                          delete single_order;


                                    }

                                    
                                    delete it;


                              } 

                        if (req_return_val==0) {
                                return true;            
                        } else {
                                return false;
                        }                

}


bool getSymbolsFromServer() {

                        CJAVal *all_data_to_be_send = new CJAVal();    

                        all_data_to_be_send["token_key"]="Defe33434Vsdfw324";

                        char req_data[];              

                        ArrayResize(req_data, StringToCharArray(all_data_to_be_send.Serialize(), req_data, 0, WHOLE_ARRAY)-1); 

                        delete all_data_to_be_send;


                              char response_json[];

                              int req_return_val = requestServer(req_data, "getSymbolNames",response_json);


                              //Print("req_val" + req_return_val +  ", array: " + CharArrayToString(response_json));

                              if (req_return_val==0) {

                                    JSONParser *parser = new JSONParser();

                                    JSONObject *j_data_obj  = parser.parse(CharArrayToString(response_json,0,ArraySize(response_json),CP_OEMCP) );

                                    delete parser;
                                    ArrayFree(response_json);

                                    JSONIterator *it = new JSONIterator(j_data_obj);
                              

                                    for( ; it.hasNext() ; it.next()) {  

                                            JSONObject *single_order = it.val();

                                            string symbol_name = getStringValFromJsonObject(single_order,"symbol");

                                            string symbol_orig = symbol_name;

                                            symbol_name = findSymbolInMarketWatch(symbol_name);

                                            bool symbol_found = false;

                                            if (symbol_name == "none") {

                                                Print("Symbol " + symbol_orig + " not found in market watch, trying alternative names if available!");


                                                JSONArray *sig_symbol_alt  = single_order.getValue("symbol_alts");

                                                if (sig_symbol_alt != NULL) {

                                                        symbol_name = findSymbolAltsInMarketWatch(symbol_name,sig_symbol_alt);

                                                        if (symbol_name == "none") {
                                                                Print("Symbol " + symbol_name + "not found in market watch, alternative also not available!");
                                                                delete sig_symbol_alt;

                                                                continue;

                                                        } else {
                                                                symbol_found = true;
                                                                Print("Symbol " + symbol_orig  + " found as "  + symbol_name + " in market watch! ");
                                                        }                                               
                                                } 

                                                delete sig_symbol_alt;

                                            } else {
                                                symbol_found = true;
                                            }

                                            if (symbol_found) {
                                                symbols_names_market.set(symbol_orig,symbol_name);
                                                symbols_names_orig.set(symbol_name,symbol_orig);
                                            }

                                          //findSymbolInMarketWatch(symbol_name)



                                          //symbols_names_market.set()

                                          delete single_order;


                                    }

                                    
                                    delete it;


                              } 

                        if (req_return_val==0) {
                                return true;            
                        } else {
                                return false;
                        }                

}

void setupTimeframes() {

            timeframes_t.set("M1",PERIOD_M1);
            timeframes_t.set("M5",PERIOD_M5);
            timeframes_t.set("M15",PERIOD_M15);
            timeframes_t.set("M30",PERIOD_M30);
            timeframes_t.set("H1",PERIOD_H1);
            timeframes_t.set("H4",PERIOD_H4);
            timeframes_t.set("D1",PERIOD_D1);
            timeframes_t.set("W1",PERIOD_W1);
            timeframes_t.set("MN1",PERIOD_MN1);
        
}

string timeframeToString (int tf_val) {

    foreachm(string,keytf,int,valuetf,timeframes_t) {

        if (valuetf==tf_val) return keytf;

    }
    return NULL;
}


string getSymbolMarketName (string orig_name) {

    foreachm(string,keytf,string,valuetf,symbols_names_market) {

        if (keytf==orig_name) return valuetf;

    }
    return NULL;

}

string getSymbolOrigName (string market_name) {

    foreachm(string,keytf,string,valuetf,symbols_names_orig) {



        if (keytf==market_name) { 

            Print("Symbol2 of " + market_name + " found as " + valuetf + " keytf=" + keytf);


            return valuetf;
        }

    }
    return NULL;
    
}