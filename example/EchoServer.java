import java.io.*;
import java.nio.channels.*;
import java.nio.ByteBuffer;

public class EchoServer {
    static {
        System.loadLibrary("tailscalejni");
    }

    // Native method declarations
    private native long tailscaleNew();
    private native int tailscaleSetEphemeral(long ts, int ephemeral);
    private native int tailscaleUp(long ts);
    private native long tailscaleListen(long ts, String network, String address);
    private native long tailscaleAccept(long listener);
    private native int tailscaleCloseConn(long conn);
    private native int tailscaleCloseListener(long listener);
    private native int tailscaleClose(long ts);
    private native String tailscaleErrmsg(long ts);

    private long ts;
    private long listener;

    public void run() {
        try {
            // Initialize Tailscale
            ts = tailscaleNew();
            if (ts == 0) {
                System.err.println("Failed to create Tailscale instance");
                return;
            }

            // Set ephemeral mode
            if (tailscaleSetEphemeral(ts, 1) != 0) {
                handleError(ts, "Failed to set ephemeral mode");
                return;
            }

            // Bring Tailscale up
            if (tailscaleUp(ts) != 0) {
                handleError(ts, "Failed to bring Tailscale up");
                return;
            }

            // Start listening on port 1999
            listener = tailscaleListen(ts, "tcp", ":1999");
            if (listener == 0) {
                handleError(ts, "Failed to listen on port 1999");
                return;
            }

            System.out.println("Echo server listening on port 1999...");

            // Main accept loop
            while (true) {
                long conn = tailscaleAccept(listener);
                if (conn == 0) {
                    handleError(ts, "Failed to accept connection");
                    continue;
                }

                // Handle connection in a new thread
                new ConnectionHandler(conn).start();
            }

        } catch (Exception e) {
            System.err.println("Echo server error: " + e.getMessage());
            e.printStackTrace();
        }
        finally {
            cleanup();
        }
    }

    private void handleError(long ts, String message) {
        String errorDetail = tailscaleErrmsg(ts);
        System.err.println(message + ": " + errorDetail);
    }

    private void cleanup() {
        if (listener != 0) {
            tailscaleCloseListener(listener);
            listener = 0;
        }
        if (ts != 0) {
            tailscaleClose(ts);
            ts = 0;
        }
    }

    // Connection handler thread
    private class ConnectionHandler extends Thread {
        private long conn;

        public ConnectionHandler(long conn) {
            this.conn = conn;
        }

        @Override
        public void run() {
            try {
                // Read from the connection and echo to stdout
                // Note: In a real implementation, you'd use JNI to read from the connection
                // For this example, we'll simulate the behavior
                System.out.println("New connection accepted");

                // In practice, you'd need JNI methods to read/write to the connection
                // tailscaleRead(conn, buffer, size) and tailscaleWrite(conn, buffer, size)

            } catch (Exception e) {
                System.err.println("Connection handler error: " + e.getMessage());
            }
            finally {
                if (conn != 0) {
                    tailscaleCloseConn(conn);
                }
            }
        }
    }

    public static void main(String[] args) {
        new EchoServer().run();
    }
}
