import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()=>runApp(const NovaPlay());
const bg=Color(0xFF090D1B),panel=Color(0xFF151C31),purple=Color(0xFF8B6CFF),cyan=Color(0xFF36D8E8);
class NovaPlay extends StatefulWidget{const NovaPlay({super.key});@override State<NovaPlay> createState()=>_AppState();}
class _AppState extends State<NovaPlay>{String lang='ar';@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'NOVA PLAY',theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:ColorScheme.fromSeed(seedColor:purple,brightness:Brightness.dark),useMaterial3:true),home:Home(lang:lang,onLang:(v)=>setState(()=>lang=v)));}
String tr(String l,String k){const d={'ar':{'tag':'ألعابك المفضلة في مكان واحد','choose':'اختر لعبتك','play':'العب الآن','best':'أفضل نتيجة','xo':'تحدي إكس أو','memory':'اختبار الذاكرة','quick':'سرعة الاستجابة','quiz':'اختبر معلوماتك','back':'رجوع','again':'العب مجدداً','win':'أحسنت!','draw':'تعادل!','tap':'اضغط بأسرع ما يمكنك','start':'ابدأ','done':'انتهى التحدي','next':'التالي','question':'السؤال','pairs':'الأزواج'},'fr':{'tag':'Vos mini-jeux au même endroit','choose':'Choisissez un jeu','play':'Jouer','best':'Meilleur score','xo':'Morpion','memory':'Mémoire','quick':'Réflexes','quiz':'Quiz','back':'Retour','again':'Rejouer','win':'Bravo !','draw':'Égalité !','tap':'Tapez vite','start':'Démarrer','done':'Terminé','next':'Suivant','question':'Question','pairs':'Paires'},'en':{'tag':'Your mini games in one place','choose':'Choose a game','play':'Play now','best':'Best score','xo':'Tic-tac-toe','memory':'Memory Match','quick':'Quick Tap','quiz':'Brain Quiz','back':'Back','again':'Play again','win':'Well done!','draw':'Draw!','tap':'Tap as fast as you can','start':'Start','done':'Challenge complete','next':'Next','question':'Question','pairs':'Pairs'}};return d[l]?[k] ?? d['en']?[k] ?? k;}
class Game{final String id;final IconData icon;final Color color;const Game(this.id,this.icon,this.color);}
const games=[Game('xo',Icons.grid_3x3_rounded,purple),Game('memory',Icons.extension_rounded,cyan),Game('quick',Icons.bolt_rounded,Color(0xFFFFA43A)),Game('quiz',Icons.quiz_rounded,Color(0xFFFF648D))];
class Home extends StatefulWidget{final String lang;final ValueChanged<String> onLang;const Home({super.key,required this.lang,required this.onLang});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int best=0;@override void initState(){super.initState();load();}Future<void> load()async{final p=await SharedPreferences.getInstance();if(mounted)setState(()=>best=p.getInt('best')??0);}
@override Widget build(BuildContext c)=>Directionality(textDirection:widget.lang=='ar'?TextDirection.rtl:TextDirection.ltr,child:Scaffold(body:SafeArea(child:CustomScrollView(slivers:[
SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(gradient:const LinearGradient(colors:[purple,cyan]),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.sports_esports_rounded)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOVA PLAY',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,letterSpacing:1.2)),Text('ARCADE • MINI GAMES',style:TextStyle(color:cyan,fontSize:9,letterSpacing:1.4))])),PopupMenuButton<String>(onSelected:widget.onLang,itemBuilder:(_)=>const [PopupMenuItem(value:'ar',child:Text('العربية')),PopupMenuItem(value:'fr',child:Text('Français')),PopupMenuItem(value:'en',child:Text('English'))],child:const Icon(Icons.translate,color:cyan))]))),
SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,22),sliver:SliverToBoxAdapter(child:Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF30245F),Color(0xFF142D4B)]),borderRadius:BorderRadius.circular(25)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(tr(widget.lang,'tag'),style:const TextStyle(color:Colors.white70)),const SizedBox(height:10),const Text('PLAY. CHALLENGE.\nREPEAT.',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900,height:1.05)),const SizedBox(height:16),Row(children:[const Icon(Icons.emoji_events,color:Color(0xFFFFC857)),const SizedBox(width:8),Text(tr(widget.lang,'best')+': '+best.toString(),style:const TextStyle(fontWeight:FontWeight.bold))])])))),
SliverPadding(padding:const EdgeInsets.symmetric(horizontal:20),sliver:SliverToBoxAdapter(child:Text(tr(widget.lang,'choose'),style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)))),
SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverGrid(delegate:SliverChildBuilderDelegate((c,i){final g=games[i];return InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>PlayPage(game:g,lang:widget.lang,onScore:load))),child:Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22),border:Border.all(color:g.color.withOpacity(.3))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:48,height:48,decoration:BoxDecoration(color:g.color.withOpacity(.16),borderRadius:BorderRadius.circular(15)),child:Icon(g.icon,color:g.color,size:27)),const Spacer(),Text(tr(widget.lang,g.id),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:5),Text(tr(widget.lang,'play'),style:TextStyle(color:g.color,fontWeight:FontWeight.bold,fontSize:11))])));},childCount:4),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:13,mainAxisSpacing:13,childAspectRatio:0.95)))
]))));
}
class PlayPage extends StatefulWidget{final Game game;final String lang;final VoidCallback onScore;const PlayPage({super.key,required this.game,required this.lang,required this.onScore});@override State<PlayPage> createState()=>_PlayState();}
class _PlayState extends State<PlayPage>{final rng=Random();List<String> board=List.filled(9,'');List<int> cards=[];Set<int> open={},matched={};int moves=0,taps=0,seconds=10,q=0,points=0;bool started=false,finished=false,answered=false;Timer? quickTimer;
List<(String,String,List<String>)> get qs {
if(widget.lang=='fr') return [('Quelle est la plus grande planète ?','Jupiter',['Terre','Mars','Jupiter']),('Combien de couleurs dans l’arc-en-ciel ?','7',['5','7','9']),('Quelle est la capitale du Maroc ?','Rabat',['Fès','Rabat','Tanger']),('Quel animal est le vaisseau du désert ?','Le chameau',['Le chameau','Le cheval','L’éléphant']),('8 × 7 = ?','56',['54','56','64'])];
if(widget.lang=='en') return [('What is the largest planet?','Jupiter',['Earth','Mars','Jupiter']),('How many colors are in a rainbow?','7',['5','7','9']),('What is the capital of Morocco?','Rabat',['Fez','Rabat','Tangier']),('Which animal is the ship of the desert?','Camel',['Camel','Horse','Elephant']),('8 × 7 = ?','56',['54','56','64'])];
return [('ما أكبر كوكب؟','المشتري',['الأرض','المريخ','المشتري']),('كم لوناً في قوس قزح؟','7',['5','7','9']),('ما عاصمة المغرب؟','الرباط',['فاس','الرباط','طنجة']),('سفينة الصحراء؟','الجمل',['الجمل','الحصان','الفيل']),('8 × 7 = ؟','56',['54','56','64'])];
}
@override void initState(){super.initState();shuffle();}
@override void dispose(){quickTimer?.cancel();super.dispose();}void shuffle(){cards=[0,1,2,3,4,5,0,1,2,3,4,5]..shuffle(rng);}Future<void> save(int n)async{final p=await SharedPreferences.getInstance();final gameKey='best_${widget.game.id}';if(n>(p.getInt(gameKey)??0))await p.setInt(gameKey,n);if(n>(p.getInt('best')??0))await p.setInt('best',n);widget.onScore();}
void reset(){quickTimer?.cancel();setState((){board=List.filled(9,'');open={};matched={};moves=0;shuffle();taps=0;seconds=10;started=false;finished=false;q=0;points=0;answered=false;});}
String? winner(){const lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];for(final a in lines){if(board[a[0]].isNotEmpty&&board[a[0]]==board[a[1]]&&board[a[1]]==board[a[2]])return board[a[0]];}return board.every((e)=>e.isNotEmpty)?'D':null;}
@override Widget build(BuildContext c) => Directionality(textDirection: widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: Scaffold(appBar: AppBar(title: Text(tr(widget.lang, widget.game.id)), leading: IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.arrow_back)), actions: [IconButton(onPressed: reset, icon: const Icon(Icons.refresh))]), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: body())))));
Widget body(){switch(widget.game.id){case'xo':return xo();case'memory':return memory();case'quick':return quick();default:return quiz();}}
Widget xo(){final w=winner();return Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(w==null?'X     O':w=='D'?tr(widget.lang,'draw'):tr(widget.lang,'win'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:20),AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:9,mainAxisSpacing:9),itemBuilder:(c,i)=>InkWell(onTap:()=>move(i),child:Container(decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(17)),child:Center(child:Text(board[i],style:TextStyle(fontSize:42,fontWeight:FontWeight.w900,color:board[i]=='X'?purple:cyan))))))),if(w!=null)FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);}
void move(int i){if(board[i].isNotEmpty||winner()!=null)return;setState(()=>board[i]='X');if(winner()=='X'){save(10);return;}final e=List.generate(9,(j)=>j).where((j)=>board[j].isEmpty).toList();if(e.isNotEmpty)setState(()=>board[e[rng.nextInt(e.length)]]='O');}
Widget memory() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('${tr(widget.lang, 'pairs')}: ${matched.length ~/ 2} / 6'),
      const SizedBox(height: 18),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
        ),
        itemBuilder: (context, index) {
          final isVisible = open.contains(index) || matched.contains(index);
          final isMatched = matched.contains(index);
          final emojis = ['🍉', '🚀', '🎯', '🐼', '⭐', '🎮'];
          return InkWell(
            onTap: () => flip(index),
            child: Container(
              decoration: BoxDecoration(
                color: isMatched ? cyan.withOpacity(.2) : panel,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  isVisible ? emojis[cards[index]] : '?',
                  style: const TextStyle(fontSize: 27),
                ),
              ),
            ),
          );
        },
      ),
      if (matched.length == 12)
        FilledButton(
          onPressed: reset,
          child: Text(tr(widget.lang, 'again')),
        ),
    ],
  );
}
void flip(int i){if(open.contains(i)||matched.contains(i)||open.length>=2)return;setState(()=>open.add(i));if(open.length==2){moves++;final pair=open.toList();if(cards[pair[0]]==cards[pair[1]]){setState((){matched.addAll(pair);open.clear();});if(matched.length==12)save(max(1,100-moves));}else{Future.delayed(const Duration(milliseconds:700),(){if(mounted)setState(()=>open.clear());});}}}
Widget quick()=>Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(tr(widget.lang,'tap'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:15),Text(started?'$seconds s':'10 s',style:const TextStyle(fontSize:35,color:cyan,fontWeight:FontWeight.w900)),const SizedBox(height:20),GestureDetector(onTap:(){if(finished)return;if(!started){setState(()=>started=true);quickTimer=Timer.periodic(const Duration(seconds:1),(timer){if(!mounted){timer.cancel();return;}if(seconds<=1){timer.cancel();setState(()=>seconds=0);setState((){started=false;finished=true;});save(taps);}else{setState(()=>seconds--);}});}if(started)setState(()=>taps++);},child:Container(width:205,height:205,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[purple,Color(0xFF4B3A9B)])),child:Center(child:Text(finished?taps.toString():started?taps.toString():tr(widget.lang,'start'),style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900))))),if(finished)FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);
Widget quiz(){if(q>=qs.length)return Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(tr(widget.lang,'done'),style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),Text(points.toString()+' / 5',style:const TextStyle(fontSize:36,color:cyan)),FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);final item=qs[q];return Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(tr(widget.lang,'question')+' '+(q+1).toString()+' / 5',style:const TextStyle(color:cyan,fontWeight:FontWeight.bold)),const SizedBox(height:16),Text(item.$1,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:20),...item.$3.map((o)=>Padding(padding:const EdgeInsets.only(bottom:10),child:OutlinedButton(onPressed:answered?null:(){setState(()=>answered=true);if(o==item.$2)points++;},child:Text(o,style:const TextStyle(fontSize:17))))),if(answered)FilledButton(onPressed:(){setState((){q++;answered=false;});if(q==5)save(points*10);},child:Text(tr(widget.lang,'next')))]);}
}
