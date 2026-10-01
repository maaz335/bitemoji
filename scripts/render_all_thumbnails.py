import bpy
import glob
import os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(PROJECT_ROOT, "assets", "thumbnails")
os.makedirs(OUT_DIR, exist_ok=True)

CHARACTERS = {
    # Men
    "men_adventurer": "assets/models/characters/men/Adventurer.gltf",
    "men_beach": "assets/models/characters/men/Beach.gltf",
    "men_casual": "assets/models/characters/men/Casual_2.gltf",
    "men_hoodie": "assets/models/characters/men/Casual_Hoodie.gltf",
    "men_farmer": "assets/models/characters/men/Farmer.gltf",
    "men_king": "assets/models/characters/men/King.gltf",
    "men_punk": "assets/models/characters/men/Punk.gltf",
    "men_spacesuit": "assets/models/characters/men/Spacesuit.gltf",
    "men_suit": "assets/models/characters/men/Suit.gltf",
    "men_swat": "assets/models/characters/men/Swat.gltf",
    "men_worker": "assets/models/characters/men/Worker.gltf",
    # Women
    "women_adventurer": "assets/models/characters/women/Adventurer.gltf",
    "women_casual": "assets/models/characters/women/Casual.gltf",
    "women_formal": "assets/models/characters/women/Formal.gltf",
    "women_medieval": "assets/models/characters/women/Medieval.gltf",
    "women_punk": "assets/models/characters/women/Punk.gltf",
    "women_scifi": "assets/models/characters/women/SciFi.gltf",
    "women_soldier": "assets/models/characters/women/Soldier.gltf",
    "women_suit": "assets/models/characters/women/Suit.gltf",
    "women_witch": "assets/models/characters/women/Witch.gltf",
    "women_worker": "assets/models/characters/women/Worker.gltf",
}

# Also map head parts to these character thumbnails
HEAD_MAPPINGS = {
    "adventurer_head": "men_adventurer",
    "beach_head": "men_beach",
    "casual2_head": "men_casual",
    "casual_head": "men_hoodie",
    "farmer_head": "men_farmer",
    "king_head": "men_king",
    "punk_head": "men_punk",
    "spacesuit_head": "men_spacesuit",
    "suit_head": "men_suit",
    "swat_head": "men_swat",
    "worker_head": "men_worker",
    "formal_head": "women_formal",
    "medieval_head": "women_medieval",
    "scifi_head": "women_scifi",
    "soldier_head": "women_soldier",
    "witch_head": "women_witch",
}

def render_character(char_id, rel_path):
    out_file = os.path.join(OUT_DIR, f"{char_id}.png")
    if os.path.exists(out_file) and os.path.getsize(out_file) > 1000:
        print(f"Skipping already rendered: {char_id}")
        return

    full_path = os.path.join(PROJECT_ROOT, rel_path.replace("/", os.sep))
    if not os.path.exists(full_path):
        print(f"File not found: {full_path}")
        return

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # Import gltf
    bpy.ops.import_scene.gltf(filepath=full_path)

    # Setup camera focused on upper body / bust for clean avatar card look
    cam_data = bpy.data.cameras.new('ThumbCam')
    cam_obj = bpy.data.objects.new('ThumbCam', cam_data)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (0, -2.2, 1.35)
    cam_obj.rotation_euler = (1.5708, 0, 0)

    # Setup lighting (Front + Rim)
    light_data = bpy.data.lights.new('KeyLight', type='SUN')
    light_data.energy = 3.5
    light_obj = bpy.data.objects.new('KeyLight', light_data)
    bpy.context.scene.collection.objects.link(light_obj)
    light_obj.rotation_euler = (0.7, 0.5, 0)

    rim_data = bpy.data.lights.new('RimLight', type='SUN')
    rim_data.energy = 2.0
    rim_obj = bpy.data.objects.new('RimLight', rim_data)
    bpy.context.scene.collection.objects.link(rim_obj)
    rim_obj.rotation_euler = (-0.7, -0.5, 3.14)

    # Render settings
    bpy.context.scene.render.resolution_x = 256
    bpy.context.scene.render.resolution_y = 256
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.filepath = out_file
    bpy.ops.render.render(write_still=True)
    print(f"✓ Rendered: {char_id}.png")

def main():
    print("Rendering 3D avatar thumbnails with Blender...")
    for char_id, path in CHARACTERS.items():
        render_character(char_id, path)

    # Create symlinks or copies for head part IDs so both character ID and head ID resolve
    import shutil
    for head_id, char_id in HEAD_MAPPINGS.items():
        src_thumb = os.path.join(OUT_DIR, f"{char_id}.png")
        dst_thumb = os.path.join(OUT_DIR, f"{head_id}.png")
        if os.path.exists(src_thumb) and not os.path.exists(dst_thumb):
            shutil.copyfile(src_thumb, dst_thumb)
            print(f"✓ Linked head thumbnail: {head_id}.png -> {char_id}.png")

    # Also default 3D thumbnail
    def_thumb = os.path.join(OUT_DIR, "default_3d.png")
    adventurer_thumb = os.path.join(OUT_DIR, "men_adventurer.png")
    if os.path.exists(adventurer_thumb) and not os.path.exists(def_thumb):
        shutil.copyfile(adventurer_thumb, def_thumb)

    print("Thumbnails rendering completed!")

if __name__ == "__main__":
    main()
