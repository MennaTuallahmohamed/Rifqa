import 'package:maplibre_gl/maplibre_gl.dart';
enum HaramainSite { makkah, madinah }
enum HaramainPoiType { gate, toilet, water, accessibility, medical, landmark, women, wudu }
class HaramainPoi {
 const HaramainPoi({required this.id,required this.site,required this.nameAr,required this.subtitleAr,required this.type,required this.position,this.verified=false});
 final String id; final HaramainSite site; final String nameAr; final String subtitleAr; final HaramainPoiType type; final LatLng position; final bool verified;
}
extension HaramainSiteUi on HaramainSite {
 String get title=>this==HaramainSite.makkah?'\u{627}\u{644}\u{645}\u{633}\u{62c}\u{62f} \u{627}\u{644}\u{62d}\u{631}\u{627}\u{645}':'\u{627}\u{644}\u{645}\u{633}\u{62c}\u{62f} \u{627}\u{644}\u{646}\u{628}\u{648}\u{64a}';
 String get city=>this==HaramainSite.makkah?'\u{645}\u{643}\u{629} \u{627}\u{644}\u{645}\u{643}\u{631}\u{645}\u{629}':'\u{627}\u{644}\u{645}\u{62f}\u{64a}\u{646}\u{629} \u{627}\u{644}\u{645}\u{646}\u{648}\u{631}\u{629}';
 String get emoji=>String.fromCharCode(this==HaramainSite.makkah?0x1f54b:0x1f54c);
 LatLng get center=>this==HaramainSite.makkah?const LatLng(21.42249,39.82618):const LatLng(24.46720,39.61114);
 double get initialZoom=>this==HaramainSite.makkah?16.8:16.5;
}
extension HaramainPoiTypeUi on HaramainPoiType {
 String get label=>switch(this){HaramainPoiType.gate=>'\u{627}\u{644}\u{623}\u{628}\u{648}\u{627}\u{628}',HaramainPoiType.toilet=>'\u{62f}\u{648}\u{631}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{64a}\u{627}\u{647}',HaramainPoiType.water=>'\u{645}\u{64a}\u{627}\u{647} \u{632}\u{645}\u{632}\u{645}',HaramainPoiType.accessibility=>'\u{633}\u{647}\u{648}\u{644}\u{629} \u{627}\u{644}\u{648}\u{635}\u{648}\u{644}',HaramainPoiType.medical=>'\u{62e}\u{62f}\u{645}\u{627}\u{62a} \u{637}\u{628}\u{64a}\u{629}',HaramainPoiType.landmark=>'\u{645}\u{639}\u{627}\u{644}\u{645}',HaramainPoiType.women=>'\u{62e}\u{62f}\u{645}\u{627}\u{62a} \u{627}\u{644}\u{646}\u{633}\u{627}\u{621}',HaramainPoiType.wudu=>'\u{645}\u{648}\u{627}\u{636}\u{639} \u{627}\u{644}\u{648}\u{636}\u{648}\u{621}'};
 String get emoji=>switch(this){HaramainPoiType.gate=>String.fromCharCode(0x1f6aa),HaramainPoiType.toilet=>String.fromCharCode(0x1f6bb),HaramainPoiType.water=>String.fromCharCode(0x1f4a7),HaramainPoiType.accessibility=>String.fromCharCode(0x267f),HaramainPoiType.medical=>String.fromCharCode(0x1fa7a),HaramainPoiType.landmark=>String.fromCharCode(0x1f4cd),HaramainPoiType.women=>String.fromCharCode(0x1f46d),HaramainPoiType.wudu=>String.fromCharCode(0x1f6b0)};
}
