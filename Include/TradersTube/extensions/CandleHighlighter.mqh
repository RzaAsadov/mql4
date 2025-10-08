int find3strike () {

    int period = 14;  // Period for calculating the average range
    double multiplier = 2.0;  // Multiplier for determining the strike candle

    for (int i = 3; i < Bars - 2; i++) {
        // Calculate the average range for the previous three candles
        double avgRange = (High[i] - Low[i] + High[i - 1] - Low[i - 1] + High[i - 2] - Low[i - 2]) / 3.0;

        // Check if the current candle is a bullish strike candle
        if (Close[i] > Open[i] && Close[i - 1] > Open[i - 1] && Close[i - 2] > Open[i - 2]) {
            // Check if the range of the current candle is greater than the average range multiplied by the multiplier
            if ((High[i] - Low[i]) > avgRange * multiplier) {
                Print("Bullish strike candles found at index: ", i - 2, ", ", i - 1, ", ", i);
                // Add your desired logic or actions for bullish strike candles here
            }
        }

        // Check if the current candle is a bearish strike candle
        if (Open[i] > Close[i] && Open[i - 1] > Close[i - 1] && Open[i - 2] > Close[i - 2]) {
            // Check if the range of the current candle is greater than the average range multiplied by the multiplier
            if ((High[i] - Low[i]) > avgRange * multiplier) {
                Print("Bearish strike candles found at index: ", i - 2, ", ", i - 1, ", ", i);
                // Add your desired logic or actions for bearish strike candles here
            }
        }
    }

    return -1;


}