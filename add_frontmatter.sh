#!/bin/bash

# 为Android源码快速参考手册添加front matter
cat > docs/android-source/quick-reference.md.tmp << 'EOF'
---
layout: default
title: Android源码快速参考手册
parent: Android源码学习
nav_order: 2
---

EOF
cat docs/android-source/quick-reference.md >> docs/android-source/quick-reference.md.tmp
mv docs/android-source/quick-reference.md.tmp docs/android-source/quick-reference.md

# 为Activity启动流程分析添加front matter
cat > docs/android-source/activity-launch-analysis.md.tmp << 'EOF'
---
layout: default
title: Activity启动流程分析
parent: Android源码学习
nav_order: 3
---

EOF
cat docs/android-source/activity-launch-analysis.md >> docs/android-source/activity-launch-analysis.md.tmp
mv docs/android-source/activity-launch-analysis.md.tmp docs/android-source/activity-launch-analysis.md

# 为Jira问题分析标准流程添加front matter
cat > docs/jira/analysis-process.md.tmp << 'EOF'
---
layout: default
title: Jira问题分析标准流程
parent: 问题分析
nav_order: 1
---

EOF
cat docs/jira/analysis-process.md >> docs/jira/analysis-process.md.tmp
mv docs/jira/analysis-process.md.tmp docs/jira/analysis-process.md

# 为Settings编译脚本使用说明添加front matter
cat > docs/tools/settings-build-script.md.tmp << 'EOF'
---
layout: default
title: Settings编译脚本使用说明
parent: 开发工具
nav_order: 1
---

EOF
cat docs/tools/settings-build-script.md >> docs/tools/settings-build-script.md.tmp
mv docs/tools/settings-build-script.md.tmp docs/tools/settings-build-script.md

# 为源码分析工具集添加front matter
cat > docs/tools/source-analysis-tools.md.tmp << 'EOF'
---
layout: default
title: 源码分析工具集
parent: 开发工具
nav_order: 2
---

EOF
cat docs/tools/source-analysis-tools.md >> docs/tools/source-analysis-tools.md.tmp
mv docs/tools/source-analysis-tools.md.tmp docs/tools/source-analysis-tools.md

echo "✅ 所有文档已添加front matter"

