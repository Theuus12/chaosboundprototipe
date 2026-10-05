import sys,pathlib,re,json,struct
root=pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0,str(root/'tools/unity-inspect'))
import pefile,capstone
game=pathlib.Path(r'C:\Program Files (x86)\Steam\steamapps\common\Megabonk\GameAssembly.dll')
pe=pefile.PE(str(game)); base=pe.OPTIONAL_HEADER.ImageBase
dump=(root/'tools/il2cpp-dumper/dump.cs').read_text(encoding='utf-8-sig')
functions=[]
for match in re.finditer(r'// RVA: 0x([0-9A-F]+).*\n\s*(?:public|private|protected).*?([\w]+)\([^\n]*\) \{ \}',dump):
    if match.group(2) in ['CalculateBaseDamage','GetCritDamageMultiplier','GetDamage','GetDamageMultiplier','GetModificationTotal']:
        functions.append((int(match.group(1),16),match.group(2)))
dis=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64)
lines=[]
for rva,name in functions:
    lines.append(f'\n{name} RVA={rva:x}')
    for instruction in dis.disasm(pe.get_data(rva,1400),base+rva):
        line=f'{instruction.address:x} {instruction.mnemonic} {instruction.op_str}'
        # Read constants used through RIP-relative addressing.
        target=re.search(r'\[rip \+ (0x[0-9a-f]+)\]',instruction.op_str)
        if target:
            addr=instruction.address+instruction.size+int(target.group(1),16)-base
            raw=pe.get_data(addr,4)
            if len(raw)==4: line+=f' ; float={struct.unpack("<f",raw)[0]}'
        lines.append(line)
        if instruction.mnemonic=='ret': break
(root/'docs/megabonk-native-damage.txt').write_text('\n'.join(lines),encoding='utf-8')
print('Inspected',len(functions),'native routines.')
