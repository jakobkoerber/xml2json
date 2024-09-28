/*
 * xml2json_parker_with_attrs
 * @description: 解析节点中的属性
 * 
 * @author: JuneCheng
 * @date: 2021/05/23 18:04:54
 */

part of '../xml2json.dart';

/// ParkerWithAttrs transform class.
/// Used as an alternative to Parker if the node element contains attributes.
class _Xml2JsonParkerWithAttrs {
  /// Parker transformer function.
  Map<dynamic, dynamic>? _transform(dynamic node, dynamic objin,
      {Map<String, String?>? entries}) {
    Map<dynamic, dynamic>? obj = objin;
    if (node is XmlElement) {
      final nodeName = '"${node.name.qualified}"';
      if (obj![nodeName] is List && !obj.keys.contains(nodeName)) {
        obj[nodeName].add(<dynamic, dynamic>{});
        obj = obj[nodeName].last;
      } else if (obj[nodeName] is Map && !obj.keys.contains(nodeName)) {
        obj[nodeName] = <dynamic>[obj[nodeName], <dynamic, dynamic>{}];
        obj = obj[nodeName].last;
      } else if (!(entries ?? {}).containsValue(node.name.qualified)) {
        if (node.children.isEmpty) {
          if ((entries ?? {}).keys.contains(node.name.qualified)) {
            obj[nodeName] = [];
          } else {
            obj[nodeName] = null;
          }
        } else if (node.children[0] is XmlText ||
            node.children[0] is XmlCDATA) {
          _parseXmlTextNode(node, obj, nodeName, entries: entries);
        } else if (obj[nodeName] is Map) {
          var jsonCopy = json.decode(json.encode(obj[nodeName]));
          obj[nodeName] = <dynamic>[jsonCopy, <dynamic, dynamic>{}];
          obj = obj[nodeName].last;
        } else if (obj[nodeName] is List) {
          obj[nodeName].add(<dynamic, dynamic>{});
          obj = obj[nodeName].last;
        } else if ((entries ?? {}).containsKey(node.name.qualified)) {
          obj[nodeName] = <dynamic>[<dynamic, dynamic>{}];
          obj = obj[nodeName].last;
        } else {
          obj[nodeName] = <dynamic, dynamic>{};
          obj = obj[nodeName];
        }
      }

      for (var j = 0; j < node.children.length; j++) {
        _transform(node.children[j], obj, entries: entries);
      }
    } else if (node is XmlDocument) {
      for (var j = 0; j < node.children.length; j++) {
        _transform(node.children[j], obj, entries: entries);
      }
    }

    return obj;
  }

  /// Analyze the attribute value in the node
  void _parseAttrs(dynamic node, dynamic obj) {
    node.attributes.forEach((attr) {
      obj!['"_${_Xml2JsonUtils.escapeTextForJson(attr.name.qualified)}"'] =
          '"${_Xml2JsonUtils.escapeTextForJson(attr.value)}"';
    });
  }

  /// Parse XmlText node
  void _parseXmlTextNode(dynamic node, dynamic obj, dynamic nodeName,
      {Map<String, String?>? entries}) {
    final sanitisedNodeData =
        _Xml2JsonUtils.escapeTextForJson(node.children[0].text);
    var nodeData = '"$sanitisedNodeData"';
    if (nodeData.isEmpty) {
      nodeData = '';
    }
    var attrs = node.attributes;
    // Check for attributes in the start node
    if (attrs.isNotEmpty) {
      var objTemp = nodeData;
      if (obj[nodeName] is Map) {
        var jsonCopy = json.decode(json.encode(obj[nodeName]));
        obj[nodeName] = <dynamic>[jsonCopy, objTemp];
      } else if (obj[nodeName] is List) {
        obj[nodeName].add(objTemp);
      } else {
        obj[nodeName] = objTemp;
      }
    } else {
      if (obj[nodeName] is String) {
        obj[nodeName] = <dynamic>[obj[nodeName], nodeData];
      } else if (obj[nodeName] is List) {
        obj[nodeName].add(nodeData);
      } else {
        obj[nodeName] = nodeData;
      }
    }
    if ((entries ?? {}).keys.contains(node.name.qualified) &&
        obj[nodeName] is! List) {
      var jsonCopy = json.decode(json.encode(obj[nodeName]));
      obj[nodeName] = <dynamic>[jsonCopy];
    }
  }

  /// Transformer function
  String transform(XmlDocument? xmlNode, {Map<String, String?>? entries}) {
    Map<dynamic, dynamic>? json;
    try {
      json = _transform(xmlNode, <dynamic, dynamic>{}, entries: entries);
    } on Exception catch (e) {
      throw Xml2JsonException(
          'Parker with attrs internal transform error => ${e.toString()}');
    }

    return json.toString();
  }
}
