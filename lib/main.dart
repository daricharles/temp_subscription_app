import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SubscriptionPage(),
    );
  }
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<String> _productIds = ['monthly_premium', 'yearly_premium'];
  late Stream<List<PurchaseDetails>> _purchaseStream;
  List<ProductDetails> _products = [];
  bool _available = false;
  bool _loading = true;
  bool _isSubscribed = false;
  bool _isRestoring = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _purchaseStream = _inAppPurchase.purchaseStream;
      _subscription = _purchaseStream.listen(
        _listenToPurchaseUpdated,
        onDone: () {
          debugPrint('Purchase stream closed');
        },
        onError: (error) {
          debugPrint('Error in purchase stream: $error');
          _showError('Error in purchase stream: $error');
        },
      );

      _available = await _inAppPurchase.isAvailable();
      debugPrint("Store available: $_available");

      if (!_available) {
        debugPrint("Store not available");
        setState(() {
          _loading = false;
        });
        return;
      }

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds.toSet());

      debugPrint("Query response: ${response.productDetails.length} products");
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Not found IDs: ${response.notFoundIDs}");
      }

      if (response.error != null) {
        debugPrint("Error querying products: ${response.error}");
        _showError('Error loading products: ${response.error}');
      }

      setState(() {
        _products = response.productDetails;
        _loading = false;
      });

      // Load saved subscription status
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isSubscribed = prefs.getBool('isSubscribed') ?? false;
      });
      debugPrint('Is user subscribed: $_isSubscribed');
    } catch (e) {
      debugPrint('Error initializing: $e');
      _showError('Error initializing app: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          await prefs.setBool('isSubscribed', true);

          setState(() {
            _isSubscribed = true;
            _isRestoring = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Purchase successful: ${purchaseDetails.productID}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _isRestoring = false;
          });
          _showError(
            'Purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}',
          );
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          setState(() {
            _isRestoring = false;
          });
          debugPrint('Purchase canceled');
        }
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
      });
      debugPrint('Error in purchase update: $e');
      _showError('Error processing purchase: $e');
    }
  }

  Future<void> _buySubscription(ProductDetails productDetails) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error buying subscription: $e');
      _showError('Error starting purchase: $e');
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isRestoring = true;
      });
      await _inAppPurchase.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restoring purchases...')));
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
      });
      debugPrint('Error restoring purchases: $e');
      _showError('Error restoring purchases: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Subscription'),
        actions: [
          if (_isSubscribed)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSubscribed)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.green.withAlpha(26),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'You are currently subscribed!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? const Center(child: Text('No subscriptions available'))
                    : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(
                              product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(product.description),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  product.price,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_isSubscribed)
                                  const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            onTap:
                                _isSubscribed
                                    ? null
                                    : () => _buySubscription(product),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRestoring ? null : _restorePurchases,
              child:
                  _isRestoring
                      ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Restoring...'),
                        ],
                      )
                      : const Text('Restore Purchases'),
            ),
          ),
        ],
      ),
    );
  }
}
