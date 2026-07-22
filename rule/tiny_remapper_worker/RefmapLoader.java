package top.fifthlight.fabazel.remapper;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

public final class RefmapLoader {
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final Pattern ACCESSOR_NAME_PATTERN =
            Pattern.compile("^(get|is|set|call|invoke|new|create)(([A-Z])(.*?))(_\\$md.*)?$");

    private RefmapLoader() {
    }

    public static String inflectAccessorName(String methodName) {
        var matcher = ACCESSOR_NAME_PATTERN.matcher(methodName);
        if (!matcher.matches()) {
            return null;
        }

        var namePart = matcher.group(2);
        var firstChar = matcher.group(3);
        var remainder = matcher.group(4);
        if (remainder == null) {
            remainder = "";
        }

        if (!namePart.equals(namePart.toUpperCase())) {
            firstChar = firstChar.toLowerCase();
        }

        return firstChar + remainder;
    }

    public static String parseRefmapMemberName(String refmapValue) {
        int nameStart = 0;
        int ownerEnd = refmapValue.indexOf(';');
        if (ownerEnd > 0 && refmapValue.charAt(0) == 'L') {
            nameStart = ownerEnd + 1;
        }
        int nameEnd = nameStart;
        while (nameEnd < refmapValue.length()) {
            char c = refmapValue.charAt(nameEnd);
            if (c == '(' || c == ':' || c == ' ') {
                break;
            }
            nameEnd++;
        }
        return refmapValue.substring(nameStart, nameEnd);
    }

    public static boolean tryParseAndMerge(byte[] content, Map<String, Map<String, String>> target) throws IOException {
        JsonNode root = MAPPER.readTree(content);
        JsonNode mappingsNode = root.get("mappings");
        if (mappingsNode == null) {
            return false;
        }

        var fields = mappingsNode.fields();
        while (fields.hasNext()) {
            var field = fields.next();
            var mixinClassName = field.getKey();
            var refEntries = field.getValue();
            var refMap = new HashMap<String, String>();
            var refFields = refEntries.fields();
            while (refFields.hasNext()) {
                var refField = refFields.next();
                refMap.put(refField.getKey(), refField.getValue().asText());
            }
            target.merge(mixinClassName, refMap, (existing, incoming) -> {
                existing.putAll(incoming);
                return existing;
            });
        }
        return true;
    }
}
