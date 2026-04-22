from PIL import Image
import os

IMG_DIR = os.path.join(os.path.dirname(__file__), "img")

def optimize_image(path):
    original_size = os.path.getsize(path)
    img = Image.open(path)
    fmt = img.format
    mode = img.mode

    if path.lower().endswith(".png"):
        # Convert RGBA PNGs to optimized PNG with palette reduction only if no transparency
        if mode == "RGBA":
            # Keep RGBA but compress with PIL optimize
            img.save(path, "PNG", optimize=True, compress_level=9)
        else:
            img = img.convert("RGB")
            img.save(path, "PNG", optimize=True, compress_level=9)
    elif path.lower().endswith((".jpg", ".jpeg")):
        if mode == "RGBA":
            img = img.convert("RGB")
        img.save(path, "JPEG", quality=82, optimize=True, progressive=True)

    new_size = os.path.getsize(path)
    saved = original_size - new_size
    pct = (saved / original_size) * 100 if original_size > 0 else 0
    print(f"  {os.path.basename(path):30s}  {original_size//1024:>6} KB  ->  {new_size//1024:>6} KB  (-{pct:.1f}%)")

print("Optimizando imágenes para web...\n")
total_before = 0
total_after = 0

for fname in sorted(os.listdir(IMG_DIR)):
    fpath = os.path.join(IMG_DIR, fname)
    if fname.lower().endswith((".png", ".jpg", ".jpeg")):
        before = os.path.getsize(fpath)
        optimize_image(fpath)
        after = os.path.getsize(fpath)
        total_before += before
        total_after += after

print(f"\nTotal antes: {total_before//1024} KB  |  Total después: {total_after//1024} KB  |  Ahorro: {(total_before-total_after)//1024} KB ({(total_before-total_after)/total_before*100:.1f}%)")
