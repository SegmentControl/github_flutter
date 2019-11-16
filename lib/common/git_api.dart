/*
 * @Author: rh.liuweihua 
 * @Date: 2019-11-14 14:54:43 
 * @Last Modified by: rh.liuweihua
 * @Last Modified time: 2019-11-14 18:38:38
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
import '../index.dart';

class Git {

  // 请求失败时可能需要context用作页面跳转等操作
  Git([this.context]) {
    _options = Options(extra: {'context': context});
  }

  BuildContext context;
  Options _options;

  // 创建单利dio
  static Dio dio = Dio(BaseOptions(
    baseUrl: 'https://api.github.com/',
    headers: {
      HttpHeaders.acceptHeader: "application/vnd.github.squirrel-girl-preview,"
          "application/vnd.github.symmetra-preview+json",
    },
  ));

  static void init() {
    // 添加缓存插件
    dio.interceptors.add(Global.netCache);
    // 添加token
    dio.options.headers[HttpHeaders.authorizationHeader] = Global.profile.token;

    // 在调试模式下需要抓包调试，所以我们使用代理，并禁用HTTPS证书校验
    if (!Global.isRelease) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          return "PROXY 10.1.10.250:8888";
        };
        //代理工具会提供一个抓包的自签名证书，会通不过证书校验，所以我们禁用证书校验
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    }
  }

  // 登录接口
  Future<User> login(String login, String pwd) async {
    String basic = 'Basic' + base64.encode(utf8.encode('$login:$pwd'));
    var r = await dio.get(
      '/user/$login',
      options: _options.merge(headers: {
        HttpHeaders.authorizationHeader: basic
      }, extra: {
        'noCache': true,
      })
    );
    // 登录成功更新header配置
    dio.options.headers[HttpHeaders.authorizationHeader] = basic;
    // 清空之前所有缓存
    Global.netCache.cache.clear();
    // 更新global中profile信息
    Global.profile.token = basic;
    return User.fromJson(r.data);
  }

  // 获取用户项目列表
  Future<List<Repo>> getRepos(
    {
      Map<String, dynamic> queryParameters,
      refresh = false
    }
  ) async {
    // 如果是下拉刷新，添加extra
    if (refresh) {
      _options.extra.addAll({'refresh': true, 'list': true});
    }
    var r = await dio.get<List>(
      'user/repos',
      queryParameters: queryParameters,
      options: _options,
    );
    return r.data.map((d) => Repo.fromJson(d)).toList();
  }
}