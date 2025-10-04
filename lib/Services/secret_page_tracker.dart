import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chiper/Hide/hide_page.dart';
import 'package:chiper/pc_tools/shutdown_control.dart';
import 'package:chiper/pc_setting/pc_setting_page.dart';
import 'package:chiper/pc_tools/pc_tools.dart';

class SecretPageTracker extends RouteObserver<PageRoute> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of types that represent "secret" pages
  final List<Type> _secretPageTypes = [
    HidePage,
    ShutdownControlPage,
    PcSettingPage,
    PCToolsPage,
  ];

  // Tracks if any secret page is currently active
  bool _isSecretPageActive = false;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAndSetSecretPageStatus(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _checkAndSetSecretPageStatus(previousRoute); // Check the new top route
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _checkAndSetSecretPageStatus(newRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _checkAndSetSecretPageStatus(previousRoute);
  }

  void _checkAndSetSecretPageStatus(Route? route) {
    bool newSecretPageActive = false;
    if (route is PageRoute) {
      Widget? pageWidget;

      if (route.settings.name == '/hidePage') {
        newSecretPageActive = true;
      } else if (route is MaterialPageRoute) {
        // For MaterialPageRoute, the builder directly provides the widget
        pageWidget = route.builder(route.navigator!.context);
      } else if (route is PageRouteBuilder) {
        // For PageRouteBuilder, call the pageBuilder to get the widget
        // We need to provide dummy animations as they are required by the pageBuilder signature
        pageWidget = route.pageBuilder(route.navigator!.context, AlwaysStoppedAnimation(0), AlwaysStoppedAnimation(0));
      }

      if (pageWidget != null) {
        for (var type in _secretPageTypes) {
          if (pageWidget.runtimeType == type) {
            newSecretPageActive = true;
            break;
          }
        }
      }
    }

    // Only update Firestore if the status has changed
    if (newSecretPageActive != _isSecretPageActive) {
      _isSecretPageActive = newSecretPageActive;
      _updateSecretPageStatusInFirestore(_isSecretPageActive);
    }
  }

  Future<void> _updateSecretPageStatusInFirestore(bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in. Cannot update secret_page status.");
      return;
    }

    final pcStatusDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    try {
      await pcStatusDocRef.set({'secret_page': isActive}, SetOptions(merge: true));
      print("Firestore secret_page status updated to $isActive");
    } catch (e) {
      print("Error updating secret_page status in Firestore: $e");
    }
  }
}
