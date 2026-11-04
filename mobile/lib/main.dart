import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'snake_game.dart';
import 'chess_game.dart';
import 'pacman_game.dart';
import 'sonic_runner_game.dart';
import 'game_artwork.dart';

void main()=>runApp(const NovaPlay());
const bg=Color(0xFF090D1B),panel=Color(0xFF151C31),purple=Color(0xFF8B6CFF),cyan=Color(0xFF36D8E8);
class NovaPlay extends StatefulWidget{const NovaPlay({super.key});@override State<NovaPlay> createState()=>_AppState();}
class _AppState extends State<NovaPlay>{String lang='ar';@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'NOVA PLAY',theme:ThemeData(
  brightness:Brightness.dark,
  scaffoldBackgroundColor:bg,
  colorScheme:ColorScheme.fromSeed(seedColor:purple,brightness:Brightness.dark),
  useMaterial3:true,
  appBarTheme:const AppBarTheme(
    backgroundColor:bg,
    foregroundColor:Colors.white,
    surfaceTintColor:Colors.transparent,
    elevation:0,
  ),
  filledButtonTheme:FilledButtonThemeData(
    style:FilledButton.styleFrom(
      minimumSize:const Size(48,48),
      padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),
      backgroundColor:purple,
      foregroundColor:Colors.white,
      textStyle:const TextStyle(fontWeight:FontWeight.w800),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
      elevation:2,
    ),
  ),
  outlinedButtonTheme:OutlinedButtonThemeData(
    style:OutlinedButton.styleFrom(
      minimumSize:const Size(48,48),
      foregroundColor:Colors.white,
      side:const BorderSide(color:Color(0x668B6CFF)),
      textStyle:const TextStyle(fontWeight:FontWeight.w700),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
    ),
  ),
  iconButtonTheme:IconButtonThemeData(
    style:IconButton.styleFrom(
      foregroundColor:Colors.white,
      backgroundColor:const Color(0xFF151C31),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13)),
    ),
  ),
),home:Home(lang:lang,onLang:(v)=>setState(()=>lang=v)));}
String tr(String l,String k){const d={'ar':{'tag':'ألعابك المفضلة في مكان واحد','choose':'اختر لعبتك','play':'العب الآن','best':'أفضل نتيجة','xo':'تحدي إكس أو','memory':'اختبار الذاكرة','quick':'سرعة الاستجابة','quiz':'اختبر معلوماتك','back':'رجوع','again':'العب مجدداً','win':'أحسنت!','draw':'تعادل!','tap':'اضغط بأسرع ما يمكنك','start':'ابدأ','done':'انتهى التحدي','next':'التالي','question':'السؤال','pairs':'الأزواج','snake':'لعبة الأفعى','chess':'الشطرنج','pacman':'باك مان','sonic':'عدّاء السرعة'},'fr':{'tag':'Vos mini-jeux au même endroit','choose':'Choisissez un jeu','play':'Jouer','best':'Meilleur score','xo':'Morpion','memory':'Mémoire','quick':'Réflexes','quiz':'Quiz','back':'Retour','again':'Rejouer','win':'Bravo !','draw':'Égalité !','tap':'Tapez vite','start':'Démarrer','done':'Terminé','next':'Suivant','question':'Question','pairs':'Paires','snake':'Serpent','chess':'Échecs','pacman':'Pac-Man','sonic':'Velocity Runner'},'en':{'tag':'Your mini games in one place','choose':'Choose a game','play':'Play now','best':'Best score','xo':'Tic-tac-toe','memory':'Memory Match','quick':'Quick Tap','quiz':'Brain Quiz','back':'Back','again':'Play again','win':'Well done!','draw':'Draw!','tap':'Tap as fast as you can','start':'Start','done':'Challenge complete','next':'Next','question':'Question','pairs':'Pairs','snake':'Snake','chess':'Chess','pacman':'Pac-Man','sonic':'Velocity Runner'}};return d[l]?[k] ?? d['en']?[k] ?? k;}
class Game{final String id;final IconData icon;final Color color;const Game(this.id,this.icon,this.color);}
const games=[Game('xo',Icons.grid_3x3_rounded,purple),Game('memory',Icons.extension_rounded,cyan),Game('quick',Icons.bolt_rounded,Color(0xFFFFA43A)),Game('quiz',Icons.quiz_rounded,Color(0xFFFF648D)),Game('snake',Icons.pets_rounded,Color(0xFF4DDB85)),Game('chess',Icons.grid_4x4_rounded,Color(0xFFE8DCC5)),Game('pacman',Icons.sports_esports_rounded,Color(0xFFFFD84D)),Game('sonic',Icons.speed_rounded,Color(0xFF28B9F2))];
class Home extends StatefulWidget{final String lang;final ValueChanged<String> onLang;const Home({super.key,required this.lang,required this.onLang});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int best=0;@override void initState(){super.initState();load();}Future<void> load()async{final p=await SharedPreferences.getInstance();if(mounted)setState(()=>best=p.getInt('best')??0);}
@override Widget build(BuildContext c)=>Directionality(textDirection:widget.lang=='ar'?TextDirection.rtl:TextDirection.ltr,child:Scaffold(body:Stack(children:[Positioned.fill(child:DecoratedBox(decoration:const BoxDecoration(gradient:RadialGradient(center:Alignment(-.75,-.8),radius:1.25,colors:[Color(0xFF202C59),bg,Color(0xFF050812)])))),Positioned(top:95,right:-65,child:Container(width:190,height:190,decoration:BoxDecoration(shape:BoxShape.circle,color:purple.withOpacity(.10),boxShadow:[BoxShadow(color:purple.withOpacity(.15),blurRadius:70,spreadRadius:25)]))),Positioned(bottom:80,left:-75,child:Container(width:210,height:210,decoration:BoxDecoration(shape:BoxShape.circle,color:cyan.withOpacity(.08),boxShadow:[BoxShadow(color:cyan.withOpacity(.12),blurRadius:75,spreadRadius:25)]))),SafeArea(child:CustomScrollView(slivers:[
SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverToBoxAdapter(child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(gradient:const LinearGradient(colors:[purple,cyan]),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.sports_esports_rounded)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOVA PLAY',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,letterSpacing:1.2)),Text('ARCADE • MINI GAMES',style:TextStyle(color:cyan,fontSize:9,letterSpacing:1.4))])),IconButton(tooltip:'Privacy policy',onPressed:()=>showDialog(context:c,builder:(_)=>PrivacyInfo(lang:widget.lang)),icon:const Icon(Icons.privacy_tip_outlined,color:cyan)),PopupMenuButton<String>(onSelected:widget.onLang,itemBuilder:(_)=>const [PopupMenuItem(value:'ar',child:Text('العربية')),PopupMenuItem(value:'fr',child:Text('Français')),PopupMenuItem(value:'en',child:Text('English'))],child:const Icon(Icons.translate,color:cyan))]))),
SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,22),sliver:SliverToBoxAdapter(child:Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF30245F),Color(0xFF142D4B)]),borderRadius:BorderRadius.circular(25)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(tr(widget.lang,'tag'),style:const TextStyle(color:Colors.white70)),const SizedBox(height:10),const Text('PLAY. CHALLENGE.\nREPEAT.',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900,height:1.05)),const SizedBox(height:16),Row(children:[const Icon(Icons.emoji_events,color:Color(0xFFFFC857)),const SizedBox(width:8),Text(tr(widget.lang,'best')+': '+best.toString(),style:const TextStyle(fontWeight:FontWeight.bold))])])))),
SliverPadding(padding:const EdgeInsets.symmetric(horizontal:20),sliver:SliverToBoxAdapter(child:Text(tr(widget.lang,'choose'),style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)))),
SliverPadding(padding:const EdgeInsets.all(20),sliver:SliverGrid(delegate:SliverChildBuilderDelegate((c,i){final g=games[i];return GameCard3D(game:g,title:tr(widget.lang,g.id),playLabel:tr(widget.lang,'play'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>g.id=='snake'?SnakeGamePage(lang:widget.lang):g.id=='chess'?ChessGamePage(lang:widget.lang):g.id=='pacman'?PacManGamePage(lang:widget.lang):g.id=='sonic'?SonicRunnerPage(lang:widget.lang):PlayPage(game:g,lang:widget.lang,onScore:load))).then((_)=>load()));},childCount:games.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:13,mainAxisSpacing:13,childAspectRatio:0.74)))
]))])));
}
class PlayPage extends StatefulWidget{final Game game;final String lang;final VoidCallback onScore;const PlayPage({super.key,required this.game,required this.lang,required this.onScore});@override State<PlayPage> createState()=>_PlayState();}
class _PlayState extends State<PlayPage> with WidgetsBindingObserver{final rng=Random();List<String> board=List.filled(9,'');List<int> cards=[];Set<int> open={},matched={};int moves=0,taps=0,seconds=10,q=0,points=0,memoryTurn=0,stage=1,coins=0;String? selectedAnswer;bool started=false,finished=false,answered=false,stageAwarded=false;Timer? quickTimer;
List<(String,String,List<String>)> get qs {
if(widget.lang=='fr') return [('Quelle est la plus grande planète ?','Jupiter',['Terre','Mars','Jupiter']),('Combien de couleurs dans l’arc-en-ciel ?','7',['5','7','9']),('Quelle est la capitale du Maroc ?','Rabat',['Fès','Rabat','Tanger']),('Quel animal est le vaisseau du désert ?','Le chameau',['Le chameau','Le cheval','L’éléphant']),('8 × 7 = ?','56',['54','56','64'])];
if(widget.lang=='en') return [('What is the largest planet?','Jupiter',['Earth','Mars','Jupiter']),('How many colors are in a rainbow?','7',['5','7','9']),('What is the capital of Morocco?','Rabat',['Fez','Rabat','Tangier']),('Which animal is the ship of the desert?','Camel',['Camel','Horse','Elephant']),('8 × 7 = ?','56',['54','56','64'])];
return [('ما أكبر كوكب؟','المشتري',['الأرض','المريخ','المشتري']),('كم لوناً في قوس قزح؟','7',['5','7','9']),('ما عاصمة المغرب؟','الرباط',['فاس','الرباط','طنجة']),('سفينة الصحراء؟','الجمل',['الجمل','الحصان','الفيل']),('8 × 7 = ؟','56',['54','56','64'])];
}
@override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);shuffle();loadProgress();}
@override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed&&widget.game.id=='quick'&&started&&!finished){quickTimer?.cancel();quickTimer=null;if(mounted)setState(()=>started=false);}}
Future<void> loadProgress()async{final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){stage=p.getInt('stage_${widget.game.id}')??1;coins=p.getInt('nova_coins')??0;});}
Future<void> completeStage(int stars) async {
  if (stageAwarded) return;
  stageAwarded = true;
  final passed = stars > 0;
  final reward = passed ? stars * 25 + stage * 5 : 0;
  final prefs = await SharedPreferences.getInstance();
  final nextStage = passed && stage < 10 ? stage + 1 : stage;
  if (passed) await prefs.setInt('stage_${widget.game.id}', nextStage);
  if (passed) await prefs.setInt('nova_coins', (prefs.getInt('nova_coins') ?? 0) + reward);
  if (!mounted) return;
  setState(() {
    coins += reward;
    stage = nextStage;
  });
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: panel,
      title: Text(passed
          ? (widget.lang == 'ar' ? 'مرحلة مكتملة!' : widget.lang == 'fr' ? 'Niveau terminé !' : 'Stage complete!')
          : (widget.lang == 'ar' ? 'حاول مرة أخرى' : widget.lang == 'fr' ? 'Réessayez' : 'Try again')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              color: passed ? const Color(0xFFFFC857) : cyan, size: 64),
          Text(List.filled(stars, '⭐').join(), style: const TextStyle(fontSize: 28)),
          if (passed) Text('+$reward 🪙', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFFFFC857))),
          Text(widget.lang == 'ar' ? 'رصيدك: $coins قطعة ذهبية' : widget.lang == 'fr' ? 'Solde : $coins pièces' : 'Balance: $coins coins'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(widget.lang == 'ar' ? 'متابعة' : widget.lang == 'fr' ? 'Continuer' : 'Continue'),
        ),
      ],
    ),
  );
}
void showStages() {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: panel,
      title: Text(widget.lang == 'ar'
          ? 'المراحل والمكافآت'
          : widget.lang == 'fr'
              ? 'Niveaux et récompenses'
              : 'Stages & rewards'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.lang == 'ar'
                ? 'المرحلة المفتوحة: $stage / 10'
                : widget.lang == 'fr'
                    ? 'Niveau débloqué : $stage / 10'
                    : 'Unlocked stage: $stage / 10'),
            Text('🪙 $coins',
                style: const TextStyle(
                    color: Color(0xFFFFC857), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (index) {
                final level = index + 1;
                final unlocked = level <= stage;
                return InkWell(
                  onTap: unlocked
                      ? () {
                          setState(() => stage = level);
                          Navigator.pop(dialogContext);
                        }
                      : null,
                  child: Container(
                    width: 48,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: unlocked
                          ? const LinearGradient(
                              colors: [purple, Color(0xFF30245F)])
                          : null,
                      color: unlocked ? null : bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: unlocked ? cyan : Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            unlocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            size: 15),
                        Text('$level',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              widget.lang == 'ar'
                  ? 'كل مرحلة تمنحك عملات ونجوماً عند الفوز.'
                  : widget.lang == 'fr'
                      ? 'Gagnez des pièces et des étoiles à chaque victoire.'
                      : 'Win to earn coins and stars at every stage.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(widget.lang == 'ar'
              ? 'إغلاق'
              : widget.lang == 'fr'
                  ? 'Fermer'
                  : 'Close'),
        ),
      ],
    ),
  );
}
@override void dispose(){WidgetsBinding.instance.removeObserver(this);quickTimer?.cancel();super.dispose();}void shuffle(){cards=[0,1,2,3,4,5,0,1,2,3,4,5]..shuffle(rng);}Future<void> save(int n)async{final p=await SharedPreferences.getInstance();final gameKey='best_${widget.game.id}';if(n>(p.getInt(gameKey)??0))await p.setInt(gameKey,n);if(n>(p.getInt('best')??0))await p.setInt('best',n);widget.onScore();}
void reset(){quickTimer?.cancel();memoryTurn++;setState((){board=List.filled(9,'');open={};matched={};moves=0;shuffle();taps=0;seconds=10;started=false;finished=false;q=0;points=0;answered=false;selectedAnswer=null;stageAwarded=false;});}
String? _winnerFor(List<String> cells){const lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];for(final a in lines){if(cells[a[0]].isNotEmpty&&cells[a[0]]==cells[a[1]]&&cells[a[1]]==cells[a[2]])return cells[a[0]];}return cells.every((e)=>e.isNotEmpty)?'D':null;}
String? winner()=>_winnerFor(board);
int _minimax(List<String> cells,bool computerTurn,int depth){
 final result=_winnerFor(cells);
 if(result=='O')return 10-depth;
 if(result=='X')return depth-10;
 if(result=='D')return 0;
 final moves=[4,0,2,6,8,1,3,5,7].where((i)=>cells[i].isEmpty);
 var best=computerTurn?-100:100;
 for(final i in moves){
  cells[i]=computerTurn?'O':'X';
  final score=_minimax(cells,!computerTurn,depth+1);
  cells[i]='';
  best=computerTurn?max(best,score):min(best,score);
 }
 return best;
}
int _bestComputerMove(){
 var bestScore=-100, bestMove=-1;
 for(final i in [4,0,2,6,8,1,3,5,7]){
  if(board[i].isNotEmpty)continue;
  board[i]='O';
  final score=_minimax(board,false,0);
  board[i]='';
  if(score>bestScore){bestScore=score;bestMove=i;}
 }
 return bestMove;
}
@override
Widget build(BuildContext c) {
  return Directionality(
    textDirection: widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.lang, widget.game.id)),
        leading: IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(tooltip: 'Stages & rewards', onPressed: showStages, icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC857))),
          IconButton(onPressed: reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF30245F), Color(0xFF142D4B)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: purple.withOpacity(.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Color(0xFFFFC857)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.lang == 'ar' ? 'المرحلة $stage من 10' : widget.lang == 'fr' ? 'Niveau $stage sur 10' : 'Stage $stage of 10', style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('🪙 $coins', style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: Center(child: body())),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget body(){switch(widget.game.id){case'xo':return xo();case'memory':return memory();case'quick':return quick();default:return quiz();}}
Widget xo(){final w=winner();return Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(w==null?'X     O':w=='D'?tr(widget.lang,'draw'):tr(widget.lang,'win'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:20),AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:9,mainAxisSpacing:9),itemBuilder:(c,i)=>GestureDetector(onTap:()=>move(i),child:AnimatedContainer(duration:const Duration(milliseconds:260),decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:board[i].isEmpty?[const Color(0xFF273454),panel]:[board[i]=='X'?purple:cyan,board[i]=='X'?const Color(0xFF49328F):const Color(0xFF126A79)]),borderRadius:BorderRadius.circular(17),border:Border.all(color:(board[i]=='X'?purple:cyan).withOpacity(.45)),boxShadow:[BoxShadow(color:(board[i]=='X'?purple:cyan).withOpacity(board[i].isEmpty ? .08 : .32),blurRadius:board[i].isEmpty?5:18,offset:const Offset(0,7))]),child:Center(child:AnimatedSwitcher(duration:const Duration(milliseconds:280),transitionBuilder:(child,animation)=>ScaleTransition(scale:CurvedAnimation(parent:animation,curve:Curves.elasticOut),child:child),child:Text(board[i],key:ValueKey(board[i]),style:const TextStyle(fontSize:42,fontWeight:FontWeight.w900,color:Colors.white)))))))),if(w!=null)FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);}
void move(int i){
 if(board[i].isNotEmpty||winner()!=null)return;
 setState(()=>board[i]='X');
 final playerResult=winner();
 if(playerResult=='X'){save(10);completeStage(3);return;}
 if(playerResult=='D'){save(5);completeStage(0);return;}
 final reply=_bestComputerMove();
 if(reply>=0){
  setState(()=>board[reply]='O');
  final result=winner();
  if(result=='O'){save(0);completeStage(0);}
  else if(result=='D'){save(5);completeStage(0);}
 }
}
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
          return GestureDetector(onTap:()=>flip(index),child:TweenAnimationBuilder<double>(tween:Tween(begin:.82,end:1),duration:const Duration(milliseconds:300),curve:Curves.easeOutBack,builder:(context,scale,child)=>Transform.scale(scale:scale,child:Transform(alignment:Alignment.center,transform:Matrix4.identity()..setEntry(3,2,.001)..rotateY(isVisible?0:.10),child:child)),child:AnimatedContainer(duration:const Duration(milliseconds:250),decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:isMatched?[cyan,const Color(0xFF126A79)]:isVisible?[const Color(0xFF6550C9),const Color(0xFF30245F)]:[const Color(0xFF34466D),const Color(0xFF151C31)]),borderRadius:BorderRadius.circular(15),border:Border.all(color:isMatched?cyan:Colors.white.withOpacity(.14),width:isMatched?2:1),boxShadow:[BoxShadow(color:(isMatched?cyan:purple).withOpacity(.22),blurRadius:12,offset:const Offset(0,6))]),child:Center(child:AnimatedSwitcher(duration:const Duration(milliseconds:220),transitionBuilder:(child,animation)=>ScaleTransition(scale:animation,child:child),child:Text(isVisible?emojis[cards[index]]:'✦',key:ValueKey(isVisible),style:TextStyle(fontSize:isVisible?27:23,color:Colors.white,fontWeight:FontWeight.bold)))))));
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
void flip(int i){if(open.contains(i)||matched.contains(i)||open.length>=2)return;setState(()=>open.add(i));if(open.length==2){moves++;final pair=open.toList();if(cards[pair[0]]==cards[pair[1]]){setState((){matched.addAll(pair);open.clear();});if(matched.length==12){save(max(1,100-moves));completeStage(moves<=8?3:moves<=12?2:1);}}else{final turn=memoryTurn;Future.delayed(const Duration(milliseconds:700),(){if(mounted&&turn==memoryTurn)setState(()=>open.clear());});}}}
Widget quick()=>Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(tr(widget.lang,'tap'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:15),Text(started?'$seconds s':'10 s',style:const TextStyle(fontSize:35,color:cyan,fontWeight:FontWeight.w900)),const SizedBox(height:20),GestureDetector(onTap:(){if(finished)return;if(!started){setState(()=>started=true);quickTimer=Timer.periodic(const Duration(seconds:1),(timer){if(!mounted){timer.cancel();return;}if(seconds<=1){timer.cancel();setState(()=>seconds=0);setState((){started=false;finished=true;});save(taps);completeStage(taps>=25?3:taps>=15?2:1);}else{setState(()=>seconds--);}});}if(started)setState(()=>taps++);},child:AnimatedContainer(duration:const Duration(milliseconds:180),width:205,height:205,decoration:BoxDecoration(shape:BoxShape.circle,gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFFB09CFF),purple,Color(0xFF30245F)]),border:Border.all(color:Colors.white.withOpacity(.32),width:2),boxShadow:[BoxShadow(color:purple.withOpacity(.48),blurRadius:started?38:24,spreadRadius:started?5:1),const BoxShadow(color:Colors.black54,blurRadius:15,offset:Offset(0,12))]),child:Center(child:Text(finished?taps.toString():started?taps.toString():tr(widget.lang,'start'),style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,shadows:[Shadow(color:Colors.black45,blurRadius:8,offset:Offset(0,3))]))))),if(finished)FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);
Widget quiz(){if(q>=qs.length)return Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(tr(widget.lang,'done'),style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),Text(points.toString()+' / 5',style:const TextStyle(fontSize:36,color:cyan)),FilledButton(onPressed:reset,child:Text(tr(widget.lang,'again')))]);final item=qs[q];return Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(tr(widget.lang,'question')+' '+(q+1).toString()+' / 5',style:const TextStyle(color:cyan,fontWeight:FontWeight.bold)),const SizedBox(height:16),Text(item.$1,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:20),...item.$3.map((o)=>Padding(padding:const EdgeInsets.only(bottom:10),child:OutlinedButton(onPressed:answered?null:(){setState(()=>answered=true);selectedAnswer=o;if(o==item.$2)points++;},child:Text(o,style:const TextStyle(fontSize:17))))),if(answered)Padding(padding:const EdgeInsets.only(bottom:12),child:Text(selectedAnswer==item.$2?(widget.lang=='ar'?'إجابة صحيحة':widget.lang=='fr'?'Bonne réponse':'Correct!'):(widget.lang=='ar'?'الإجابة الصحيحة: ':widget.lang=='fr'?'Bonne réponse : ':'Correct answer: ')+item.$2,style:TextStyle(color:selectedAnswer==item.$2?cyan:const Color(0xFFFFA43A),fontWeight:FontWeight.bold))),if(answered)FilledButton(onPressed:(){setState((){q++;answered=false;selectedAnswer=null;});if(q==5){save(points*10);completeStage(points>=5?3:points>=3?2:0);}},child:Text(tr(widget.lang,'next')))]);}
}



class GameCard3D extends StatefulWidget {
  final Game game;
  final String title;
  final String playLabel;
  final VoidCallback onTap;

  const GameCard3D({
    super.key,
    required this.game,
    required this.title,
    required this.playLabel,
    required this.onTap,
  });

  @override
  State<GameCard3D> createState() => _GameCard3DState();
}

class _GameCard3DState extends State<GameCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(controller.value);
      return Transform.translate(
        offset: Offset(0, (1 - progress) * 12),
        child: Opacity(opacity: progress, child: child),
      );
    },
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.game.color.withOpacity(.22),
                panel,
                const Color(0xFF10182B),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.game.color.withOpacity(.5)),
            boxShadow: [
              BoxShadow(
                color: widget.game.color.withOpacity(.15),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 7,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'nova-art-${widget.game.id}',
                  child: GameCover(
                    gameId: widget.game.id,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 35,
                  child: FilledButton.icon(
                    onPressed: widget.onTap,
                    icon: const Icon(Icons.play_arrow_rounded, size: 19),
                    label: Text(
                      widget.playLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 35),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: widget.game.color.withOpacity(.22),
                      foregroundColor: widget.game.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: widget.game.color.withOpacity(.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PrivacyInfo extends StatelessWidget {
  final String lang;
  const PrivacyInfo({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final title = lang == 'ar' ? 'سياسة الخصوصية' : lang == 'fr' ? 'Politique de confidentialité' : 'Privacy Policy';
    final body = lang == 'ar'
      ? 'تطبيق NOVA PLAY يحترم خصوصيتك.\n\nالبيانات والتخزين: يحفظ التطبيق أفضل نتائج الألعاب محلياً على جهازك باستخدام مساحة التخزين الخاصة بالتطبيق. لا نرسل هذه النتائج إلى خوادمنا.\n\nالجمع والمشاركة: الإصدار الحالي لا يطلب إنشاء حساب، ولا يتضمن إعلانات أو أدوات تحليل، ولا يجمع أو يشارك معلومات شخصية عبر التطبيق.\n\nالاحتفاظ والحذف: تبقى النتائج على جهازك حتى تمسح بيانات التطبيق أو تزيله.\n\nالأطفال: التطبيق ليس مصمماً خصيصاً لجمع معلومات شخصية من الأطفال.\n\nالتواصل: لأي سؤال متعلق بالخصوصية، راسلنا على البريد التالي:'
      : lang == 'fr'
      ? 'NOVA PLAY respecte votre vie privée.\n\nDonnées et stockage : l’application conserve localement sur votre appareil les meilleurs scores des jeux à l’aide du stockage de l’application. Ces scores ne sont pas envoyés à nos serveurs.\n\nCollecte et partage : la version actuelle ne demande pas de créer un compte, ne contient ni publicité ni outil d’analyse, et ne collecte ni ne partage d’informations personnelles par l’application.\n\nConservation et suppression : les scores restent sur votre appareil jusqu’à ce que vous effaciez les données de l’application ou la désinstalliez.\n\nEnfants : l’application n’est pas conçue pour collecter des informations personnelles auprès des enfants.\n\nContact : pour toute question relative à la confidentialité, écrivez-nous à :'
      : 'NOVA PLAY respects your privacy.\n\nData and storage: the app stores game best scores locally on your device using the app’s local storage. These scores are not sent to our servers.\n\nCollection and sharing: the current version does not require account creation, contains no ads or analytics tools, and does not collect or share personal information through the app.\n\nRetention and deletion: scores remain on your device until you clear the app data or uninstall the app.\n\nChildren: the app is not designed to collect personal information from children.\n\nContact: for privacy questions, email us at:';
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(body),
            const SizedBox(height: 10),
            const SelectableText('Hamniat61@gmail.com', style: TextStyle(color: cyan, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(lang == 'ar' ? 'آخر تحديث: 4 نوفمبر 2026' : lang == 'fr' ? 'Dernière mise à jour : 4 novembre 2026' : 'Last updated: 4 November 2026'),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(lang == 'ar' ? 'إغلاق' : lang == 'fr' ? 'Fermer' : 'Close'))],
    );
  }
}