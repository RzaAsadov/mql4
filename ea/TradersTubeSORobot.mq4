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


extern string server_key = "dsadasewr23452323ASFDSR32432fsacQWfasfds";
extern string Server_Host = "api-ea-v1.fortfinance.ee";
extern int magic_number = 19841995;
extern double RISK_VALUE = 0.0;
extern double RISK_SIZE = 5.0;
extern int NEXT_ORDER_MULTIPLIER = 30;
extern int CUR_SL = 40;
extern int CUR_TP = 20;
extern int point_multiplier = 10;
extern bool verbose = false;

bool is_initilized = false;
bool first_connection_to_server = true;

int ServerFailTriesToReport = 10;
int ServerRequestTimeoutMs = 10000;
bool silentMode = true;

extern bool isDebug = false;

HashMap<string,int>*symbol_pairs = new HashMap<string,int>();

HashMap<string,string>*symbols_names_market = new HashMap<string,string>();
HashMap<string,string>*symbols_names_orig = new HashMap<string,string>();

HashMap<string,int>*timeframes_t = new HashMap<string,int>();

int CUR_DIR = -1;

double current_lots;


double LAST_SIGNAL_ID = 0.0;





int OnInit() {

    if (is_initilized) return(INIT_SUCCEEDED); // Prevent from double init. 

    Print("Init starting!");

    GlobalVariablesDeleteAll();


    Print("Init successful!");

    is_initilized = true;  

    current_lots = RISK_SIZE;


    return(INIT_SUCCEEDED);   

}


void OnDeinit(const int reason) {

    //EventKillTimer();

}

void OnTick() {

        doWork();

}


void doWork() {




        double val_up=iCustom(NULL,Period(),"TradersTubeScalperOne",0,2);
        double val_down=iCustom(NULL,Period(),"TradersTubeScalperOne",1,3);
 



        double candle_open_price = iOpen(NULL,Period(),1);


          


        /// OPEN ORDERS

        // OPEN BUY
        if (val_up != EMPTY_VALUE) {

            if (getOrderTicket(OP_BUY,Symbol(),magic_number)==-1) {

                RefreshRates();                

                int prev_order_ticket = getOrderTicket(OP_SELL,Symbol(),magic_number);

                if (prev_order_ticket > -1) {

                        double prev_order_lots = getOrderLots(OP_SELL,Symbol(),magic_number);
                        if (!OrderClose(prev_order_ticket,prev_order_lots,Bid,20,Blue)) {
                                return;
                        }

                }


                double sl_in_pips = CUR_SL;


                double sig_sl = NormalizeDouble(Ask - (sl_in_pips * point_multiplier * Point),Digits); 
                double sig_tp = NormalizeDouble(Ask + (CUR_TP * point_multiplier * Point),Digits); 

                double t_risk_size = 0.0; 

                double last_profit = getLastOrderProfit();


                
                if (RISK_SIZE == 0.0) {
                    t_risk_size = NormalizeDouble(calculateLotRiskSize(Symbol(),sl_in_pips,RISK_VALUE,point_multiplier),2);
                } else {
                    t_risk_size = RISK_SIZE;
                }


                if (last_profit < 0) {
                    t_risk_size = NormalizeDouble(t_risk_size + ((t_risk_size / 100) * NEXT_ORDER_MULTIPLIER),2);
                } else {
                    t_risk_size = current_lots;
                }



                ResetLastError();

                if (t_risk_size > 0) { 

                    int order_ticket_number = OrderSend(Symbol(), OP_BUY, t_risk_size, Ask, 10,sig_sl, sig_tp, "", magic_number, 0, clrNONE);

                    Print("Last order profit: " + last_profit);



                    if (order_ticket_number < 0 ) {
                        Print("OrderSend error " + GetLastError() + " BUY at " + Ask + " Lot:" + t_risk_size + " SL: " + sig_sl);
                    } else {
                        LAST_SIGNAL_ID = order_ticket_number;
                    }

                }

            } else {
                if (verbose) Print("SELL Order already exists, nothing to do!");
            }
        }

        // OPEN SELL
        if (val_down != EMPTY_VALUE) {
            if (getOrderTicket(OP_SELL,Symbol(),magic_number)==-1) {

                RefreshRates();                

                int prev_order_ticket = getOrderTicket(OP_BUY,Symbol(),magic_number);

                if (prev_order_ticket > -1) {

                        double prev_order_lots = getOrderLots(OP_BUY,Symbol(),magic_number);
                        if (!OrderClose(prev_order_ticket,prev_order_lots,Bid,20,Blue)) {
                            return;
                        }

                }


                

                double sl_in_pips = CUR_SL;

                double sig_sl = NormalizeDouble(Bid + (sl_in_pips * point_multiplier * Point),Digits); 
                double sig_tp = NormalizeDouble(Bid - (CUR_TP * point_multiplier * Point),Digits); 

                double t_risk_size = 0.0; 

                double last_profit = getLastOrderProfit();
                
                if (RISK_SIZE == 0.0) {
                    t_risk_size = NormalizeDouble(calculateLotRiskSize(Symbol(),sl_in_pips,RISK_VALUE,point_multiplier),2);
                } else {
                    t_risk_size = RISK_SIZE;
                }

                if (last_profit < 0) {
                    t_risk_size = NormalizeDouble(t_risk_size + ((t_risk_size / 100) * NEXT_ORDER_MULTIPLIER),2);
                } else {
                    t_risk_size = current_lots;
                }            


                RefreshRates();

                if (t_risk_size > 0 ) {

                    int order_ticket_number = OrderSend(Symbol(), OP_SELL, t_risk_size, Bid, 10,sig_sl, sig_tp, "", magic_number, 0, clrNONE);

                    Print("Last order profit: " + last_profit);


                    if (order_ticket_number < 0) {
                        Print("OrderSend error " + GetLastError() + " SELL at " + Bid + " Lot: " + t_risk_size + " SL: " + NormalizeDouble(sig_sl,Digits));
                    } else {
                        LAST_SIGNAL_ID = order_ticket_number;
                    }

                }

            } else {
                if (verbose) Print("SELL Order already exists, nothing to do!");
            }          
        }




}


int getOrderTicket(int sig_op_type,string sig_symbol,int magic_number) {



         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                  if (OrderType()==sig_op_type) {
                        if (OrderSymbol()==sig_symbol) {
                            
                            if (OrderMagicNumber()==magic_number) {
                                    return OrderTicket();
                            }
                        }
                  }

         }

         return -1;

}

double getOrderLots(int sig_op_type,string  sig_symbol,int magic_number) {


         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                  if (OrderType()==sig_op_type) {
                        if (OrderSymbol()==sig_symbol) {
                            
                            if (OrderMagicNumber()==magic_number) {
                                    return OrderLots();
                            }
                        }
                  }
         }

         return -1;

}

  double getLastOrderProfit() {

    if(OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY) ) {
        return OrderProfit();
    }
        return 123456789;
  }

void checkAndCloseOnExitSignal(double val_down_tp,double val_up_tp) {

        //// CLOSE ON TP

        // CLOSE BUY

        if (val_down_tp != EMPTY_VALUE) {

            int order_ticket = getOrderTicket(OP_BUY,Symbol(),magic_number);
            double order_lots = getOrderLots(OP_BUY,Symbol(),magic_number);

            CUR_DIR = -1;

            if (order_ticket==-1) {
                //Print("BUY Order not exists, nothing to close...");
            } else {
                if (verbose) Print("BUY Order found, closing on TP....");

                if (OrderClose(order_ticket,order_lots,Bid,20,Blue)) {
                    Print("Successfully closed BUY on TP");
                }               
            }
        }

        // CLOSE SELL
        if (val_up_tp != EMPTY_VALUE) {

            RefreshRates();

            int order_ticket = getOrderTicket(OP_SELL,Symbol(),magic_number);
            double order_lots = getOrderLots(OP_SELL,Symbol(),magic_number);

            CUR_DIR = -1;
            

            if (order_ticket==-1) {
                //Print("SELL Order not exists, nothing to close...");
            } else {
                if (verbose) Print("SELL Order found, closing on TP....");

                if (OrderClose(order_ticket,order_lots,Ask,20,Blue)) {
                    Print("Successfully closed SELL on TP");
                }
            }            
        }


}



double calculateLotRiskSize( string symbol,double riskPoints,double MaxRiskPerTrade, double point_multiplier ) {

   double tickSize      = MarketInfo( symbol, MODE_TICKSIZE );
   double tickValue     = MarketInfo( symbol, MODE_TICKVALUE );

   double point         = MarketInfo( symbol, MODE_POINT );


    int vdigits = (int)MarketInfo(symbol,MODE_DIGITS);

        /*if (( vdigits == 3) || (vdigits == 5)){
            tickValue = tickValue * 10;
        } */   

    //PrintFormat( "tickSize=%f, tickValue=%f, point=%f",tickSize, tickValue, point );

    double ticksPerPoint = tickSize / point;
    double pointValue    = tickValue / ticksPerPoint;

    //PrintFormat( "ticksPerPoint=%f, pointValue=%f",ticksPerPoint, pointValue );

    double account_balance = AccountBalance();

    
    double riskAmount = (AccountBalance() * MaxRiskPerTrade/ 100);
    riskPoints = riskPoints * point_multiplier;


    double riskLots   = riskAmount / ( pointValue * riskPoints );

    if (verbose) Print("Symbol=" + symbol + ", Risk SL=" + riskPoints + " , Risk Amount="  + riskAmount + " Lots=" + riskLots );


    return riskLots;

}
