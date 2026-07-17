import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

/**
 * Patch FunctionManager compilation context: iconst_2 → iconst_4.
 *
 * Searches for a public method with signature ()L... (no args, returns object)
 * whose first instructions are: aload_0, getfield, invokevirtual, iconst_2.
 * Only patches the first iconst_2 after this specific prefix.
 */
public class PatchFuncMan implements Opcodes {

    public static void main(String[] args) throws IOException {
        if (args.length != 2) {
            System.err.println("Usage: PatchFuncMan <input.jar> <output.jar>");
            System.exit(1);
        }
        int patched = 0;

        try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(Path.of(args[0])));
             ZipOutputStream zos = new ZipOutputStream(Files.newOutputStream(Path.of(args[1])))) {

            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                byte[] data = zis.readAllBytes();

                if (entry.getName().endsWith(".class")) {
                    byte[] patchedData = patch(data);
                    if (patchedData != null) {
                        data = patchedData;
                        patched++;
                        System.err.println("Patched: " + entry.getName());
                    }
                }

                ZipEntry out = new ZipEntry(entry.getName());
                zos.putNextEntry(out);
                zos.write(data);
                zos.closeEntry();
            }
        }

        if (patched == 0) {
            System.err.println("WARNING: no class patched");
        }
    }

    static byte[] patch(byte[] classBytes) {
        ClassReader cr = new ClassReader(classBytes);
        ClassWriter cw = new ClassWriter(cr, 0);
        boolean[] didPatch = {false};

        cr.accept(new ClassVisitor(ASM9, cw) {
            @Override
            public MethodVisitor visitMethod(int access, String name,
                                             String desc, String sig, String[] ex) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, ex);

                // Target: public, ()→object, no args
                if ((access & ACC_PUBLIC) == 0
                    || !desc.startsWith("()L")
                    || (access & ACC_STATIC) != 0) {
                    return mv;
                }

                return new MethodVisitor(ASM9, mv) {
                    // State machine: 0=start, 1=saw_aload0, 2=saw_getfield, 3=saw_invokevirt
                    private int state = 0;

                    // Reset state on instructions not in the expected sequence
                    @Override public void visitLdcInsn(Object v) { if (!didPatch[0]) state = -1; super.visitLdcInsn(v); }
                    @Override public void visitTypeInsn(int op, String t) { if (!didPatch[0]) state = -1; super.visitTypeInsn(op, t); }
                    @Override public void visitJumpInsn(int op, org.objectweb.asm.Label l) { if (!didPatch[0]) state = -1; super.visitJumpInsn(op, l); }
                    @Override public void visitIincInsn(int v, int inc) { if (!didPatch[0]) state = -1; super.visitIincInsn(v, inc); }

                    @Override
                    public void visitVarInsn(int opcode, int var) {
                        if (!didPatch[0]) {
                            if (state == 0 && opcode == ALOAD && var == 0) state = 1;
                            else state = -1;
                        }
                        mv.visitVarInsn(opcode, var);
                    }

                    private boolean isStdLib(String c) {
                        return c.startsWith("java/") || c.startsWith("javax/")
                            || c.startsWith("io/netty/") || c.startsWith("com/google/")
                            || c.startsWith("org/apache/") || c.startsWith("joptsimple/")
                            || c.startsWith("it/unimi/") || c.startsWith("org/joml/");
                    }

                    @Override
                    public void visitFieldInsn(int opcode, String owner, String name, String d) {
                        if (!didPatch[0]) {
                            if (state == 1 && opcode == GETFIELD && !isStdLib(owner)) {
                                state = 2;
                            } else {
                                state = -1;
                            }
                        }
                        mv.visitFieldInsn(opcode, owner, name, d);
                    }

                    @Override
                    public void visitMethodInsn(int opcode, String owner, String name,
                                                String d, boolean itf) {
                        if (!didPatch[0]) {
                            if ((state == 2 || state == 3) && opcode == INVOKEVIRTUAL) {
                                state = state == 2 ? 3 : 4;
                            } else {
                                state = -1;
                            }
                        }
                        mv.visitMethodInsn(opcode, owner, name, d, itf);
                    }

                    @Override
                    public void visitInsn(int opcode) {
                        if (!didPatch[0] && state == 3 && opcode == ICONST_2) {
                            mv.visitInsn(ICONST_4);
                            didPatch[0] = true;
                            state = -1;
                            return;
                        }
                        if (state >= 0 && opcode != NOP) state = -1;
                        mv.visitInsn(opcode);
                    }
                };
            }
        }, 0);

        return didPatch[0] ? cw.toByteArray() : null;
    }
}
