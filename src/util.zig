pub const std = @import("std");
pub const Alloc = std.mem.Allocator;
pub const List = std.ArrayList;
pub const MultiList = std.MultiArrayList;
pub const Map = std.AutoHashMap;
pub const StrMap = std.StringHashMap;
pub const BitSet = std.DynamicBitSet;
pub const Str = []const u8;

pub const mem = std.mem;
pub const ascii = std.ascii;
pub const sortm = std.sort;
pub const math = std.math;
pub const rand = std.rand;

var gpa_impl = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const gpa = gpa_impl.allocator();

// Add utility functions here

// Useful stdlib functions
pub const tokenizeAny = std.mem.tokenizeAny;
pub const tokenizeSeq = std.mem.tokenizeSequence;
pub const tokenizeSca = std.mem.tokenizeScalar;
pub const splitAny = std.mem.splitAny;
pub const splitSeq = std.mem.splitSequence;
pub const splitSca = std.mem.splitScalar;
pub const indexOf = std.mem.indexOfScalar;
pub const indexOfAny = std.mem.indexOfAny;
pub const indexOfStr = std.mem.indexOfPosLinear;
pub const lastIndexOf = std.mem.lastIndexOfScalar;
pub const lastIndexOfAny = std.mem.lastIndexOfAny;
pub const lastIndexOfStr = std.mem.lastIndexOfLinear;
pub const trim = std.mem.trim;
pub const sliceMin = std.mem.min;
pub const sliceMax = std.mem.max;

pub const print = std.debug.print;
pub const assert = std.debug.assert;

pub const sort = std.sort.block;
pub const asc = std.sort.asc;
pub const desc = std.sort.desc;

pub const ws = std.ascii.whitespace;

pub fn strip(str: Str) Str {
    return trim(u8, str, &ws);
}

pub fn linesOf(comptime T: type, str: Str) ParseError![]T {
    var items = List(T).init(gpa);

    var ls = lines(str);
    while (ls.next()) |line| {
        const item = try tryParse(T, line);
        items.append(item) catch @panic("oom");
    }

    return items.items;
}

pub fn chunksOf(comptime T: type, str: Str) ParseError![][]T {
    var items = List([]T).init(gpa);

    var cs = chunks(str);
    while (cs.next()) |chunk| {
        var inner = List(T).init(gpa);

        var ls = lines(chunk);
        while (ls.next()) |line| {
            const item = try tryParse(T, line);
            inner.append(item) catch @panic("oom");
        }

        items.append(inner.items) catch @panic("oom");
    }

    return items.items;
}

pub fn columnsOf(comptime T: type, str: Str) ParseError!ColumnsOf(T) {
    var mla = MultiList(T){};

    var ls = lines(str);
    while (ls.next()) |line| {
        const item = try tryParse(T, line);
        mla.append(gpa, item) catch @panic("oom");
    }

    const Field = std.meta.FieldEnum(T);
    const tags = comptime std.meta.tags(Field);
    const fields = comptime std.meta.fields(T);

    var result: ColumnsOf(T) = undefined;
    inline for (tags, fields) |tag, fld| {
        @field(result, fld.name) = mla.items(tag);
    }
    return result;
}

pub fn ColumnsOf(comptime T: type) type {
    const t_info = @typeInfo(T).Struct;

    var col_type: std.builtin.Type.Struct = .{
        .fields = &.{},
        .layout = t_info.layout,
        .decls = &.{},
        .is_tuple = t_info.is_tuple,
    };
    inline for (std.meta.fields(T)) |field| {
        const Column = []field.type;
        const new_field = .{
            .name = field.name,
            .type = Column,
            .alignment = @alignOf(Column),
            .default_value = null,
            .is_comptime = false,
        };
        col_type.fields = col_type.fields ++ .{new_field};
    }

    return @Type(.{ .Struct = col_type });
}

pub fn lines(str: Str) std.mem.TokenIterator(u8, .scalar) {
    return tokenizeSca(u8, str, '\n');
}

pub fn chunks(str: Str) std.mem.TokenIterator(u8, .sequence) {
    return tokenizeSeq(u8, str, "\n\n");
}

pub fn sortAsc(items: anytype) void {
    const Inner = @typeInfo(@TypeOf(items)).Pointer.child;
    sort(Inner, items, {}, asc(Inner));
}

pub fn absDiff(a: anytype, b: anytype) std.meta.Int(.unsigned, @typeInfo(@TypeOf(a)).Int.bits + 1) {
    const T = AbsDiff(@TypeOf(a));
    return @abs(@as(T, a) - @as(T, b));
}

pub fn AbsDiff(comptime T: type) type {
    const Int = @typeInfo(T).Int;
    if (Int.signedness == .signed) return T;
    return std.meta.Int(.signed, Int.bits + 1);
}

pub fn parseBool(str: Str) error{Bool}!bool {
    const val = std.meta.stringToEnum(enum { false, true }, str) orelse return error.Bool;
    return @intFromEnum(val) != 0;
}

pub fn parseInt(comptime T: type, str: Str) error{Int}!T {
    return std.fmt.parseInt(T, str, 10) catch error.Int;
}

pub fn parseFloat(comptime T: type, str: Str) error{Float}!T {
    return std.fmt.parseFloat(T, str) catch error.Float;
}

pub fn parseEnum(comptime E: type, str: Str) error{Enum}!E {
    return std.meta.stringToEnum(E, str) orelse error.Enum;
}

pub const Separator = union(std.mem.DelimiterType) {
    sequence: []const u8,
    any: []const u8,
    scalar: u8,

    pub fn tokenize(
        comptime self: Separator,
        comptime T: type,
        str: Str,
    ) std.mem.TokenIterator(T, self) {
        switch (self) {
            .sequence => |seq| return std.mem.tokenizeSequence(T, str, seq),
            .any => |any| return std.mem.tokenizeAny(T, str, any),
            .scalar => |scalar| return std.mem.tokenizeScalar(T, str, scalar),
        }
    }
};

pub const ParseOpts = struct {
    separator: Separator = .{ .any = " ," },
};

pub const ParseError = error{
    Bool,
    Int,
    Float,
    Enum,
    Union,
    MissingToken,
    ExtraToken,
};

pub fn parse(comptime T: type, str: Str) T {
    return parseOpt(T, str, .{});
}

pub fn parseOpt(comptime T: type, str: Str, comptime opts: ParseOpts) T {
    return tryParseOpt(T, str, opts) catch @panic("parse for expected type " ++ @typeName(T));
}

pub fn tryParse(comptime T: type, str: Str) ParseError!T {
    return tryParseOpt(T, str, .{});
}

pub fn tryParseOpt(comptime T: type, str: Str, comptime opts: ParseOpts) ParseError!T {
    var tokens = opts.separator.tokenize(u8, str);
    const res = try parseTokens(T, opts.separator, &tokens);
    if (tokens.next() != null) {
        if (@typeInfo(T) == .Optional and tokens.next() == null) {
            return res;
        }
        return error.ExtraToken;
    }
    return res;
}

pub fn parseTokens(
    comptime T: type,
    comptime delim: std.mem.DelimiterType,
    tokens: *std.mem.TokenIterator(u8, delim),
) ParseError!T {
    return switch (@typeInfo(T)) {
        .Void => {},
        .Null => null,
        .Optional => |o| {
            const before = tokens.index;
            return parseTokens(o.child, delim, tokens) catch {
                tokens.index = before;
                return null;
            };
        },
        .Bool => parseBool(tokens.next() orelse return error.MissingToken),
        .Int => parseInt(T, tokens.next() orelse return error.MissingToken),
        .Float => parseFloat(T, tokens.next() orelse return error.MissingToken),
        .Enum => parseEnum(T, tokens.next() orelse return error.MissingToken),
        .Union => |u| {
            const token = tokens.next() orelse return error.MissingToken;
            inline for (u.fields) |f| {
                if (tryParse(f.type, token)) |val| {
                    return @unionInit(T, f.name, val);
                } else |_| {}
            }
            return error.Union;
        },
        .Struct => |s| {
            var result: T = undefined;

            inline for (s.fields) |f| {
                const field_value = try parseTokens(f.type, delim, tokens);
                @field(result, f.name) = field_value;
            }

            return result;
        },
        .Array => |a| {
            var items: [a.len]a.child = undefined;

            inline for (0..a.len) |i| {
                const item = try parseTokens(a.child, delim, tokens);
                items[i] = item;
            }

            return items;
        },
        .Pointer => |p| {
            if (p.size != .Slice) @compileError("The only pointer sized supported are slices.");
            if (p.sentinel != null) @compileError("Sentinel terminated slices are not supported.");
            if (p.child == u8 and p.is_const) {
                return tokens.next() orelse return error.MissingToken;
            } else {
                var items = List(p.child).init(gpa);
                var valid_index = tokens.index;
                while (parseTokens(p.child, delim, tokens)) |token| {
                    valid_index = tokens.index;
                    items.append(token) catch @panic("oom");
                } else |_| {
                    tokens.index = valid_index;
                }
                return items.items;
            }
        },
        else => {
            const msg = std.fmt.comptimePrint(
                "parseInner not implemented for {s} ({})",
                .{ @typeName(T), @typeInfo(T) },
            );
            @compileError(msg);
        },
    };
}

test "parseInner" {
    const t = std.testing;

    try t.expectEqual({}, tryParse(void, ""));

    try t.expectEqual(true, tryParse(bool, "true"));
    try t.expectEqual(false, tryParse(bool, "false"));
    try t.expectError(error.Bool, tryParse(bool, "foo"));

    inline for (.{ u8, u16, u32, u64, i8, i16, i32, i64 }) |T| {
        try t.expectEqual(@as(T, 42), tryParse(T, "42"));
        try t.expectError(error.Int, tryParse(T, "foo"));
    }

    inline for (.{ f32, f64 }) |T| {
        try t.expectEqual(@as(T, 13.37), tryParse(T, "13.37"));
        try t.expectError(error.Float, tryParse(T, "foo"));
    }

    const SomeEnum = enum { foo, bar };
    try t.expectEqual(@as(SomeEnum, .foo), tryParse(SomeEnum, "foo"));
    try t.expectEqual(@as(SomeEnum, .bar), tryParse(SomeEnum, "bar"));
    try t.expectError(error.Enum, tryParse(SomeEnum, "baz"));

    const SomeUnion = union(enum) { foo: i32, bar: f32 };
    try t.expectEqual(@as(SomeUnion, .{ .foo = 42 }), tryParse(SomeUnion, "42"));
    try t.expectEqual(@as(SomeUnion, .{ .bar = 13.37 }), tryParse(SomeUnion, "13.37"));
    try t.expectError(error.Union, tryParse(SomeUnion, "foo"));

    try t.expectEqual([3]u32{ 42, 1337, 84 }, tryParse([3]u32, "42 1337 84"));
    try t.expectError(error.MissingToken, tryParse([3]u32, "42 1337"));
    try t.expectError(error.ExtraToken, tryParse([3]u32, "42 1337 84 84"));

    const SomeStruct = struct { foo: i32, bar: f32 };
    try t.expectEqual(SomeStruct{ .foo = 42, .bar = 13.37 }, tryParse(SomeStruct, "42 13.37"));
    try t.expectError(error.MissingToken, tryParse(SomeStruct, "42"));
    try t.expectError(error.ExtraToken, tryParse(SomeStruct, "42 13.37 13.37"));

    const SomeTuple = struct { u32, f64 };
    try t.expectEqual(SomeTuple{ 42, 13.37 }, tryParse(SomeTuple, "42 13.37"));
    try t.expectError(error.MissingToken, tryParse(SomeTuple, "42"));
    try t.expectError(error.ExtraToken, tryParse(SomeTuple, "42 13.37 13.37"));

    const S = struct { a: i32, b: ?bool, c: f32 };
    try t.expectEqual(S{ .a = 42, .b = true, .c = 13.37 }, tryParse(S, "42, true, 13.37"));
    try t.expectEqual(S{ .a = 42, .b = null, .c = 13.37 }, tryParse(S, "42, 13.37"));

    const Nested = struct { foo: i32, bar: struct { baz: f32 }, qux: [2]struct { quux: u32 } };
    try t.expectEqual(
        Nested{ .foo = 42, .bar = .{ .baz = 13.37 }, .qux = .{ .{ .quux = 84 }, .{ .quux = 21 } } },
        tryParse(Nested, "42 13.37 84 21"),
    );
    try t.expectError(error.MissingToken, tryParse(Nested, "42 13.37 84"));
    try t.expectError(error.ExtraToken, tryParse(Nested, "42 13.37 84 21 42"));

    try t.expectEqualStrings("foo", tryParse([]const u8, "foo") catch unreachable);

    try t.expectEqualSlices(u32, &.{ 42, 1337, 84 }, tryParse([]u32, "42 1337 84") catch unreachable);

    const NestedSlice = struct { foo: []const u8, slice: []u32, bar: []const u8 };
    const nested_result = tryParse(NestedSlice, "foo 42 1337 84 bar") catch unreachable;
    try t.expectEqualStrings("foo", nested_result.foo);
    try t.expectEqualSlices(u32, &.{ 42, 1337, 84 }, nested_result.slice);
    try t.expectEqualStrings("bar", nested_result.bar);

    try t.expectEqual(@as(?i32, 42), tryParse(?i32, "42"));
    try t.expectEqual(@as(?i32, null), tryParse(?i32, "foo"));
}

test "parse with opts" {
    const t = std.testing;

    const S = struct { foo: i32, bar: f32 };

    // defaults
    try t.expectEqual(S{ .foo = 42, .bar = 13.37 }, tryParseOpt(S, "42 13.37", .{}));
    try t.expectEqual(S{ .foo = 42, .bar = 13.37 }, tryParseOpt(S, "42,13.37", .{}));

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseOpt(S, "42BC13.37", .{ .separator = .{ .any = "ABC" } }),
    );

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseOpt(S, "42 | 13.37", .{ .separator = .{ .sequence = " | " } }),
    );

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseOpt(S, "42&13.37", .{ .separator = .{ .scalar = '&' } }),
    );
}

pub const Measure = struct {
    timer: std.time.Timer,
    snapshots: std.BoundedArray(Snap, 4),

    const empty = Measure{ .timer = undefined, .snapshots = undefined };
    const do_measure = @import("opts").bench;

    const Snap = struct {
        label: []const u8,
        usage: std.posix.rusage,
        heap: usize,
        wall: u64,

        fn take(label: []const u8, timer: *std.time.Timer) Snap {
            return .{
                .label = label,
                .usage = std.posix.getrusage(std.posix.rusage.SELF),
                .heap = gpa_impl.queryCapacity(),
                .wall = timer.read(),
            };
        }

        fn diff(lhs: Snap, rhs: Snap, label: ?[]const u8) Usage {
            const user_time = utime: {
                var after: u64 = @intCast(rhs.usage.utime.tv_sec);
                after *|= std.time.us_per_s;
                after +|= @intCast(rhs.usage.utime.tv_usec);

                var before: u64 = @intCast(lhs.usage.utime.tv_sec);
                before *|= std.time.us_per_s;
                before +|= @intCast(lhs.usage.utime.tv_usec);

                break :utime (after -| before) *| std.time.ns_per_us;
            };

            const system_time = stime: {
                var after: u64 = @intCast(rhs.usage.stime.tv_sec);
                after *|= std.time.us_per_s;
                after +|= @intCast(rhs.usage.stime.tv_usec);

                var before: u64 = @intCast(lhs.usage.stime.tv_sec);
                before *|= std.time.us_per_s;
                before +|= @intCast(lhs.usage.stime.tv_usec);

                break :stime (after -| before) *| std.time.ns_per_us;
            };

            const rss =
                @as(u64, @intCast(rhs.usage.maxrss)) -|
                @as(u64, @intCast(lhs.usage.maxrss));

            const heap = rhs.heap -| lhs.heap;
            const wall_time = rhs.wall -| lhs.wall;

            return .{
                .label = label orelse rhs.label,
                .wall_time_ns = wall_time,
                .user_time_ns = user_time,
                .system_time_ns = system_time,
                .heap_bytes = heap,
                .rss_bytes = rss,
            };
        }
    };

    const Usage = struct {
        label: []const u8,
        wall_time_ns: u64,
        user_time_ns: u64,
        system_time_ns: u64,
        heap_bytes: u64,
        rss_bytes: u64,

        const empty = std.mem.zeroes(Usage);

        fn dump(self: *const Usage) void {
            if (comptime do_measure == false) return;

            std.debug.lockStdErr();
            defer std.debug.unlockStdErr();
            const out = std.io.getStdErr();
            if (out.isTty()) {
                out.writer().print("\n{}", .{self}) catch {};
            } else {
                std.json.stringify(self, .{ .whitespace = .indent_4 }, out.writer()) catch {};
                out.writeAll("\n") catch {};
            }
        }

        pub fn format(
            self: *const Usage,
            comptime _: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            try writer.print(
                \\Usage for {s}:
                \\     {s: >16} wall time
                \\     {s: >16} user time
                \\     {s: >16} system time
                \\     {s: >16.9} heap memory usage
                \\     {s: >16.9} resident memory usage
                \\
            , .{
                self.label,
                std.fmt.fmtDuration(self.wall_time_ns),
                std.fmt.fmtDuration(self.user_time_ns),
                std.fmt.fmtDuration(self.system_time_ns),
                std.fmt.fmtIntSizeBin(self.heap_bytes),
                std.fmt.fmtIntSizeBin(self.rss_bytes),
            });
        }
    };

    pub fn start() Measure {
        if (comptime do_measure == false) return empty;

        const timer = std.time.Timer.start() catch unreachable;
        var this = Measure{ .timer = timer, .snapshots = .{} };
        this.lap("start");
        return this;
    }

    pub fn lap(self: *Measure, label: []const u8) void {
        if (comptime do_measure == false) return;

        const snap = Snap.take(label, &self.timer);
        self.snapshots.append(snap) catch {};
    }

    pub fn dump(self: *Measure) void {
        if (comptime do_measure == false) return;

        const snaps = self.snapshots.constSlice();
        if (snaps.len < 2) return;

        var segments = mem.window(Snap, snaps, 2, 1);
        while (segments.next()) |segment| {
            segment[0].diff(segment[1], null).dump();
        }
        snaps[0].diff(snaps[snaps.len - 1], "everything").dump();
    }
};
