const std = @import("std");
const IsZero = @import("./utils.zig").IsZero;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Commodity Channel Index (Cci) for the given data frame.
///
/// The Commodity Channel Index (Cci) is a momentum-based oscillator used to identify cyclical trends in a financial market.
/// It measures the variation of a security's price from its statistical mean. High positive values indicate that prices are well above their average, which may signal an overbought condition; low negative values indicate an oversold condition.
///
/// The Cci is calculated using the following formula:
///   Cci = (Typical Price - SMA) / (0.015 * Mean Deviation)
/// where:
///   - Typical Price = (High + Low + Close) / 3
///   - SMA = Simple Moving Average of Typical Price over the specified period
///   - Mean Deviation = Average of the absolute differences between Typical Price and SMA
///
/// Parameters:
///   - `high`: The high price of the asset.
///   - `low`: The low price of the asset.
///   - `close`: The closing price of the asset.
///   - `inTimePeriod`: The period over which to calculate the Cci (e.g., 14).
///   - `allocator`: Memory allocator to use for the result array.
///
/// Returns:
///   - An array of f64 values representing the Cci for each row.
///
/// Errors:
///   - Returns an error if memory allocation fails or if input data is insufficient.
///
/// Example usage:
/// ```zig
/// const cci_values = try Cci(&data_frame, 14, allocator);
/// ```
pub fn Cci(
    inHigh: []const f64,
    inLow: []const f64,
    inClose: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = inHigh.len;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);
    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    const lookbackTotal = inTimePeriod - 1;

    var buffer = try allocator.alloc(f64, inTimePeriod);
    defer allocator.free(buffer);

    for (0..lookbackTotal) |i| {
        buffer[i] = (inHigh[i] + inLow[i] + inClose[i]) / 3;
    }
    var circBufferIdx = lookbackTotal;
    for (inTimePeriod - 1..len) |i| {
        const lastValue = (inHigh[i] + inLow[i] + inClose[i]) / 3;
        buffer[circBufferIdx] = lastValue;

        var theAverage: f64 = 0.0;
        for (buffer) |v| {
            theAverage += v;
        }
        const ma = theAverage / inTimePeriodF;
        var sum: f64 = 0.0;
        for (0..buffer.len) |j| {
            sum += @abs(buffer[j] - ma);
        }

        const tmp1 = lastValue - ma;
        if ((tmp1 != 0.0) and (sum != 0.0)) {
            out[i] = tmp1 / (0.015 * (sum / inTimePeriodF));
        } else {
            out[i] = 0.0;
        }
        circBufferIdx += 1;
        if (circBufferIdx > inTimePeriod - 1) {
            circBufferIdx = 0;
        }
    }
    return out;
}

test "Cci work correctly" {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const adx = try Cci(&highs, &lows, &closes, 5, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 113.82113821138218, 92.10526315789485, 47.61904761904769, 142.85714285714295, 61.40350877192985, 166.6666666666667, 41.09303295786401, -51.64319248826292, -50.458715596330265, -54.80984340044743, -32.828282828282845 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

test "Cci handles with 1 period" {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const adx = try Cci(&highs, &lows, &closes, 1, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}
