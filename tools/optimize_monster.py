"""Keep editable Blender sources; batch glTF surfaces by articulated parent."""
import bpy, os, collections
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','assets','characters'))
for folder,stem in [('goblin','goblin'),('orc_boss','orc_boss')]:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(root,folder,stem+'.blend'))
    material=bpy.data.materials.new('Faceted vertex colors'); material.use_nodes=True
    shader=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    shader.inputs['Roughness'].default_value=.85
    color=material.node_tree.nodes.new('ShaderNodeVertexColor'); color.layer_name='Color'
    material.node_tree.links.new(color.outputs['Color'],shader.inputs['Base Color'])
    groups=collections.defaultdict(list)
    for ob in list(bpy.context.scene.objects):
        if ob.type!='MESH': continue
        colors=ob.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
        for face in ob.data.polygons:
            rgba=ob.data.materials[face.material_index].diffuse_color
            for index in face.loop_indices: colors.data[index].color=rgba
            face.material_index=0
        ob.data.materials.clear(); ob.data.materials.append(material)
        groups[ob.parent].append(ob)
    for parent,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in objects: ob.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=os.path.join(root,folder,stem+'.glb'),export_format='GLB',export_vertex_color='MATERIAL')
    print(folder,'batched mesh count',len(groups))
