using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;

public class Editor : Form {
 [StructLayout(LayoutKind.Sequential)] struct Region { public ulong Base, Allocation; public uint AllocationProtect; public ushort Partition; public ulong Size; public uint State, Protect, Type; }
 [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
 [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
 [DllImport("kernel32.dll")] static extern UIntPtr VirtualQueryEx(IntPtr h, UIntPtr address, out Region info, UIntPtr size);
 [DllImport("kernel32.dll", SetLastError=true)] static extern bool ReadProcessMemory(IntPtr h, UIntPtr address, byte[] data, UIntPtr size, out UIntPtr read);
 [DllImport("kernel32.dll", SetLastError=true)] static extern bool WriteProcessMemory(IntPtr h, UIntPtr address, byte[] data, UIntPtr size, out UIntPtr written);
 IntPtr handle; int pid; bool busy; int searchKind = -1; List<ulong> hits = new List<ulong>();
 ComboBox type = new ComboBox(); TextBox value = new TextBox(); ListBox results = new ListBox(); Label status = new Label();
 Button connect = new Button(), scan = new Button(), refine = new Button(), write = new Button();
 public Editor() {
  Text="Megabonk — editor de memória"; ClientSize=new Size(640,460); Font=new Font("Segoe UI",10); StartPosition=FormStartPosition.CenterScreen;
  var intro=new Label { Text="Busque um valor, mude-o no jogo e refine a busca.\nSelecione um endereço antes de aplicar um novo valor.", Location=new Point(18,15), Size=new Size(600,48) }; Controls.Add(intro);
  connect.Text="Conectar ao jogo"; connect.SetBounds(18,70,190,34); Controls.Add(connect); connect.Click+=(s,e)=>Connect();
  type.DropDownStyle=ComboBoxStyle.DropDownList; type.Items.AddRange(new object[]{"Inteiro (32 bits)","Decimal (float)","Decimal (double)"}); type.SelectedIndex=0; type.SetBounds(220,73,210,30); Controls.Add(type);
  value.SetBounds(18,120,190,30); value.Text="100"; Controls.Add(value);
  scan.Text="Nova busca"; scan.SetBounds(220,118,125,34); Controls.Add(scan); scan.Click+=async(s,e)=>await Search(false);
  refine.Text="Refinar"; refine.SetBounds(355,118,125,34); Controls.Add(refine); refine.Click+=async(s,e)=>await Search(true);
  write.Text="Aplicar valor"; write.SetBounds(490,118,130,34); Controls.Add(write); write.Click+=async(s,e)=>await Write();
  results.SetBounds(18,170,602,225); Controls.Add(results); status.SetBounds(18,407,602,45); status.Text="Abra uma partida e conecte ao jogo."; Controls.Add(status);
  FormClosed+=(s,e)=>{ if(handle!=IntPtr.Zero) CloseHandle(handle); };
 }
 void Connect() { if(busy)return; var p=Process.GetProcessesByName("Megabonk"); if(p.Length!=1){ status.Text="Abra uma única instância do Megabonk."; return; } if(handle!=IntPtr.Zero)CloseHandle(handle); handle=OpenProcess(0x438,false,p[0].Id); pid=p[0].Id; hits.Clear(); results.Items.Clear(); status.Text=handle==IntPtr.Zero?"Acesso negado. Tente executar como administrador.":"Conectado ao Megabonk (PID "+pid+")."; }
 byte[] Parse(int kind) { string v=value.Text.Trim().Replace(',','.'); if(kind==0)return BitConverter.GetBytes(int.Parse(v,CultureInfo.InvariantCulture)); if(kind==1)return BitConverter.GetBytes(float.Parse(v,CultureInfo.InvariantCulture)); return BitConverter.GetBytes(double.Parse(v,CultureInfo.InvariantCulture)); }
 bool Match(byte[] data,int offset,byte[] expected){for(int i=0;i<expected.Length;i++)if(data[offset+i]!=expected[i])return false;return true;}
 async Task Search(bool narrow) {
  if(busy)return; if(handle==IntPtr.Zero){status.Text="Conecte ao jogo primeiro.";return;}
  if(narrow && searchKind!=type.SelectedIndex){status.Text="O tipo mudou. Faça uma nova busca antes de refinar.";return;}
  searchKind=type.SelectedIndex;
  byte[] target; try{target=Parse(type.SelectedIndex);}catch{status.Text="Digite um número válido para o tipo escolhido.";return;}
  busy=true; connect.Enabled=scan.Enabled=refine.Enabled=write.Enabled=type.Enabled=false; status.Text="Buscando na memória…";
  try { var found=await Task.Run(()=>{
   var list=new List<ulong>(); UIntPtr count;
   if(narrow){foreach(ulong a in hits){var b=new byte[target.Length]; if(ReadProcessMemory(handle,new UIntPtr(a),b,new UIntPtr((uint)b.Length),out count)&&count.ToUInt64()==(ulong)b.Length&&Match(b,0,target))list.Add(a);}return list;}
   ulong cursor=0; Region r;
   while(VirtualQueryEx(handle,new UIntPtr(cursor),out r,new UIntPtr((uint)Marshal.SizeOf(typeof(Region)))).ToUInt64()!=0){
    ulong end=r.Base+r.Size;if(end<=cursor)break;
    uint protect=r.Protect & 0xff;
    if(r.State==0x1000 && (r.Protect & 0x100)==0 && (protect==4||protect==8||protect==0x40||protect==0x80)) {
     for(ulong a=r.Base;a<end;){int n=(int)Math.Min(1048576UL,end-a);var b=new byte[n]; ReadProcessMemory(handle,new UIntPtr(a),b,new UIntPtr((uint)n),out count); int got=(int)count.ToUInt64();
      for(int i=0;i+target.Length<=got;i+=4)if(Match(b,i,target)){list.Add(a+(ulong)i);if(list.Count>=500000)throw new InvalidOperationException("Muitos resultados. Procure um valor mais específico, diferente de zero.");}
      a+=(ulong)n;
     }
    } cursor=end;
   }return list;
  }); hits=found; results.Items.Clear(); for(int i=0;i<Math.Min(hits.Count,2000);i++)results.Items.Add("0x"+hits[i].ToString("X16")); status.Text=hits.Count+" resultados. Exibindo até 2000. Mude o valor no jogo e refine.";
  }catch(Exception ex){status.Text=ex.Message;}finally{busy=false;connect.Enabled=scan.Enabled=refine.Enabled=write.Enabled=type.Enabled=true;}
 }
 string Format(byte[] data,int kind){return kind==0?BitConverter.ToInt32(data,0).ToString():kind==1?BitConverter.ToSingle(data,0).ToString():BitConverter.ToDouble(data,0).ToString();}
 byte[] ReadValue(ulong address,int size){var data=new byte[size];UIntPtr count;if(!ReadProcessMemory(handle,new UIntPtr(address),data,new UIntPtr((uint)size),out count)||count.ToUInt64()!=(ulong)size)throw new Exception("Não foi possível ler o endereço. Reconecte e refaça a busca.");return data;}
 async Task Write(){
  if(busy)return;
  if(results.SelectedIndex<0){status.Text="Selecione um endereço na lista.";return;}
  if(searchKind!=type.SelectedIndex){status.Text="O tipo mudou. Faça uma nova busca antes de aplicar.";return;}
  try{
   int kind=searchKind;var data=Parse(kind);ulong a=hits[results.SelectedIndex];var original=ReadValue(a,data.Length);
   if(MessageBox.Show("Endereço: 0x"+a.ToString("X")+"\nValor atual: "+Format(original,kind)+"\nNovo valor: "+value.Text+"\n\nAplicar?","Confirmar alteração",MessageBoxButtons.YesNo)!=DialogResult.Yes)return;
   busy=true;connect.Enabled=scan.Enabled=refine.Enabled=write.Enabled=type.Enabled=false;
   UIntPtr count;
   if(!WriteProcessMemory(handle,new UIntPtr(a),data,new UIntPtr((uint)data.Length),out count)||count.ToUInt64()!=(ulong)data.Length)throw new Exception("Escrita recusada. Código do Windows: "+Marshal.GetLastWin32Error());
   var immediate=ReadValue(a,data.Length);
   if(!Match(immediate,0,data)){status.Text="O valor já mudou após a escrita. Atual: "+Format(immediate,kind);return;}
   status.Text="Escrita conferida. Verificando se o jogo substitui o valor…";
   await Task.Delay(1000);
   var later=ReadValue(a,data.Length);
   status.Text=Match(later,0,data)?"Valor mantido na memória após 1 s. Confira o atributo no jogo.":"O valor mudou após a escrita. Atual: "+Format(later,kind)+". Pode ser recalculado pelo jogo.";
  }catch(Exception ex){status.Text=ex.Message;}
  finally{busy=false;connect.Enabled=scan.Enabled=refine.Enabled=write.Enabled=type.Enabled=true;}
 }
 [STAThread] public static void Main(){Application.EnableVisualStyles();Application.Run(new Editor());}
}
