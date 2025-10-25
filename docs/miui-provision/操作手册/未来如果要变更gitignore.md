---
layout: default
title: 取消skip-worktree标记
parent: 操作手册
---



如果将来需要提交.gitignore（罕见情况）
如果未来某天需要修改并提交.gitignore到远程，只需执行：
现在你可以放心地在本地.gitignore中添加个人的ignore规则了，完全不会影响分支切换！


# 取消skip-worktree标记
git update-index --no-skip-worktree .gitignore

# 然后正常提交
git add .gitignore
git commit -m "update: .gitignore"

# 提交后重新设置（如果还需要个人规则）
git update-index --skip-worktree .gitignore
