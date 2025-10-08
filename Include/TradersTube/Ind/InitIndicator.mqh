int initIndicator(IndicatorData &indicatorData,int bufferNum) {

      
      SetIndexStyle(bufferNum,DRAW_LINE);
      SetIndexBuffer(bufferNum,indicatorData.MABuffer);
      SetIndexLabel(bufferNum,"TTMA " + indicatorData.Length); 
      SetIndexShift(bufferNum,indicatorData.Displace);
      SetIndexEmptyValue(bufferNum,EMPTY_VALUE);
      SetIndexDrawBegin(bufferNum,indicatorData.Length * indicatorData.Cycle + indicatorData.Length+1);
      
      bufferNum++;

      SetIndexLabel(bufferNum,"TT Up " + indicatorData.Length);
      SetIndexStyle(bufferNum,DRAW_LINE,EMPTY,2,indicatorData.up_line_color);
      SetIndexBuffer(bufferNum,indicatorData.UpBuffer);
      SetIndexShift(bufferNum,indicatorData.Displace);
      SetIndexEmptyValue(bufferNum,EMPTY_VALUE);
      SetIndexDrawBegin(bufferNum,indicatorData.Length * indicatorData.Cycle + indicatorData.Length+1);

      bufferNum++;


      SetIndexLabel(bufferNum,"TT Dn " + indicatorData.Length);
      SetIndexStyle(bufferNum,DRAW_LINE,EMPTY,2,indicatorData.down_line_color);
      SetIndexBuffer(bufferNum,indicatorData.DnBuffer);
      SetIndexShift(bufferNum,indicatorData.Displace);   
      SetIndexEmptyValue(bufferNum,EMPTY_VALUE); 
      SetIndexDrawBegin(bufferNum,indicatorData.Length * indicatorData.Cycle + indicatorData.Length+1);  

      bufferNum++;      


      SetIndexBuffer(bufferNum,indicatorData.trend);
      SetIndexLabel(bufferNum,"TT Trend " + indicatorData.Length);

      bufferNum++;

      SetIndexBuffer(bufferNum,indicatorData.Del);

      bufferNum++;

      SetIndexBuffer(bufferNum,indicatorData.AvgDel); 

      bufferNum++;


      SetIndexBuffer(bufferNum,indicatorData.up_arr);
      SetIndexStyle(bufferNum,DRAW_ARROW,EMPTY,indicatorData.arrowBuySize,indicatorData.arrowColorBuy);
      SetIndexArrow(bufferNum,indicatorData.arrowBuyCode);
      SetIndexLabel(bufferNum,"TT UP " + indicatorData.Length);

      bufferNum++;
      
      SetIndexBuffer(bufferNum,indicatorData.dn_arr);
      SetIndexStyle(bufferNum,DRAW_ARROW,EMPTY,indicatorData.arrowSellSize,indicatorData.arrowColorSell);
      SetIndexArrow(bufferNum,indicatorData.arrowSellCode);
      SetIndexLabel(bufferNum,"TT DOWN " + indicatorData.Length); 

      bufferNum++;
   

      SetIndexBuffer(bufferNum,indicatorData.up_sl_arr);
      SetIndexLabel(bufferNum,"UP SL " + indicatorData.Length);

      bufferNum++;
      
      SetIndexBuffer(bufferNum,indicatorData.dn_sl_arr);
      SetIndexLabel(bufferNum,"DOWN SL " + indicatorData.Length);  


    

      indicatorData.Coeff =  3 * indicatorData.pi;
      indicatorData.Phase = indicatorData.Length-1;
      indicatorData.Len = indicatorData.Length * 4 + indicatorData.Phase;  
      ArrayResize(indicatorData.alfa,indicatorData.Len);
      indicatorData.Weight=0; 


      
      for ( indicatorData.ix=0; indicatorData.ix < indicatorData.Len-1; indicatorData.ix++ ) {
      
            if (indicatorData.ix<=indicatorData.Phase-1) { 
                  indicatorData.t = 1.0 * indicatorData.ix / ( indicatorData.Phase-1 );
            } else {
                  indicatorData.t = 1.0 + ( indicatorData.ix-indicatorData.Phase+1 ) * ( 2.0 * indicatorData.Cycle-1.0 ) / (indicatorData.Cycle * indicatorData.Length-1.0 ); 
            }
            
            indicatorData.beta = MathCos( indicatorData.pi * indicatorData.t );
            indicatorData.g = 1.0 / ( indicatorData.Coeff * indicatorData.t+1 );   
            if ( indicatorData.t <= 0.5 ) indicatorData.g = 1;
            indicatorData.alfa[indicatorData.ix] = indicatorData.g * indicatorData.beta;
            indicatorData.Weight += indicatorData.alfa[indicatorData.ix];
         
      }
 
   return(bufferNum);
   
 }

