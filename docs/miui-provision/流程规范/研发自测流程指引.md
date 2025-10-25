---
layout: default
title: MIUI ADD: Feature_id
parent: MiuiProvision项目文档
---

FeatureID代码注释规范
时间
作者
更新
2023-2-6
胡於鑫huyuxin@xiaomi.com
创建文档
2023-2-9
陈文杰chenwenjie3@xiaomi.com
更新文档
Feature的定义
Feature是对功能的抽象描述，是一组代码新增、修改、问题修复的Change集合。即同一个Feature可能包含多笔不同类型，分布于不同仓库的Change。
通过Feature标识建立MIUI Feature的索引，实现MIUI Feature的有序管理，以及在 Android大版本升级中的可视化迁移。结合我米代码修改时，已有添加修改标识共识的基础Framework代码修改规范 落地细则如下:

FeatureID命名规范见【高密级】MIUI代码Feature级管理方案
代码注释格式要求
Feature应该足够抽象，单个问题的修复请勿创建新的Feature标识，避免标识泛滥，理想情况下单个业务组的Feature量应该控制在三位数以内。
注释参考每个编程语言的注释语法，下面的示例会列举一些常见的语言规则
注：makefile，python，shell等编程或脚本语言的注释是以#开始，而非//（或/*）

- MIUI ADD|MOD|DEL  <FEATUREID>与END <FEATUREID>成对出现，用来划定Feature的代码范围
- 每个新增文件在开始行与结束行需有成对的MIUI注释
- FeatureID注释允许嵌套出现，需满足成对要求，类似编程语言中的(){}成对要求
- 以前的多行注释中要求格式如下，现在开头和结尾总是成对出现的，所以废弃START
  // MIUI ADD/MOD/DEL: START
  // END
-  MIUI ADD: END 就像 {} () 他们总是成对出现的，即使在单行代码修改中
   新增文件
   // MIUI ADD: Feature_id
   import com.android.server;

package com.android.server.miui.services;

public class MyTestServices{
public MyTestServices(){
}
}


//END Feature_id

新增方法
java：
// MIUI ADD: Feature_id
/**
*
* 方法注释<optional>
  */
  void newMethod() {}
  // END Feature_id
  C/C++：
  // MIUI ADD: Feature_id
  /**
*
* 方法注释<optional>
  */
  void newMethod() {}
  // END Feature_id
  go：
  // MIUI ADD: Feature_id
  /**
*
* 方法注释<optional>
  */
  func newMethod() {}
  // END Feature_id
  Makefile(或.mk)：
# MIUI ADD: Feature_id
#方法注释<optional>
#
define newMethod
# END Feature_id

#下面这个是针对对define 关键字的定制化注释方法
define _apkcerts_write_line
$(eval # MIUI MOD: PORTING_050008) \
$(eval # $(hide) echo -n 'name="$(1).apk" certificate="$2" private_key="$3"' >> $6) \
$(hide) echo -n 'name="$(call _apkcerts_fixed_name,$1)" certificate="$2" private_key="$3"' >> $6 \
$(eval # END PORTING_050008) \
$(if $(4), $(hide) echo -n ' compressed="$4"' >> $6)
$(if $(5), $(hide) echo -n ' partition="$5"' >> $6)
$(hide) echo '' >> $6

endef
python：
# MIUI ADD: Feature_id
#
#方法注释<optional>
#
def newMethod():
# END Feature_id
shell：
同python的语法，都是#
xml:
 <!-- MIUI MOD|ADD|DEL: FeatureID -->  <!-- END FeatureID -->
    <!-- MIUI MOD: Power_PowerUiConfig -->
    <!-- <bool name="config_enableAutoPowerModes">false</bool> -->
    <bool name="config_enableAutoPowerModes">true</bool>
    <!-- END Power_PowerUiConfig -->

新增字段
// MIUI ADD: Feature_id
// 新增注释说明<optional>
int newField;
// END Feature_id
新增代码行
// MIUI ADD: Feature_id
// 新增注释说明<optional>
单行代码
// END Feature_id

// MIUI ADD: Feature_id
// 新增注释说明<optional>
多行代码
// END Feature_id
修改代码行
// MIUI MOD: Feature_id
// 新增注释说明<optional>
// 被修改的代码行 (请务必在注释中保留被修改的Google代码)
新代码行
// END Feature_id
修改多行代码
// MIUI MOD: Feature_id
// 新增注释说明<optional>
// 被修改的多行代码 (请务必在注释中保留被修改的Google代码)
新代码行
// END Feature_id
删除单行代码
// MIUI DEL: Feature_id
// 新增注释说明<optional>
// 单行代码 (请务必在注释中保留被删除的Google代码)
// END Feature_id
删除多行代码
// MIUI DEL: Feature_id
// 新增注释说明<optional>>
// 多行代码  (请务必在注释中保留被删除的Google代码)
// END Feature_id