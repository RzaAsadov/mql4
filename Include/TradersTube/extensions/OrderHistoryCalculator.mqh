#include "../../libs/Mql/Collection/HashMap.mqh"
#include "../../libs/Mql/Collection/LinkedList.mqh"
#include "../../libs/Mql/Format/Json.mqh"
#include "../../libs/hash.mqh"
#include "../../libs/json.mqh"
#include "../../libs/JAson.mqh"
#include "../../Strings/String.mqh"



CJAVal *getOrdersHistory (string serverKey, int from_pos) {

      if (from_pos == -1) return NULL;
   

      int send_limit_per_session=100;


      int total_his=OrdersHistoryTotal();


      
      int history_to_fetch = 0;   

      if ( (total_his-from_pos) > send_limit_per_session) { 
          history_to_fetch = from_pos + send_limit_per_session;
      } else {
          history_to_fetch = total_his;
      }

     if (from_pos==total_his) {
         return NULL;
     }

      if (isDebug) Print("Fetching from: " + from_pos + " total is: " + total_his );

      CJAVal *total_orders = new CJAVal();

      int x=0;

      int last_ticket = 0;


      if (total_his > 0) {
            OrderSelect(total_his-1,SELECT_BY_POS,MODE_HISTORY);
            last_ticket = OrderTicket();
      } 


      for(int i=from_pos; i < history_to_fetch; i++) {

            CJAVal *order_details = new CJAVal();

            OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);


            int pips_value = 0; 

            int point_multiplier = getPointMultiplier(OrderSymbol(),"0");
            
            
            if (OrderType()==OP_BUY) {
                pips_value = (OrderClosePrice() - OrderOpenPrice()) * point_multiplier * getPoint(OrderSymbol());
            } else if (OrderType()==OP_SELL) {
                pips_value = (OrderOpenPrice() - OrderClosePrice()) * point_multiplier * getPoint(OrderSymbol());
            }



            order_details["OrderTicket"]= OrderTicket();
            order_details["OrderOpenTime"] = "" + OrderOpenTime();
            order_details["OrderCloseTime"] = "" + OrderCloseTime();
            order_details["OrderSymbol"]= getSymbolOrigName(OrderSymbol()); 
            order_details["OrderOperationType"] = OrderType();  
            order_details["OrderLots"]= OrderLots();          
            order_details["OrderOpenPrice"]= OrderOpenPrice();
            order_details["OrderClosePrice"]= OrderClosePrice();
            order_details["OrderProfit"]= OrderProfit();  
            order_details["OrderPipsValue"]=pips_value;      
            order_details["OrderSwap"]= OrderSwap();
            order_details["OrderCommission"]= OrderCommission();
            order_details["OrderComment"]= OrderComment();

            total_orders[x].Set(order_details); 

            x++;  

            delete order_details;

      }
     

            CJAVal *j_main = new CJAVal();

            j_main["tok_key"]=serverKey;
            j_main["acct_id"]=account_id;
            j_main["ordershistory"].Set(total_orders);
            j_main["last_ticket"]=last_ticket;
            j_main["total_history_count"]=total_his;
            j_main["from_pos"]=from_pos;
            j_main["history_to_fetch"]=history_to_fetch;


            delete total_orders;

      return j_main;


}


bool isAllHistoryEnabled() {

      int total_his=OrdersHistoryTotal();


      bool balance_order_found = false;

      for(int i=0; i < total_his; i++) {

            OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);

            if (OrderType()==6) balance_order_found = true;

      }

      return balance_order_found;

}
//////////////////////////////////////////////////////////////////////////////////////////////////

