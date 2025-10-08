void log(string currency_pair,string module,string log) {


    if (isDebug) {

        /*if ( StringFind(DebugSymbols,";") >= 0 ) {
            int k=StringSplit(DebugSymbols,StringGetCharacter("-",0),debug_pairs); 
        } else {
            ArrayResize(debug_pairs,1,1);
            debug_pairs[0] = DebugSymbols;
        }

            for (int i=0; i < ArraySize(debug_pairs); i++) {
                if (debug_pairs[i]==currency_pair) {
                        Print(currency_pair + "|" + module + "|" + log);
                }

            }*/

            Print(module + "|" + log);
         
    }

}


void logWriteToFile(string line,string filename) {

    ResetLastError();  

    line = line + "\r\n";  

   int fd = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_TXT);
   if (fd < 0) {
      Print("Log file open " + filename + " failed , error code: " + GetLastError());
      return;
   }

     FileSeek(fd, 0, SEEK_END);
     FileWrite(fd, line);
     FileClose(fd);
}