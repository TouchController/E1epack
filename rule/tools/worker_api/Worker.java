package top.fifthlight.bazel.worker.api;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.*;
import java.util.LinkedList;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import java.util.concurrent.locks.ReentrantLock;

public abstract class Worker {
    public void run() throws Exception {
        System.err.println("[Worker] Starting, pid=" + ProcessHandle.current().pid());
        try (var executor = Executors.newFixedThreadPool(4)) {
            var mapper = new ObjectMapper().configure(JsonGenerator.Feature.AUTO_CLOSE_TARGET, false);
            var reader = new BufferedReader(new InputStreamReader(System.in));
            var requests = new LinkedList<CompletableFuture<Void>>();
            var outputLock = new ReentrantLock();
            System.err.println("[Worker] Entering read loop");
            while (true) {
                System.err.println("[Worker] Waiting for input...");
                var line = reader.readLine();
                System.err.println("[Worker] Got line: " + (line == null ? "null" : line.length() + " bytes"));
                if (line == null) {
                    break;
                }
                if (line.isEmpty()) {
                    continue;
                }
                WorkRequest request;
                try {
                    request = mapper.readValue(line, WorkRequest.class);
                } catch (Exception e) {
                    System.err.println("Failed to parse WorkRequest: " + e.getMessage());
                    continue;
                }
                if (request.requestId() != 0) {
                    requests.add(CompletableFuture.runAsync(() -> {
                        var output = new StringWriter();
                        int exitCode;
                        try {
                            exitCode = handleRequest(request, new PrintWriter(output));
                        } catch (Exception e) {
                            e.printStackTrace(System.err);
                            output = new StringWriter();
                            e.printStackTrace(new PrintWriter(output));
                            exitCode = 1;
                        }
                        var response = new WorkResponse(request.requestId(), output.toString(), exitCode);
                        outputLock.lock();
                        try {
                            mapper.writeValue(System.out, response);
                            System.out.println();
                            System.out.flush();
                        } catch (IOException ex) {
                            ex.printStackTrace(System.err);
                        } finally {
                            outputLock.unlock();
                        }
                    }, executor));
                } else {
                    for (var future : requests) {
                        future.join();
                    }
                    try {
                        outputLock.lock();
                        var output = new StringWriter();
                        var exitCode = handleRequest(request, new PrintWriter(output));
                        var response = new WorkResponse(0, output.toString(), exitCode);
                        mapper.writeValue(System.out, response);
                        System.out.println();
                    } catch (Exception e) {
                        e.printStackTrace(System.err);
                        try {
                            var response = new WorkResponse(0, e.getMessage(), 1);
                            mapper.writeValue(System.out, response);
                            System.out.println();
                        } catch (IOException ex) {
                            ex.printStackTrace(System.err);
                        }
                    } finally {
                        outputLock.unlock();
                        System.out.flush();
                    }
                }
            }
            System.gc();
        }
    }

    protected abstract int handleRequest(WorkRequest request, PrintWriter out);
}
