package top.fifthlight.fabazel.mappingmerger.context;

import java.util.HashMap;
import java.util.Map;

public record MergeContext(Map<String, InputEntry> inputEntries) {
    public static class Builder {
        private final Map<String, InputEntry> inputEntries = new HashMap<>();

        public Builder addInputEntry(String name, InputEntry entry) {
            inputEntries.put(name, entry);
            return this;
        }

        public MergeContext build() {
            return new MergeContext(inputEntries);
        }
    }
}
