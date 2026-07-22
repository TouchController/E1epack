package io.github.touchcontroller.spawnchunkfix.mixin;

import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.ChunkPos;
import net.minecraft.server.level.TicketType;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.Unique;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(MinecraftServer.class)
public abstract class MinecraftServerMixin {
    @Unique
    private static final TicketType SPAWN_CHUNK_FIX = TicketType.FORCED;

    @Inject(method = "loadLevel", at = @At("TAIL"))
    private void onLoadWorld(CallbackInfo ci) {
        MinecraftServer server = (MinecraftServer) (Object) this;
        ServerLevel overworld = server.overworld();

        if (overworld == null) {
            return;
        }

        // 获取出生点坐标
        var respawnData = overworld.getLevelData().getRespawnData();
        if (respawnData == null) {
            return;
        }
        var spawnPos = respawnData.globalPos().pos();
        ChunkPos spawnChunk = new ChunkPos(spawnPos.getX() >> 4, spawnPos.getZ() >> 4);

        // 添加 FORCED ticket 到出生点区块及周围 3x3 范围
        for (int x = -1; x <= 1; x++) {
            for (int z = -1; z <= 1; z++) {
                ChunkPos chunkPos = new ChunkPos(spawnChunk.x + x, spawnChunk.z + z);
                overworld.getChunkSource().addTicketWithRadius(SPAWN_CHUNK_FIX, chunkPos, 0);
            }
        }

        // 阻塞等待所有区块加载完成（通过 getChunk 触发加载）
        for (int x = -1; x <= 1; x++) {
            for (int z = -1; z <= 1; z++) {
                ChunkPos chunkPos = new ChunkPos(spawnChunk.x + x, spawnChunk.z + z);
                overworld.getChunk(chunkPos.x, chunkPos.z);
            }
        }
    }
}