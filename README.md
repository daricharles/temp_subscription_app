# temp_subscription_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# Flutter In-App Subscriptions (Google Play Billing)
Below is a step-by-step guide on how this app was implemented.

This project demonstrates how to implement in-app subscription purchases (monthly and yearly) in a Flutter app using the [`in_app_purchase`](https://pub.dev/packages/in_app_purchase) package. It covers:

* Setting up subscriptions in Google Play Console
* Handling subscription purchases in Flutter
* Restoring purchases
* Saving subscription state with `shared_preferences`

---

## 📱 Features

* Monthly and yearly subscription options
* Purchase and restore subscription
* Subscription validation and local storage
* Works with Google Play Internal Testing track

---

## 🛠️ Packages Used

| Package                                                             | Purpose                                           |
| ------------------------------------------------------------------- | ------------------------------------------------- |
| [`in_app_purchase`](https://pub.dev/packages/in_app_purchase)       | Access and manage in-app products via Google Play |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Save and retrieve subscription state locally      |

---

## 🔧 Prerequisites

1. A **Google Play Developer Account**
2. A Flutter project targeting **Android**
3. **Google Play Console App** created and configured
4. A **test device with a Google account added as license tester**

---

## 🚀 Step-by-Step Setup

### 1. Configure Your App in Google Play Console

* Create your app in **Google Play Console**
* Go to **Monetization > Products > Subscriptions**
* Add 2 subscriptions:

  * `monthly_premium`
  * `yearly_premium`
* Fill out required information and **activate** both

### 2. Internal Testing Setup

* Go to **Testing > Internal Testing**
* Create a test release and upload your app bundle (`.aab`)
* Add your **testers** (use Gmail accounts) under testers list
* Share the **opt-in link** with yourself to install the app from Play Store

### 3. Flutter Project Configuration

* Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  in_app_purchase: ^3.1.11
  shared_preferences: ^2.2.2
```

* In your `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="com.android.vending.BILLING" />
  ```

* Enable Play Billing in `build.gradle`:

```gradle
dependencies {
    implementation 'com.android.billingclient:billing:6.1.0'
}
```

### 4. Initialize In-App Purchases in Flutter

* In `main.dart`:

```dart
final InAppPurchase _inAppPurchase = InAppPurchase.instance;
final List<String> _productIds = ['monthly_premium', 'yearly_premium'];
```

* Listen to purchase stream and query available products:

```dart
_purchaseStream = _inAppPurchase.purchaseStream;
_available = await _inAppPurchase.isAvailable();
ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds.toSet());
```

* Display UI conditionally using `_loading`, `_products`, and `_isSubscribed`.

* Handle purchases:

```dart
void _buySubscription(ProductDetails productDetails) {
  final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
  _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
}
```

* Save subscription status:

```dart
final prefs = await SharedPreferences.getInstance();
prefs.setBool('isSubscribed', true);
```

### 5. Build and Upload to Play Console

* Run this to build the `.aab`:

  ```
  flutter build appbundle
  ```

* If you get an error like:

  > Version code 1 has already been used

  Open `android/app/build.gradle`, and **increment** the version code:

```gradle
defaultConfig {
    versionCode 2
    versionName "1.0.1"
}
```

### 6. Create New Release

* Go to **Internal Testing > Create new release**
* Upload your updated `.aab`
* Save and publish to testers

---

## 🧪 Testing Tips

* Use a real device with your **tester Gmail account** added
* Always download the app from the **opt-in link** (not manually installed)
* Wait \~15–30 mins after publishing before testing
* Use Play Store version with **logged-in test account**

---

## ✅ Output

Once configured properly:

* Subscription plans appear as a list
* Users can purchase monthly or yearly plans
* App stores and restores purchase history
* Subscription status is visually shown

---

## 📸 Screenshots (optional)

*Add screenshots of your working UI here*

---

## 💡 Credits

This project was developed as part of a learning exercise to implement in-app subscriptions in Flutter.
