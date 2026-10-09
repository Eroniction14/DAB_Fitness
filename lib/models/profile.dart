/// What every account has, whether a client ([UserProfile]) or a trainer
/// ([Trainer]). Field names match the legacy database fields.
abstract class Profile {
  const Profile();

  /// The account's uid; also the profile's database key.
  String get id;
  String get name;
  String get email;
  String get number;
  String get gender;
  String get address;

  /// Database fields the user may edit on the profile screen, with their current
  /// values (legacy spellings, e.g. `Name`, `Number`).
  Map<String, String> get editableFields => {
        'Name': name,
        'Number': number,
        'Gender': gender,
        'Address': address,
      };
}
