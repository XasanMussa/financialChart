import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  const DateSelector({super.key});

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  DateTime selectedDate = DateTime.now();
  int weekOffset = 0;

  List<DateTime> generateWeekDates(int weekOffset) {
    final today = DateTime.now();
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    startOfWeek = startOfWeek.add(Duration(days: weekOffset * 7));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  void updateWeekOffset(DateTime newSelectedDate) {
    DateTime startOfSelectedWeek =
        newSelectedDate.subtract(Duration(days: newSelectedDate.weekday - 1));
    DateTime startOfCurrentWeek =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    int newOffset =
        startOfSelectedWeek.difference(startOfCurrentWeek).inDays ~/ 7;

    setState(() {
      weekOffset = newOffset; // Fix week offset calculation
      selectedDate = newSelectedDate;
      String searchingDate = DateFormat('yy-MM-dd').format(selectedDate);

      // print("selectedDate = $searchingDate");
      print("new selectedDate = $searchingDate");
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDates = generateWeekDates(weekOffset);
    String monthName = DateFormat('MMMM').format(weekDates.first);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(
            bottom: 10.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    weekOffset--;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    updateWeekOffset(date);
                  }
                },
              ),
              Text(
                monthName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    weekOffset++;
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                DateTime date = weekDates[index];
                bool isSelected = selectedDate.day == date.day &&
                    selectedDate.month == date.month &&
                    selectedDate.year == date.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                    String searchingDate =
                        DateFormat('yy-MM-dd').format(selectedDate);

                    print("selectedDate = $searchingDate");
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepOrangeAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrangeAccent
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(221, 255, 255, 255),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color.fromARGB(221, 255, 255, 255),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
