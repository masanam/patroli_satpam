import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:police_patrol_app/models/user.dart';
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/models/resource.dart';
import 'package:police_patrol_app/models/officer.dart';
import 'package:police_patrol_app/models/patrol_report.dart';
import 'package:police_patrol_app/models/checkpoint.dart';
import 'package:police_patrol_app/models/patrol_scan.dart';
import 'package:police_patrol_app/models/contact_center.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference incidentsCollection =
      FirebaseFirestore.instance.collection('incidents');
  // Reference to the patrol routes collection in Firestore
  final CollectionReference patrolRoutesCollection =
      FirebaseFirestore.instance.collection('patrolRoutes');
  // New collections
  final CollectionReference resourcesCollection =
      FirebaseFirestore.instance.collection('resources');
  final CollectionReference officersCollection =
      FirebaseFirestore.instance.collection('officers');
  final CollectionReference checkpointsCollection =
      FirebaseFirestore.instance.collection('checkpoints');
  final CollectionReference _patrolReportCollection =
      FirebaseFirestore.instance.collection('patrolReports');
  final CollectionReference _contactCentersCollection =
      FirebaseFirestore.instance.collection('contactCenters');

  Future<void> addPreApprovalRequest(
      String email, UserRole selectedRole) async {
    final request = _firestore.collection('PreApprovedUsers').doc(email);
    final existing = await request.get();
    if (existing.exists) {
      return;
    }
    await request.set({
      'email': email,
      'isApproved': false,
      'role': selectedRole.index,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Function to check if a user is pre-approved
  Future<bool> isUserPreApproved(String email) async {
    return await getApprovedUserRole(email) != null;
  }

  Future<UserRole?> getApprovedUserRole(String email) async {
    final snapshot =
        await _firestore.collection('PreApprovedUsers').doc(email).get();
    final data = snapshot.data();
    if (!snapshot.exists ||
        data is! Map<String, dynamic> ||
        data['isApproved'] != true) {
      return null;
    }
    final roleIndex = _roleIndex(data['role']);
    if (roleIndex == null) {
      throw StateError('Peran pada persetujuan akun tidak valid.');
    }
    return UserRole.values[roleIndex];
  }

  int? _roleIndex(dynamic role) {
    if (role is int && role >= 0 && role < UserRole.values.length) {
      return role;
    }
    if (role is String) {
      final normalized = role.replaceFirst('UserRole.', '');
      for (final userRole in UserRole.values) {
        if (userRole.name == normalized) return userRole.index;
      }
    }
    return null;
  }

  // Function to register a new user
  Future<fbAuth.UserCredential?> registerUser(
      String email, String password, UserRole role) async {
    try {
      fbAuth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After successfully creating the user, save additional information in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'role': role.toString(),
      });

      return userCredential;
    } catch (e) {
      print('Error occurred while registering: $e');
      return null;
    }
  }

  // Add a new user to Firestore
  Future<void> addUser(User user, UserRole role) async {
    // Role parameter added
    try {
      await usersCollection.doc(user.id).set({
        ...user.toJson(),
        'role': role.index, // Role is saved
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Update user role in Firestore
  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await usersCollection.doc(userId).update({
        'role': role.index,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Get user data from Firestore
  Future<User?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if 'role' exists and is a map with a 'role' key
        if (data.containsKey('role') && data['role'] is Map) {
          Map<String, dynamic> roleMap = data['role'] as Map<String, dynamic>;
          if (roleMap.containsKey('role')) {
            // Convert the integer role into an enum and replace in the data map
            data['role'] = UserRole.values[roleMap['role'] as int];
          }
        }

        return User.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Add a new incident to Firestore
  Future<void> addIncident(Incident incident) async {
    await incidentsCollection.add(incident.toJson());
  }

  // Get a list of recent incidents from Firestore
  Stream<List<Incident>> getRecentIncidents() {
    return incidentsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get a list of all incidents from Firestore
  Future<List<Incident>> getIncidents() async {
    try {
      QuerySnapshot querySnapshot = await incidentsCollection.get();
      return querySnapshot.docs.map((doc) {
        return Incident.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<List<Incident>> getIncidentsForPatrolRoute(
      String patrolRouteId) async {
    try {
      // Query the incidentsCollection where the patrolRouteId matches the provided ID
      QuerySnapshot querySnapshot = await incidentsCollection
          .where('patrolRouteId', isEqualTo: patrolRouteId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No incidents found for patrolRouteId: $patrolRouteId");
        return [];
      }

      // Loop through each document and print its data (For debugging)
      for (var doc in querySnapshot.docs) {
        print("Document data: ${doc.data()}");
      }

      // Convert the results to a list of Incident objects
      return querySnapshot.docs.map((doc) {
        var data = doc.data();
        if (data == null) {
          print("Null data for document with ID: ${doc.id}");
        }
        return Incident.fromJson(data as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<Map<String, int>> getIncidentCountsForPatrolRoutes(
      List<String> patrolRouteIds) async {
    final counts = <String, int>{};
    if (patrolRouteIds.isEmpty) return counts;

    for (var offset = 0; offset < patrolRouteIds.length; offset += 30) {
      final batch = patrolRouteIds.skip(offset).take(30).toList();
      final snapshot = await incidentsCollection
          .where('patrolRouteId', whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final routeId = data['patrolRouteId'] as String?;
        if (routeId != null) {
          counts[routeId] = (counts[routeId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  // Add a new patrol route to Firestore
  Future<void> addPatrolRoute(PatrolRoute patrolRoute) async {
    return await patrolRoutesCollection
        .doc(patrolRoute.id)
        .set(patrolRoute.toJson());
  }

  Future<String> createCheckpointSession(String officerId) async {
    final sessionId = const Uuid().v4();
    await patrolRoutesCollection.doc(sessionId).set({
      'id': sessionId,
      'officerId': officerId,
      'startTime': DateTime.now().millisecondsSinceEpoch,
      'endTime': null,
      'locations': <Map<String, dynamic>>[],
      'incidents': null,
      'sessionType': 'checkpoint',
      'startedAt': FieldValue.serverTimestamp(),
    });
    return sessionId;
  }

  Future<Checkpoint?> getCheckpoint(String checkpointId) async {
    final snapshot = await checkpointsCollection.doc(checkpointId).get();
    if (!snapshot.exists) return null;
    return Checkpoint.fromJson(
        snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  Future<bool> hasCheckpointBeenScanned(
      String sessionId, String checkpointId) async {
    final officerId = _auth.currentUser?.uid;
    if (officerId == null) {
      throw StateError('Sesi login sudah berakhir.');
    }
    final snapshot = await patrolRoutesCollection
        .doc(sessionId)
        .collection('scans')
        .where('checkpointId', isEqualTo: checkpointId)
        .where('officerId', isEqualTo: officerId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> addPatrolScan(PatrolScan scan) async {
    await patrolRoutesCollection
        .doc(scan.sessionId)
        .collection('scans')
        .doc(scan.id)
        .set(scan.toJson());
  }

  Future<List<PatrolScan>> getScansForSession(String sessionId) async {
    try {
      final snapshot = await patrolRoutesCollection
          .doc(sessionId)
          .collection('scans')
          .get();
      final scans = snapshot.docs
          .map((doc) => PatrolScan.fromJson(doc.data(), doc.id))
          .toList();
      scans.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      return scans;
    } catch (e) {
      print('Error getScansForSession: $e');
      return [];
    }
  }

  Future<Map<String, int>> getCheckpointScanCounts(
      List<String> sessionIds) async {
    final counts = <String, int>{};
    final userId = _auth.currentUser?.uid;
    if (userId == null || sessionIds.isEmpty) return counts;
    
    // Menghindari collectionGroup karena butuh composite index
    await Future.wait(sessionIds.map((sessionId) async {
      try {
        final snapshot = await patrolRoutesCollection
            .doc(sessionId)
            .collection('scans')
            .where('officerId', isEqualTo: userId)
            .get();
        if (snapshot.docs.isNotEmpty) {
          counts[sessionId] = snapshot.docs.length;
        }
      } catch (e) {
        print('Error get scan counts for $sessionId: $e');
      }
    }));
    return counts;
  }

  /// Mengambil set sessionId yang memiliki minimal 1 scan berhasil.
  /// Digunakan untuk filter patrol routes di laporan.
  Future<Set<String>> getSessionIdsWithScans(
      List<String> sessionIds) async {
    final result = <String>{};
    final userId = _auth.currentUser?.uid;
    if (userId == null || sessionIds.isEmpty) return result;

    await Future.wait(sessionIds.map((sessionId) async {
      try {
        final snapshot = await patrolRoutesCollection
            .doc(sessionId)
            .collection('scans')
            .where('officerId', isEqualTo: userId)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          result.add(sessionId);
        }
      } catch (e) {
        print('Error get session scans for $sessionId: $e');
      }
    }));
    return result;
  }

  // Retrieve all patrol routes recorded by a specific officer
  Stream<List<PatrolRoute>> getPatrolRoutesForOfficer(String officerId) {
    return patrolRoutesCollection
        .where('officerId', isEqualTo: officerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PatrolRoute.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update a specific patrol route
  Future<void> updatePatrolRoute(PatrolRoute patrolRoute) async {
    return await patrolRoutesCollection
        .doc(patrolRoute.id)
        .update(patrolRoute.toJson());
  }

  /// Update hanya field locations dan endTime pada patrol route yang sudah ada.
  /// Digunakan untuk menyimpan titik GPS secara incremental ke Firestore.
  Future<void> updatePatrolRouteLocations({
    required String routeId,
    required List<LocationPoint> locations,
    DateTime? endTime,
  }) async {
    final data = <String, dynamic>{
      'locations': locations.map((l) => l.toJson()).toList(),
    };
    if (endTime != null) {
      data['endTime'] = endTime.millisecondsSinceEpoch;
    }
    await patrolRoutesCollection.doc(routeId).update(data);
  }

  /// Append satu LocationPoint ke array locations di Firestore
  /// tanpa harus membaca seluruh dokumen (menggunakan FieldValue.arrayUnion).
  Future<void> appendLocationToRoute(
      String routeId, LocationPoint point) async {
    await patrolRoutesCollection.doc(routeId).update({
      'locations': FieldValue.arrayUnion([point.toJson()]),
    });
  }

  // Fetch all available resources (cars, equipment, manpower)
  Future<List<Resource>> getAllResources() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('resources').get();
      return querySnapshot.docs.map((doc) {
        return Resource.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  // Method to delete a resource by ID
  Future<void> deleteResource(String id) async {
    try {
      await resourcesCollection.doc(id).delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Fetch all officer details
  Future<List<Officer>> getAllOfficers() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('officers').get();
      return querySnapshot.docs.map((doc) {
        return Officer.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  // Add a new resource to Firestore
  Future<void> addResource(Resource resource) async {
    try {
      await resourcesCollection.doc(resource.id).set(resource.toJson());
    } catch (e) {
      print(e.toString());
    }
  }

  // Add a new officer to Firestore
  Future<void> addOfficer(Officer officer) async {
    try {
      await officersCollection.doc(officer.id).set(officer.toJson());
    } catch (e) {
      print(e.toString());
    }
  }

  // Fetch all resources from Firestore
  Future<List<Resource>> getResources() async {
    try {
      QuerySnapshot querySnapshot = await resourcesCollection.get();
      return querySnapshot.docs.map((doc) {
        return Resource.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  // Fetch all officers from Firestore
  Future<List<Officer>> getOfficers() async {
    try {
      QuerySnapshot querySnapshot = await officersCollection.get();
      return querySnapshot.docs.map((doc) {
        return Officer.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Stream<List<User>> getOfficer() {
    return usersCollection
        .where('role', isEqualTo: UserRole.Officer.index)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Incident>> getAllIncidents() {
    return incidentsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Incident.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addPatrolReport(PatrolReport report) async {
    return _patrolReportCollection
        .doc(report.id)
        .set(report.toMap())
        .catchError((error) {
      throw Exception('Failed to add report: $error');
    });
  }

  Stream<List<PatrolReport>> getPatrolReportsForOfficer(String officerId) {
    return _patrolReportCollection
        .where('officerId', isEqualTo: officerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PatrolReport.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<PatrolReport?> getPatrolReportByIncident(Incident incident) async {
    try {
      // Assuming patrol reports have an attribute that references the associated incident's patrolRouteId
      QuerySnapshot querySnapshot = await _patrolReportCollection
          .where('patrolRouteId', isEqualTo: incident.patrolRouteId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print(
            "No patrol report found for incident with patrolRouteId: ${incident.patrolRouteId}");
        return null;
      }

      // Convert the first document (assuming only one report per incident) to a PatrolReport object
      return PatrolReport.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // ─── Contact Center ───────────────────────────────────────────────────────

  /// Mengambil semua kontak contact center dari Firestore (sekali ambil)
  Future<List<ContactCenter>> getContactCenters() async {
    try {
      final snapshot = await _contactCentersCollection
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ContactCenter.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('getContactCenters error: $e');
      return [];
    }
  }

  /// Stream realtime daftar contact center (aktif)
  Stream<List<ContactCenter>> streamContactCenters() {
    return _contactCentersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ContactCenter.fromJson({...data, 'id': doc.id});
            }).toList());
  }

  /// Mengambil contact center berdasarkan kategori
  Future<List<ContactCenter>> getContactCentersByCategory(
      ContactCategory category) async {
    try {
      final snapshot = await _contactCentersCollection
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category.index)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ContactCenter.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('getContactCentersByCategory error: $e');
      return [];
    }
  }

  /// Menambahkan contact center baru ke Firestore
  Future<String> addContactCenter(ContactCenter contact) async {
    try {
      final id = contact.id.isNotEmpty ? contact.id : const Uuid().v4();
      final data = contact.copyWith(id: id).toJson();
      await _contactCentersCollection.doc(id).set(data);
      return id;
    } catch (e) {
      print('addContactCenter error: $e');
      rethrow;
    }
  }

  /// Memperbarui data contact center yang sudah ada
  Future<void> updateContactCenter(ContactCenter contact) async {
    try {
      await _contactCentersCollection
          .doc(contact.id)
          .update(contact.toJson());
    } catch (e) {
      print('updateContactCenter error: $e');
      rethrow;
    }
  }

  /// Menonaktifkan (soft-delete) contact center
  Future<void> deleteContactCenter(String id) async {
    try {
      await _contactCentersCollection.doc(id).update({'isActive': false});
    } catch (e) {
      print('deleteContactCenter error: $e');
      rethrow;
    }
  }
}
