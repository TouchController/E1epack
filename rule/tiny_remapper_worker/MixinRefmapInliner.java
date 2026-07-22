package top.fifthlight.fabazel.remapper;

import net.fabricmc.tinyremapper.OutputConsumerPath;
import net.fabricmc.tinyremapper.TinyRemapper;
import net.fabricmc.tinyremapper.api.TrClass;
import org.objectweb.asm.AnnotationVisitor;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

public class MixinRefmapInliner implements TinyRemapper.Extension {
    private final Map<String, Map<String, String>> refmaps = new HashMap<>();

    @Override
    public void attach(TinyRemapper.Builder builder) {
        builder.extraPreApplyVisitor(this::insertApplyVisitor);
    }

    private ClassVisitor insertApplyVisitor(TrClass cls, ClassVisitor next) {
        if (!cls.isInput() || refmaps.isEmpty()) {
            return next;
        }
        var refmap = refmaps.get(cls.getName());
        if (refmap == null || refmap.isEmpty()) {
            return next;
        }
        return new RefmapInlinerClassVisitor(next, refmap);
    }

    public OutputConsumerPath.ResourceRemapper createResourceRemapper() {
        return new OutputConsumerPath.ResourceRemapper() {
            @Override
            public boolean canTransform(TinyRemapper remapper, Path relativePath) {
                return relativePath.toString().endsWith(".json");
            }

            @Override
            public void transform(Path dstDir, Path relativePath, InputStream input, TinyRemapper remapper)
                    throws IOException {
                byte[] data = input.readAllBytes();
                if (!RefmapLoader.tryParseAndMerge(data, refmaps)) {
                    var dstFile = dstDir.resolve(relativePath.toString());
                    Files.createDirectories(dstFile.getParent());
                    Files.write(dstFile, data);
                }
            }
        };
    }

    private static class RefmapInlinerClassVisitor extends ClassVisitor {
        private static final String ACCESSOR_DESC = "Lorg/spongepowered/asm/mixin/gen/Accessor;";
        private static final String INVOKER_DESC = "Lorg/spongepowered/asm/mixin/gen/Invoker;";
        private final Map<String, String> refmap;

        RefmapInlinerClassVisitor(ClassVisitor classVisitor, Map<String, String> refmap) {
            super(Opcodes.ASM9, classVisitor);
            this.refmap = refmap;
        }

        @Override
        public AnnotationVisitor visitAnnotation(String descriptor, boolean visible) {
            var av = super.visitAnnotation(descriptor, visible);
            return new InlinerAnnotationVisitor(av, refmap);
        }

        @Override
        public MethodVisitor visitMethod(int access, String name, String descriptor, String signature,
                                         String[] exceptions) {
            var mv = super.visitMethod(access, name, descriptor, signature, exceptions);
            return new MethodVisitor(Opcodes.ASM9, mv) {
                @Override
                public AnnotationVisitor visitAnnotation(String annoDesc, boolean visible) {
                    var av = super.visitAnnotation(annoDesc, visible);
                    if (ACCESSOR_DESC.equals(annoDesc) || INVOKER_DESC.equals(annoDesc)) {
                        return new AccessorValueInjector(av, refmap, name);
                    }
                    return new InlinerAnnotationVisitor(av, refmap);
                }

                @Override
                public AnnotationVisitor visitParameterAnnotation(int parameter, String annoDesc,
                                                                  boolean visible) {
                    var av = super.visitParameterAnnotation(parameter, annoDesc, visible);
                    return new InlinerAnnotationVisitor(av, refmap);
                }
            };
        }

        private static class AccessorValueInjector extends AnnotationVisitor {
            private final String methodName;
            private final Map<String, String> refmap;
            private boolean valueVisited;

            AccessorValueInjector(AnnotationVisitor annotationVisitor, Map<String, String> refmap,
                                  String methodName) {
                super(Opcodes.ASM9, annotationVisitor);
                this.methodName = methodName;
                this.refmap = refmap;
            }

            @Override
            public void visit(String name, Object value) {
                if ("value".equals(name)) {
                    valueVisited = true;
                    if (value instanceof String strValue) {
                        var refmapValue = refmap.get(strValue);
                        if (refmapValue != null) {
                            value = RefmapLoader.parseRefmapMemberName(refmapValue);
                        }
                    }
                }
                super.visit(name, value);
            }

            @Override
            public void visitEnd() {
                if (!valueVisited) {
                    var inflected = RefmapLoader.inflectAccessorName(methodName);
                    if (inflected != null) {
                        var refmapValue = refmap.get(inflected);
                        if (refmapValue != null) {
                            var name = RefmapLoader.parseRefmapMemberName(refmapValue);
                            super.visit("value", name);
                        }
                    }
                }
                super.visitEnd();
            }

            @Override
            public AnnotationVisitor visitAnnotation(String name, String descriptor) {
                var av = super.visitAnnotation(name, descriptor);
                return new InlinerAnnotationVisitor(av, refmap);
            }

            @Override
            public AnnotationVisitor visitArray(String name) {
                var av = super.visitArray(name);
                return new InlinerAnnotationVisitor(av, refmap);
            }
        }

        private static class InlinerAnnotationVisitor extends AnnotationVisitor {
            private final Map<String, String> refmap;

            InlinerAnnotationVisitor(AnnotationVisitor annotationVisitor, Map<String, String> refmap) {
                super(Opcodes.ASM9, annotationVisitor);
                this.refmap = refmap;
            }

            @Override
            public void visit(String name, Object value) {
                if (value instanceof String strValue) {
                    var remapped = refmap.get(strValue);
                    if (remapped != null) {
                        value = remapped;
                    }
                }
                super.visit(name, value);
            }

            @Override
            public AnnotationVisitor visitArray(String name) {
                var av = super.visitArray(name);
                return new InlinerAnnotationVisitor(av, refmap);
            }

            @Override
            public AnnotationVisitor visitAnnotation(String name, String descriptor) {
                var av = super.visitAnnotation(name, descriptor);
                return new InlinerAnnotationVisitor(av, refmap);
            }
        }
    }
}
