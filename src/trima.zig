const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Triangular Moving Average (TRIMA) for a given array of prices.
///
/// The Triangular Moving Average is a double-smoothed simple moving average,
/// which gives more weight to the middle portion of the data. The formula for TRIMA is:
///
///     TRIMA = SMA(SMA(prices, period), period)
///
/// Where `SMA` is the Simple Moving Average over the specified period.
///
/// Parameters:
/// - `prices`: The input slice of price data (e.g., closing prices).
/// - `period`: The number of periods to use for the moving average calculation.
/// - `allocator`: The allocator to use for the result array.
///
/// Returns:
/// - A newly allocated array of TRIMA values (length: prices.len - period + 1).
///
/// Errors:
/// - Returns an error if memory allocation fails or if the period is invalid.
///
/// Example usage:
/// ```zig
/// const trima = try Trima(prices, 10, allocator);
/// ```
pub fn Trima(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = prices.len;
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);
    if (period < 1 or period > len) {
        return MyError.InvalidInput;
    }

    const lookback_total = period - 1;
    var out_idx: usize = 0;

    if (period % 2 == 1) {
        // Odd period
        const i = period >> 1;
        const factor = 1.0 / ((@as(f64, @floatFromInt(i)) + 1.0) * (@as(f64, @floatFromInt(i)) + 1.0));
        var trailing_idx = lookback_total - lookback_total;
        var middle_idx = trailing_idx + i;
        var today_idx = middle_idx + i;

        var numerator: f64 = 0.0;
        var numerator_sub: f64 = 0.0;
        // First window: build numerator and numerator_sub
        var j = middle_idx;
        while (j >= trailing_idx) : (j -= 1) {
            const temp_real = prices[j];
            numerator_sub += temp_real;
            numerator += numerator_sub;
            if (j == 0) break; // Prevent underflow
        }
        var numerator_add: f64 = 0.0;
        middle_idx += 1;
        j = middle_idx;
        while (j <= today_idx) : (j += 1) {
            const temp_real = prices[j];
            numerator_add += temp_real;
            numerator += numerator_add;
        }
        out_idx = period - 1;
        var temp_real = prices[trailing_idx];
        trailing_idx += 1;
        out[out_idx] = numerator * factor;
        out_idx += 1;
        today_idx += 1;

        while (today_idx < len) : (today_idx += 1) {
            numerator -= numerator_sub;
            numerator_sub -= temp_real;
            temp_real = prices[middle_idx];
            middle_idx += 1;
            numerator_sub += temp_real;
            numerator += numerator_add;
            numerator_add -= temp_real;
            temp_real = prices[today_idx];
            numerator_add += temp_real;
            numerator += temp_real;
            temp_real = prices[trailing_idx];
            trailing_idx += 1;
            out[out_idx] = numerator * factor;
            out_idx += 1;
        }
    } else {
        // Even period
        const i = period >> 1;
        const factor = 1.0 / (@as(f64, @floatFromInt(i)) * (@as(f64, @floatFromInt(i)) + 1.0));
        var trailing_idx = lookback_total - lookback_total;
        var middle_idx = trailing_idx + i - 1;
        var today_idx = middle_idx + i;

        var numerator: f64 = 0.0;
        var numerator_sub: f64 = 0.0;
        var j = middle_idx;
        while (j >= trailing_idx) : (j -= 1) {
            const temp_real = prices[j];
            numerator_sub += temp_real;
            numerator += numerator_sub;
            if (j == 0) break; // Prevent underflow
        }
        var numerator_add: f64 = 0.0;
        middle_idx += 1;
        j = middle_idx;
        while (j <= today_idx) : (j += 1) {
            const temp_real = prices[j];
            numerator_add += temp_real;
            numerator += numerator_add;
        }
        out_idx = period - 1;
        var temp_real = prices[trailing_idx];
        trailing_idx += 1;
        out[out_idx] = numerator * factor;
        out_idx += 1;
        today_idx += 1;

        while (today_idx < len) : (today_idx += 1) {
            numerator -= numerator_sub;
            numerator_sub -= temp_real;
            temp_real = prices[middle_idx];
            middle_idx += 1;
            numerator_sub += temp_real;
            numerator_add -= temp_real;
            numerator += numerator_add;
            temp_real = prices[today_idx];
            numerator_add += temp_real;
            numerator += temp_real;
            temp_real = prices[trailing_idx];
            trailing_idx += 1;
            out[out_idx] = numerator * factor;
            out_idx += 1;
        }
    }
    return out;
}

test "Trima work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
    };
    {
        const result = try Trima(&prices, 5, allocator);
        defer allocator.free(result);

        const expected = [_]f64{
            0.000000000,
            0.000000000,
            0.000000000,
            0.000000000,
            57.133333333,
            58.533333333,
            53.100000000,
            51.600000000,
            49.900000000,
            50.877777778,
            45.711111111,
            38.588888889,
            36.066666667,
            36.588888889,
            40.600000000,
            41.622222222,
            32.211111111,
            21.511111111,
            19.655555556,
            26.155555556,
            33.877777778,
            27.355555556,
            20.977777778,
            14.355555556,
            17.977777778,
            23.211111111,
            28.533333333,
            27.222222222,
            22.377777778,
            24.033333333,
        };
        for (result, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
        }
    }

    {
        const result = try Trima(&prices, 6, allocator);
        defer allocator.free(result);

        const expected = [_]f64{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 57.341666667, 54.025000000, 53.908333333, 51.916666667, 48.283333333, 48.366666667, 42.158333333, 37.908333333, 37.650000000, 38.325000000, 40.183333333, 34.758333333, 27.016666667, 24.475000000, 23.158333333, 28.266666667, 28.858333333, 24.150000000, 19.416666667, 16.933333333, 21.041666667, 25.083333333, 26.583333333, 24.341666667, 25.700000000 };
        for (result, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
        }
    }
}
