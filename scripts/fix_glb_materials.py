import glob
import json
import os
import struct

def fix_glb(filepath):
    with open(filepath, "rb") as f:
        data = f.read()

    magic, version, total_length = struct.unpack("<4sII", data[:12])
    if magic != b"glTF":
        print(f"Skipping {filepath}: not a glTF binary")
        return

    # Chunk 0
    chunk0_len, chunk0_type = struct.unpack("<II", data[12:20])
    if chunk0_type != 0x4E4F534A:  # "JSON"
        print(f"Skipping {filepath}: first chunk is not JSON")
        return

    json_bytes = data[20:20 + chunk0_len]
    gltf = json.loads(json_bytes.decode("utf-8"))

    # Fix materials
    modified = False
    for mat in gltf.get("materials", []):
        # Remove or reset alphaMode if it was MASK / BLEND with 0 alpha
        if "alphaMode" in mat:
            del mat["alphaMode"]
            modified = True

        pbr = mat.get("pbrMetallicRoughness", {})
        if "baseColorFactor" in pbr:
            color = pbr["baseColorFactor"]
            if len(color) == 4 and color[3] < 0.5:
                color[3] = 1.0
                modified = True

    if not modified:
        return

    # Re-serialize JSON
    new_json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    # Pad with spaces (0x20) to 4-byte boundary
    pad_len = (4 - (len(new_json_bytes) % 4)) % 4
    new_json_bytes += b" " * pad_len
    new_chunk0_len = len(new_json_bytes)

    # Chunk 1 (BIN)
    bin_chunk_start = 20 + chunk0_len
    bin_chunk_data = data[bin_chunk_start:]

    new_total_length = 12 + 8 + new_chunk0_len + len(bin_chunk_data)

    new_header = struct.pack("<4sII", magic, version, new_total_length)
    new_chunk0_hdr = struct.pack("<II", new_chunk0_len, chunk0_type)

    with open(filepath, "wb") as f:
        f.write(new_header)
        f.write(new_chunk0_hdr)
        f.write(new_json_bytes)
        f.write(bin_chunk_data)

    print(f"Fixed: {filepath}")

def main():
    base_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "modular_parts")
    glb_files = glob.glob(os.path.join(base_dir, "**", "*.glb"), recursive=True)
    print(f"Found {len(glb_files)} GLB files to inspect and fix...")
    count = 0
    for path in glb_files:
        fix_glb(path)
        count += 1
    print(f"Processed {count} files.")

if __name__ == "__main__":
    main()
