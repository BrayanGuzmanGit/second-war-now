// Recetas reproducibles del selector: solo originales CC0 ya conservados.
const fs=require('fs'), path=require('path'), cp=require('child_process');
const root=path.resolve(__dirname,'../..'), src=path.join(__dirname,'originales');
const out=path.join(root,'Vistas/Recursos/Audio'), rate=44100;
const ff=process.env.FFMPEG || path.join(root,'.godot/herramientas/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe');
function decode(file,filter='anull'){
 const b=cp.execFileSync(ff,['-v','error','-i',path.join(src,file),'-af',filter,'-ac','1','-ar',String(rate),'-f','f32le','pipe:1'],{maxBuffer:64*1024*1024});
 const a=Array.from({length:b.length/4},(_,i)=>b.readFloatLE(i*4));
 let first=a.findIndex(v=>Math.abs(v)>0.003); return a.slice(Math.max(0,first-100));
}
const entries=[];
function make(name,duration,layers){
 const samples=new Float32Array(Math.round(duration*rate));
 for(const [file,filter,start,gain,length] of layers){
  const a=decode(file,filter), n=Math.min(a.length,Math.round(length*rate)), offset=Math.round(start*rate);
  for(let i=0;i<n && offset+i<samples.length;i++){
   const envelope=Math.max(0,Math.min(1,i/88,(n-1-i)/441));
   samples[offset+i]+=a[i]*gain*envelope;
  }
 }
 let peak=0;for(const v of samples)peak=Math.max(peak,Math.abs(v));
 if(peak<0.001)throw new Error('Recurso vacío: '+name);
 const b=Buffer.alloc(samples.length*4);
 samples.forEach((v,i)=>b.writeFloatLE(v*0.65/peak*Math.max(0,Math.min(1,i/88,(samples.length-1-i)/220)),i*4));
 cp.execFileSync(ff,['-v','error','-y','-f','f32le','-ar',String(rate),'-ac','1','-i','pipe:0','-c:a','pcm_s16le',path.join(out,name+'.wav')],{input:b});
 entries.push({archivo:name+'.wav',originales:[...new Set(layers.map(l=>l[0]))],edicion:{duracion:duration,capas:layers,descripcion:'Recorte inicial, filtros, montaje, fundidos de 2–10 ms y pico 0.65'},pico:0.65,bucle:false});
}
const metal='impactMetal_heavy_000.ogg';
make('selector_abrir',.10,[['click1.ogg','highpass=f=250,lowpass=f=4500',0,1,.10]]);
make('selector_cerrar',.10,[['click2.ogg','lowpass=f=3200',0,1,.10]]);
make('selector_estandar',.15,[[metal,'highpass=f=200,lowpass=f=4000',0,.65,.12],['switch3.ogg','anull',.035,.5,.115]]);
make('selector_pesado',.25,[['impactMetal_heavy_001.ogg','asetrate=33075,aresample=44100,lowpass=f=2400',0,1,.24],['switch5.ogg','lowpass=f=2500',.10,.35,.15]]);
make('selector_dispersion',.25,[0,.075,.15].map((t,i)=>['switch3.ogg','asetrate='+[48510,50715,52920][i]+',aresample=44100,highpass=f=350',t,1,.09]));
make('selector_bombardeo',.30,[['switch10.ogg','lowpass=f=3500',0,.9,.12],... [.09,.14,.19,.24].map(t=>['click2.ogg','highpass=f=400,lowpass=f=2600',t,.25,.05])]);
make('selector_incendiario',.25,[[metal,'highpass=f=500,lowpass=f=4500',0,.65,.09],['fire-1.wav','highpass=f=900,lowpass=f=5500',.055,.65,.195]]);
const manifestPath=path.join(out,'manifest.json');
const old=fs.existsSync(manifestPath)?JSON.parse(fs.readFileSync(manifestPath,'utf8')):[];
fs.writeFileSync(manifestPath,JSON.stringify([...old.filter(e=>!e.archivo.startsWith('selector_')),...entries],null,2)+'\n');
console.log('Preparados siete sonidos del selector.');
