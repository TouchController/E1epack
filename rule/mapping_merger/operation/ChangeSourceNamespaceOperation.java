package top.fifthlight.fabazel.mappingmerger.operation;

import net.fabricmc.mappingio.adapter.MappingSourceNsSwitch;
import net.fabricmc.mappingio.tree.MemoryMappingTree;
import top.fifthlight.fabazel.mappingmerger.context.MergeContext;

public class ChangeSourceNamespaceOperation implements Operation {
    private final String namespace;
    private final boolean droppingMissing;

    public ChangeSourceNamespaceOperation(String namespace, boolean droppingMissing) {
        this.namespace = namespace;
        this.droppingMissing = droppingMissing;
    }

    @Override
    public MemoryMappingTree run(MemoryMappingTree tree, MergeContext context) throws Exception {
        var newTree = new MemoryMappingTree();
        var visitor = new MappingSourceNsSwitch(newTree, namespace, droppingMissing);
        tree.accept(visitor);
        return newTree;
    }
}
