import os
import shutil

repo_root = r"d:\GitHub\contraRe"

# Folders to delete
folders_to_delete = [
    r"assets\vfx\explosions\alien",
    r"assets\vfx\explosions\cryo",
    r"assets\vfx\explosions\electric",
    r"assets\vfx\explosions\fiery",
    r"assets\vfx\explosions\magma",
    r"assets\vfx\explosions\mini_burst",
    r"assets\vfx\explosions\nuclear",
]

# Themed tres files to delete
files_to_delete = [
    r"resources\vfx\explosion_alien_bio.tres",
    r"resources\vfx\explosion_arcade_fiery.tres",
    r"resources\vfx\explosion_cryo_frost.tres",
    r"resources\vfx\explosion_electric_tesla.tres",
    r"resources\vfx\explosion_magma_volcanic.tres",
    r"resources\vfx\explosion_mini_impact.tres",
    r"resources\vfx\explosion_nuclear_mega.tres",
]

for folder in folders_to_delete:
    full_path = os.path.join(repo_root, folder)
    if os.path.exists(full_path):
        shutil.rmtree(full_path)
        print(f"Removed folder: {folder}")
    else:
        print(f"Folder not found: {folder}")

# If explosions folder is empty, remove it too
explosions_root = os.path.join(repo_root, r"assets\vfx\explosions")
if os.path.exists(explosions_root) and not os.listdir(explosions_root):
    os.rmdir(explosions_root)
    print("Removed empty folder: assets\\vfx\\explosions")

for file_rel in files_to_delete:
    full_path = os.path.join(repo_root, file_rel)
    if os.path.exists(full_path):
        os.remove(full_path)
        print(f"Removed file: {file_rel}")
    else:
        print(f"File not found: {file_rel}")

print("Cleanup complete!")
