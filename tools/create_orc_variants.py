import bpy, os
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','assets','characters'))
for folder,color in [('orc_soldier',(.20,.45,.055)),('orc_commander',(.055,.22,.60))]:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(root,'orc_boss','orc_boss.blend'))
    for material in bpy.data.materials:
        if material.name.startswith('Goblin moss'):
            factor=material.diffuse_color[0]/.65
            rgba=tuple(min(1.0,c*factor) for c in color)+(1.0,)
            material.diffuse_color=rgba
            if material.use_nodes:
                next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs[0].default_value=rgba
    out=os.path.join(root,folder); os.makedirs(out,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,folder+'.blend'))
