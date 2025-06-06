const std = @import("std");
const Ad = @import("./lib.zig").Ad;
const Ema = @import("./lib.zig").Ema;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Accumulation/Distribution Oscillator (AdOsc).
///
/// The AdOsc is a technical analysis indicator that measures the momentum
/// of the Accumulation/Distribution Line using the difference between two
/// exponential moving averages (EMAs) of the Accumulation/Distribution Line.
///
/// Formula:
/// AdOsc = Ema(fast_period, ADL) - Ema(slow_period, ADL)
///
/// Where:
/// - ADL (Accumulation/Distribution Line) is calculated as:
///   ADL = ((Close - Low) - (High - Close)) / (High - Low) * Volume
///
/// Parameters:
/// - `high`: The high price of the asset.
/// - `low`: The low price of the asset.
/// - `close`: The closing price of the asset.
/// - `volume`: The trading volume of the asset.
/// - `fast_period`: The period for the fast Ema.
/// - `slow_period`: The period for the slow Ema.
///
/// Returns:
/// - The AdOsc value, which indicates the strength of buying or selling pressure.
pub fn AdOsc(
    high: []const f64,
    low: []const f64,
    close: []const f64,
    volume: []const f64,
    fast_period: usize,
    slow_period: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = high.len;

    if (fast_period < 2 or slow_period < 2) {
        return try allocator.alloc(f64, len);
    }

    const slowest_period = if (fast_period > slow_period) fast_period else slow_period;
    const lookback_total = slowest_period - 1;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);

    var ad: f64 = 0.0;
    const fastk = 2.0 / (@as(f64, @floatFromInt(fast_period)) + 1);
    const one_minus_fastk = 1.0 - fastk;
    const slowk = 2.0 / (@as(f64, @floatFromInt(slow_period)) + 1);
    const one_minus_slowk = 1.0 - slowk;

    var today: usize = 0;
    var fastEMA: f64 = 0.0;
    var slowEMA: f64 = 0.0;

    if (len == 0) return out;

    // Initialize Ad, fastEMA, slowEMA at the first valid index
    {
        const high0 = high[today];
        const low0 = low[today];
        const close0 = close[today];
        const vol0 = volume[today];
        const tmp = high0 - low0;
        if (tmp > 0.0) {
            ad += (((close0 - low0) - (high0 - close0)) / tmp) * vol0;
        }
        fastEMA = ad;
        slowEMA = ad;
        today += 1;
    }

    // Warm up EMAs up to lookback_total
    while (today < lookback_total and today < len) : (today += 1) {
        const highv = high[today];
        const lowv = low[today];
        const closev = close[today];
        const vol = volume[today];
        const tmp = highv - lowv;
        if (tmp > 0.0) {
            ad += (((closev - lowv) - (highv - closev)) / tmp) * vol;
        }
        fastEMA = (fastk * ad) + (one_minus_fastk * fastEMA);
        slowEMA = (slowk * ad) + (one_minus_slowk * slowEMA);
    }

    var outIdx = lookback_total;
    while (today < len) : (today += 1) {
        const highv = high[today];
        const lowv = low[today];
        const closev = close[today];
        const vol = volume[today];
        const tmp = highv - lowv;
        if (tmp > 0.0) {
            ad += (((closev - lowv) - (highv - closev)) / tmp) * vol;
        }
        fastEMA = (fastk * ad) + (one_minus_fastk * fastEMA);
        slowEMA = (slowk * ad) + (one_minus_slowk * slowEMA);
        out[outIdx] = fastEMA - slowEMA;
        outIdx += 1;
    }
    return out;
}

test "AdOsc calculation" {
    const gpa = std.testing.allocator;

    const high = [_]f64{ 10.0, 12.0, 14.0, 16.0, 18.0 };
    const low = [_]f64{ 5.0, 6.0, 7.0, 8.0, 9.0 };
    const close = [_]f64{ 7.0, 10.0, 12.0, 15.0, 17.0 };
    const volume = [_]f64{ 1000.0, 1500.0, 2000.0, 2500.0, 3000.0 };

    const expected_adosc = &[_]f64{ 0, 0, 212.30158730158723, 475.52910052910056, 749.779541446208 };
    // Calculate AdOsc
    const short_period = 2;
    const long_period = 3;
    const adosc_values = try AdOsc(&high, &low, &close, &volume, short_period, long_period, gpa);
    defer gpa.free(adosc_values);

    // Print AdOsc values
    for (0..expected_adosc.len) |i| {
        try std.testing.expectApproxEqAbs(expected_adosc[i], adosc_values[i], 1e-9);
    }
}
