const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const IsZero = @import("./utils.zig").IsZero;

/// Calculates the Relative Strength Index (RSI) for a given array of closing prices.
///
/// The RSI is a momentum oscillator that measures the speed and change of price movements.
/// It is calculated using the following formula:
///
///   RSI = 100 - (100 / (1 + RS))
///
/// where RS (Relative Strength) is the average of 'n' days' up closes divided by the average of 'n' days' down closes,
/// and 'n' is the input parameter `inTimePeriod`.
///
/// Parameters:
///   closes: Array of closing prices (slice of f64).
///   inTimePeriod: The period over which to calculate the RSI (typically 14).
///   allocator: Allocator to use for the output array.
///
/// Returns:
///   An array of f64 values representing the RSI for each period, allocated using the provided allocator.
///
/// Errors:
///   Returns an error if allocation fails or if input parameters are invalid.
///
/// Example:
///   const rsi = try RSI(closes, 14, allocator);
pub fn RSI(closes: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, closes.len);
    @memset(out, 0);

    if (inTimePeriod < 2) {
        return out;
    }

    var prevGain: f64 = 0.0;
    var prevLoss: f64 = 0.0;

    for (1..inTimePeriod + 1) |i| {
        if (closes[i] > closes[i - 1]) {
            prevGain += (closes[i] - closes[i - 1]);
        } else {
            prevLoss += (closes[i - 1] - closes[i]);
        }
    }

    const inTimePeriodf: f64 = @floatFromInt(inTimePeriod);
    prevLoss /= @as(f64, inTimePeriodf);
    prevGain /= @as(f64, inTimePeriodf);

    const tmp = prevGain + prevLoss;
    if (IsZero(tmp)) {
        out[inTimePeriod] = 0.0;
    } else {
        out[inTimePeriod] = 100.0 * (prevGain / tmp);
    }

    for (inTimePeriod + 1..closes.len) |i| {
        const diff = closes[i] - closes[i - 1];

        prevGain = prevGain * (inTimePeriodf - 1);
        prevLoss = prevLoss * (inTimePeriodf - 1);
        if (diff > 0) {
            prevGain += diff;
        } else {
            prevLoss -= diff;
        }
        prevGain = prevGain / inTimePeriodf;
        prevLoss = prevLoss / inTimePeriodf;

        const dividor = prevGain + prevLoss;
        if (IsZero(dividor)) {
            out[i] = 0;
        } else {
            out[i] = 100 * (prevGain / dividor);
        }
    }
    return out;
}

test "RSI: basic functionality with known values" {
    const allocator = std.testing.allocator;
    // Example close prices and expected RSI values (rounded, for demonstration)
    // 先增长后下跌的趋势数据
    const closes = [_]f64{
        10.0, 11.0, 12.5, 13.0, 14.2, 15.0, 16.5, 17.0, 17.8, 18.0, // 上涨
        17.5, 16.8, 16.0, 15.5, 15.0, 14.2, 13.5, 13.0, 12.5, 12.0, // 下跌
    };
    const period = 3;

    const result = try RSI(&closes, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 100, 100, 100, 100, 100, 100, 100, 72.52167357708255, 45.9858027199503, 28.25962428212623, 20.75809109716329, 14.84655250742954, 8.818977761760397, 5.753268615914092, 4.191948739046798, 2.979205310967679, 2.077614910366095 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}
