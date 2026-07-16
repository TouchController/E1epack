import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.LinkedHashMap;

/**
 * 读取 MC test_server 的 stdout，收集测试结果和加载错误。
 * 命令行参数：期望的测试名列表，如 common/case_foo 1.20/case_bar
 * 匹配格式：[[TEST][name][PASS]] 或 [[TEST][name][FAIL]]
 */
public class TestRunner {
    private static final String MARKER = "[[TEST][";

    public static void main(String[] args) throws Exception {
        var expected = new LinkedHashMap<String, String>(); // name -> null
        for (String name : args) {
            expected.put(name, null);
        }

        var reader = new BufferedReader(new InputStreamReader(System.in));
        var loadErrors = new ArrayList<String>();
        boolean started = false;

        String line;
        while ((line = reader.readLine()) != null) {
            System.err.println(line);
            if (line.contains("[[TESTING_STARTED]]")) {
                started = true;
                continue;
            }
            if (!started && line.contains("ERROR")) {
                loadErrors.add(line);
                continue;
            }
            if (!started) continue;

            int idx = line.indexOf(MARKER);
            if (idx < 0) continue;
            int nameStart = idx + MARKER.length();
            int nameEnd = line.indexOf("][", nameStart);
            if (nameEnd < 0) continue;
            String name = line.substring(nameStart, nameEnd);

            int statusStart = nameEnd + 2; // skip "]["
            int statusEnd = line.indexOf("]", statusStart);
            if (statusEnd < 0) continue;
            String status = line.substring(statusStart, statusEnd);

            if ("PASS".equals(status)) {
                expected.put(name, "pass");
            } else if ("FAIL".equals(status)) {
                expected.put(name, "fail");
            }
        }

        // --- Report ---
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
