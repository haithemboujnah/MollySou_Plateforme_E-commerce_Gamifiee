class User {
  final String id;
  final String nomComplet;
  final DateTime dateNaissance;
  final String genre;
  final String email;
  final String password;

  User({
    required this.id,
    required this.nomComplet,
    required this.dateNaissance,
    required this.genre,
    required this.email,
    required this.password,
  });
}