import 'package:flutter/material.dart';
import '../../models/haramain/haramain_ultimate_models.dart';

/// DEMO/UX coordinates only. Replace with reviewed Haramain indoor data before production navigation.
const haramainDemoPois = <HPoi>[
  HPoi(id:'mk_kaaba',name:'الكعبة المشرفة',site:HaramSite.makkah,kind:PoiKind.ritual,p:Offset(.50,.48),trust:DataTrust.approximate),
  HPoi(id:'mk_safa',name:'الصفا',site:HaramSite.makkah,kind:PoiKind.ritual,p:Offset(.70,.42),trust:DataTrust.approximate),
  HPoi(id:'mk_marwa',name:'المروة',site:HaramSite.makkah,kind:PoiKind.ritual,p:Offset(.83,.28),trust:DataTrust.approximate),
  HPoi(id:'mk_gate_demo',name:'بوابة تجريبية',site:HaramSite.makkah,kind:PoiKind.gate,p:Offset(.18,.72),trust:DataTrust.approximate),
  HPoi(id:'mk_water',name:'نقطة مياه تجريبية',site:HaramSite.makkah,kind:PoiKind.water,p:Offset(.62,.63),trust:DataTrust.approximate),
  HPoi(id:'mk_wc',name:'دورات مياه تجريبية',site:HaramSite.makkah,kind:PoiKind.toilet,p:Offset(.12,.38),trust:DataTrust.approximate),
  HPoi(id:'mk_med',name:'إسعاف تجريبي',site:HaramSite.makkah,kind:PoiKind.medical,p:Offset(.80,.76),trust:DataTrust.approximate),
  HPoi(id:'md_rawdah',name:'الروضة الشريفة',site:HaramSite.madinah,kind:PoiKind.landmark,p:Offset(.48,.52),trust:DataTrust.approximate),
  HPoi(id:'md_dome',name:'القبة الخضراء',site:HaramSite.madinah,kind:PoiKind.landmark,p:Offset(.61,.48),trust:DataTrust.approximate),
  HPoi(id:'md_gate_demo',name:'بوابة تجريبية',site:HaramSite.madinah,kind:PoiKind.gate,p:Offset(.20,.72),trust:DataTrust.approximate),
  HPoi(id:'md_wc',name:'دورات مياه تجريبية',site:HaramSite.madinah,kind:PoiKind.toilet,p:Offset(.14,.34),trust:DataTrust.approximate),
  HPoi(id:'md_women',name:'مصلى نساء تجريبي',site:HaramSite.madinah,kind:PoiKind.women,p:Offset(.76,.30),trust:DataTrust.approximate),
  HPoi(id:'md_access',name:'خدمة ذوي الهمم',site:HaramSite.madinah,kind:PoiKind.accessibility,p:Offset(.78,.72),trust:DataTrust.approximate),
];
