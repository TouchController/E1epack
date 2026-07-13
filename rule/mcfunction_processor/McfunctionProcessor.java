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
    private Map<String, Path> namespaceToRoot = new HashMap<>();

    public static void main(String[] args) throws Exception {
        new McfunctionProcessor().run();
    }

    @Override
    protected int handleRequest(WorkRequest request, PrintWriter out) {
        var args = request.arguments();
        if (args.size() < 2) {
            out.println("Usage: McfunctionProcessor <input_file> <output_file> [dependency_files...]");
            return 1;
        }

        var inputFile = args.get(0);
        var outputFile = args.get(1);

        // 从依赖文件路径中提取 namespace -> 数据包根目录映射
        for (int i = 2; i < args.size(); i++) {
            registerDepFile(Paths.get(args.get(i)));
        }

        try {
            processFile(inputFile, outputFile);
        } catch (IOException e) {
            out.println("Error processing file: " + e.getMessage());
            e.printStackTrace(out);
            return 1;
        }
        return 0;
    }

    private void registerDepFile(Path depFilePath) {
        Path root = findDataPackRoot(depFilePath);
        if (root == null) return;

        // 从文件路径提取命名空间: data/<namespace>/function/...
        Path dataDir = root.resolve("data");
        Path relativePath = dataDir.relativize(depFilePath);
        if (relativePath.getNameCount() >= 2) {
            String namespace = relativePath.getName(0).toString();
            namespaceToRoot.putIfAbsent(namespace, root);
        }
    }

    private void processFile(String inputPath, String outputPath) throws IOException {
        var inputLines = Files.readAllLines(Paths.get(inputPath));
        determineDataPackInfo(Paths.get(inputPath));
        var processedLines = processLines(inputLines);

        var outputFile = Paths.get(outputPath);
        var outputDir = outputFile.getParent();
        if (outputDir != null) {
            Files.createDirectories(outputDir);
        }
        Files.write(outputFile, processedLines);
    }

    private void determineDataPackInfo(Path inputFile) {
        dataPackRoot = findDataPackRoot(inputFile);
        if (dataPackRoot == null) {
            dataPackRoot = inputFile.getParent();
            if (dataPackRoot == null) {
                dataPackRoot = Paths.get(".").toAbsolutePath().normalize();
            }
        }

        // 从文件路径推断包ID: data/<namespace>/function/...
        String relativePath = dataPackRoot.relativize(inputFile).toString().replace('\\', '/');
        if (relativePath.startsWith("data/")) {
            String[] parts = relativePath.split("/");
            if (parts.length >= 2) {
                currentPackId = parts[1];
            }
        }
        if (currentPackId == null) {
            currentPackId = "minecraft";
        }

        // 注册当前数据包到命名空间映射
        namespaceToRoot.putIfAbsent(currentPackId, dataPackRoot);
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
        List<String> afterForceReplace = processForceReplace(rawLines);
        List<String> afterBasicProcessing = processBasicLines(afterForceReplace);

        List<String> result = afterBasicProcessing;
        for (int depth = 0; depth < MAX_INLINE_DEPTH; depth++) {
            List<String> newResult = processFunctionInlining(result);
            if (newResult.equals(result)) {
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
            if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                continue;
            }
            if (trimmed.endsWith("\\")) {
                currentCommand.append(trimmed.substring(0, trimmed.length() - 1));
            } else {
                currentCommand.append(trimmed);
                String finalCommand = currentCommand.toString().trim();
                if (!finalCommand.isEmpty()) {
                    result.add(finalCommand);
                }
                currentCommand.setLength(0);
            }
        }

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

                if (!NAMESPACE_ID_PATTERN.matcher(functionName).matches()) {
                    result.add(line);
                    continue;
                }
                if (functionName.startsWith("#")) {
                    result.add(line);
                    continue;
                }

                List<String> functionContent = loadFunction(functionName);
                if (functionContent == null) {
                    result.add(line);
                    continue;
                }
                if (containsReturnCommand(functionContent)) {
                    result.add(line);
                    continue;
                }

                if (arguments != null && !arguments.trim().isEmpty()) {
                    List<String> expandedContent = expandMacroFunction(functionContent, arguments.trim());
                    if (expandedContent != null) {
                        result.addAll(expandedContent);
                    } else {
                        result.add(line);
                    }
                } else {
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

        String[] parts = functionName.split(":", 2);
        if (parts.length != 2) return null;

        String namespace = parts[0];
        String functionPath = parts[1];

        // 直接通过命名空间查表定位数据包根目录
        Path root = namespaceToRoot.get(namespace);
        if (root != null) {
            Path functionFile = root.resolve("data")
                                  .resolve(namespace)
                                  .resolve("function")
                                  .resolve(functionPath + ".mcfunction");
            if (Files.exists(functionFile)) {
                try {
                    List<String> content = Files.readAllLines(functionFile);
                    List<String> processed = processBasicLines(content);
                    functionCache.put(functionName, processed);
                    return processed;
                } catch (IOException ignored) {}
            }
        }

        functionCache.put(functionName, null);
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
                String expandedLine = expandMacroLine(line, macroParams);
                if (expandedLine == null) {
                    return null;
                }
                result.add(expandedLine);
            } else {
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

        line = line.substring(1);

        Pattern paramPattern = Pattern.compile("\\$\\(([a-zA-Z0-9_]+)\\)");
        Matcher matcher = paramPattern.matcher(line);
        StringBuffer result = new StringBuffer();

        while (matcher.find()) {
            String key = matcher.group(1);
            String value = params.get(key);
            if (value == null) {
                return null;
            }
            matcher.appendReplacement(result, Matcher.quoteReplacement(value));
        }
        matcher.appendTail(result);

        return result.toString();
    }

    private Map<String, String> parseSNBT(String snbt) {
        snbt = snbt.trim();
        if (!snbt.startsWith("{") || !snbt.endsWith("}")) {
            return null;
        }

        Map<String, String> result = new HashMap<>();
        String content = snbt.substring(1, snbt.length() - 1).trim();
        if (content.isEmpty()) {
            return result;
        }

        List<String> pairs = splitSNBTPairs(content);
        for (String pair : pairs) {
            String[] keyValue = pair.split(":", 2);
            if (keyValue.length != 2) {
                return null;
            }

            String key = keyValue[0].trim();
            String value = keyValue[1].trim();

            if (key.startsWith("\"") && key.endsWith("\"")) {
                key = key.substring(1, key.length() - 1);
            }

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

    private String processSNBTValue(String value) {
        value = value.trim();

        if (value.startsWith("\"") && value.endsWith("\"")) {
            return value.substring(1, value.length() - 1);
        }

        if (value.matches("-?\\d+[bslfdBSLFD]?")) {
            return value.replaceAll("[bslfdBSLFD]$", "");
        }

        if (value.matches("-?\\d*\\.\\d+([eE][+-]?\\d+)?[fd]?")) {
            String result = value.replaceAll("[fd]$", "");
            try {
                double d = Double.parseDouble(result);
                return String.format("%.15g", d);
            } catch (NumberFormatException e) {
                return result;
            }
        }

        if (value.startsWith("{") || value.startsWith("[")) {
            return value;
        }

        return value;
    }
}
