package top.fifthlight.fabazel.mappingmerger.operation;

import net.fabricmc.mappingio.tree.MemoryMappingTree;
import top.fifthlight.fabazel.mappingmerger.context.MergeContext;

public interface Operation {
    MemoryMappingTree run(MemoryMappingTree tree, MergeContext context) throws Exception;
}
