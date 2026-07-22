package top.fifthlight.fabazel.mappingmerger.operation;

import net.fabricmc.mappingio.MappingVisitor;
import net.fabricmc.mappingio.adapter.MappingNsRenamer;
import net.fabricmc.mappingio.tree.MemoryMappingTree;
import top.fifthlight.fabazel.mappingmerger.context.MergeContext;

import java.io.IOException;
import java.nio.file.Files;

public class ImportMappingOperation implements Operation {
    private final String name;

    public ImportMappingOperation(String name) {
        this.name = name;
    }

    @Override
    public MemoryMappingTree run(MemoryMappingTree tree, MergeContext context) throws IOException {
        var input = context.inputEntries().get(name);
        if (input == null) {
            throw new IllegalStateException("No input entry: " + name + ", available: " + context.inputEntries().keySet());
        }
        MappingVisitor visitor = tree;
        if (!input.namespaceMapping().isEmpty()) {
            visitor = new MappingNsRenamer(visitor, input.namespaceMapping());
        }
        try (var reader = Files.newBufferedReader(input.path())) {
            input.format().read(reader, visitor);
        }
        return tree;
    }
}
