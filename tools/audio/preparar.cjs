// Reproduce las ediciones a partir de originales conservados; requiere FFmpeg.
const fs = require('fs'), path = require('path'), cp = require('child_process');
const root = path.resolve(__dirname, '../..');
const src = path.join(__dirname, 'originales');
const out = path.join(root, 'Vistas/Recursos/Audio');
const ff = process.env.FFMPEG || path.join(root, '.godot/herramientas/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe');
fs.mkdirSync(out, {recursive:true});
const rate = 44100, manifest = [];
function decode(file, filter='anull') {
 const data = cp.execFileSync(ff, ['-v','error','-i',path.join(src,file),'-af',filter,'-ac','1','-ar',String(rate),'-f','f32le','pipe:1'], {maxBuffer:64*1024*1024});
 return Array.from({length:data.length/4}, (_,i)=>data.readFloatLE(i*4));
}
function save(name, data, sources, edit, loop=false) {
 let peak = Math.max(...[0]); for(const x of data) peak=Math.max(peak,Math.abs(x));
 const gain=0.65/Math.max(peak,0.001);
 const b=Buffer.alloc(data.length*4);
 for(let i=0;i<data.length;i++) {
  const fade=loop?1:Math.min(1,i/220,(data.length-1-i)/880);
  b.writeFloatLE(data[i]*gain*Math.max(0,fade),i*4);
 }
 const args=['-v','error','-y','-f','f32le','-ar',String(rate),'-ac','1','-i','pipe:0'];
 args.push(...(loop?['-c:a','libvorbis','-q:a','5']:['-c:a','pcm_s16le']),path.join(out,name));
 cp.execFileSync(ff,args,{input:b});
 manifest.push({archivo:name,originales:sources,edicion:edit,pico:0.65,bucle:loop});
}
function loopSeam(a,seconds) {
 const n=Math.min(a.length,Math.floor(seconds*rate)), k=Math.min(4410,Math.floor(n/5));
 const b=a.slice(k,n);
 for(let i=0;i<k;i++) b[b.length-k+i]=a[n-k+i]*(1-i/k)+a[i]*(i/k);
 return b;
}
save('motor.ogg',loopSeam(decode('engine.ogg','highpass=f=45,lowpass=f=2400'),4),['engine.ogg'],'Mono, filtros, fundido circular y normalización',true);
const winch=fs.readdirSync(path.join(src,'winch')).filter(n=>n.endsWith('.wav'));
save('cadenas.ogg',loopSeam(decode('winch/'+winch[0],'asetrate=33075,aresample=44100,lowpass=f=2600'),3),['winch/'+winch[0]],'Mono, velocidad 0.75, filtro, unión circular',true);
save('engranajes.ogg',loopSeam(decode('winch/'+winch[1],'asetrate=39690,aresample=44100,highpass=f=250,lowpass=f=1700'),2),['winch/'+winch[1]],'Mono, velocidad 0.9, filtros y unión circular',true);
save('fuego.ogg',loopSeam(decode('fire-1.wav','highpass=f=100,lowpass=f=6000'),4),['fire-1.wav'],'Mono, filtros y unión circular',true);
save('bombardeo.ogg',loopSeam(decode('explosion1_0.ogg','asetrate=22050,aresample=44100,lowpass=f=1400'),1.5),['explosion1_0.ogg'],'Explosión grave sostenida, unión circular',true);
const mats={metal:'impactMetal_heavy',tierra:'impactSoft_heavy',arena:'footstep_snow',escombros:'impactMining'};
for(const [mat,stem] of Object.entries(mats)) for(let i=0;i<3;i++) {
 const file=`${stem}_${String(i).padStart(3,'0')}.ogg`;
 save(`${mat}_${i}.wav`,decode(file,mat==='arena'?'lowpass=f=2800':'anull'),[file],'Mono, filtro de arena cuando corresponde, fades y normalización');
}
for(const [mat,stem] of Object.entries({tierra:'footstep_grass',arena:'footstep_snow',escombros:'footstep_concrete'})) {
 const b=new Array(rate*3).fill(0), files=[];
 for(let i=0;i<12;i++) {
  const file=`${stem}_${String(i%3).padStart(3,'0')}.ogg`; if(i<3)files.push(file);
  const a=decode(file,'lowpass=f=3000');
  const offset=Math.floor(i*rate*0.25);
  for(let j=0;j<a.length;j++) b[(offset+j)%b.length]+=a[j]*Math.min(1,j/180,(a.length-1-j)/500);
 }
 save(`rodar_${mat}.ogg`,b,files,'Capas de contacto solapadas en bucle circular, mono',true);
}
const explosions=['explosion1_0.ogg','explosion2.ogg','explosion3.ogg'];
for(const [type,pitch,cut] of [['estandar',1,5000],['pesado',0.7,2200],['dispersion',1.4,4800],['bombardeo',0.8,1800],['incendiario',1.1,3800]]) {
 for(let i=0;i<3;i++) save(`impacto_${type}_${i}.wav`,decode(explosions[i],`asetrate=${Math.round(rate*pitch)},aresample=44100,lowpass=f=${cut},atrim=duration=${type==='dispersion'?0.45:2.5}`),[explosions[i]],`Velocidad ${pitch}, filtro ${cut} Hz, recorte y fades`);
}
save('disparo.wav',decode(explosions[0],'highpass=f=65,lowpass=f=4500,atrim=duration=1.2'),[explosions[0]],'Filtros, recorte 1.2s y fades');
save('destruccion.wav',decode(explosions[2],'asetrate=33075,aresample=44100,lowpass=f=3000'),[explosions[2]],'Velocidad 0.75, filtro, fades');
for(const [name,file] of Object.entries({division:'click2.ogg',bengala:'switch3.ogg',turno_jugador:'click1.ogg',turno_enemigo:'click2.ogg',evacuacion:'switch5.ogg',cuenta:'switch3.ogg',refuerzos:'switch10.ogg'}))
 save(name+'.wav',decode(file),[file],'Mono, normalización y fades');
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`Preparados ${manifest.length} sonidos.`);
require('./preparar-selector.cjs');
