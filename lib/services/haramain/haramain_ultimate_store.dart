import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/haramain/haramain_ultimate_models.dart';

class HaramainUltimateStore extends ChangeNotifier {
  static const _key='rifqa_haramain_ultimate_v1';
  bool largeText=false, voice=true, highContrast=false, wheelchair=false;
  String name='', hotel='', leader='', medical='';
  int tawaf=0, sai=0; final List<HPin> pins=[];
  Future<void> load() async { final p=await SharedPreferences.getInstance(); final raw=p.getString(_key); if(raw==null)return; try{final j=jsonDecode(raw);largeText=j['largeText']??false;voice=j['voice']??true;highContrast=j['highContrast']??false;wheelchair=j['wheelchair']??false;name=j['name']??'';hotel=j['hotel']??'';leader=j['leader']??'';medical=j['medical']??'';tawaf=j['tawaf']??0;sai=j['sai']??0;pins..clear()..addAll(((j['pins']??[]) as List).map((e)=>HPin.fromJson(Map<String,dynamic>.from(e))));}catch(_){ } notifyListeners(); }
  Future<void> save() async { final p=await SharedPreferences.getInstance(); await p.setString(_key,jsonEncode({'largeText':largeText,'voice':voice,'highContrast':highContrast,'wheelchair':wheelchair,'name':name,'hotel':hotel,'leader':leader,'medical':medical,'tawaf':tawaf,'sai':sai,'pins':pins.map((e)=>e.toJson()).toList()})); notifyListeners(); }
  void addPin(HPin x){pins.removeWhere((p)=>p.site==x.site&&p.kind==x.kind&&x.kind==PinKind.myGate);pins.add(x);save();}
}
