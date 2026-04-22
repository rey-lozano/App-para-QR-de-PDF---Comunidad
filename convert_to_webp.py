from PIL import Image
import os

IMG_DIR = os.path.join(os.path.dirname(__file__), "img")

print("Convirtiendo imagenes a WebP...\n")
total_before = 0
total_after = 0

for fname in sorted(os.listdir(IMG_DIR)):
    if not fname.lower().endswith((".png", ".jpg", ".jpeg")):
        continue
    
    src = os.path.join(IMG_DIR, fname)
    name_no_ext = os.path.splitext(fname)[0]
    dst = os.path.join(IMG_DIR, name_no_ext + ".webp")
    
    original_size = os.path.getsize(src)
    img = Image.open(src)
    
    # Preserve transparency for PNG with alpha
    if img.mode == "RGBA":
        img.save(dst, "WEBP", quality=85, method=6, lossless=False)
    else:
        img = img.convert("RGB")
        img.save(dst, "WEBP", quality=85, method=6)
    
    new_size = os.path.getsize(dst)
    saved = original_size - new_size
    pct = (saved / original_size) * 100 if original_size > 0 else 0
    print(f"  {fname:30s}  {original_size//1024:>6} KB  ->  {new_size//1024:>6} KB  (-{pct:.1f}%)")
    total_before += original_size
    total_after += new_size

print(f"\nTotal PNG/JPG: {total_before//1024} KB  |  Total WebP: {total_after//1024} KB  |  Ahorro: {(total_before-total_after)//1024} KB ({(total_before-total_after)/total_before*100:.1f}%)")
