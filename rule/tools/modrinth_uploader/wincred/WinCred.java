package wincred;

import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;

import com.sun.jna.LastErrorException;
import com.sun.jna.Memory;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

// https://stackoverflow.com/questions/65144266/use-the-windows-credential-manager-in-java-to-get-credentials-for-authentication
public class WinCred implements CredAdvapi32 {

    public static <T> T coalesce(final T maybeNullValue, final T nonNullValue) {
        return maybeNullValue == null ? nonNullValue : maybeNullValue;
    }

    public class Credential {
        public String target;
        public String username;
        public String password;

        public Credential(String target, String username, String password) {
            this.target = coalesce(target, "");
            this.username = coalesce(username, "");
            this.password = coalesce(password, "");
        }
    }

    public Credential getCredential(String target) {
        PCREDENTIAL pcredMem = new PCREDENTIAL();

        try {
            if (CredRead(target, 1, 0, pcredMem)) {
                CREDENTIAL credMem = new CREDENTIAL(pcredMem.credential);
                byte[] passwordBytes = credMem.CredentialBlob.getByteArray(0, credMem.CredentialBlobSize);

                String password = new String(passwordBytes, Charset.forName("UTF-16LE"));
                Credential cred = new WinCred.Credential(credMem.TargetName, credMem.UserName, password);
                return cred;
            } else {
                int err = Native.getLastError();
                throw new LastErrorException(err);
            }
        } finally {
            CredFree(pcredMem.credential);
        }
    }

    public boolean setCredential(String target, String userName, String password) throws UnsupportedEncodingException {
        CREDENTIAL credMem = new CREDENTIAL();

        credMem.Flags = 0;
        credMem.TargetName = target;
        credMem.Type = CRED_TYPE_GENERIC;
        credMem.UserName = userName;
        credMem.AttributeCount = 0;
        credMem.Persist = CRED_PERSIST_ENTERPRISE;
        byte[] bpassword = password.getBytes("UTF-16LE");
        credMem.CredentialBlobSize = (int) bpassword.length;
        credMem.CredentialBlob = getPointer(bpassword);
        if (!CredWrite(credMem, 0)) {
            int err = Native.getLastError();
            throw new LastErrorException(err);
        } else {
            return true;
        }
    }

    public boolean deleteCredential(String target) throws UnsupportedEncodingException {
        if (!CredDelete(target, CRED_TYPE_GENERIC, 0)) {
            int err = Native.getLastError();
            throw new LastErrorException(err);
        } else {
            return true;
        }
    }

    private static Pointer getPointer(byte[] array) {
        Pointer p = new Memory(array.length);
        p.write(0, array, 0, array.length);

        return p;
    }

    @Override
    public boolean CredRead(String targetName, int type, int flags, PCREDENTIAL pcredential) throws LastErrorException {
        synchronized (INSTANCE) {
            return INSTANCE.CredRead(targetName, type, flags, pcredential);
        }
    }

    @Override
    public boolean CredWrite(CREDENTIAL credential, int flags) throws LastErrorException {
        synchronized (INSTANCE) {
            return INSTANCE.CredWrite(credential, flags);
        }
    }

    @Override
    public boolean CredDelete(String targetName, int type, int flags) throws LastErrorException {
        synchronized (INSTANCE) {
            return INSTANCE.CredDelete(targetName, type, flags);
        }
    }

    @Override
    public void CredFree(Pointer credential) throws LastErrorException {
        synchronized (INSTANCE) {
            INSTANCE.CredFree(credential);
        }
    }
}