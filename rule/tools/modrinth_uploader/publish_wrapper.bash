#!/bin/bash

# A wrapper script to call the Java side modrinth uploader, and to finish the
# release locally (Git tag + GitHub Release).
#
# 以 `@rlocation:<repo 相对路径>` 形式传入的文件路径会在这里解析成 runfiles 中的
# 真实路径；由 `--upload` 分隔的多个上传项会在同一个 Java 进程里依次上传。
# 全部上传成功之后，会在工作区里创建并推送 Git 标签，再用系统 `gh` 创建
# GitHub Release（附件为该目标的全部产物）。

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
 source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
 source "$0.runfiles/$f" 2>/dev/null || \
 source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
 source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
 { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

workspace_name='{WORKSPACE_NAME}'

# 所有需要定位的路径都写成 @rlocation:<repo 相对路径>，只在这里解析一次
resolve_path() {
    rlocation "$workspace_name/${1#@rlocation:}"
}

# 这些取值可能包含引号，统一用 heredoc 读入，避免拼进单引号字符串后破坏脚本
IFS= read -r git_tag_name <<'GIT_TAG_NAME_VALUE'
{GIT_TAG_NAME}
GIT_TAG_NAME_VALUE
IFS= read -r discussion_category <<'DISCUSSION_CATEGORY_VALUE'
{DISCUSSION_CATEGORY}
DISCUSSION_CATEGORY_VALUE
auto_tag='{AUTO_TAG}'
github_release='{GITHUB_RELEASE}'
release_notes_arg='{RELEASE_NOTES_PATH}'

exec_path="$(resolve_path '{EXEC_PATH}')"

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT
cat >"$TEMP_FILE" <<'MODRINTH_UPLOAD_ARG_FILE'
{ARGS}
MODRINTH_UPLOAD_ARG_FILE
readarray -t raw_args <"$TEMP_FILE"
rm "$TEMP_FILE"

args=()
for arg in "${raw_args[@]}"; do
    if [ -z "$arg" ]; then
        continue
    fi
    case "$arg" in
    @rlocation:*)
        args+=("$(resolve_path "$arg")")
        ;;
    *)
        args+=("$arg")
        ;;
    esac
done

# GitHub Release 的附件：本目标产出的全部文件
release_assets=()
while IFS= read -r asset_path; do
    if [ -n "$asset_path" ]; then
        release_assets+=("$(resolve_path "$asset_path")")
    fi
done <<'GITHUB_RELEASE_ASSET_LIST'
{RELEASE_ASSETS}
GITHUB_RELEASE_ASSET_LIST

release_notes_path=""
if [ -n "$release_notes_arg" ]; then
    release_notes_path="$(resolve_path "$release_notes_arg")"
fi

# ---------------------------------------------------------------------------
# 发布前置校验
#
# Modrinth 上传不可回滚，所以所有只读检查都必须在真正上传之前完成，
# 否则校验失败时远端已经多出一个版本，而重跑会被重复版本检查拦下。
# ---------------------------------------------------------------------------

# 后面的 Git / GitHub 操作必须在工作区里执行：`bazel run` 会把当前目录设为
# runfiles 目录，那里不是 Git 仓库。
if [ -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]; then
    echo >&2 "ERROR: BUILD_WORKSPACE_DIRECTORY 未设置，请通过 'bazel run' 执行本目标"
    exit 1
fi
cd "$BUILD_WORKSPACE_DIRECTORY"

# 产物由工作区构建，标签却指向 HEAD：两者必须一致，否则发布内容与标签语义不符
if [ -n "$(git status --porcelain)" ]; then
    echo >&2 "ERROR: 工作区存在未提交改动，构建产物与将要打标签的提交不一致，请先提交后再发布"
    git status --short >&2
    exit 1
fi

head_commit="$(git rev-parse HEAD)"

# 标签打在 HEAD 上：这个提交必须已经在远端，否则推送标签会把一个游离提交带到远端
if ! git fetch --quiet origin; then
    echo >&2 "ERROR: 无法从 origin 获取最新引用，无法确认 HEAD 是否已在远端"
    exit 1
fi
if ! git branch -r --contains "$head_commit" | grep -q '[^[:space:]]'; then
    echo >&2 "ERROR: HEAD ${head_commit:0:12} 尚未推送到 origin；标签会指向远端不存在的提交，请先推送后再发布"
    exit 1
fi

# 标签若已存在，必须正好指向 HEAD，否则复用它会让发布内容与标签对不上
if [ -n "$auto_tag" ] && [ -n "$git_tag_name" ]; then
    if existing_commit="$(git rev-list -n 1 "$git_tag_name" 2>/dev/null)"; then
        if [ "$existing_commit" != "$head_commit" ]; then
            echo >&2 "ERROR: 标签 '$git_tag_name' 已存在且指向 ${existing_commit:0:12}，与当前 HEAD ${head_commit:0:12} 不一致"
            exit 1
        fi
    fi
fi

# gh 只在真正要建 Release 时才必须存在；发布说明必须能从 runfiles 解析出来
if [ -n "$github_release" ]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo >&2 "ERROR: 未找到 gh CLI，无法创建 GitHub Release"
        exit 1
    fi
    if [ -z "$release_notes_path" ]; then
        echo >&2 "ERROR: 无法解析发布说明文件：$release_notes_arg"
        exit 1
    fi
fi

echo "HEAD ${head_commit:0:12} 已通过发布前检查"

# ---------------------------------------------------------------------------
# 上传到 Modrinth（不可回滚的一步）
# ---------------------------------------------------------------------------

# java launcher 只认 JAVA_RUNFILES，并会在这个目录下找 _main/，自己不会去搜
# RUNFILES_DIR；这里用本次 bazel run 构造出的 runfiles 根，不依赖当前目录
if [ -n "${RUNFILES_DIR:-}" ]; then
    JAVA_RUNFILES="$RUNFILES_DIR"
elif [ -d "$0.runfiles" ]; then
    JAVA_RUNFILES="$(cd "$0.runfiles" && pwd)"
else
    echo >&2 "ERROR: 无法定位 runfiles 目录（RUNFILES_DIR 未设置且 $0.runfiles 不存在）"
    exit 1
fi
export JAVA_RUNFILES

"$exec_path" "${args[@]}"

# ---------------------------------------------------------------------------
# 全部上传成功之后：打标签、推送标签、创建 GitHub Release
# ---------------------------------------------------------------------------

if [ -n "$auto_tag" ] && [ -n "$git_tag_name" ]; then
    if git rev-list -n 1 "$git_tag_name" >/dev/null 2>&1; then
        echo "Git tag '$git_tag_name' already exists at HEAD, reusing it"
    else
        git tag "$git_tag_name"
        echo "Git tag '$git_tag_name' created"
    fi

    echo "Pushing Git tag to origin..."
    if ! git push origin "$git_tag_name"; then
        echo >&2 "ERROR: 推送标签 '$git_tag_name' 失败；已跳过 GitHub Release，避免 GitHub 在默认分支上自建同名标签"
        exit 1
    fi
    echo "Git tag '$git_tag_name' pushed"
fi

if [ -n "$github_release" ]; then
    if gh release view "$git_tag_name" >/dev/null 2>&1; then
        echo "GitHub Release '$git_tag_name' already exists, syncing assets"
    else
        echo "Creating GitHub Release: $git_tag_name"
        created=0
        if [ -n "$discussion_category" ]; then
            if gh api --method POST "repos/{owner}/{repo}/releases" \
                -f "tag_name=$git_tag_name" \
                -f "name=$git_tag_name" \
                -f "target_commitish=$head_commit" \
                -F "body=@$release_notes_path" \
                -f "discussion_category_name=$discussion_category" >/dev/null 2>&1; then
                created=1
            elif gh release view "$git_tag_name" >/dev/null 2>&1; then
                # 请求其实已在服务端生效（例如响应超时），重发只会拿到 422
                echo "GitHub Release '$git_tag_name' was created despite the error, continuing"
                created=1
            else
                echo >&2 "Warning: 带 Discussion 分类 '$discussion_category' 创建失败，改为不带分类重试"
            fi
        fi
        if [ "$created" -eq 0 ]; then
            gh api --method POST "repos/{owner}/{repo}/releases" \
                -f "tag_name=$git_tag_name" \
                -f "name=$git_tag_name" \
                -f "target_commitish=$head_commit" \
                -F "body=@$release_notes_path" >/dev/null
        fi
    fi

    if [ ${#release_assets[@]} -gt 0 ]; then
        # --clobber 允许覆盖同名附件，使重跑能补齐上次中断的附件
        gh release upload "$git_tag_name" "${release_assets[@]}" --clobber
    fi
    echo "GitHub Release '$git_tag_name' is up to date"
fi

echo "Publish completed"
