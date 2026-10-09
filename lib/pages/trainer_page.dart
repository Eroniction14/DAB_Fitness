import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/booking_model.dart';
import '../provider/database_model.dart';
import '../utils/location_helper.dart';
import './trainerDetail_page.dart';

class TrainerPage extends StatefulWidget {
  static const routeName = '/trainerpage';
  const TrainerPage({super.key});

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> {
  final _pageController = PageController(viewportFraction: 0.85);
  int _index = 0;
  String? _bookingFor; // trainerId currently being booked

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _book(Trainer trainer) async {
    final slot = await showDialog<BookingSlot>(
      context: context,
      builder: (_) => const BookingDialog(),
    );
    if (slot == null || !mounted) return;

    setState(() => _bookingFor = trainer.trainerId);
    final booking = context.read<Booking>();
    final userName = context.read<DataBase>().user?.name ?? '';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final city = await getCity();
      final ok = await booking.book(
        DateFormat('yyyy-MM-dd').format(slot.date),
        slot.time,
        city,
        trainer.trainerId,
        userName,
      );
      messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? 'Session booked with ${trainer.name}!'
            : 'Booking failed. Please try again.'),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      debugPrint('Booking failed: $e');
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not connect. Check your internet connection.'),
      ));
    } finally {
      if (mounted) setState(() => _bookingFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as List?;
    final trainers = args?.cast<Trainer>() ?? const <Trainer>[];

    if (trainers.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No trainers are available yet")),
      );
    }
    final current = trainers[_index.clamp(0, trainers.length - 1)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Full-screen photo of the current trainer, cross-fading on swipe.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              layoutBuilder: (currentChild, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (currentChild != null) currentChild],
              ),
              child: Image.asset(
                current.image,
                key: ValueKey(current.trainerId),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black87],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 440,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: trainers.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _trainerCard(trainers[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trainerCard(Trainer trainer) {
    final isBooking = _bookingFor == trainer.trainerId;
    const bold20 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(trainer.name, textAlign: TextAlign.center, style: bold20),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TrainerDetail(trainer)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(trainer.image, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text("Age: ${trainer.age}", style: bold20),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text("Rating: ", style: bold20),
                  for (int i = 0; i < 5; i++)
                    Icon(i < trainer.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber),
                ],
              ),
              const Divider(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isBooking ? null : () => _book(trainer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BC0C5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text("BOOK NOW",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}