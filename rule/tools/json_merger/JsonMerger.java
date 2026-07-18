import top.fifthlight.bazel.worker.api.WorkRequest;
import top.fifthlight.bazel.worker.api.Worker;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.*;
import java.nio.file.*;
import java.util.Iterator;
import java.util.Map;

/**
 * JSON合并器，用于合并多个JSON文件的键值对。
 * 支持深度合并，后面的文件会覆盖前面文件的相同键。
 */
public class JsonMerger extends Worker {
    public static void main(String[] args) throws Exception {
        new JsonMerger().run();
    }

    @Override
    protected int handleRequest(WorkRequest request, PrintWriter out) {
        var args = request.arguments();
        if (args.size() < 2) {
            out.println("Usage: JsonMerger <output_file> <input_file1> [input_file2] ...");
            return 1;
        }

        var outputFile = args.get(0);
        var inputFiles = args.subList(1, args.size());
        
        try {
            mergeFiles(inputFiles, outputFile);
        } catch (Exception e) {
            out.println("Error merging files: " + e.getMessage());
            e.printStackTrace(out);
            return 1;
        }
        return 0;
    }

    private static void mergeFiles(java.util.List<String> inputPaths, String outputPath) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        ObjectNode result = mapper.createObjectNode();
        
        // 按顺序合并所有输入文件
        for (String inputPath : inputPaths) {
            Path path = Paths.get(inputPath);
            if (Files.exists(path)) {
                try {
                    JsonNode json = mapper.readTree(Files.readString(path));
                    if (json.isObject()) {
                        result = mergeObjects(result, (ObjectNode) json);
                    }
                } catch (Exception e) {
                    System.err.println("Warning: Failed to parse " + inputPath + ": " + e.getMessage());
                    // 继续处理其他文件
                }
            }
        }
        
        // 确保输出目录存在
        Path outputFile = Paths.get(outputPath);
        Path outputDir = outputFile.getParent();
        if (outputDir != null) {
            Files.createDirectories(outputDir);
        }
        
        // 压缩输出为单行
        String compressed = mapper.writeValueAsString(result);
        Files.writeString(outputFile, compressed);
    }

    /**
     * 深度合并两个ObjectNode
     * @param base 基础对象
     * @param overlay 覆盖对象
     * @return 合并后的对象
     */
    private static ObjectNode mergeObjects(ObjectNode base, ObjectNode overlay) {
        Iterator<Map.Entry<String, JsonNode>> fields = overlay.fields();
        while (fields.hasNext()) {
            Map.Entry<String, JsonNode> entry = fields.next();
            String key = entry.getKey();
            JsonNode value = entry.getValue();
            
            if (base.has(key) && base.get(key).isObject() && value.isObject()) {
                // 如果两个值都是对象，递归合并
                ObjectNode merged = mergeObjects((ObjectNode) base.get(key), (ObjectNode) value);
                base.set(key, merged);
            } else {
                // 否则直接覆盖
                base.set(key, value);
            }
        }
        return base;
    }
}