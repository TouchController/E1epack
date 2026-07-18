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
        try (var executor = Executors.newFixedThreadPool(4)) {
            var mapper = new ObjectMapper().configure(JsonGenerator.Feature.AUTO_CLOSE_TARGET, false);
            var reader = new BufferedReader(new InputStreamReader(System.in));
            var requests = new LinkedList<CompletableFuture<Void>>();
            var outputLock = new ReentrantLock();
            while (true) {
                var line = reader.readLine();
                if (line == null) {
                    break;
                }
                if (line.isEmpty()) {
                    continue;
                }
                var request = mapper.readValue(line, WorkRequest.class);
                if (request.requestId() != 0) {
                    requests.add(CompletableFuture.runAsync(() -> {
                        try {
                            var output = new StringWriter();
                            var exitCode = handleRequest(request, new PrintWriter(output));
                            var response = new WorkResponse(request.requestId(), output.toString(), exitCode);
                            outputLock.lock();
                            mapper.writeValue(System.out, response);
                            System.out.println();
                        } catch (IOException e) {
                            throw new RuntimeException(e);
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
                    } catch (IOException e) {
                        throw new RuntimeException(e);
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
