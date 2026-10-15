import 'package:flutter/material.dart';

enum HaramSite { makkah, madinah }
enum PoiKind { gate, toilet, water, wudu, women, medical, info, accessibility, elevator, courtyard, ritual, meeting, landmark }
enum DataTrust { verified, approximate, personal }
enum PinKind { myGate, meeting, hotel, bus, custom }

extension HaramSiteX on HaramSite {
  String get title => this == HaramSite.makkah ? 'المسجد الحرام' : 'المسجد النبوي';
  String get city => this == HaramSite.makkah ? 'مكة المكرمة' : 'المدينة المنورة';
  String get emoji => this == HaramSite.makkah ? '🕋' : '🕌';
}
extension PoiKindX on PoiKind {
  String get label => const {
    PoiKind.gate:'الأبواب', PoiKind.toilet:'دورات المياه', PoiKind.water:'المياه / زمزم', PoiKind.wudu:'الوضوء',
    PoiKind.women:'مصليات النساء', PoiKind.medical:'الإسعاف', PoiKind.info:'الإرشاد', PoiKind.accessibility:'ذوي الهمم',
    PoiKind.elevator:'المصاعد', PoiKind.courtyard:'الساحات', PoiKind.ritual:'المناسك', PoiKind.meeting:'نقاط التجمع', PoiKind.landmark:'المعالم'
  }[this]!;
  String get emoji => const {
    PoiKind.gate:'🚪', PoiKind.toilet:'🚻', PoiKind.water:'🚰', PoiKind.wudu:'💧', PoiKind.women:'🧕', PoiKind.medical:'🚑',
    PoiKind.info:'ℹ️', PoiKind.accessibility:'♿', PoiKind.elevator:'🛗', PoiKind.courtyard:'☀️', PoiKind.ritual:'🕋', PoiKind.meeting:'👥', PoiKind.landmark:'📍'
  }[this]!;
}
class HPoi {
  final String id, name, subtitle; final HaramSite site; final PoiKind kind; final Offset p; final int floor;
  final bool accessible; final DataTrust trust;
  const HPoi({required this.id,required this.name,required this.site,required this.kind,required this.p,this.subtitle='',this.floor=0,this.accessible=true,this.trust=DataTrust.approximate});
}
class HPin {
  final String id,label; final HaramSite site; final PinKind kind; final Offset p; final DateTime createdAt;
  const HPin({required this.id,required this.label,required this.site,required this.kind,required this.p,required this.createdAt});
  Map<String,dynamic> toJson()=>{'id':id,'label':label,'site':site.name,'kind':kind.name,'x':p.dx,'y':p.dy,'createdAt':createdAt.toIso8601String()};
  factory HPin.fromJson(Map<String,dynamic> j)=>HPin(id:j['id']??'',label:j['label']??'',site:HaramSite.values.firstWhere((e)=>e.name==j['site'],orElse:()=>HaramSite.makkah),kind:PinKind.values.firstWhere((e)=>e.name==j['kind'],orElse:()=>PinKind.custom),p:Offset((j['x'] as num?)?.toDouble()??0,(j['y'] as num?)?.toDouble()??0),createdAt:DateTime.tryParse(j['createdAt']??'')??DateTime.now());
}
class HRoute { final Offset a,b; final double meters; final bool accessible; const HRoute(this.a,this.b,this.meters,{this.accessible=false}); int get minutes => (meters/60).ceil().clamp(1,999); }
