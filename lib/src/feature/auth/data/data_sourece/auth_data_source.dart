import 'package:briqwear/src/service/remote/api_services.dart';


class AuthDAtaSource {
  final _apiService = ShopifyAuthApiService();

  userSignup() {
    final request = ShopifySignupRequest(email: "email", password: "password",);

    _apiService.signup(request);
  }
}
