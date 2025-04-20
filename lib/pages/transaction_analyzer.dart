import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance_tracker/authentication/signup_page.dart';
import 'package:personal_finance_tracker/model/transaction_card.dart';
import 'package:personal_finance_tracker/pages/dashboard_screen.dart';
import 'package:personal_finance_tracker/widgets/date_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as FirebaseFirestore;
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_finance_tracker/model/transaction_model.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final Telephony telephony = Telephony.instance;
  List<Transaction> transactions = [];
  List<Transaction> searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _permissionDenied = false;
  int _selectedIndex = 0; // Keeps track of which tab is selected
  String searchPhoneNumber = "";
  // Load transactions and upload them if not already uploaded
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS)
          .like("192")
          .or(SmsColumn.ADDRESS)
          .like("eDahab"),
    );

    final parsed = messages
        .map((msg) => Transaction.fromSms(msg.body ?? ''))
        .where((t) => t.amount > 0)
        .toList();

    setState(() {
      transactions = parsed;
      _isLoading = false;
    });
  }

  Future<void> _processTransactionsInBackground(
      List<Transaction> parsedTransactions) async {
    // Use Future.delayed to run this in the background and avoid blocking the UI
    Future(() async {
      for (var transaction in parsedTransactions) {
        bool exists =
            await _isTransactionUploadedLocally(transaction.transactionID);
        if (!exists) {
          await _uploadTransactionToFirebase(transaction);
        }
      }
    });
  }

  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        // Android-specific code
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Unique ID for Android devices
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        // iOS-specific code
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // Unique ID for iOS devices
      }
    } catch (e) {
      showSnackbar(context, "Error fetching device ID");
      // print("Error fetching device ID: $e");
    }

    return deviceId;
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
            const Duration(seconds: 2), // Duration for the Snackbar to stay
      ),
    );
  }

  // Check if transaction is already uploaded based on transactionID
  Future<bool> _isTransactionUploadedLocally(String transactionID) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(transactionID) ?? false; // If not found, return false
  }

  // Upload the transaction to Firebase and store its transactionID locally
  Future<void> _uploadTransactionToFirebase(Transaction transaction) async {
    String? deviceID = await getDeviceId();
    try {
      // Debug log for phone number being stored
      print(
          '📱 Storing transaction with phone number: ${transaction.phoneNumber}');

      //upload deviceid to firebase
      await FirebaseFirestore.FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({'deviceId': deviceID});

      // Upload the transaction to Firebase
      await FirebaseFirestore.FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('transactions')
          .doc(transaction.transactionID)
          .set({
        'sender': transaction.originalMessage,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': FirebaseFirestore.Timestamp.fromDate(transaction.date!),
        'isExpense': transaction.isExpense,
        'phone': transaction.phoneNumber?.replaceAll(' ', '') ?? 'Unknown',
        'transactionID': transaction.transactionID,
      });

      // Store the transactionID in local storage to mark it as uploaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(transaction.transactionID, true);

      print("✅ Transaction uploaded: ${transaction.transactionID}");
    } catch (e) {
      print("❌ Error uploading transaction: $e");
    }
  }

  final isLoggedIn = "false";
  Future<void> Logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUpPage()),
      );

      print("User successfully logged out.");
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  Future<List<Transaction>> getTransactions(String? userUid) async {
    try {
      final snapshot = await FirebaseFirestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('transactions')
          .orderBy('date', descending: true) // Order by date descending
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Transaction(
          isExpense: (data['isExpense'] as bool?) ?? false,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phone'] as String? ?? 'Unknown',
          date: (data['date'] as FirebaseFirestore.Timestamp?)?.toDate() ??
              DateTime.now(),
          originalMessage: data['sender'] as String? ?? 'No message',
          category: data['category'] as String? ?? 'Uncategorized',
          transactionID: data['transactionID'] as String? ?? 'Unknown_ID',
        );
      }).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByPhone(
      String? userUid, String phoneNumber) async {
    try {
      String normalizedNumber = phoneNumber.replaceAll(' ', '');
      if (normalizedNumber.length > 9) {
        normalizedNumber =
            normalizedNumber.substring(normalizedNumber.length - 9);
      }

      String withZero = "0$normalizedNumber";
      String withoutZero = normalizedNumber.startsWith('0')
          ? normalizedNumber.substring(1)
          : normalizedNumber;

      final snapshot = await FirebaseFirestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('transactions')
          .where('phone', whereIn: [withZero, withoutZero])
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Transaction(
          isExpense: (data['isExpense'] as bool?) ?? false,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phone'] as String? ?? 'Unknown',
          date: (data['date'] as FirebaseFirestore.Timestamp?)?.toDate() ??
              DateTime.now(),
          originalMessage: data['sender'] as String? ?? 'No message',
          category: data['category'] as String? ?? 'Uncategorized',
          transactionID: data['transactionID'] as String? ?? 'Unknown_ID',
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching transactions for phone number $phoneNumber: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByDate(
      String? userUid, String selectedDate) async {
    try {
      if (userUid == null) {
        print("User is not logged in.");
        return [];
      }

      // Convert selectedDate (yy-MM-dd) to a DateTime object
      DateTime dateTime = DateFormat('yy-MM-dd').parse(selectedDate);

      // Get the start and end of the day as Timestamp
      FirebaseFirestore.Timestamp startOfDay =
          FirebaseFirestore.Timestamp.fromDate(
              DateTime(dateTime.year, dateTime.month, dateTime.day, 0, 0, 0));
      FirebaseFirestore.Timestamp endOfDay =
          FirebaseFirestore.Timestamp.fromDate(DateTime(
              dateTime.year, dateTime.month, dateTime.day, 23, 59, 59));

      print(
          "🔍 Querying Firestore between: ${startOfDay.toDate()} and ${endOfDay.toDate()}");

      // Firestore query to get transactions within the selected date range
      final snapshot = await FirebaseFirestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .orderBy('date', descending: true) // Order by date descending
          .get();

      print(
          "📄 Transactions found for date $selectedDate: ${snapshot.docs.length}");

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Transaction(
          isExpense: (data['isExpense'] as bool?) ?? false,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phone'] as String? ?? 'Unknown',
          date: (data['date'] as FirebaseFirestore.Timestamp?)?.toDate() ??
              DateTime.now(),
          originalMessage: data['sender'] as String? ?? 'No message',
          category: data['category'] as String? ?? 'Uncategorized',
          transactionID: data['transactionID'] as String? ?? 'Unknown_ID',
        );
      }).toList();
    } catch (e) {
      print('❌ Error fetching transactions for date $selectedDate: $e');
      return [];
    }
  }

  Future<void> check() async {
    String? deviceId = "";
    String? currentdeviceId = await getDeviceId();
    FirebaseFirestore.DocumentSnapshot? documentSnapshot =
        await FirebaseFirestore.FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();
    if (documentSnapshot.exists) {
      deviceId = documentSnapshot.get('deviceId');
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackbar(context, "Document deviceId does not exist (new user)");
        _loadTransactions();
        _processTransactionsInBackground(transactions);
      });
    }

    if (deviceId == currentdeviceId) {
      showSnackbar(context, "this the same user you can load transactions");

      _loadTransactions();
      _processTransactionsInBackground(transactions);
    } else {
      showSnackbar(context, "this is a different device you can only read it");
      await readFromFirebase();
    }
  }

  Future<void> readFromFirebase() async {
    transactions =
        await getTransactions(FirebaseAuth.instance.currentUser?.uid);
    setState(() {}); // Update UI after fetching data
  }

  @override
  void initState() {
    super.initState();
    check();

    // getDeviceId();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildTransactionView(),
      DashboardScreen(transactions: transactions),
      // Any other screen such as Dashboard
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF0A0E21),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionView() {
    String? selectedDateForSearch;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: check,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: Logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF0A0E21).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildSearchBar(onSubmit: (phonenumber) async {
                    transactions = await getTransactionsByPhone(
                        FirebaseAuth.instance.currentUser?.uid, phonenumber);
                  }),
                  const SizedBox(height: 16),
                  DateSelector(
                    onDateSelected: (date) async {
                      if (date == null) {
                        await readFromFirebase();
                      } else {
                        transactions = await getTransactionsByDate(
                            FirebaseAuth.instance.currentUser?.uid, date);
                      }
                      setState(() {
                        selectedDateForSearch = date;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  void showSearchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget buildSearchBar({required Function(String) onSubmit}) {
    final TextEditingController controller = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        enabled: !_isSearching,
        decoration: InputDecoration(
          hintText: "Search by phone number...",
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: _isSearching
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                )
              : Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[500]),
            onPressed: _isSearching
                ? null
                : () {
                    controller.clear();
                    setState(() {
                      searchResults.clear();
                    });
                    readFromFirebase();
                  },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: _isSearching
            ? null
            : (value) async {
                if (value.isEmpty) {
                  showSearchError('Please enter a phone number');
                  return;
                }

                setState(() {
                  _isSearching = true;
                });

                String searchValue = value.replaceAll(' ', '');
                if (searchValue.length > 9) {
                  searchValue = searchValue.substring(searchValue.length - 9);
                }

                final results = await getTransactionsByPhone(
                    FirebaseAuth.instance.currentUser?.uid, searchValue);

                setState(() {
                  _isSearching = false;
                  searchResults = results;
                });

                if (results.isEmpty) {
                  showSearchError('No transactions found for this number');
                }
              },
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return _PermissionDeniedMessage(onRetry: _loadTransactions);
    }
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    final displayTransactions =
        searchResults.isNotEmpty ? searchResults : transactions;

    if (displayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or date filter',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayTransactions.length,
      itemBuilder: (context, index) {
        final isLastItem = index == displayTransactions.length - 1;
        return Column(
          children: [
            TransactionCard(transaction: displayTransactions[index]),
            if (!isLastItem) const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _PermissionDeniedMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'SMS Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We need SMS permission to analyze your transactions',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await openAppSettings();
                onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }
}
