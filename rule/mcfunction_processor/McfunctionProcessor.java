import top.fifthlight.bazel.worker.api.WorkRequest;
import top.fifthlight.bazel.worker.api.Worker;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

public class McfunctionProcessor extends Worker {
    private static final int MAX_INLINE_DEPTH = 5;
    private static final Pattern NAMESPACE_ID_PATTERN = Pattern.compile("^[a-z0-9_.-]+:[a-z0-9_./\\-]+$");
    private static final Pattern FUNCTION_CALL_PATTERN = Pattern.compile("^function\\s+([a-z0-9_.-]+:[a-z0-9_./\\-]+)(?:\\s+(.+))?$");
    private static final Pattern FORCE_FUNCTION_PATTERN = Pattern.compile("^#function\\s+([a-z0-9_.-]+:[a-z0-9_./\\-]+)$");
    private static final Pattern RETURN_PATTERN = Pattern.compile("^(?:return|execute\\s+.*\\s+run\\s+return)\\b");

    private Map<String, List<String>> functionCache = new HashMap<>();
    private String currentPackId;
    private Path dataPackRoot;
    private List<Path> dependencyPaths = new ArrayList<>();
    private Path workspaceRoot;
    private Map<String, Set<String>> functionCallGraph = new HashMap<>();
    private Set<String> detectedCycles = new HashSet<>();

    public static void main(String[] args) throws Exception {
        new McfunctionProcessor().run();
    }

    @Override
    protected int handleRequest(WorkRequest request, PrintWriter out) {
        var args = request.arguments();
        if (args.size() < 2) {
            out.println("Usage: McfunctionProcessor <input_file> <output_file> [workspace_root] [dependency_files...]");
            return 1;
        }

        var inputFile = args.get(0);
        var outputFile = args.get(1);

        // Optional workspace root argument (for Bazel sandbox environment)
        Path workspaceRoot = null;
        int depStartIndex = 2;

        if (args.size() >= 3) {
            String thirdArg = args.get(2);
            // Check if the third argument looks like a path (not a dependency file)
            // Simple heuristic: if it contains "workspace" or doesn't end with .mcfunction or similar
            if (!thirdArg.endsWith(".mcfunction") && !thirdArg.endsWith(".json") && !thirdArg.endsWith(".zip")) {
                workspaceRoot = Paths.get(thirdArg);
                depStartIndex = 3;
            }
        }

        // 解析依赖文件路径
        for (int i = depStartIndex; i < args.size(); i++) {
            Path depFilePath = Paths.get(args.get(i));
            Path depDataPackRoot = findDataPackRoot(depFilePath);
            if (depDataPackRoot != null) {
                dependencyPaths.add(depDataPackRoot);
            }
        }

        // If workspace root is provided, use it as the project root
        if (workspaceRoot != null) {
            // Store workspace root for use in findProjectRoot
            this.workspaceRoot = workspaceRoot;
        }

        try {
            processFile(inputFile, outputFile);
        } catch (Exception e) {
            out.println("Error processing file: " + e.getMessage());
            e.printStackTrace(out);
            return 1;
        }
        return 0;
    }

    private void processFile(String inputPath, String outputPath) throws IOException {
        var inputLines = Files.readAllLines(Paths.get(inputPath));

        // 确定数据包根目录和包ID
        Path inputFile = Paths.get(inputPath);
        determineDataPackInfo(inputFile);

        var processedLines = processLines(inputLines);

        // 确保输出目录存在
        var outputFile = Paths.get(outputPath);
        var outputDir = outputFile.getParent();
        if (outputDir != null) {
            Files.createDirectories(outputDir);
        }

        Files.write(outputFile, processedLines);
    }

    private void determineDataPackInfo(Path inputFile) {
        // 向上查找包含 data 目录的根目录
        Path current = inputFile.getParent();
        while (current != null) {
            Path dataDir = current.resolve("data");
            if (Files.exists(dataDir) && Files.isDirectory(dataDir)) {
                dataPackRoot = current;
                break;
            }
            current = current.getParent();
        }

        if (dataPackRoot == null) {
            // 如果找不到data目录，使用输入文件的父目录作为根目录
            dataPackRoot = inputFile.getParent();
            if (dataPackRoot == null) {
                dataPackRoot = Paths.get(".").toAbsolutePath().normalize();
            }
        }

        // 从文件路径推断包ID
        String relativePath = dataPackRoot.relativize(inputFile).toString().replace('\\', '/');
        if (relativePath.startsWith("data/")) {
            String[] parts = relativePath.split("/");
            if (parts.length >= 2) {
                currentPackId = parts[1];
            }
        }

        // 如果无法推断包ID，使用默认值
        if (currentPackId == null) {
            currentPackId = "minecraft";
        }
    }

    private Path findDataPackRoot(Path filePath) {
        Path current = filePath.getParent();
        while (current != null) {
            Path dataDir = current.resolve("data");
            if (Files.exists(dataDir) && Files.isDirectory(dataDir)) {
                return current;
            }
            current = current.getParent();
        }
        return null;
    }

    private List<String> processLines(List<String> rawLines) {
        // 第一步：处理强制替换（#function）
        List<String> afterForceReplace = processForceReplace(rawLines);

        // 第二步：处理注释去除和反斜杠拼接
        List<String> afterBasicProcessing = processBasicLines(afterForceReplace);

        // 第三步：进行函数内联处理（最多5层）
        List<String> result = afterBasicProcessing;
        for (int depth = 0; depth < MAX_INLINE_DEPTH; depth++) {
            List<String> newResult = processFunctionInlining(result);
            if (newResult.equals(result)) {
                // 没有更多替换，提前退出
                break;
            }
            result = newResult;
        }

        return result;
    }

    private List<String> processForceReplace(List<String> lines) {
        List<String> result = new ArrayList<>();

        for (String line : lines) {
            String trimmed = line.trim();
            Matcher matcher = FORCE_FUNCTION_PATTERN.matcher(trimmed);

            if (matcher.matches()) {
                String functionName = matcher.group(1);
                List<String> functionContent = loadFunction(functionName);
                if (functionContent != null) {
                    result.addAll(functionContent);
                } else {
                    // 如果找不到函数，保留原命令
                    result.add(line);
                }
            } else {
                result.add(line);
            }
        }

        return result;
    }

    private List<String> processBasicLines(List<String> rawLines) {
        List<String> result = new ArrayList<>();
        StringBuilder currentCommand = new StringBuilder();

        for (String line : rawLines) {
            String trimmed = line.trim();

            // 跳过空行和注释行
            if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                continue;
            }

            // 处理续行（以反斜杠结尾）
            if (trimmed.endsWith("\\")) {
                // 移除反斜杠，严格保留内容
                String lineWithoutBackslash = trimmed.substring(0, trimmed.length() - 1);

                // 直接拼接，不添加任何字符
                currentCommand.append(lineWithoutBackslash);
            } else {
                // 普通行，直接拼接
                currentCommand.append(trimmed);

                // 添加完整的命令到结果中
                String finalCommand = currentCommand.toString().trim();

                if (!finalCommand.isEmpty()) {
                    result.add(finalCommand);
                }

                // 重置当前命令
                currentCommand.setLength(0);
            }
        }

        // 处理最后一个可能未完成的命令
        if (!currentCommand.isEmpty()) {
            var finalCommand = currentCommand.toString().trim();
            if (!finalCommand.isEmpty()) {
                result.add(finalCommand);
            }
        }

        return result;
    }

    private List<String> processFunctionInlining(List<String> lines) {
        List<String> result = new ArrayList<>();

        for (String line : lines) {
            String trimmed = line.trim();
            Matcher matcher = FUNCTION_CALL_PATTERN.matcher(trimmed);

            if (matcher.matches()) {
                String functionName = matcher.group(1);
                String arguments = matcher.group(2);

                // 验证命名空间ID格式
                if (!NAMESPACE_ID_PATTERN.matcher(functionName).matches()) {
                    result.add(line);
                    continue;
                }

                // 跳过以#开头的函数名
                if (functionName.startsWith("#")) {
                    result.add(line);
                    continue;
                }

                List<String> functionContent = loadFunction(functionName);
                if (functionContent == null) {
                    // 函数不存在，保留原命令
                    result.add(line);
                    continue;
                }

                // 检查函数是否包含return命令
                if (containsReturnCommand(functionContent)) {
                    result.add(line);
                    continue;
                }

                // 处理函数内容
                if (arguments != null && !arguments.trim().isEmpty()) {
                    // 宏调用
                    List<String> expandedContent = expandMacroFunction(functionContent, arguments.trim());
                    if (expandedContent != null) {
                        result.addAll(expandedContent);
                    } else {
                        // SNBT解析失败，保留原命令
                        result.add(line);
                    }
                } else {
                    // 普通调用
                    result.addAll(functionContent);
                }
            } else {
                result.add(line);
            }
        }

        return result;
    }

    private List<String> loadFunction(String functionName) {
        if (functionCache.containsKey(functionName)) {
            return functionCache.get(functionName);
        }

        // 解析命名空间和路径
        String[] parts = functionName.split(":", 2);
        if (parts.length != 2) {
            return null;
        }

        String namespace = parts[0];
        String functionPath = parts[1];

        // 尝试多个可能的搜索路径
        List<Path> searchPaths = getDataPackSearchPaths();

        for (Path searchRoot : searchPaths) {
            Path functionFile = searchRoot.resolve("data")
                                         .resolve(namespace)
                                         .resolve("function")
                                         .resolve(functionPath + ".mcfunction");

            if (Files.exists(functionFile)) {
                try {
                    List<String> content = Files.readAllLines(functionFile);
                    // 对加载的函数内容进行基础处理（注释去除和反斜杠拼接）
                    List<String> processedContent = processBasicLines(content);
                    functionCache.put(functionName, processedContent);
                    // 解析该函数调用的其他函数，构建调用图
                    parseFunctionCalls(functionName, processedContent);
                    return processedContent;
                } catch (IOException e) {
                    // 继续尝试下一个路径
                    continue;
                }
            }
        }

        // 所有路径都找不到函数
        functionCache.put(functionName, null);
        return null;
    }

    private List<Path> getDataPackSearchPaths() {
        List<Path> searchPaths = new ArrayList<>();

        // 1. 当前数据包根目录
        if (dataPackRoot != null) {
            searchPaths.add(dataPackRoot);
        }

        // 2. 项目根目录（包含多个数据包）
        Path projectRoot = findProjectRoot();
        if (projectRoot != null && !projectRoot.equals(dataPackRoot)) {
            searchPaths.add(projectRoot);
        }

        // 3. 添加所有依赖数据包目录
        for (Path depPath : dependencyPaths) {
            if (Files.exists(depPath.resolve("data")) && !depPath.equals(dataPackRoot)) {
                searchPaths.add(depPath);
            }
        }

        return searchPaths;
    }

    private Path findProjectRoot() {
        // If workspace root is provided, use it as the project root
        if (workspaceRoot != null) {
            return workspaceRoot;
        }

        if (dataPackRoot == null) {
            return null;
        }

        // 向上查找包含MODULE.bazel的目录作为项目根目录（优先）
        // 或者包含多个数据包目录的目录
        Path current = dataPackRoot;
        Path bestCandidate = null;

        while (current != null) {
            boolean hasBuild = Files.exists(current.resolve("BUILD.bazel"));
            boolean hasModule = Files.exists(current.resolve("MODULE.bazel"));
            boolean hasGit = Files.exists(current.resolve(".git"));

            // 如果找到MODULE.bazel，这很可能是真正的项目根目录
            if (hasModule) {
                return current;
            }

            // 如果有BUILD.bazel，记录为候选，但继续向上查找
            if (hasBuild && bestCandidate == null) {
                bestCandidate = current;
            }

            current = current.getParent();
        }

        if (bestCandidate != null) {
            return bestCandidate;
        }

        return null;
    }

    private boolean containsReturnCommand(List<String> lines) {
        for (String line : lines) {
            if (RETURN_PATTERN.matcher(line.trim()).find()) {
                return true;
            }
        }
        return false;
    }

    private List<String> expandMacroFunction(List<String> functionContent, String snbtArguments) {
        Map<String, String> macroParams = parseSNBT(snbtArguments);
        if (macroParams == null) {
            return null;
        }

        List<String> result = new ArrayList<>();
        for (String line : functionContent) {
            if (line.trim().startsWith("$")) {
                // 宏行，进行参数替换
                String expandedLine = expandMacroLine(line, macroParams);
                if (expandedLine == null) {
                    // 参数不足，返回null表示失败
                    return null;
                }
                result.add(expandedLine);
            } else {
                // 普通行，直接添加
                result.add(line);
            }
        }

        return result;
    }

    private String expandMacroLine(String macroLine, Map<String, String> params) {
        String line = macroLine.trim();
        if (!line.startsWith("$")) {
            return line;
        }

        // 移除开头的$
        line = line.substring(1);

        // 替换所有 $(key) 格式的参数
        Pattern paramPattern = Pattern.compile("\\$\\(([a-zA-Z0-9_]+)\\)");
        Matcher matcher = paramPattern.matcher(line);
        StringBuffer result = new StringBuffer();

        while (matcher.find()) {
            String key = matcher.group(1);
            String value = params.get(key);
            if (value == null) {
                // 缺少必需的参数
                return null;
            }
            matcher.appendReplacement(result, Matcher.quoteReplacement(value));
        }
        matcher.appendTail(result);

        return result.toString();
    }

    private Map<String, String> parseSNBT(String snbt) {
        // 简化的SNBT解析器，只处理复合标签的基本情况
        snbt = snbt.trim();
        if (!snbt.startsWith("{") || !snbt.endsWith("}")) {
            return null;
        }

        Map<String, String> result = new HashMap<>();
        String content = snbt.substring(1, snbt.length() - 1).trim();

        if (content.isEmpty()) {
            return result;
        }

        // 简单的键值对解析
        List<String> pairs = splitSNBTPairs(content);
        for (String pair : pairs) {
            String[] keyValue = pair.split(":", 2);
            if (keyValue.length != 2) {
                return null;
            }

            String key = keyValue[0].trim();
            String value = keyValue[1].trim();

            // 移除键的引号
            if (key.startsWith("\"") && key.endsWith("\"")) {
                key = key.substring(1, key.length() - 1);
            }

            // 处理值
            String processedValue = processSNBTValue(value);
            if (processedValue == null) {
                return null;
            }

            result.put(key, processedValue);
        }

        return result;
    }

    private List<String> splitSNBTPairs(String content) {
        List<String> pairs = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        int braceLevel = 0;
        int bracketLevel = 0;
        boolean inQuotes = false;
        boolean escaped = false;

        for (char c : content.toCharArray()) {
            if (escaped) {
                current.append(c);
                escaped = false;
                continue;
            }

            if (c == '\\') {
                escaped = true;
                current.append(c);
                continue;
            }

            if (c == '"') {
                inQuotes = !inQuotes;
                current.append(c);
                continue;
            }

            if (!inQuotes) {
                if (c == '{') {
                    braceLevel++;
                } else if (c == '}') {
                    braceLevel--;
                } else if (c == '[') {
                    bracketLevel++;
                } else if (c == ']') {
                    bracketLevel--;
                } else if (c == ',' && braceLevel == 0 && bracketLevel == 0) {
                    pairs.add(current.toString().trim());
                    current.setLength(0);
                    continue;
                }
            }

            current.append(c);
        }

        if (!current.isEmpty()) {
            pairs.add(current.toString().trim());
        }

        return pairs;
    }

    private void parseFunctionCalls(String functionName, List<String> functionContent) {
        Set<String> calls = new HashSet<>();
        for (String line : functionContent) {
            String trimmed = line.trim();
            Matcher matcher = FUNCTION_CALL_PATTERN.matcher(trimmed);
            if (matcher.matches()) {
                String calledFunction = matcher.group(1);
                // 验证命名空间ID格式
                if (!NAMESPACE_ID_PATTERN.matcher(calledFunction).matches()) {
                    continue;
                }
                // 跳过以#开头的函数名
                if (calledFunction.startsWith("#")) {
                    continue;
                }
                calls.add(calledFunction);
            }
        }
        functionCallGraph.put(functionName, calls);
        // 检测调用图中是否有环
        detectCycles(functionName);
    }

    private void detectCycles(String startFunction) {
        Set<String> visited = new HashSet<>();
        Set<String> stack = new HashSet<>();
        List<String> path = new ArrayList<>();
        if (hasCycle(startFunction, visited, stack, path)) {
            // 避免重复报告同一个环
            String cycleKey = String.join("->", path);
            if (!detectedCycles.contains(cycleKey)) {
                detectedCycles.add(cycleKey);
                throw new RuntimeException("Detected function call cycle: " + cycleKey);
            }
        }
    }

    private boolean hasCycle(String function, Set<String> visited, Set<String> stack, List<String> path) {
        if (stack.contains(function)) {
            path.add(function);
            return true;
        }
        if (visited.contains(function)) {
            return false;
        }
        visited.add(function);
        stack.add(function);
        path.add(function);
        
        Set<String> calls = functionCallGraph.get(function);
        if (calls != null) {
            for (String callee : calls) {
                if (hasCycle(callee, visited, stack, path)) {
                    return true;
                }
            }
        }
        
        stack.remove(function);
        path.remove(path.size() - 1);
        return false;
    }

    private String processSNBTValue(String value) {
        value = value.trim();

        // 字符串值
        if (value.startsWith("\"") && value.endsWith("\"")) {
            return value.substring(1, value.length() - 1);
        }

        // 数字值（移除类型后缀）
        if (value.matches("-?\\d+[bslfdBSLFD]?")) {
            // 移除类型后缀
            return value.replaceAll("[bslfdBSLFD]$", "");
        }

        // 浮点数（包括科学计数法）
        if (value.matches("-?\\d*\\.\\d+([eE][+-]?\\d+)?[fd]?")) {
            String result = value.replaceAll("[fd]$", "");
            // 转换科学计数法为小数形式
            try {
                double d = Double.parseDouble(result);
                // 保留最多15位小数
                return String.format("%.15g", d);
            } catch (NumberFormatException e) {
                return result;
            }
        }

        // 复合标签、列表、数组等保持SNBT形式
        if (value.startsWith("{") || value.startsWith("[")) {
            return value;
        }

        // 其他情况直接返回
        return value;
    }
}
