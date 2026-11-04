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
  static const double groundY = 330;
  double get worldWidth => 4200.0 + (stage-1)*420.0;
  Timer? _timer;
  double x=60, y=groundY-42, vx=0, vy=0, camera=0, jumpBuffer=0, coyote=0, invulnerable=0, loopProgress=0, enemyClock=0, dashTimer=0, dashCooldown=0;
  int stage=1, defeatedEnemies=0;
  bool inLoop=false, loopUsed=false, shield=false;
  bool left=false, right=false, jumping=false, rolling=false, grounded=true, paused=true, dead=false, complete=false;
  int rings=0, lives=3, score=0;
  final Set<int> collected={}, broken={};
  List<Offset> get ringPoints => List<Offset>.generate(45+stage*4,(i)=>Offset(180+i*(stage==1?86.0:78.0),groundY-40-(i%3)*22.0));
  List<Rect> get hazards => [650.0,1120.0,1750.0,2520.0,3280.0].asMap().entries.map((e)=>Rect.fromLTWH(e.value+(stage-1)*45.0,groundY-24,e.key==2||e.key==4?68:34,24)).toList();
  List<Rect> get platforms => [const Rect.fromLTWH(850,245,230,18),const Rect.fromLTWH(1370,210,250,18),const Rect.fromLTWH(2100,250,250,18),const Rect.fromLTWH(2800,215,250,18)].map((p)=>p.shift(Offset((stage-1)*55.0,(stage-1)*-10.0))).toList();
  final springs=<Rect>[const Rect.fromLTWH(980,groundY-16,34,16),const Rect.fromLTWH(1900,groundY-16,34,16),const Rect.fromLTWH(3000,groundY-16,34,16)];
  final enemyBases=<Offset>[const Offset(760,groundY-24),const Offset(1220,groundY-24),const Offset(2360,groundY-24),const Offset(3140,groundY-24)];
  final Set<int> defeated={};
  String t(String ar,String fr,String en)=>lang=='ar'?ar:lang=='fr'?fr:en;
  String get lang=>widget.lang;

  void _start(){if(dead)_reset(preserveStage:true);if(!paused)return;setState(()=>paused=false);_timer??=Timer.periodic(const Duration(milliseconds:16),(_)=>_step(1/60));}
  void _nextStage(){final next=stage>=3?1:stage+1;_reset(preserveStage:true);setState(()=>stage=next);}
  void _pause(){if(!mounted)return;setState(()=>paused=true);}
  void _reset({bool preserveStage=false}){final currentStage=stage;x=60;y=groundY-42;vx=0;vy=0;camera=0;rings=0;lives=3;score=0;stage=preserveStage?currentStage:1;defeatedEnemies=0;collected.clear();broken.clear();defeated.clear();grounded=true;dead=false;complete=false;invulnerable=0;jumpBuffer=0;coyote=0;loopProgress=0;inLoop=false;loopUsed=false;shield=false;enemyClock=0;dashTimer=0;dashCooldown=0;}
  void _step(double dt){
    if(!mounted||paused||dead||complete)return;dt=dt.clamp(0.0,0.033).toDouble();final oldY=y;
    const accel=1450.0,maxSpeed=520.0,friction=900.0;
    if(left)vx-=accel*dt;if(right)vx+=accel*dt;
    if(!left&&!right&&grounded)vx=vx.abs()<friction*dt?0:vx-vx.sign*friction*dt;
    vx=vx.clamp(-maxSpeed,maxSpeed).toDouble();
    if(jumpBuffer>0)jumpBuffer-=dt;if(coyote>0)coyote-=dt;if(invulnerable>0)invulnerable-=dt;if(dashTimer>0)dashTimer-=dt;if(dashCooldown>0)dashCooldown-=dt;
    if(jumping)jumpBuffer=.13;
    enemyClock+=dt;
    if(jumpBuffer>0&&(grounded||coyote>0)){vy=-650;grounded=false;jumpBuffer=0;coyote=0;}
    vy+=1650*dt;if(rolling&&grounded)vx+=vx.sign*360*dt;
    x+=vx*dt;y+=vy*dt;grounded=false;
    // A momentum-gated loop-de-loop section: the runner follows a curved track
    // while the camera keeps the course moving forward.
    const loopStart=1430.0, loopRadius=110.0;
    if(!inLoop&&!loopUsed&&x>=loopStart&&vx>235){inLoop=true;loopUsed=true;loopProgress=0;}
    if(inLoop){
      loopProgress+=vx.abs()*dt/(2*math.pi*loopRadius);
      final angle=loopProgress*2*math.pi;
      x=loopStart+loopRadius*math.sin(angle);
      final centerY=groundY-21-loopRadius;
      y=centerY+loopRadius*math.cos(angle)-18;
      vy=0;grounded=true;coyote=.10;
      vx=math.min(690.0,vx+95*dt);
      if(loopProgress>=1){inLoop=false;loopProgress=1;x=loopStart+loopRadius+15;y=groundY-42;vy=0;grounded=true;}
    }
    // Gentle downhill/uphill track sections feed momentum back into the runner.
    if(!inLoop&&x>1880&&x<2070)vy+= (x<1975? -260:260)*dt;
    if(!inLoop&&x>2070&&x<2180&&y>groundY-42){y=groundY-42;vy=0;grounded=true;}
    if(vy>=0&&!inLoop){
      if(oldY+42<=groundY&&y+42>=groundY){y=groundY-42;vy=0;grounded=true;coyote=.10;}
      for(final p in platforms){if(x+25>p.left&&x-25<p.right&&oldY+42<=p.top&&y+42>=p.top){y=p.top-42;vy=0;grounded=true;coyote=.10;}}
    }
    for(final s in springs){if(x+22>s.left&&x-22<s.right&&y+42>=s.top&&y+42<=s.bottom+18&&vy>=0){vy=-900;grounded=false;score+=25;}}
    for(var i=0;i<enemyBases.length;i++){
      if(defeated.contains(i))continue;
      final base=enemyBases[i];
      final enemyX=base.dx+math.sin(enemyClock*1.8+i)*32;
      final enemy=Rect.fromCenter(center:Offset(enemyX,base.dy),width:34,height:30);
      if(playerRect(x,y).overlaps(enemy)){
        if(vy>120||rolling||dashTimer>0){defeated.add(i);defeatedEnemies++;score+=150;vy=-420;}
        else if(invulnerable<=0){if(rings>0){rings=math.max(0,rings-10);invulnerable=1.5;vx=-220;}else if(shield){shield=false;invulnerable=1.5;vx=-220;}else{lives--;invulnerable=1.5;vx=-220;if(lives<=0){dead=true;_pause();}}}
      }
    }
    for(var i=0;i<ringPoints.length;i++){if(!collected.contains(i)&&(Offset(x,y+18)-ringPoints[i]).distance<34){collected.add(i);rings++;score+=10;}}
    // A glowing shield pickup gives one free hit.
    if(!shield&&x>2210&&x<2250&&y<groundY-45){shield=true;score+=50;}
    final player=playerRect(x,y);
    for(final h in hazards){if(player.overlaps(h)&&invulnerable<=0&&dashTimer<=0){if(rings>0){rings=0;invulnerable=1.6;vx=-vx.sign*260;vy=-300;}else{lives--;invulnerable=1.6;vx=-vx.sign*220;vy=-320;if(lives<=0){dead=true;_pause();}}}}
    if(x<20){x=20;vx=0;}
    if(y>600){lives--;if(lives<=0){dead=true;_pause();}else{x=math.max(60,x-180).toDouble();y=groundY-42;vy=0;rings=0;invulnerable=1.5;}}
    if(x>=worldWidth-100){complete=true;score+=rings*100;_pause();}
    camera=(x-130).clamp(0,worldWidth-360).toDouble();if(mounted)setState((){});jumping=false;
  }
  void _dash(){if(paused||dead||complete||dashCooldown>0)return;setState((){final direction=right?1.0:left?-1.0:(vx<0?-1.0:1.0);vx=direction*780;vy=0;dashTimer=.24;dashCooldown=1.35;invulnerable=.28;score+=5;});}\n  void _hold(String a,bool v){setState((){if(a=='left')left=v;if(a=='right')right=v;if(a=='jump'){jumping=v;if(v)jumpBuffer=.13;}if(a=='roll')rolling=v;});}
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
          _stat('⭐ '+score.toString(),t('النقاط','Score','Score')),_stat('🏁 $stage/3',t('المرحلة','Niveau','Stage')),_stat((vx.abs()/6.9).round().toString()+'%',t('السرعة','Vitesse','Speed'))])),
        Expanded(child:LayoutBuilder(builder:(context,c)=>ClipRect(child:Stack(children:[
          Positioned.fill(child:CustomPaint(painter:_RunnerPainter(camera:camera,playerX:x,playerY:y,rings:ringPoints,collected:collected,hazards:hazards,platforms:platforms,springs:springs,enemies:enemyBases,defeated:defeated,worldWidth:worldWidth,invulnerable:invulnerable>0,inLoop:inLoop,loopProgress:loopProgress,shield:shield,dashActive:dashTimer>0,stage:stage))),
          if(paused||dead||complete)Positioned.fill(child:Container(color:Colors.black.withOpacity(.58),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text(dead?t('انتهت المحاولة','Partie terminée','Game over'):complete?(stage==3?t('أنهيت جميع المراحل!','Tous les niveaux terminés !','All stages complete!'):t('أكملت المرحلة!','Niveau terminé !','Stage complete!')):t('مستعد للانطلاق؟','Prêt à courir ?','Ready to run?'),style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:Colors.white)),
            const SizedBox(height:12),FilledButton.icon(onPressed:complete?_nextStage:_start,icon:const Icon(Icons.play_arrow),label:Text(complete?(stage==3?t('إعادة جميع المراحل','Recommencer','Restart all'):t('المرحلة التالية','Niveau suivant','Next stage')):t('ابدأ اللعب','Jouer','Play')))])))),
          Positioned(left:12,bottom:12,child:Row(children:[_control(Icons.arrow_back,()=>_hold('left',true),()=>_hold('left',false)),const SizedBox(width:8),_control(Icons.arrow_forward,()=>_hold('right',true),()=>_hold('right',false))])),
          Positioned(right:12,bottom:12,child:Row(children:[_control(Icons.south,()=>_hold('roll',true),()=>_hold('roll',false),color:const Color(0xFFEF9B35)),const SizedBox(width:8),_control(Icons.bolt,_dash,_dash,color:const Color(0xFFFFC247)),const SizedBox(width:8),_control(Icons.arrow_upward,()=>_hold('jump',true),()=>_hold('jump',false),color:const Color(0xFF27C7E7))]))
        ])))),
        Padding(padding:const EdgeInsets.all(8),child:Text(t('اجمع الحلقات، اقفز فوق الأشواك، وحافظ على سرعتك.','Ramassez les anneaux, sautez les pics et gardez votre vitesse.','Collect rings, jump over spikes and keep your momentum.'),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:12)))
      ]))));
  }
  Widget _stat(String value,String label)=>Column(children:[Text(value,style:const TextStyle(fontWeight:FontWeight.w900,color:Colors.white)),Text(label,style:const TextStyle(fontSize:10,color:Colors.white70))]);
  Rect playerRect(double px,double py)=>Rect.fromCenter(center:Offset(px,py+18),width:rolling?29:36,height:rolling?29:42);
  Widget _control(IconData icon,VoidCallback down,VoidCallback up,{Color color=const Color(0xFF6E69E8)})=>GestureDetector(onTapDown:(_)=>down(),onTapUp:(_)=>up(),onTapCancel:up,child:Container(width:58,height:58,decoration:BoxDecoration(color:color.withOpacity(.88),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white54),boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:8,offset:Offset(0,4))]),child:Icon(icon,color:Colors.white,size:30)));
}

class _RunnerPainter extends CustomPainter{\n  double vxDirection(double _) => 1.0;
  static const double groundY=330;
  final double camera,playerX,playerY,worldWidth,loopProgress;final List<Offset> rings,enemies;final Set<int> collected,defeated;final List<Rect> hazards,platforms,springs;final bool invulnerable,inLoop,shield,dashActive;final int stage;
  _RunnerPainter({required this.camera,required this.playerX,required this.playerY,required this.rings,required this.collected,required this.hazards,required this.platforms,required this.springs,required this.enemies,required this.defeated,required this.worldWidth,required this.invulnerable,required this.inLoop,required this.loopProgress,required this.shield,required this.dashActive,required this.stage});
  @override void paint(Canvas canvas,Size size){
    final colors=stage==1?[const Color(0xFF48C9F0),const Color(0xFFB9F4E8),const Color(0xFF61B76C)]:stage==2?[const Color(0xFF392B78),const Color(0xFF8A6AC8),const Color(0xFFCF8B68)]:[const Color(0xFF301B36),const Color(0xFFB84A4A),const Color(0xFFF0A34B)];
    final sky=Paint()..shader=LinearGradient(colors:colors,begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(Offset.zero&size);canvas.drawRect(Offset.zero&size,sky);canvas.save();canvas.translate(-camera,0);
    final hill=Paint()..color=const Color(0xFF26965F);for(int i=0;i<15;i++){final xx=i*320.0;canvas.drawOval(Rect.fromLTWH(xx,225+(i%3)*20,260,110),hill);}
    canvas.drawRect(Rect.fromLTWH(0,330,worldWidth,400),Paint()..color=stage==3?const Color(0xFF59404A):const Color(0xFFB77A3B));canvas.drawRect(Rect.fromLTWH(0,330,worldWidth,13),Paint()..color=stage==3?const Color(0xFFFF8C42):stage==2?const Color(0xFF9A70D0):const Color(0xFF32B85C));
    final stripe=Paint()..color=const Color(0xFF8A542B);for(int i=0;i<80;i++){canvas.drawRect(Rect.fromLTWH(i*55.0,354+(i%4)*38,24,7),stripe);}
    for(final p in platforms){canvas.drawRect(p,Paint()..color=const Color(0xFF8D633C));canvas.drawRect(Rect.fromLTWH(p.left,p.top,p.width,5),Paint()..color=const Color(0xFF42C86B));}
    // Curved high-speed track and banked slope artwork.
    final loopPaint=Paint()..color=const Color(0xFF2C8B50)..style=PaintingStyle.stroke..strokeWidth=17..strokeCap=StrokeCap.round;
    canvas.drawCircle(const Offset(1430,199),110,loopPaint);
    final slope=Path()..moveTo(1870,groundY)..quadraticBezierTo(1970,groundY-82,2070,groundY)..lineTo(2180,groundY)..lineTo(2180,groundY+20)..lineTo(1870,groundY+20)..close();
    canvas.drawPath(slope,Paint()..color=const Color(0xFF39A95E));
    final ringPaint=Paint()..color=const Color(0xFFFFD84D)..style=PaintingStyle.stroke..strokeWidth=5;for(int i=0;i<rings.length;i++){if(!collected.contains(i)){final r=rings[i];canvas.drawOval(Rect.fromCenter(center:r,width:19,height:25),ringPaint);}}
    for(final h in hazards){final path=Path()..moveTo(h.left,h.bottom)..lineTo(h.center.dx,h.top)..lineTo(h.right,h.bottom)..close();canvas.drawPath(path,Paint()..color=const Color(0xFFEAF4F7));canvas.drawLine(Offset(h.left,h.bottom),Offset(h.right,h.bottom),Paint()..color=Colors.redAccent..strokeWidth=3);}
    for(final s in springs){canvas.drawRRect(RRect.fromRectAndRadius(s,const Radius.circular(4)),Paint()..color=const Color(0xFFE83E62));canvas.drawLine(Offset(s.left+4,s.top),Offset(s.right-4,s.top),Paint()..color=Colors.white..strokeWidth=3);}
    for(var i=0;i<enemies.length;i++){if(defeated.contains(i))continue;final e=enemies[i];final bob=math.sin((playerX/60)+i)*5;final center=Offset(e.dx,e.dy+bob);canvas.drawCircle(center,15,Paint()..color=const Color(0xFFCF4B42));canvas.drawCircle(center.translate(-5,-3),3,Paint()..color=Colors.white);canvas.drawCircle(center.translate(5,-3),3,Paint()..color=Colors.white);canvas.drawLine(center.translate(-8,12),center.translate(8,12),Paint()..color=const Color(0xFF4B2730)..strokeWidth=3);}
    if(shield)canvas.drawCircle(Offset(playerX,playerY+18),32,Paint()..color=const Color(0xFF4DD9FF)..style=PaintingStyle.stroke..strokeWidth=4);\n    if(dashActive){final trail=Paint()..color=const Color(0xFF8CEBFF).withOpacity(.78)..strokeWidth=5..strokeCap=StrokeCap.round;for(var i=0;i<4;i++){final yy=playerY+7+i*8.0;canvas.drawLine(Offset(playerX-(vxDirection(playerX))* (26+i*9),yy),Offset(playerX-(vxDirection(playerX))*(8+i*8),yy),trail);}}
    final body=Paint()..color=const Color(0xFF087DE0),dark=Paint()..color=const Color(0xFF064B9B);canvas.drawOval(Rect.fromCenter(center:Offset(playerX,playerY+18),width:36,height:43),body);canvas.drawCircle(Offset(playerX+9,playerY+6),5,Paint()..color=Colors.white);canvas.drawCircle(Offset(playerX+11,playerY+6),2.3,Paint()..color=Colors.black);canvas.drawOval(Rect.fromLTWH(playerX-24,playerY+30,25,9),dark);canvas.drawOval(Rect.fromLTWH(playerX+1,playerY+30,25,9),dark);
    if(inLoop){final marker=Paint()..color=const Color(0xFFFFE16A)..strokeWidth=3;canvas.drawLine(Offset(1450,groundY-35),Offset(1472,groundY-55),marker);}
    if(invulnerable)canvas.drawCircle(Offset(playerX,playerY+18),29,Paint()..color=Colors.white.withOpacity(.35)..style=PaintingStyle.stroke..strokeWidth=3);canvas.restore();
  }
  @override bool shouldRepaint(covariant _RunnerPainter old)=>true;
}
