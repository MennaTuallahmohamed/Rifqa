import 'package:flutter/material.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../../../services/madinah/salawat_repository.dart';
import '../salawat/salawat_library_screen.dart';

class SalawatScreen extends StatelessWidget {
  const SalawatScreen({
    super.key,
    required this.repository,
    required this.salawatRepository,
  });
  final MadinahRepository repository;
  final SalawatRepository salawatRepository;

  @override
  Widget build(BuildContext context) => SalawatLibraryScreen(
        repository: repository,
        salawatRepository: salawatRepository,
      );
}
