/*
 * @Author: rh.liuweihua 
 * @Date: 2019-11-13 19:26:09 
 * @Last Modified by: rh.liuweihua
 * @Last Modified time: 2019-11-14 14:57:22
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../index.dart';

// 主题颜色
const _themes = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
];

class Global {
  // 本地存储
  static SharedPreferences _prefs;
  // 用户模型
  static Profile profile = Profile();
  // 网络缓存对象
  static NetCache netCache = NetCache();
  // 可选主题列表
  static List<MaterialColor> get themes => _themes;
  // 是否为release版
  static bool get isRelease => bool.fromEnvironment('dart.vm.product');

  // 初始化全局信息，在App启动时执行
  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
    // 获取本次用户信息
    var _profile = _prefs.getString('profile');
    if (_profile != null) {
      try {
        profile = Profile.fromJson(jsonDecode(_profile));
      } catch(e) {
        print(e);
      }
    }

    // 查看本地用户信息中是否有缓存策略，若果没有设置成默认的
    profile.cache = profile.cache ?? CacheConfig()
      ..enable = true
      ..maxAge = 3600
      ..maxCount = 100;

    // 初始化网络请求相关配置
    Git.init();
  }

  // 持久化Profile信息
  static saveProfile() => 
    _prefs.setString('profile', jsonEncode(profile.toJson()));
  
}