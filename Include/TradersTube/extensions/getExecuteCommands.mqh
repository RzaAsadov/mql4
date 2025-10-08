void getAndExecuteOrders(JSONObject *param_obj) {


                                    JSONIterator *it = new JSONIterator(param_obj);

                                    for( ; it.hasNext() ; it.next()) {  
                          

                                          string symbol_name = it.key();

                                          JSONObject *single_order = it.val();

                                          string sig_symbol = getStringValFromJsonObject(single_order,"sig_symbol");



                                          if (sig_symbol=="lucrum") {

                                                    string result = getStringValFromJsonObject(single_order,"result");

                                                    if (result == "wrong_account_id") {
                                                        MessageBox("Wrong account ID !","ERROR");
                                                        ExpertRemove();
                                                        return;
                                                    }

                                                    delete single_order;
        
                                                    continue;

                                          }


                                          sig_symbol = getSymbolMarketName(sig_symbol);




                                          int sig_op_type = getIntValFromJsonObject(single_order,"sig_op_type");
                                          int sig_status = getIntValFromJsonObject(single_order,"sig_status");


                                          double sig_tp = getDoubleValFromJsonObject(single_order,"sig_tp");
                                          double sig_sl = getDoubleValFromJsonObject(single_order,"sig_sl");
                                          int sig_half_close_on = getIntValFromJsonObject(single_order,"sig_half_close_on");
                                          int sig_open_multiple = getIntValFromJsonObject(single_order,"sig_open_multiple");
                                          int sig_close_opposite = getIntValFromJsonObject(single_order,"sig_close_opposite");



                                          string sig_comment = getStringValFromJsonObject(single_order,"sig_comments");
                                          string sig_main_comment = getStringValFromJsonObject(single_order,"sig_main_comment");
                                          
                                          if (isDebug) Print("NewOrder 1 ( symbol=" + sig_symbol + ", sl=" + sig_sl + ", tp=" + ", status=" + sig_status  + ", oper=" + sig_op_type + " )");


                                          if (StringFind(sig_comment,"-") > 0 ) {


                                                if (sig_status==0) {

                                                      string sig_risk = getStringValFromJsonObject(single_order,"sig_lots");
                                                      int sig_def_tp = StringToInteger(getStringValFromJsonObject(single_order,"sig_def_tp"));
                                                      int sig_def_sl = StringToInteger(getStringValFromJsonObject(single_order,"sig_def_sl"));
                                                      double deposit_size = getIntValFromJsonObject(single_order,"deposit_size");


                                                      double sig_openprice = getDoubleValFromJsonObject(single_order,"sl_openprice");

                                                      if (emulateTradeOperations) {
                                                            SendNotification("NewOrder ( symbol=" + sig_symbol + ", lot=" + sig_risk + ", sl=" + sig_sl + ", tp=" + sig_tp + ", oper=" + sig_op_type + " )\r\n");
                                                      } else {

                                                            newSingleOrder(sig_comment,sig_main_comment,sig_op_type,sig_symbol,sig_tp,sig_sl,sig_half_close_on,sig_open_multiple,sig_close_opposite,sig_def_tp,sig_def_sl,sig_status,sig_risk,sig_openprice,deposit_size);
                                                      }

                                                } else if (sig_status==2 || sig_status==10) {
                                                        int sig_ticket = getIntValFromJsonObject(single_order,"sig_ticket");

                                                      if (emulateTradeOperations) {
                                                            SendNotification("OrderClose ( ticket=" + sig_ticket + ", oper=" + sig_op_type + ", close_full " + " )\r\n");
                                                      } else {
                                                            closeOrder(sig_ticket,sig_op_type,CLOSE_FULL,0);
                                                      }
                                                } else if (sig_status==3) {
                                                        int sig_ticket = getIntValFromJsonObject(single_order,"sig_ticket");

                                                        if (emulateTradeOperations) {
                                                            SendNotification("OrderClose ( ticket=" + sig_ticket + ", oper=" + sig_op_type + ", close_partial " + " )\r\n");
                                                        } else {
                                                            closeOrder(sig_ticket,sig_op_type,CLOSE_PARTIAL,50);
                                                        }
                                                }


                                          } else {
                                                
                                          }

                                          delete single_order;

                                    }

                                    delete it;

}



void newSingleOrder(string sig_comment,string sig_main_comment,int sig_op_type,string sig_symbol,double sig_tp,double sig_sl,int sig_half_close_on,int sig_open_multiple,int sig_close_opposite,int sig_def_tp,int sig_def_sl,int sig_status,string sig_risk_size,double sig_entry,double deposit_size) {


        bool operation_found=false;


        // For divergence robot orders
        if (sig_op_type == 6 || sig_op_type == 7)  {
            sig_op_type = 0;
        } else if (sig_op_type == 8 || sig_op_type == 9) {
            sig_op_type = 1;    
        }
        ////   

        // Here we need original symbol name from server

        string sig_symbol_orig = sig_symbol;

        sig_symbol = getSymbolNameFromMarket(sig_symbol);

        int point_multiplier = getPointMultiplier(sig_symbol,sig_symbol_orig);


         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                  if (OrderType()==sig_op_type) {
                        if (OrderSymbol()==sig_symbol) {


                              if (OrderComment()==sig_comment) {
                                    operation_found=true;
                                    // Change tp or sl



                                    if (OrderStopLoss() > 0 && (sig_sl == 0 || sig_sl > 20000000)) sig_sl = OrderStopLoss();
                                    if (OrderTakeProfit() > 0 && sig_tp == 0) sig_tp = OrderTakeProfit(); 

                                    if (OrderTakeProfit()!=sig_tp || OrderStopLoss()!=sig_sl) { // Modify order


                                    if (sig_op_type==OP_BUY) {

                                        if (addPipsToSL > 0) {
                                            sig_sl = sig_sl - (addPipsToSL * point_multiplier * getPoint(sig_symbol)); 
                                        }
                                              
                                    } else if (sig_op_type==OP_SELL) {

                                        if (addPipsToSL > 0) {
                                            sig_sl = sig_sl + (addPipsToSL * point_multiplier * getPoint(sig_symbol));   
                                        }
                                    }                                

                                          if ( ! OrderModify(OrderTicket(), sig_entry, sig_sl, sig_tp, 0, 0) ) {

                                          }

                                          int last_error = GetLastError();

                                          if (last_error == 0/* NO_ERROR */) {
                                                Print("Can not modify tp or sl on " + sig_symbol + ", ticket=" + OrderTicket() + ", last_error=" + last_error);
                                          } else {
                                                Print("Can not modify tp to " + sig_tp + " or sl to " + sig_sl + " on " + sig_symbol + ", ticket=" + OrderTicket() + ", error=" + last_error);
                                          }

                                    }



                              }  
                        }
                  }
               
         } 

         // Send new order if no operation found
         if (operation_found==false) {

              if (!IsSymbol(sig_symbol)) { 
                Print("Symbol " + sig_symbol + " not found in marketwatch");
                return;
              }


              if (sig_open_multiple == 0) {
                  if (findAlreadyOpenedOrder(sig_symbol,sig_op_type)) {
                    if (isDebug) Print("Order for " + sig_symbol + " already exists, do not need to open because multiple openning disabled!");
                    return;
                  }
                  if (findAlreadyClosedOrder(sig_symbol,sig_op_type,sig_comment)) {
                    if (isDebug) Print("Order for " + sig_symbol + " already closed in history, do not need to open!");
                    return;
                  }                  
              }

              Print("Close oposite value: " + sig_close_opposite);
              if (sig_close_opposite == 1) {
                    findAndCloseOppositeOrder(sig_symbol,sig_op_type);
              }


              Print("NEW ORDER, Symbol: " + sig_symbol + ", SL=" + sig_sl + ", SIG_DEF_SL=" + sig_def_sl + ", OP_TYPE=" + sig_op_type);



               RefreshRates();

               double cur_price = 0.0;
               double sl_in_pips = 0.0;

               if (sig_op_type==OP_BUY) {

                    cur_price  = getAsk(sig_symbol);


                        if (sig_sl == 0) {

                            if (sig_def_sl == -1) {

                                double atr_value = 0.0;

                                if (StringFind(OrderComment(),"31-")) {
                                    atr_value = iATR(sig_symbol,PERIOD_H1,3,0);
                                } else if (StringFind(OrderComment(),"34-")) {
                                    atr_value = iATR(sig_symbol,PERIOD_H4,3,0);
                                } else {
                                    atr_value = iATR(sig_symbol,PERIOD_H4,3,0);
                                }


                                sig_sl = cur_price - (atr_value * 4);
                            } else {
                                sig_sl = cur_price - ((sig_def_sl+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                            }
                        } else if (sig_sl > 20000000) {
                                sig_sl = sig_sl - 20000000;
                                sig_sl = cur_price - (((sig_sl)+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                        } else {
                                if (addPipsToSL > 0)
                                    sig_sl = sig_sl - (addPipsToSL * point_multiplier * getPoint(sig_symbol));
                        }

                        if (sig_tp == 0) {
                                sig_tp = cur_price + (sig_def_tp * point_multiplier * getPoint(sig_symbol));
                        }

                        sl_in_pips = ((cur_price - sig_sl) / point_multiplier) / getPoint(sig_symbol);


               } else if (sig_op_type==OP_SELL) {

                  cur_price  = getBid(sig_symbol);

                        if (sig_sl == 0) {

                            if (sig_def_sl == -1) {

                                double atr_value = 0.0;

                                if (StringFind(OrderComment(),"31-")) {
                                    atr_value = iATR(sig_symbol,PERIOD_H1,3,0);
                                } else if (StringFind(OrderComment(),"34-")) {
                                    atr_value = iATR(sig_symbol,PERIOD_H4,3,0);
                                } else {
                                    atr_value = iATR(sig_symbol,PERIOD_H4,3,0);
                                }

                                

                                sig_sl = cur_price + (atr_value * 4);
                            } else {                            
                                sig_sl = cur_price + ((sig_def_sl+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                            }
                        } else if (sig_sl > 20000000) {
                                sig_sl = sig_sl - 20000000;
                                sig_sl = cur_price + (((sig_sl)+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                        }  else {
                                if (addPipsToSL > 0)
                                    sig_sl = sig_sl + (addPipsToSL * point_multiplier * getPoint(sig_symbol));
                        }

                        if (sig_tp == 0) {
                                sig_tp = cur_price - (sig_def_tp * point_multiplier * getPoint(sig_symbol));
                        }

                        sl_in_pips = ((sig_sl - cur_price) / point_multiplier) / getPoint(sig_symbol);

               }/* else if (sig_op_type==OP_BUYLIMIT || sig_op_type==OP_BUYSTOP)  {

                   cur_price = sig_entry;

                        if (sig_sl == 0) {
                                sig_sl = cur_price - ((sig_def_sl+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                        } else {
                                if (addPipsToSL > 0)
                                    sig_sl = sig_sl - (addPipsToSL * point_multiplier * getPoint(sig_symbol));
                        }

                        if (sig_tp == 0) {
                                sig_tp = cur_price + (sig_def_tp * point_multiplier * getPoint(sig_symbol));
                        } 

                        sl_in_pips = (cur_price - sig_sl) * point_multiplier * getPoint(sig_symbol);                  

               } else if (sig_op_type==OP_SELLLIMIT || sig_op_type==OP_SELLSTOP)  {

                   cur_price = sig_entry;

                        if (sig_sl == 0) {
                                sig_sl = cur_price + ((sig_def_sl+addPipsToSL) * point_multiplier * getPoint(sig_symbol));
                        } else {
                                if (addPipsToSL > 0)
                                    sig_sl = sig_sl + (addPipsToSL * point_multiplier * getPoint(sig_symbol));
                        }

                        if (sig_tp == 0) {
                                sig_tp = cur_price - (sig_def_tp * point_multiplier * getPoint(sig_symbol));
                        }

                        sl_in_pips = (sig_sl - cur_price) * point_multiplier * getPoint(sig_symbol);

               } else  { 
                  cur_price = sig_entry; 
               } */

                double t_risk_size = 0.0;

                string risk_type = StringSubstr(sig_risk_size,0,1);

                Print("Risk_type: " + risk_type);

                double risk_value = StrToDouble(StringSubstr(sig_risk_size,1,StringLen(sig_risk_size) -1));

                if (risk_type=="O") {
                        t_risk_size = risk_value;
                } else if (risk_type=="R") {
                        t_risk_size = calculateLotRiskSize(sig_symbol,sl_in_pips,risk_value/100,point_multiplier,deposit_size);

                } else {
                    Print("Risk calculate problem: " + sig_risk_size + " " + t_risk_size);
                    return;
                }

                t_risk_size=NormalizeDouble(t_risk_size,2);

                Print("Risk calculate: " + sig_risk_size + " " + t_risk_size);


                if (t_risk_size < 0.01) t_risk_size = 0.01;


                Print("Symbol=" + sig_symbol + ", Risk is=" + sig_risk_size + "%" + ", SL PIPS=" + sl_in_pips  + ", Lot size is=" + t_risk_size);

               ResetLastError();

               
               int order_ticket_number = -1;// = OrderSend(sig_symbol, sig_op_type, t_risk_size, cur_price, 10, sig_sl, sig_tp, sig_comment, 1984, 0, Lime);


               if (order_ticket_number > -1) {
                    if (sig_half_close_on > 0) {
                        double close_half_on_price = 0;

                        if (sig_op_type==OP_BUY) {
                               close_half_on_price = cur_price + (sig_half_close_on * point_multiplier * getPoint(sig_symbol));
                        } else if (sig_op_type==OP_SELL) {
                               close_half_on_price = cur_price - (sig_half_close_on * point_multiplier * getPoint(sig_symbol));
                        }

                        GlobalVariableSet(IntegerToString(order_ticket_number),close_half_on_price);
                    }
               } else {
                Print(GetLastError());
               }

         }
}

void findAndCloseOppositeOrder(string sig_symbol,int sig_op_type) {


        if (sig_op_type == 0) sig_op_type = 1;
        else sig_op_type = 0;


         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                        if (OrderSymbol()==sig_symbol) {
                            if (OrderType()==sig_op_type) {

                                   RefreshRates();

                                   OrderClose(OrderTicket(),OrderLots(),getBid(OrderSymbol()),20,Blue);
                            }
                        }

         }

}

void findAndHalfCoseOrders() {


         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                  double price_for_close = GlobalVariableGet(IntegerToString(OrderTicket()));

                  if (price_for_close > 0) {

                        RefreshRates();

                        if (OrderType()==OP_BUY) {
                            if (getBid(OrderSymbol()) >= price_for_close) {

                                   if (OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, 0)) {

                                        if (closeOrder(OrderTicket(),OrderType(),CLOSE_PARTIAL,50)) {
                                                GlobalVariableDel(IntegerToString(OrderTicket()));
                                        }

                                   }
                            }
                        } else if (OrderType()==OP_SELL) {
                            if (getAsk(OrderSymbol()) <= price_for_close) {

                                   if (OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, 0)) {

                                        if (closeOrder(OrderTicket(),OrderType(),CLOSE_PARTIAL,50)) {
                                                GlobalVariableDel(IntegerToString(OrderTicket()));
                                        }

                                   }
                            }

                        }
                  }

         }

}

bool findAlreadyOpenedOrder(string sig_symbol,int sig_op_type) {


         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                        if (OrderSymbol()==sig_symbol) {

                            if (OrderType()==sig_op_type) {
                                    return true;
                            }

                        }

         }

        return false;

}

bool findAlreadyClosedOrder(string sig_symbol,int sig_op_type,string sig_comment) {


        int total_his=OrdersHistoryTotal();


        for (int v = total_his - 1; v >= 0; v--) {

                  OrderSelect(v,SELECT_BY_POS,MODE_HISTORY);

                        if (OrderSymbol()==sig_symbol) {

                            if (OrderType()==sig_op_type) {

                                if (OrderComment()==sig_comment) {
                                    return true;
                                }

                            }

                        }

        }

        return false;

}


void checkAndClearGlobalvars() {

        int globalV_Count = GlobalVariablesTotal();


        for (int i=0; i < globalV_Count; i++) {
             string ticket_number = GlobalVariableName(i);

            bool globalVarFound = false;
            for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                  if (IntegerToString(OrderTicket())==ticket_number) {
                    globalVarFound = true;
                    break;
                  }
            }

            if (globalVarFound == false) {
                GlobalVariableDel(ticket_number);
            }
        }

}




bool closeOrder(int order_ticket,int sig_op_type,int closeType, int closePercent) {

        Print("Need to close order ticket=" + order_ticket + " type=" + closeType + " percent="+closePercent);

          for(int i=OrdersTotal()-1;i>=0;i--) {


            OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

                if (OrderTicket()!=order_ticket) continue;

                  if (OrderType()==sig_op_type) {


                            double cur_price = 0.0;

                            RefreshRates();

                            if (sig_op_type==OP_BUY) {
                                cur_price  = getAsk(OrderSymbol());
                            } else if (sig_op_type==OP_SELL) {
                                cur_price  = getBid(OrderSymbol());
                            } else {
                                return OrderDelete(OrderTicket());
                            }                           

                            double orderLots = 0.0;


                            if (closeType==CLOSE_FULL) {
                                    ResetLastError();
                                    Print("Closing oder ticket=" + OrderTicket() + " lots=" + OrderLots() + " price=" + cur_price);
                                    if (OrderClose(OrderTicket(),OrderLots(),cur_price,20,Blue)) {
                                        return true;
                                    } else {
                                        Print(GetLastError());
                                    }
                            } else if (closeType==CLOSE_PARTIAL) {

                                    /*if ( ! OrderModify(OrderTicket(), 0, OrderOpenPrice(), OrderTakeProfit(), 0, 0) ) {
                                        int error = GetLastError();
                                        Print("HC: Can not modify tp to " + OrderTakeProfit() + " or sl to " + OrderOpenPrice() + " on " + OrderSymbol() + ", ticket=" + OrderTicket() + ", error=" + error);

                                        return;
                                    }*/

                                    return OrderClose(OrderTicket(),OrderLots()/2,cur_price,20,Blue);
                            }

                            

                  }
          }
          return false;





}


double calculateLotRiskSize( string symbol,double riskPoints,double MaxRiskPerTrade, double point_multiplier, double deposit_size ) {

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

    double account_balance;

    if (deposit_size < AccountBalance()) {
        account_balance = deposit_size;
    } else {
        account_balance = AccountBalance();
    }

    double riskAmount = (AccountBalance() * MaxRiskPerTrade / 100);
    riskPoints = riskPoints * point_multiplier;


    double riskLots   = riskAmount / ( pointValue * riskPoints );

    Print("Symbol=" + symbol + ", Risk SL=" + riskPoints + " , Risk Amount="  + riskAmount + " Lots=" + riskLots );


    return riskLots;

}




void findAndCloseOrderAfterCandleCount(int candle_count) {


        for(int iPos=OrdersTotal() - 1; iPos >=0; iPos--) 
        
            if (OrderSelect(iPos,SELECT_BY_POS)) {

                int timeframe = -1;

                 if (StringFind(OrderComment(),"31-") > 0 ) {

                    timeframe = PERIOD_H1;

                 } else  if (StringFind(OrderComment(),"34-") > 0 ) {

                    timeframe = PERIOD_H4;

                 }

                int duration = iBarShift(OrderSymbol(),timeframe, OrderOpenTime());

                if (duration < candle_count) continue;

                if (closeOrder(OrderTicket(),OrderType(),CLOSE_FULL, 100)) {

                    Print("Order Closed on symbol=" + OrderSymbol() + ", comment=" + OrderComment());

                }
            }


}

