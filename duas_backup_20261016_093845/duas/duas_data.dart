// محتوى الأدعية الموثّقة - Rifqa
//
// قواعد المحتوى:
// 1) لا نسب لأي نص للنبي ﷺ إلا إذا كان مصدره معروفًا. المراجع بالكتاب/الباب، ولم تُكتب أرقام الأحاديث
//    حتى تُراجَع وتُضاف بعد المراجعة الشرعية.
// 2) needsReview = true: النص أو الدرجة أو صيغة النسبة تحتاج مراجعة عالم قبل الإطلاق.
// 3) الدعاء العام الجائز (generalPermissible) منفصل بوضوح ولا يُنسب للنبي ﷺ.
// 4) لا يوجد هنا أي محتوى مُولَّد بالـAI.
// 5) لا نخصص دعاءً لشوط معيّن في الطواف أو السعي، فلم يثبت دليل بذلك.

import '../../models/dua_model.dart';

abstract final class DuasData {
  static const String _bukhari = 'صحيح البخاري';
  static const String _muslim = 'صحيح مسلم';

  static const List<Dua> all = [
    // ───────────── الإحرام والتلبية ─────────────
    Dua(
      id: 'talbiyah',
      title: 'التلبية',
      arabicText:
          'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
      category: DuaCategory.umrah,
      stages: [RitualStage.ihram],
      sourceType: DuaSourceType.hadith,
      reference:
          'متفق عليه: صحيح البخاري وصحيح مسلم، كتاب الحج (حديث ابن عمر رضي الله عنهما)',
      grade: 'متفق عليه',
      transliteration:
          'Labbayk Allahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-nimata laka wal-mulk, la sharika lak.',
      translations: {
        'en':
            'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Verily all praise, grace and sovereignty belong to You. You have no partner.'
      },
      note:
          'يُكثر منها المحرم من الإحرام. للمعتمر حتى يبدأ الطواف، وللحاج حتى رمي جمرة العقبة يوم النحر.',
    ),
    Dua(
      id: 'umrah_niyyah',
      title: 'التلبية بنية العمرة',
      arabicText: 'لَبَّيْكَ عُمْرَةً',
      category: DuaCategory.umrah,
      stages: [RitualStage.ihram],
      sourceType: DuaSourceType.mathur,
      reference:
          'ثبت في الصحيح التلبية بالنسك المعيّن (مثل حديث أنس في صحيح مسلم: «لبيك عمرةً وحجًّا»)، وصيغة «لبيك عمرةً» لمن أحرم بالعمرة وحدها ذكرها أهل العلم.',
      needsReview: true,
      transliteration: 'Labbayk Umrah.',
      translations: {'en': 'Here I am for Umrah.'},
      note: 'الأصل أن النية محلّها القلب، ولا يلزم النطق بها.',
    ),
    Dua(
      id: 'hajj_niyyah',
      title: 'التلبية بنية الحج',
      arabicText: 'لَبَّيْكَ حَجًّا',
      category: DuaCategory.hajj,
      stages: [RitualStage.ihram],
      sourceType: DuaSourceType.mathur,
      reference:
          'ثبت في الصحيح التلبية بالنسك المعيّن، وصيغة «لبيك حجًّا» لمن أحرم بالحج ذكرها أهل العلم.',
      needsReview: true,
      transliteration: 'Labbayk Hajjan.',
      translations: {'en': 'Here I am for Hajj.'},
      note: 'الأصل أن النية محلّها القلب، ولا يلزم النطق بها.',
    ),
    Dua(
      id: 'ishtirat',
      title: 'الاشتراط عند الإحرام',
      arabicText: 'اللَّهُمَّ مَحِلِّي حَيْثُ حَبَسْتَنِي',
      category: DuaCategory.general,
      stages: [RitualStage.ihram],
      sourceType: DuaSourceType.hadith,
      reference:
          'متفق عليه: صحيح البخاري وصحيح مسلم، كتاب الحج (حديث ضُباعة بنت الزبير رضي الله عنها)',
      grade: 'متفق عليه',
      transliteration: 'Allahumma mahilli haythu habastani.',
      translations: {
        'en': 'O Allah, my place of release is wherever You hold me back.'
      },
      note: 'لمن يخشى مانعًا يمنعه من إتمام النسك، كمرض أو عائق.',
    ),

    // ───────────── السفر ─────────────
    Dua(
      id: 'travel_full',
      title: 'دعاء السفر',
      arabicText:
          'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
      category: DuaCategory.travel,
      stages: [RitualStage.preTravel],
      sourceType: DuaSourceType.hadith,
      reference:
          '$_muslim، كتاب الحج، باب ما يقول إذا ركب إلى سفر الحج وغيره (حديث ابن عمر رضي الله عنهما). وفيه آية الزخرف ١٣-١٤',
      grade: 'في صحيح مسلم',
      transliteration:
          'Allahu akbar, Allahu akbar, Allahu akbar. Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila rabbina lamunqalibun. Allahumma inna nasaluka fi safarina hadha al-birra wat-taqwa, wa minal-amali ma tarda. Allahumma hawwin alayna safarana hadha watwi anna buda. Allahumma antas-sahibu fis-safar, wal-khalifatu fil-ahl. Allahumma inni audhu bika min waathais-safar, wa kaabatil-manzar, wa suil-munqalabi fil-mali wal-ahl.',
      translations: {
        'en':
            'Allah is the Greatest (x3). Glory to Him who has subjected this to us, and we could not have done it ourselves, and to our Lord we will return. O Allah, we ask You on this journey for righteousness, piety and deeds that please You. O Allah, make this journey easy for us and shorten its distance. O Allah, You are the Companion on the journey and the Guardian of the family. O Allah, I seek refuge in You from the hardship of travel, from a sorrowful sight, and from an evil return in wealth and family.'
      },
      note:
          'عند العودة يُزاد: «آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ» (في الحديث نفسه).',
    ),
    Dua(
      id: 'travel_return',
      title: 'الزيادة عند العودة من السفر',
      arabicText: 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
      category: DuaCategory.travel,
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب الحج (في حديث ابن عمر نفسه)',
      grade: 'في صحيح مسلم',
      transliteration: 'Ayibuna, taibuna, abiduna, li-rabbina hamidun.',
      translations: {
        'en': 'We return, repenting, worshipping, and praising our Lord.'
      },
    ),
    Dua(
      id: 'travel_stop_place',
      title: 'عند النزول في مكان',
      arabicText:
          'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      category: DuaCategory.travel,
      sourceType: DuaSourceType.hadith,
      reference:
          '$_muslim، كتاب الذكر والدعاء (حديث خولة بنت حكيم رضي الله عنها)',
      grade: 'في صحيح مسلم',
      transliteration: 'Audhu bikalimatillahit-tammati min sharri ma khalaq.',
      translations: {
        'en':
            'I seek refuge in the perfect words of Allah from the evil of what He has created.'
      },
      note: 'من نزل منزلًا فقاله لم يضرّه شيء حتى يرتحل منه.',
    ),
    Dua(
      id: 'travel_arrival_quran',
      title: 'دعاء النزول والوصول',
      arabicText:
          'رَبِّ أَنزِلْنِي مُنزَلًا مُبَارَكًا وَأَنتَ خَيْرُ الْمُنزِلِينَ',
      category: DuaCategory.travel,
      sourceType: DuaSourceType.quran,
      reference: 'سورة المؤمنون، الآية ٢٩',
      transliteration:
          'Rabbi anzilni munzalan mubarakan wa anta khayrul-munzilin.',
      translations: {
        'en':
            'My Lord, let me land at a blessed landing place, and You are the best of those who bring to land.'
      },
      note: 'دعاء نوح عليه السلام، ويُدعى به عند النزول في مكان جديد.',
    ),

    // ───────────── المسجد ─────────────
    Dua(
      id: 'mosque_enter',
      title: 'دخول المسجد (ومنه المسجد الحرام)',
      arabicText: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      category: DuaCategory.mosque,
      stages: [RitualStage.enteringHaram],
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب صلاة المسافرين، باب ما يقول إذا دخل المسجد',
      grade: 'في صحيح مسلم',
      transliteration: 'Allahummaf-tah li abwaba rahmatik.',
      translations: {'en': 'O Allah, open for me the doors of Your mercy.'},
    ),
    Dua(
      id: 'mosque_exit',
      title: 'الخروج من المسجد',
      arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      category: DuaCategory.mosque,
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب صلاة المسافرين، باب ما يقول إذا دخل المسجد',
      grade: 'في صحيح مسلم',
      transliteration: 'Allahumma inni asaluka min fadlik.',
      translations: {'en': 'O Allah, I ask You for Your bounty.'},
    ),

    // ───────────── الطواف ─────────────
    Dua(
      id: 'tawaf_blackstone',
      title: 'التكبير عند الحجر الأسود',
      arabicText: 'اللهُ أَكْبَرُ',
      category: DuaCategory.tawaf,
      stages: [RitualStage.tawaf],
      sourceType: DuaSourceType.hadith,
      reference: '$_bukhari، كتاب الحج، باب التكبير عند الركن',
      grade: 'في صحيح البخاري',
      transliteration: 'Allahu akbar.',
      translations: {'en': 'Allah is the Greatest.'},
      note: 'كلما حاذى الحجر الأسود كبّر، إن لم يتيسر استلامه أشار إليه.',
    ),
    Dua(
      id: 'tawaf_rabbana_atina',
      title: 'ربنا آتنا في الدنيا حسنة',
      arabicText:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      category: DuaCategory.tawaf,
      stages: [RitualStage.tawaf, RitualStage.sai, RitualStage.arafah],
      sourceType: DuaSourceType.quran,
      reference:
          'سورة البقرة، الآية ٢٠١. وثبت في الصحيحين أنه كان أكثر دعاء النبي ﷺ. وورد قوله بين الركنين في سنن أبي داود.',
      needsReview: true,
      transliteration:
          'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina adhaban-nar.',
      translations: {
        'en':
            'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.'
      },
      note:
          'بين الركن اليماني والحجر الأسود. أما سائر الطواف فلم يرد دعاء مخصوص لشوط معيّن، فيدعو بما شاء.',
    ),
    Dua(
      id: 'tawaf_maqam',
      title: 'عند مقام إبراهيم بعد الطواف',
      arabicText: 'وَاتَّخِذُوا مِنْ مَقَامِ إِبْرَاهِيمَ مُصَلًّى',
      category: DuaCategory.tawaf,
      stages: [RitualStage.afterTawaf],
      sourceType: DuaSourceType.quran,
      reference:
          'سورة البقرة، الآية ١٢٥. وقراءتها عند الاقتراب من المقام في حديث جابر في صحيح مسلم',
      transliteration: 'Wattakhidhu min maqami Ibrahima musalla.',
      translations: {
        'en': 'And take the standing place of Abraham as a place of prayer.'
      },
      note:
          'ثم يصلي ركعتين، ويُسنّ فيهما قراءة «قل يا أيها الكافرون» و«قل هو الله أحد».',
    ),
    Dua(
      id: 'tawaf_general',
      title: 'دعاء عام جائز في الطواف',
      arabicText:
          'اللَّهُمَّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُسْلِمِينَ، وَارْزُقْنَا قَبُولَ الْعَمَلِ وَحُسْنَ الْخِتَامِ',
      category: DuaCategory.tawaf,
      stages: [RitualStage.tawaf, RitualStage.sai],
      sourceType: DuaSourceType.generalPermissible,
      reference: 'صيغة عامة جائزة، ليست نصًا مأثورًا عن النبي ﷺ.',
      transliteration:
          'Allahummaghfir li wa liwalidayya wa lil-muslimin, warzuqna qabulal-amali wa husnal-khatimah.',
      translations: {
        'en':
            'O Allah, forgive me, my parents and the Muslims, and grant us acceptance of deeds and a good ending.'
      },
      note: 'يجوز الدعاء في الطواف بأي لغة وبما شاء من خير.',
    ),

    // ───────────── السعي ─────────────
    Dua(
      id: 'sai_safa_approach',
      title: 'عند الاقتراب من الصفا',
      arabicText:
          'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ، أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ',
      category: DuaCategory.sai,
      stages: [RitualStage.sai],
      sourceType: DuaSourceType.hadith,
      reference:
          '$_muslim، كتاب الحج (حديث جابر رضي الله عنه). والآية في سورة البقرة ١٥٨',
      grade: 'في صحيح مسلم',
      transliteration:
          'Innas-Safa wal-Marwata min shaa-irillah, abdau bima bada-allahu bih.',
      translations: {
        'en':
            'Indeed, Safa and Marwa are among the symbols of Allah. I begin with what Allah began with.'
      },
      note: 'تُقال مرة واحدة عند أول اقترابه من الصفا في بداية السعي.',
    ),
    Dua(
      id: 'sai_safa_marwa_dhikr',
      title: 'الذكر على الصفا والمروة',
      arabicText:
          'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
      category: DuaCategory.sai,
      stages: [RitualStage.sai],
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب الحج (حديث جابر رضي الله عنه)',
      grade: 'في صحيح مسلم',
      repeatCount: 3,
      transliteration:
          'Allahu akbar (x3), la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa ala kulli shayin qadir, la ilaha illallahu wahdah, anjaza wadah, wa nasara abdah, wa hazamal-ahzaba wahdah.',
      translations: {
        'en':
            'Allah is the Greatest (x3). There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He is capable of all things. There is no god but Allah alone; He fulfilled His promise, aided His servant, and defeated the confederates alone.'
      },
      note:
          'يقولها ثلاث مرات ويدعو بين ذلك بما شاء، ويفعل مثل ذلك على المروة. وفي سائر السعي لم يرد دعاء مخصوص لشوط معيّن.',
    ),
    Dua(
      id: 'sai_rabbighfir',
      title: 'رب اغفر وارحم',
      arabicText: 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
      category: DuaCategory.sai,
      stages: [RitualStage.sai, RitualStage.tawaf],
      sourceType: DuaSourceType.quran,
      reference: 'سورة المؤمنون، الآية ١١٨',
      transliteration: 'Rabbighfir warham wa anta khayrur-rahimin.',
      translations: {
        'en':
            'My Lord, forgive and have mercy, for You are the best of the merciful.'
      },
      note: 'دعاء قرآني جامع. لا يُخصَّص به شوط معيّن.',
    ),

    // ───────────── عرفة ─────────────
    Dua(
      id: 'arafah_best_dua',
      title: 'خير الدعاء دعاء يوم عرفة',
      arabicText:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      category: DuaCategory.arafah,
      stages: [RitualStage.arafah],
      sourceType: DuaSourceType.hadith,
      reference:
          'سنن الترمذي، كتاب الدعوات (حديث عمرو بن شعيب عن أبيه عن جده). ويُراجَع في درجته.',
      needsReview: true,
      transliteration:
          'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa ala kulli shayin qadir.',
      translations: {
        'en':
            'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He is capable of all things.'
      },
      note:
          'يُكثر منها الحاج في عرفة ويدعو بما شاء مستقبلًا القبلة رافعًا يديه.',
    ),
    Dua(
      id: 'arafah_sayyid_istighfar',
      title: 'سيد الاستغفار',
      arabicText:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      category: DuaCategory.general,
      stages: [RitualStage.arafah],
      sourceType: DuaSourceType.hadith,
      reference:
          '$_bukhari، كتاب الدعوات، باب أفضل الاستغفار (حديث شداد بن أوس رضي الله عنه)',
      grade: 'في صحيح البخاري',
      transliteration:
          'Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana abduk, wa ana ala ahdika wa wadika mastatat, audhu bika min sharri ma sanat, abuu laka binimatika alayya, wa abuu bidhanbi faghfir li, fa-innahu la yaghfirudh-dhunuba illa ant.',
      translations: {
        'en':
            'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.'
      },
    ),

    // ───────────── مزدلفة والجمرات ─────────────
    Dua(
      id: 'muzdalifah_dhikr',
      title: 'ذكر الله عند المشعر الحرام',
      arabicText:
          'فَإِذَا أَفَضْتُمْ مِنْ عَرَفَاتٍ فَاذْكُرُوا اللَّهَ عِنْدَ الْمَشْعَرِ الْحَرَامِ وَاذْكُرُوهُ كَمَا هَدَاكُمْ',
      category: DuaCategory.hajj,
      stages: [RitualStage.muzdalifah],
      sourceType: DuaSourceType.quran,
      reference:
          'سورة البقرة، الآية ١٩٨. وفعله ﷺ في مزدلفة في حديث جابر في صحيح مسلم',
      transliteration:
          'Fa-idha afadtum min Arafatin fadhkurullaha indal-Masharil-Haram, wadhkuruhu kama hadakum.',
      translations: {
        'en':
            'When you depart from Arafat, remember Allah at the sacred landmark, and remember Him as He has guided you.'
      },
      note: 'وثبت أنه ﷺ استقبل القبلة ودعا وكبّر وهلّل حتى أسفر جدًّا.',
    ),
    Dua(
      id: 'jamarat_takbir',
      title: 'التكبير مع كل حصاة',
      arabicText: 'اللهُ أَكْبَرُ',
      category: DuaCategory.hajj,
      stages: [RitualStage.jamarat],
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب الحج (حديث جابر رضي الله عنه)',
      grade: 'في صحيح مسلم',
      repeatCount: 7,
      transliteration: 'Allahu akbar.',
      translations: {'en': 'Allah is the Greatest.'},
      note: 'يكبّر مع كل حصاة من السبع. ولم يثبت دعاء مخصوص آخر عند الرمي.',
    ),

    // ───────────── أدعية قرآنية ─────────────
    Dua(
      id: 'quran_7_23',
      title: 'دعاء آدم عليه السلام',
      arabicText:
          'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      category: DuaCategory.general,
      stages: [RitualStage.arafah],
      sourceType: DuaSourceType.quran,
      reference: 'سورة الأعراف، الآية ٢٣',
      transliteration:
          'Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakunanna minal-khasirin.',
      translations: {
        'en':
            'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.'
      },
    ),
    Dua(
      id: 'quran_2_127',
      title: 'دعاء إبراهيم وإسماعيل عند بناء البيت',
      arabicText:
          'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ',
      category: DuaCategory.umrah,
      stages: [RitualStage.tawaf, RitualStage.afterTawaf],
      sourceType: DuaSourceType.quran,
      reference: 'سورة البقرة، الآية ١٢٧',
      transliteration: 'Rabbana taqabbal minna innaka antas-Samiul-Alim.',
      translations: {
        'en':
            'Our Lord, accept this from us. You are the All-Hearing, the All-Knowing.'
      },
    ),
    Dua(
      id: 'quran_3_8',
      title: 'الثبات على الهداية',
      arabicText:
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
      category: DuaCategory.general,
      sourceType: DuaSourceType.quran,
      reference: 'سورة آل عمران، الآية ٨',
      transliteration:
          'Rabbana la tuzigh qulubana bada idh hadaytana wa hab lana min ladunka rahmah, innaka antal-Wahhab.',
      translations: {
        'en':
            'Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself. You are the Giver.'
      },
    ),
    Dua(
      id: 'quran_14_40',
      title: 'دعاء إبراهيم عليه السلام',
      arabicText:
          'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ، رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      category: DuaCategory.hajj,
      stages: [RitualStage.arafah],
      sourceType: DuaSourceType.quran,
      reference: 'سورة إبراهيم، الآيتان ٤٠-٤١',
      transliteration:
          'Rabbij-alni muqimas-salati wa min dhurriyyati, rabbana wa taqabbal duaa. Rabbanaghfir li wa liwalidayya wa lil-muminina yawma yaqumul-hisab.',
      translations: {
        'en':
            'My Lord, make me an establisher of prayer, and from my descendants. Our Lord, accept my supplication. Our Lord, forgive me, my parents and the believers on the Day the account is established.'
      },
    ),
    Dua(
      id: 'quran_2_286',
      title: 'عدم المؤاخذة بالنسيان والخطأ',
      arabicText: 'رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا',
      category: DuaCategory.general,
      sourceType: DuaSourceType.quran,
      reference: 'سورة البقرة، من الآية ٢٨٦',
      transliteration: 'Rabbana la tuakhidhna in nasina aw akhtana.',
      translations: {
        'en':
            'Our Lord, do not hold us accountable if we forget or make a mistake.'
      },
    ),
    Dua(
      id: 'quran_25_74',
      title: 'صلاح الأهل والذرية',
      arabicText:
          'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
      category: DuaCategory.general,
      sourceType: DuaSourceType.quran,
      reference: 'سورة الفرقان، الآية ٧٤',
      transliteration:
          'Rabbana hab lana min azwajina wa dhurriyyatina qurrata ayunin waj-alna lil-muttaqina imama.',
      translations: {
        'en':
            'Our Lord, grant us from our spouses and offspring comfort to our eyes, and make us leaders for the righteous.'
      },
    ),
    Dua(
      id: 'quran_59_10',
      title: 'الدعاء للمؤمنين',
      arabicText:
          'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ',
      category: DuaCategory.general,
      stages: [RitualStage.arafah],
      sourceType: DuaSourceType.quran,
      reference: 'سورة الحشر، الآية ١٠',
      transliteration:
          'Rabbanaghfir lana wa li-ikhwaninal-ladhina sabaqunabil-iman, wa la tajal fi qulubina ghillan lil-ladhina amanu, rabbana innaka raufur-rahim.',
      translations: {
        'en':
            'Our Lord, forgive us and our brothers who preceded us in faith, and do not put in our hearts any resentment toward those who believe. Our Lord, You are Kind and Merciful.'
      },
    ),

    // ───────────── أدعية صحيحة من السنة ─────────────
    Dua(
      id: 'sunnah_huda',
      title: 'الهدى والتقى والعفاف والغنى',
      arabicText:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب الذكر والدعاء (حديث ابن مسعود رضي الله عنه)',
      grade: 'في صحيح مسلم',
      transliteration:
          'Allahumma inni asalukal-huda wat-tuqa wal-afafa wal-ghina.',
      translations: {
        'en':
            'O Allah, I ask You for guidance, piety, chastity and self-sufficiency.'
      },
    ),
    Dua(
      id: 'sunnah_taqwa',
      title: 'اللهم آت نفسي تقواها',
      arabicText:
          'اللَّهُمَّ آتِ نَفْسِي تَقْوَاهَا، وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا، أَنْتَ وَلِيُّهَا وَمَوْلَاهَا',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب الذكر والدعاء (حديث زيد بن أرقم رضي الله عنه)',
      grade: 'في صحيح مسلم',
      transliteration:
          'Allahumma ati nafsi taqwaha, wa zakkiha anta khayru man zakkaha, anta waliyyuha wa mawlaha.',
      translations: {
        'en':
            'O Allah, grant my soul its piety and purify it, for You are the best to purify it; You are its Protector and Master.'
      },
    ),
    Dua(
      id: 'sunnah_musarrif',
      title: 'مصرّف القلوب',
      arabicText:
          'اللَّهُمَّ مُصَرِّفَ الْقُلُوبِ صَرِّفْ قُلُوبَنَا عَلَى طَاعَتِكَ',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference: '$_muslim، كتاب القدر (حديث عبد الله بن عمرو رضي الله عنهما)',
      grade: 'في صحيح مسلم',
      transliteration:
          'Allahumma musarrifal-qulubi sarrif qulubana ala taatik.',
      translations: {
        'en': 'O Allah, Turner of hearts, turn our hearts to Your obedience.'
      },
    ),
    Dua(
      id: 'sunnah_salawat',
      title: 'الصلاة الإبراهيمية',
      arabicText:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference:
          '$_bukhari، كتاب أحاديث الأنبياء (حديث كعب بن عجرة رضي الله عنه)',
      grade: 'في صحيح البخاري',
      transliteration:
          'Allahumma salli ala Muhammadin wa ala ali Muhammad, kama sallayta ala Ibrahima wa ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik ala Muhammadin wa ala ali Muhammad, kama barakta ala Ibrahima wa ala ali Ibrahim, innaka Hamidun Majid.',
      translations: {
        'en':
            'O Allah, send prayers upon Muhammad and the family of Muhammad as You sent prayers upon Abraham and the family of Abraham; You are Praiseworthy and Glorious. O Allah, bless Muhammad and the family of Muhammad as You blessed Abraham and the family of Abraham; You are Praiseworthy and Glorious.'
      },
    ),
    Dua(
      id: 'sunnah_subhanallah',
      title: 'كلمتان خفيفتان على اللسان',
      arabicText:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference:
          'متفق عليه: صحيح البخاري (آخر الكتاب) وصحيح مسلم، كتاب الذكر والدعاء (حديث أبي هريرة رضي الله عنه)',
      grade: 'متفق عليه',
      transliteration: 'Subhanallahi wa bihamdihi, subhanallahil-Azim.',
      translations: {
        'en':
            'Glory and praise be to Allah; Glory be to Allah, the Magnificent.'
      },
    ),
    Dua(
      id: 'sunnah_afw_afiyah',
      title: 'العفو والعافية',
      arabicText:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
      category: DuaCategory.general,
      sourceType: DuaSourceType.hadith,
      reference:
          'سنن أبي داود وسنن ابن ماجه (كتاب الأدب / الدعاء). وتُراجَع درجته.',
      needsReview: true,
      transliteration:
          'Allahumma inni asalukal-afwa wal-afiyata fid-dunya wal-akhirah.',
      translations: {
        'en':
            'O Allah, I ask You for pardon and well-being in this world and the Hereafter.'
      },
    ),

    // ───────────── دعاء عام جائز (غير مأثور) ─────────────
    Dua(
      id: 'general_umrah_acceptance',
      title: 'طلب قبول العمرة',
      arabicText:
          'اللَّهُمَّ تَقَبَّلْ مِنِّي عُمْرَتِي، وَاغْفِرْ لِي، وَارْزُقْنِي الْعَوْدَةَ إِلَى بَيْتِكَ',
      category: DuaCategory.umrah,
      sourceType: DuaSourceType.generalPermissible,
      reference: 'صيغة عامة جائزة، ليست نصًا مأثورًا عن النبي ﷺ.',
      transliteration:
          'Allahumma taqabbal minni umrati, waghfir li, warzuqnil-awdata ila baytik.',
      translations: {
        'en':
            'O Allah, accept my Umrah from me, forgive me, and grant me the return to Your House.'
      },
    ),
  ];
}
