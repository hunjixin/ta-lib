const std = @import("std");
const Adx = @import("./lib.zig").Adx;

pub fn Adxr(inHigh: []const f64, inLow: []const f64, inClose: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const n = inHigh.len;
    var out = try allocator.alloc(f64, n);
    errdefer allocator.free(out);
    @memset(out, 0);
    if (n == 0 or period < 2) return out;

    const tmpadx = try Adx(inHigh, inLow, inClose, period, allocator);
    defer allocator.free(tmpadx);

    const start_idx = (2 * period) - 1;
    var i = start_idx;
    var j = start_idx + period - 1;
    var out_idx = start_idx + period - 1;
    while (out_idx < n) : ({
        out_idx += 1;
        i += 1;
        j += 1;
    }) {
        out[out_idx] = (tmpadx[i] + tmpadx[j]) / 2.0;
    }

    return out;
}

test "Adxr work correctly" {
    var allocator = std.testing.allocator;

    // Prepare simple test data
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 };
    const closes = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 19, 20, 21, 23, 22, 24, 26, 25, 27, 29, 28, 32, 33, 34, 35 };

    const adx = try Adxr(&highs, &lows, &closes, 4, allocator);
    defer allocator.free(adx);
    const expected = [_]f64{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 100.000000000, 90.789132364, 83.574216898, 78.163030298, 64.376863041, 53.092663427, 43.859122198, 36.813042854, 29.680794394, 23.561216531, 21.546045039, 20.199816055, 17.831396253, 20.063770654, 24.719782246, 26.853042875, 32.997258838, 39.212122447, 44.917263944, 52.662775320 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-6);
    }
}
