void setTrailingStopByComment (int operation_type,string currency_pair, string comment_t,double distance) {


         bool isLastOrder = true;

     
         for (int v = OrdersTotal() - 1; v >= 0; v--) {

                  OrderSelect(v, SELECT_BY_POS, MODE_TRADES);

                     if (OrderSymbol() != currency_pair || StringFind(OrderComment(),comment_t) < 0) continue;

                     double price_movement = 0.0;

                     if (operation_type==OP_BUY && isLastOrder) { // Last BUY ORDER

                           price_movement = NormalizeDouble(getAsk(currency_pair) - OrderOpenPrice(),getDigits(currency_pair));  


                           if (price_movement >= distance) {

                                 double new_sl = getAsk(currency_pair)  - distance;

                                 if (OrderStopLoss()==new_sl) continue;

                                 log(currency_pair,"setTrailingStopByComment","Modifying TS of " + OrderComment() + " new_ts=" + new_sl);
                                 modifySelectedOrder(0, new_sl);
                           }

                           isLastOrder == false;
                           

                     } else if (operation_type==OP_SELL && isLastOrder) { // Last SELL ORDER

                           price_movement = NormalizeDouble(OrderOpenPrice() - getBid(currency_pair),getDigits(currency_pair)); 
                              
                           if (price_movement >= distance) {

                                 double new_sl = getBid(currency_pair) + distance;

                                 if (OrderStopLoss()==new_sl) continue;

                                 log(currency_pair,"setTrailingStopByComment","Modifying TS of " + OrderComment() + " new_ts=" + new_sl);
                                 modifySelectedOrder(0, new_sl);
                           }

                           isLastOrder == false;
                           
                     } else if (operation_type==OP_BUY && !isLastOrder) { // BUY ORDER

                           price_movement = NormalizeDouble(getAsk(currency_pair) - OrderOpenPrice(),getDigits(currency_pair)); 

                           if (price_movement >= distance) {

                                 double new_sl = getAsk(currency_pair)  - distance;

                                 if (OrderStopLoss()==new_sl) continue;

                                 log(currency_pair,"setTrailingStopByComment","Modifying TS of " + OrderComment() + " new_ts=" + new_sl);
                                 modifySelectedOrder(0, new_sl);
                           }

                     } else if (operation_type==OP_SELL && !isLastOrder) { // SELL ORDER

                           price_movement = NormalizeDouble(OrderOpenPrice() - getBid(currency_pair),getDigits(currency_pair)); 
                           
                           if (price_movement >= distance) {

                                 double new_sl = getBid(currency_pair) + distance;

                                 if (OrderStopLoss()==new_sl) continue;

                                 log(currency_pair,"setTrailingStopByComment","Modifying TS of " + OrderComment() + " new_ts=" + new_sl);
                                 modifySelectedOrder(0, new_sl);
                           }

                     }

               
         } 
   

}

