const std = @import("std");

pub const MyError = error{
    ColumnNotFound,
    RowIndexOutOfBounds,
    RowColumnMismatch,
    TooFewDataPoints,
};

pub fn Column(comptime T: type) type {
    return struct {
        name: []const u8,
        data: std.ArrayList(T),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, name: []const u8) !Self {
            return Self{
                .name = name,
                .data = try std.ArrayList(T).initCapacity(allocator, 8),
            };
        }

        pub fn deinit(self: *const Self) void {
            self.data.deinit();
        }

        pub fn push(self: *Self, value: T) !void {
            try self.data.append(value);
        }

        pub fn get(self: *const Self, index: usize) T {
            return self.data.items[index];
        }

        pub fn len(self: *const Self) usize {
            return self.data.items.len;
        }

        pub fn asSlice(self: *const Self) []const T {
            return self.data.items[0..self.data.items.len];
        }
    };
}

pub fn DataFrame(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        columns: std.ArrayList(Column(T)),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .allocator = allocator,
                .columns = std.ArrayList(Column(T)).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.columns.items) |*col| {
                col.deinit();
            }
            self.columns.deinit();
        }

        pub fn addColumn(self: *Self, name: []const u8) !void {
            const col = try Column(T).init(self.allocator, name);
            try self.columns.append(col);
        }

        pub fn addColumnWithData(self: *Self, name: []const u8, values: []const T) !void {
            var col = try Column(T).init(self.allocator, name);
            for (values) |v| {
                try col.push(v);
            }

            try self.columns.append(col);
        }

        pub fn addRow(self: *Self, values: []const T) !void {
            if (values.len != self.columns.items.len)
                return error.RowColumnMismatch;

            for (0..self.columns.items.len) |i| {
                try self.columns.items[i].push(values[i]);
            }
        }

        fn findColumnByName(self: *const Self, name: []const u8) !usize {
            for (0..self.columns.items.len) |i| {
                if (std.mem.eql(u8, self.columns.items[i].name, name)) return i;
            }
            return MyError.ColumnNotFound;
        }

        pub fn getValue(self: *const Self, colName: []const u8, rowIndex: usize) T {
            const idx = try self.findColumnByName(colName);

            if (rowIndex >= self.columns.items[idx].len())
                return MyError.RowIndexOutOfBounds;

            return self.columns.items[idx].get(rowIndex);
        }

        pub fn getRowCount(self: *const Self) usize {
            if (self.columns.items.len == 0) {
                return 0;
            }
            return self.columns.items[0].len();
        }

        pub fn getColumnData(self: *const Self, colName: []const u8) ![]const T {
            const idx = try self.findColumnByName(colName);
            return self.columns.items[idx].data.items[0..self.columns.items[idx].len()];
        }

        pub fn getRow(self: *const Self, rowIndex: usize, allocator: std.mem.Allocator) ![]T {
            const colCount = self.columns.items.len;
            if (colCount == 0) return MyError.RowColumnMismatch;

            for (0..colCount) |i| {
                var col = &self.columns.items[i];
                if (rowIndex >= col.len()) return MyError.RowIndexOutOfBounds;
            }

            var rowData = try allocator.alloc(T, colCount);

            for (0..colCount) |i| {
                rowData[i] = self.columns.items[i].get(rowIndex);
            }

            return rowData;
        }
    };
}

test "DataFrame basic functionality" {
    var allocator = std.testing.allocator;
    const DF = DataFrame(i32);

    var df = try DF.init(allocator);
    defer df.deinit();

    try df.addColumn("a");
    try df.addColumn("b");
    try df.addColumn("c");

    try df.addRow(&[_]i32{ 1, 2, 3 });
    try df.addRow(&[_]i32{ 4, 5, 6 });
    try df.addRow(&[_]i32{ 7, 8, 9 });

    // 测试 getValue
    try std.testing.expect(try df.getValue("a", 0) == 1);
    try std.testing.expect(try df.getValue("b", 1) == 5);
    try std.testing.expect(try df.getValue("c", 2) == 9);
    const result = df.getValue("c", 3);
    try std.testing.expectError(MyError.RowIndexOutOfBounds, result);

    // 测试 getColumnData
    const col_a = try df.getColumnData("a");
    try std.testing.expect(col_a.len == 3);
    try std.testing.expect(col_a[0] == 1);
    try std.testing.expect(col_a[2] == 7);

    // 测试 getRow
    const row1 = try df.getRow(1, allocator);
    try std.testing.expect(row1.len == 3);
    try std.testing.expect(row1[0] == 4);
    try std.testing.expect(row1[1] == 5);
    try std.testing.expect(row1[2] == 6);
    allocator.free(row1);

    // 测试找不到列
    try std.testing.expectError(MyError.ColumnNotFound, df.getValue("nonexistent", 0));
    try std.testing.expectError(MyError.ColumnNotFound, df.getColumnData("nonexistent"));
}
