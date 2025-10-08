#include "../../libs/Mql/Collection/HashMap.mqh"
#include "../../libs/Mql/Collection/LinkedList.mqh"
#include "../../libs/Mql/Format/Json.mqh"
#include "../../libs/hash.mqh"
#include "../../libs/json.mqh"
#include "../../libs/JAson.mqh"
#include "../../Strings/String.mqh"

////////////////////////////////////////// DD Calculator /////////////////////////////////////////




CJAVal *getDrawDownData (string serverKey) {

      bool send_calculated_result = false;

      if (seconds_passed_dd_sender == 0) {
            // Send calculated data
            send_calculated_result = true;
      } else {
            // Do send calculated data till period passed
             send_calculated_result = false;
      }

      if (seconds_passed_dd_sender >= Calculated_data_period) {
            seconds_passed_dd_sender=0;
      } else {
            seconds_passed_dd_sender++;
      }
     

      CJAVal *j_main = new CJAVal();
      CJAVal *total_orders = new CJAVal();

      HashMap<string,double>*trade_totalSymbolsBuyDD = new HashMap<string,double>();
      HashMap<string,double>*trade_totalSymbolsSellDD = new HashMap<string,double>();

      HashMap<string,double>*trade_totalSymbolsBuySwap = new HashMap<string,double>();
      HashMap<string,double>*trade_totalSymbolsSellSwap = new HashMap<string,double>();

      HashMap<string,double>*trade_totalSymbolsBuyCommision = new HashMap<string,double>();
      HashMap<string,double>*trade_totalSymbolsSellCommision = new HashMap<string,double>();

      HashMap<string,double>*trade_totalSymbolsBuyLots = new HashMap<string,double>();
      HashMap<string,double>*trade_totalSymbolsSellLots = new HashMap<string,double>();

      HashMap<string,int>*trade_totalSymbolsBuyOpCount = new HashMap<string,int>();
      HashMap<string,int>*trade_totalSymbolsSellOpCount = new HashMap<string,int>();   


            /////////////// for debug /////////////////////
            /*if (isDebug) {

                  CJAVal *order_details1 = new CJAVal();


                  order_details1["OrderTicket"] = "10000100";
                  order_details1["OrderOpenTime"] = "2022-06-05 22:00:10.838";
                  order_details1["OrderSymbol"] = "EURUSD"; 

                  if (order_details1["OrderSymbol"]=="GOLD") {
                        order_details1["OrderSymbol"]=="XAUUSD"; 
                  } else if (order_details1["OrderSymbol"]=="SILVER") {
                        order_details1["OrderSymbol"]=="XAGUSD"; 
                  }            

                  order_details1["OrderOperationType"] = 1; 
                  order_details1["OrderLots"] = 0.10;          
                  order_details1["OrderOpenPrice"] = 1.12456;
                  order_details1["OrderProfit"] = 28.8;            
                  order_details1["OrderSwap"] = 0;
                  order_details1["OrderCommission"] = 0;
                  order_details1["OrderComment"] = 0;
                  order_details1["OrderTakeProfit"] = 1.13444;
                  order_details1["OrderStopLoss"] = 1.11345;

                  total_orders[0].Set(order_details1);

                  delete order_details1;

            }*/
            //////////////////////////////////////////////  


      for(int i=OrdersTotal()-1;i>=0;i--) {

            CJAVal *order_details = new CJAVal();

            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);


            order_details["OrderTicket"] = OrderTicket();
            order_details["OrderOpenTime"] = TimeToStr(OrderOpenTime(),TIME_DATE|TIME_SECONDS);


            string sym_orig_name = getSymbolOrigName(OrderSymbol());

            
            order_details["OrderSymbol"] = sym_orig_name; 

            order_details["OrderOperationType"] = OrderType(); 
            order_details["OrderLots"] = OrderLots();          
            order_details["OrderOpenPrice"] = OrderOpenPrice();
            order_details["OrderProfit"] = OrderProfit();            
            order_details["OrderSwap"] = OrderSwap();
            order_details["OrderCommission"] = OrderCommission();
            order_details["OrderComment"] = OrderComment();
            order_details["OrderTakeProfit"] = OrderTakeProfit();
            order_details["OrderStopLoss"] = OrderStopLoss();

            /*if (!isDebug) { // do not send real drawdown if in debug mode
                  total_orders[i].Set(order_details); 
            } */ 
            
            total_orders[i].Set(order_details); 

            delete order_details;

            if (!send_calculated_result) continue;

                  if (OrderType()==OP_BUY) {

                        double t_dd = trade_totalSymbolsBuyDD.get(OrderSymbol(),0);
                        t_dd = t_dd + OrderProfit();
                        trade_totalSymbolsBuyDD.set(OrderSymbol(),t_dd);

                        double t_swap = trade_totalSymbolsBuySwap.get(OrderSymbol(),0);
                        t_swap = t_swap + OrderSwap();
                        trade_totalSymbolsBuySwap.set(OrderSymbol(),t_swap);

                        double t_comm = trade_totalSymbolsBuyCommision.get(OrderSymbol(),0);
                        t_comm = t_comm + OrderCommission();
                        trade_totalSymbolsBuyCommision.set(OrderSymbol(),t_comm);  

                        double t_lots = trade_totalSymbolsBuyLots.get(OrderSymbol(),0);
                        t_lots = t_lots + OrderLots();
                        trade_totalSymbolsBuyLots.set(OrderSymbol(),t_lots);  

                        double t_ops = trade_totalSymbolsBuyOpCount.get(OrderSymbol(),0);
                        t_ops = t_ops + 1;
                        trade_totalSymbolsBuyOpCount.set(OrderSymbol(),t_ops);                                            

                  } else if (OrderType()==OP_SELL) {

                        double t_dd = trade_totalSymbolsSellDD.get(OrderSymbol(),0);
                        t_dd = t_dd + OrderProfit();
                        trade_totalSymbolsSellDD.set(OrderSymbol(),t_dd);

                        double t_swap = trade_totalSymbolsSellSwap.get(OrderSymbol(),0);
                        t_swap = t_swap + OrderSwap();
                        trade_totalSymbolsSellSwap.set(OrderSymbol(),t_swap);   

                        double t_comm = trade_totalSymbolsSellCommision.get(OrderSymbol(),0);
                        t_comm = t_comm + OrderCommission();
                        trade_totalSymbolsSellCommision.set(OrderSymbol(),t_comm);  

                        double t_lots = trade_totalSymbolsSellLots.get(OrderSymbol(),0);
                        t_lots = t_lots + OrderLots();
                        trade_totalSymbolsSellLots.set(OrderSymbol(),t_lots);

                        double t_ops = trade_totalSymbolsSellOpCount.get(OrderSymbol(),0);
                        t_ops = t_ops + 1;
                        trade_totalSymbolsSellOpCount.set(OrderSymbol(),t_ops);                                                                     

                  }
      }


      if (send_calculated_result) {

                  CJAVal *buy_details = new CJAVal();
                  CJAVal *sell_details = new CJAVal();

                  foreachm(string,key,double,value,trade_totalSymbolsBuyDD) {

                        CJAVal *dd_details = new CJAVal();

                        dd_details["dd"]= trade_totalSymbolsBuyDD.get(key,0);
                        dd_details["swap"]= trade_totalSymbolsBuySwap.get(key,0);
                        dd_details["comm"]= trade_totalSymbolsBuyCommision.get(key,0);
                        dd_details["lots"]= trade_totalSymbolsSellLots.get(key,0);         
                        dd_details["ops"]= trade_totalSymbolsSellOpCount.get(key,0);

                        buy_details[key].Set(dd_details);

                        delete dd_details;
            
                  }

                       

                  foreachm(string,key,double,value,trade_totalSymbolsSellDD) {

                        CJAVal *dd_details = new CJAVal();

                        dd_details["dd"]= trade_totalSymbolsSellDD.get(key,0);
                        dd_details["swap"]= trade_totalSymbolsSellSwap.get(key,0);
                        dd_details["comm"]= trade_totalSymbolsSellCommision.get(key,0);
                        dd_details["lots"]= trade_totalSymbolsSellLots.get(key,0);            
                        dd_details["ops"]= trade_totalSymbolsSellOpCount.get(key,0); 

                        sell_details[key].Set(dd_details);

                        delete dd_details;
            
                  }      


            if (buy_details.Size() > 0)
                  j_main["buy"].Set(buy_details);
            
            if (sell_details.Size() > 0)
                  j_main["sell"].Set(sell_details);


            delete buy_details;
            delete sell_details;            
      }

      delete trade_totalSymbolsBuyDD;
      delete trade_totalSymbolsBuySwap;
      delete trade_totalSymbolsBuyCommision;
      delete trade_totalSymbolsBuyLots;
      delete trade_totalSymbolsBuyOpCount;  

      delete trade_totalSymbolsSellDD;
      delete trade_totalSymbolsSellSwap;
      delete trade_totalSymbolsSellCommision;
      delete trade_totalSymbolsSellLots;
      delete trade_totalSymbolsSellOpCount;      


      j_main["tok_key"]=serverKey;   
      j_main["acct_id"]=account_id;

      if (total_orders.Size() > 0)   
            j_main["orders"].Set(total_orders);

      string server_time = TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
      StringReplace(server_time,".","-");

      j_main["server_time"]=server_time;



      //string result = j_main.Serialize();      
      //ArrayResize(dd_data, StringToCharArray(result, dd_data, 0, WHOLE_ARRAY)-1);

      delete total_orders;
      //delete j_main;

      return j_main;


}
//////////////////////////////////////////////////////////////////////////////////////////////////

