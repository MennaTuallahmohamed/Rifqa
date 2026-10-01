import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AppState extends ChangeNotifier {
 bool onboardingDone=false, loggedIn=false, dark=false; String name='', userType='معتمر', dest='mataf', gate='g1'; int step=0,tawaf=0,sai=0,jamarat=0; final Set<int> done={};
 int get progress => (((done.length + (tawaf>=7?1:0)+(sai>=7?1:0))/9)*100).round();
 Future<void> load() async { final p=await SharedPreferences.getInstance(); final raw=p.getString('state'); if(raw!=null){final j=jsonDecode(raw); onboardingDone=j['onb']??false;loggedIn=j['login']??false;name=j['name']??'';dark=j['dark']??false;step=j['step']??0;tawaf=j['tw']??0;sai=j['sa']??0;done.addAll(List<int>.from(j['done']??[]));} notifyListeners(); }
 Future<void> _save() async {final p=await SharedPreferences.getInstance();await p.setString('state',jsonEncode({'onb':onboardingDone,'login':loggedIn,'name':name,'dark':dark,'step':step,'tw':tawaf,'sa':sai,'done':done.toList()}));}
 void change(void Function() f){f();_save();notifyListeners();}
}
class AppScope extends InheritedNotifier<AppState>{const AppScope({super.key,required AppState state,required super.child}):super(notifier:state);static AppState of(BuildContext c)=>c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;}
