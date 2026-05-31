"""Crop NPC sprite sheet to proper 8-frame format for Godot (hframes auto-detection).

Godot npc_node.gd uses: _hframes = max(1, tw / th)
So each frame must be square (w == h) for correct detection.
Output: 8 square frames side by side → total width = 8 * frame_size.
"""
from PIL import Image
import numpy as np
import sys

FRAME_SIZE = 192  # Each frame is 192x192; total sheet = 1536x192, ratio = 8

def crop_sheet(input_path, output_path, num_frames=8, frame_size=FRAME_SIZE):
    img = Image.open(input_path).convert('RGBA')
    w, h = img.size
    print(f'Original: {w}x{h}')

    arr = np.array(img)
    alpha = arr[:, :, 3]

    # Find vertical content bounds
    row_has_content = np.any(alpha > 10, axis=1)
    top = int(np.argmax(row_has_content))
    bottom = int(h - np.argmax(row_has_content[::-1]))
    content_h = bottom - top
    print(f'Content rows: {top} to {bottom}, height={content_h}')

    src_frame_w = w // num_frames

    # Create output with square frames
    output = Image.new('RGBA', (frame_size * num_frames, frame_size), (0, 0, 0, 0))

    for i in range(num_frames):
        # Extract frame from source
        frame = img.crop((i * src_frame_w, top, (i + 1) * src_frame_w, bottom))
        # Find horizontal content bounds for this frame
        frame_arr = np.array(frame)
        frame_alpha = frame_arr[:, :, 3]
        col_has = np.any(frame_alpha > 10, axis=0)
        if not np.any(col_has):
            continue
        left = int(np.argmax(col_has))
        right = int(frame.size[0] - np.argmax(col_has[::-1]))
        frame = frame.crop((left, 0, right, content_h))

        # Fit into square frame_size x frame_size (maintain aspect ratio, center)
        fw, fh = frame.size
        scale = min(frame_size / fw, frame_size / fh) * 0.9  # 90% fill
        new_w = int(fw * scale)
        new_h = int(fh * scale)
        frame_resized = frame.resize((new_w, new_h), Image.LANCZOS)

        # Center in square
        x_off = (frame_size - new_w) // 2
        y_off = (frame_size - new_h) // 2
        output.paste(frame_resized, (i * frame_size + x_off, y_off), frame_resized)

    final_w, final_h = output.size
    print(f'Output: {final_w}x{final_h}, ratio={final_w / final_h:.1f} (expect {num_frames})')
    output.save(output_path)
    print(f'Saved: {output_path}')

if __name__ == '__main__':
    input_path = sys.argv[1] if len(sys.argv) > 1 else r'F:\Code\RPG_GAME\game\art\characters\npc_shenbanzhan_idle.png'
    output_path = sys.argv[2] if len(sys.argv) > 2 else r'F:\Code\RPG_GAME\game\art\characters\npc_shenbanzhan_idle_8f.png'
    num_frames = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    crop_sheet(input_path, output_path, num_frames)
