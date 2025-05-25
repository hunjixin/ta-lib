const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const SMA = @import("./lib.zig").SMA;
const IsZero = @import("./utils.zig").IsZero;
const MyError = @import("./lib.zig").MyError;

// The AD function calculates the Accumulation/Distribution Line (ADL) for a given DataFrame.
// Formula: ADL = SUM(((2 * Close - High - Low) / (High - Low)) * Volume)
// This is a cumulative indicator that uses the relationship between the stock's price and volume
// to determine the flow of money into or out of a stock over time.
pub fn StochF(
    df: *const DataFrame(f64),
    inFastKPeriod: usize,
    inFastDPeriod: usize,
    allocator: std.mem.Allocator,
) !struct { []f64, []f64 } {
    const high = try df.getColumnData("High");
    const low = try df.getColumnData("Low");
    const close = try df.getColumnData("Close");
    const len = close.len;

    var outFastK = try allocator.alloc(f64, len);
    var outFastD = try allocator.alloc(f64, len);
    @memset(outFastK, 0);
    @memset(outFastD, 0);

    const lookbackK = inFastKPeriod - 1;
    const lookbackFastD = inFastDPeriod - 1;
    const lookbackTotal = lookbackK + lookbackFastD;
    const startIdx = lookbackTotal;

    if (len <= startIdx) return .{ outFastK, outFastD };

    const tempLen = len - lookbackK + 1;
    var tempBuffer = try allocator.alloc(f64, tempLen);
    defer allocator.free(tempBuffer);
    @memset(tempBuffer, 0);

    for (lookbackK..len) |today| {
        const outIdx = today - lookbackK;
        const windowStart = today - lookbackK;
        var lowest = low[windowStart];
        var highest = high[windowStart];
        for (windowStart..today + 1) |i| {
            if (low[i] < lowest) lowest = low[i];
            if (high[i] > highest) highest = high[i];
        }
        const diff = (highest - lowest) / 100.0;
        tempBuffer[outIdx] = if (!IsZero(diff))
            (close[today] - lowest) / diff
        else
            0.0;
    }

    std.debug.print("tempBuffer {any}", .{tempBuffer});
    const tempBuffer1 = try SMA(tempBuffer, inFastDPeriod, allocator);
    defer allocator.free(tempBuffer1);
    for (lookbackTotal..len) |j| {
        const i = j - lookbackTotal + 1;
        outFastK[j] = tempBuffer[i];
        outFastD[j] = tempBuffer1[i];
    }
    return .{ outFastK, outFastD };
}

test "StochF calculation works correctly" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("High", &[_]f64{ 10.0, 12.0, 14.0, 13.0, 15.0 });
    try df.addColumnWithData("Low", &[_]f64{ 5.0, 6.0, 7.0, 8.0, 9.0 });
    try df.addColumnWithData("Close", &[_]f64{ 7.0, 10.0, 12.0, 11.0, 14.0 });

    // Use FastK period = 3, FastD period = 2
    const result = try StochF(&df, 3, 2, gpa);
    defer gpa.free(result[0]);
    defer gpa.free(result[1]);

    std.debug.print("StochF: {any}\n", .{result});
}

test "StochF calculation works with bigger dataset" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    // 直接使用固定的随机数据字面量，保证每次数据一致且不依赖生成器
    const high_data = [_]f64{
        15.2, 16.8, 18.5, 19.1, 20.7, 22.3, 23.0, 24.8, 26.1, 27.5,
        28.9, 30.2, 31.7, 33.0, 34.4, 35.8, 37.1, 38.5, 39.9, 41.2,
    };
    const low_data = [_]f64{
        13.1, 14.0, 15.7, 16.2, 17.8, 19.0, 20.2, 21.5, 22.7, 24.0,
        25.1, 26.3, 27.6, 28.9, 30.1, 31.4, 32.7, 34.0, 35.2, 36.5,
    };
    const close_data = [_]f64{
        14.0, 16.0, 17.2, 18.7, 19.9, 21.5, 22.6, 23.9, 25.0, 26.8,
        27.7, 29.1, 30.5, 31.8, 33.2, 34.7, 36.0, 37.3, 38.7, 40.0,
    };

    try df.addColumnWithData("High", &high_data);
    try df.addColumnWithData("Low", &low_data);
    try df.addColumnWithData("Close", &close_data);

    // Use FastK period = 3, FastD period = 2
    const result = try StochF(&df, 3, 2, gpa);
    defer gpa.free(result[0]);
    defer gpa.free(result[1]);

    const expect_fastk = [_]f64{
        0,                 0,                 0,                 92.156862745098,   83.99999999999999, 86.88524590163934, 92.30769230769234,
        84.48275862068962, 81.35593220338981, 88.33333333333334, 80.64516129032259, 82.25806451612907, 81.81818181818183, 82.08955223880598,
        82.35294117647064, 84.05797101449282, 84.28571428571426, 83.09859154929575, 83.33333333333339, 83.33333333333331,
    };
    const expect_fastd = [_]f64{
        0,                 0,                 0,                 84.04139433551195, 88.07843137254899, 85.44262295081967, 89.59646910466584,
        88.39522546419099, 82.91934541203972, 84.84463276836158, 84.48924731182797, 81.45161290322582, 82.03812316715545, 81.9538670284939,
        82.2212467076383,  83.20545609548172, 84.17184265010354, 83.69215291750501, 83.21596244131457, 83.33333333333336,
    };

    for (result[0], expect_fastk) |actual, expect| {
        try std.testing.expectApproxEqAbs(actual, expect, 1e-8);
    }
    for (result[1], expect_fastd) |actual, expect| {
        try std.testing.expectApproxEqAbs(actual, expect, 1e-8);
    }
}
