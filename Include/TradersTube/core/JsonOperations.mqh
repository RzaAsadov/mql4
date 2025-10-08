string getStringValFromJsonObject (JSONObject &inputss,string keyss) {

        string ret_val;

        inputss.getString(keyss,ret_val);

        return ret_val;

}

int getIntValFromJsonObject (JSONObject &inputss,string keyss) {
        

        int ret_val;

        inputss.getInt(keyss,ret_val);

        return ret_val;


}

double getDoubleValFromJsonObject (JSONObject &inputss,string keyss) {

        double ret_val;

        inputss.getDouble(keyss,ret_val);

        return ret_val;
    

}

bool isArrayJson (string response_json) {



                        ushort first_symbol_of_jsondata = StringGetCharacter(response_json,0);
                        ushort last_symbol_of_json_data = StringGetCharacter(response_json,StringLen(response_json)-1);


                        if (first_symbol_of_jsondata != '{' || last_symbol_of_json_data != '}') {
                            Print("ERROR: response from server is not json");
                            if (isDebug) {
                                Print("-------------------------------------\n");
                                Print(response_json);
                                Print("-------------------------------------\n");
                            }
                           return false;
                        }  

                        return true;

}

bool parseJsonFromCharArray(char &response_data[],JSONObject &jo) {

                        int response_data_size = ArraySize(response_data);

                        string response_json = CharArrayToString(response_data,0,response_data_size,CP_OEMCP); 


                        ushort first_symbol_of_jsondata = StringGetCharacter(response_json,0);
                        ushort last_symbol_of_json_data = StringGetCharacter(response_json,StringLen(response_json)-1);


                        if (first_symbol_of_jsondata != '{' || last_symbol_of_json_data != '}') {
                            Print("ERROR: response from server is not json");
                            if (isDebug) {
                                Print("-------------------------------------\n");
                                Print(response_json);
                                Print("-------------------------------------\n");
                            }
                           return false;
                        }  


                        JSONParser *parser = new JSONParser();


                        JSONObject *jv = parser.parse(response_json);

                        jo = GetPointer(jv);

                        //jo = parser.parse(response_json);


                        delete parser;

                        /*
                        if (jv==NULL)  {
                           delete jv;
                           return NULL;
                        }
                        
                        if (!jv.isObject()) {
                           delete jv;
                           return NULL;
                        }*/

                        return true;
                          



}
