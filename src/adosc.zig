const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const AD = @import("./lib.zig").AD;
const EMA = @import("./lib.zig").EMA;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Accumulation/Distribution Oscillator (ADOSC).
///
/// The ADOSC is a technical analysis indicator that measures the momentum
/// of the Accumulation/Distribution Line using the difference between two
/// exponential moving averages (EMAs) of the Accumulation/Distribution Line.
///
/// Formula:
/// ADOSC = EMA(fast_period, ADL) - EMA(slow_period, ADL)
///
/// Where:
/// - ADL (Accumulation/Distribution Line) is calculated as:
///   ADL = ((Close - Low) - (High - Close)) / (High - Low) * Volume
///
/// Parameters:
/// - `fast_period`: The period for the fast EMA.
/// - `slow_period`: The period for the slow EMA.
/// - `high`: The high price of the asset.
/// - `low`: The low price of the asset.
/// - `close`: The closing price of the asset.
/// - `volume`: The trading volume of the asset.
///
/// Returns:
/// - The ADOSC value, which indicates the strength of buying or selling pressure.
pub fn ADOSC(
    df: *DataFrame(f64),
    fast_period: usize,
    slow_period: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    // Get columns
    const high = try df.getColumnData("High");
    const low = try df.getColumnData("Low");
    const close = try df.getColumnData("Close");
    const volume = try df.getColumnData("Volume");
    const len = high.len;

    if (fast_period < 2 or slow_period < 2) {
        return try allocator.alloc(f64, len);
    }

    const slowest_period = if (fast_period > slow_period) fast_period else slow_period;
    const lookback_total = slowest_period - 1;
    var out = try allocator.alloc(f64, len);
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

    // Initialize AD, fastEMA, slowEMA at the first valid index
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

    // Fill leading values with NaN
    for (0..lookback_total) |i| {
        out[i] = std.math.nan(f64);
    }

    return out;
}

test "ADOSC calculation" {
    const gpa = std.testing.allocator;
    // Create a mock DataFrame
    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    // Add "High", "Low", "Close", and "Volume" columns
    try df.addColumnWithData("High", &[_]f64{ 10.0, 12.0, 14.0, 16.0, 18.0 });
    try df.addColumnWithData("Low", &[_]f64{ 5.0, 6.0, 7.0, 8.0, 9.0 });
    try df.addColumnWithData("Close", &[_]f64{ 7.0, 10.0, 12.0, 15.0, 17.0 });
    try df.addColumnWithData("Volume", &[_]f64{ 1000.0, 1500.0, 2000.0, 2500.0, 3000.0 });

    // Expected ADOSC values (manually calculated or from a trusted source)
    // Adjust expected ADOSC values to have 5 elements
    const expected_adosc = &[_]f64{ 0, 0, 212.30158730158723, 475.52910052910056, 749.779541446208 };
    // Calculate ADOSC
    const short_period = 2;
    const long_period = 3;
    const adosc_values = try ADOSC(&df, short_period, long_period, gpa);
    defer gpa.free(adosc_values);

    // Print ADOSC values
    std.debug.print("ADOSC values: {any}\n", .{adosc_values});
    for (2..expected_adosc.len) |i| {
        try std.testing.expect(std.math.approxEqAbs(f64, adosc_values[i], expected_adosc[i], 1e-9));
    }
}
