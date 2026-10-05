import sys,pathlib,struct,re
root=pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0,str(root/'tools/unity-inspect'))
import pefile,capstone
pe=pefile.PE(r'C:\Program Files (x86)\Steam\steamapps\common\Megabonk\GameAssembly.dll'); base=pe.OPTIONAL_HEADER.ImageBase
cs=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64)
lines=[]
for rva in [0x4700F0,0x46FA50,0x46F6B0,0x46F320,0x46FAB0,0x46F5D0,0x46F560]:
 lines.append(hex(rva))
 for i in cs.disasm(pe.get_data(rva,900),base+rva):
  line=f'{i.mnemonic} {i.op_str}'
  m=re.search(r'\[rip \+ (0x[0-9a-f]+)\]',i.op_str)
  if m and i.mnemonic in ['movss','mulss','addss','divss']:
   raw=pe.get_data(i.address+i.size+int(m[1],16)-base,4)
   if len(raw)==4:line+=f' float={struct.unpack("<f",raw)[0]}'
  lines.append(line)
  if i.mnemonic=='ret':break
(root/'docs/megabonk-difficulty-native.txt').write_text('\n'.join(lines))
print('\n'.join(lines[:45]))
