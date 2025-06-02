const std = @import("std");
const MyError = @import("./lib.zig").MyError;

pub fn Obv(close: []const f64, volume: []const f64, allocator: std.mem.Allocator) ![]f64 {
    if (close.len != volume.len) return MyError.RowColumnMismatch;

    var obvCol = try allocator.alloc(f64, close.len);
    var obv: f64 = 0.0;

    obvCol[0] = 0.0;

    for (1..close.len) |i| {
        if (close[i] > close[i - 1]) {
            obv += volume[i];
        } else if (close[i] < close[i - 1]) {
            obv -= volume[i];
        }
        obvCol[i] = obv;
    }

    return obvCol;
}

test "Obv calculation" {
    const gpa = std.testing.allocator;

    const close = [_]f64{ 100.0, 105.0, 102.0, 108.0, 107.0 };
    const volume = [_]f64{ 1000.0, 1500.0, 1200.0, 1800.0, 1600.0 };

    const obvCol = try Obv(&close, &volume, gpa);
    defer gpa.free(obvCol);

    // Verify Obv values
    const expected = [_]f64{ 0.0, 1500.0, 300.0, 2100.0, 500.0 };
    for (expected, 0..) |val, i| {
        try std.testing.expectApproxEqAbs(val, obvCol[i], 1e-9);
    }
}

test "Obv with mismatched column lengths" {
    const gpa = std.testing.allocator;

    const close = [_]f64{ 100.0, 105.0 };
    const volume = [_]f64{1000.0};

    // Attempt to calculate Obv and expect an error
    const result = Obv(&close, &volume, gpa);
    try std.testing.expect(result == MyError.RowColumnMismatch);
}
