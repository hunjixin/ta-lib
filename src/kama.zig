const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Kaufman's Adaptive Moving Average (KAMA) for a given slice of prices.
///
/// KAMA is an adaptive moving average designed to account for market noise or volatility.
/// It adjusts its smoothing constant based on price fluctuations, making it more responsive
/// during trending markets and less sensitive during sideways or volatile periods.
///
/// Parameters:
/// - `prices`: A slice of f64 values representing the input price data.
/// - `period`: The number of periods to use for the KAMA calculation.
/// - `allocator`: The allocator to use for allocating the result array.
///
/// Returns:
/// - An array of f64 values containing the calculated KAMA values.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input parameters are invalid.
pub fn KAMA(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = prices.len;
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    const const_max = 2.0 / (30.0 + 1.0);
    const const_diff = 2.0 / (2.0 + 1.0) - const_max;
    const lookback_total = period;
    const start_idx = lookback_total;
    var sum_roc1: f64 = 0.0;
    var today: usize = start_idx - lookback_total;
    var trailing_idx: usize = today;

    var i = period;
    while (i > 0) : (i -= 1) {
        var temp_real = prices[today];
        today += 1;
        temp_real -= prices[today];
        sum_roc1 += @abs(temp_real);
    }

    var prev_kama = prices[today - 1];
    var temp_real = prices[today];
    var temp_real2 = prices[trailing_idx];
    trailing_idx += 1;
    var period_roc = temp_real - temp_real2;
    var trailing_value = temp_real2;

    if (sum_roc1 <= period_roc or (@abs(sum_roc1) < 1e-14)) {
        temp_real = 1.0;
    } else {
        temp_real = @abs(period_roc / sum_roc1);
    }
    temp_real = (temp_real * const_diff) + const_max;
    temp_real *= temp_real;
    prev_kama = ((prices[today] - prev_kama) * temp_real) + prev_kama;
    today += 1;

    while (today <= start_idx) : (today += 1) {
        temp_real = prices[today];
        temp_real2 = prices[trailing_idx];
        trailing_idx += 1;
        period_roc = temp_real - temp_real2;
        sum_roc1 -= @abs(trailing_value - temp_real2);
        sum_roc1 += @abs(temp_real - prices[today - 1]);
        trailing_value = temp_real2;
        if (sum_roc1 <= period_roc or (@abs(sum_roc1) < 1e-14)) {
            temp_real = 1.0;
        } else {
            temp_real = @abs(period_roc / sum_roc1);
        }
        temp_real = (temp_real * const_diff) + const_max;
        temp_real *= temp_real;
        prev_kama = ((prices[today] - prev_kama) * temp_real) + prev_kama;
    }
    out[period] = prev_kama;
    var out_idx = period + 1;

    while (today < len) : (today += 1) {
        temp_real = prices[today];
        temp_real2 = prices[trailing_idx];
        trailing_idx += 1;
        period_roc = temp_real - temp_real2;
        sum_roc1 -= @abs(trailing_value - temp_real2);
        sum_roc1 += @abs(temp_real - prices[today - 1]);
        trailing_value = temp_real2;
        if (sum_roc1 <= period_roc or (@abs(sum_roc1) < 1e-14)) {
            temp_real = 1.0;
        } else {
            temp_real = @abs(period_roc / sum_roc1);
        }
        temp_real = (temp_real * const_diff) + const_max;
        temp_real *= temp_real;
        prev_kama = ((prices[today] - prev_kama) * temp_real) + prev_kama;
        out[out_idx] = prev_kama;
        out_idx += 1;
    }

    return out;
}

test "KAMA work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
        1.5,  2.7,  3.6,  4.8,  5.2,  6.4,  7.9,  8.3,  9.1,  9.7,  10.2, 11.6, 12.8, 13.9, 14.5,
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
        1.5,  2.7,  3.6,  4.8,  5.2,  6.4,  7.9,  8.3,  9.1,  9.7,  10.2, 11.6, 12.8, 13.9, 14.5,
    };
    const result = try KAMA(&prices, 10, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 0.0000000000, 11.2254234627, 11.2466271432, 11.4670797244, 11.8525144613, 11.8986837354, 11.8651563519, 11.8761802920, 11.8602176944, 12.7496411965, 12.7541700353, 12.7919391324, 12.7954408879, 12.8163458675, 12.9603005014, 13.6138570539, 13.9970627117, 14.0095811041, 14.0065202056, 14.4015658416, 22.5403833096, 26.2707517337, 26.2086538902, 26.1228504003, 26.0611728255, 25.6743588514, 25.4151126067, 25.3490816922, 25.2950892307, 25.2241589491, 19.9652465600, 19.3482912099, 25.1592075933, 25.0563558558, 24.9757771986, 24.9008827029, 24.3919554474, 23.9457148002, 23.4933891594, 23.1681706327, 22.9709803928, 22.5897346981, 19.2035545964, 18.2276066734, 17.6212439476, 16.9761142736, 13.9645079298, 12.9136155165, 12.8631197314, 13.3239554063, 13.8466418924, 44.3148010513, 44.0412203316, 45.1454719427, 49.1641273179, 48.9348518625, 49.0659393155, 48.9309648225, 49.6996608120, 49.6306823318, 49.4411849464, 49.5766813068, 49.4344162353, 48.9895444977, 49.1837601029, 49.0074628098, 48.2822294630, 47.8638130027, 46.6414667992, 47.0478271291, 46.8889114302, 46.0349862108, 45.8740825782, 45.6722479327, 43.4318356174, 43.4289957068, 43.2104293326, 43.0569401003, 42.9080232741, 40.0348626134, 44.7923183601, 46.6038552679, 46.4493966015, 46.2422171682, 46.0837659660, 45.0703917994, 44.4112564816, 44.2372341258, 44.0807379484, 43.8897120708, 31.9185840322, 28.5346518419, 32.0981015705, 31.8812294412, 31.7258937765, 31.5634705276, 30.9096439289, 30.3293232752, 29.7350773420, 29.3012689488, 29.0367715159, 28.5159712084, 23.7637144171, 22.3795988212, 21.4974120633, 20.5365957257, 15.9425531809, 14.0125295450, 13.4736275250, 13.6631264028, 14.0350702238 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
