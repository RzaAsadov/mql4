struct IndicatorData {

      string name;


      int arrowBuyCode; // = 233;
      int arrowSellCode;//= 234;
      int arrowBuySize;// = 1;
      int arrowSellSize;// = 1;

      color arrowColorBuy;// = UP_COLOR_SHORT;
      color arrowColorSell;// = DOWN_COLOR_SHORT;
      color arrowTextColorBuy;      
      color arrowTextColorSell;
      color up_line_color;
      color down_line_color;


      int ArrowRef;// = 1234;      // def 1234

      //------------------------------------------------------------------

      int     Price;  //Apply to Price(0-Close;1-Open;2-High;3-Low;4-Median price;5-Typical price;6-Weighted Close)
      int     Length ;  //Period 
      int     Displace;  //DispLace or Shift   def=0
      double  PctFilter;  //Dynamic filter in decimal   def=0
      int     Color;  //Switch of Color mode (1-color)  def=1
      int     ColorBarBack;  //Bar back for color mode  def=1
      double  Deviation;  //Up/down deviation         def = 0.1 


      //---- indicator buffers
      double MABuffer[];
      double UpBuffer[];
      double DnBuffer[];
      double trend[];
      double Del[];
      double AvgDel[];

      double alfa[];
      double Coeff, beta, t, Sum, Weight, g;
      int ix, Phase, Len,Cycle;     
      double pi;
      double Filter;
      datetime tim;


      double up_arr[];
      double dn_arr[];
      
      double up_sl_arr[];
      double dn_sl_arr[];






      int LAST_SG;



      double signal_open_price;


      IndicatorData() {

            arrowBuyCode = 233;
            arrowSellCode = 234;
            arrowBuySize = 3;
            arrowSellSize = 3;


            ArrowRef = 1234;

            Price = 0;
            Displace = 0;
            PctFilter = 0;
            Color = 1;
            ColorBarBack = 1;
            Deviation = 0.1;  

            Cycle = 4;      
            pi = 3.1415926535;   

                                 
             
      }


};

