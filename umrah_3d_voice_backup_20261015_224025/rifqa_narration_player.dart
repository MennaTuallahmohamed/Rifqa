import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'umrah_data.dart';

/// يفضل ملف mp3 المحلي الكامل إن كان موجودًا، وإلا يشغّل المعاينة القصيرة عبر الإنترنت.
/// روابط المعاينات ليست بديلًا عن ملفات التسجيل الكاملة للإصدار النهائي.
class RifqaNarrationPlayer extends StatefulWidget {
  const RifqaNarrationPlayer({super.key, required this.stepIndex, required this.onDua});
  final int stepIndex;
  final VoidCallback onDua;
  @override
  State<RifqaNarrationPlayer> createState() => _RifqaNarrationPlayerState();
}
class _RifqaNarrationPlayerState extends State<RifqaNarrationPlayer> {
  static const emerald = Color(0xFF0B4F3E);
  static const gold = Color(0xFFE5BE69);
  static const _previews = [
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/b2c72ffa-56f8-44a3-a623-e0c3e0210108.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/89121c54-c8f6-40d2-83a6-38a68c9abfd7.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/fa5d33b5-6b70-4a5a-b3e6-35cd6a9c75fa.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/be715f7b-4d54-4d7a-ac10-146685f61144.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/d32ab746-c9c9-4eb9-aacb-d83eac58ae22.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/306b4d79-228c-437f-ad2d-aab5c0f97ab1.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/471830a6-1b11-4180-ade9-c4440f9f9a58.mp3',
  ];
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  int _selected = 0;
  bool _playlist = false;
  bool _loading = false;
  String? _error;
  double _speed = 1;
  @override
  void initState() {
    super.initState();
    _selected = widget.stepIndex;
    _sub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed && _playlist && _selected < 6) {
        _load(_selected + 1, autoplay: true);
      } else if (state.processingState == ProcessingState.completed && _playlist && _selected == 6) {
        setState(() => _playlist = false);
      }
    });
  }
  @override
  void didUpdateWidget(covariant RifqaNarrationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex) {
      _playlist = false;
      _player.stop();
      setState(() => _selected = widget.stepIndex);
    }
  }
  Future<void> _load(int idx, {bool autoplay = false}) async {
    setState(() { _selected = idx; _loading = true; _error = null; });
    try {
      await _player.stop();
      try {
        await _player.setAsset('assets/audio/umrah/step_${idx + 1}.mp3');
      } catch (_) {
        await _player.setUrl(_previews[idx]);
      }
      await _player.setSpeed(_speed);
      if (!mounted) return;
      setState(() => _loading = false);
      if (autoplay) await _player.play();
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _playlist = false;
        _error = 'تعذر تشغيل الصوت. تأكدي من الإنترنت أو أضيفي ملفات MP3 الكاملة.';
      });
    }
  }
  Future<void> _toggle() async {
    if (_loading) return;
    if (_player.playing) { await _player.pause(); return; }
    if (_player.audioSource == null || _player.processingState == ProcessingState.completed) {
      await _load(_selected, autoplay: true);
    } else {
      await _player.play();
    }
  }
  Future<void> _seek(Duration delta) async {
    final d = _player.duration;
    if (d == null) return;
    final ms = (_player.position + delta).inMilliseconds.clamp(0,d.inMilliseconds).toInt();
    await _player.seek(Duration(milliseconds: ms));
  }
  String _time(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';
  @override
  void dispose() { _sub?.cancel(); _player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight,end: Alignment.bottomLeft,colors:[Color(0xFF0C5442),Color(0xFF092C25)]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x88D8B26B)),
        boxShadow: [BoxShadow(color: emerald.withValues(alpha: .22),blurRadius: 20,offset:const Offset(0,9))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
        const Row(children:[Icon(Icons.headphones_rounded,color:gold),SizedBox(width:9),Expanded(child:Text('رِفقة الصوتية',style:TextStyle(fontWeight:FontWeight.w900,color:Colors.white,fontSize:18))), Icon(Icons.auto_awesome_rounded,color:gold,size:19)]),
        const SizedBox(height:5),
        const Text('مرشدك الصوتي — تعليق وثائقي عربي عميق',style:TextStyle(color:Color(0xCCD5E7DA),fontSize:12)),
        const SizedBox(height:13),
        Text('الخطوة ${_selected + 1} · ${umrahGuide[_selected].title}',style:const TextStyle(color:gold,fontWeight:FontWeight.w800,fontSize:15)),
        const SizedBox(height:12),
        StreamBuilder<Duration>(stream:_player.positionStream,builder:(context,snap){
          final pos=snap.data??Duration.zero;
          final total=_player.duration??Duration.zero;
          final max=total.inMilliseconds>0?total.inMilliseconds.toDouble():1.0;
          return Column(children:[
            SliderTheme(data:SliderTheme.of(context).copyWith(activeTrackColor:gold,inactiveTrackColor:Colors.white24,thumbColor:gold,overlayColor:gold.withValues(alpha:.12),trackHeight:3),child:Slider(value:pos.inMilliseconds.toDouble().clamp(0,max),min:0,max:max,onChanged:total==Duration.zero?null:(v)=>_player.seek(Duration(milliseconds:v.toInt())))),
            Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(_time(pos),style:const TextStyle(color:Colors.white70,fontSize:11)),Text(_time(total),style:const TextStyle(color:Colors.white70,fontSize:11))])),
          ]);
        }),
        const SizedBox(height:10),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          IconButton(onPressed:()=>_seek(const Duration(seconds:-10)),icon:const Icon(Icons.replay_10_rounded,color:Colors.white,size:28)),
          const SizedBox(width:18),
          StreamBuilder<PlayerState>(stream:_player.playerStateStream,builder:(context,s){
            final playing=s.data?.playing??false;
            return Material(color:gold,shape:const CircleBorder(),child:IconButton(iconSize:32,onPressed:_loading?null:_toggle,icon:_loading?const SizedBox(width:25,height:25,child:CircularProgressIndicator(strokeWidth:2,color:emerald)):Icon(playing?Icons.pause_rounded:Icons.play_arrow_rounded,color:emerald)));
          }),
          const SizedBox(width:18),
          IconButton(onPressed:()=>_seek(const Duration(seconds:10)),icon:const Icon(Icons.forward_10_rounded,color:Colors.white,size:28)),
        ]),
        const SizedBox(height:11),
        Row(children:[
          Expanded(child:OutlinedButton.icon(onPressed:widget.onDua,icon:const Icon(Icons.menu_book_rounded,size:18),label:const Text('استمع للدعاء'),style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Colors.white38)))),
          const SizedBox(width:8),
          OutlinedButton(onPressed:() async { final double v = _speed == 1 ? 1.25 : (_speed == 1.25 ? 0.75 : 1.0); setState(()=>_speed=v); await _player.setSpeed(v); },style:OutlinedButton.styleFrom(foregroundColor:gold,side:const BorderSide(color:Color(0x88E5BE69))),child:Text('${_speed}×')),
          const SizedBox(width:8),
          IconButton(tooltip:'تشغيل الخطوات السبع',onPressed:(){ _playlist=true; _load(_selected,autoplay:true); },icon:const Icon(Icons.playlist_play_rounded,color:gold)),
        ]),
        if (_error!=null) Padding(padding:const EdgeInsets.only(top:10),child:Text(_error!,style:const TextStyle(color:Color(0xFFFFD2C4),fontSize:12))),
        const SizedBox(height:6),
        const Text('التسجيل الكامل يعمل دون إنترنت بعد إضافته للمشروع. بدون الملف، تُشغّل معاينة قصيرة بالإنترنت.',style:TextStyle(color:Colors.white60,fontSize:10,height:1.5)),
      ]),
    );
  }
}
