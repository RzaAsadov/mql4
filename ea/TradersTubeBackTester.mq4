


int OnInit() {

    doBackTest();

}


void OnDeinit(const int reason) {


}



void doBackTest() {

    Print("B1");

     string stat_file = "lcm_divergences_filtered.csv";

    ParseCSV(stat_file);


}

bool ParseCSV(const string filename)
{

    Print("B2");
    // Open the file in binary mode for reading
    int file_handle = FileOpen(filename, FILE_READ | FILE_CSV);
    if (file_handle == INVALID_HANDLE)
    {
        Print("Failed to open file: ", filename);
        return false;
    }

        Print("B3");

    // Read each line of the CSV file
    string line;
    while (!FileIsEnding(file_handle))
    {
        if (FileIsLineEnding(file_handle))
        {
            FileReadString(file_handle, line);
            string fields[];
            StringSplit(line, ',', fields);

            // Access and process individual fields
            for (int i = 0; i < ArraySize(fields); i++)
            {
                Print("Field ", i, ": ", fields[i]);
                // You can perform further operations with each field here
            }
        }
    }

        Print("B4");

    // Close the file after parsing
    FileClose(file_handle);
    return true;
}