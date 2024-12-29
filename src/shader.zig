const std = @import("std");
const gl = @import("gl.zig");

pub const Shader = struct {
    const Self = @This();

    programID: u32 = 0,

    pub fn init(self: *Self, vs: []const u8, fs: []const u8) void {
        const vsID = self.createVertexShader(vs);
        defer gl.glDeleteShader(vsID);

        const fsID = self.createFragmentShader(fs);
        defer gl.glDeleteShader(fsID);

        self.programID = self.createProgramShader(vsID, fsID);
    }

    pub fn shaderUse(self: *Self) void {
        gl.glUseProgram(self.programID);
    }

    fn createVertexShader(_: *Self, vs: []const u8) u32 {
        const vsPtr: [*c]const [*c]const u8 = &[_][*c]const u8{vs.ptr};
        const vertexShader: u32 = gl.glCreateShader(gl.GL_VERTEX_SHADER);
        gl.glShaderSource(vertexShader, 1, vsPtr, null);
        gl.glCompileShader(vertexShader);
        return vertexShader;
    }

    fn createFragmentShader(_: *Self, fs: []const u8) u32 {
        const fsPtr: [*c]const [*c]const u8 = &[_][*c]const u8{fs.ptr};
        const fragmentShader: u32 = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
        gl.glShaderSource(fragmentShader, 1, fsPtr, null);
        gl.glCompileShader(fragmentShader);
        return fragmentShader;
    }

    fn createProgramShader(_: *Shader, vertexShader: u32, fragmentShader: u32) u32 {
        const shaderProgram = gl.glCreateProgram();
        gl.glAttachShader(shaderProgram, vertexShader);
        gl.glAttachShader(shaderProgram, fragmentShader);
        gl.glLinkProgram(shaderProgram);
        return shaderProgram;
    }
};
