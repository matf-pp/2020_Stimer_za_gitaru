namespace Strings.Audio {
    public class AudioThread {
        protected Device device;
        protected bool is_running;
        protected Thread<bool> thread;

        public AudioThread.from_device (Device device) {
            this.device = device;
            thread = new Thread<bool> ("audio-thread", start);
        }


        protected bool start () {
            is_running = true;
            var signal = new Audio.Sample[3 * device.sample_rate];
            try {
                device.init ();
                while (is_running) {
                    device.record (signal);
                    var file = Posix.FILE.open ("test.txt", "w");
                    foreach (var sample in signal) {
                        file.printf("%d ", sample);
                    }
                }
            } catch (Audio.DeviceError devErr) {
                stderr.printf ("%s\n", devErr.message); 
            } finally {
                is_running = false;
                device.close ();
            }
            return true;
        }

        public void stop () {
            is_running = false;
            stdout.printf ("Done listening!\n");
        }
    }
}
