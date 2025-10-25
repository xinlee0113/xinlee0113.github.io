---
layout: default
title: Gerrit提交change管控规则v1.1
parent: MiuiProvision项目文档
---

Commit Message格式规范
Commit Message模板
----------------------------- commit message format -----------------------------
#Line 1:  [where] [what] -- [类型][模块] change描述，限制160个字符
#Line 2:  [空行]
#Line 3:  [Jira ID] -- 有效Jira ID且Jira中包含该提交的 4-W 要素，以及问题影响及测试方法
#Line 4:  [空行]
#Line 5:  [what]/[why] -- 描述问题的根本原因、修改的思路，每行限制100个字符，可换行
#Line x:  ... -- 接上一行的描述，或者为空行
#Signed-off-by: [who] -- 提交者（提交时自动生成）
#Change-Id: [Change id] -- 同一组Review的change的标识
------------------------- end of commit message format -------------------------
Commit Message示例
Commit Message Sample

JIRA-ID

This is an example that conforms to the commit message format specification.
Please follow it.

Signed-off-by: xxx<xxx@xiaomi.com>
Change-Id: xxxxxxxx
CMC规则说明
[] Change描述不超过160个字符
[] 如果有需要关联的JIRA，引用的JIRA必须规范、真实、有效（具体细则请看下文的引用JIRA规范)
[] 包含Signed-off-by信息
若未通过上述的CMC校验，gerrit将执行 Commit-MSG-Check -1 的操作，可通过以下方式去除：
1. 若已修正commit message的信息并保存，系统会重新[自动]触发CMC，通过校验即可去除 Commit-MSG-Check -1 的标签；
2. 若在JIRA系统中更新JIRA，在Gerrit提交时需要通过更新patch set来[手动]触发CMC，包含以下方式：
1. 更新原代码：在线编辑或本地编辑后上传到服务器上；
2. 执行rebase；
3. 在线编辑Commit message并保存（如果不知道改什么，可以像下图操作一样在标题行尾添加空格）

[图片]
[图片]


引用JIRA规范
1. OS2及以上的项目，JIRA必须是新JIRA库，OS1及更早的项目新库旧库都可以进。
2. 所有手机项目的change，都必须填JIRA。检查条件如下：
   检查项
   检查条件
   备注
   JIRA ID
   [] JIRA ID的填写位置符合Commit Message的要求
   留意JIRA ID所在行中是否有多余的空格/空行;
   注意区分-和_、0和O;

[] JIRA ID满足^[A-Z]+[A-Z0-9]*-\d+$的正则表达式


[] JIRA ID一行支持多个，使用英文冒号:分割
多个JIRA ID时检查是否为英文冒号。

[] JIRA真实存在于新JIRA库或老JIRA库

JIRA 类型

[] Requirement类型的新JIRA不能直接用于提交change
对于此类Requirement，请使用Task类型的JIRA。
新JIRA库说明

[] 保密分支的提交必须使用保密JIRA(MIUI15)

JIRA 状态
新JIRA:
[] 可进change的Feature状态包括：Open/Testing/Integrating
[] 可进change的Bug状态包括：Open/In Progress/Resolved/Verified
若为Task类型的JIRA：
- 关联的为Feature，则与Feature的规则一致；
- 关联的为Bug，则与Bug的规则一致。

老JIRA:
[] MIUI15的JIRA状态必须是Integrating或Master Integrating
[] 其他JIRA状态不能是Done或Closed
Feature分支新功能开发&测试培训材料

Manifest-Sanity-Check 检查规范
Manifest-Sanity-Check 检查规范

其他规则
锁库期间禁止进change, 如有问题请联系适配组同学。
