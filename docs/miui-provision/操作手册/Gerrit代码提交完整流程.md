---
layout: default
title: Gerrit代码提交完整流程
parent: 操作手册
---



# Gerrit代码提交完整流程

## 目录
- [前置准备](#前置准备)
- [完整提交流程](#完整提交流程)
- [Commit Message规范](#commit-message规范)
- [常见问题及解决方案](#常见问题及解决方案)
- [注意事项清单](#注意事项清单)

---

## 前置准备

### 1. 确认Git配置
```bash
# 查看用户信息
git config user.name
git config user.email

# 如需修改（不建议在小米项目中修改）
# git config user.name "your-name"
# git config user.email "your-email@xiaomi.com"
```

### 2. 准备工作环境
- 确保在正确的工作目录：`/mnt/01_lixin_workspace/miui_apps/MiuiProvisionAosp`
- 确认当前分支和状态：`git status`
- 拉取最新代码：`git fetch origin`

---

## 完整提交流程

### 步骤1: 代码开发与本地提交

#### 1.1 修改代码
完成功能开发或Bug修复。

#### 1.2 查看修改
```bash
# 查看修改的文件
git status

# 查看具体修改内容
git diff
git diff <file_path>
```

#### 1.3 添加到暂存区
```bash
# 添加指定文件
git add <file1> <file2>

# 或添加所有修改（谨慎使用）
git add .
```

#### 1.4 提交到本地仓库
```bash
# 提交（必须包含Signed-off-by签名）
git commit -s -m "commit message"

# 或使用--signoff参数
git commit --signoff -m "commit message"
```

**重要**：`-s` 或 `--signoff` 参数会自动添加 `Signed-off-by: Your Name <your-email@xiaomi.com>`

### 步骤2: 编写符合规范的Commit Message

#### 2.1 Commit Message模板
参考 `/docs/规范/Jira_comment_temp.md`

```
[BugFix] 简短标题（不超过50字符）

BUGOS2-xxxxx

[RootCause]
问题描述：简要描述问题现象
根本原因：深入分析的根本原因

[Modify]
1. 文件1: 修改内容说明
2. 文件2: 修改内容说明
3. ...

[Test] 测试用例如下
测试环境：机型、系统版本、Android版本
测试步骤：
1. 步骤1
2. 步骤2
3. ...
测试结果：预期的测试结果

Signed-off-by: Your Name <your-email@xiaomi.com>
```

#### 2.2 标签类型说明
- `[BugFix]`: Bug修复
- `[Feature]`: 新功能开发
- `[Refactor]`: 代码重构
- `[Optimize]`: 性能优化
- `[Test]`: 测试相关

### 步骤3: 创建独立分支（重要！）

为了确保提交不依赖其他本地未合入的提交，必须基于远程分支创建新分支：

```bash
# 1. 拉取最新远程代码
git fetch origin

# 2. 基于远程分支创建新的bugfix分支
git checkout -b bugfix/BUGOS2-xxxxx origin/master-25q2

# 3. Cherry-pick你的提交到新分支
git cherry-pick <your-commit-hash>

# 4. 确认新分支只包含1个提交
git log --oneline -3
```

**为什么要这样做？**
- 确保你的提交独立，不依赖其他未合入的本地提交
- 避免提交到Gerrit时带入不相关的修改
- 便于Code Review和后续合入

### 步骤4: 推送到Gerrit

#### 4.1 标准推送命令
```bash
# 推送到Gerrit审查队列
git push origin <local-branch>:refs/for/<target-branch>

# 例如：
git push origin bugfix/BUGOS2-244410:refs/for/master-25q2
```

#### 4.2 推送成功标志
```
remote: SUCCESS
remote: 
remote:   https://gerrit.pt.mioffice.cn/c/.../+/XXXXXX [标题] [NEW]
```

#### 4.3 记录Gerrit Change ID
保存返回的Gerrit链接，用于后续跟踪和更新。

### 步骤5: 如果需要修改提交

#### 5.1 修改最近一次提交
```bash
# 修改代码后，追加到上次提交
git add <files>
git commit --amend --no-edit

# 或修改commit message
git commit --amend

# 添加签名（如果缺失）
git commit --amend --signoff --no-edit
```

#### 5.2 重新推送到Gerrit
```bash
# 相同的命令，Gerrit会识别Change-Id并更新
git push origin <local-branch>:refs/for/<target-branch>
```

---

## Commit Message规范

### 必须包含的元素

1. **标题行**: `[类型] 简短描述`
   - 不超过50个字符
   - 清晰描述本次修改的主要内容

2. **Jira单号**: `BUGOS2-xxxxx`
   - 必须是有效的Jira问题单号
   - 便于问题追溯

3. **RootCause部分**:
   - 问题描述：用户视角的问题现象
   - 根本原因：技术视角的深层原因

4. **Modify部分**:
   - 列出所有修改的文件和修改内容
   - 使用编号列表（1. 2. 3...）

5. **Test部分**:
   - 测试环境：机型、系统版本等
   - 测试步骤：具体的操作步骤
   - 测试结果：预期的结果

6. **Signed-off-by**: `Signed-off-by: Name <email>`
   - **必须包含**，否则Gerrit检查不通过
   - 使用 `git commit -s` 或 `--signoff` 自动添加

### 示例

```
[BugFix] 修复开机引导尾页关闭TalkBack时闪屏问题

BUGOS2-244410

[RootCause]
问题描述：开机引导流程在尾页通过音量键快捷方式关闭TalkBack时，出现明显的闪黑现象。
根本原因：DefaultActivity的android:configChanges中缺少uiMode配置，导致关闭TalkBack触发uiMode Configuration Change时，系统强制重建Activity，在Window销毁和重建过程中产生闪黑效果。

[Modify]
1. AndroidManifest.xml: 在DefaultActivity的configChanges中添加uiMode，防止Activity重建
2. DefaultActivity.java: 实现onConfigurationChanged方法，手动处理uiMode变化并刷新View以确保UI渲染完整

[Test] 测试用例如下
测试环境：O81 (Xiaomi Pad 7 Pro), OS2.0.241111.1.VOYCNXM.STABLE-TEST, Android 15
测试步骤：
1. 恢复出厂设置
2. 进入开机引导流程
3. 完成所有步骤到达尾页（欢迎页）
4. 确保TalkBack已开启
5. 同时按住音量+和音量-键约3秒（触发TalkBack快捷方式）
6. 观察屏幕是否有闪黑现象
测试结果：关闭TalkBack时UI保持稳定，无闪黑现象，Toast正常弹出不影响用户体验

Signed-off-by: v-lixin88 <v-lixin88@xiaomi.com>
```

---

## 常见问题及解决方案

### 问题1: 缺少Signed-off-by签名

**错误信息**：
```
'Signed-off-by: 'should be included. Commit Message
```

**解决方案**：
```bash
# 为最近一次提交添加签名
git commit --amend --signoff --no-edit

# 重新推送
git push origin <branch>:refs/for/master-25q2
```

### 问题2: 提交依赖其他未合入的提交

**现象**：
- 推送到Gerrit时带入了多个提交
- Gerrit显示依赖关系链

**解决方案**：
```bash
# 1. 查看当前提交历史
git log --oneline -5

# 2. 找到你的提交的commit hash
YOUR_COMMIT_HASH=xxx

# 3. 基于远程分支创建新分支
git checkout -b bugfix/new-branch origin/master-25q2

# 4. Cherry-pick你的提交
git cherry-pick $YOUR_COMMIT_HASH

# 5. 确认只有一个提交
git log --oneline -3

# 6. 推送到Gerrit
git push origin bugfix/new-branch:refs/for/master-25q2
```

### 问题3: Change-Id冲突

**错误信息**：
```
remote: ERROR: commit XXXXXX: duplicate Change-Id in destination branch
```

**解决方案**：
```bash
# 1. 移除旧的Change-Id
git commit --amend

# 2. 手动编辑commit message，删除Change-Id行
# 3. 保存退出

# 4. 重新生成Change-Id
# Gerrit会自动生成新的Change-Id

# 5. 推送
git push origin <branch>:refs/for/master-25q2
```

### 问题4: Commit Message格式错误

**错误信息**：
```
Commit-MSG-Check-1 by gerrit-admin (failed)
```

**解决方案**：
```bash
# 1. 修改commit message
git commit --amend

# 2. 按照模板重新编写commit message
# 确保包含：[标签]、Jira单号、[RootCause]、[Modify]、[Test]、Signed-off-by

# 3. 保存退出并推送
git push origin <branch>:refs/for/master-25q2
```

### 问题5: 推送权限问题

**错误信息**：
```
Permission denied (publickey)
```

**解决方案**：
```bash
# 1. 检查SSH密钥
ssh -T gerrit.pt.mioffice.cn -p 29418

# 2. 如果失败，配置SSH密钥
# 在Gerrit网站上添加你的公钥
```

---

## 注意事项清单

### 提交前检查（必做）

- [ ] **代码编译通过**：确保没有语法错误
  ```bash
  # 可选：本地编译测试
  ./gradlew build
  ```

- [ ] **Lint检查通过**：无新增的Lint错误
  ```bash
  # 使用Cursor的read_lints工具检查
  ```

- [ ] **功能自测通过**：按照测试步骤验证修改有效

- [ ] **代码格式规范**：符合项目代码风格

- [ ] **没有调试代码**：移除临时的Log、注释等

### Commit Message检查（必做）

- [ ] **包含正确的标签**：[BugFix]、[Feature]等
- [ ] **包含有效的Jira单号**：BUGOS2-xxxxx格式
- [ ] **包含RootCause部分**：问题描述和根本原因
- [ ] **包含Modify部分**：列出所有修改
- [ ] **包含Test部分**：测试环境、步骤、结果
- [ ] **包含Signed-off-by**：签名行（使用-s参数自动添加）
- [ ] **标题不超过50字符**
- [ ] **描述清晰准确**：便于Code Review

### 推送前检查（必做）

- [ ] **基于最新远程分支**：避免合并冲突
  ```bash
  git fetch origin
  ```

- [ ] **只包含一个提交**：确保提交独立
  ```bash
  git log --oneline -3
  ```

- [ ] **没有依赖其他未合入提交**

- [ ] **目标分支正确**：通常是master-25q2

- [ ] **使用正确的推送命令**：
  ```bash
  git push origin <branch>:refs/for/<target-branch>
  ```

### 推送后操作（建议）

- [ ] **访问Gerrit链接**：确认Change已创建

- [ ] **添加Reviewer**：添加合适的审查人

- [ ] **关联Jira**：在Jira单上添加Gerrit链接

- [ ] **通知相关人员**：如有需要，通知测试/审查人员

---

## 快速参考命令

### 标准提交流程（一行命令版）
```bash
# 假设代码已修改完成

# 1. 添加文件
git add <files>

# 2. 提交（带签名）
git commit -s -m "[BugFix] 简短描述

BUGOS2-xxxxx

[RootCause]
问题描述：...
根本原因：...

[Modify]
1. ...

[Test] 测试用例如下
测试环境：...
测试步骤：
1. ...
测试结果：..."

# 3. 创建独立分支
git fetch origin
git checkout -b bugfix/BUGOS2-xxxxx origin/master-25q2
git cherry-pick HEAD@{1}

# 4. 推送到Gerrit
git push origin bugfix/BUGOS2-xxxxx:refs/for/master-25q2
```

### 修改提交后重新推送
```bash
# 1. 修改代码
git add <files>

# 2. 追加到上次提交（保持Change-Id）
git commit --amend --no-edit

# 3. 重新推送（会更新同一个Change）
git push origin <branch>:refs/for/master-25q2
```

### 添加签名到已有提交
```bash
git commit --amend --signoff --no-edit
git push origin <branch>:refs/for/master-25q2
```

---

## 相关文档

- **Commit Message模板**: `/docs/规范/Jira_comment_temp.md`
- **Gerrit提交管控规则**: `/docs/规范/Gerrit提交change管控规则v1.1.md`
- **Jira问题分析流程**: `/docs/规范/Jira问题标准分析流程.md`

---

## 最佳实践建议

### 1. 提交粒度
- **一个提交只做一件事**：不要在一个提交中混合多个不相关的修改
- **功能完整**：提交的代码应该是可编译、可测试的完整功能

### 2. 提交频率
- **本地频繁提交**：开发过程中可以频繁提交到本地
- **推送前整理**：使用 `git rebase -i` 整理提交历史
- **一个功能一个Change**：推送到Gerrit时保持一个功能/Bug对应一个Change

### 3. 分支管理
- **功能分支命名规范**：
  - Bug修复：`bugfix/BUGOS2-xxxxx`
  - 新功能：`feature/功能名称`
  - 重构：`refactor/模块名称`

- **及时清理本地分支**：合入后删除本地分支
  ```bash
  git branch -D bugfix/BUGOS2-xxxxx
  ```

### 4. Code Review
- **及时响应评审意见**：收到评审意见后尽快修改
- **修改后更新Change**：使用 `git commit --amend` 保持同一个Change
- **主动沟通**：有疑问及时与Reviewer沟通

### 5. 测试验证
- **自测充分**：推送前完成充分的功能测试
- **回归测试**：确保修改不影响其他功能
- **真机测试**：重要修改在真机上验证

---

**文档版本**: v1.0  
**创建时间**: 2025-10-16  
**维护人**: 李新  
**更新记录**:
- 2025-10-16: 初始版本，包含完整提交流程和常见问题
