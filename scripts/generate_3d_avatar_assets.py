#!/usr/bin/env python3
"""
3D Fluttermoji Asset Generator Script.
Processes 3D geometry layers, specular light maps, and generates modular 3D avatar assets.
"""

import os
import json
import math

def generate_3d_avatar_metadata():
    categories = {
        "hair_styles": [
            {"id": 0, "name": "Bald", "mesh": "hair_bald"},
            {"id": 1, "name": "Short Cut", "mesh": "hair_short"},
            {"id": 2, "name": "Curly Top", "mesh": "hair_curly"},
            {"id": 3, "name": "Long Locks", "mesh": "hair_long"},
            {"id": 4, "name": "Afro", "mesh": "hair_afro"},
            {"id": 5, "name": "Mohawk", "mesh": "hair_mohawk"},
        ],
        "beard_styles": [
            {"id": 0, "name": "Clean Shaved", "mesh": "beard_none"},
            {"id": 1, "name": "Full Beard", "mesh": "beard_full"},
            {"id": 2, "name": "Stubble", "mesh": "beard_stubble"},
            {"id": 3, "name": "Mustache", "mesh": "beard_mustache"},
        ],
        "outfits": [
            {"id": 0, "name": "Casual Tee", "mesh": "outfit_tee"},
            {"id": 1, "name": "Suit", "mesh": "outfit_suit"},
            {"id": 2, "name": "Hoodie", "mesh": "outfit_hoodie"},
            {"id": 3, "name": "Jacket", "mesh": "outfit_jacket"},
        ],
        "eye_styles": [
            {"id": 0, "name": "Natural Eyes", "mesh": "eyes_natural"},
            {"id": 1, "name": "Sunglasses", "mesh": "eyes_sunglasses"},
        ],
        "mouth_styles": [
            {"id": 0, "name": "Smile", "mesh": "mouth_smile"},
            {"id": 1, "name": "Neutral", "mesh": "mouth_neutral"},
            {"id": 2, "name": "Laughing", "mesh": "mouth_laughing"},
            {"id": 3, "name": "Smirk", "mesh": "mouth_smirk"},
        ],
    }

    output_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "models")
    os.makedirs(output_dir, exist_ok=True)
    metadata_path = os.path.join(output_dir, "3d_avatar_config.json")

    with open(metadata_path, "w") as f:
        json.dump(categories, f, indent=2)

    print(f"[SUCCESS] 3D Fluttermoji Asset Metadata generated successfully at: {metadata_path}")

if __name__ == "__main__":
    generate_3d_avatar_metadata()
