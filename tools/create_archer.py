import bpy, math, os, random
from mathutils import Vector

random.seed(12)
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'characters', 'archer'))
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def mat(name, color):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    shader=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'); shader.inputs[0].default_value=(*color,1); shader.inputs[2].default_value=.85
    return m
green=mat('Forest green',(.105,.245,.025)); trim=mat('Ivory',(.72,.64,.48))
dark=mat('Dark cloth',(.105,.073,.06)); leather=mat('Leather',(.28,.105,.035))
gold=mat('Brass',(.48,.27,.055)); skin=mat('Skin',(.72,.34,.16)); black=mat('Eyes',(.009,.007,.005))
hair=mat('Hair',(.075,.034,.015))
def mesh(name, verts, faces, material):
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces); me.update()
    ob=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(ob); ob.data.materials.append(material); return ob
def ball(name,loc,scale,material,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc)
    ob=bpy.context.object; ob.name=name; ob.scale=scale; ob.data.materials.append(material); return ob
def box(name,loc,scale,material,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); ob=bpy.context.object; ob.name=name; ob.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); ob.data.materials.append(material)
    if bevel:
        mod=ob.modifiers.new('Small chamfers','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.context.view_layer.objects.active=ob; bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob
def rod(name,a,b,r,material,r2=None):
    d=Vector(b)-Vector(a); bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(Vector(a)+Vector(b))/2)
    ob=bpy.context.object; ob.name=name; ob.rotation_euler=d.to_track_quat('Z','Y').to_euler(); ob.data.materials.append(material); return ob
def strap(name,a,b,width,material):
    d=Vector(b)-Vector(a); ob=box(name,(Vector(a)+Vector(b))/2,(width,.065,d.length),material,.012); ob.rotation_euler=d.to_track_quat('Z','Y').to_euler(); return ob
def cloth_volume(name, rings, material, sides=10):
    vertices=[]
    for z,x,y,rx,ry in rings:
        for i in range(sides):
            angle=2*math.pi*i/sides
            vertices.append((x+rx*math.cos(angle),y+ry*math.sin(angle),z))
    faces=[tuple(reversed(range(sides)))]
    for j in range(len(rings)-1):
        for i in range(sides):
            a=j*sides+i; b=j*sides+(i+1)%sides
            faces.extend([(a,b,b+sides),(a,b+sides,a+sides)])
    faces.append(tuple(range((len(rings)-1)*sides,len(rings)*sides)))
    return mesh(name,vertices,faces,material)
# Front faces toward negative Y, Z is up. Height approximately two metres.
ball('Torso',(0,0,1.22),(.29,.17,.38),dark,2)
cloth_volume('Tunic',[(.96,0,-.01,.21,.175),(1.10,0,-.015,.23,.18),(1.32,0,0,.24,.175),(1.45,0,0,.235,.16)],trim,12)
ball('Pelvis',(0,0,.88),(.24,.16,.19),dark,2)
for s,side in [(-1,'L'),(1,'R')]:
    x=s*.17
    cloth_volume('Thigh.'+side,[(.52,s*.20,0,.11,.11),(.58,s*.21,-.01,.14,.13),(.66,s*.22,-.015,.17,.155),(.77,s*.20,0,.155,.15),(.86,x,0,.14,.14),(.93,x,0,.13,.12)],dark)
    cloth_volume('Shin.'+side,[(.13,s*.20,0,.085,.09),(.23,s*.20,0,.095,.11),(.40,s*.20,0,.115,.115),(.53,s*.20,0,.10,.10)],leather)
    cloth_volume('Boot cuff.'+side,[(.40,s*.20,0,.13,.13),(.43,s*.20,0,.145,.145),(.54,s*.20,0,.15,.145),(.57,s*.20,0,.135,.13)],leather)
    for dx,dz in [(-.09,.0),(-.025,-.025),(.045,-.015),(.10,.005)]:
        mesh('Boot cuff flap.'+side,[(s*.20+dx-.038,-.139,.51),(s*.20+dx+.038,-.139,.51),(s*.20+dx+.042,-.16,.435+dz),(s*.20+dx,-.168,.408+dz),(s*.20+dx-.035,-.16,.435+dz)],[(0,1,2),(0,2,3),(0,3,4)],leather)
    rod('Shin ankle band.'+side,(s*.20,0,.13),(s*.20,0,.18),.103,leather)
    box('Boot.'+side,(s*.20,-.085,.085),(.25,.39,.17),leather,.055)
    box('Sole.'+side,(s*.20,-.09,.025),(.23,.37,.045),dark,.01)
    ball('Sleeve.'+side,(s*.34,0,1.42),(.155,.13,.145),dark,2)
    rod('Sleeve trim.'+side,(s*.40,0,1.42),(s*.46,0,1.42),.137,gold)
    rod('Sleeve trim leather.'+side,(s*.43,0,1.42),(s*.465,0,1.42),.144,leather)
    rod('Arm.'+side,(s*.45,0,1.42),(s*.59,0,1.42),.082,skin,.09)
    ball('Elbow.'+side,(s*.59,0,1.42),(.077,.077,.077),skin,2)
    rod('Forearm.'+side,(s*.59,0,1.42),(s*.70,0,1.42),.075,skin,.082)
    ball('Knee.'+side,(s*.20,0,.54),(.105,.105,.10),dark,2)
    rod('Bracer.'+side,(s*.65,0,1.42),(s*.80,0,1.42),.085,leather)
    box('Glove.'+side,(s*.86,-.008,1.42),(.16,.125,.07),dark,.018)
    box('Fingers.'+side,(s*.96,-.008,1.42),(.10,.115,.045),skin,.012)
    ball('Thumb.'+side,(s*.87,-.08,1.39),(.045,.05,.032),skin)
    box('Belt pouch.'+side,(s*.28,-.09,.91),(.15,.14,.26),leather,.025)
    box('Pouch flap.'+side,(s*.28,-.17,1.01),(.16,.035,.08),leather,.015)
    box('Pouch clasp.'+side,(s*.28,-.183,.985),(.023,.012,.045),gold)
    mesh('Tunic tail.'+side,[(s*.035,-.19,.96),(s*.23,-.14,.96),(s*.29,-.16,.77),(s*.26,-.17,.75),(s*.25,-.18,.71),(s*.22,-.18,.73),(s*.16,-.21,.65),(s*.11,-.21,.68)],[(0,1,2),(0,2,3),(0,3,4),(0,4,5),(0,5,6),(0,6,7)],trim)
rod('Neck',(0,0,1.48),(0,0,1.64),.075,skin)
head=cloth_volume('Head',[(1.59,0,-.025,.075,.105),(1.62,0,-.025,.155,.155),(1.70,0,-.02,.218,.185),(1.79,0,-.015,.228,.185),(1.88,0,0,.213,.17),(1.95,0,.015,.16,.125)],skin,16)
# Flatten the facial plane; cheeks and chin retain a rounded silhouette.
for vertex in head.data.vertices:
    if vertex.co.y < -.125:
        vertex.co.y=-.215 if vertex.co.z>=1.70 else -.19
for poly in head.data.polygons: poly.use_smooth=True
ball('Hair',(0,.015,1.85),(.233,.18,.19),hair,2)
for x,z in [(-.15,1.89),(-.08,1.92),(0,1.94),(.09,1.91),(.17,1.87)]:
    mesh('Hair fringe',[(x-.04,-.18,z+.025),(x+.045,-.18,z+.025),(x+.012,-.205,z-.065)],[(0,1,2)],hair)
for s in [-1,1]:
    box('Eye',(s*.079,-.23,1.775),(.039,.014,.087),black,.003)
    ob=box('Eyebrow',(s*.079,-.23,1.84),(.074,.016,.020),hair); ob.rotation_euler.y=s*-.12
    ball('Ear',(s*.217,0,1.76),(.034,.035,.055),skin)
box('Mouth',(0,-.199,1.64),(.035,.005,.003),leather)
# Open hood: successive arches run around the face, leaving its front exposed.
verts=[]
profile=[(.64,0),(.95,.13),(1,.28),(.88,.53),(.65,.72),(.34,.91),(0,1),(-.34,.91),(-.65,.72),(-.88,.53),(-1,.28),(-.95,.13),(-.64,0)]
for y,rx,rz,zc in [(-.255,.29,.43,1.56),(.035,.31,.62,1.56),(.255,.255,.52,1.57)]:
    for px,pz in profile:
        depth=y + (.10*(1-pz) if y<0 else -.055*(1-pz))
        verts.append((px*rx,depth,zc+pz*rz))
faces=[]
for j in range(2):
    for i in range(12):
        a=j*13+i; faces.extend([(a,a+1,a+14),(a,a+14,a+13)])
faces.append(tuple(range(26,39)))
faces.append((0,13,26,38,25,12))
hood=mesh('Open hood',verts,faces,green)
mod=hood.modifiers.new('Hood thickness','SOLIDIFY'); mod.thickness=.018
for i in range(12):
    a=Vector(verts[i]); b=Vector(verts[i+1]); offset=Vector((-a.x*.055,-.005,-.026 if i in range(3,9) else .008))
    mesh('Hood ivory edging',[a,b,b+offset,a+offset],[(0,1,2,3)],trim)
mesh('Hood rear point',[(0,.035,2.18),(-.19,.23,1.98),(.19,.23,1.98),(0,.43,1.98)],[(0,1,3),(0,3,2),(1,2,3)],green)
# Cape widens towards a jagged hem behind the body.
v=[]
hem=[.09,.03,.055,-.03,.025,-.10,-.02,-.13,-.085,.005,-.045,.04,-.01,.035,.065,.015,-.025,.055,-.035,-.11,-.04,-.075,.02,.075,.03,.09]
for z,w,y in [(1.52,.27,.15),(1.28,.30,.22),(1.03,.38,.27),(.76,.52,.34),(.57,.66,.41)]:
    for i in range(26):
        x=w*(i/12.5-1); zz=z+(hem[i] if z==.57 else 0)
        v.append((x,y+.052*math.cos(i*math.pi/4),zz))
f=[]
for j in range(4):
    for i in range(25):
        a=j*26+i; f.extend([(a,a+1,a+27),(a,a+27,a+26)])
cape=mesh('Jagged cape',v,f,green); cape.modifiers.new('Cape thickness','SOLIDIFY').thickness=.012
mesh('Shoulder scarf',[(-.31,-.12,1.54),(0,-.24,1.50),(.31,-.12,1.54),(.24,-.19,1.37),(0,-.245,1.29),(-.24,-.19,1.37)],[(0,1,5),(1,4,5),(1,2,3),(1,3,4)],green)
mesh('Scarf folds',[(-.32,-.13,1.55),(-.13,-.23,1.56),(.14,-.23,1.54),(.32,-.13,1.55),(.22,-.22,1.46),(0,-.27,1.41),(-.24,-.22,1.47)],[(0,1,6),(1,5,6),(1,2,5),(2,4,5),(2,3,4)],green)
strap('Diagonal chest strap',(-.24,-.20,1.48),(.20,-.20,1.02),.07,leather)
strap('Cross chest strap',(.20,-.20,1.42),(-.19,-.20,1.04),.052,leather)
box('Waist belt',(0,-.005,.995),(.54,.36,.09),leather,.025)
def buckle(name,x,y,z,size):
    for dx,dz,sx,sz in [(-size/2,0,.018,size),(size/2,0,.018,size),(0,-size/2,size,.018),(0,size/2,size,.018)]:
        box(name,(x+dx,y,z+dz),(sx,.024,sz),gold,.004)
buckle('Belt buckle',0,-.203,.995,.125)
buckle('Chest buckle',.04,-.244,1.19,.075)
rod('Quiver',(-.22,.25,1.10),(-.37,.27,1.62),.095,leather)
rod('Quiver rim',(-.36,.27,1.58),(-.38,.27,1.65),.11,leather)
for i in range(4):
    x=-.42+i*.038; a=(x+.10,.27,1.32); b=(x-.055,.27,1.88+i*.025)
    rod('Arrow shaft',a,b,.009,leather)
    tip=Vector(b); direction=(tip-Vector(a)).normalized()
    for axis in [Vector((.033,0,0)),Vector((0,.033,0))]:
        p=tip-direction*.035; q=tip-direction*.17
        mesh('Arrow feather',[p+axis,q+axis,q-axis,p-axis],[(0,1,2,3)],trim)
# Hand-painted-style faceted color variations without external textures.
for base in [green,leather,dark,trim,skin]:
    palette=[base]
    for i,factor in enumerate([.78,.89,1.06,1.15]):
        color=tuple(min(1,c*factor) for c in base.diffuse_color[:3])
        palette.append(mat(base.name+' facet '+str(i),color))
    for ob in list(bpy.context.scene.objects):
        if ob.type!='MESH' or not ob.data.materials or ob.data.materials[0]!=base: continue
        for m in palette[1:]: ob.data.materials.append(m)
        for face in ob.data.polygons:
            face.material_index=0 if base==skin else random.choices(range(5),weights=[60,6,12,16,6])[0]
# Presentation scene is excluded from GLB selection.
character=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in character: o.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'archer.glb'),use_selection=True,export_format='GLB')
ground=mat('Ground',(.19,.22,.25))
box('Display floor',(0,0,-.025),(200,200,.02),ground)
bpy.ops.object.camera_add(location=(3,-6,2.7)); cam=bpy.context.object; cam.name='Preview camera'
cam.rotation_euler=(Vector((0,0,1.05))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=2.7; bpy.context.scene.camera=cam
for loc,power,size in [((1,-4,5),450,4),((-3,-1,3),280,3),((0,3,4),500,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc); ob=bpy.context.object; ob.data.energy=power; ob.data.shape='DISK'; ob.data.size=size; ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.world.color=(.25,.25,.25); scene.view_settings.view_transform='AgX'; scene.render.resolution_x=1000; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.filepath=os.path.join(OUT,'preview.png')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'archer.blend'))
bpy.ops.render.render(write_still=True)
cam.location=(0,-6,1.08); cam.rotation_euler=(Vector((0,0,1.08))-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=os.path.join(OUT,'front.png'); bpy.ops.render.render(write_still=True)
cam.location=(6,0,1.08); cam.rotation_euler=(Vector((0,0,1.08))-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=os.path.join(OUT,'side.png'); bpy.ops.render.render(write_still=True)
print('ARCHER_COMPLETE',OUT,len(character))
