import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/trainers/trainer_detail_page.dart';
import 'package:dab_fitness/services/location_service.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

class TrainerListPage extends StatefulWidget {
  static const routeName = '/trainerpage';
  const TrainerListPage({super.key});

  @override
  State<TrainerListPage> createState() => _TrainerListPageState();
}

class _TrainerListPageState extends State<TrainerListPage> {
  final _pageController = PageController(viewportFraction: 0.85);
  int _index = 0;
  String? _bookingFor; // trainerId currently being booked

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final database = context.read<DatabaseModel>();
    final messenger = ScaffoldMessenger.of(context);
    await database.loadTrainers();
    if (database.trainersError != null) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't refresh. Showing the last loaded trainers."),
      ));
    }
  }

  Future<void> _book(Trainer trainer) async {
    final slot = await showDialog<BookingSlot>(
      context: context,
      builder: (_) => const BookingDialog(),
    );
    if (slot == null || !mounted) return;

    setState(() => _bookingFor = trainer.trainerId);
    final booking = context.read<BookingModel>();
    final userName = context.read<DatabaseModel>().user?.name ?? '';
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
    } on BookingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
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
    final database = context.watch<DatabaseModel>();
    final trainers = database.getTrainersData;

    if (trainers.isEmpty) {
      // Loading, error or empty: a pull-to-refreshable message.
      return Scaffold(
        appBar: AppBar(title: const Text('Trainers')),
        body: RefreshableList<Trainer>(
          items: const [],
          isLoading: database.trainersLoading,
          error: database.trainersError,
          onRefresh: database.loadTrainers,
          emptyMessage: "No trainers are available yet.\nPull to refresh.",
          emptyIcon: Icons.person_search,
          itemBuilder: (_, __) => const SizedBox.shrink(),
        ),
      );
    }
    final current = trainers[_index.clamp(0, trainers.length - 1)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // The carousel scrolls sideways, so refresh is a button here.
          IconButton(
            tooltip: 'Refresh trainers',
            icon: database.trainersLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: database.trainersLoading ? null : _refresh,
          ),
        ],
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
            child: LayoutBuilder(
              // Up to 440 tall, but always leave room for the app bar.
              builder: (context, constraints) => Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: (constraints.maxHeight - kToolbarHeight)
                      .clamp(0.0, 440.0),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: trainers.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _trainerCard(trainers[i]),
                  ),
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
              Text(trainer.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bold20),
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
              const SizedBox(height: 10),
              // Age and rating share one row; the stars shrink on narrow
              // screens instead of overflowing.
              Row(
                children: [
                  Text("Age: ${trainer.age}", style: bold20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        children: [
                          for (int i = 0; i < 5; i++)
                            Icon(
                                i < trainer.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
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
