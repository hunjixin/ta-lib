const std = @import("std");
const StochF = @import("./lib.zig").StochF;
const RSI = @import("./lib.zig").RSI;
const MaType = @import("./lib.zig").MaType;
const Ma = @import("./lib.zig").Ma;
const IsZero = @import("./utils.zig").IsZero;
const MyError = @import("./lib.zig").MyError;

pub fn StochRsi(
    inReal: []const f64,
    inTimePeriod: usize,
    inFastKPeriod: usize,
    inFastDPeriod: usize,
    inFastDMAType: MaType,
    allocator: std.mem.Allocator,
) !struct { []f64, []f64 } {
    const len = inReal.len;
    const lookbackSTOCHF = (inFastKPeriod - 1) + (inFastDPeriod - 1);
    const lookbackTotal = inTimePeriod + lookbackSTOCHF;
    const startIdx = lookbackTotal;
    const tempRSIBuffer = try RSI(inReal, inTimePeriod, allocator);
    defer allocator.free(tempRSIBuffer);

    const tempk, const tempd = try StochF(tempRSIBuffer, tempRSIBuffer, tempRSIBuffer, inFastKPeriod, inFastDPeriod, inFastDMAType, allocator);
    defer allocator.free(tempd);
    defer allocator.free(tempk);

    var outFastK = try allocator.alloc(f64, len);
    @memset(outFastK, 0);
    var outFastD = try allocator.alloc(f64, len);
    @memset(outFastD, 0);
    for (startIdx..len) |i| {
        outFastK[i] = tempk[i];
        outFastD[i] = tempd[i];
    }

    return .{ outFastK, outFastD };
}

test "StochF calculation works with bigger dataset" {
    const gpa = std.testing.allocator;

    const high_data = [_]f64{ 10.0, 25.0, 5.0, 40.0, 60.0, 15.0, 80.0, 100.0, 55.0, 120.0, 90.0, 150.0, 30.0, 200.0, 170.0, 250.0, 60.0, 300.0, 20.0, 350.0 };

    // Use FastK period = 3, FastD period = 2
    const result = try StochRsi(&high_data, 5, 3, 2, MaType.SMA, gpa);
    defer gpa.free(result[0]);
    defer gpa.free(result[1]);

    const expect_fastk = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 75.77134329101783, 26.267457897545647, 100, 0, 86.09354258901296, 77.39366409145038, 100, 0, 81.87760738631782, 0, 88.4333571411185,
    };
    const expect_fastd = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 50, 37.885671645508914, 51.019400594281734, 63.13372894877282, 50, 43.04677129450648, 81.74360334023166, 88.69683204572519, 50, 40.93880369315891, 40.93880369315891, 44.21667857055925,
    };

    for (result[0], expect_fastk) |actual, expect| {
        try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
    }
    for (result[1], expect_fastd) |actual, expect| {
        try std.testing.expectApproxEqAbs(expect, actual, 1e-8);
    }
}
