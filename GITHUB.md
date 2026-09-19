# 用 GitHub Actions 编译

1. 去 github.com 新建一个空仓库（比如叫 `pte_track`）。
2. 把本目录所有文件 push 上去，包括 `.github/workflows/build.yml`。
3. 网页上点 **Actions** 标签，选 **Build pte_track.ko**，点 **Run workflow**。
4. 等 15~25 分钟（下载内核源码 + 编译）。
5. 跑完点进那次 run，底部 **Artifacts** 里下载 `pte_track-ko`，解压就是 `pte_track.ko`。
6. 把 `pte_track.ko` 推到手机，`sh insmod_pte.sh`。

## push 命令参考

```sh
cd pte_track_fixed
git init
git add .
git commit -m "pte_track fixed"
git branch -M main
git remote add origin https://github.com/<你的用户名>/pte_track.git
git push -u origin main
```

push 上去后 Actions 会自动跑一次，不用手动点。
