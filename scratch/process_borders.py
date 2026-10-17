import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def add_arcade_borders_and_padding(im, pad=20, outline_color=(15, 18, 25, 255), taper_ends=False, cap_bottom=None, cap_top=None):
    """
    Pads image with transparent margin, optionally tapers sheared left/right ends,
    caps sheared top/bottom, and applies a clean 2px retro pixel-art contour outline.
    """
    w, h = im.size
    orig = im.copy()
    
    # If taper_ends is True (for platforms), round/taper the cut left and right ends
    if taper_ends:
        # Create an end-cap mask that softly rounds the extreme 16-24 pixels on left and right
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        cap_w = 24
        for x in range(cap_w):
            factor = x / float(cap_w)
            # Taper top and bottom corners at the ends
            cut_h = int((1.0 - factor) * (h * 0.35))
            if cut_h > 0:
                draw.line([(x, 0), (x, cut_h)], fill=0)
                draw.line([(x, h - cut_h), (x, h - 1)], fill=0)
                
            rx = w - 1 - x
            if cut_h > 0:
                draw.line([(rx, 0), (rx, cut_h)], fill=0)
                draw.line([(rx, h - cut_h), (rx, h - 1)], fill=0)
        
        orig_alpha = orig.split()[3]
        orig_alpha = ImageChops.multiply(orig_alpha, mask)
        orig.putalpha(orig_alpha)

    # If cap_bottom is specified (for bosses cut flat at bottom), round/taper the bottom edge
    if cap_bottom:
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        bot_h = cap_bottom
        for y in range(bot_h):
            # bottom-most y is (h - 1 - y)
            py = h - 1 - y
            factor = y / float(bot_h)
            # fade/sculpt extreme left and right corners of the bottom cut
            corner_cut = int((1.0 - factor) * 40)
            if corner_cut > 0:
                draw.line([(0, py), (corner_cut, py)], fill=0)
                draw.line([(w - 1 - corner_cut, py), (w - 1, py)], fill=0)
        orig_alpha = orig.split()[3]
        orig_alpha = ImageChops.multiply(orig_alpha, mask)
        orig.putalpha(orig_alpha)

    # If cap_top is specified (for bosses cut flat at top), round/taper the top edge
    if cap_top:
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        top_h = cap_top
        for y in range(top_h):
            factor = y / float(top_h)
            corner_cut = int((1.0 - factor) * 35)
            if corner_cut > 0:
                draw.line([(0, y), (corner_cut, y)], fill=0)
                draw.line([(w - 1 - corner_cut, y), (w - 1, y)], fill=0)
        orig_alpha = orig.split()[3]
        orig_alpha = ImageChops.multiply(orig_alpha, mask)
        orig.putalpha(orig_alpha)

    # 1. Place onto padded transparent canvas
    new_w = w + pad * 2
    new_h = h + pad * 2
    padded = Image.new('RGBA', (new_w, new_h), (0, 0, 0, 0))
    padded.paste(orig, (pad, pad))
    
    # 2. Extract alpha and create solid 2px outer outline contour
    alpha = padded.split()[3]
    # Filter with MaxFilter(5) produces ~2px radius dilation
    dilated = alpha.filter(ImageFilter.MaxFilter(5))
    
    # Create dark outline image
    outline_img = Image.new('RGBA', (new_w, new_h), outline_color)
    
    # Outline mask: pixels where dilated is high and original alpha is lower
    outline_mask = Image.new('L', (new_w, new_h), 0)
    for y in range(new_h):
        for x in range(new_w):
            d = dilated.getpixel((x, y))
            a = alpha.getpixel((x, y))
            if d > 20 and a < 220:
                # Solid dark outline contour
                border_strength = min(255, int((d - a) * 2.2))
                outline_mask.putpixel((x, y), border_strength)
                
    # Place outline behind padded sprite
    combined = Image.composite(padded, outline_img, alpha)
    # The final alpha is max of alpha and outline
    final_alpha = ImageChops.lighter(alpha, outline_mask)
    combined.putalpha(final_alpha)
    return combined

print('Helper loaded')
