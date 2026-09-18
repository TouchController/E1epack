package top.fifthlight.fabazel.modrinthuploader;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.mizosoft.methanol.MediaType;
import com.github.mizosoft.methanol.MoreBodyPublishers;
import com.github.mizosoft.methanol.MultipartBodyPublisher;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class ModrinthUploader {
    private static final String VERSION_API = "https://api.modrinth.com/v2/version";
    private static final String PROJECT_API = "https://api.modrinth.com/v2/project";

    // Modrinth 要求请求带上可唯一识别调用方的 User-Agent，格式建议 github_username/project_name
    private static final String USER_AGENT = "TouchController/E1epack";

    /** 块起始符：这两类参数各自携带一组从属参数。 */
    private static final List<String> BLOCK_STARTERS = List.of("--upload", "--dependency");

    /**
     * 单个待上传的版本。一次运行可以携带多个条目，它们会在同一个进程里依次上传。
     */
    private record UploadEntry(
            String filePath,
            String fileName,
            String versionName,
            List<String> gameVersions
    ) {
    }

    /** 整批上传共用的参数。 */
    private record BatchOptions(
            String tokenSecretId,
            String projectId,
            String versionId,
            String versionType,
            String changelogPath,
            List<String> loaders,
            List<ModrinthUploadData.Dependency> dependencies
    ) {
    }

    public static void main(String[] args) throws IOException, InterruptedException {
        var root = (Logger) LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.INFO);

        var rawArgs = new ArrayList<String>();
        for (var arg : args) {
            if (!arg.isEmpty()) {
                // 参数经 heredoc 传递，可能出现空行
                rawArgs.add(arg);
            }
        }

        // 先按块起始符切分再逐块解析：--upload / --dependency 各带一组从属参数，
        // 剩余部分（第一个块之前）是整批共用的全局参数
        var entries = new ArrayList<UploadEntry>();
        var dependencies = new ArrayList<ModrinthUploadData.Dependency>();
        var globalBlock = new ArrayList<String>();
        for (var block : splitBlocks(rawArgs)) {
            switch (block.get(0)) {
                case "--upload" -> entries.add(parseUploadEntry(block));
                case "--dependency" -> dependencies.add(parseDependency(block));
                default -> globalBlock = new ArrayList<>(block);
            }
        }

        var options = parseGlobalArgs(globalBlock, dependencies);

        Objects.requireNonNull(options.tokenSecretId(), "tokenSecretId cannot be null");
        Objects.requireNonNull(options.projectId(), "projectId cannot be null");
        Objects.requireNonNull(options.versionId(), "versionId cannot be null");
        Objects.requireNonNull(options.versionType(), "versionType cannot be null");
        if (options.loaders().isEmpty()) {
            throw new IllegalArgumentException("至少要有一个 --loader");
        }
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("至少要有一个 --upload 分组");
        }

        // 先把所有发布项校验完，避免上传到一半才发现参数有问题
        for (var i = 0; i < entries.size(); i++) {
            var entry = entries.get(i);
            var prefix = "第 " + (i + 1) + " 个 --upload 分组：";
            if (entry.filePath() == null) {
                throw new IllegalArgumentException(prefix + "缺少 --file");
            }
            if (entry.fileName() == null) {
                throw new IllegalArgumentException(prefix + "缺少 --file-name");
            }
            if (entry.versionName() == null) {
                throw new IllegalArgumentException(prefix + "缺少 --version-name");
            }
            if (entry.gameVersions().isEmpty()) {
                throw new IllegalArgumentException(prefix + "缺少 --game-version");
            }
            if (!Files.isRegularFile(Path.of(entry.filePath()))) {
                throw new IllegalArgumentException(prefix + "文件不存在：" + entry.filePath());
            }
        }

        String changelog = null;
        if (options.changelogPath() != null) {
            changelog = Files.readString(Path.of(options.changelogPath()));
        }

        var token = TokenBackend.getDefault().getToken(options.tokenSecretId());
        if (token == null) {
            throw new IllegalArgumentException("未找到 token '" + options.tokenSecretId() + "'，请先用 //rule/tools/modrinth_uploader:modrinth_token_saver 保存");
        }

        var uploaded = 0;
        try (var httpClient = HttpClient.newHttpClient()) {
            var mapper = new ObjectMapper();
            if (isVersionPublished(httpClient, mapper, options.projectId(), options.versionId())) {
                throw new IllegalStateException("Modrinth 上已存在版本号 '" + options.versionId() + "' 的发布；如确需重发，请先在 Modrinth 上删除该版本，或提升 pack_version");
            }
            for (var entry : entries) {
                uploadOne(httpClient, mapper, token, options, changelog, entry);
                uploaded++;
            }
        }

        System.out.println("Uploaded " + uploaded + " of " + entries.size() + " version(s) to Modrinth");
    }

    /** 按块起始符切分参数：第一个块可能只含全局参数。 */
    private static List<List<String>> splitBlocks(List<String> args) {
        var blocks = new ArrayList<List<String>>();
        List<String> current = null;
        for (var arg : args) {
            if (current == null || BLOCK_STARTERS.contains(arg)) {
                current = new ArrayList<>();
                blocks.add(current);
            }
            current.add(arg);
        }
        return blocks;
    }

    /** 解析全局参数块；所有参数都成对出现。 */
    private static BatchOptions parseGlobalArgs(List<String> block, List<ModrinthUploadData.Dependency> dependencies) {
        String tokenSecretId = null;
        String projectId = null;
        String versionId = null;
        String versionType = null;
        String changelogPath = null;
        var loaders = new ArrayList<String>();
        for (var i = 0; i < block.size(); i += 2) {
            var flag = block.get(i);
            switch (flag) {
                case "--token-secret-id" -> tokenSecretId = value(block, i + 1, flag);
                case "--project-id" -> projectId = value(block, i + 1, flag);
                case "--version-id" -> versionId = value(block, i + 1, flag);
                case "--version-type" -> versionType = value(block, i + 1, flag);
                case "--changelog" -> changelogPath = value(block, i + 1, flag);
                case "--loader" -> loaders.add(value(block, i + 1, flag));
                default -> throw new IllegalArgumentException("未知参数：" + flag);
            }
        }
        return new BatchOptions(tokenSecretId, projectId, versionId, versionType, changelogPath, loaders, dependencies);
    }

    /** 解析一个 --upload 块；所有参数都成对出现。 */
    private static UploadEntry parseUploadEntry(List<String> block) {
        String filePath = null;
        String fileName = null;
        String versionName = null;
        var gameVersions = new ArrayList<String>();
        for (var i = 1; i < block.size(); i += 2) {
            var flag = block.get(i);
            switch (flag) {
                case "--file" -> filePath = value(block, i + 1, flag);
                case "--file-name" -> fileName = value(block, i + 1, flag);
                case "--version-name" -> versionName = value(block, i + 1, flag);
                case "--game-version" -> gameVersions.add(value(block, i + 1, flag));
                default -> throw new IllegalArgumentException("--upload 块中的未知参数：" + flag);
            }
        }
        return new UploadEntry(filePath, fileName, versionName, List.copyOf(gameVersions));
    }

    /** 解析一个 --dependency 块；所有参数都成对出现。 */
    private static ModrinthUploadData.Dependency parseDependency(List<String> block) {
        String projectId = null;
        String versionId = null;
        ModrinthUploadData.Dependency.Type type = null;
        for (var i = 1; i < block.size(); i += 2) {
            var flag = block.get(i);
            switch (flag) {
                case "--dependency-project-id" -> projectId = value(block, i + 1, flag);
                case "--dependency-version-id" -> versionId = value(block, i + 1, flag);
                case "--dependency-type" -> type = ModrinthUploadData.Dependency.Type.fromName(value(block, i + 1, flag));
                default -> throw new IllegalArgumentException("--dependency 块中的未知参数：" + flag);
            }
        }
        if (projectId == null || type == null) {
            throw new IllegalArgumentException("--dependency 块缺少 --dependency-project-id 或 --dependency-type");
        }
        return new ModrinthUploadData.Dependency(projectId, versionId, type);
    }

    /** 读取带值参数的取值，并给出比下标越界更清楚的报错。 */
    private static String value(List<String> block, int index, String flag) {
        if (index >= block.size()) {
            throw new IllegalArgumentException("参数 " + flag + " 缺少取值");
        }
        return block.get(index);
    }

    /**
     * 检查项目是否已经发布过指定版本号。
     * Modrinth 不会因为版本号重复而拒绝发布，所以这里在发布前主动拦住重复发布；
     * 查询失败时按“未发布”处理，不阻塞发布。
     */
    private static boolean isVersionPublished(HttpClient httpClient, ObjectMapper mapper, String projectId, String versionNumber) throws IOException, InterruptedException {
        var request = HttpRequest.newBuilder(URI.create(PROJECT_API + "/" + projectId + "/version"))
                .header("User-Agent", USER_AGENT)
                .GET()
                .build();
        var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            System.out.println("Warning: 无法获取已发布版本列表（HTTP " + response.statusCode() + "），跳过重复发布检查");
            return false;
        }

        // jackson-databind 2.9.x 对空 body 返回 null（2.10+ 才改为 MissingNode）
        var body = mapper.readTree(response.body());
        if (body == null || !body.isArray()) {
            System.out.println("Warning: 已发布版本列表响应不是 JSON 数组，跳过重复发布检查");
            return false;
        }
        for (var version : body) {
            if (versionNumber.equals(version.path("version_number").asText())) {
                return true;
            }
        }
        return false;
    }

    private static void uploadOne(
            HttpClient httpClient,
            ObjectMapper mapper,
            String token,
            BatchOptions options,
            String changelog,
            UploadEntry entry) throws IOException, InterruptedException {
        var uploadData = new ModrinthUploadData(entry.versionName(), options.versionId(), changelog, options.dependencies(), entry.gameVersions(), options.versionType(), options.loaders(), options.projectId(), List.of("primary_file"), "primary_file", true);

        var body = MultipartBodyPublisher.newBuilder()
                .textPart("data", mapper.writeValueAsString(uploadData))
                .formPart("primary_file", entry.fileName(), MoreBodyPublishers.ofMediaType(HttpRequest.BodyPublishers.ofFile(Path.of(entry.filePath())), MediaType.APPLICATION_OCTET_STREAM))
                .build();
        var request = HttpRequest.newBuilder(URI.create(VERSION_API))
                .header("Authorization", token)
                .header("User-Agent", USER_AGENT)
                .header("Content-Type", body.mediaType().toString())
                .POST(body)
                .build();

        System.out.println("Uploading " + entry.fileName() + " as '" + entry.versionName() + "'...");
        var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IOException("Upload failed: " + response.statusCode() + " " + response.body());
        }
        System.out.println("Uploaded " + entry.fileName() + " successfully");
    }
}
