#!/usr/bin/env python3
"""Generate AirLink app icon images."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

def draw_icon(size):
    """Draw a modern AirLink app icon at the given size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient (deep blue to purple)
    for y in range(size):
        ratio = y / size
        r = int(20 + ratio * 40)
        g = int(30 + ratio * 10)
        b = int(120 + ratio * 80)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Round corners
    corner_radius = int(size * 0.22)
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=corner_radius, fill=255)
    img.putalpha(mask)
    
    cx, cy = size // 2, int(size * 0.52)
    
    # Draw signal waves (arcs)
    wave_colors = [
        (100, 200, 255, 200),  # light blue
        (130, 180, 255, 170),
        (160, 160, 255, 140),
        (190, 140, 255, 110),
    ]
    
    for i, color in enumerate(wave_colors):
        radius = int(size * (0.12 + i * 0.08))
        pen_width = max(int(size * 0.025), 2)
        bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
        draw.arc(bbox, start=210, end=330, fill=color, width=pen_width)
    
    # Center dot (antenna base)
    dot_r = int(size * 0.06)
    draw.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], 
                 fill=(255, 255, 255, 255))
    
    # Antenna line going down
    line_w = max(int(size * 0.02), 2)
    draw.line([(cx, cy + dot_r), (cx, cy + int(size * 0.18))], 
              fill=(255, 255, 255, 230), width=line_w)
    
    # Small base
    base_w = int(size * 0.08)
    base_y = cy + int(size * 0.18)
    draw.line([(cx - base_w, base_y), (cx + base_w, base_y)], 
              fill=(255, 255, 255, 200), width=line_w)
    
    # "AirLink" text at bottom
    font_size = int(size * 0.1)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFCompact.ttf", font_size)
    except (IOError, OSError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except (IOError, OSError):
            font = ImageFont.load_default()
    
    text = "AirLink"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_w = text_bbox[2] - text_bbox[0]
    text_x = (size - text_w) // 2
    text_y = int(size * 0.78)
    draw.text((text_x, text_y), text, fill=(255, 255, 255, 220), font=font)
    
    # Convert to RGB (iOS icons must not have alpha)
    background = Image.new('RGB', (size, size), (20, 30, 120))
    for y in range(size):
        ratio = y / size
        r = int(20 + ratio * 40)
        g = int(30 + ratio * 10)
        b = int(120 + ratio * 80)
        for x in range(size):
            background.putpixel((x, y), (r, g, b))
    
    # Composite
    background.paste(img, (0, 0), img)
    
    return background


def main():
    icon_dir = os.path.join(os.path.dirname(__file__), 
                            "AirLink", "Assets.xcassets", "AppIcon.appiconset")
    
    # Required sizes for iOS
    sizes = {
        "icon_20x2": 40,
        "icon_20x3": 60,
        "icon_29x2": 58,
        "icon_29x3": 87,
        "icon_40x2": 80,
        "icon_40x3": 120,
        "icon_60x2": 120,
        "icon_60x3": 180,
        "icon_76x1": 76,
        "icon_76x2": 152,
        "icon_83x2": 167,
        "icon_1024": 1024,
    }
    
    for name, px in sizes.items():
        icon = draw_icon(px)
        filepath = os.path.join(icon_dir, f"{name}.png")
        icon.save(filepath, "PNG")
        print(f"Generated {name}.png ({px}x{px})")
    
    # Write Contents.json
    import json
    contents = {
        "images": [
            {"filename": "icon_20x2.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
            {"filename": "icon_20x3.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
            {"filename": "icon_29x2.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
            {"filename": "icon_29x3.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
            {"filename": "icon_40x2.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
            {"filename": "icon_40x3.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
            {"filename": "icon_60x2.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
            {"filename": "icon_60x3.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
            {"filename": "icon_76x1.png", "idiom": "ipad", "scale": "1x", "size": "76x76"},
            {"filename": "icon_76x2.png", "idiom": "ipad", "scale": "2x", "size": "76x76"},
            {"filename": "icon_83x2.png", "idiom": "ipad", "scale": "2x", "size": "83.5x83.5"},
            {"filename": "icon_1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"}
        ],
        "info": {"author": "xcode", "version": 1}
    }
    
    contents_path = os.path.join(icon_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print("Updated Contents.json")


if __name__ == "__main__":
    main()
