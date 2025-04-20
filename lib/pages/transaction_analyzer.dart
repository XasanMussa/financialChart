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
  bool _isLoading = false;
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
          .doc(transaction
              .transactionID) // Using transactionID as the document ID
          .set({
        'sender': transaction.originalMessage,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': FirebaseFirestore.Timestamp.fromDate(transaction.date!),
        'isExpense': transaction.isExpense,
        'phone': transaction.phoneNumber,
        'transactionID': transaction.transactionID,
      });

      // Store the transactionID in local storage to mark it as uploaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(transaction.transactionID, true);

      print("Transaction uploaded: ${transaction.transactionID}");
    } catch (e) {
      print("Error uploading transaction: $e");
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
      final snapshot = await FirebaseFirestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('transactions')
          .where('phone', isEqualTo: phoneNumber)
          .orderBy('date', descending: true) // Order by date descending
          .get();
      print("document found for $phoneNumber");

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
      print('Error fetching transactions for phone number $phoneNumber: $e');
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
        title: const Text('Transactions'),
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
      body: Column(
        children: [
          buildSearchBar(onSubmit: (phonenumber) async {
            transactions = await getTransactionsByPhone(
                FirebaseAuth.instance.currentUser?.uid, phonenumber);
            print(phonenumber);
          }),
          DateSelector(
            onDateSelected: (date) async {
              if (date == null) {
                // Date was deselected, show all transactions
                await readFromFirebase();
              } else {
                // Date was selected, filter transactions
                transactions = await getTransactionsByDate(
                    FirebaseAuth.instance.currentUser?.uid, date);
                print("Searching for transactions on: $date");
              }
              setState(() {
                selectedDateForSearch = date;
              });
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget buildSearchBar({required Function(String) onSubmit}) {
    TextEditingController _searchController = TextEditingController();
    String searchValue = '';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              searchValue = ''; // Reset value
            },
          ),
          hintText: "Search here...",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) {
          searchValue = value; // Store input value
        },
        onSubmitted: (value) {
          onSubmit(value); // Trigger function when submitted
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return _PermissionDeniedMessage(onRetry: _loadTransactions);
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) =>
          TransactionCard(transaction: transactions[index]),
    );
  }
}

class _PermissionDeniedMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SMS permission required to analyze transactions',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.security),
            label: const Text('Grant Permission'),
            onPressed: () async {
              await openAppSettings();
              onRetry();
            },
          ),
        ],
      ),
    );
  }
}
