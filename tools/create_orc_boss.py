import os
# Build the same articulated low-poly foundation as the goblin.
exec(open(os.path.join(os.path.dirname(__file__),'create_goblin.py'),encoding='utf-8').read().split('for base in [skin')[0])
OUT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','assets','characters','orc_boss'))
os.makedirs(OUT,exist_ok=True)
skin.diffuse_color=(.65,.10,.025,1)
next(n for n in skin.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs[0].default_value=skin.diffuse_color
red.diffuse_color=(.22,.018,.025,1)
next(n for n in red.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs[0].default_value=red.diffuse_color
for ob in list(bpy.context.scene.objects):
    if ob.name.startswith(('Vest tatters','Patchwork shirt','Pointed scarf','Red neck scarf','Iron shoulder plate','Shoulder spike','Shoulder rivet')):
        bpy.data.objects.remove(ob,do_unlink=True)
ball('Muscular chest',(0,-.005,1.06),(.35,.21,.26),skin,2)
for s in [-1,1]:
    ball('Pectoral',(s*.15,-.18,1.10),(.17,.08,.145),skin,1)
    for z in [.91,.99]: ball('Abdominal muscle',(s*.072,-.17,z),(.078,.052,.055),skin,1)
    muscle=ball('Biceps',(s*.34,0,1.13),(.17,.125,.135),skin,2)
    bpy.context.view_layer.update(); parent=bpy.data.objects['Arm_'+('L' if s<0 else 'R')]; transform=muscle.matrix_world.copy(); muscle.parent=parent; muscle.matrix_world=transform
    ball('Broad shoulder armor',(s*.28,0,1.23),(.20,.21,.12),leather,1)
    for x,y,h in [(s*.24,-.09,.19),(s*.37,.02,.20),(s*.20,.09,.12)]: rod('Armor ivory spike',(x,y,1.28),(x+s*.025,y,1.28+h),.048,ivory,0)
    strap('Crossed harness',(s*.27,-.215,1.23),(-s*.10,-.215,.79),.066,leather)
    for z in [1.08,1.17]: ball('Harness rivet',(s*(.27-(1.23-z)*.84),-.254,z),(.015,.012,.015),metal)

def skull(name,center,size):
    x,y,z=center
    ball(name,(x,y,z),(size*.75,size*.28,size),ivory,1)
    for s in [-1,1]:
        ball(name+' eye socket',(x+s*size*.29,y-size*.26,z+size*.14),(size*.20,size*.085,size*.22),black,1)
        rod(name+' horn',(x+s*size*.5,y,z+size*.65),(x+s*size*.65,y,z+size*1.65),size*.17,ivory,0)
    mesh(name+' nose',[(x,y-size*.31,z),(x-size*.10,y-size*.31,z-size*.22),(x+size*.10,y-size*.31,z-size*.22)],[(0,1,2)],black)
    for dx in [-.30,0,.30]: box(name+' tooth',(x+dx*size,y-size*.12,z-size*.83),(size*.17,size*.22,size*.40),ivory,.006)
skull('Shoulder beast skull',(.29,-.17,1.28),.17)
skull('Belt skull',(0,-.225,.755),.074)
skull('Hanging skull',(.20,-.195,.58),.055)
for z in [1.68,1.75,1.80]: ball('Dark red mohawk',(0,.065,z),(.055,.16,.09),red,1)
for base in [skin,inner,red,cloth,leather,ivory,metal]:
    palette=[mat(base.name+' facet '+str(i),tuple(min(1,c*f) for c in base.diffuse_color[:3])) for i,f in enumerate([.8,.92,1.10,1.18])]
    for ob in list(bpy.context.scene.objects):
        if ob.type=='MESH' and ob.data.materials[0]==base:
            for m in palette: ob.data.materials.append(m)
            for face in ob.data.polygons: face.material_index=random.choices(range(5),weights=[55,8,12,18,7])[0]
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'orc_boss.glb'),export_format='GLB')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'orc_boss.blend'))
for s,side in [(-1,'L'),(1,'R')]: bpy.data.objects['Arm_'+side].rotation_euler.y=s*1.1
bpy.ops.object.camera_add(location=(2.6,-5,2.4)); cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,.95))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=2.35; bpy.context.scene.camera=cam
for loc,power in [((2,-4,5),450),((-3,-2,3),250)]:
    bpy.ops.object.light_add(type='AREA',location=loc); light=bpy.context.object; light.data.energy=power; light.data.size=4
    light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24; scene.world.color=(.4,.4,.4)
scene.render.resolution_x=700; scene.render.resolution_y=800; scene.render.resolution_percentage=100; scene.render.film_transparent=True
scene.render.filepath=os.path.join(OUT,'preview.png'); bpy.ops.render.render(write_still=True)

