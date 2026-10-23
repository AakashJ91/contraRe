from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
from scipy.ndimage import label, find_objects, distance_transform_edt
import zipfile, json
root=Path.cwd()
work=root/'scratch/player_replacement'
work.mkdir(exist_ok=True)
(work/'.gdignore').write_text('')
src=Image.open(root/'scratch/player_sheet.png').convert('RGBA')
a=np.array(src)
labs,n=label(a[:,:,3]>80)
objects=find_objects(labs)
ids=[i+1 for i,s in enumerate(objects) if s is not None and int((labs[s]==i+1).sum())>1700]
assert len(ids)==38, len(ids)
# Read artwork in visual pose order; the second row contains ten sprites.
order=[2,3,4,5,1,8,6,7,12,11,9,10,13,18,14,15,16,17,25,19,20,21,22,26,23,24,30,31,32,34,35,33,29,28,36,37,38,39]
names=['player_idle','player_aim','player_aim_diag_down','player_aim_diag_up','player_aim_up','player_fire','player_fire_1','player_fire_diag_down','player_fire_diag_up','player_fire_diag_up_1','player_fire_up','player_fire_up_1','player_jump','player_prone']
for group in ['player_run','player_run_down','player_run_fire','player_run_fire_down','player_run_fire_up','player_run_up']:
    names.extend(f'{group}_{i}' for i in range(4))
assert len(names)==38 and set(order)==set(ids)
heads=[105,283,485,685,882,1075,1270,1475,95,285,492,679,861,1025,1204,1325,1423,1532,100,303,500,688,884,1080,1280,1480,100,302,490,700,880,1075,1275,1480,105,300,495,680]
body=np.isin(labs,ids)
_,nearest=distance_transform_edt(~body,return_indices=True)
owner=labs[tuple(nearest)]
backup=work/'original_player_assets.zip'
assert not backup.exists(), 'Backup already exists; inspect before rerun'
with zipfile.ZipFile(backup,'w',zipfile.ZIP_DEFLATED) as z:
    for p in (root/'assets/player').iterdir():
        if p.is_file(): z.write(p,p.name)
out=work/'prepared'
out.mkdir(exist_ok=True)
manifest=[]
for idx,(cid,name,head) in enumerate(zip(order,names,heads)):
    rgba=a.copy()
    rgba[owner!=cid]=0
    rgba[rgba[:,:,3]<8]=0
    frame=Image.fromarray(rgba)
    bbox=frame.getbbox()
    crop=frame.crop(bbox)
    old=Image.open(root/'assets/player'/f'{name}.png')
    canvas=Image.new('RGBA',old.size)
    if name in ['player_jump','player_prone']:
        pad=4 if name=='player_prone' else 50
        factor=min((old.width-2*pad)/crop.width,(old.height-2*pad)/crop.height)
        resized=crop.resize((round(crop.width*factor),round(crop.height*factor)),Image.Resampling.NEAREST)
        xy=((old.width-resized.width)//2,(old.height-resized.height)//2)
    else:
        factor=1.1 if idx<12 else 1.2
        # Keep the entire isolated sprite within the existing canvas.
        factor=min(factor,210/crop.height,230/crop.width)
        resized=crop.resize((round(crop.width*factor),round(crop.height*factor)),Image.Resampling.NEAREST)
        x=round(100-(head-bbox[0])*factor)
        x=max(2,min(x,238-resized.width))
        xy=(x,220-resized.height)
    canvas.alpha_composite(resized,xy)
    canvas.save(out/f'{name}.png')
    manifest.append({'name':name+'.png','source_component':cid,'source_bounds':bbox,'size':old.size,'position':xy})
(work/'manifest.json').write_text(json.dumps(manifest,indent=2))
preview=Image.new('RGB',(8*240,5*260),(38,44,52))
d=ImageDraw.Draw(preview)
for i,m in enumerate(manifest):
    im=Image.open(out/m['name'])
    im.thumbnail((230,230),Image.Resampling.NEAREST)
    x=(i%8)*240; y=(i//8)*260
    preview.paste(im,(x+(240-im.width)//2,y),im)
    d.text((x+3,y+235),m['name'].replace('player_',''),fill='white')
preview.save(work/'preview.png')
print('Prepared',len(manifest),'sprites; original backup:',backup)
