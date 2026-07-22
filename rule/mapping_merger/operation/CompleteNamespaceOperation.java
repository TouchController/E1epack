package top.fifthlight.fabazel.mappingmerger.operation;

import net.fabricmc.mappingio.adapter.MappingNsCompleter;
import net.fabricmc.mappingio.tree.MemoryMappingTree;
import top.fifthlight.fabazel.mappingmerger.context.MergeContext;

import java.util.Map;

public class CompleteNamespaceOperation implements Operation {
    private final Map<String, String> namespaceMapping;

    public CompleteNamespaceOperation(Map<String, String> namespaceMapping) {
        this.namespaceMapping = namespaceMapping;
    }

    @Override
    public MemoryMappingTree run(MemoryMappingTree tree, MergeContext context) throws Exception {
        var newTree = new MemoryMappingTree();
        var visitor = new MappingNsCompleter(newTree, namespaceMapping);
        tree.accept(visitor);
        return newTree;
    }
}
