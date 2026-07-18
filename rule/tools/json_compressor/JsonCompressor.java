import top.fifthlight.bazel.worker.api.WorkRequest;
import top.fifthlight.bazel.worker.api.Worker;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.*;
import java.nio.file.*;

public class JsonCompressor extends Worker {
    public static void main(String[] args) throws Exception {
        new JsonCompressor().run();
    }

    @Override
    protected int handleRequest(WorkRequest request, PrintWriter out) {
        var args = request.arguments();
        if (args.size() < 2) {
            out.println("Usage: JsonCompressor <input_file> <output_file>");
            return 1;
        }

        var inputFile = args.get(0);
        var outputFile = args.get(1);
        
        try {
            processFile(inputFile, outputFile);
        } catch (Exception e) {
            out.println("Error processing file: " + e.getMessage());
            e.printStackTrace(out);
            return 1;
        }
        return 0;
    }

    private static void processFile(String inputPath, String outputPath) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        
        // Read JSON
        Object json = mapper.readValue(Files.readString(Paths.get(inputPath)), Object.class);
        
        // Compress to single line
        String compressed = mapper.writeValueAsString(json);
        
        // Ensure output directory exists
        Path outputFile = Paths.get(outputPath);
        Path outputDir = outputFile.getParent();
        if (outputDir != null) {
            Files.createDirectories(outputDir);
        }
        
        // Write as single line
        Files.writeString(outputFile, compressed);
    }
}