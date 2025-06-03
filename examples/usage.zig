const std = @import("std");
const DataFrame = @import("ta_lib").DataFrame;
const Rsi = @import("ta_lib").Rsi;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var df = DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("open", &[_]f64{
        100.0, 101.5, 102.0, 103.2, 104.1, 104.8, 105.3, 106.5, 107.0, 108.2,
        109.1, 110.0, 110.5, 111.3, 112.2, 113.0, 113.8, 114.3, 115.0, 115.8,
        116.5, 117.2, 118.0, 118.5, 119.0, 119.5, 120.0, 120.8, 121.2, 122.0,
    });
    try df.addColumnWithData("high", &[_]f64{
        102.0, 103.0, 103.5, 104.5, 105.3, 106.0, 106.8, 107.5, 108.5, 109.5,
        110.5, 111.0, 112.0, 112.8, 113.5, 114.5, 115.0, 115.8, 116.5, 117.2,
        118.0, 118.8, 119.5, 120.0, 120.5, 121.0, 121.8, 122.5, 123.0, 124.0,
    });
    try df.addColumnWithData("low", &[_]f64{
        99.0,  100.2, 101.0, 102.0, 103.0, 104.0, 104.5, 105.0, 106.0, 107.2,
        108.0, 109.0, 109.8, 110.5, 111.5, 112.0, 113.0, 113.5, 114.0, 115.0,
        115.8, 116.0, 117.2, 117.8, 118.2, 118.8, 119.0, 119.8, 120.5, 121.0,
    });
    try df.addColumnWithData("close", &[_]f64{
        101.5, 102.8, 103.0, 104.0, 104.5, 105.5, 106.0, 107.0, 108.0, 109.0,
        110.0, 110.8, 111.5, 112.0, 113.0, 113.5, 114.0, 115.0, 115.5, 116.0,
        117.0, 117.5, 118.0, 119.0, 119.5, 120.0, 120.5, 121.0, 122.0, 123.0,
    });
    try df.addColumnWithData("volume", &[_]f64{
        1000, 1100, 1200, 1300, 1400, 1350, 1450, 1500, 1550, 1600,
        1580, 1620, 1640, 1680, 1700, 1720, 1750, 1780, 1800, 1820,
        1850, 1880, 1900, 1920, 1950, 1980, 2000, 2020, 2050, 2080,
    });

    const rowCount = df.getRowCount();

    const close = try df.getColumnData("close");
    const rsi_result = try Rsi(close, 5, allocator);

    try df.addColumnWithData("rsi", rsi_result);

    std.debug.print("Rows: {}\n", .{rowCount});
    std.debug.print("RSI: {any}\n", .{rsi_result});
}
