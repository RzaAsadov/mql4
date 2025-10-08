
void setupSymbols () {

    int total=SymbolsTotal(true)-1;
    
    for(int i=total-1;i>=0;i--)
    {
    string Sembol=SymbolName(i,true);
    Print("Number: "+string(i)+" Sembol Name: "+Sembol+" Close Price: ",iClose(Sembol,0,0));
    }

}