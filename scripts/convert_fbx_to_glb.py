"""
Blender Python Script: Batch convert FBX modular body parts to GLB.
Run via: blender --background --python convert_fbx_to_glb.py

Converts all FBX files from Quaternius "Separate Skeletal Meshes and Animations"
folders into individual GLB files in assets/models/modular_parts/{men,women}/
"""

import bpy
import os
import sys

# ── Configuration ──
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SOURCES = {
    "men": os.path.join(
        PROJECT_ROOT,
        "assets",
        "Ultimate Modular Men- Feb 2022",
        "Separate Skeletal Meshes and Animations",
    ),
    "women": os.path.join(
        PROJECT_ROOT,
        "assets",
        "Ultimate Modular Women - April 2022",
        "Separate Skeletal Meshes and Animations",
    ),
}

OUTPUT_BASE = os.path.join(PROJECT_ROOT, "assets", "models", "modular_parts")


def clear_scene():
    """Remove all objects from the scene."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Also clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)
    for block in bpy.data.textures:
        if block.users == 0:
            bpy.data.textures.remove(block)
    for block in bpy.data.armatures:
        if block.users == 0:
            bpy.data.armatures.remove(block)
    for block in bpy.data.actions:
        if block.users == 0:
            bpy.data.actions.remove(block)


def convert_fbx_to_glb(fbx_path, glb_path):
    """Import a single FBX file and export it as GLB."""
    clear_scene()

    # Import FBX
    bpy.ops.import_scene.fbx(filepath=fbx_path)

    # Select all imported objects
    bpy.ops.object.select_all(action="SELECT")

    # Export as GLB (binary glTF)
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=True,
    )

    print(f"  ✓ {os.path.basename(fbx_path)} → {os.path.basename(glb_path)}")


def process_all():
    """Walk all source directories and convert each FBX to GLB."""
    total = 0
    skipped_dirs = {"Horse", "Weapons"}  # Non-body-part directories

    for gender, source_dir in SOURCES.items():
        if not os.path.isdir(source_dir):
            print(f"⚠ Source directory not found: {source_dir}")
            continue

        output_dir = os.path.join(OUTPUT_BASE, gender)
        os.makedirs(output_dir, exist_ok=True)

        print(f"\n{'='*60}")
        print(f"Processing {gender.upper()} characters from:")
        print(f"  {source_dir}")
        print(f"Output to: {output_dir}")
        print(f"{'='*60}")

        for item in sorted(os.listdir(source_dir)):
            item_path = os.path.join(source_dir, item)

            # Skip non-directories and special items
            if not os.path.isdir(item_path):
                # Handle standalone FBX files like Animations.fbx (skip)
                continue

            if item in skipped_dirs:
                print(f"\n  ⏭ Skipping non-body folder: {item}")
                continue

            char_name = item.lower()
            print(f"\n  📁 Character: {item}")

            for fbx_file in sorted(os.listdir(item_path)):
                if not fbx_file.lower().endswith(".fbx"):
                    continue

                fbx_path = os.path.join(item_path, fbx_file)
                # Generate clean output name: e.g. adventurer_head.glb
                part_name = os.path.splitext(fbx_file)[0].lower()
                glb_filename = f"{part_name}.glb"
                glb_path = os.path.join(output_dir, glb_filename)

                try:
                    convert_fbx_to_glb(fbx_path, glb_path)
                    total += 1
                except Exception as e:
                    print(f"  ✗ FAILED: {fbx_file} → {e}")

    print(f"\n{'='*60}")
    print(f"✅ Conversion complete! {total} GLB files created.")
    print(f"Output directory: {OUTPUT_BASE}")
    print(f"{'='*60}")


if __name__ == "__main__":
    process_all()
