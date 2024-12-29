const std = @import("std");
const sdl = @import("sdl.zig");
const gl = @import("gl.zig");
const Shader = @import("shader.zig").Shader;

const vs =
    "#version 330 core\n" ++
    "layout (location = 0) in vec3 aPos;\n" ++
    "void main()\n" ++
    "{\n" ++
    "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n" ++
    "}";

const fs =
    "#version 330 core\n" ++
    "out vec4 FragColor;\n" ++
    "uniform vec4 ourColor;\n" ++
    "void main()\n" ++
    "{\n" ++
    "   FragColor = ourColor;\n" ++
    "}\n";

const vertices = [_]f32{
    0.5, 0.5, 0.0, // top right
    0.5, -0.5, 0.0, // bottom right
    -0.5, -0.5, 0.0, // bottom left
    -0.5, 0.5, 0.0, // top left
};
const indices = [_]u32{ // note that we start from 0!
    0, 1, 3, // first Triangle
    1, 2, 3, // second Triangle
};

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, sdl.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

fn isMouseInsideSquare(x: c_int, y: c_int, window_width: c_int, window_height: c_int) bool {
    _ = window_width;
    _ = window_height;
    return x > 150 and y > 150 and x < 450 and y < 450;
}

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0)
        sdlPanic();

    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("Opengl - zig", 0, 0, 600, 600, sdl.SDL_WINDOW_OPENGL);
    defer sdl.SDL_DestroyWindow(window);

    _ = sdl.SDL_GL_CreateContext(window);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 3);

    var shader = Shader{};
    shader.init(vs, fs);

    var VBO: c_uint = 0;
    var VAO: c_uint = 0;
    var EBO: c_uint = 0;

    gl.glGenVertexArrays(1, &VAO);
    gl.glGenBuffers(1, &VBO);
    gl.glGenBuffers(1, &EBO);

    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    gl.glBindVertexArray(VAO);

    // Use a pointer to the first element of the array
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, VBO);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices[0], gl.GL_STATIC_DRAW);

    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, EBO);
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices[0], gl.GL_STATIC_DRAW);

    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), null);
    gl.glEnableVertexAttribArray(0);

    // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0);

    gl.glBindVertexArray(0);

    var running: bool = true;
    var event: sdl.SDL_Event = undefined;

    while (running) {
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_QUIT) {
                running = false;
                break;
            }
        }

        var x: c_int = 0;
        var y: c_int = 0;
        const button: u32 = sdl.SDL_GetMouseState(&x, &y);

        std.debug.print("x = {}, y = {}\n", .{ x, y });

        var color: [4]f32 = if (isMouseInsideSquare(x, y, 600, 600) and button == 1) [_]f32{ 0.4, 0.5, 0.9, 1.0 } else [_]f32{ 0.6, 0.6, 0.6, 1.0 };

        gl.glClearColor(0.1, 0.1, 0.1, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        shader.shaderUse();
        const colorLocation = gl.glGetUniformLocation(shader.programID, "ourColor");

        gl.glUniform4fv(colorLocation, 1, @ptrCast(&color));

        gl.glBindVertexArray(VAO);
        gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, null);
        gl.glBindVertexArray(0); // no need to unbind it every time

        sdl.SDL_GL_SwapWindow(window);
    }
    std.debug.print("{s}\n", .{"Great job boy rs"});
}
