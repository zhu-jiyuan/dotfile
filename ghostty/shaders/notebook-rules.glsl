// Ruled notebook paper: a faint line along the foot of every text row, drawn only where the
// paper shows, so text and colored cells stay on top. The row height and phase come from the
// cursor, which is one cell tall, so the lines follow any font size and display scale.

// Ghostty hands colors over in sRGB, while the pipeline works in linear light.
vec3 toLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

const vec3 PAPER = vec3(244.0, 242.0, 236.0) / 255.0; // #f4f2ec, the Notebook Paper background
const vec3 RULE = vec3(201.0, 214.0, 232.0) / 255.0;  // #c9d6e8

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 screen = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = screen;

    // A hidden or blinking cursor can report no size; the previous one still knows the cell.
    vec4 cursor = iCurrentCursor.w >= 4.0 ? iCurrentCursor : iPreviousCursor;
    float cell = cursor.w;
    if (cell < 4.0) return;

    // Rows run from the cursor's top edge in steps of one cell; the rule takes each row's foot.
    float thickness = max(1.0, floor(cell / 25.0 + 0.5));
    if (mod(cursor.y - fragCoord.y, cell) < cell - thickness) return;
    // The screen texture may arrive linear or sRGB, so plain paper is either value.
    bool linearPaper = distance(screen.rgb, toLinear(PAPER)) < 0.03;
    bool srgbPaper = distance(screen.rgb, PAPER) < 0.03;
    if (!linearPaper && !srgbPaper) return;

    fragColor = vec4(linearPaper ? toLinear(RULE) : RULE, screen.a);
}
