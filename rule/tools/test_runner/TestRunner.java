import java.io.*;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.HashSet;

/**
 * 通过 RCON 调用 _test_runner，从 stdin 读取测试结果。
 * args: --version <v> --ignore-error-ns <ns> test_ns test_name1 ...
 */
public class TestRunner {
    private static final String MARKER = "[[TEST][";
    private static final int RCON_PORT = 25575;
    private static final String RCON_PW = "dev";

    public static void main(String[] args) throws Exception {
        String version = "?";
        var expected = new LinkedHashMap<String, String>();
        var ignoredNS = new HashSet<String>();
        var testNsHolder = new String[]{null};
        int ai = 0;
        while (ai < args.length) {
            if ("--version".equals(args[ai])) { ai++; if (ai < args.length) version = args[ai]; }
            else if ("--ignore-error-ns".equals(args[ai])) { ai++; if (ai < args.length) ignoredNS.add(args[ai]); }
            else if ("--test-ns".equals(args[ai])) { ai++; if (ai < args.length) testNsHolder[0] = args[ai]; }
            else expected.put(args[ai], null);
            ai++;
        }

        boolean verbose = "1".equals(System.getenv("TEST_VERBOSE"));
        var logDir = System.getenv("TEST_UNDECLARED_OUTPUTS_DIR");
        var reader = new BufferedReader(new InputStreamReader(System.in));
        var loadErrors = new ArrayList<String>();
        var logWriter = logDir != null ? Files.newBufferedWriter(Path.of(logDir, "server.log")) : null;
        boolean started = false;

        // RCON background thread: poll until server accepts, auth, trigger runner
        var rconThread = new Thread(() -> {
            for (int i = 0; i < 120; i++) {
                try (Socket s = new Socket("127.0.0.1", RCON_PORT)) {
                    var out = s.getOutputStream(); var in = s.getInputStream();
                    rconSend(out, 1, 3, RCON_PW);
                    var resp = rconRecv(in);
                    if (resp == null || resp[0] == -1) { System.err.println("RCON auth failed"); return; }
                    rconSend(out, 2, 2, "function " + testNsHolder[0] + ":_test_runner");
                    rconRecv(in);  // consume response
                    return;
                } catch (Exception e) {
                    if (i == 119) e.printStackTrace();
                    try { Thread.sleep(500); } catch (InterruptedException ie) {}
                }
            }
        });
        rconThread.setDaemon(true);
        rconThread.start();

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

    // --- RCON helpers ---
    static void rconSend(OutputStream out, int id, int type, String payload) throws IOException {
        byte[] p = payload.getBytes(StandardCharsets.UTF_8);
        ByteBuffer bb = ByteBuffer.allocate(14 + p.length).order(ByteOrder.LITTLE_ENDIAN);
        bb.putInt(10 + p.length);
        bb.putInt(id); bb.putInt(type);
        bb.put(p); bb.put((byte)0); bb.put((byte)0);
        out.write(bb.array()); out.flush();
    }

    /** Returns int[]{id, type} or null. id=-1 means auth failure. */
    static int[] rconRecv(InputStream in) throws IOException {
        byte[] h = new byte[4];
        if (in.readNBytes(h, 0, 4) < 4) return null;
        int len = ByteBuffer.wrap(h).order(ByteOrder.LITTLE_ENDIAN).getInt();
        if (len < 10) return null;
        byte[] b = new byte[len];
        if (in.readNBytes(b, 0, len) < len) return null;
        ByteBuffer bb = ByteBuffer.wrap(b).order(ByteOrder.LITTLE_ENDIAN);
        return new int[]{bb.getInt(), bb.getInt()};
    }
}
