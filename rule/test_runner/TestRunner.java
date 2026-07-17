import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Set;
import java.util.HashSet;

/**
 * 读取 MC test_server 的 stdout，收集测试结果和加载错误。
 * args: --version <v> --ignore-error-ns <ns> ... test_name1 test_name2 ...
 * 匹配格式：[[TEST][name][PASS]] 或 [[TEST][name][FAIL]]
 */
public class TestRunner {
    private static final String MARKER = "[[TEST][";

    public static void main(String[] args) throws Exception {
        String version = "?";
        var expected = new LinkedHashMap<String, String>();
        var ignoredNS = new HashSet<String>();
        int ai = 0;
        while (ai < args.length) {
            if ("--version".equals(args[ai])) {
                ai++;
                if (ai < args.length) version = args[ai];
            } else if ("--ignore-error-ns".equals(args[ai])) {
                ai++;
                if (ai < args.length) ignoredNS.add(args[ai]);
            } else {
                expected.put(args[ai], null);
            }
            ai++;
        }

        boolean verbose = "1".equals(System.getenv("TEST_VERBOSE"));
        var logDir = System.getenv("TEST_UNDECLARED_OUTPUTS_DIR");
        var reader = new BufferedReader(new InputStreamReader(System.in));
        var loadErrors = new ArrayList<String>();
        var logWriter = logDir != null ? Files.newBufferedWriter(Path.of(logDir, "server.log")) : null;
        boolean started = false;

        try {
            String line;
            while ((line = reader.readLine()) != null) {
                if (logWriter != null) { logWriter.write(line); logWriter.newLine(); }
                if (verbose) System.err.println(line);
                if (line.contains("[[TESTING_STARTED]]")) {
                    started = true;
                    continue;
                }
                if (!started && line.contains("ERROR")) {
                    var isIgnored = false;
                    for (var ns : ignoredNS) { if (line.contains(ns + ":")) { isIgnored = true; break; } }
                    if (!isIgnored) loadErrors.add(line);
                    continue;
                }
                if (!started) continue;

                int idx = line.indexOf(MARKER);
                if (idx < 0) continue;
                int nameStart = idx + MARKER.length();
                int nameEnd = line.indexOf("][", nameStart);
                if (nameEnd < 0) continue;
                String name = line.substring(nameStart, nameEnd);

                int statusStart = nameEnd + 2;
                int statusEnd = line.indexOf("]", statusStart);
                if (statusEnd < 0) continue;
                String status = line.substring(statusStart, statusEnd);

                if ("PASS".equals(status)) {
                    expected.put(name, "pass");
                } else if ("FAIL".equals(status)) {
                    expected.put(name, "fail");
                }
            }
        } finally {
            if (logWriter != null) logWriter.close();
        }

        // --- Report ---
        if (!expected.isEmpty() || !loadErrors.isEmpty()) {
            System.out.println("┌─ " + version + " ─" + "─".repeat(40));
        }
        if (!loadErrors.isEmpty()) {
            System.out.println("┌─ Load Errors (" + loadErrors.size() + ") ──────────────");
            for (String e : loadErrors) System.out.println("│ " + e.trim());
            System.out.println("└──────────────────────────────────────────");
        }

        var passed = new ArrayList<String>();
        var failed = new ArrayList<String>();
        var missed = new ArrayList<String>();
        for (var e : expected.entrySet()) {
            String r = e.getValue();
            if ("pass".equals(r)) passed.add(e.getKey());
            else if ("fail".equals(r)) failed.add(e.getKey());
            else missed.add(e.getKey());
        }

        if (!expected.isEmpty()) {
            System.out.println("┌─ Test Results ───────────────────────────");
            if (!passed.isEmpty()) {
                System.out.println("│ PASS (" + passed.size() + "):");
                for (String n : passed) System.out.println("│   " + n);
            }
            if (!failed.isEmpty()) {
                System.out.println("│ FAIL (" + failed.size() + "):");
                for (String n : failed) System.out.println("│   " + n);
            }
            if (!missed.isEmpty()) {
                System.out.println("│ MISS (" + missed.size() + "):");
                for (String n : missed) System.out.println("│   " + n);
            }
            System.out.println("├──────────────────────────────────────────");
            System.out.println("│ errors:" + loadErrors.size() + "  passed:" + passed.size() + "  failed:" + failed.size() + "  missing:" + missed.size());
            System.out.println("└──────────────────────────────────────────");
        }

        if (!loadErrors.isEmpty() || !failed.isEmpty() || !missed.isEmpty()) {
            System.exit(1);
        }
    }
}
