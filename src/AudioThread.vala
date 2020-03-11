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
            var i = 0;
            is_running = true;
            var signal = new Audio.Sample[3 * device.sample_rate];
            device.init ();
            while (is_running) {
                try {
                    device.record (signal);
                } catch (Audio.DeviceError devErr) {
                    stderr.printf ("%s\n", devErr.message);
                    is_running = false;
                } finally {
                }
                var file = Posix.FILE.open ("test.txt", "w");
                foreach (var sample in signal) {
                    file.printf("%d ", sample);
                }
            }
            device.close ();
            return true;
        }

        public void stop () {
            is_running = false;
            stdout.printf ("Done listening!\n");
        }
    }
}
