import bpy, math, os, random
from mathutils import Vector

# Share the player's mesh construction helpers and material style.
exec(open(os.path.join(os.path.dirname(__file__), 'create_archer.py'), encoding='utf-8').read().split('# Front faces')[0])
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'characters', 'goblin'))
os.makedirs(OUT, exist_ok=True)
random.seed(47)
skin = mat('Goblin moss', (.35,.48,.07))
inner = mat('Ear ochre', (.38,.20,.065))
red = mat('Rust red scarf', (.48,.075,.035))
cloth = mat('Ragged hide', (.20,.115,.05))
metal = mat('Weathered iron', (.32,.30,.27))
ivory = mat('Fangs and wraps', (.68,.58,.37))
leather = mat('Goblin leather', (.24,.10,.035))
black = mat('Black eyes', (.004,.006,.002))

def pivot(name, loc, objects, parent=None):
    ob=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(ob); ob.location=loc
    bpy.context.view_layer.update()
    for child in objects:
        transform=child.matrix_world.copy(); child.parent=ob; child.matrix_world=transform
    if parent:
        transform=ob.matrix_world.copy(); ob.parent=parent; ob.matrix_world=transform
    bpy.context.view_layer.update()
    return ob

ball('Body',(0,0,.94),(.25,.15,.30),cloth,2)
cloth_volume('Patchwork shirt',[(.77,0,0,.21,.15),(.95,0,0,.23,.16),(1.16,0,0,.25,.15)],ivory,10)
strap('Chest strap',(-.21,-.17,1.13),(.20,-.17,.78),.065,leather)
for s in [-1,1]:
    # Tattered open vest and skirt silhouette.
    for i in range(3):
        x=s*(.08+i*.075)
        mesh('Vest tatters',[(x-.05,-.185,1.16),(x+.05,-.185,1.16),(x+.045,-.19,.85),(x,-.20,.80+random.random()*.06),(x-.05,-.185,.85)],[(0,1,2),(0,2,3),(0,3,4)],cloth)
    for i in range(6):
        a=2*math.pi*(i+(0 if s==1 else 6))/12
        b=a+2*math.pi/12
        mesh('Ragged skirt',[(.24*math.cos(a),.16*math.sin(a),.76),(.24*math.cos(b),.16*math.sin(b),.76),(.33*math.cos(b),.21*math.sin(b),.49),(.34*math.cos((a+b)/2),.22*math.sin((a+b)/2),.43+random.random()*.06),(.33*math.cos(a),.21*math.sin(a),.50)],[(0,1,2),(0,2,3),(0,3,4)],cloth)
    start=set(bpy.context.scene.objects)
    rod('Upper arm',(s*.24,0,1.13),(s*.44,0,1.13),.085,skin,.07)
    upper=list(set(bpy.context.scene.objects)-start)
    start=set(bpy.context.scene.objects)
    rod('Forearm',(s*.44,0,1.13),(s*.64,0,1.13),.07,skin,.065)
    rod('Wrist leather',(s*.58,0,1.13),(s*.69,0,1.13),.081,leather)
    for x in [.59,.67]: rod('Wrist band',(s*x,0,1.13),(s*(x+.022),0,1.13),.087,cloth)
    box('Palm',(s*.74,-.008,1.13),(.14,.11,.06),skin,.018)
    for f in range(3): box('Finger',(s*.835,-.045+f*.035,1.13),(.09,.03,.039),skin,.01)
    ball('Thumb',(s*.74,-.085,1.10),(.055,.045,.028),skin)
    fore=list(set(bpy.context.scene.objects)-start)
    arm=pivot('Arm_'+('L' if s<0 else 'R'),(s*.24,0,1.13),upper)
    pivot('Elbow_'+('L' if s<0 else 'R'),(s*.44,0,1.13),fore,arm)
    start=set(bpy.context.scene.objects)
    rod('Green thigh',(s*.15,0,.65),(s*.20,0,.37),.09,skin,.10)
    upper=list(set(bpy.context.scene.objects)-start)
    start=set(bpy.context.scene.objects)
    rod('Lower leg',(s*.20,0,.38),(s*.20,0,.12),.073,skin)
    for z in [.21,.255,.30]:
        wrap=rod('Bandage',(s*.20,0,z),(s*.20,0,z+.036),.084,ivory)
        wrap.rotation_euler.x+=s*.10
    rod('Boot cuff',(s*.20,0,.31),(s*.20,0,.36),.091,leather)
    box('Boot',(s*.20,-.08,.085),(.22,.32,.15),cloth,.045)
    box('Sole',(s*.20,-.075,.018),(.23,.34,.035),leather,.008)
    lower=list(set(bpy.context.scene.objects)-start)
    leg=pivot('Leg_'+('L' if s<0 else 'R'),(s*.15,0,.65),upper)
    pivot('Knee_'+('L' if s<0 else 'R'),(s*.20,0,.37),lower,leg)
    box('Belt pouch',(s*.27,-.055,.71),(.115,.11,.20),leather,.018)
    box('Pouch flap',(s*.27,-.12,.78),(.12,.025,.065),cloth,.01)

box('Waist belt',(0,0,.755),(.51,.34,.082),leather,.02)
for x,z,sx,sz in [(-.065,.755,.022,.115),(.065,.755,.022,.115),(0,.698,.15,.022),(0,.812,.15,.022)]:
    box('Iron buckle',(x,-.188,z),(sx,.025,sz),metal,.004)
mesh('Red belt banner',[(-.10,-.185,.72),(.10,-.185,.72),(.09,-.21,.50),(.03,-.22,.35),(0,-.22,.31),(-.04,-.22,.38),(-.09,-.21,.49)],[(0,1,2),(0,2,3),(0,3,4),(0,4,5),(0,5,6)],red)
rod('Neck',(0,0,1.14),(0,0,1.32),.10,skin)
head=cloth_volume('Large angular head',[(1.22,0,-.04,.11,.13),(1.27,0,-.025,.22,.20),(1.38,0,0,.29,.24),(1.58,0,.015,.30,.235),(1.74,0,.025,.235,.18),(1.82,0,.025,.10,.10)],skin,12)
for v in head.data.vertices:
    if v.co.y<-.12: v.co.y=-.24 if v.co.z<1.65 else -.19
ball('Broad muzzle',(0,-.195,1.31),(.20,.09,.08),skin,1)
for s in [-1,1]:
    verts=[(s*.23,-.05,1.63),(s*.65,.0,1.70),(s*.45,.02,1.43),(s*.27,.04,1.36),(s*.32,-.095,1.49),(s*.34,.075,1.50)]
    mesh('Pointed ear',verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,5,1),(1,5,2),(2,5,3),(3,5,0)],skin)
    mesh('Ear inner',[(s*.29,-.078,1.59),(s*.56,-.026,1.65),(s*.43,-.01,1.45),(s*.32,-.08,1.43),(s*.35,-.105,1.50)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],inner)
    box('Eye',(s*.115,-.248,1.48),(.047,.015,.115),black,.004)
    brow=box('Angry brow',(s*.12,-.255,1.55),(.09,.025,.032),skin,.005); brow.rotation_euler.y=-s*.28
    rod('Ivory fang',(s*.12,-.275,1.30),(s*.12,-.27,1.365),.023,ivory,0)
box('Mouth',(0,-.278,1.303),(.24,.007,.009),black)
cloth_volume('Red neck scarf',[(1.135,0,-.005,.25,.19),(1.215,0,0,.235,.175),(1.255,0,0,.17,.145)],red,10)
mesh('Pointed scarf',[(-.25,-.14,1.23),(0,-.25,1.19),(.25,-.14,1.23),(.18,-.22,1.02),(.12,-.25,1.06),(0,-.265,.94),(-.12,-.25,1.06),(-.19,-.22,1.00)],[(0,1,7),(1,6,7),(1,5,6),(1,4,5),(1,3,4),(1,2,3)],red)
ball('Iron shoulder plate',(.27,-.018,1.20),(.13,.14,.10),metal,1)
rod('Shoulder spike',(.30,0,1.24),(.34,0,1.40),.047,metal,0)
ball('Shoulder rivet',(.28,-.143,1.20),(.016,.012,.016),ivory)

for base in [skin,inner,red,cloth,leather,ivory,metal]:
    palette=[mat(base.name+' variation '+str(i),tuple(min(1,c*f) for c in base.diffuse_color[:3])) for i,f in enumerate([.8,.92,1.10,1.18])]
    for ob in list(bpy.context.scene.objects):
        if ob.type=='MESH' and ob.data.materials[0]==base:
            for m in palette: ob.data.materials.append(m)
            for face in ob.data.polygons: face.material_index=random.choices(range(5),weights=[55,8,12,18,7])[0]
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'goblin.glb'),export_format='GLB')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'goblin.blend'))
# Pose only the presentation image; exported model retains articulated T pose.
for s,side in [(-1,'L'),(1,'R')]: bpy.data.objects['Arm_'+side].rotation_euler.y=s*1.1
bpy.ops.object.camera_add(location=(2.8,-5,2.6)); cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,.95))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO'; cam.data.ortho_scale=2.35; bpy.context.scene.camera=cam
for loc,power,size in [((2,-4,5),450,4),((-3,-2,3),250,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc); light=bpy.context.object; light.data.energy=power; light.data.shape='DISK'; light.data.size=size
    light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.world.color=(.4,.4,.4); scene.render.resolution_x=700; scene.render.resolution_y=800; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=True
scene.render.filepath=os.path.join(OUT,'preview.png'); bpy.ops.render.render(write_still=True)
