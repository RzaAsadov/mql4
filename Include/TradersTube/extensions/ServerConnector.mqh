
bool is_not_connected_to_server_msg_sent = false;
bool is_connected_to_server_msg_sent = false;

bool is_server_answer_not_parsable_message_sent = false;
bool is_server_answer_parsable_message_sent = false;

bool is_no_data_block_msg_sent = false;
bool is_data_block_ok_msg_sent = false;


int server_connection_fail_count=0;
int server_answer_fail_count=0;


bool sendToServer(char &post[],char &result[],string func_name,string query,int timeout) {

   string cookie=NULL,headers;
   int res;

   string acct_number = IntegerToString(AccountNumber());
   string server_url="https://" + Server_Host 
         + "/engine?module=crud&action="+ func_name + "&of=json"
         +  "&" + query;

   ResetLastError();

   res=WebRequest("GET",server_url,cookie,NULL,timeout,post,0,result,headers);

   if(res==-1) {

            Print("Error in WebRequest. Error code  =",GetLastError(), " URL is: " + server_url);
            //--- Perhaps the URL is not listed, display a message about the necessity to add the address
            //MessageBox("Add the address '"+Server_Host+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
            return false;
            
   } 
      //--- Load successfully         
      return true;

}


int requestServer(char &req_data[],string apiFunctionName,char &response_json[]) {

         char response_data[];

         if (isDebug) {
                  logWriteToFile("Request: " + CharArrayToString(req_data),apiFunctionName + ".log");
         }            

         if (sendToServer(req_data,response_data,apiFunctionName,"",ServerRequestTimeoutMs)) {  

               ArrayFree(req_data);      

               server_connection_fail_count=0;
               if (!is_connected_to_server_msg_sent) {
                     if (!silentMode) {                     
                        SendNotification(apiFunctionName + " (SUCCESS): Server connection established after " + ServerFailTriesToReport + " tries !\r\n");
                     }

                     Print(apiFunctionName + " (SUCCESS): Server connection established after " + ServerFailTriesToReport + " tries !\r\n");
                     is_connected_to_server_msg_sent = true;
                     is_not_connected_to_server_msg_sent = false;
               } 

               if (isDebug) { log("connection",apiFunctionName,"Request sended to server!"); }    

         } else {      

               ArrayFree(response_data);  
               ArrayFree(req_data);      

               if (server_connection_fail_count >= ServerFailTriesToReport) {
                     if (!is_not_connected_to_server_msg_sent) {
                           if (!silentMode) {                           
                              SendNotification(apiFunctionName + " (ERROR): Unable connect to Server after " + ServerFailTriesToReport + " tries !\r\n");
                           }
                           Print(apiFunctionName + " (ERROR): Unable connect to Server after " + ServerFailTriesToReport + " tries !\r\n");
                           is_not_connected_to_server_msg_sent = true;
                           is_connected_to_server_msg_sent = false;
                     }
                     server_connection_fail_count=0;
               } else {
                     server_connection_fail_count++; 
               }  

               if (isDebug) { log("connection",apiFunctionName,"ERROR on sending request to server"); } 
               return 3;

         }



         if (isDebug) {
            logWriteToFile("Response: " + CharArrayToString(response_data),apiFunctionName + ".log");
         }         



      

                              string response_json_str = CharArrayToString(response_data);
                              ArrayFree(response_data);


                              if (!isArrayJson(response_json_str)) {
                                    return 10;
                              }



                              JSONParser *parser = new JSONParser();

                              JSONObject *jo = parser.parse(response_json_str);


                              if (jo==NULL) {

                                    if (server_answer_fail_count >= ServerFailTriesToReport) {
                                          if (!is_server_answer_not_parsable_message_sent) {
                                                if (!silentMode) {
                                                      SendNotification(apiFunctionName + " (ERROR): Unparsable answer from server after " + ServerFailTriesToReport + " tries !\r\n");
                                                }
                                                      Print(apiFunctionName + " (ERROR): Unparsable answer from server after " + ServerFailTriesToReport + " tries !\r\n");

                                                is_server_answer_not_parsable_message_sent = true;
                                                is_server_answer_parsable_message_sent = false;
                                          }
                                          server_answer_fail_count=0;
                                    }

                                    server_answer_fail_count++;
                                    delete jo;
                                    delete parser;

                                    return 1;

                              } else {


                                    if (!is_server_answer_parsable_message_sent) {
                                                if (!silentMode) {                                          
                                                      SendNotification(apiFunctionName + " (SUCCESS): Parsable answer from server after " + ServerFailTriesToReport + " tries !\r\n");
                                                }
                                                      Print(apiFunctionName + " (SUCCESS): Parsable answer from server after " + ServerFailTriesToReport + " tries !\r\n");

                                                is_server_answer_not_parsable_message_sent = false;
                                                is_server_answer_parsable_message_sent = true;
                                    }                                    
                                    server_answer_fail_count=0;
                              }      
                                 
                              

                              JSONObject *data_obj=jo.getValue("data");

                  
   
                              if (data_obj == NULL) {


                                    if (server_answer_fail_count >= ServerFailTriesToReport) {
                                          if (!is_no_data_block_msg_sent) {
                                                if (!silentMode) {                                                
                                                      SendNotification(apiFunctionName + " (ERROR): No DATA block in response from server after " + ServerFailTriesToReport + " tries !\r\n");
                                                }

                                                      Print(apiFunctionName + " (ERROR): No DATA block in response from server after " + ServerFailTriesToReport + " tries !\r\n");

                                                is_no_data_block_msg_sent = true;
                                                is_data_block_ok_msg_sent = false;
                                          }
                                          server_answer_fail_count=0;
                                    }

                                    server_answer_fail_count++;

                                    delete jo;
                                    delete data_obj;
                                    delete parser;
                                    return 2;

                              } else {
                                    if (!is_data_block_ok_msg_sent) {
                                          if (!silentMode) {                                          
                                                SendNotification(apiFunctionName + " (SUCCESS): DATA block OK in response from server after " + ServerFailTriesToReport + " tries !\r\n");
                                          }
                                                Print(apiFunctionName + " (SUCCESS): DATA block OK in response from server after " + ServerFailTriesToReport + " tries !\r\n");

                                          is_data_block_ok_msg_sent = true;
                                          is_no_data_block_msg_sent = false;
                                    }                                    
                                   
                                    server_answer_fail_count=0;
                              }

                              string response_result = getStringValFromJsonObject(data_obj,"result");

                              if (response_result != NULL) {
                                    if (response_result == "error") {
                                          string response_message = getStringValFromJsonObject(data_obj,"message");
                                          if (response_message != NULL) {
                                                MessageBox("Server side error (" + apiFunctionName +  "): " + response_message);
                                                ExpertRemove();
                                          }
                                    }
                              } 

                              if (first_connection_to_server) {
                                    MessageBox("Successfuly connected to server !");
                                    first_connection_to_server = false;
                              }
                                                            

                              string data_json = data_obj.toString();

                              delete data_obj;
                              delete jo;
                              delete parser;         

                              
                              StringToCharArray(data_json,response_json,0,StringLen(data_json));



                        return 0;
}





