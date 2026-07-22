package top.fifthlight.fabazel.mappingmerger.context;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import net.fabricmc.mappingio.MappedElementKind;
import net.fabricmc.mappingio.MappingVisitor;

import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.List;

public final class ParchmentFileReader {
    private static final String DEFAULT_SOURCE_NAMESPACE = "named";
    private static final JsonFactory jsonFactory = new JsonFactory();

    private ParchmentFileReader() {
    }

    public static void read(Reader reader, MappingVisitor visitor) throws IOException {
        read(reader, visitor, DEFAULT_SOURCE_NAMESPACE);
    }

    public static void read(Reader reader, MappingVisitor visitor, String sourceNamespace) throws IOException {
        try (var parser = jsonFactory.createParser(reader)) {
            if (parser.nextToken() != JsonToken.START_OBJECT) {
                throw new IOException("Expected JSON object root");
            }

            var version = (String) null;

            while (parser.nextToken() != JsonToken.END_OBJECT) {
                var fieldName = parser.currentName();
                parser.nextToken(); // Move to value

                switch (fieldName) {
                    case "version":
                        version = parser.getText();
                        break;
                    case "classes":
                        if (visitor.visitHeader()) {
                            visitor.visitNamespaces(sourceNamespace, List.of());
                        }
                        if (visitor.visitContent()) {
                            visitClasses(parser, visitor);
                        }
                        break;
                    default:
                        skipValue(parser);
                        break;
                }
            }

            if (version == null || version.isEmpty()) {
                throw new IOException("Missing Parchment version");
            }

            visitor.visitEnd();
        }
    }

    private static void visitClasses(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_ARRAY) {
            return;
        }

        while (parser.nextToken() != JsonToken.END_ARRAY) {
            visitClass(parser, visitor);
        }
    }

    private static void visitClass(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_OBJECT) {
            return;
        }

        String className = null;
        List<String> javadoc = null;
        var classVisited = false;

        while (parser.nextToken() != JsonToken.END_OBJECT) {
            var fieldName = parser.currentName();
            parser.nextToken();

            switch (fieldName) {
                case "name":
                    className = parser.getText();
                    break;
                case "fields":
                    if (className != null && !className.isEmpty()) {
                        if (!classVisited) {
                            classVisited = visitor.visitClass(className);
                            if (classVisited) {
                                if (!visitor.visitElementContent(MappedElementKind.CLASS)) {
                                    // Skip rest of class if content rejected
                                    skipValue(parser);
                                    do {
                                        skipValue(parser);
                                    } while (parser.nextToken() != JsonToken.END_OBJECT);
                                    return;
                                }
                            }
                        }
                        if (classVisited) {
                            visitFields(parser, visitor);
                        } else {
                            skipValue(parser);
                        }
                    } else {
                        skipValue(parser);
                    }
                    break;
                case "methods":
                    if (className != null && !className.isEmpty()) {
                        if (!classVisited) {
                            classVisited = visitor.visitClass(className);
                            if (classVisited) {
                                if (!visitor.visitElementContent(MappedElementKind.CLASS)) {
                                    skipValue(parser);
                                    do {
                                        skipValue(parser);
                                    } while (parser.nextToken() != JsonToken.END_OBJECT);
                                    return;
                                }
                            }
                        }
                        if (classVisited) {
                            visitMethods(parser, visitor);
                        } else {
                            skipValue(parser);
                        }
                    } else {
                        skipValue(parser);
                    }
                    break;
                case "javadoc":
                    javadoc = readStringArray(parser);
                    break;
                default:
                    skipValue(parser);
                    break;
            }
        }

        // Handle Javadoc at the end
        if (javadoc != null && !javadoc.isEmpty() && className != null && !className.isEmpty()) {
            if (visitor.visitClass(className)) {
                visitor.visitComment(MappedElementKind.CLASS, joinLines(javadoc));
            }
        }
    }

    private static void visitFields(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_ARRAY) {
            return;
        }

        while (parser.nextToken() != JsonToken.END_ARRAY) {
            visitField(parser, visitor);
        }
    }

    private static void visitField(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_OBJECT) {
            return;
        }

        String name = null;
        String descriptor = null;
        List<String> javadoc = null;

        while (parser.nextToken() != JsonToken.END_OBJECT) {
            var fieldName = parser.currentName();
            parser.nextToken();

            switch (fieldName) {
                case "name":
                    name = parser.getText();
                    break;
                case "descriptor":
                    descriptor = parser.getText();
                    break;
                case "javadoc":
                    javadoc = readStringArray(parser);
                    break;
                default:
                    skipValue(parser);
                    break;
            }
        }

        if (name != null && !name.isEmpty() && descriptor != null && !descriptor.isEmpty()) {
            if (visitor.visitField(name, descriptor)) {
                if (visitor.visitElementContent(MappedElementKind.FIELD)) {
                    if (javadoc != null && !javadoc.isEmpty()) {
                        visitor.visitComment(MappedElementKind.FIELD, joinLines(javadoc));
                    }
                }
            }
        }
    }

    private static void visitMethods(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_ARRAY) {
            return;
        }

        while (parser.nextToken() != JsonToken.END_ARRAY) {
            visitMethod(parser, visitor);
        }
    }

    private static void visitMethod(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_OBJECT) {
            return;
        }

        String name = null;
        String descriptor = null;
        List<String> javadoc = null;

        while (parser.nextToken() != JsonToken.END_OBJECT) {
            var fieldName = parser.currentName();
            parser.nextToken();

            switch (fieldName) {
                case "name":
                    name = parser.getText();
                    break;
                case "descriptor":
                    descriptor = parser.getText();
                    break;
                case "parameters":
                    if (name != null && !name.isEmpty() && descriptor != null && !descriptor.isEmpty()) {
                        if (visitor.visitMethod(name, descriptor)) {
                            if (visitor.visitElementContent(MappedElementKind.METHOD)) {
                                visitParameters(parser, visitor);
                            } else {
                                skipValue(parser);
                            }
                        } else {
                            skipValue(parser);
                        }
                    } else {
                        skipValue(parser);
                    }
                    break;
                case "javadoc":
                    javadoc = readStringArray(parser);
                    break;
                default:
                    skipValue(parser);
                    break;
            }
        }

        // Handle Javadoc at the end
        if (javadoc != null && !javadoc.isEmpty() && name != null && !name.isEmpty() && descriptor != null && !descriptor.isEmpty()) {
            if (visitor.visitMethod(name, descriptor)) {
                visitor.visitComment(MappedElementKind.METHOD, joinLines(javadoc));
            }
        }
    }

    private static void visitParameters(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_ARRAY) {
            return;
        }

        while (parser.nextToken() != JsonToken.END_ARRAY) {
            visitParameter(parser, visitor);
        }
    }

    private static void visitParameter(JsonParser parser, MappingVisitor visitor) throws IOException {
        if (parser.currentToken() != JsonToken.START_OBJECT) {
            return;
        }

        var index = -1;
        String name = null;
        String javadoc = null;

        while (parser.nextToken() != JsonToken.END_OBJECT) {
            var fieldName = parser.currentName();
            parser.nextToken();

            switch (fieldName) {
                case "index":
                    index = parser.getIntValue();
                    break;
                case "name":
                    name = parser.getText();
                    break;
                case "javadoc":
                    javadoc = parser.getText();
                    break;
                default:
                    skipValue(parser);
                    break;
            }
        }

        if (name != null && !name.isEmpty() && index >= 0) {
            if (visitor.visitMethodArg(index, index, name)) {
                if (visitor.visitElementContent(MappedElementKind.METHOD_ARG)) {
                    if (javadoc != null && !javadoc.isEmpty()) {
                        visitor.visitComment(MappedElementKind.METHOD_ARG, javadoc);
                    }
                }
            }
        }
    }

    private static List<String> readStringArray(JsonParser parser) throws IOException {
        if (parser.currentToken() != JsonToken.START_ARRAY) {
            return List.of();
        }

        List<String> result = new ArrayList<>();
        while (parser.nextToken() != JsonToken.END_ARRAY) {
            if (parser.currentToken() == JsonToken.VALUE_STRING) {
                result.add(parser.getText());
            } else {
                // Skip non-string values
                parser.skipChildren();
            }
        }
        return result;
    }

    private static void skipValue(JsonParser parser) throws IOException {
        var token = parser.currentToken();
        if (token == JsonToken.START_ARRAY || token == JsonToken.START_OBJECT) {
            parser.skipChildren();
        }
    }

    private static String joinLines(List<String> lines) {
        return String.join("\n", lines);
    }
}
