const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const MyError = @import("./lib.zig").MyError;

pub fn OBV(df: *DataFrame(f64), allocator: std.mem.Allocator) !Column(f64) {
    const close = try df.getColumnData("Close");
    const volume = try df.getColumnData("Volume");

    if (close.len != volume.len) return MyError.RowColumnMismatch;

    var obvCol = try Column(f64).init(allocator, "OBV");
    var obv: f64 = 0.0;

    try obvCol.push(obv);

    for (1..close.len) |i| {
        if (close[i] > close[i - 1]) {
            obv += volume[i];
        } else if (close[i] < close[i - 1]) {
            obv -= volume[i];
        }
        try obvCol.push(obv);
    }

    return obvCol;
}

test "OBV calculation" {
    const gpa = std.testing.allocator;

    // Create a mock DataFrame
    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    // Add "Close" column
    try df.addColumnWithData("Close", &[_]f64{ 100.0, 105.0, 102.0, 108.0, 107.0 });

    // Add "Volume" column
    try df.addColumnWithData("Volume", &[_]f64{ 1000.0, 1500.0, 1200.0, 1800.0, 1600.0 });

    // Calculate OBV
    var obvCol = try OBV(&df, gpa);
    defer obvCol.deinit();

    // Verify OBV values
    try std.testing.expect(std.math.approxEqAbs(f64, 0.0, obvCol.get(0), 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, 1500.0, obvCol.get(1), 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, 300.0, obvCol.get(2), 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, 2100.0, obvCol.get(3), 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, 500.0, obvCol.get(4), 1e-9));
}

test "OBV with mismatched column lengths" {
    const gpa = std.testing.allocator;

    // Create a mock DataFrame
    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    // Add "Close" column
    try df.addColumnWithData("Close", &[_]f64{ 100.0, 105.0 });

    // Add "Volume" column with mismatched length
    try df.addColumnWithData("Volume", &[_]f64{1000.0});

    // Attempt to calculate OBV and expect an error
    const result = OBV(&df, gpa);
    try std.testing.expect(result == MyError.RowColumnMismatch);
}
