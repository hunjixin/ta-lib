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
    short_period: usize,
    long_period: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const ad_values = try AD(df, allocator);
    defer ad_values.deinit();

    const ema_short = try EMA(ad_values.asSlice(), short_period, allocator);
    const ema_long = try EMA(ad_values.asSlice(), long_period, allocator);
    defer allocator.free(ema_long);
    defer allocator.free(ema_short);

    const adosc_values = try allocator.alloc(f64, ema_short.len);
    for (0..ema_short.len) |i| {
        adosc_values[i] = ema_short[i] - ema_long[i];
    }

    return adosc_values;
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
    const expected_adosc = &[_]f64{ 0e0, 5e1, 3.690476190476189e2, 5.585317460317456e2, 7.928240740740739e2 };
    // Calculate ADOSC
    const short_period = 2;
    const long_period = 3;
    const adosc_values = try ADOSC(&df, short_period, long_period, gpa);
    defer gpa.free(adosc_values);

    // Print ADOSC values
    std.debug.print("ADOSC values: {any}\n", .{adosc_values});
    // Verify ADOSC values
    for (0..expected_adosc.len) |i| {
        try std.testing.expect(std.math.approxEqAbs(f64, adosc_values[i], expected_adosc[i], 1e-9));
    }
}
