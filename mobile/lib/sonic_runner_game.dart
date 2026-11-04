import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SonicRunnerPage extends StatefulWidget {
  final String lang;
  const SonicRunnerPage({super.key, required this.lang});
  @override
  State<SonicRunnerPage> createState() => _SonicRunnerPageState();
}

class _SonicRunnerPageState extends State<SonicRunnerPage> {
  static const double worldWidth = 4200, groundY = 330;
  Timer? _timer;
  double x=60, y=groundY-42, vx=0, vy=0, camera=0, jumpBuffer=0, coyote=0, invulnerable=0;
  bool left=false, right=false, jumping=false, rolling=false, grounded=true, paused=true, dead=false, complete=false;
  int rings=0, lives=3, score=0;
  final Set<int> collected={}, broken={};
  final ringPoints=List<Offset>.generate(45,(i)=>Offset(180+i*86.0,groundY-78-(i%3)*18.0));
  final hazards=<Rect>[const Rect.fromLTWH(650,groundY-24,34,24),const Rect.fromLTWH(1120,groundY-24,34,24),const Rect.fromLTWH(1750,groundY-24,68,24),const Rect.fromLTWH(2520,groundY-24,34,24),const Rect.fromLTWH(3280,groundY-24,68,24)];
  final platforms=<Rect>[const Rect.fromLTWH(850,245,230,18),const Rect.fromLTWH(1370,210,250,18),const Rect.fromLTWH(2100,250,250,18),const Rect.fromLTWH(2800,215,250,18)];
  final springs=<Rect>[const Rect.fromLTWH(980,groundY-16,34,16),const Rect.fromLTWH(1900,groundY-16,34,16),const Rect.fromLTWH(3000,groundY-16,34,16)];
  String t(String ar,String fr,String en)=>lang=='ar'?ar:lang=='fr'?fr:en;
  String get lang=>widget.lang;

  void _start(){if(dead||complete)_reset();if(!paused)return;setState(()=>paused=false);_timer??=Timer.periodic(const Duration(milliseconds:16),(_)=>_step(1/60));}
  void _pause(){if(!mounted)return;setState(()=>paused=true);}
  void _reset(){x=60;y=groundY-42;vx=0;vy=0;camera=0;rings=0;lives=3;score=0;collected.clear();broken.clear();grounded=true;dead=false;complete=false;invulnerable=0;jumpBuffer=0;coyote=0;}
  void _step(double dt){
    if(!mounted||paused||dead||complete)return;dt=dt.clamp(0.0,0.033);final oldY=y;
    const accel=1450.0,maxSpeed=520.0,friction=900.0;
    if(left)vx-=accel*dt;if(right)vx+=accel*dt;
    if(!left&&!right&&grounded)vx=vx.abs()<friction*dt?0:vx-vx.sign*friction*dt;
    vx=vx.clamp(-maxSpeed,maxSpeed);
    if(jumpBuffer>0)jumpBuffer-=dt;if(coyote>0)coyote-=dt;if(invulnerable>0)invulnerable-=dt;
    if(jumping)jumpBuffer=.13;
    if(jumpBuffer>0&&(grounded||coyote>0)){vy=-650;grounded=false;jumpBuffer=0;coyote=0;}
    vy+=1650*dt;if(rolling&&grounded)vx+=vx.sign*360*dt;
    x+=vx*dt;y+=vy*dt;grounded=false;
    if(vy>=0){
      if(oldY+42<=groundY&&y+42>=groundY){y=groundY-42;vy=0;grounded=true;coyote=.10;}
      for(final p in platforms){if(x+25>p.left&&x-25<p.right&&oldY+42<=p.top&&y+42>=p.top){y=p.top-42;vy=0;grounded=true;coyote=.10;}}
    }
    for(final s in springs){if(x+22>s.left&&x-22<s.right&&y+42>=s.top&&y+42<=s.bottom+18&&vy>=0){vy=-900;grounded=false;score+=25;}}
    for(var i=0;i<ringPoints.length;i++){if(!collected.contains(i)&&(Offset(x,y+18)-ringPoints[i]).distance<34){collected.add(i);rings++;score+=10;}}
    final player=Rect.fromCenter(center:Offset(x,y+18),width:36,height:42);
    for(final h in hazards){if(player.overlaps(h)&&invulnerable<=0){if(rings>0){rings=0;invulnerable=1.6;vx=-vx.sign*260;vy=-300;}else{lives--;invulnerable=1.6;vx=-vx.sign*220;vy=-320;if(lives<=0){dead=true;_pause();}}}}
    if(x<20){x=20;vx=0;}
    if(y>600){lives--;if(lives<=0){dead=true;_pause();}else{x=math.max(60,x-180);y=groundY-42;vy=0;rings=0;invulnerable=1.5;}}
    if(x>=worldWidth-100){complete=true;score+=rings*100;_pause();}
    camera=(x-130).clamp(0,worldWidth-360);if(mounted)setState((){});jumping=false;
  }
  void _hold(String a,bool v){setState((){if(a=='left')left=v;if(a=='right')right=v;if(a=='jump'){jumping=v;if(v)jumpBuffer=.13;}if(a=='roll')rolling=v;});}
  void _resetAndPause(){_pause();setState(_reset);}
  @override void dispose(){_timer?.cancel();super.dispose();}

  @override Widget build(BuildContext context){
    return Directionality(textDirection:lang=='ar'?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
      backgroundColor:const Color(0xFF07172C),
      appBar:AppBar(title:const Text('VELOCITY RUNNER',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1)),backgroundColor:const Color(0xFF102C4C),
        actions:[IconButton(onPressed:_resetAndPause,icon:const Icon(Icons.refresh)),IconButton(onPressed:paused?_start:_pause,icon:Icon(paused?Icons.play_arrow:Icons.pause))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          _stat('💍 '+rings.toString(),t('الحلقات','Anneaux','Rings')),_stat('❤️ '+lives.toString(),t('الأرواح','Vies','Lives')),
          _stat('⭐ '+score.toString(),t('النقاط','Score','Score')),_stat((vx.abs()/5.2).round().toString()+'%',t('السرعة','Vitesse','Speed'))])),
        Expanded(child:LayoutBuilder(builder:(context,c)=>ClipRect(child:Stack(children:[
          Positioned.fill(child:CustomPaint(painter:_RunnerPainter(camera:camera,playerX:x,playerY:y,rings:ringPoints,collected:collected,hazards:hazards,platforms:platforms,springs:springs,worldWidth:worldWidth,invulnerable:invulnerable>0))),
          if(paused||dead||complete)Positioned.fill(child:Container(color:Colors.black.withOpacity(.58),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text(dead?t('انتهت المحاولة','Partie terminée','Game over'):complete?t('أكملت المرحلة!','Niveau terminé !','Level complete!'):t('مستعد للانطلاق؟','Prêt à courir ?','Ready to run?'),style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:Colors.white)),
            const SizedBox(height:12),FilledButton.icon(onPressed:_start,icon:const Icon(Icons.play_arrow),label:Text(t('ابدأ اللعب','Jouer','Play')))])))),
          Positioned(left:12,bottom:12,child:Row(children:[_control(Icons.arrow_back,()=>_hold('left',true),()=>_hold('left',false)),const SizedBox(width:8),_control(Icons.arrow_forward,()=>_hold('right',true),()=>_hold('right',false))])),
          Positioned(right:12,bottom:12,child:Row(children:[_control(Icons.south,()=>_hold('roll',true),()=>_hold('roll',false),color:const Color(0xFFEF9B35)),const SizedBox(width:8),_control(Icons.arrow_upward,()=>_hold('jump',true),()=>_hold('jump',false),color:const Color(0xFF27C7E7))]))
        ])))),
        Padding(padding:const EdgeInsets.all(8),child:Text(t('اجمع الحلقات، اقفز فوق الأشواك، وحافظ على سرعتك.','Ramassez les anneaux, sautez les pics et gardez votre vitesse.','Collect rings, jump over spikes and keep your momentum.'),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:12)))
      ]))));
  }
  Widget _stat(String value,String label)=>Column(children:[Text(value,style:const TextStyle(fontWeight:FontWeight.w900,color:Colors.white)),Text(label,style:const TextStyle(fontSize:10,color:Colors.white70))]);
  Widget _control(IconData icon,VoidCallback down,VoidCallback up,{Color color=const Color(0xFF6E69E8)})=>GestureDetector(onTapDown:(_)=>down(),onTapUp:(_)=>up(),onTapCancel:up,child:Container(width:58,height:58,decoration:BoxDecoration(color:color.withOpacity(.88),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white54),boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:8,offset:Offset(0,4))]),child:Icon(icon,color:Colors.white,size:30)));
}

class _RunnerPainter extends CustomPainter{
  final double camera,playerX,playerY,worldWidth;final List<Offset> rings;final Set<int> collected;final List<Rect> hazards,platforms,springs;final bool invulnerable;
  _RunnerPainter({required this.camera,required this.playerX,required this.playerY,required this.rings,required this.collected,required this.hazards,required this.platforms,required this.springs,required this.worldWidth,required this.invulnerable});
  @override void paint(Canvas canvas,Size size){
    final sky=Paint()..shader=const LinearGradient(colors:[Color(0xFF48C9F0),Color(0xFFB9F4E8),Color(0xFF61B76C)],begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(Offset.zero&size);canvas.drawRect(Offset.zero&size,sky);canvas.save();canvas.translate(-camera,0);
    final hill=Paint()..color=const Color(0xFF26965F);for(int i=0;i<15;i++){final xx=i*320.0;canvas.drawOval(Rect.fromLTWH(xx,225+(i%3)*20,260,110),hill);}
    canvas.drawRect(Rect.fromLTWH(0,330,worldWidth,400),Paint()..color=const Color(0xFFB77A3B));canvas.drawRect(Rect.fromLTWH(0,330,worldWidth,13),Paint()..color=const Color(0xFF32B85C));
    final stripe=Paint()..color=const Color(0xFF8A542B);for(int i=0;i<80;i++){canvas.drawRect(Rect.fromLTWH(i*55.0,354+(i%4)*38,24,7),stripe);}
    for(final p in platforms){canvas.drawRect(p,Paint()..color=const Color(0xFF8D633C));canvas.drawRect(Rect.fromLTWH(p.left,p.top,p.width,5),Paint()..color=const Color(0xFF42C86B));}
    final ringPaint=Paint()..color=const Color(0xFFFFD84D)..style=PaintingStyle.stroke..strokeWidth=5;for(int i=0;i<rings.length;i++){if(!collected.contains(i)){final r=rings[i];canvas.drawOval(Rect.fromCenter(center:r,width:19,height:25),ringPaint);}}
    for(final h in hazards){final path=Path()..moveTo(h.left,h.bottom)..lineTo(h.center.dx,h.top)..lineTo(h.right,h.bottom)..close();canvas.drawPath(path,Paint()..color=const Color(0xFFEAF4F7));canvas.drawLine(Offset(h.left,h.bottom),Offset(h.right,h.bottom),Paint()..color=Colors.redAccent..strokeWidth=3);}
    for(final s in springs){canvas.drawRRect(RRect.fromRectAndRadius(s,const Radius.circular(4)),Paint()..color=const Color(0xFFE83E62));canvas.drawLine(Offset(s.left+4,s.top),Offset(s.right-4,s.top),Paint()..color=Colors.white..strokeWidth=3);}
    final body=Paint()..color=const Color(0xFF087DE0),dark=Paint()..color=const Color(0xFF064B9B);canvas.drawOval(Rect.fromCenter(center:Offset(playerX,playerY+18),width:36,height:43),body);canvas.drawCircle(Offset(playerX+9,playerY+6),5,Paint()..color=Colors.white);canvas.drawCircle(Offset(playerX+11,playerY+6),2.3,Paint()..color=Colors.black);canvas.drawOval(Rect.fromLTWH(playerX-24,playerY+30,25,9),dark);canvas.drawOval(Rect.fromLTWH(playerX+1,playerY+30,25,9),dark);
    if(invulnerable)canvas.drawCircle(Offset(playerX,playerY+18),29,Paint()..color=Colors.white.withOpacity(.35)..style=PaintingStyle.stroke..strokeWidth=3);canvas.restore();
  }
  @override bool shouldRepaint(covariant _RunnerPainter old)=>true;
}
