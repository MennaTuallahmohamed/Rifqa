import 'package:flutter/material.dart';

import '../../../models/madinah/rawdah_appointment.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class RawdahAppointmentScreen extends StatefulWidget {
  const RawdahAppointmentScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<RawdahAppointmentScreen> createState() =>
      _RawdahAppointmentScreenState();
}

class _RawdahAppointmentScreenState extends State<RawdahAppointmentScreen> {
  late DateTime date;
  late TimeOfDay time;
  late bool permit;

  @override
  void initState() {
    super.initState();
    final old = widget.repository.rawdahAppointment;
    final dt = old?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    date = dt;
    time = TimeOfDay.fromDateTime(dt);
    permit = old?.hasOfficialPermit ?? false;
  }

  Future<void> save() async {
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await widget.repository.saveRawdahAppointment(
      RawdahAppointment(
        dateTime: dt,
        hasOfficialPermit: permit,
        preparationCompleted: false,
        sidqPauseCompleted: false,
        prayerBagPrepared: false,
        prayerTrustsReviewed: false,
        waitingStarted: false,
        quietModeStarted: false,
        visitCompleted: false,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'موعد الروضة',
        emoji: '🗓️',
        subtitle:
            'رِفقة يحفظ الموعد للتنظيم فقط. التصريح الرسمي يتم من الجهة الرسمية ولا يصدره رِفقة.',
        children: [
          SwitchListTile(
            value: permit,
            activeThumbColor: emerald,
            onChanged: (v) => setState(() => permit = v),
            title: const Text('لدي تصريح رسمي بالفعل'),
            subtitle: const Text('فعّلي هذا بعد حصولك على التصريح الرسمي.'),
          ),
          if (!permit)
            const MSourceBox(
              source: 'التصريح الرسمي مطلوب من المنصة/التطبيق الرسمي المعتمد',
              note:
                  'رِفقة لا ينشئ QR ولا يقلّد تصريحًا رسميًا. احصلي على التصريح أولًا ثم احفظي موعده هنا.',
            ),
          MCard(
            title: 'التاريخ',
            subtitle: '${date.day}/${date.month}/${date.year}',
            emoji: '📅',
            onTap: () async {
              final x = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (x != null) setState(() => date = x);
            },
          ),
          MCard(
            title: 'الوقت',
            subtitle: time.format(context),
            emoji: '⏰',
            onTap: () async {
              final x =
                  await showTimePicker(context: context, initialTime: time);
              if (x != null) setState(() => time = x);
            },
          ),
          FilledButton(
            onPressed: permit ? save : null,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('حفظ الموعد'),
          ),
        ],
      );
}
