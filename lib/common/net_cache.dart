/*
 * @Author: rh.liuweihua 
 * @Date: 2019-11-14 11:29:48 
 * @Last Modified by: rh.liuweihua
 * @Last Modified time: 2019-11-14 17:46:03
 */
import 'dart:collection';
import 'package:dio/dio.dart';
import '../index.dart';

class CacheObject {
  CacheObject(this.response)
    : timeStamp = new DateTime.now().millisecondsSinceEpoch;
  Response response;
  int timeStamp;

  // 运算符重载
  @override 
  bool operator ==(other) {
    return response.hashCode == other.hashCode;
  }

  @override 
  int get hashCode => response.realUri.hashCode;
}

class NetCache extends Interceptor {
  // 为了保证顺序，使用LinkedHashMap存储对象
  // LinkedHashMap: 有序的Map
  // HashMap：不保证顺序的Map
  // SplayTreeMap：伸展树（自平衡二叉树），能快速完成增删改查
  var cache = LinkedHashMap<String, CacheObject>();

  @override 
  onRequest(RequestOptions options) async {
    /**
     * 原则：
     * 1.查看是否启用缓存
     * 2.判断是否是下拉刷新：是，删除以前缓存并返回默认options；否，返回缓存并查看缓存是否过期
     */
    // 查看是否启用缓存
    if (!Global.profile.cache.enable) return options;
    if (options.extra['refresh'] == true) {
      if (options.extra['list'] == true) {
        // 如果是列表，把与当前url相同的key都删除
        cache.removeWhere((key, v) => key.contains(options.path));
      } else {
        // 不是列表只删除url对应的key
        cache.remove(options.uri.toString());
      }
      return options;
    }

    if (options.extra['noCahce'] != true && options.method.toLowerCase() == 'get') {
      // 获取要读取的缓存key
      String key = options.extra['cacheKey'] ?? options.uri.toString();
      var ob = cache[key];
      if (ob != null) {
        // 取到缓存后要查看上次缓存是否已过期
        if ((DateTime.now().millisecondsSinceEpoch - ob.timeStamp) / 1000 < Global.profile.cache.maxAge) {
          return ob.response;
        } else {
          // 如果上次缓存已过期，删除
          cache.remove(key);
        }
      }
    }
    return super.onRequest(options);
  }

  @override
  Future onError(DioError err) {
    // 错误状态不缓存
    return super.onError(err);
  }

  @override
  Future onResponse(Response response) {
    // 如果启用缓存，请求成功后保存数据
    if (Global.profile.cache.enable) {
      _saveCache(response);
    }
    return super.onResponse(response);
  }

  _saveCache(Response object) {
    // 需要判断是否需要缓存以及是否是get请求
    RequestOptions options = object.request;
    if (options.extra['noCache'] != true && options.method.toLowerCase() == 'get') {
      // 判断缓存条数是否超过最大限制
      if (cache.length >= Global.profile.cache.maxCount) {
        cache.remove(cache[cache.keys.first]); // 移除最早一条
      }
      String key = options.extra['cacheKey'] ?? options.uri.toString();
      cache[key] = CacheObject(object);
    }
  }

}