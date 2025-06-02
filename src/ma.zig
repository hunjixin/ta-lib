const std = @import("std");
pub const SMA = @import("sma.zig").SMA;
pub const EMA = @import("ema.zig").EMA;
pub const EMAK = @import("ema.zig").EMAK;
pub const TEMA = @import("tema.zig").TEMA;
pub const Trima = @import("trima.zig").Trima;
pub const WMA = @import("wma.zig").WMA;
pub const DEMA = @import("dema.zig").DEMA;
pub const KAMA = @import("kama.zig").KAMA;
pub const MAMA = @import("mama.zig").MAMA;
pub const T3 = @import("t3.zig").T3;

pub const MaType = enum {
    SMA, // Simple Moving Average
    EMA, // Exponential Moving Average
    WMA, // Weighted Moving Average
    DEMA, // Double Exponential Moving Average
    TEMA, // Triple Exponential Moving Average
    TRIMA, // Triangular Moving Average
    KAMA, // Kaufman's Adaptive Moving Average
    MAMA, // MESA Adaptive Moving Average
    T3MA, // T3 Moving Average
};

pub fn Ma(
    inReal: []const f64,
    inTimePeriod: usize,
    inMatype: MaType,
    allocator: std.mem.Allocator,
) ![]f64 {
    if (inTimePeriod == 1) {
        const out_real = try allocator.alloc(f64, inReal.len);
        @memcpy(out_real, inReal);
        return out_real;
    }

    return switch (inMatype) {
        .SMA => try SMA(inReal, inTimePeriod, allocator),
        .EMA => try EMA(inReal, inTimePeriod, allocator),
        .WMA => try WMA(inReal, inTimePeriod, allocator),
        .DEMA => try DEMA(inReal, inTimePeriod, allocator),
        .TEMA => try TEMA(inReal, inTimePeriod, allocator),
        .TRIMA => try Trima(inReal, inTimePeriod, allocator),
        .KAMA => try KAMA(inReal, inTimePeriod, allocator),
        .MAMA => {
            const out_real, const _ignore = try MAMA(inReal, 0.5, 0.05, allocator);
            allocator.free(_ignore);
            return out_real;
        },
        .T3MA => try T3(inReal, inTimePeriod, 0.7, allocator),
    };
}
