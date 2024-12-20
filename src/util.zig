pub const std = @import("std");
pub const Alloc = std.mem.Allocator;
pub const List = std.ArrayList;
pub const MultiList = std.MultiArrayList;
pub const Map = std.AutoHashMap;
pub const StrMap = std.StringHashMap;
pub const BitSet = std.DynamicBitSet;
pub const Str = []const u8;

pub const ascii = std.ascii;
pub const math = std.math;
pub const mem = std.mem;
pub const meta = std.meta;
pub const rand = std.rand;
pub const sortm = std.sort;

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

pub const maxInt = std.math.maxInt;
pub const minInt = std.math.minInt;

pub const ws = std.ascii.whitespace;

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

pub fn sum(comptime T: type, nums: anytype) T {
    var res: T = 0;
    for (nums) |num| res += num;
    return res;
}

pub fn prod(comptime T: type, nums: anytype) T {
    var res: T = 1;
    for (nums) |num| res *= num;
    return res;
}

pub fn eql(lhs: Str, rhs: Str) bool {
    return mem.eql(u8, lhs, rhs);
}

pub fn equals(lhs: anytype, rhs: @TypeOf(lhs)) bool {
    return std.meta.eql(lhs, rhs);
}

pub fn strip(str: Str) Str {
    return trim(u8, str, &ws);
}

pub fn stripPrefix(needle: Str, haystack: Str) ?Str {
    if (!mem.startsWith(u8, haystack, needle)) return null;
    return haystack[needle.len..];
}

pub fn splitAtNext(needle: Str, haystack: Str) ?struct { Str, Str } {
    const pos = mem.indexOf(u8, haystack, needle) orelse return null;
    return .{ haystack[0..pos], haystack[pos + needle.len ..] };
}

pub fn skipToNext(needle: Str, haystack: Str) ?Str {
    _, const suffix = splitAtNext(needle, haystack) orelse return null;
    return suffix;
}

pub fn splitFirst(comptime T: type, slice: []const T) struct { T, []const T } {
    assert(slice.len > 0);
    return .{ slice[0], slice[1..] };
}

pub fn trySplitFirst(comptime T: type, slice: []const T) ?struct { T, []const T } {
    if (slice.len == 0) return null;
    return splitFirst(T, slice);
}

pub fn splitLast(comptime T: type, slice: []const T) struct { []const T, T } {
    assert(slice.len > 0);
    return .{ slice[0 .. slice.len - 1], slice[slice.len - 1] };
}

pub fn trySplitLast(comptime T: type, slice: []const T) ?struct { []const T, T } {
    if (slice.len == 0) return null;
    return splitLast(T, slice);
}

pub fn splitAt(comptime T: type, slice: []const T, index: usize) struct { []const T, []const T } {
    assert(slice.len >= index);
    return .{ slice[0..index], slice[index..] };
}

pub fn trySplitAt(comptime T: type, slice: []const T, index: usize) ?struct { []const T, []const T } {
    if (slice.len < index) return null;
    return splitAt(T, slice, index);
}

pub fn splitFirstMut(comptime T: type, slice: []T) struct { T, []T } {
    assert(slice.len > 0);
    return .{ slice[0], slice[1..] };
}

pub fn trySplitFirstMut(comptime T: type, slice: []T) ?struct { T, []T } {
    if (slice.len == 0) return null;
    return splitFirst(T, slice);
}

pub fn splitLastMut(comptime T: type, slice: []T) struct { []T, T } {
    assert(slice.len > 0);
    return .{ slice[0 .. slice.len - 1], slice[slice.len - 1] };
}

pub fn trySplitLastMut(comptime T: type, slice: []T) ?struct { []T, T } {
    if (slice.len == 0) return null;
    return splitLast(T, slice);
}

pub fn splitAtMut(comptime T: type, slice: []T, index: usize) struct { []T, []T } {
    assert(slice.len >= index);
    return .{ slice[0..index], slice[index..] };
}

pub fn trySplitAtMut(comptime T: type, slice: []T, index: usize) ?struct { []T, []T } {
    if (slice.len < index) return null;
    return splitAt(T, slice, index);
}

pub fn offsetFrom(base: Str, str: Str) usize {
    return @intFromPtr(str.ptr) - @intFromPtr(base.ptr);
}

pub fn advanceTo(tokens: anytype, str: Str) void {
    tokens.index = offsetFrom(tokens.buffer, str);
}

pub fn advanceWith(tokens: anytype, op: anytype, needle: Str) @typeInfo(@TypeOf(op)).Fn.return_type.? {
    const res = op(needle, tokens.rest()) orelse return null;
    switch (@TypeOf(res)) {
        Str => advanceTo(tokens, res),
        else => advanceTo(tokens, res[1]),
    }
    return res;
}

pub const Needle = union(enum) {
    sequence: []const u8,
    any: []const u8,
    scalar: u8,
    none: []const u8,
};

pub fn findCharsComptime(str: Str, comptime needle: Needle) FindCharsComptime(needle) {
    return FindCharsComptime(needle){ .str = str, .pos = 0 };
}

pub fn FindCharsComptime(comptime needle: Needle) type {
    return struct {
        str: Str,
        pos: usize,

        pub fn next(self: *@This()) ?usize {
            const pos = switch (needle) {
                .scalar => |n| mem.indexOfScalarPos(u8, self.str, self.pos, n),
                .sequence => |n| mem.indexOfPos(u8, self.str, self.pos, n),
                .any => |n| mem.indexOfAnyPos(u8, self.str, self.pos, n),
                .none => |n| mem.indexOfNonePos(u8, self.str, self.pos, n),
            } orelse return null;
            self.pos = pos + 1;
            return pos;
        }
    };
}

pub fn findChars(str: Str, needle: Needle) FindChars {
    return .{ .str = str, .needle = needle, .pos = 0 };
}

pub const FindChars = struct {
    str: Str,
    needle: Needle,
    pos: usize,

    pub fn next(self: *FindChars) ?usize {
        const pos = switch (self.needle) {
            .scalar => |n| mem.indexOfScalarPos(u8, self.str, self.pos, n),
            .sequence => |n| mem.indexOfPos(u8, self.str, self.pos, n),
            .any => |n| mem.indexOfAnyPos(u8, self.str, self.pos, n),
            .none => |n| mem.indexOfNonePos(u8, self.str, self.pos, n),
        } orelse return null;
        self.pos = pos + 1;
        return pos;
    }
};

pub const Axis = enum { x, y };
pub const Dir = enum(i2) {
    forward = 1,
    backward = -1,

    pub fn reverse(self: Dir) Dir {
        return switch (self) {
            .forward => .backward,
            .backward => .forward,
        };
    }

    pub fn reverse2d(self: Dir2d) Dir2d {
        return .{ self[0], self[1].backward() };
    }
};

pub const Dir2d = struct { Axis, Dir };
pub const Kind = enum { straight, diagonal };

pub const LineConfig = struct {
    kind: Kind,
    axis: Axis,
    dir: Dir,
};

pub const LineOpts = struct {
    kind: ?Kind = null,
    axis: ?Axis = null,
    dir: ?Dir = null,

    fn combinations(comptime self: LineOpts) comptime_int {
        return (if (self.kind == null) meta.fields(Kind).len else 1) *
            (if (self.axis == null) meta.fields(Axis).len else 1) *
            (if (self.dir == null) meta.fields(Dir).len else 1);
    }
};

pub const StrGrid = Grid(u8, false);

pub fn Grid(comptime T: type, comptime mutable: bool) type {
    return struct {
        const Slice = if (mutable) []T else []const T;

        input: Slice,
        row_len: isize,

        const Self = @This();

        pub fn fromInput(input: Slice, comptime sentinel: T) Self {
            const row_len = (indexOf(T, input, sentinel) orelse unreachable) + 1;
            return .{ .input = input, .row_len = @intCast(row_len) };
        }

        fn getFrom(self: *const Self, pos: usize, cfg: LineConfig) ?usize {
            return self.get(pos, cfg.kind, cfg.axis, cfg.dir);
        }

        fn get2d(self: *const Self, pos: usize, kind: Kind, dir: Dir2d) ?usize {
            return self.get(pos, kind, dir[0], dir[1]);
        }

        fn get(self: *const Self, pos: usize, kind: Kind, axis: Axis, dir: Dir) ?usize {
            var l = self.line(pos, kind, axis, dir);
            _ = l.next() orelse return null;
            return l.pos;
        }

        pub fn neighbors(
            self: *const Self,
            start: usize,
            comptime filter: LineOpts,
        ) std.BoundedArray(usize, filter.combinations()) {
            const kinds = comptime if (filter.kind) |k| &.{k} else meta.tags(Kind);
            const axis = comptime if (filter.axis) |a| &.{a} else meta.tags(Axis);
            const dir = comptime if (filter.dir) |d| &.{d} else meta.tags(Dir);
            var buf = std.BoundedArray(usize, filter.combinations()){};
            inline for (kinds) |k| inline for (axis) |a| inline for (dir) |d| {
                if (self.get(start, k, a, d)) |p| buf.appendAssumeCapacity(p);
            };
            return buf;
        }

        pub fn lineFrom(self: *const Self, start: usize, cfg: LineConfig) Line {
            return self.line(start, cfg.kind, cfg.axis, cfg.dir);
        }

        pub fn line2d(self: *const Self, start: usize, kind: Kind, dir2d: Dir2d) Line {
            return self.line(start, kind, dir2d[0], dir2d[1]);
        }

        pub fn line(self: *const Self, start: usize, kind: Kind, axis: Axis, dir: Dir) Line {
            const d = @intFromEnum(dir);
            const stride = switch (kind) {
                .straight => switch (axis) {
                    .x => d,
                    .y => d * self.row_len,
                },
                .diagonal => switch (axis) {
                    .x => d * (self.row_len + 1),
                    .y => -d * (self.row_len - 1),
                },
            };
            return .{
                .grid = self,
                .pos = start,
                .stride = stride,
                .config = .{ .kind = kind, .axis = axis, .dir = dir },
            };
        }

        pub fn lines(
            self: *const Self,
            start: usize,
            comptime filter: LineOpts,
        ) [filter.combinations()]Line {
            const kinds = comptime if (filter.kind) |k| &.{k} else meta.tags(Kind);
            const axis = comptime if (filter.axis) |a| &.{a} else meta.tags(Axis);
            const dir = comptime if (filter.dir) |d| &.{d} else meta.tags(Dir);
            var buf: [filter.combinations()]Line = undefined;
            var idx: usize = 0;
            inline for (kinds) |k| inline for (axis) |a| inline for (dir) |d| {
                buf[idx] = self.line(start, k, a, d);
                idx += 1;
            };
            return buf;
        }

        pub const Line = struct {
            grid: *const Self,
            pos: usize,
            stride: isize,
            config: LineConfig,

            pub fn next(self: *Line) ?T {
                const ipos = @as(isize, @intCast(self.pos)) + self.stride;

                // top boundary
                const new_pos = math.cast(usize, ipos) orelse return null;

                // bottom boundary
                if (new_pos >= self.grid.input.len) return null;

                // left/right boundary
                const row_len = @as(usize, @intCast(self.grid.row_len));
                if (new_pos % (row_len) == row_len - 1) return null;

                self.pos = new_pos;
                return self.grid.input[new_pos];
            }

            pub fn match(self: *Line, target: []const T) bool {
                var idx: usize = 0;
                while (self.next()) |c| : (idx += 1) {
                    if (c != target[idx]) break;
                    if (idx == target.len - 1) return true;
                }
                return false;
            }
        };

        pub fn spots(self: *const Self, a: usize, b: usize) Spots {
            const ib = @as(isize, @intCast(b));
            const stride = ib - @as(isize, @intCast(a));

            const row_len = @as(usize, @intCast(self.row_len));

            const a_x = a / row_len;
            const b_x = b / row_len;

            const dx: usize = @intCast(absDiff(a_x, b_x));

            return .{ .grid = self, .pos = b, .stride = stride, .dx = dx };
        }

        pub const Spots = struct {
            grid: *const Self,
            pos: usize,
            stride: isize,
            dx: usize,

            pub fn next(self: *Spots) ?T {
                const ipos = @as(isize, @intCast(self.pos)) + self.stride;

                // top boundary
                const new_pos = math.cast(usize, ipos) orelse return null;

                // bottom boundary
                if (new_pos >= self.grid.input.len) return null;

                // spots in directly in the left/right boundary
                const row_len = @as(usize, @intCast(self.grid.row_len));
                if (new_pos % (row_len) == row_len - 1) return null;

                // left/right boundary
                const x_a = self.pos / row_len;
                const x_b = new_pos / row_len;
                if (absDiff(x_a, x_b) != self.dx) return null;

                self.pos = new_pos;
                return self.grid.input[new_pos];
            }
        };
    };
}

pub fn linesOf(comptime T: type, str: Str) ParseError![]T {
    return linesOfSep(T, str, Separator.default);
}

pub fn linesOfSep(comptime T: type, str: Str, comptime sep: Separator) ParseError![]T {
    var items = List(T).init(gpa);

    var ls = lines(str);
    while (ls.next()) |line| {
        const item = try tryParseSep(T, line, sep);
        items.append(item) catch @panic("oom");
    }

    return items.items;
}

pub fn chunksOf(comptime T: type, str: Str) ParseError![][]T {
    return chunksOfSep(T, str, Separator.default);
}

pub fn chunksOfSep(comptime T: type, str: Str, comptime sep: Separator) ParseError![][]T {
    var items = List([]T).init(gpa);

    var cs = chunks(str);
    while (cs.next()) |chunk| {
        var inner = List(T).init(gpa);

        var ls = lines(chunk);
        while (ls.next()) |line| {
            const item = try tryParseSep(T, line, sep);
            inner.append(item) catch @panic("oom");
        }

        items.append(inner.items) catch @panic("oom");
    }

    return items.items;
}

pub fn columnsOf(comptime T: type, str: Str) ParseError!ColumnsOf(T) {
    return columnsOfSep(T, str, Separator.default);
}

pub fn columnsOfSep(comptime T: type, str: Str, comptime sep: Separator) ParseError!ColumnsOf(T) {
    var mla = MultiList(T){};

    var ls = lines(str);
    while (ls.next()) |line| {
        const item = try tryParseSep(T, line, sep);
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

pub fn lines(str: Str) mem.TokenIterator(u8, .scalar) {
    return tokenizeSca(u8, str, '\n');
}

pub fn chunks(str: Str) mem.TokenIterator(u8, .sequence) {
    return tokenizeSeq(u8, str, "\n\n");
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

pub const Separator = union(mem.DelimiterType) {
    sequence: []const u8,
    any: []const u8,
    scalar: u8,

    const default: Separator = .{ .any = ", " };

    pub fn tokenize(
        comptime self: Separator,
        comptime T: type,
        str: Str,
    ) mem.TokenIterator(T, self) {
        switch (self) {
            .sequence => |seq| return mem.tokenizeSequence(T, str, seq),
            .any => |any| return mem.tokenizeAny(T, str, any),
            .scalar => |scalar| return mem.tokenizeScalar(T, str, scalar),
        }
    }
};

pub const ParseError = error{
    Bool,
    Int,
    Float,
    Enum,
    Union,
    MissingToken,
    ExtraToken,
    NoMoreItems,
    Custom,
};

pub fn parse(comptime T: type, str: Str) T {
    return parseSep(T, str, Separator.default);
}

pub fn parseSep(comptime T: type, str: Str, comptime sep: Separator) T {
    return tryParseSep(T, str, sep) catch @panic("parse for expected type " ++ @typeName(T));
}

pub fn tryParse(comptime T: type, str: Str) ParseError!T {
    return tryParseSep(T, str, Separator.default);
}

pub fn tryParseSep(comptime T: type, str: Str, comptime sep: Separator) ParseError!T {
    var tokens = sep.tokenize(u8, str);
    const res = try parseTokens(T, &tokens);
    if (tokens.next() != null) {
        if (@typeInfo(T) == .Optional and tokens.next() == null) {
            return res;
        }
        return error.ExtraToken;
    }
    return res;
}

pub fn parseTokens(comptime T: type, tokens: anytype) ParseError!T {
    return switch (@typeInfo(T)) {
        .Void => {},
        .Null => null,
        .Optional => |o| {
            const before = tokens.index;
            return parseTokens(o.child, tokens) catch {
                tokens.index = before;
                return null;
            };
        },
        .Bool => parseBool(tokens.next() orelse return error.MissingToken),
        .Int => parseInt(T, tokens.next() orelse return error.MissingToken),
        .Float => parseFloat(T, tokens.next() orelse return error.MissingToken),
        .Enum => parseEnum(T, tokens.next() orelse return error.MissingToken),
        .Union => |u| {
            if (@hasDecl(T, "parse")) {
                return try T.parse(tokens);
            }

            const start = tokens.index;
            inline for (u.fields) |f| {
                if (parseTokens(f.type, tokens)) |val| {
                    return @unionInit(T, f.name, val);
                } else |_| tokens.index = start;
            }
            return error.Union;
        },
        .Struct => |s| {
            if (@hasDecl(T, "parse")) {
                return try T.parse(tokens);
            }

            var result: T = undefined;

            inline for (s.fields) |f| {
                const field_value = try parseTokens(f.type, tokens);
                @field(result, f.name) = field_value;
            }

            return result;
        },
        .Array => |a| {
            var items: [a.len]a.child = undefined;

            inline for (0..a.len) |i| {
                const item = try parseTokens(a.child, tokens);
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
                while (parseTokens(p.child, tokens)) |token| {
                    valid_index = tokens.index;
                    items.append(token) catch @panic("oom");
                } else |e| switch (e) {
                    error.NoMoreItems => {},
                    else => tokens.index = valid_index,
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

    const Nested = struct { foo: i32, bar: union(enum) { baz: f32 }, qux: [2]struct { quux: u32 } };
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

test "parse with custom parse" {
    const S = struct {
        l: u32,
        r: u32,

        pub fn parse(tokens: anytype) !@This() {
            _ = advanceWith(tokens, stripPrefix, "foo(") orelse return error.MissingToken;
            const l, const r = try parseTokens([2]u32, tokens);
            return .{ .l = l, .r = r };
        }
    };

    const s_result = try tryParseSep(S, "foo(42, 1337)", .{ .any = ", )" });
    try std.testing.expectEqual(S{ .l = 42, .r = 1337 }, s_result);

    const E = union(enum) {
        l: u32,
        r: u32,

        pub fn parse(tokens: anytype) !@This() {
            const tag_str = tokens.next() orelse return error.MissingToken;
            inline for (meta.fields(@This())) |f| if (eql(tag_str, f.name)) {
                const value = try parseTokens(f.type, tokens);
                return @unionInit(@This(), f.name, value);
            };
            return error.Custom;
        }
    };

    const e_result = try tryParseSep([2]E, "l=42, r=1337", .{ .any = "=, " });
    try std.testing.expectEqual([_]E{ .{ .l = 42 }, .{ .r = 1337 } }, e_result);
}

test "parse with opts" {
    const t = std.testing;

    const S = struct { foo: i32, bar: f32 };

    // defaults
    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseSep(S, "42 13.37", Separator.default),
    );
    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseSep(S, "42,13.37", Separator.default),
    );

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseSep(S, "42BC13.37", .{ .any = "ABC" }),
    );

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseSep(S, "42 | 13.37", .{ .sequence = " | " }),
    );

    try t.expectEqual(
        S{ .foo = 42, .bar = 13.37 },
        tryParseSep(S, "42&13.37", .{ .scalar = '&' }),
    );
}

// parse + part1 + part2
pub const Measure = BoundedMeasure(3);

pub fn BoundedMeasure(max_snapshots: comptime_int) type {
    return struct {
        active: bool,
        timer: std.time.Timer,
        snapshots: std.BoundedArray(Snap, max_snapshots + 1),

        const empty = Self{ .timer = undefined, .snapshots = undefined, .active = false };
        const do_measure = @import("opts").bench;
        const should_measure = if (@hasDecl(@import("root"), "disable_sub_measure")) false else do_measure;

        const Self = @This();

        const Snap = struct {
            label: []const u8,
            heap: usize,
            rss: u64,
            wall: u64,
            size: ?u64,

            fn take(label: []const u8, timer: *std.time.Timer) Snap {
                return .{
                    .label = label,
                    .heap = gpa_impl.queryCapacity(),
                    .rss = @intCast(std.posix.getrusage(std.posix.rusage.SELF).maxrss),
                    .wall = timer.read(),
                    .size = null,
                };
            }

            fn diff(lhs: Snap, rhs: Snap, label: ?[]const u8) Usage {
                const rss = rhs.rss -| lhs.rss;
                const heap = rhs.heap -| lhs.heap;
                const wall_time = rhs.wall -| lhs.wall;

                const thrpt = if (rhs.size) |size| thrpt: {
                    const secs =
                        @as(f64, @floatFromInt(wall_time)) /
                        @as(f64, @floatFromInt(std.time.ns_per_s));
                    const tp = @as(f64, @floatFromInt(size)) / secs;
                    break :thrpt @as(u64, @intFromFloat(@round(tp)));
                } else null;

                return .{
                    .label = label orelse rhs.label,
                    .wall_time_ns = wall_time,
                    .heap_bytes = heap,
                    .rss_bytes = rss,
                    .throughput = thrpt,
                };
            }
        };

        const Usage = struct {
            label: []const u8,
            wall_time_ns: u64,
            heap_bytes: u64,
            rss_bytes: u64,
            throughput: ?u64,

            const empty = mem.zeroes(Usage);

            fn dump(self: *const Usage) void {
                if (comptime do_measure == false) return;

                std.debug.lockStdErr();
                defer std.debug.unlockStdErr();
                const out = std.io.getStdErr();
                if (out.isTty()) {
                    out.writer().print("\n{}", .{self}) catch {};
                } else {
                    std.json.stringify(self, .{
                        .whitespace = .indent_4,
                        .emit_null_optional_fields = false,
                    }, out.writer()) catch {};
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
                    \\     {s: >12} wall time
                    \\     {s: >12.3} heap memory usage
                    \\     {s: >12.3} resident memory usage
                    \\
                , .{
                    self.label,
                    std.fmt.fmtDuration(self.wall_time_ns),
                    std.fmt.fmtIntSizeBin(self.heap_bytes),
                    std.fmt.fmtIntSizeBin(self.rss_bytes),
                });

                if (self.throughput) |t| {
                    try writer.print(
                        \\     {s: >12.3} throughput (per second)
                        \\
                    , .{
                        std.fmt.fmtIntSizeBin(t),
                    });
                }
            }
        };

        pub inline fn forceStart() Self {
            return startInternal(true);
        }

        pub inline fn start() Self {
            return startInternal(should_measure);
        }

        fn startInternal(comptime enable_measure: bool) Self {
            if (comptime do_measure == false) return empty;
            if (comptime enable_measure == false) return empty;

            const timer = std.time.Timer.start() catch unreachable;
            var this = Self{ .timer = timer, .snapshots = .{}, .active = true };
            this.lap("start");
            return this;
        }

        pub fn lap(self: *Self, label: []const u8) void {
            if (self.active == false) return;

            const snap = Snap.take(label, &self.timer);
            self.snapshots.append(snap) catch {};
        }

        pub fn lapWithSize(self: *Self, label: []const u8, size: u64) void {
            if (self.active == false) return;

            var snap = Snap.take(label, &self.timer);
            snap.size = size;
            self.snapshots.append(snap) catch {};
        }

        pub fn dump(self: *Self) void {
            if (self.active == false) return;

            const snaps = self.snapshots.constSlice();
            if (snaps.len < 2) return;

            var segments = mem.window(Snap, snaps, 2, 1);
            while (segments.next()) |segment| {
                segment[0].diff(segment[1], null).dump();
            }
            snaps[0].diff(snaps[snaps.len - 1], "everything").dump();
        }
    };
}
