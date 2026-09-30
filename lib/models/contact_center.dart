/// Enum untuk kategori Contact Center
enum ContactCategory {
  emergency,   // Darurat (Polisi, Ambulans, Pemadam)
  patrol,      // Koordinasi Patroli
  report,      // Pelaporan Insiden
  administrative, // Administrasi
}

/// Model ContactCenter merepresentasikan kontak penting (petugas, posko, layanan darurat)
/// yang dapat dihubungi melalui WhatsApp maupun telepon langsung.
class ContactCenter {
  final String id;
  final String name;
  final String whatsappNumber; // Format internasional tanpa '+', contoh: 6281234567890
  final String? phoneNumber;   // Nomor telepon biasa (opsional)
  final String? position;      // Jabatan / posisi (opsional)
  final String? unit;          // Unit / divisi (opsional)
  final ContactCategory category;
  final bool isActive;
  final String? description;   // Deskripsi singkat (opsional)
  final String? avatarUrl;     // URL foto profil (opsional)

  const ContactCenter({
    required this.id,
    required this.name,
    required this.whatsappNumber,
    this.phoneNumber,
    this.position,
    this.unit,
    required this.category,
    this.isActive = true,
    this.description,
    this.avatarUrl,
  });

  /// Menghasilkan URL deep-link WhatsApp
  String get whatsappUrl => 'https://wa.me/$whatsappNumber';

  /// Menghasilkan URL WhatsApp dengan pesan awal (pre-filled message)
  String whatsappUrlWithMessage(String message) =>
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}';

  /// Mengkonversi objek ContactCenter menjadi Map JSON (untuk Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'whatsappNumber': whatsappNumber,
      'phoneNumber': phoneNumber,
      'position': position,
      'unit': unit,
      'category': category.index,
      'isActive': isActive,
      'description': description,
      'avatarUrl': avatarUrl,
    };
  }

  /// Membuat objek ContactCenter dari Map JSON (dari Firestore)
  factory ContactCenter.fromJson(Map<String, dynamic> json) {
    return ContactCenter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      whatsappNumber: json['whatsappNumber'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      position: json['position'] as String?,
      unit: json['unit'] as String?,
      category: json['category'] != null
          ? ContactCategory.values[json['category'] as int]
          : ContactCategory.patrol,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// Membuat salinan objek dengan perubahan tertentu
  ContactCenter copyWith({
    String? id,
    String? name,
    String? whatsappNumber,
    String? phoneNumber,
    String? position,
    String? unit,
    ContactCategory? category,
    bool? isActive,
    String? description,
    String? avatarUrl,
  }) {
    return ContactCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() =>
      'ContactCenter(id: $id, name: $name, wa: $whatsappNumber, category: $category)';
}
