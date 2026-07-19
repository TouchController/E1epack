"""数据包测试系统。

此模块生成按 Minecraft 版本拆分的测试目标，包括：
- 测试目录版本匹配
- 自动测试 runner 生成
- test / test_major / test_all 测试套件
"""

load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_pkg//pkg:mappings.bzl", "pkg_files", "pkg_filegroup")
load("@rules_pkg//pkg:zip.bzl", "pkg_zip")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load(":minecraft_versions.bzl", "ALL_MINECRAFT_VERSIONS", "compare_versions")

def _is_version_str(s):
    """检查字符串是否仅含数字和点。"""
    return len(s) > 0 and all([c in "0123456789." for c in s.elems()])

def _version_ge(a, b):
    """a >= b，如 '1.20.3' >= '1.20'。"""
    return compare_versions(a, b) >= 0

def _test_dir_matches(dir_name, version):
    """检查版本目录是否匹配目标 MC version。"""
    if dir_name == "common":
        return True
    if "-" in dir_name:
        parts = dir_name.split("-", 1)
        lo, hi = parts[0], parts[1]
        if lo and not _is_version_str(lo):
            return False
        if hi and not _is_version_str(hi):
            return False
        if lo and hi:
            if not _version_ge(hi, lo):
                fail("Inverted version range in test directory '%s': %s > %s" % (dir_name, lo, hi))
            return _version_ge(version, lo) and _version_ge(hi, version)
        elif lo:
            return _version_ge(version, lo)
        else:
            return _version_ge(hi, version)
    elif _is_version_str(dir_name):
        return dir_name == version
    return False

# 共享 server java_binary 配置
SERVER_JVM_FLAGS = [
    "-Ddev.launch.type=server",
    "-Xmx4G",
]
SERVER_MAIN_CLASS = "top.fifthlight.fabazel.devlaunchwrapper.DevLaunchWrapper"

def _make_sh_test(d_ver, v, test_ns, rcon_port, ns_args, names, name_suffix, env = None):
    """创建单个版本的 sh_test 目标。"""
    sh_test(
        name = name_suffix,
        srcs = ["//rule/tools/test_runner:run_test.sh"],
        args = [
            "$(rootpath :test_server_%s)" % d_ver,
            "$(rootpath //rule/tools/test_runner:TestRunner)",
            "--version",
            v,
            "--rcon-port",
            str(rcon_port),
            "--test-ns", test_ns,
        ] + ns_args + names,
        data = [
            ":test_server_%s" % d_ver,
            "//rule/tools/test_runner:TestRunner",
        ],
        env = env or {},
        timeout = "moderate",
        size = "large",
    )

def setup_tests(
        pack_id,
        target_name,
        game_versions,
        segments,
        ignore_error_ns = []):
    """为 game_versions 中的每个版本创建测试目标。"""
    test_ns = pack_id + "-test"
    ns_args = [arg for ns in ignore_error_ns for arg in ("--ignore-error-ns", ns)]
    test_files = native.glob(["data/%s/function/*/*.mcfunction" % test_ns], allow_empty = True)

    # 解析 {version_dir: [(dir, name, path), ...]}
    entries = {}
    for f in test_files:
        parts = f.split("/")
        d = parts[-2]
        n = parts[-1][:-len(".mcfunction")]
        entries.setdefault(d, []).append((d, n, f))

    # 按段索引找每个 version 对应的 datapack zip 所属 segment
    _ver_to_seg = {}
    for _i, seg in enumerate(segments):
        _, seg_vers, _ = seg
        for v in seg_vers:
            _ver_to_seg[v] = seg[0]

    for v in game_versions:
        port_idx = ALL_MINECRAFT_VERSIONS.index(v)
        game_port = 49152 + port_idx * 2
        rcon_port = 49152 + port_idx * 2 + 1
        filtered = [(dir_name, n, f) for dir_name, test_list in entries.items() if _test_dir_matches(dir_name, v) for dir_name, n, f in test_list]
        names = [d + "/" + n for d, n, _f in filtered]

        # 打包：除明确不匹配的版本目录外，所有文件都包含
        test_func_files = []
        for f in test_files:
            d = f.split("/")[-2]
            if d == "common" or _test_dir_matches(d, v):
                test_func_files.append(f)
            elif not _is_version_str(d) and "-" not in d:
                test_func_files.append(f)  # 非版本目录（helper 等）

        # Runner genrule
        native.genrule(
            name = "test_runner_" + v,
            srcs = ["//template:test_runner.mcf"],
            tools = ["//rule:generate_test_runner"],
            outs = ["test_runner/" + v + "/_test_runner.mcfunction"],
            cmd = "mkdir -p $(@D) && $(location //rule:generate_test_runner) " +
                  "--template $(location //template:test_runner.mcf) " +
                  "--namespace " + test_ns + " --out $@ -- " +
                  " ".join(["'" + n + "'" for n in names]),
        )

        # Test namespace zip
        test_components = []
        for suffix, suffix_name in [("function", "singular"), ("functions", "plural")]:
            pkg_files(
                name = "test_function_files_" + suffix_name + "_" + v,
                srcs = test_func_files,
                prefix = "data/" + test_ns + "/" + suffix,
                strip_prefix = "data/" + test_ns + "/function",
            )
            test_components.append(":test_function_files_" + suffix_name + "_" + v)

            # Runner
            pkg_files(
                name = "test_runner_function_files_" + suffix_name + "_" + v,
                srcs = [":test_runner_" + v],
                prefix = "data/" + test_ns + "/" + suffix,
                strip_prefix = "test_runner/" + v,
            )
            test_components.append(":test_runner_function_files_" + suffix_name + "_" + v)

        pkg_filegroup(
            name = "test_datapack_files_" + v,
            srcs = test_components,
        )
        pkg_zip(
            name = "test_datapack_" + v,
            srcs = [":test_datapack_files_" + v, "//template:mcmeta"],
        )

        # 对应的 datapack zip
        range_name = _ver_to_seg.get(v)
        if range_name == None:
            fail("version %s is not in any segment" % v)

        # test_server
        java_binary(
            name = "test_server_" + v,
            srcs = [],
            data = [
                ":" + range_name,
                ":test_datapack_" + v,
                "//game:ops_json",
            ],
            jvm_flags = [
                "-Ddev.launch.version=%s" % v,
                "-Ddev.launch.mainClass=%s" % ("net.minecraft.server.MinecraftServer" if compare_versions(v, "1.16") < 0 else "net.minecraft.server.Main"),
            ] + SERVER_JVM_FLAGS + [
                "-Ddev.launch.rconPort=%d" % rcon_port,
                "-Ddev.launch.gamePort=%d" % game_port,
            ] + [
                "-Ddev.launch.copyFiles=" +
                "$(rlocationpath //%s:%s):world/datapacks/main.zip," % (native.package_name(), range_name) +
                "$(rlocationpath //%s:test_datapack_%s):world/datapacks/test.zip," % (native.package_name(), v) +
                "$(rlocationpath //game:ops_json):ops.json",
            ],
            main_class = SERVER_MAIN_CLASS,
            runtime_deps = [
                "//game:server_" + v.replace(".", "_"),
                "//rule/tools/dev_launch_wrapper",
                "@minecraft//:%s_server_libraries" % v,
            ],
        )

        _make_sh_test(v, v, test_ns, rcon_port, ns_args, names, "test_verbose_" + v, {"TEST_VERBOSE": "1"})
        _make_sh_test(v, v, test_ns, rcon_port, ns_args, names, "test_quiet_" + v)

    # 收集所有安静版测试目标（供批量测试）
    _quiet = [":test_quiet_" + v for v in game_versions]

    # :test — 最新版本（verbose，实时输出服务器日志）
    native.test_suite(
        name = "test",
        tests = [":test_verbose_" + game_versions[-1]],
    )

    # :test_major — 每个大版本（X.Y）+ 最新版本（安静）
    # Starlark 无 set 类型，用 dict 做 O(1) 去重
    _major = {}
    for v in game_versions:
        if len(v.split(".")) == 2:
            _major[v] = True
    _major[game_versions[-1]] = True
    _major_tests = [":test_quiet_" + v for v in _major.keys()]
    native.test_suite(
        name = "test_major",
        tests = _major_tests,
    )

    # :test_all — 全部版本（安静）
    native.test_suite(
        name = "test_all",
        tests = _quiet,
    )
