/*
 * @Author: rh.liuweihua 
 * @Date: 2019-11-14 15:20:06 
 * @Last Modified by: rh.liuweihua
 * @Last Modified time: 2019-11-14 16:47:09
 */
import 'package:github/index.dart';

class ProfileChangeNotifier extends ChangeNotifier {
  Profile get _profile => Global.profile;

  @override
  void notifyListeners() {
    // 保存变更的profile
    Global.saveProfile();
    // 通知依赖的widgets
    super.notifyListeners();
  }
}

// 用户
class UserModel extends ProfileChangeNotifier {
  User get user => _profile.user;

  // App是否登录
  bool get isLogin => user != null;

  // 用户信息发生变化，更新用户信息并通知依赖他的子孙widgets更新
  set user(User user) {
    if (user?.login != _profile.user?.login) {
      _profile.lastLogin = _profile.user?.login;
      _profile.user = user;
      notifyListeners();
    }
  }
}

// 主题
class ThemeModel extends ProfileChangeNotifier {
  // 获取当前主题，如果未设置，默认使用蓝色主题
  ColorSwatch get theme => Global.themes
    .firstWhere((e) => e.value == _profile.theme, orElse: () => Colors.blue);

  // 主题更新后，通知其依赖，更新主题
  set theme(ColorSwatch color) {
    if (color != theme) {
      _profile.theme = color[500].value;
      notifyListeners();
    }
  }
}

// 语言状态
class LocaleModel extends ProfileChangeNotifier {
  // 获取当前用户的App语言配置Locale类
  Locale getLocale() {
    if (_profile.locale == null) return null;
    var t = _profile.locale.split('_');
    return Locale(t[0], t[1]);
  }

  // 获取当前Locale
  String get locale => _profile.locale;

  set locale(String locale) {
    if (locale != _profile.locale) {
      _profile.locale = locale;
      notifyListeners();
    }
  }
}
