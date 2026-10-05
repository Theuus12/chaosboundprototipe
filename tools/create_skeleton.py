import os
exec(open(os.path.join(os.path.dirname(__file__),'create_goblin.py'),encoding='utf-8').read().split('for base in [skin')[0])
OUT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','assets','characters','skeleton'))
os.makedirs(OUT,exist_ok=True)
skin.diffuse_color=ivory.diffuse_color
next(n for n in skin.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs[0].default_value=skin.diffuse_color
remove=('Body','Patchwork shirt','Vest tatters','Large angular head','Broad muzzle','Pointed ear','Ear inner','Eye','Angry brow','Ivory fang','Mouth','Red neck scarf','Pointed scarf','Belt pouch','Pouch flap')
for ob in list(bpy.context.scene.objects):
    if ob.name.startswith(remove): bpy.data.objects.remove(ob,do_unlink=True)
for ob in list(bpy.context.scene.objects):
    if ob.name.startswith('Ragged skirt'):
        ob.data.materials.clear(); ob.data.materials.append(red)
rod('Spine',(0,.045,.79),(0,.045,1.19),.045,ivory)
rod('Sternum',(0,-.15,.87),(0,-.15,1.15),.033,ivory)
for z in [.86,.94,1.02,1.10]:
    for s in [-1,1]:
        points=[(0,.05,z+.04),(s*.15,.07,z+.035),(s*.23,-.025,z),(s*.16,-.14,z-.025),(0,-.16,z-.02)]
        for a,b in zip(points,points[1:]): rod('Open rib',a,b,.025,ivory)
for s in [-1,1]:
    rod('Collar bone',(0,-.07,1.17),(s*.22,0,1.14),.033,ivory)
    ball('Pelvic bone',(s*.12,0,.73),(.10,.065,.055),ivory,1)
head=cloth_volume('Angular skull',[(1.29,0,-.015,.16,.15),(1.35,0,0,.23,.21),(1.48,0,.015,.28,.23),(1.68,0,.025,.26,.21),(1.78,0,.025,.18,.15),(1.83,0,.025,.075,.065)],ivory,12)
for v in head.data.vertices:
    if v.co.y<-.12:v.co.y=-.235
for s in [-1,1]:
    box('Dark eye socket',(s*.105,-.246,1.48),(.075,.018,.125),black,.009)
    brow=box('Bone brow',(s*.105,-.25,1.56),(.12,.045,.045),ivory,.012); brow.rotation_euler.y=-s*.22
    ball('Cheek bone',(s*.17,-.20,1.36),(.08,.045,.06),ivory,1)
    rod('Skull fang',(s*.115,-.247,1.30),(s*.115,-.25,1.365),.02,ivory,0)
box('Open jaw',(0,-.17,1.28),(.28,.10,.055),ivory,.018)
box('Mouth gap',(0,-.234,1.322),(.17,.014,.027),black)
mesh('Nose cavity',[(-.018,-.25,1.40),(.018,-.25,1.40),(0,-.25,1.43)],[(0,1,2)],black)
for x in [-.04,0,.04]:box('Small tooth',(x,-.233,1.31),(.023,.019,.025),ivory,.003)
for s in [-1,1]:
    parent=bpy.data.objects['Elbow_'+('L' if s<0 else 'R')]
    band=rod('Iron wrist band',(s*.62,0,1.13),(s*.65,0,1.13),.089,metal)
    bpy.context.view_layer.update(); transform=band.matrix_world.copy(); band.parent=parent; band.matrix_world=transform
for x,y,z in [(.26,-.015,1.23),(.30,.04,1.24),(.25,-.09,1.23)]:rod('Shoulder spikes',(x,y,z),(x+.025,y,z+.11),.035,metal,0)
for base in [skin,red,cloth,leather,ivory,metal]:
    palette=[mat(base.name+' skeleton facet '+str(i),tuple(min(1,c*f) for c in base.diffuse_color[:3])) for i,f in enumerate([.8,.92,1.10,1.18])]
    for ob in list(bpy.context.scene.objects):
        if ob.type=='MESH' and ob.data.materials[0]==base:
            for m in palette:ob.data.materials.append(m)
            for face in ob.data.polygons:face.material_index=random.choices(range(5),weights=[55,8,12,18,7])[0]
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'skeleton.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'skeleton.glb'),export_format='GLB')
for s,side in [(-1,'L'),(1,'R')]:bpy.data.objects['Arm_'+side].rotation_euler.y=s*1.1
bpy.ops.object.camera_add(location=(2.8,-5,2.6)); cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,.95))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=2.35; bpy.context.scene.camera=cam
for loc,power in [((2,-4,5),450),((-3,-2,3),250)]:
    bpy.ops.object.light_add(type='AREA',location=loc); light=bpy.context.object; light.data.energy=power; light.data.size=4
    light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24; scene.world.color=(.4,.4,.4)
scene.render.resolution_x=700; scene.render.resolution_y=800; scene.render.resolution_percentage=100; scene.render.film_transparent=True
scene.render.filepath=os.path.join(OUT,'preview.png'); bpy.ops.render.render(write_still=True)
