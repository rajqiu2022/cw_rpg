import os
from PIL import Image

src_dir = r"F:\Code\RPG_GAME\images\hero_frames"
out_dir = r"F:\Code\RPG_GAME\game\art\characters"

idle_frame_indices = [0, 3, 7, 10]
directions = ["down", "left", "right", "up"]
# Swap left/right: source "left" files → game "right" texture, source "right" files → game "left" texture
src_to_game = {"down": "down", "left": "right", "right": "left", "up": "up"}

frame_w, frame_h = 86, 197
scale = 0.7
new_w, new_h = int(frame_w * scale), int(frame_h * scale)
walk_count = 15
idle_count = len(idle_frame_indices)

for src_dir_name in directions:
    game_dir_name = src_to_game[src_dir_name]

    # Walk sprite sheet (15 frames)
    walk_sheet = Image.new("RGBA", (new_w * walk_count, new_h))
    for i in range(walk_count):
        frame_path = os.path.join(src_dir, f"{src_dir_name}_{i:02d}.png")
        frame = Image.open(frame_path)
        frame = frame.resize((new_w, new_h), Image.LANCZOS)
        walk_sheet.paste(frame, (new_w * i, 0))
        frame.close()
    walk_path = os.path.join(out_dir, f"hero_walk_{game_dir_name}_{walk_count}f.png")
    walk_sheet.save(walk_path)
    print(f"Saved {walk_path} ({walk_sheet.size[0]}x{walk_sheet.size[1]})")

    # Idle sprite sheet (4 frames)
    idle_sheet = Image.new("RGBA", (new_w * idle_count, new_h))
    for j, idx in enumerate(idle_frame_indices):
        frame_path = os.path.join(src_dir, f"{src_dir_name}_{idx:02d}.png")
        frame = Image.open(frame_path)
        frame = frame.resize((new_w, new_h), Image.LANCZOS)
        idle_sheet.paste(frame, (new_w * j, 0))
        frame.close()
    idle_path = os.path.join(out_dir, f"hero_idle_{game_dir_name}_{idle_count}f.png")
    idle_sheet.save(idle_path)
    print(f"Saved {idle_path} ({idle_sheet.size[0]}x{idle_sheet.size[1]})")

print(f"Done! Frame size: {new_w}x{new_h}")